class Song {
  final int? id;
  final String title;
  final String? author;
  final String content;
  final String originalKey;
  final int? tempoBpm;
  final int capoPosition;
  final bool isFavorite;
  final int playCount;
  final DateTime creationDate;
  final DateTime modificationDate;
  final String? notes;
  final List<String>? videoLinks;
  final double? preferredFontSize;

  Song({
    this.id,
    required this.title,
    this.author,
    required this.content,
    required this.originalKey,
    this.tempoBpm,
    this.capoPosition = 0,
    this.isFavorite = false,
    this.playCount = 0,
    required this.creationDate,
    required this.modificationDate,
    this.notes,
    this.videoLinks,
    this.preferredFontSize,
  });

  factory Song.fromMap(Map<String, dynamic> map) {
    return Song(
      id: map['id'],
      title: map['titulo'],
      author: map['autor'],
      content: map['letra_con_acordes'],
      originalKey: map['tonalidad_original'],
      tempoBpm: map['tempo_bpm'],
      capoPosition: map['posicion_capo'] ?? 0,
      isFavorite: map['es_favorita'] == 1,
      playCount: map['contador_reproducciones'] ?? 0,
      creationDate: DateTime.parse(map['fecha_creacion']),
      modificationDate: DateTime.parse(map['fecha_modificacion']),
      notes: map['notas'],
      videoLinks: (map['enlaces_video'] as String?)?.split(',').where((s) => s.trim().isNotEmpty).toList(),
      preferredFontSize: map['preferred_font_size'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'titulo': title,
      'autor': author,
      'letra_con_acordes': content,
      'tonalidad_original': originalKey,
      'tempo_bpm': tempoBpm,
      'posicion_capo': capoPosition,
      'es_favorita': isFavorite ? 1 : 0,
      'contador_reproducciones': playCount,
      'fecha_creacion': creationDate.toIso8601String(),
      'fecha_modificacion': modificationDate.toIso8601String(),
      'notas': notes,
      'enlaces_video': videoLinks?.join(','),
      'preferred_font_size': preferredFontSize,
    };
  }

  Song copyWith({
    int? id,
    String? title,
    String? author,
    String? content,
    String? originalKey,
    int? tempoBpm,
    int? capoPosition,
    bool? isFavorite,
    int? playCount,
    DateTime? creationDate,
    DateTime? modificationDate,
    String? notes,
    List<String>? videoLinks,
    double? preferredFontSize,
  }) {
    return Song(
      id: id ?? this.id,
      title: title ?? this.title,
      author: author ?? this.author,
      content: content ?? this.content,
      originalKey: originalKey ?? this.originalKey,
      tempoBpm: tempoBpm ?? this.tempoBpm,
      capoPosition: capoPosition ?? this.capoPosition,
      isFavorite: isFavorite ?? this.isFavorite,
      playCount: playCount ?? this.playCount,
      creationDate: creationDate ?? this.creationDate,
      modificationDate: modificationDate ?? this.modificationDate,
      notes: notes ?? this.notes,
      videoLinks: videoLinks ?? this.videoLinks,
      // SOLUCIÓN: Usar el nuevo valor si se proporciona, incluso si es null.
      // Para eso, necesitamos una forma de saber si el parámetro fue pasado.
      preferredFontSize: preferredFontSize,
    );
  }
}