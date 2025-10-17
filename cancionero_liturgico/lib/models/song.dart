class Song {
  final int? id;
  final String title;
  final String? author; // Nuevo campo
  final String content; // Anteriormente 'content', ahora contendrá la versión transpuesta
  final String originalKey; // Anteriormente no existía, ahora 'tonalidad_original'
  final int? tempoBpm; // Nuevo campo
  final int capoPosition; // Anteriormente no existía, ahora 'posicion_capo' con valor por defecto
  final bool isFavorite; // Nuevo campo, con valor por defecto
  final int playCount; // Nuevo campo, con valor por defecto
  final DateTime creationDate; // Nuevo campo
  final DateTime modificationDate; // Nuevo campo
  final String? notes; // Nuevo campo
  final List<String>? videoLinks; // Nuevo campo, almacenado como JSON

  Song({
    this.id,
    required this.title,
    this.author, // Puede ser nulo
    required this.content, // Ahora contendrá la versión transpuesta
    required this.originalKey, // Anteriormente no existía
    this.tempoBpm, // Puede ser nulo
    this.capoPosition = 0, // Valor por defecto
    this.isFavorite = false, // Valor por defecto
    this.playCount = 0, // Valor por defecto
    required this.creationDate, // Debe ser provisto
    required this.modificationDate, // Debe ser provisto
    this.notes, // Puede ser nulo
    this.videoLinks, // Puede ser nulo
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'titulo': title, // Cambiado de 'title' a 'titulo'
      'autor': author,
      'letra_con_acordes': content, // Ahora refleja la versión transpuesta
      'tonalidad_original': originalKey,
      'tempo_bpm': tempoBpm,
      'posicion_capo': capoPosition,
      'es_favorita': isFavorite ? 1 : 0, // SQLite no tiene booleano nativo
      'contador_reproducciones': playCount,
      'fecha_creacion': creationDate.toIso8601String(), // Almacenar como string ISO
      'fecha_modificacion': modificationDate.toIso8601String(), // Almacenar como string ISO
      'notas': notes,
      'enlaces_video': videoLinks != null ? videoLinks!.join(',') : null, // Almacenar como string CSV
    };
  }

  // Ajuste en el factory para manejar los nuevos campos
  factory Song.fromMap(Map<String, dynamic> map) {
    return Song(
      id: map['id'] != null ? map['id'] as int : null,
      title: map['titulo'] as String, // Cambiado de 'title' a 'titulo'
      author: map['autor'] as String?,
      content: map['letra_con_acordes'] as String, // Ahora refleja la versión transpuesta
      originalKey: map['tonalidad_original'] as String,
      tempoBpm: map['tempo_bpm'] as int?,
      capoPosition: map['posicion_capo'] as int? ?? 0,
      isFavorite: (map['es_favorita'] as int? ?? 0) == 1,
      playCount: map['contador_reproducciones'] as int? ?? 0,
      creationDate: DateTime.parse(map['fecha_creacion'] as String), // Parsear desde string ISO
      modificationDate: DateTime.parse(map['fecha_modificacion'] as String), // Parsear desde string ISO
      notes: map['notas'] as String?,
      videoLinks: (map['enlaces_video'] as String?)?.split(',').where((link) => link.isNotEmpty).toList(), // Parsear desde string CSV
    );
  }
}