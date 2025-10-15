import 'package:flutter/material.dart';
import '../models/song.dart';
import 'song_repository.dart';

class SongProvider with ChangeNotifier {
  final SongRepository _repository = SongRepository();
  List<Song> _songs = [];
  bool _isLoading = false;
  String _searchQuery = '';
  List<Song> _filteredSongs = [];

  List<Song> get songs => _filteredSongs;
  List<Song> get allSongs => _songs;
  bool get isLoading => _isLoading;
  String get searchQuery => _searchQuery;

  SongProvider() {
    _initializeData();
  }

  // ✅ CORREGIDO: Usar initializeWithDemoData() en lugar de addSampleSongs()
  Future<void> _initializeData() async {
    await _repository.initializeWithDemoData();
    await loadSongs();
  }

  // ✅ CORREGIDO: Usar getSongs() en lugar de getAllSongs()
  Future<void> loadSongs() async {
    _setLoading(true);
    try {
      _songs = await _repository.getSongs();
      _applySearchFilter();
      notifyListeners();
    } catch (e) {
      print('Error loading songs: $e');
      // Fallback to demo songs if there's an error
      _songs = _repository.getDemoSongs();
      _applySearchFilter();
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void searchSongs(String query) {
    _searchQuery = query;
    _applySearchFilter();
    notifyListeners();
  }

  void _applySearchFilter() {
    if (_searchQuery.isEmpty) {
      _filteredSongs = _songs;
    } else {
      final queryLower = _searchQuery.toLowerCase();
      _filteredSongs = _songs.where((song) {
        return song.title.toLowerCase().contains(queryLower) ||
               (song.artist != null && song.artist!.toLowerCase().contains(queryLower)) ||
               song.lyricsWithChords.toLowerCase().contains(queryLower) ||
               (song.notes != null && song.notes!.toLowerCase().contains(queryLower));
      }).toList();
    }
  }

  void clearSearch() {
    _searchQuery = '';
    _applySearchFilter();
    notifyListeners();
  }

  Future<void> addSong(Song song) async {
    _setLoading(true);
    try {
      await _repository.insertSong(song);
      await loadSongs(); // Reload to get the updated list
    } catch (e) {
      print('Error adding song: $e');
      // Add to local list as fallback
      final newId = (_songs.map((s) => s.id ?? 0).reduce((a, b) => a > b ? a : b)) + 1;
      final newSong = song.copyWith(id: newId);
      _songs.add(newSong);
      _applySearchFilter();
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> updateSong(Song song) async {
    _setLoading(true);
    try {
      await _repository.updateSong(song);
      await loadSongs(); // Reload to get the updated list
    } catch (e) {
      print('Error updating song: $e');
      // Update in local list as fallback
      final index = _songs.indexWhere((s) => s.id == song.id);
      if (index != -1) {
        _songs[index] = song;
        _applySearchFilter();
        notifyListeners();
      }
    } finally {
      _setLoading(false);
    }
  }

  Future<void> deleteSong(int songId) async {
    _setLoading(true);
    try {
      await _repository.deleteSong(songId);
      await loadSongs(); // Reload to get the updated list
    } catch (e) {
      print('Error deleting song: $e');
      // Remove from local list as fallback
      _songs.removeWhere((song) => song.id == songId);
      _applySearchFilter();
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> toggleFavorite(int songId) async {
    try {
      await _repository.toggleFavorite(songId);
      // Update local state immediately for better UX
      final index = _songs.indexWhere((song) => song.id == songId);
      if (index != -1) {
        final song = _songs[index];
        _songs[index] = song.copyWith(
          isFavorite: !song.isFavorite,
          modificationDate: DateTime.now(),
        );
        _applySearchFilter();
        notifyListeners();
      }
    } catch (e) {
      print('Error toggling favorite: $e');
    }
  }

  Future<void> incrementPlayCount(int songId) async {
    try {
      await _repository.incrementPlayCount(songId);
      // Update local state immediately for better UX
      final index = _songs.indexWhere((song) => song.id == songId);
      if (index != -1) {
        final song = _songs[index];
        _songs[index] = song.copyWith(
          playCount: song.playCount + 1,
          modificationDate: DateTime.now(),
        );
        notifyListeners();
      }
    } catch (e) {
      print('Error incrementing play count: $e');
    }
  }

  Future<List<Song>> getFavoriteSongs() async {
    try {
      return await _repository.getFavoriteSongs();
    } catch (e) {
      print('Error getting favorite songs: $e');
      return _songs.where((song) => song.isFavorite).toList();
    }
  }

  Future<List<Song>> searchSongsFromRepository(String query) async {
    try {
      return await _repository.searchSongs(query);
    } catch (e) {
      print('Error searching songs: $e');
      return _filteredSongs;
    }
  }

  Future<Song?> getSongById(int id) async {
    try {
      return await _repository.getSongById(id);
    } catch (e) {
      print('Error getting song by id: $e');
      return _songs.firstWhere((song) => song.id == id, orElse: () => _songs.first);
    }
  }

  Future<Map<String, int>> getStatistics() async {
    try {
      return await _repository.getStatistics();
    } catch (e) {
      print('Error getting statistics: $e');
      return {
        'totalSongs': _songs.length,
        'favoriteSongs': _songs.where((s) => s.isFavorite).length,
        'totalPlays': _songs.fold(0, (sum, song) => sum + song.playCount),
      };
    }
  }

  Future<List<Song>> getRecentlyPlayed({int limit = 5}) async {
    try {
      return await _repository.getRecentlyPlayed(limit: limit);
    } catch (e) {
      print('Error getting recently played: $e');
      _songs.sort((a, b) => b.playCount.compareTo(a.playCount));
      return _songs.take(limit).toList();
    }
  }

  Future<List<Song>> getNewestSongs({int limit = 5}) async {
    try {
      return await _repository.getNewestSongs(limit: limit);
    } catch (e) {
      print('Error getting newest songs: $e');
      _songs.sort((a, b) => b.creationDate.compareTo(a.creationDate));
      return _songs.take(limit).toList();
    }
  }

  // Method to force refresh data
  Future<void> refresh() async {
    await loadSongs();
  }

  // Method to check if songs are loaded
  bool get hasSongs => _songs.isNotEmpty;

  // Method to get song count
  int get songCount => _songs.length;

  // Method to get filtered song count
  int get filteredSongCount => _filteredSongs.length;
}