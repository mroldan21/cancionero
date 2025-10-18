import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cancionero_liturgico/models/song.dart';
import 'package:cancionero_liturgico/services/song_provider.dart';
import 'package:cancionero_liturgico/services/song_repository.dart';
import 'package:cancionero_liturgico/screens/song_detail_screen.dart';
import 'package:cancionero_liturgico/screens/song_edit_screen.dart';
import 'package:cancionero_liturgico/widgets/song_item.dart';
import 'package:cancionero_liturgico/services/category_repository.dart'; // Añadir esta línea

class SongListScreen extends StatelessWidget {
  final int? categoryId; // Si es null, mostrar todas las canciones o aplicar filtros

  const SongListScreen({super.key, this.categoryId});

  @override
  Widget build(BuildContext context) {
    print("[SCREEN] Build: SongListScreen");
    final songRepository = Provider.of<SongRepository>(context, listen: false);
    final categoryRepository = Provider.of<CategoryRepository>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: Text(categoryId != null ? 'Canciones' : 'Todas las Canciones'),
        actions: [
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
      body: Column(
        children: [
          // Campo de búsqueda
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              onChanged: (query) {
                // Manejar búsqueda en tiempo real aquí o en un widget separado
                // Actualizar la lista de canciones mostradas
              },
              decoration: const InputDecoration(
                hintText: 'Buscar canciones...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
            ),
          ),
          // Lista de canciones
          Expanded(
            child: FutureBuilder<List<Song>>(
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
                      final song = songs[index];
                      return SongItem(
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
                      );
                    },
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}