class TransposeHelper {
  static const List<String> americanNotes = [
    'C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B'
  ];
  
  static const List<String> latinNotes = [
    'Do', 'Do#', 'Re', 'Re#', 'Mi', 'Fa', 'Fa#', 'Sol', 'Sol#', 'La', 'La#', 'Si'
  ];

  static String transposeChord(String chord, int semitones) {
    if (chord.isEmpty || semitones == 0) return chord;

    final parsed = _parseChord(chord);
    if (parsed == null) return chord;

    final (baseNote, modifier, extension) = parsed;
    
    // Determinar notación
    final bool isAmerican = americanNotes.any((note) => 
        note.toLowerCase() == baseNote.toLowerCase());
    final noteList = isAmerican ? americanNotes : latinNotes;

    // Encontrar índice actual
    final currentIndex = noteList.indexWhere((note) => 
        note.toLowerCase() == baseNote.toLowerCase());
    if (currentIndex == -1) return chord;

    // Calcular nuevo índice
    final newIndex = (currentIndex + semitones + noteList.length) % noteList.length;
    final newBaseNote = noteList[newIndex];

    return newBaseNote + modifier + extension;
  }

  static (String, String, String)? _parseChord(String chord) {
    // Patrón para acordes: base[#|b]?[m|7|9|etc]?
    final pattern = RegExp(r'^([A-G]|Do|Re|Mi|Fa|Sol|La|Si)([#b]?)(.*)$');
    final match = pattern.firstMatch(chord);
    
    if (match == null) return null;
    
    final baseNote = match.group(1)!;
    final modifier = match.group(2)!;
    final extension = match.group(3)!;
    
    return (baseNote, modifier, extension);
  }

  static bool isChord(String text) {
    if (text.isEmpty) return false;
    
    final pattern = RegExp(
      r'^([A-G][#b]?|Do|Re|Mi|Fa|Sol|La|Si)(m|m7|7|maj7|9|11|13|sus2|sus4|dim|aug|add)?[0-9]*$',
      caseSensitive: false
    );
    
    return pattern.hasMatch(text);
  }

  static String transposeLyrics(String lyrics, int semitones) {
    if (semitones == 0) return lyrics;

    final lines = lyrics.split('\n');
    final transposedLines = lines.map((line) {
      if (_isChordLine(line)) {
        return _transposeChordLine(line, semitones);
      }
      return line;
    }).toList();

    return transposedLines.join('\n');
  }

  static String _transposeChordLine(String line, int semitones) {
    final words = line.split(' ');
    final transposedWords = words.map((word) {
      final trimmed = word.trim();
      if (isChord(trimmed)) {
        return transposeChord(trimmed, semitones);
      }
      return word;
    }).toList();

    return transposedWords.join(' ');
  }

  static bool _isChordLine(String line) {
    final words = line.trim().split(' ').where((word) => word.isNotEmpty);
    if (words.isEmpty) return false;

    final chordCount = words.where((word) => isChord(word)).length;
    return chordCount > words.length / 2;
  }
}