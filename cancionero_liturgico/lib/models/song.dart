class Song {
  final int? id;
  final String title;
  final String? artist;
  final String lyricsWithChords;
  final String originalKey;
  final int? tempoBpm;
  final int capoPosition;
  final bool isFavorite;
  final int playCount;
  final DateTime creationDate;
  final DateTime modificationDate;
  final String? notes;
  final List<String>? videoLinks;

  Song({
    this.id,
    required this.title,
    this.artist,
    required this.lyricsWithChords,
    required this.originalKey,
    this.tempoBpm,
    this.capoPosition = 0,
    this.isFavorite = false,
    this.playCount = 0,
    required this.creationDate,
    required this.modificationDate,
    this.notes,
    this.videoLinks,
  });

  // Copy with method for updates
  Song copyWith({
    int? id,
    String? title,
    String? artist,
    String? lyricsWithChords,
    String? originalKey,
    int? tempoBpm,
    int? capoPosition,
    bool? isFavorite,
    int? playCount,
    DateTime? creationDate,
    DateTime? modificationDate,
    String? notes,
    List<String>? videoLinks,
  }) {
    return Song(
      id: id ?? this.id,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      lyricsWithChords: lyricsWithChords ?? this.lyricsWithChords,
      originalKey: originalKey ?? this.originalKey,
      tempoBpm: tempoBpm ?? this.tempoBpm,
      capoPosition: capoPosition ?? this.capoPosition,
      isFavorite: isFavorite ?? this.isFavorite,
      playCount: playCount ?? this.playCount,
      creationDate: creationDate ?? this.creationDate,
      modificationDate: modificationDate ?? this.modificationDate,
      notes: notes ?? this.notes,
      videoLinks: videoLinks ?? this.videoLinks,
    );
  }

  // Convert to Map for database
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'artist': artist,
      'lyrics_with_chords': lyricsWithChords,
      'original_key': originalKey,
      'tempo_bpm': tempoBpm,
      'capo_position': capoPosition,
      'is_favorite': isFavorite ? 1 : 0,
      'play_count': playCount,
      'creation_date': creationDate.toIso8601String(),
      'modification_date': modificationDate.toIso8601String(),
      'notes': notes,
      'video_links': videoLinks != null ? videoLinks!.join('||') : null,
    };
  }

  // Create from Map from database
  factory Song.fromJson(Map<String, dynamic> json) {
    return Song(
      id: json['id'],
      title: json['title'],
      artist: json['artist'],
      lyricsWithChords: json['lyrics_with_chords'],
      originalKey: json['original_key'],
      tempoBpm: json['tempo_bpm'],
      capoPosition: json['capo_position'] ?? 0,
      isFavorite: json['is_favorite'] == 1,
      playCount: json['play_count'] ?? 0,
      creationDate: DateTime.parse(json['creation_date']),
      modificationDate: DateTime.parse(json['modification_date']),
      notes: json['notes'],
      videoLinks: json['video_links'] != null 
          ? (json['video_links'] as String).split('||')
          : null,
    );
  }

  @override
  String toString() {
    return 'Song{id: $id, title: $title, artist: $artist, originalKey: $originalKey, isFavorite: $isFavorite}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Song &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          title == other.title;

  @override
  int get hashCode => id.hashCode ^ title.hashCode;
}