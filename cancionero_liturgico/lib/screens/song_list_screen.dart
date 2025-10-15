import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/song.dart';
import '../services/database_helper.dart';
import 'song_edit_screen.dart';
import 'presentation_mode_screen.dart';

class SongListScreen extends StatefulWidget {
  const SongListScreen({Key? key}) : super(key: key);

  @override
  State<SongListScreen> createState() => _SongListScreenState();
}

class _SongListScreenState extends State<SongListScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  List<Song> _songs = [];
  List<Song> _filteredSongs = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadSongs();
  }

  Future<void> _loadSongs() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      _songs = await _dbHelper.getSongs();
      _filteredSongs = _songs;
    } catch (e) {
      print("Error loading songs: $e");
      // Show error message to user
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading songs: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _searchSongs(String query) {
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _filteredSongs = _songs;
      } else {
        _filteredSongs = _songs.where((song) {
          final title = song.title.toLowerCase();
          final artist = song.artist?.toLowerCase() ?? '';
          final searchLower = query.toLowerCase();
          return title.contains(searchLower) || artist.contains(searchLower);
        }).toList();
      }
    });
  }

  void _addNewSong() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SongEditScreen(),
      ),
    ).then((_) => _loadSongs());
  }

  void _editSong(Song song) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SongEditScreen(song: song),
      ),
    ).then((_) => _loadSongs());
  }

  void _deleteSong(Song song) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Song'),
        content: Text('Are you sure you want to delete "${song.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await _dbHelper.deleteSong(song.id!);
                await _loadSongs();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('"${song.title}" deleted successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error deleting song: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _openPresentationMode(Song song) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PresentationModeScreen(song: song),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Songs'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _addNewSong,
            tooltip: 'Add New Song',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Search songs...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: _searchSongs,
            ),
          ),
          // Songs List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredSongs.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.music_note,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _searchQuery.isEmpty
                                  ? 'No songs yet\nTap + to add your first song'
                                  : 'No songs found for "$_searchQuery"',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: _filteredSongs.length,
                        itemBuilder: (context, index) {
                          final song = _filteredSongs[index];
                          return _buildSongCard(song);
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addNewSong,
        child: const Icon(Icons.add),
        tooltip: 'Add New Song',
      ),
    );
  }

  Widget _buildSongCard(Song song) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: const Icon(Icons.music_note),
        title: Text(
          song.title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: song.artist != null ? Text(song.artist!) : null,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Presentation Mode Button
            IconButton(
              icon: const Icon(Icons.slideshow),
              onPressed: () => _openPresentationMode(song),
              tooltip: 'Presentation Mode',
              color: Colors.blue,
            ),
            // Favorite Indicator
            if (song.isFavorite)
              const Icon(Icons.favorite, color: Colors.red, size: 20),
            // More Options
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'edit') {
                  _editSong(song);
                } else if (value == 'delete') {
                  _deleteSong(song);
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'edit', child: Text('Edit')),
                const PopupMenuItem(value: 'delete', child: Text('Delete')),
              ],
            ),
          ],
        ),
        onTap: () => _editSong(song),
      ),
    );
  }
}