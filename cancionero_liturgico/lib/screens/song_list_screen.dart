import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cancionero_liturgico/models/song.dart';
import 'package:cancionero_liturgico/services/song_provider.dart';
import 'package:cancionero_liturgico/services/song_repository.dart';
import 'package:cancionero_liturgico/screens/song_detail_screen.dart';
import 'package:cancionero_liturgico/screens/song_edit_screen.dart';
import 'package:cancionero_liturgico/widgets/song_item.dart';
import 'package:cancionero_liturgico/screens/setlist_management_screen.dart'; // Importar la pantalla de gestión de setlists
import 'package:cancionero_liturgico/widgets/song_search_delegate.dart';
import 'package:cancionero_liturgico/services/category_repository.dart'; // Añadir esta línea

class SongListScreen extends StatefulWidget {
  final int? categoryId; // Si es null, mostrar todas las canciones o aplicar filtros

  const SongListScreen({super.key, this.categoryId});

  @override
  State<SongListScreen> createState() => _SongListScreenState();
}

class _SongListScreenState extends State<SongListScreen> {
  // SOLUCIÓN: Usar una key para forzar la reconstrucción del FutureBuilder
  int _futureBuilderKey = 0;

  @override
  void initState() {
    super.initState();
  }

  void _loadSongs() {
    // SOLUCIÓN: Simplemente incrementamos la key. Esto hará que el FutureBuilder
    // se reconstruya y vuelva a llamar a su `future`.
    setState(() => _futureBuilderKey++);
  }

  // MEJORA: Método para navegar y esperar resultado para refrescar la lista
  Future<void> _navigateAndRefreshSongs(Widget screen) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => screen),
    );
    // Al volver, recargar la lista de canciones.
    // El 'result' podría usarse si la pantalla de edición devolviera un valor.
    _loadSongs();
  }

  // Lógica similar para la gestión de setlists.
  // NOTA: Este es un ejemplo de cómo se implementaría en la pantalla de lista de setlists.
  Future<void> _navigateAndRefreshSetlists(Widget screen) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => screen),
    );

    // Si la pantalla de gestión devuelve 'true', significa que se guardó algo.
    if (result == true) {
    _loadSongs();
    }
  } // Fin del método _navigateAndRefreshSetlists

  @override
  Widget build(BuildContext context) {
    print("[SCREEN] Build: SongListScreen");
    final songRepository = Provider.of<SongRepository>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.categoryId != null ? 'Canciones' : 'Todas las Canciones'),
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
                // Usamos el nuevo método para que si hay cambios (ej. favoritos) se reflejen
                _navigateAndRefreshSongs(SongDetailScreen(song: selectedSong));
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              // Para crear una nueva canción, se navega a SongEditScreen sin pasarle una canción.
              _navigateAndRefreshSongs(SongEditScreen());
            },
          ),
        ],
      ),
      body: FutureBuilder<List<Song>>(
              // SOLUCIÓN: Usar la key y definir el future directamente aquí.
              key: ValueKey(_futureBuilderKey),
              future: widget.categoryId != null
                  ? songRepository.getSongsByCategory(widget.categoryId!)
                  : songRepository.getAllSongs(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                } else {
                  final songs = snapshot.data ?? [];
                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    itemCount: songs.length,
                    itemBuilder: (context, index) {
                      final song = songs[index];
                      return ListTile(
                        key: ValueKey(song.id),
                        leading: CircleAvatar(
                          child: Text('${index + 1}'),
                        ),
                        title: Text(song.title),
                        subtitle: Text(song.author ?? 'Autor desconocido'),
                        onTap: () {
                          // SOLUCIÓN: No es necesario establecer la canción en el provider aquí.
                          // SongDetailScreen la recibirá a través del constructor (widget.song).
                          // Y usamos el método que refresca la lista al volver.
                          _navigateAndRefreshSongs(SongDetailScreen(song: song)); // CORRECCIÓN: Usar el método que refresca
                        },
                        onLongPress: () {
                          _navigateAndRefreshSongs(SongEditScreen(song: song));
                        },
                      );
                    },
                  );
                }
              },
            ),
    );
  }
}