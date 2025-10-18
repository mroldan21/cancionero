import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cancionero_liturgico/models/song.dart';
import 'package:cancionero_liturgico/models/setlist.dart'; // Importar SetlistItem
import 'package:cancionero_liturgico/screens/presentation_screen.dart';
import 'package:cancionero_liturgico/services/song_provider.dart'; // Importar SongProvider
import 'package:cancionero_liturgico/services/transposition_service.dart';
import 'package:cancionero_liturgico/widgets/chord_text.dart';
import 'package:cancionero_liturgico/services/song_repository.dart';
import 'package:cancionero_liturgico/screens/song_edit_screen.dart';

class SongDetailScreen extends StatefulWidget {
  final Song song;
  final List<SetlistItem>? setlistItems; // Nuevo: para recibir el contexto del setlist

  const SongDetailScreen({
    super.key,
    required this.song,
    this.setlistItems, // Parámetro opcional
  });

  @override
  State<SongDetailScreen> createState() => _SongDetailScreenState();
}

class _SongDetailScreenState extends State<SongDetailScreen> {
  late Song _currentSong;

  @override
  void initState() {
    super.initState();
    // Usamos el estado local para la canción, asegurando que siempre se muestre la correcta.
    _currentSong = widget.song;
    // Si estamos en modo setlist, nos aseguramos que el provider esté sincronizado.
  }

  // SOLUCIÓN: Usar didUpdateWidget para mantener el estado sincronizado.
  // Este método se llama cuando el widget es reconstruido con nuevos parámetros,
  // como cuando se navega entre canciones de un setlist o se vuelve a la pantalla
  // con una versión actualizada de la canción desde SongListScreen.
  @override
  void didUpdateWidget(covariant SongDetailScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.song != oldWidget.song) {
      _currentSong = widget.song;
    }
  }

  void _goToNextSong() {
    if (widget.setlistItems == null) return;

    final songProvider = Provider.of<SongProvider>(context, listen: false);
    final currentIndex = songProvider.currentSetlistIndex;

    if (currentIndex < widget.setlistItems!.length - 1) {
      final nextIndex = currentIndex + 1;
      final nextItem = widget.setlistItems![nextIndex];
      songProvider.setSelectedSetlistItem(nextItem, nextIndex);
    }
  }

  void _goToPreviousSong() {
    if (widget.setlistItems == null) return;

    final songProvider = Provider.of<SongProvider>(context, listen: false);
    final currentIndex = songProvider.currentSetlistIndex;

    if (currentIndex > 0) {
      final prevIndex = currentIndex - 1;
      final prevItem = widget.setlistItems![prevIndex];
      songProvider.setSelectedSetlistItem(prevItem, prevIndex);
    }
  }

  void _toggleFavorite() {
    final songRepository = Provider.of<SongRepository>(context, listen: false);
    songRepository.toggleFavorite(_currentSong.id!);
    setState(() {
      // Usar copyWith es más seguro y limpio
      _currentSong = _currentSong.copyWith(isFavorite: !_currentSong.isFavorite);
    });
  }

  @override
  Widget build(BuildContext context) {
    print("[SCREEN] Build: SongDetailScreen");
    
    final isSetlistMode = widget.setlistItems?.isNotEmpty ?? false;

    // Escuchamos siempre al provider para reaccionar a cambios (next/previous y guardado).
    final songProvider = Provider.of<SongProvider>(context);
    final songRepository = Provider.of<SongRepository>(context, listen: false); // No necesita escuchar

    // Esta lógica se mantiene y es correcta para reaccionar a los cambios
    // INMEDIATOS después de guardar en PresentationScreen, ya que el provider
    // se actualiza y notifica a esta pantalla.
    if (songProvider.currentSong != null &&
        songProvider.currentSong!.id == _currentSong.id &&
        songProvider.currentSong!.modificationDate.isAfter(_currentSong.modificationDate)) {
      // Usamos un post-frame callback para actualizar el estado de forma segura
      // después de que el frame actual se haya construido.
      WidgetsBinding.instance.addPostFrameCallback((_) => setState(() => _currentSong = songProvider.currentSong!));
    }

    final currentSong = _currentSong; // Usar siempre el estado local actualizado.

    // Usamos PopScope para interceptar la navegación hacia atrás y limpiar el estado.
    print("[DEBUG] SongDetailScreen build: Mostrando canción '${currentSong.title}' con preferredFontSize: ${currentSong.preferredFontSize}");
    return PopScope(
      canPop: true, // Permitir siempre la navegación hacia atrás.
      onPopInvoked: (didPop) {
        if (didPop && isSetlistMode) {
          Provider.of<SongProvider>(context, listen: false).clearSetlistItem();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(currentSong.title),
          actions: [
            IconButton(
              icon: Icon(currentSong.isFavorite ? Icons.star : Icons.star_border),
              onPressed: () {
                _toggleFavorite();
              },
            ),
            IconButton(
              icon: const Icon(Icons.slideshow),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PresentationScreen(song: currentSong),
                  ),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                // MEJORA: Navegar y esperar un resultado para actualizar la UI
                Navigator.push<bool>(
                  context,
                  MaterialPageRoute(builder: (context) => SongEditScreen(song: currentSong)),
                ).then((result) async {
                  // Si la edición fue exitosa (result == true)
                  if (result == true && currentSong.id != null) {
                    // Recargar la canción desde la base de datos
                    final updatedSong = await songRepository.getSongById(currentSong.id!);
                    if (updatedSong != null) {
                      // Actualizar el provider para refrescar la pantalla
                      setState(() {
                        _currentSong = updatedSong;
                      });
                    }
                  }
                });
              },
            ),
          ],
        ),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Autor: ${currentSong.author ?? "Desconocido"}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                Text(
                  'Tono Original: ${currentSong.originalKey}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                Text(
                  'Tempo: ${currentSong.tempoBpm ?? "N/A"} BPM',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                Text(
                  'Capo: ${currentSong.capoPosition != 0 ? "Traste ${currentSong.capoPosition}" : "No"}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                Text(
                  'Reproducciones: ${currentSong.playCount}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                // El ChordText ya no necesita Expanded porque la columna entera es desplazable.
                // Asumimos que ChordText internamente no es un widget que se expande infinitamente.
                // Si ChordText usara un ListView/Column, necesitaría `shrinkWrap: true` y `physics: NeverScrollableScrollPhysics()`.
                ChordText(
                  currentSong.content,
                  fontSize: 16.0,
                ),
                if (currentSong.notes != null && currentSong.notes!.isNotEmpty) ...[
                  const SizedBox(height: 16), // Aumentar separación
                  Text(
                    'Notas:',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    currentSong.notes!,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
                if (currentSong.videoLinks != null && currentSong.videoLinks!.isNotEmpty) ...[
                  const SizedBox(height: 16), // Aumentar separación
                  Text(
                    'Videos:',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  // SOLUCIÓN: Envolver la columna de videos en IntrinsicWidth para resolver el error de layout.
                  IntrinsicWidth(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: currentSong.videoLinks!.map(
                        (link) => ListTile(
                          title: Text(link, style: const TextStyle(color: Colors.blue), overflow: TextOverflow.ellipsis),
                          onTap: () {
                            // launchUrl(Uri.parse(link));
                          },
                        ),
                      ).toList(),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        // Mostrar la barra de navegación del setlist si aplica
        bottomNavigationBar: isSetlistMode
            ? BottomAppBar(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.skip_previous),
                      onPressed: songProvider.currentSetlistIndex > 0 ? _goToPreviousSong : null,
                      tooltip: 'Canción Anterior',
                    ),
                    Text(
                      '${songProvider.currentSetlistIndex + 1} de ${widget.setlistItems!.length}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    IconButton(
                      icon: const Icon(Icons.skip_next),
                      onPressed: songProvider.currentSetlistIndex < widget.setlistItems!.length - 1 ? _goToNextSong : null,
                      tooltip: 'Siguiente Canción',
                    ),
                  ],
                ),
              )
            : null,
        floatingActionButton: FloatingActionButton(
          heroTag: 'play_presentation',
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                // Si estamos en modo setlist, pasamos el SetlistItem para usar su configuración.
                builder: (context) => PresentationScreen(
                  song: currentSong,
                  setlistItem: songProvider.isCurrentSongFromSetlist ? songProvider.currentSetlistItem : null,
                ),
              ),
            );
          },
          child: const Icon(Icons.play_arrow),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      ),
    )
    ;
  }
}