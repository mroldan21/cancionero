import 'package:flutter/material.dart';
import '../models/song.dart';
import '../widgets/chord_text.dart';

class PresentationScreen extends StatefulWidget {
  final Song song;
  final int transposition;

  const PresentationScreen({
    super.key,
    required this.song,
    this.transposition = 0,
  });

  @override
  State<PresentationScreen> createState() => _PresentationScreenState();
}

class _PresentationScreenState extends State<PresentationScreen> {
  double _fontSize = 20.0;
  bool _isPlaying = false;

  void _increaseFontSize() {
    setState(() {
      if (_fontSize < 40.0) _fontSize += 2.0;
    });
  }

  void _decreaseFontSize() {
    setState(() {
      if (_fontSize > 14.0) _fontSize -= 2.0;
    });
  }

  void _togglePlay() {
    setState(() {
      _isPlaying = !_isPlaying;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black.withOpacity(0.8),
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          children: [
            Text(
              widget.song.title,
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
            if (widget.transposition != 0)
              Text(
                'Tono: +${widget.transposition}',
                style: const TextStyle(color: Colors.white60, fontSize: 12),
              ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.zoom_out, color: Colors.white),
            onPressed: _decreaseFontSize,
          ),
          IconButton(
            icon: Icon(Icons.zoom_in, color: Colors.white),
            onPressed: _increaseFontSize,
          ),
          IconButton(
            icon: Icon(
              _isPlaying ? Icons.pause : Icons.play_arrow,
              color: Colors.white,
            ),
            onPressed: _togglePlay,
          ),
        ],
      ),
      body: Center(
        child: ChordText(
          lyricsWithChords: widget.song.lyricsWithChords,
          fontSize: _fontSize,
          textColor: Colors.white,
          chordColor: const Color(0xFF4FC3F7),
        ),
      ),
      // Indicador de reproducción
      bottomNavigationBar: _isPlaying
          ? Container(
              height: 40,
              color: Colors.green,
              child: const Center(
                child: Text(
                  '▶ REPRODUCIENDO',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            )
          : null,
    );
  }
}