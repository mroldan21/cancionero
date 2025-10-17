// Helper para operaciones comunes relacionadas con tonalidades y transposición

class TransposeHelper {
  // Determina si una tonalidad dada es menor basado en su sufijo
  static bool isMinorKey(String key) {
    // Este patrón busca una 'm' minúscula seguida de un espacio, final de string,
    // o caracteres comunes de extensión de acorde. Es un ejemplo simple.
    // Puede necesitar refinamiento para casos complejos.
    return RegExp(r'm(\s|$|7|9|11|13|aj7|us2|us4|im|ug|dd)').hasMatch(key);
  }

  // Extrae la nota base de una tonalidad (ej: "Cm" -> "C", "Bb7" -> "Bb")
  static String getBaseNote(String key) {
    final match = RegExp(r'^([A-G][b#]?)').firstMatch(key);
    return match?.group(1) ?? key; // Devuelve la nota base o la cadena original si no coincide
  }

  // Opcional: Función para convertir entre notación americana y latina
  // static String convertNotation(String chord, Notation targetNotation) { ... }
  // Esta función sería más compleja y podría requerir tablas de conversión.
}

// enum Notation { americana, latina, ambas }