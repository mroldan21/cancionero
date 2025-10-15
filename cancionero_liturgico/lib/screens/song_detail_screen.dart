import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/song.dart';
import '../services/song_provider.dart';
import '../widgets/chord_text.dart';
import '../widgets/transposition_controls.dart';
import 'presentation_screen.dart';

class SongDetailScreen extends StatefulWidget {
  final Song song;

  const SongDetailScreen({super.key, required this.song});

  @override
  State<SongDetailScreen> createState() => _SongDetailScreenState();
}

class _SongDetailScreenState extends State<SongDetailScreen> {
  int _transposition = 0;

  void _transposeUp() {
    setState(() {
      if (_transposition < 11) _transposition++;
    });
  }

  void _transposeDown() {
    setState(() {
      if (_transposition > -11) _transposition--;
    });
  }

  void _resetTransposition() {
    setState(() {
      _transposition = 0;
    });
  }

  String _getCurrentKey(String originalKey) {
    // TODO: Implementar lógica de transposición
    if (_transposition == 0) return originalKey;
    return '$originalKey (+$_transposition)';
  }

  void _startPresentation() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PresentationScreen(
          song: widget.song,
          transposition: _transposition,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.song.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.play_arrow),
            onPressed: _startPresentation,
            tooltip: 'Modo Presentación',
          ),
        ],
      ),
      body: Column(
        children: [
          // Controles de transposición
          TranspositionControls(
            currentTransposition: _transposition,
            originalKey: widget.song.originalKey,
            currentKey: _getCurrentKey(widget.song.originalKey),
            onTransposeUp: _transposeUp,
            onTransposeDown: _transposeDown,
            onReset: _resetTransposition,
          ),

          // Información de la canción
          Card(
            margin: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (widget.song.artist.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Text(
                        'Artista: ${widget.song.artist}',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                  Text('Tonalidad: ${_getCurrentKey(widget.song.originalKey)}'),
                  if (widget.song.tempoBpm != null)
                    Text('Tempo: ${widget.song.tempoBpm} BPM'),
                ],
              ),
            ),
          ),

          // Letra con acordes
          Expanded(
            child: Card(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: ChordText(
                  lyricsWithChords: widget.song.lyricsWithChords,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}