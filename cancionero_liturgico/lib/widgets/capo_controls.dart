import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cancionero_liturgico/models/song.dart';
import 'package:cancionero_liturgico/services/song_provider.dart';
import 'package:cancionero_liturgico/services/transposition_service.dart';

class CapoControls extends StatelessWidget {
  final Song song;

  const CapoControls({super.key, required this.song});

  @override
  Widget build(BuildContext context) {
    final songProvider = Provider.of<SongProvider>(context);

    return FloatingActionButton(
      onPressed: () {
        // Abrir diálogo para seleccionar número de traste
        showDialog<int>(
          context: context,
          builder: (BuildContext context) {
            int selectedFret = song.capoPosition; // Usar la posición actual como valor inicial
            return AlertDialog(
              title: const Text('Usar Capo'),
              content: StatefulBuilder(
                builder: (BuildContext context, StateSetter setState) {
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Selecciona el traste:'),
                      Slider(
                        value: selectedFret.toDouble(),
                        min: 0,
                        max: 12, // Máximo 12 trastes
                        divisions: 12,
                        label: selectedFret.toString(),
                        onChanged: (value) {
                          setState(() {
                            selectedFret = value.round();
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
                    // --- CORRECCIÓN 2: Crear nueva canción con todos los campos requeridos ---
                    // y sin usar el campo 'category' inexistente.
                    // Aquí asumimos que el capo se aplica como una transposición equivalente
                    // al momento de mostrar la canción (en la vista o provider),
                    // o que se guarda la posición del capo en la canción misma si es permanente.
                    // Si la intención es guardar el capo *permanentemente* en la canción,
                    // se debe actualizar el modelo Song para incluir 'capoPosition' y
                    // usar song.copyWith o crear una nueva instancia con el nuevo capo.
                    // Para esta corrección, mostramos como crear la instancia con los campos requeridos.
                    // Suponiendo que la transposición se aplica temporalmente aquí (lo cual puede no ser correcto
                    // si la intención es guardar el capo como una modificación permanente).
                    // Si se guarda permanentemente, se debe usar song.copyWith o un nuevo constructor
                    // que permita cambiar solo el capo.
                    // Por ahora, creamos una nueva canción con el nuevo capo, manteniendo otros campos.
                    // Si se aplica capo, se puede transponer la letra *temporalmente* para mostrarla,
                    // pero la canción original no cambia a menos que se guarde explícitamente.
                    // Para aplicar capo como transposición temporal:
                    final transposedContent = TranspositionService.transposeContent(song.content, selectedFret);
                    final transposedKey = TranspositionService.getTransposedOriginalKey(song.originalKey, selectedFret);

                    songProvider.setSelectedSong(
                      Song(
                        id: song.id,
                        title: song.title,
                        author: song.author, // Asumiendo que author puede ser nulo
                        content: transposedContent, // Contenido transpuesto temporalmente
                        originalKey: transposedKey, // Tonalidad transpuesta temporalmente
                        tempoBpm: song.tempoBpm,
                        capoPosition: selectedFret, // Nueva posición de capo
                        isFavorite: song.isFavorite,
                        playCount: song.playCount,
                        creationDate: song.creationDate, // Campo requerido
                        modificationDate: song.modificationDate, // Campo requerido
                        notes: song.notes,
                        videoLinks: song.videoLinks,
                        preferredFontSize: song.preferredFontSize, // Preservar el tamaño de fuente existente
                        // No usar 'category' porque no existe en el modelo Song
                      ),
                    );
                    Navigator.pop(context, selectedFret);
                  },
                  child: const Text('Aplicar'),
                ),
              ],
            );
          },
        );
      },
      child: const Icon(Icons.straighten),
    );
  }
}