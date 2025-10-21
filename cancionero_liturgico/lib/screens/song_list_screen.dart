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
  @override
  void initState() {
    super.initState();
    // SOLUCIÓN: Cargar las canciones en el SongProvider al inicializar la pantalla.
    // Esto asegura que el provider tenga la lista maestra.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<SongProvider>(context, listen: false).loadSongs(Provider.of<SongRepository>(context, listen: false));
    });
  }
  
  // MEJORA: Método para navegar y esperar resultado para refrescar la lista
  Future<void> _navigateAndRefreshSongs(Widget screen) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => screen),
    );
    // Al volver, recargar la lista de canciones.
    // Si se añadió/editó/eliminó una canción, recargar la lista maestra en el provider.
    if (result == true) {
      Provider.of<SongProvider>(context, listen: false).loadSongs(Provider.of<SongRepository>(context, listen: false));
    }
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
      Provider.of<SongProvider>(context, listen: false).loadSongs(Provider.of<SongRepository>(context, listen: false));
    }
  } // Fin del método _navigateAndRefreshSetlists

  @override
  Widget build(BuildContext context) {
    print("[SCREEN] Build: SongListScreen");
    // Escuchar al SongProvider para obtener la lista de canciones y reaccionar a cambios.
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
      body: Consumer<SongProvider>(
        builder: (context, songProvider, child) {
          if (songProvider.isLoadingSongs) {
            return const Center(child: CircularProgressIndicator());
          }

          final songs = widget.categoryId != null
              ? songProvider.songs.where((s) => s.categoryIds.contains(widget.categoryId)).toList()
              : songProvider.songs;

          if (songs.isEmpty) {
            return const Center(child: Text('No hay canciones disponibles.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            itemCount: songs.length,
            itemBuilder: (context, index) {
              return SongItem(
                song: songs[index],
                onTap: () {
                  songProvider.setSelectedSong(songs[index]);
                  _navigateAndRefreshSongs(SongDetailScreen(song: songs[index]));
                },
                onLongPress: () {
                  _navigateAndRefreshSongs(SongEditScreen(song: songs[index]));
                },
              );
            },
          );
        },
      ),
    );
  }
}