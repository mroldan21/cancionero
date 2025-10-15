import 'package:flutter/material.dart';

class ChordText extends StatelessWidget {
  final String lyricsWithChords;
  final double fontSize;
  final Color textColor;
  final Color chordColor;

  const ChordText({
    super.key,
    required this.lyricsWithChords,
    this.fontSize = 16.0,
    this.textColor = Colors.black,
    this.chordColor = Colors.red,
  });

  bool _isChordLine(String line) {
    final words = line.trim().split(' ').where((word) => word.isNotEmpty);
    if (words.isEmpty) return false;

    final chordCount = words.where((word) => _isChord(word)).length;
    return chordCount > words.length / 2;
  }

  bool _isChord(String text) {
    if (text.isEmpty) return false;

    // Acordes americanos: C, C#, Dm, G7, etc.
    final americanChord = RegExp(r'^[A-G][#b]?(m|m7|7|maj7|9|11|13|sus2|sus4|dim|aug|add)?[0-9]*$');
    
    // Acordes latinos: Do, Re#, Mim, Sol7, etc.
    final latinChord = RegExp(r'^(Do|Re|Mi|Fa|Sol|La|Si)[#b]?(m|m7|7|maj7|9|11|13|sus2|sus4|dim|aug|add)?[0-9]*$');

    return americanChord.hasMatch(text) || latinChord.hasMatch(text);
  }

  @override
  Widget build(BuildContext context) {
    final lines = lyricsWithChords.split('\n');
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: lines.map((line) {
        if (line.trim().isEmpty) {
          return const SizedBox(height: 16.0);
        }

        if (_isChordLine(line)) {
          // Línea de acordes
          return _buildChordLine(line);
        } else {
          // Línea de letra
          return _buildLyricLine(line);
        }
      }).toList(),
    );
  }

  Widget _buildChordLine(String line) {
    final words = line.split(' ');
    
    return Wrap(
      spacing: 4.0,
      children: words.map((word) {
        if (word.isEmpty) return const SizedBox(width: 4.0);
        
        if (_isChord(word)) {
          // Palabra es un acorde
          return Text(
            word,
            style: TextStyle(
              color: chordColor,
              fontWeight: FontWeight.bold,
              fontSize: fontSize - 2.0,
            ),
          );
        } else {
          // Palabra normal (espaciado)
          return Text(
            word,
            style: TextStyle(
              color: textColor,
              fontSize: fontSize - 2.0,
            ),
          );
        }
      }).toList(),
    );
  }

  Widget _buildLyricLine(String line) {
    return Text(
      line,
      style: TextStyle(
        color: textColor,
        fontSize: fontSize,
        height: 1.4,
      ),
    );
  }
}