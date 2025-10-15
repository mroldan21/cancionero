import 'package:flutter/material.dart';
import '../models/song.dart';
import '../services/song_repository.dart';
import 'song_edit_screen.dart';
import 'presentation_mode_screen.dart';

class SongDetailScreen extends StatefulWidget {
  final Song song;

  const SongDetailScreen({Key? key, required this.song}) : super(key: key);

  @override
  State<SongDetailScreen> createState() => _SongDetailScreenState();
}

class _SongDetailScreenState extends State<SongDetailScreen> {
  final SongRepository _songRepository = SongRepository();
  late Song _currentSong;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _currentSong = widget.song;
    _incrementPlayCount();
  }

  void _incrementPlayCount() async {
    await _songRepository.incrementPlayCount(_currentSong.id!);
    // Refresh song data to get updated play count
    final updatedSong = await _songRepository.getSongById(_currentSong.id!);
    if (updatedSong != null && mounted) {
      setState(() {
        _currentSong = updatedSong;
      });
    }
  }

  void _toggleFavorite() async {
    setState(() {
      _isLoading = true;
    });
    
    await _songRepository.toggleFavorite(_currentSong.id!);
    
    // Refresh song data
    final updatedSong = await _songRepository.getSongById(_currentSong.id!);
    if (updatedSong != null && mounted) {
      setState(() {
        _currentSong = updatedSong;
        _isLoading = false;
      });
    }
  }

  void _editSong() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SongEditScreen(song: _currentSong),
      ),
    ).then((result) {
      if (result == true && mounted) {
        // Refresh song data after editing
        _refreshSong();
      }
    });
  }

  void _refreshSong() async {
    final updatedSong = await _songRepository.getSongById(_currentSong.id!);
    if (updatedSong != null && mounted) {
      setState(() {
        _currentSong = updatedSong;
      });
    }
  }

  void _openPresentationMode() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PresentationModeScreen(song: _currentSong),
      ),
    );
  }

  void _deleteSong() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Song'),
        content: Text('Are you sure you want to delete "${_currentSong.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              setState(() {
                _isLoading = true;
              });
              
              try {
                await _songRepository.deleteSong(_currentSong.id!);
                if (mounted) {
                  Navigator.pop(context); // Go back to previous screen
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('"${_currentSong.title}" deleted successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  setState(() {
                    _isLoading = false;
                  });
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_currentSong.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.slideshow),
            onPressed: _openPresentationMode,
            tooltip: 'Presentation Mode',
          ),
          IconButton(
            icon: Icon(
              _currentSong.isFavorite ? Icons.favorite : Icons.favorite_border,
              color: _currentSong.isFavorite ? Colors.red : null,
            ),
            onPressed: _isLoading ? null : _toggleFavorite,
            tooltip: _currentSong.isFavorite ? 'Remove from favorites' : 'Add to favorites',
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'edit') {
                _editSong();
              } else if (value == 'delete') {
                _deleteSong();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'edit', child: Text('Edit')),
              const PopupMenuItem(value: 'delete', child: Text('Delete')),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Song Header
                  _buildSongHeader(),
                  const SizedBox(height: 24),
                  
                  // Song Info
                  _buildSongInfo(),
                  const SizedBox(height: 24),
                  
                  // Lyrics with Chords
                  _buildLyricsSection(),
                  const SizedBox(height: 24),
                  
                  // Additional Info
                  _buildAdditionalInfo(),
                ],
              ),
            ),
    );
  }

  Widget _buildSongHeader() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _currentSong.title,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (_currentSong.artist != null && _currentSong.artist!.isNotEmpty) // ✅ CORREGIDO: Null check
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'by ${_currentSong.artist!}', // ✅ CORREGIDO: Null assertion
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSongInfo() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Wrap(
          spacing: 20,
          runSpacing: 10,
          children: [
            _buildInfoItem('Key', _currentSong.originalKey),
            _buildInfoItem('Capo', '${_currentSong.capoPosition}'),
            if (_currentSong.tempoBpm != null)
              _buildInfoItem('Tempo', '${_currentSong.tempoBpm} BPM'),
            _buildInfoItem('Plays', '${_currentSong.playCount}'),
            _buildInfoItem('Favorite', _currentSong.isFavorite ? 'Yes' : 'No'),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildLyricsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Lyrics with Chords',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Text(
                _currentSong.lyricsWithChords,
                style: const TextStyle(
                  fontSize: 14,
                  fontFamily: 'Monospace',
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdditionalInfo() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Additional Information',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            if (_currentSong.notes != null && _currentSong.notes!.isNotEmpty) // ✅ CORREGIDO: Null check
              _buildAdditionalInfoItem('Notes', _currentSong.notes!),
            if (_currentSong.videoLinks != null && _currentSong.videoLinks!.isNotEmpty) // ✅ CORREGIDO: Null check
              _buildAdditionalInfoItem('Video Links', _currentSong.videoLinks!.join('\n')),
            _buildAdditionalInfoItem('Created', _formatDate(_currentSong.creationDate)),
            _buildAdditionalInfoItem('Modified', _formatDate(_currentSong.modificationDate)),
          ],
        ),
      ),
    );
  }

  Widget _buildAdditionalInfoItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.grey,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontSize: 14),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}