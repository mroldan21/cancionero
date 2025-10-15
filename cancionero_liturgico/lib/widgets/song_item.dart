import 'package:flutter/material.dart';
import '../models/song.dart';
import '../screens/song_detail_screen.dart';
import '../screens/presentation_mode_screen.dart';

class SongItem extends StatelessWidget {
  final Song song;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onToggleFavorite;

  const SongItem({
    Key? key,
    required this.song,
    this.onTap,
    this.onEdit,
    this.onDelete,
    this.onToggleFavorite,
  }) : super(key: key);

  void _handleTap(BuildContext context) {
    if (onTap != null) {
      onTap!();
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SongDetailScreen(song: song),
        ),
      );
    }
  }

  void _handlePresentationMode(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PresentationModeScreen(song: song),
      ),
    );
  }

  void _showOptionsMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.slideshow),
            title: const Text('Presentation Mode'),
            onTap: () {
              Navigator.pop(context);
              _handlePresentationMode(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.edit),
            title: const Text('Edit Song'),
            onTap: () {
              Navigator.pop(context);
              onEdit?.call();
            },
          ),
          ListTile(
            leading: const Icon(Icons.favorite, color: Colors.red),
            title: Text(song.isFavorite ? 'Remove from favorites' : 'Add to favorites'),
            onTap: () {
              Navigator.pop(context);
              onToggleFavorite?.call();
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete, color: Colors.red),
            title: const Text('Delete Song'),
            onTap: () {
              Navigator.pop(context);
              onDelete?.call();
            },
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: () => _handleTap(context),
        onLongPress: () => _showOptionsMenu(context),
        child: ListTile(
          leading: _buildSongLeading(),
          title: _buildSongTitle(),
          subtitle: _buildSongSubtitle(),
          trailing: _buildSongTrailing(context),
          contentPadding: const EdgeInsets.only(left: 16, right: 4), // ✅ MÁXIMO ESPACIO
        ),
      ),
    );
  }

  Widget _buildSongLeading() {
    return Stack(
      children: [
        const Icon(Icons.music_note, size: 32, color: Colors.blue),
        if (song.isFavorite)
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.favorite, size: 12, color: Colors.red),
            ),
          ),
      ],
    );
  }

  Widget _buildSongTitle() {
    return Text(
      song.title,
      style: const TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 16,
      ),
      maxLines: 2, // ✅ MÁS LÍNEAS PARA TÍTULOS LARGOS
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildSongSubtitle() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (song.artist != null && song.artist!.isNotEmpty)
          Text(
            song.artist!,
            style: const TextStyle(fontSize: 14),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        const SizedBox(height: 4),
        // ✅ CORREGIDO: Usar Wrap en lugar de Row para evitar overflow
        Wrap(
          spacing: 6,
          runSpacing: 4,
          children: [
            _buildInfoChip('Key: ${song.originalKey}'),
            if (song.capoPosition > 0)
              _buildInfoChip('Capo: ${song.capoPosition}'),
            if (song.tempoBpm != null)
              _buildInfoChip('${song.tempoBpm} BPM'),
          ],
        ),
      ],
    );
  }

  Widget _buildInfoChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 10,
          color: Colors.grey,
        ),
      ),
    );
  }

  // Widget _buildSongTrailing(BuildContext context) {
  //   return SizedBox(
  //     width: 60, // ✅ ANCHO MÍNIMO ABSOLUTO
  //     child: Row(
  //       mainAxisSize: MainAxisSize.min,
  //       mainAxisAlignment: MainAxisAlignment.end,
  //       children: [
  //         // Botón de presentación
  //         IconButton(
  //           icon: const Icon(Icons.slideshow, size: 18), // ✅ TAMAÑO REDUCIDO
  //           onPressed: () => _handlePresentationMode(context),
  //           tooltip: 'Presentation Mode',
  //           padding: const EdgeInsets.all(2), // ✅ PADDING MÍNIMO
  //           constraints: const BoxConstraints(minWidth: 20, minHeight: 20), // ✅ CONSTRAINTS MÍNIMOS
  //           iconSize: 18, // ✅ TAMAÑO FIJO PEQUEÑO
  //         ),
  //         // Menú de opciones
  //         IconButton(
  //           icon: const Icon(Icons.more_vert, size: 18), // ✅ TAMAÑO REDUCIDO
  //           onPressed: () => _showOptionsMenu(context),
  //           tooltip: 'More options',
  //           padding: const EdgeInsets.all(2), // ✅ PADDING MÍNIMO
  //           constraints: const BoxConstraints(minWidth: 20, minHeight: 20), // ✅ CONSTRAINTS MÍNIMOS
  //           iconSize: 18, // ✅ TAMAÑO FIJO PEQUEÑO
  //         ),
  //       ],
  //     ),
  //   );
  // }

  Widget _buildSongTrailing(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.slideshow, size: 40),
      onPressed: () => _handlePresentationMode(context),
      tooltip: 'Presentation Mode',
      color: Colors.blue,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
    );
  }
}

// Widget alternativo MÁS COMPACTO para cuando hay overflow
class SongItemCompact extends StatelessWidget {
  final Song song;
  final VoidCallback? onTap;

  const SongItemCompact({
    Key? key,
    required this.song,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: const Icon(Icons.music_note, size: 20),
        title: Text(
          song.title,
          style: const TextStyle(fontSize: 14),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: song.artist != null 
            ? Text(
                song.artist!,
                style: const TextStyle(fontSize: 12),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              )
            : null,
        trailing: song.isFavorite 
            ? const Icon(Icons.favorite, size: 16, color: Colors.red)
            : null,
        onTap: onTap,
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12),
      ),
    );
  }
}

// ✅ RESTAURADO: Widget para grid view
class SongGridItem extends StatelessWidget {
  final Song song;
  final VoidCallback? onTap;

  const SongGridItem({
    Key? key,
    required this.song,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icono y favorito
              Row(
                children: [
                  const Icon(Icons.music_note, size: 24, color: Colors.blue),
                  const Spacer(),
                  if (song.isFavorite)
                    const Icon(Icons.favorite, size: 16, color: Colors.red),
                ],
              ),
              const SizedBox(height: 8),
              
              // Título
              Text(
                song.title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              
              // Artista
              if (song.artist != null && song.artist!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    song.artist!,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              
              const Spacer(),
              
              // Información adicional
              Row(
                children: [
                  Text(
                    song.originalKey,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.grey,
                    ),
                  ),
                  const Spacer(),
                  if (song.playCount > 0)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.play_arrow, size: 12, color: Colors.grey),
                        const SizedBox(width: 2),
                        Text(
                          song.playCount > 99 ? '99+' : '${song.playCount}',
                          style: const TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                      ],
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}