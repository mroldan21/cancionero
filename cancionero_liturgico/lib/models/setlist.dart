import 'song.dart';  // ← AGREGAR ESTA IMPORTACIÓN AL INICIO

class Setlist {
  int? id;
  String name;
  DateTime? eventDate;
  String notes;
  List<SetlistSong> songs;
  DateTime createdAt;
  DateTime updatedAt;

  Setlist({
    this.id,
    required this.name,
    this.eventDate,
    this.notes = '',
    required this.songs,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'eventDate': eventDate?.millisecondsSinceEpoch,
      'notes': notes,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
    };
  }

  factory Setlist.fromMap(Map<String, dynamic> map) {
    return Setlist(
      id: map['id'],
      name: map['name'],
      eventDate: map['eventDate'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(map['eventDate'])
          : null,
      notes: map['notes'],
      songs: [], // Se cargan por separado
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt']),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updatedAt']),
    );
  }

  int get songCount => songs.length;
  Duration get estimatedDuration {
    if (songs.isEmpty) return Duration.zero;
    final totalBpm = songs.fold(0, (sum, song) => sum + (song.song.tempoBpm ?? 120));
    final avgBpm = totalBpm / songs.length;
    final estimatedSeconds = (songs.length * 30); // 30 segundos por canción en promedio
    return Duration(seconds: estimatedSeconds);
  }
}

class SetlistSong {
  int? id;
  int setlistId;
  int songId;
  Song song;
  int order;
  int transposition;
  int? customCapo;

  SetlistSong({
    this.id,
    required this.setlistId,
    required this.songId,
    required this.song,
    required this.order,
    this.transposition = 0,
    this.customCapo,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'setlistId': setlistId,
      'songId': songId,
      'order': order,
      'transposition': transposition,
      'customCapo': customCapo,
    };
  }

  factory SetlistSong.fromMap(Map<String, dynamic> map, Song song) {
    return SetlistSong(
      id: map['id'],
      setlistId: map['setlistId'],
      songId: map['songId'],
      song: song,
      order: map['order'],
      transposition: map['transposition'],
      customCapo: map['customCapo'],
    );
  }
}