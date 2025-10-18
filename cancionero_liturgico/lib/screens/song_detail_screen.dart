import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cancionero_liturgico/models/song.dart';
import 'package:cancionero_liturgico/screens/presentation_screen.dart';
import 'package:cancionero_liturgico/services/transposition_service.dart';
import 'package:cancionero_liturgico/widgets/chord_text.dart';
import 'package:cancionero_liturgico/services/song_repository.dart';
import 'package:cancionero_liturgico/screens/song_edit_screen.dart';

class SongDetailScreen extends StatefulWidget {
  final Song song;

  const SongDetailScreen({super.key, required this.song});

  @override
  State<SongDetailScreen> createState() => _SongDetailScreenState();
}

class _SongDetailScreenState extends State<SongDetailScreen> {
  late Song _currentSong;

  @override
  void initState() {
    super.initState();
    _currentSong = widget.song;
  }

  @override
  Widget build(BuildContext context) {
    print("[SCREEN] Build: SongDetailScreen");
    final songRepository = Provider.of<SongRepository>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: Text(_currentSong.title),
        actions: [
          IconButton(
            icon: Icon(_currentSong.isFavorite ? Icons.star : Icons.star_border),
            onPressed: () {
              songRepository.toggleFavorite(_currentSong.id!);
            },
          ),
          IconButton(
            icon: const Icon(Icons.slideshow),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PresentationScreen(song: _currentSong),
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
                MaterialPageRoute(builder: (context) => SongEditScreen(song: _currentSong)),
              ).then((result) async {
                // Si la edición fue exitosa (result == true)
                if (result == true && _currentSong.id != null) {
                  // Recargar la canción desde la base de datos
                  final updatedSong = await songRepository.getSongById(_currentSong.id!);
                  if (updatedSong != null) {
                    // Actualizar el estado para refrescar la pantalla
                    setState(() => _currentSong = updatedSong);
                  }
                }
              });
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Autor: ${_currentSong.author ?? "Desconocido"}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            Text(
              'Tono Original: ${_currentSong.originalKey}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            Text(
              'Tempo: ${_currentSong.tempoBpm ?? "N/A"} BPM',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            Text(
              'Capo: ${_currentSong.capoPosition != 0 ? "Traste ${_currentSong.capoPosition}" : "No"}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            Text(
              'Reproducciones: ${_currentSong.playCount}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ChordText(
                _currentSong.content,
                fontSize: 16.0,
              ),
            ),
            if (_currentSong.notes != null && _currentSong.notes!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Notas:',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Text(
                _currentSong.notes!,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
            if (_currentSong.videoLinks != null && _currentSong.videoLinks!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Videos:',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              ..._currentSong.videoLinks!.map(
                (link) => ListTile(
                  title: Text(link),
                  onTap: () {
                    // launchUrl(Uri.parse(link));
                  },
                ),
              ),
            ],
          ],
        ),
      ),
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
                          String newContent = TranspositionService.transposeContent(_currentSong.content, transposition);
                          String newOriginalKey = TranspositionService.getTransposedOriginalKey(_currentSong.originalKey, transposition);
                          Song updatedSong = Song(
                            id: _currentSong.id,
                            title: _currentSong.title,
                            author: _currentSong.author,
                            content: newContent,
                            originalKey: newOriginalKey,
                            tempoBpm: _currentSong.tempoBpm,
                            capoPosition: _currentSong.capoPosition,
                            isFavorite: _currentSong.isFavorite,
                            playCount: _currentSong.playCount,
                            creationDate: _currentSong.creationDate,
                            modificationDate: DateTime.now(),
                            notes: _currentSong.notes,
                            videoLinks: _currentSong.videoLinks,
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
    );
  }
}