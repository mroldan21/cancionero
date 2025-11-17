import 'package:flutter/material.dart';

class SongLineView extends StatelessWidget {
  final String line;
  final TextStyle lyricStyle;
  final TextStyle chordStyle;

  // Expresión regular para encontrar acordes entre corchetes, ej: [Am]
  // Si tu formato es diferente, ajústala aquí.
  static final RegExp _chordRegex = RegExp(r'\[([^\]]+)\]');

  const SongLineView({
    super.key,
    required this.line,
    required this.lyricStyle,
    required this.chordStyle,
  });

  @override
  Widget build(BuildContext context) {
    final List<TextSpan> spans = [];
    line.splitMapJoin(
      _chordRegex,
      onMatch: (m) {
        spans.add(TextSpan(text: m.group(1), style: chordStyle));
        return '';
      },
      onNonMatch: (n) {
        spans.add(TextSpan(text: n, style: lyricStyle));
        return '';
      },
    );

    return RichText(
      text: TextSpan(children: spans),
    );
  }
}