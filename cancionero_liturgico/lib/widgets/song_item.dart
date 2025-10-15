import 'package:flutter/material.dart';
import '../models/song.dart';

class SongItem extends StatelessWidget {
  final Song song;
  final VoidCallback onTap;

  const SongItem({
    super.key,
    required this.song,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        title: Text(song.title),
        subtitle: song.artist.isNotEmpty
            ? Text('${song.artist} • Tono: ${song.originalKey}')
            : Text('Tono: ${song.originalKey}'),
        trailing: song.isFavorite ? const Icon(Icons.star, color: Colors.amber) : null,
        onTap: onTap,
      ),
    );
  }
}