import 'package:cancionero_liturgico/models/song.dart';


class Setlist {
  final int? id;
  final String name;
  final DateTime creationDate; // Nuevo campo, según modelo de datos
  final DateTime modificationDate; // Nuevo campo, según modelo de datos
  final DateTime? eventDate; // Nuevo campo opcional
  final String? notes; // Nuevo campo opcional
  final List<SetlistItem> songs; // Ahora usa el SetlistItem actualizado

  Setlist({
    this.id,
    required this.name,
    required this.creationDate, // Debe ser provisto
    required this.modificationDate, // Debe ser provisto
    this.eventDate, // Puede ser nulo
    this.notes, // Puede ser nulo
    required this.songs, // Ahora incluye SetlistItem con transposición/capo
  });

  Setlist copyWith({
    int? id,
    String? name,
    DateTime? creationDate,
    DateTime? modificationDate,
    DateTime? eventDate,
    String? notes,
    List<SetlistItem>? songs,
  }) {
    return Setlist(
      id: id ?? this.id,
      name: name ?? this.name,
      creationDate: creationDate ?? this.creationDate,
      modificationDate: modificationDate ?? this.modificationDate,
      eventDate: eventDate ?? this.eventDate,
      notes: notes ?? this.notes,
      songs: songs ?? this.songs,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nombre': name,
      'fecha_evento': eventDate?.toIso8601String(), // Almacenar como string ISO o null
      'notas': notes,
      'fecha_creacion': creationDate.toIso8601String(), // Almacenar como string ISO
      'fecha_modificacion': modificationDate.toIso8601String(), // Almacenar como string ISO
    };
  }

  factory Setlist.fromMap(Map<String, dynamic> map) {
    return Setlist(
      id: map['id'] != null ? map['id'] as int : null,
      name: map['nombre'] as String,
      eventDate: map['fecha_evento'] != null ? DateTime.parse(map['fecha_evento'] as String) : null, // Parsear desde string ISO o null
      notes: map['notas'] as String?,
      creationDate: DateTime.parse(map['fecha_creacion'] as String), // Parsear desde string ISO
      modificationDate: DateTime.parse(map['fecha_modificacion'] as String), // Parsear desde string ISO
      songs: [], // Inicialmente vacío, se carga por separado o se construye externamente
    );
  }
}

// UNIFICACIÓN: La clase SetlistItem se mueve aquí desde setlist.dart
class SetlistItem {
  final Song song;
  final int order;
  final int transposition; // Nuevo campo, transposición personalizada en semitonos
  final int? capo;         // Nuevo campo, capo personalizado (puede ser nulo si no se usa)

  SetlistItem({
    required this.song,
    required this.order,
    this.transposition = 0, // Valor por defecto
    this.capo,              // Valor por defecto nulo
  });

  SetlistItem copyWith({
    Song? song,
    int? order,
    int? transposition,
    int? capo,
  }) {
    return SetlistItem(
      song: song ?? this.song,
      order: order ?? this.order,
      transposition: transposition ?? this.transposition,
      capo: capo ?? this.capo,
    );
  }
}