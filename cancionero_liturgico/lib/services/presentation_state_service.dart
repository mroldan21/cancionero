import 'package:flutter/foundation.dart';
import 'package:cancionero_liturgico/models/song.dart';
import 'package:cancionero_liturgico/services/song_repository.dart';
import 'package:cancionero_liturgico/services/transposition_service.dart';

/// Representa los ajustes de presentación para una canción.
class PresentationSettings {
  final int transposition;
  final int capo;

  PresentationSettings({this.transposition = 0, this.capo = 0});

  PresentationSettings copyWith({int? transposition, int? capo}) {
    return PresentationSettings(
      transposition: transposition ?? this.transposition,
      capo: capo ?? this.capo,
    );
  }
}

/// Servicio para gestionar el estado temporal de los ajustes de presentación.
class PresentationStateService with ChangeNotifier {
  final SongRepository _songRepository;
  final Map<int, PresentationSettings> _settingsCache = {};

  PresentationStateService(this._songRepository);

  /// Obtiene los ajustes para una canción, desde el caché o los valores por defecto.
  PresentationSettings getSettingsForSong(Song song) {
    return _settingsCache[song.id] ?? PresentationSettings(capo: song.capoPosition);
  }

  /// Actualiza los ajustes de una canción en el caché.
  void updateSettings(Song song, PresentationSettings settings) {
    if (song.id == null) return;
    _settingsCache[song.id!] = settings;
    // No es necesario notificar a los listeners a menos que una UI
    // global dependa de estos cambios en tiempo real.
  }

  /// Indica si hay modificaciones pendientes de guardar.
  bool get hasModifications => _settingsCache.isNotEmpty;

  /// Guarda permanentemente los ajustes cacheados en la base de datos.
  Future<void> saveAllModifications() async {
    if (!hasModifications) return;

    for (final entry in _settingsCache.entries) {
      final songId = entry.key;
      final settings = entry.value;

      final originalSong = await _songRepository.getSongById(songId);
      if (originalSong != null) {
        final newContent = TranspositionService.transposeContent(originalSong.content, settings.transposition);
        final newKey = TranspositionService.getTransposedOriginalKey(originalSong.originalKey, settings.transposition);

        // MEJORA: Reemplazar copyWith por la creación de una nueva instancia de Song
        final updatedSong = Song(
          id: originalSong.id,
          title: originalSong.title,
          author: originalSong.author,
          content: newContent, // Contenido actualizado
          originalKey: newKey, // Tonalidad actualizada
          capoPosition: settings.capo, // Capo actualizado
          tempoBpm: originalSong.tempoBpm,
          isFavorite: originalSong.isFavorite,
          playCount: originalSong.playCount,
          creationDate: originalSong.creationDate,
          modificationDate: DateTime.now(), // Actualizar fecha de modificación
          notes: originalSong.notes,
          videoLinks: originalSong.videoLinks,
        );
        await _songRepository.updateSong(updatedSong);
      }
    }
    _settingsCache.clear();
    notifyListeners(); // Notificar que ya no hay modificaciones.
  }
}