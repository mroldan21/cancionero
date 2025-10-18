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

  @override
  Widget build(BuildContext context) {
    print("[SCREEN] Build: SongDetailScreen");
    
    final isSetlistMode = widget.setlistItems != null && widget.setlistItems!.isNotEmpty;
    
    // Escuchamos al provider solo en modo setlist para reaccionar a next/previous.
    final songProvider = Provider.of<SongProvider>(context, listen: isSetlistMode);
    final songRepository = Provider.of<SongRepository>(context, listen: false); // No necesita escuchar

    // La fuente de verdad es el estado local `_currentSong`.
    // En modo setlist, si el provider tiene una canción, la usamos para actualizar el estado local.
    final Song currentSong;
    if (isSetlistMode && songProvider.currentSong != null) {
      // Sincronizamos el estado local con el del provider
      _currentSong = songProvider.currentSong!;
    }
    // Usamos siempre el estado local para renderizar.
    currentSong = _currentSong;

    // Usamos PopScope para interceptar la navegación hacia atrás y limpiar el estado.
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
                // TODO: Actualizar el estado de favorito visualmente al instante
                songRepository.toggleFavorite(currentSong.id!);
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
        floatingActionButton: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            FloatingActionButton(
              heroTag: 'transpose_song',
              onPressed: () async {
                int transposition = 0;
                await showDialog<int>(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: const Text('Transponer Canción'),
                      content: StatefulBuilder(
                        builder: (BuildContext context, StateSetter setState) {
                          return Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text('Selecciona la transposición en semitonos:'),
                              Slider(
                                value: transposition.toDouble(),
                                min: -11,
                                max: 11,
                                divisions: 22,
                                label: transposition.toString(),
                                onChanged: (value) {
                                  setState(() {
                                    transposition = value.round();
                                  });
                                },
                              ),
                            ],
                          );
                        },
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancelar'),
                        ),
                        TextButton(
                          onPressed: () {
                            String newContent = TranspositionService.transposeContent(currentSong.content, transposition);
                            String newOriginalKey = TranspositionService.getTransposedOriginalKey(currentSong.originalKey, transposition);
                            Song updatedSong = Song(
                              id: currentSong.id,
                              title: currentSong.title,
                              author: currentSong.author,
                              content: newContent,
                              originalKey: newOriginalKey,
                              tempoBpm: currentSong.tempoBpm,
                              capoPosition: currentSong.capoPosition,
                              isFavorite: currentSong.isFavorite,
                              playCount: currentSong.playCount,
                              creationDate: currentSong.creationDate,
                              modificationDate: DateTime.now(),
                              notes: currentSong.notes,
                              videoLinks: currentSong.videoLinks,
                            );
                            songRepository.updateSong(updatedSong);
                            Navigator.pop(context, transposition);
                          },
                          child: const Text('Aplicar'),
                        ),
                      ],
                    );
                  },
                );
              },
              child: const Icon(Icons.tune),
            ),
            const SizedBox(width: 8),
            FloatingActionButton(
              heroTag: 'reset_transpose',
              onPressed: () {
                print("Resetear transposición no implementado sin datos originales.");
              },
              child: const Icon(Icons.refresh),
            ),
          ],
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      ),
    )
    ;
  }
}