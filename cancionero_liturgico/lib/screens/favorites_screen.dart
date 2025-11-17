import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cancionero_liturgico/models/song.dart';
import 'package:cancionero_liturgico/services/song_repository.dart';
import 'package:cancionero_liturgico/screens/song_detail_screen.dart';
import 'package:cancionero_liturgico/widgets/song_item.dart';
import 'package:cancionero_liturgico/services/song_provider.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({Key? key}) : super(key: key);

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  @override
  void initState() {
    super.initState();
    // SOLUCIÓN: Cargar las canciones en el SongProvider al inicializar la pantalla.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<SongProvider>(context, listen: false).loadSongs(Provider.of<SongRepository>(context, listen: false));
    });
  }

  @override
  Widget build(BuildContext context) {
    // Escuchar al SongProvider para obtener la lista de canciones favoritas y reaccionar a cambios.
    final songProvider = Provider.of<SongProvider>(context, listen: true);
    final List<Song> favoriteSongs = songProvider.favoriteSongs;

    return Scaffold(
      appBar: AppBar(title: const Text('Canciones más frecuentes')),
      body: Consumer<SongProvider>(
        builder: (context, songProvider, child) {
          if (songProvider.isLoadingSongs) {
            return const Center(child: CircularProgressIndicator());
          }
          final favoriteSongs = songProvider.favoriteSongs;
          if (favoriteSongs.isEmpty) {
            return const Center(child: Text('No hay canciones favoritas.'));
          }
          return ListView.builder(
            itemCount: favoriteSongs.length,
            itemBuilder: (context, index) {
              final song = favoriteSongs[index];
              return SongItem(
                song: song,
                onTap: () {
                  songProvider.setSelectedSong(song);
                  Navigator.push(context, MaterialPageRoute(builder: (context) => SongDetailScreen(song: song)));
                },
              );
            },
          );
        },
      ),
    );
  }
}