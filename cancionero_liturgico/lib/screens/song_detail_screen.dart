import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cancionero_liturgico/models/song.dart';
//import 'package:cancionero_liturgico/services/song_provider.dart';
import 'package:cancionero_liturgico/services/transposition_service.dart';
import 'package:cancionero_liturgico/widgets/chord_text.dart';
// import 'package:cancionero_liturgico/widgets/transposition_controls.dart'; // Ya no se usa aquí
// import 'package:cancionero_liturgico/widgets/capo_controls.dart'; // Ya no se usa aquí para transposición
import 'package:cancionero_liturgico/services/song_repository.dart';
import 'package:cancionero_liturgico/screens/song_edit_screen.dart'; // Añadir esta importación

class SongDetailScreen extends StatelessWidget {
  final Song song;

  const SongDetailScreen({super.key, required this.song});

  @override
  Widget build(BuildContext context) {
    final songRepository = Provider.of<SongRepository>(context, listen: false);
    // No usamos SongProvider para transposición contextual
    final currentSong = song; // La canción mostrada es la transpuesta guardada
    // La transposición ya está aplicada en 'content' y 'originalKey'
    String displayedKey = currentSong.originalKey; // Mostrar la clave ya transpuesta

    return Scaffold(
      appBar: AppBar(
        title: Text(currentSong.title),
        actions: [
          IconButton(
            icon: Icon(currentSong.isFavorite ? Icons.star : Icons.star_border),
            onPressed: () {
              // Lógica para marcar/desmarcar favorito
              songRepository.toggleFavorite(currentSong.id!);
              // Opcional: Actualizar el estado localmente si es necesario o usar provider para reflejar el cambio globalmente
              // Por ejemplo, actualizando el objeto song localmente si se está mostrando en una lista.
              // setState(() { currentSong = Song(...currentSong, isFavorite: !currentSong.isFavorite); });
            },
          ),
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SongEditScreen(song: null)), // Pasar la canción actual si se quiere editar con valores pre-cargados
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
            // Metadatos
            Text(
              'Autor: ${currentSong.author ?? "Desconocido"}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            Text(
              'Tono Original (Transpuesto): $displayedKey', // Mostrar la clave ya transpuesta
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
            // Contenido con acordes (ya transpuesto)
            Expanded(
              child: ChordText(
                currentSong.content, // Mostrar contenido transpuesto
                fontSize: 16.0, // Valor por defecto o ajustar según sea necesario
              ),
            ),
            // Notas
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
            // Enlaces de video
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
                    // Abrir el enlace en un navegador
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
          // Botón para transponer la canción permanentemente
          FloatingActionButton(
            heroTag: 'transpose_song',
            onPressed: () async {
              int transposition = 0; // Valor inicial para el diálogo
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
                          // Aplicar la transposición a la canción original
                          String newContent = TranspositionService.transposeContent(currentSong.content, transposition);
                          String newOriginalKey = TranspositionService.getTransposedOriginalKey(currentSong.originalKey, transposition);
                          // Crear una nueva instancia de Song con el contenido y la clave transpuesta
                          Song updatedSong = Song(
                            id: currentSong.id,
                            title: currentSong.title,
                            author: currentSong.author,
                            content: newContent,
                            originalKey: newOriginalKey,
                            tempoBpm: currentSong.tempoBpm,
                            capoPosition: currentSong.capoPosition, // Capo no cambia con la transposición de acordes
                            isFavorite: currentSong.isFavorite,
                            playCount: currentSong.playCount,
                            creationDate: currentSong.creationDate,
                            modificationDate: DateTime.now(), // Actualizar fecha de modificación
                            notes: currentSong.notes,
                            videoLinks: currentSong.videoLinks,
                          );
                          // Guardar la canción actualizada
                          songRepository.updateSong(updatedSong);
                          // Opcional: Actualizar el estado local o navegar para reflejar el cambio
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
          // Botón para resetear la transposición (volver a la clave original)
          FloatingActionButton(
            heroTag: 'reset_transpose',
            onPressed: () {
              // Aquí necesitarías la versión original no transpuesta de la canción
              // o tenerla almacenada de alguna manera (ej: un campo 'letra_original_sin_transponer')
              // Por ahora, asumimos que no se puede resetear sin datos extra.
              // Se podría implementar un servicio que calcule la inversa, pero es complejo.
              // La opción más directa es editar la canción y reescribir la letra.
              print("Resetear transposición no implementado sin datos originales.");
              // Mostrar un mensaje o navegar a la edición
              // ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Edite la canción para revertir la transposición.")));
            },
            child: const Icon(Icons.refresh),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}