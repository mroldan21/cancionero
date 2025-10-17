// ... (mismas constantes y mapeos que antes) ...

class TranspositionService {
  static const List<String> _notes = [
    'C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B'
  ];

  // Mapeo para convertir bemoles a sostenidos (simplifica cálculos)
  static const Map<String, String> _flatEquivalents = {
    'Db': 'C#',
    'Eb': 'D#',
    'Gb': 'F#',
    'Ab': 'G#',
    'Bb': 'A#',
  };

  // Mapeo inverso para convertir sostenidos a bemoles si es necesario (opcional, para mostrar)
  static const Map<String, String> _sharpEquivalents = {
    'C#': 'Db',
    'D#': 'Eb',
    'F#': 'Gb',
    'G#': 'Ab',
    'A#': 'Bb',
  };

  /// Transpone un acorde simple un número dado de semitonos.
  /// Maneja notación americana (C, D, E, F, G, A, B) y modificadores (#, b).
  /// Devuelve el acorde original si no se puede parsear.
  static String transposeChord(String chord, int semitones) {
    if (semitones == 0) return chord;

    // Separar el acorde en nota base, modificador y sufijo (m, 7, sus4, etc.)
    // El patrón busca: NotaBase (opcionalmente # o b), seguido de cualquier cosa.
    final match = RegExp(r'^([A-G][b#]?)(.*)').firstMatch(chord);
    if (match == null) return chord; // Si no es un acorde reconocible, devolverlo igual

    String note = match.group(1)!;
    String suffix = match.group(2)!;

    // Convertir bemoles a sostenidos para facilitar el cálculo cromático
    note = _flatEquivalents[note] ?? note;

    // Encontrar índice de la nota base
    int index = _notes.indexOf(note);
    if (index == -1) return chord; // Si no se encuentra la nota base, devolverlo igual

    // Calcular nuevo índice con transposición
    // El módulo % 12 asegura que el índice esté entre 0 y 11
    // El +12 antes del % evita índices negativos si semitones es negativo
    int newIndex = (index + semitones + 12) % 12;

    // Opcional: Convertir sostenidos de vuelta a bemoles según preferencia
    // Por ahora, devolvemos sostenidos. Se podría hacer configurable.
    return _notes[newIndex] + suffix;
  }

  /// Transpone el contenido de la letra de una canción.
  /// Busca acordes simples y los transpone usando [transposeChord].
  /// Asume que los acordes están claramente separados o sobre el texto.
  static String transposeContent(String content, int semitones) {
    if (semitones == 0) return content;

    // Expresión regular para encontrar acordes simples.
    // Asume: Letra mayúscula (A-G), opcionalmente # o b, seguido de caracteres comunes en acordes.
    // Este patrón puede necesitar ajustes para acordes muy complejos o no estándar.
    final chordRegex = RegExp(r'\b[A-G][b#]?(m|7|9|11|13|maj7|m7|sus2|sus4|dim|aug|add\d+)?\b', caseSensitive: false);

    return content.replaceAllMapped(chordRegex, (match) {
      String chord = match.group(0)!;
      // Devuelve el acorde transpuesto, manteniendo el match original si no es un acorde simple
      return transposeChord(chord, semitones);
    });
  }

  /// Calcula la nueva tonalidad original transpuesta.
  static String getTransposedOriginalKey(String originalKey, int semitones) {
     return transposeChord(originalKey, semitones);
  }
}