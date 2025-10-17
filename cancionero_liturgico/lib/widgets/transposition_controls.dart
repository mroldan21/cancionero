import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cancionero_liturgico/models/song.dart';
import 'package:cancionero_liturgico/services/song_provider.dart';
import 'package:cancionero_liturgico/services/transposition_service.dart';

class TranspositionControls extends StatelessWidget {
  final Song song; // Parámetro posicional o nombrado, dependiendo de cómo se llame

  const TranspositionControls({
    super.key,
    required this.song, // Parámetro nombrado requerido
  });

  @override
  Widget build(BuildContext context) {
    final songProvider = Provider.of<SongProvider>(context);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        FloatingActionButton(
          heroTag: 'btn_down_${song.id}', // Tag único para evitar conflictos con múltiples instancias
          onPressed: () {
            // Disminuir transposición
            // --- CORRECCIÓN: Crear nueva canción con todos los campos requeridos ---
            // y sin usar el campo 'category' inexistente.
            // La transposición se aplica temporalmente aquí para mostrarla.
            final transposedContent = TranspositionService.transposeContent(song.content, -1);
            final transposedKey = TranspositionService.getTransposedOriginalKey(song.originalKey, -1);

            songProvider.setSelectedSong(
              Song(
                id: song.id,
                title: song.title,
                author: song.author, // Asumiendo que author puede ser nulo
                content: transposedContent, // Contenido transpuesto temporalmente
                originalKey: transposedKey, // Tonalidad transpuesta temporalmente
                tempoBpm: song.tempoBpm,
                capoPosition: song.capoPosition, // Mantener posición de capo original
                isFavorite: song.isFavorite,
                playCount: song.playCount,
                creationDate: song.creationDate, // Campo requerido
                modificationDate: song.modificationDate, // Campo requerido
                notes: song.notes,
                videoLinks: song.videoLinks,
                // No usar 'category' porque no existe en el modelo Song
              ),
            );
          },
          child: const Icon(Icons.remove),
        ),
        const SizedBox(width: 8),
        FloatingActionButton(
          heroTag: 'btn_reset_${song.id}',
          onPressed: () {
            // Resetear a la canción original
            songProvider.clearSelectedSong(); // Esto podría no ser suficiente si el estado de la canción original no se restaura
            // O bien, se podría pasar la canción original como estado inicial o manejarla en SongProvider
            // Por ahora, simplemente selecciona la canción original
            songProvider.setSelectedSong(song);
          },
          child: const Icon(Icons.refresh),
        ),
        const SizedBox(width: 8),
        FloatingActionButton(
          heroTag: 'btn_up_${song.id}',
          onPressed: () {
            // Aumentar transposición
            // --- CORRECCIÓN: Crear nueva canción con todos los campos requeridos ---
            // y sin usar el campo 'category' inexistente.
            // La transposición se aplica temporalmente aquí para mostrarla.
            final transposedContent = TranspositionService.transposeContent(song.content, 1);
            final transposedKey = TranspositionService.getTransposedOriginalKey(song.originalKey, 1);

            songProvider.setSelectedSong(
              Song(
                id: song.id,
                title: song.title,
                author: song.author, // Asumiendo que author puede ser nulo
                content: transposedContent, // Contenido transpuesto temporalmente
                originalKey: transposedKey, // Tonalidad transpuesta temporalmente
                tempoBpm: song.tempoBpm,
                capoPosition: song.capoPosition, // Mantener posición de capo original
                isFavorite: song.isFavorite,
                playCount: song.playCount,
                creationDate: song.creationDate, // Campo requerido
                modificationDate: song.modificationDate, // Campo requerido
                notes: song.notes,
                videoLinks: song.videoLinks,
                // No usar 'category' porque no existe en el modelo Song
              ),
            );
          },
          child: const Icon(Icons.add),
        ),
      ],
    );
  }
}