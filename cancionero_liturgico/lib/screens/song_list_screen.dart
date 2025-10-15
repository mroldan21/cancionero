import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/song.dart';  // ← AGREGAR ESTA IMPORTACIÓN
import '../services/song_provider.dart';
import '../widgets/song_item.dart';
import 'song_edit_screen.dart';
import 'song_detail_screen.dart';

class SongListScreen extends StatefulWidget {
  const SongListScreen({super.key});

  @override
  State<SongListScreen> createState() => _SongListScreenState();
}

class _SongListScreenState extends State<SongListScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Song> _displayedSongs = [];  // ← Especificar tipo Song

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_filterSongs);
  }

  void _filterSongs() {
    final query = _searchController.text;
    final songProvider = Provider.of<SongProvider>(context, listen: false);
    
    if (query.isEmpty) {
      setState(() {
        _displayedSongs = songProvider.songs;
      });
    } else {
      songProvider.searchSongs(query).then((results) {
        setState(() {
          _displayedSongs = results;
        });
      });
    }
  }

  void _addSong() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SongEditScreen()),
    );
  }

  void _viewSong(Song song) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => SongDetailScreen(song: song)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Canciones Litúrgicas'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _addSong,
          ),
        ],
      ),
      body: Consumer<SongProvider>(
        builder: (context, songProvider, child) {
          if (_displayedSongs.isEmpty && _searchController.text.isEmpty) {
            _displayedSongs = songProvider.songs;
          }
          
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextField(
                  controller: _searchController,
                  decoration: const InputDecoration(
                    labelText: 'Buscar canciones...',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              Expanded(
                child: _displayedSongs.isEmpty
                    ? const Center(
                        child: Text('No hay canciones. ¡Agrega la primera!'),
                      )
                    : ListView.builder(
                        itemCount: _displayedSongs.length,
                        itemBuilder: (context, index) {
                          final song = _displayedSongs[index];
                          return SongItem(
                            song: song,
                            onTap: () => _viewSong(song),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addSong,
        child: const Icon(Icons.add),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}