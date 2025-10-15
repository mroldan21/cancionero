class TransposicionService {
  static final Map<String, int> _notasAmericanas = {
    'C': 0, 'C#': 1, 'Db': 1, 'D': 2, 'D#': 3, 'Eb': 3,
    'E': 4, 'F': 5, 'F#': 6, 'Gb': 6, 'G': 7, 'G#': 8,
    'Ab': 8, 'A': 9, 'A#': 10, 'Bb': 10, 'B': 11
  };

  static final Map<String, int> _notasLatinas = {
    'Do': 0, 'Do#': 1, 'Reb': 1, 'Re': 2, 'Re#': 3, 'Mib': 3,
    'Mi': 4, 'Fa': 5, 'Fa#': 6, 'Solb': 6, 'Sol': 7, 'Sol#': 8,
    'Lab': 8, 'La': 9, 'La#': 10, 'Sib': 10, 'Si': 11
  };

  static final List<String> _notasAmericanasOrden = [
    'C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B'
  ];

  static final List<String> _notasLatinasOrden = [
    'Do', 'Do#', 'Re', 'Re#', 'Mi', 'Fa', 'Fa#', 'Sol', 'Sol#', 'La', 'La#', 'Si'
  ];

  /// Transpone un acorde individual
  static String transponerAcorde(String acorde, int semitonos, {bool notacionLatina = false}) {
    if (acorde.isEmpty) return acorde;

    // Expresión regular para parsear acordes complejos
    final regex = RegExp(r'^([A-G][#b]?|Do|Re|Mi|Fa|Sol|La|Si)(.*)$');
    final match = regex.firstMatch(acorde);

    if (match == null) return acorde;

    String notaBase = match.group(1)!;
    String extension = match.group(2) ?? '';

    // Convertir nota base a índice
    int indice = _notaAIndice(notaBase);
    
    // Aplicar transposición
    int nuevoIndice = (indice + semitonos + 12) % 12;
    
    // Convertir índice de vuelta a nota
    String nuevaNotaBase = _indiceANota(nuevoIndice, notacionLatina);
    
    return nuevaNotaBase + extension;
  }

  /// Transpone todos los acordes en el texto de una canción
  static String transponerLetraCompleta(String letraConAcordes, int semitonos, {bool notacionLatina = false}) {
    // Expresión regular para encontrar acordes en el texto
    final regex = RegExp(r'(\b[A-G][#b]?(?:m|maj|min|sus|dim|aug|add)?\d*\b|\b(?:Do|Re|Mi|Fa|Sol|La|Si)[#b]?(?:m|maj|min|sus|dim|aug|add)?\d*\b)');
    
    return letraConAcordes.replaceAllMapped(regex, (match) {
      String acorde = match.group(0)!;
      return transponerAcorde(acorde, semitonos, notacionLatina: notacionLatina);
    });
  }

  static int _notaAIndice(String nota) {
    // Primero buscar en notación americana
    if (_notasAmericanas.containsKey(nota)) {
      return _notasAmericanas[nota]!;
    }
    // Luego en notación latina
    if (_notasLatinas.containsKey(nota)) {
      return _notasLatinas[nota]!;
    }
    return 0; // Fallback
  }

  static String _indiceANota(int indice, bool notacionLatina) {
    if (notacionLatina) {
      return _notasLatinasOrden[indice];
    } else {
      return _notasAmericanasOrden[indice];
    }
  }

  /// Calcula la tonalidad resultante después de aplicar capo
  static String calcularTonalidadConCapo(String tonalidadOriginal, int posicionCapo) {
    if (posicionCapo == 0) return tonalidadOriginal;
    
    int indice = _notaAIndice(tonalidadOriginal);
    int nuevoIndice = (indice - posicionCapo + 12) % 12;
    
    return _indiceANota(nuevoIndice, false); // Siempre devolver en notación americana para consistencia
  }
}