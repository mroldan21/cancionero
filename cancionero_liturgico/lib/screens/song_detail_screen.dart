import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cancionero_liturgico/models/song.dart';
import 'package:cancionero_liturgico/screens/presentation_screen.dart';
import 'package:cancionero_liturgico/services/transposition_service.dart';
import 'package:cancionero_liturgico/widgets/chord_text.dart';
import 'package:cancionero_liturgico/services/song_repository.dart';
import 'package:cancionero_liturgico/screens/song_edit_screen.dart';

class SongDetailScreen extends StatelessWidget {
  final Song song;

  const SongDetailScreen({super.key, required this.song});

  @override
  Widget build(BuildContext context) {
    print("[SCREEN] Build: SongDetailScreen");
    final songRepository = Provider.of<SongRepository>(context, listen: false);
    final currentSong = song;
    String displayedKey = currentSong.originalKey;

    return Scaffold(
      appBar: AppBar(
        title: Text(currentSong.title),
        actions: [
          IconButton(
            icon: Icon(currentSong.isFavorite ? Icons.star : Icons.star_border),
            onPressed: () {
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
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SongEditScreen(song: null)),
              );
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
              'Autor: ${currentSong.author ?? "Desconocido"}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            Text(
              'Tono Original (Transpuesto): $displayedKey',
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
            Expanded(
              child: ChordText(
                currentSong.content,
                fontSize: 16.0,
              ),
            ),
            if (currentSong.notes != null && currentSong.notes!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Notas:',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Text(
                currentSong.notes!,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
            if (currentSong.videoLinks != null && currentSong.videoLinks!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Videos:',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              ...currentSong.videoLinks!.map(
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
    );
  }
}