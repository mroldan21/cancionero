import 'package:flutter/material.dart';
import 'package:cancionero_liturgico/models/song.dart';

class SongItem extends StatelessWidget {
  final Song song;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress; // Añadir este parámetro
  final bool isSelected;

  const SongItem({
    super.key,
    required this.song,
    this.onTap,
    this.onLongPress, // Añadir este parámetro al constructor
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: isSelected ? Theme.of(context).colorScheme.primary.withOpacity(0.2) : null,
      child: ListTile(
        title: Text(song.title),
        // Eliminar esta línea porque 'category' ya no existe en el modelo Song
        // subtitle: song.category != null ? Text(song.category!) : null, // Ajuste temporal si 'category' en Song era String?
        onTap: onTap,
        onLongPress: onLongPress, // Añadir el callback aquí
      ),
    );
  }
}