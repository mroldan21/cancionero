import 'package:cancionero_liturgico/models/setlist.dart'; // Importa el SetlistItem actualizado
//import 'package:cancionero_liturgico/models/song.dart'; // Importa Song para el factory si es necesario

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