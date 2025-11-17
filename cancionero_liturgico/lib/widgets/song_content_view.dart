import 'package:flutter/material.dart';
import 'package:cancionero_liturgico/widgets/song_line_view.dart';

class SongContentView extends StatelessWidget {
  final String text;
  final double fontSize;
  final TextStyle? chordStyle;
  final TextStyle? lyricStyle;

  const SongContentView({
    super.key,
    required this.text,
    required this.fontSize,
    this.chordStyle,
    this.lyricStyle,
  });

  @override
  Widget build(BuildContext context) {
    final lines = text.split('\n');
    final theme = Theme.of(context);
    final defaultLyricStyle = TextStyle(fontSize: fontSize, color: theme.textTheme.bodyLarge?.color);
    final defaultChordStyle = TextStyle(fontSize: fontSize * 0.9, color: theme.primaryColor, fontWeight: FontWeight.bold);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: lines.map((line) {
        return SongLineView(
          line: line,
          lyricStyle: lyricStyle ?? defaultLyricStyle,
          chordStyle: chordStyle ?? defaultChordStyle,
        );
      }).toList(),
    );
  }
}