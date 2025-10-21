import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cancionero_liturgico/models/song.dart';
import 'package:cancionero_liturgico/services/song_repository.dart';
import 'package:cancionero_liturgico/screens/song_detail_screen.dart';
import 'package:cancionero_liturgico/widgets/song_item.dart';
import 'package:cancionero_liturgico/services/song_provider.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  late Future<List<Song>> _favoritesFuture;

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  void _loadFavorites() {
    setState(() {
      _favoritesFuture = Provider.of<SongRepository>(context, listen: false).getFavoriteSongs();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Canciones más frecuentes')),
      body: FutureBuilder<List<Song>>(
        future: _favoritesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else {
            final songs = snapshot.data ?? [];
            if (songs.isEmpty) {
              return const Center(child: Text('No hay canciones favoritas.'));
            }
            return ListView.builder(
              itemCount: songs.length,
              itemBuilder: (context, index) {
                final song = songs[index];
                return SongItem(
                  song: song,
                  onTap: () {
                    // Limpiar el estado anterior antes de navegar
                    Provider.of<SongProvider>(context, listen: false).clearSelectedSong();
                    // Navegar y esperar un resultado booleano
                    Navigator.push<bool>(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SongDetailScreen(song: song),
                      ),
                    ).then((result) {
                      // Si la pantalla anterior devolvió 'true', recargar la lista.
                      if (result == true) {
                        _loadFavorites();
                      }
                    });
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