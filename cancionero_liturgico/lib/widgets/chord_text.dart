import 'package:flutter/material.dart';

class ChordText extends StatelessWidget {
  final String text; // Parámetro posicional
  final double fontSize; // Parámetro nombrado

  const ChordText(
    this.text, // Parámetro posicional
    {super.key, this.fontSize = 16.0} // Parámetro nombrado con valor por defecto
  );

  @override
  Widget build(BuildContext context) {
    // Expresión regular para identificar acordes
    // Asume acordes simples como C, Am, F#, Bb7, etc.
    final chordRegex = RegExp(r'\b[A-G][b#]?(m|7|sus|add|dim|aug)?\b');

    List<InlineSpan> spans = [];
    text.split('\n').forEach((line) {
      final lineSpans = _parseLineForChords(line, chordRegex);
      spans.addAll(lineSpans);
      spans.add(const TextSpan(text: '\n')); // Agregar salto de línea
    });

    // Remover el último salto de línea extra añadido
    if (spans.isNotEmpty) {
      spans.removeLast();
    }

    return RichText(
      text: TextSpan(
        style: DefaultTextStyle.of(context).style.copyWith(fontSize: fontSize),
        children: spans,
      ),
    );
  }

  List<InlineSpan> _parseLineForChords(String line, RegExp chordRegex) {
    List<InlineSpan> spans = [];
    int lastMatchEnd = 0;

    chordRegex.allMatches(line).forEach((match) {
      // Agregar texto antes del acorde
      if (match.start > lastMatchEnd) {
        spans.add(TextSpan(text: line.substring(lastMatchEnd, match.start)));
      }
      // Agregar acorde en negrita
      spans.add(TextSpan(
        text: match.group(0),
        style: const TextStyle(fontWeight: FontWeight.bold),
      ));
      lastMatchEnd = match.end;
    });

    // Agregar texto restante después del último acorde
    if (lastMatchEnd < line.length) {
      spans.add(TextSpan(text: line.substring(lastMatchEnd)));
    }

    return spans;
  }
}