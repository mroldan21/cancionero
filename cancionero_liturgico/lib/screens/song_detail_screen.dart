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
  // No se necesita estado local para la canción, se manejará directamente en el build.
  // El estado de favorito se gestionará directamente a través de currentSong.isFavorite
  bool _hasChanges = false; // Para notificar a la pantalla anterior si debe recargar.

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

  Future<void> _toggleFavorite(Song currentSong) async {
    final songRepository = Provider.of<SongRepository>(context, listen: false);
    final songProvider = Provider.of<SongProvider>(context, listen: false);

    // Determinar el nuevo estado de favorito
    final newFavoriteState = !currentSong.isFavorite;

    // 1. Actualizar la base de datos de forma atómica.
    await songRepository.toggleFavorite(currentSong.id!);

    // 2. Crear una nueva instancia de la canción con el estado ya actualizado.
    final updatedSongInUI = currentSong.copyWith(isFavorite: newFavoriteState);

    // 3. Actualizar el provider para que la UI reaccione inmediatamente.
    songProvider.setSelectedSong(updatedSongInUI);
    // Marcar que ha habido cambios.
    _hasChanges = true;
  }

  @override
  Widget build(BuildContext context) {
    print("[SCREEN] Build: SongDetailScreen");
    
    final isSetlistMode = widget.setlistItems?.isNotEmpty ?? false;

    // Escuchamos siempre al provider para reaccionar a cambios (next/previous y guardado).
    final songProvider = Provider.of<SongProvider>(context, listen: true);
    final songRepository = Provider.of<SongRepository>(context, listen: false); // No necesita escuchar

    // SOLUCIÓN: Determinar la fuente de verdad para la canción a mostrar.
    Song currentSong;
    if (isSetlistMode && songProvider.currentSong != null) {
      // Si estamos en modo setlist, la canción actual SIEMPRE es la del provider.
      currentSong = songProvider.currentSong!;
    } else if (songProvider.currentSong != null && songProvider.currentSong!.id == widget.song.id) {
      // Si no es modo setlist (o el provider aún no se actualizó), pero hay una canción en el provider
      // que coincide con la del widget, la usamos para reflejar cambios (ej: al volver de editar).
      currentSong = songProvider.currentSong!;
    } else {
      // Como último recurso, usamos la canción que se pasó al widget.
      currentSong = widget.song;
    }


    // Usamos PopScope para interceptar la navegación hacia atrás y limpiar el estado.
    // SOLICITUD: Imprimir todos los parámetros de la canción para depuración.
    print("""
[DEBUG] SongDetailScreen build:
  - Song ID: ${currentSong.id}
  - Title: ${currentSong.title}
  - Author: ${currentSong.author}
  - Original Key: ${currentSong.originalKey}
  - Tempo: ${currentSong.tempoBpm}
  - Capo: ${currentSong.capoPosition}
  - Favorite: ${currentSong.isFavorite}
  - Play Count: ${currentSong.playCount}
  - Creation Date: ${currentSong.creationDate.toIso8601String()}
  - Modification Date: ${currentSong.modificationDate.toIso8601String()}
  - preferredFontSize: ${currentSong.preferredFontSize}
"""); // Fin del print de depuración
    return PopScope(
      canPop: false, // Interceptar la navegación para devolver un resultado.
      onPopInvoked: (didPop) {
        if (didPop) return; // Si ya se hizo pop, no hacer nada.
        final songProvider = Provider.of<SongProvider>(context, listen: false);
        if (isSetlistMode) songProvider.clearSetlistItem();
        songProvider.clearSelectedSong();
        Navigator.pop(context, _hasChanges); // Devolver si hubo cambios.
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context, _hasChanges), // Devolver si hubo cambios.
          ),
          title: Text(currentSong.title),
          actions: [
            IconButton(
              // SOLICITUD: Usar el estado local y añadir color para destacar.
              icon: Icon(
                currentSong.isFavorite ? Icons.star : Icons.star_border,
                color: currentSong.isFavorite ? Colors.redAccent : null,
              ),
              onPressed: () {
                _toggleFavorite(currentSong);
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
                      // Actualizar el provider para que la UI reaccione.
                    Provider.of<SongProvider>(context, listen: false).setSelectedSong(updatedSong);
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