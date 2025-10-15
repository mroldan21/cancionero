class TranspositionService {
  static final Map<String, int> _americanNotes = {
    'C': 0, 'C#': 1, 'Db': 1, 'D': 2, 'D#': 3, 'Eb': 3,
    'E': 4, 'F': 5, 'F#': 6, 'Gb': 6, 'G': 7, 'G#': 8,
    'Ab': 8, 'A': 9, 'A#': 10, 'Bb': 10, 'B': 11
  };

  static String transposeChord(String chord, int semitones) {
    if (chord.isEmpty) return chord;

    final regex = RegExp(r'^([A-G][#b]?)(.*)$');
    final match = regex.firstMatch(chord);

    if (match == null) return chord;

    String baseNote = match.group(1)!;
    String extension = match.group(2) ?? '';

    int index = _noteToIndex(baseNote);
    int newIndex = (index + semitones + 12) % 12;
    String newBaseNote = _indexToNote(newIndex);

    return newBaseNote + extension;
  }

  static int _noteToIndex(String note) {
    return _americanNotes[note] ?? 0;
  }

  static String _indexToNote(int index) {
    final notes = ['C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B'];
    return notes[index];
  }
}