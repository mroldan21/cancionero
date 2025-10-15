import 'song.dart'; // CAMBIAR de cancion_model.dart a song.dart

// ELIMINAR JSON SERIALIZATION TEMPORALMENTE
class Setlist {
  final int? id;
  final String name;
  final DateTime? eventDate;
  final String? notes;
  final DateTime creationDate;
  final DateTime modificationDate;

  Setlist({
    this.id,
    required this.name,
    this.eventDate,
    this.notes,
    required this.creationDate,
    required this.modificationDate,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'event_date': eventDate?.toIso8601String(),
      'notes': notes,
      'creation_date': creationDate.toIso8601String(),
      'modification_date': modificationDate.toIso8601String(),
    };
  }

  factory Setlist.fromJson(Map<String, dynamic> json) {
    return Setlist(
      id: json['id'],
      name: json['name'],
      eventDate: json['event_date'] != null 
          ? DateTime.parse(json['event_date'])
          : null,
      notes: json['notes'],
      creationDate: DateTime.parse(json['creation_date']),
      modificationDate: DateTime.parse(json['modification_date']),
    );
  }
}

class SetlistSong {
  final int? id;
  final int setlistId;
  final int songId;
  final int order;
  final int transpositionSemitones;
  final int? customCapo;

  SetlistSong({
    this.id,
    required this.setlistId,
    required this.songId,
    required this.order,
    this.transpositionSemitones = 0,
    this.customCapo,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'setlist_id': setlistId,
      'song_id': songId,
      'order_index': order,
      'transposition_semitones': transpositionSemitones,
      'custom_capo': customCapo,
    };
  }

  factory SetlistSong.fromJson(Map<String, dynamic> json) {
    return SetlistSong(
      id: json['id'],
      setlistId: json['setlist_id'],
      songId: json['song_id'],
      order: json['order_index'],
      transpositionSemitones: json['transposition_semitones'] ?? 0,
      customCapo: json['custom_capo'],
    );
  }
}