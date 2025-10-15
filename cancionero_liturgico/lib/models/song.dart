class Song {
  int? id;
  String title;
  String artist;
  String lyricsWithChords;
  String originalKey;
  int? tempoBpm;
  int capoPosition;
  bool isFavorite;
  DateTime createdAt;
  DateTime updatedAt;

  Song({
    this.id,
    required this.title,
    this.artist = '',
    required this.lyricsWithChords,
    this.originalKey = 'C',
    this.tempoBpm,
    this.capoPosition = 0,
    this.isFavorite = false,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'artist': artist,
      'lyricsWithChords': lyricsWithChords,
      'originalKey': originalKey,
      'tempoBpm': tempoBpm,
      'capoPosition': capoPosition,
      'isFavorite': isFavorite ? 1 : 0,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
    };
  }

  factory Song.fromMap(Map<String, dynamic> map) {
    return Song(
      id: map['id'],
      title: map['title'],
      artist: map['artist'],
      lyricsWithChords: map['lyricsWithChords'],
      originalKey: map['originalKey'],
      tempoBpm: map['tempoBpm'],
      capoPosition: map['capoPosition'],
      isFavorite: map['isFavorite'] == 1,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt']),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updatedAt']),
    );
  }
}