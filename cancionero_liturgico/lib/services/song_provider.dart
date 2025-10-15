import 'package:flutter/foundation.dart';
import '../models/song.dart';
import 'song_repository.dart';
import '../utils/transpose_helper.dart';

class SongProvider with ChangeNotifier {
  final SongRepository _repository = SongRepository();
  List<Song> _songs = [];
  int _transposition = 0;

  List<Song> get songs => _songs;
  int get transposition => _transposition;

  SongProvider() {
    _initializeData();
  }

  Future<void> _initializeData() async {
    await _repository.addSampleSongs(); // ← AGREGAR ESTA LÍNEA
    await loadSongs();
  }

  Future<void> loadSongs() async {
    _songs = await _repository.getAllSongs();
    notifyListeners();
  }

  Future<void> addSong(Song song) async {
    await _repository.insertSong(song);
    await loadSongs();
  }

  Future<void> updateSong(Song song) async {
    await _repository.updateSong(song);
    await loadSongs();
  }

  Future<void> deleteSong(int id) async {
    await _repository.deleteSong(id);
    await loadSongs();
  }

  Future<List<Song>> searchSongs(String query) async {
    if (query.isEmpty) {
      return _songs;
    }
    return await _repository.searchSongs(query);
  }

  // Transposición
  void transposeUp() {
    if (_transposition < 11) {
      _transposition++;
      notifyListeners();
    }
  }

  void transposeDown() {
    if (_transposition > -11) {
      _transposition--;
      notifyListeners();
    }
  }

  void resetTransposition() {
    _transposition = 0;
    notifyListeners();
  }

  String getTransposedLyrics(String originalLyrics) {
    return TransposeHelper.transposeLyrics(originalLyrics, _transposition);
  }

  String getCurrentKey(String originalKey) {
    if (_transposition == 0) return originalKey;
    return TransposeHelper.transposeChord(originalKey, _transposition);
  }
}