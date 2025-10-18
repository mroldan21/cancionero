import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cancionero_liturgico/models/song.dart';
import 'package:cancionero_liturgico/services/song_provider.dart';
import 'package:cancionero_liturgico/services/song_repository.dart';
import 'package:cancionero_liturgico/screens/song_detail_screen.dart';
import 'package:cancionero_liturgico/screens/song_edit_screen.dart';
import 'package:cancionero_liturgico/widgets/song_item.dart';
import 'package:cancionero_liturgico/widgets/song_search_delegate.dart';
import 'package:cancionero_liturgico/services/category_repository.dart'; // Añadir esta línea

class SongListScreen extends StatelessWidget {
  final int? categoryId; // Si es null, mostrar todas las canciones o aplicar filtros

  const SongListScreen({super.key, this.categoryId});

  @override
  Widget build(BuildContext context) {
    print("[SCREEN] Build: SongListScreen");
    final songRepository = Provider.of<SongRepository>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: Text(categoryId != null ? 'Canciones' : 'Todas las Canciones'),
        actions: [
          // MEJORA: Usar SearchDelegate para una mejor experiencia de búsqueda
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () async {
              final songs = await songRepository.getAllSongs();
              final selectedSong = await showSearch<Song?>(
                context: context,
                delegate: SongSearchDelegate(songs),
              );

              if (selectedSong != null && context.mounted) {
                Provider.of<SongProvider>(context, listen: false).setSelectedSong(selectedSong);
                Navigator.push(context, MaterialPageRoute(builder: (context) => SongDetailScreen(song: selectedSong)));
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SongEditScreen()),
              );
            },
          ),
        ],
      ),
      body: FutureBuilder<List<Song>>(
              future: categoryId != null
                  ? songRepository.getSongsByCategory(categoryId!)
                  : songRepository.getAllSongs(), // Por ahora, sin filtro de búsqueda activo
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                } else {
                  final songs = snapshot.data ?? [];
                  return ListView.builder(
                    itemCount: songs.length,
                    itemBuilder: (context, index) {
                      final song = songs[index];                      // MEJORA: Envolver con Semantics para accesibilidad
                      return Semantics(
                        label: 'Canción: ${song.title}, Tono: ${song.originalKey}',
                        hint: 'Toca para ver detalles, mantén presionado para editar.',
                        button: true,
                        child: SongItem(
                          key: ValueKey(song.id), // **MEJORA: Añadir Key para optimización de renderizado**
                          song: song,
                          onTap: () {
                            // **LA CORRECCIÓN: Establecer la canción seleccionada en el provider**
                            Provider.of<SongProvider>(context, listen: false).setSelectedSong(song);

                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => SongDetailScreen(song: song),
                              ),
                            );
                          },
                          onLongPress: () {
                            // Opción de edición en presión larga
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => SongEditScreen(song: song),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  );
                }
              },
            ),
    );
  }
}