import 'package:flutter/material.dart';
import '../models/song.dart';

class PresentationModeScreen extends StatefulWidget {
  final Song song;
  final List<Song>? setlistSongs;
  final int initialIndex;

  const PresentationModeScreen({
    Key? key,
    required this.song,
    this.setlistSongs,
    this.initialIndex = 0,
  }) : super(key: key);

  @override
  State<PresentationModeScreen> createState() => _PresentationModeScreenState();
}

class _PresentationModeScreenState extends State<PresentationModeScreen> {
  final ScrollController _scrollController = ScrollController();
  int _currentTransposition = 0;
  int _currentCapo = 0;
  bool _isAutoScrolling = false;
  double _scrollSpeed = 1.0;
  double _fontSize = 22.0;
  bool _isDarkMode = true;
  int _currentSongIndex = 0;
  double _scale = 1.0;

  @override
  void initState() {
    super.initState();
    _currentCapo = widget.song.capoPosition;
    _currentSongIndex = widget.initialIndex;
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _toggleAutoScroll() {
    setState(() {
      _isAutoScrolling = !_isAutoScrolling;
    });
    
    if (_isAutoScrolling) {
      _startAutoScroll();
    }
  }

  void _startAutoScroll() {
    Future.doWhile(() async {
      if (!_isAutoScrolling) return false;
      
      if (_scrollController.hasClients && 
          _scrollController.offset < _scrollController.position.maxScrollExtent) {
        
        final double scrollAmount = _calculateScrollSpeed();
        await _scrollController.animateTo(
          _scrollController.offset + scrollAmount,
          duration: const Duration(milliseconds: 1000),
          curve: Curves.linear,
        );
        
        return _isAutoScrolling;
      } else {
        setState(() {
          _isAutoScrolling = false;
        });
        return false;
      }
    });
  }

  double _calculateScrollSpeed() {
    final double baseSpeed = 50.0;
    final double tempoFactor = (widget.song.tempoBpm ?? 120) / 60.0;
    return baseSpeed * tempoFactor * _scrollSpeed;
  }

  String _getTransposedLyrics() {
    if (_currentTransposition == 0) {
      return widget.song.lyricsWithChords;
    }
    
    return _transposeLyrics(widget.song.lyricsWithChords, _currentTransposition);
  }

  String _transposeLyrics(String lyrics, int semitones) {
    final lines = lyrics.split('\n');
    final transposedLines = <String>[];
    
    for (final line in lines) {
      final chordRegex = RegExp(r'([A-G][#b]?(?:m|maj|min|sus|dim|aug|add)?\d*)');
      final transposedLine = line.replaceAllMapped(chordRegex, (match) {
        return _transposeChord(match.group(0)!, semitones);
      });
      transposedLines.add(transposedLine);
    }
    
    return transposedLines.join('\n');
  }

  String _transposeChord(String chord, int semitones) {
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

  int _noteToIndex(String note) {
    final Map<String, int> notes = {
      'C': 0, 'C#': 1, 'Db': 1, 'D': 2, 'D#': 3, 'Eb': 3,
      'E': 4, 'F': 5, 'F#': 6, 'Gb': 6, 'G': 7, 'G#': 8,
      'Ab': 8, 'A': 9, 'A#': 10, 'Bb': 10, 'B': 11
    };
    return notes[note] ?? 0;
  }

  String _indexToNote(int index) {
    final notes = ['C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B'];
    return notes[index];
  }

  void _nextSong() {
    if (widget.setlistSongs == null) return;
    
    final nextIndex = _currentSongIndex + 1;
    if (nextIndex < widget.setlistSongs!.length) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => PresentationModeScreen(
            song: widget.setlistSongs![nextIndex],
            setlistSongs: widget.setlistSongs,
            initialIndex: nextIndex,
          ),
        ),
      );
    }
  }

  void _previousSong() {
    if (widget.setlistSongs == null) return;
    
    final prevIndex = _currentSongIndex - 1;
    if (prevIndex >= 0) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => PresentationModeScreen(
            song: widget.setlistSongs![prevIndex],
            setlistSongs: widget.setlistSongs,
            initialIndex: prevIndex,
          ),
        ),
      );
    }
  }

  void _handlePinchUpdate(ScaleUpdateDetails details) {
    setState(() {
      _scale = details.scale.clamp(0.5, 3.0);
      _fontSize = 22.0 * _scale;
    });
  }

  void _handlePinchEnd() {
    // Mantener el último tamaño, no resetear
  }

  @override
  Widget build(BuildContext context) {
    final transposedLyrics = _getTransposedLyrics();
    final isSetlist = widget.setlistSongs != null;

    return Scaffold(
      backgroundColor: _isDarkMode ? Colors.black87 : Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            // Área principal de letras con gestos
            _buildLyricsArea(transposedLyrics),
            
            // Header transparente
            _buildHeader(isSetlist),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool isSetlist) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: _isDarkMode 
              ? [Colors.black87, Colors.transparent]
              : [Colors.white, Colors.transparent],
        ),
      ),
      child: Row(
        children: [
          // Botón de volver
          IconButton(
            icon: Icon(Icons.arrow_back, color: _isDarkMode ? Colors.white : Colors.black),
            onPressed: () => Navigator.pop(context),
            tooltip: 'Volver',
          ),
          
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.song.title,
                  style: TextStyle(
                    color: _isDarkMode ? Colors.white : Colors.black,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'Tono: ${widget.song.originalKey} • '
                  'Capo: $_currentCapo • '
                  'Transp: ${_currentTransposition > 0 ? '+' : ''}$_currentTransposition',
                  style: TextStyle(
                    color: _isDarkMode ? Colors.grey[400] : Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          
          // Indicador de setlist
          if (isSetlist)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Text(
                '${_currentSongIndex + 1}/${widget.setlistSongs!.length}',
                style: TextStyle(
                  color: _isDarkMode ? Colors.grey[400] : Colors.grey[600],
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          
          // Botón de configuración
          PopupMenuButton<String>(
            icon: Icon(Icons.settings, color: _isDarkMode ? Colors.white : Colors.black),
            tooltip: 'Configuración',
            onSelected: _handleSettingSelection,
            itemBuilder: (context) => [
              _buildMenuItem('Tamaño texto', Icons.text_fields, '${_fontSize.toInt()}px'),
              _buildMenuItem('Transposición', Icons.trending_up, '${_currentTransposition > 0 ? '+' : ''}$_currentTransposition'),
              _buildMenuItem('Capo', Icons.vertical_align_top, '$_currentCapo'),
              _buildMenuItem('Velocidad', Icons.speed, '${_scrollSpeed.toStringAsFixed(1)}x'),
              const PopupMenuDivider(),
              PopupMenuItem(
                value: 'theme',
                child: Row(
                  children: [
                    Icon(_isDarkMode ? Icons.light_mode : Icons.dark_mode),
                    const SizedBox(width: 8),
                    Text(_isDarkMode ? 'Tema claro' : 'Tema oscuro'),
                  ],
                ),
              ),
              if (isSetlist) ...[
                const PopupMenuDivider(),
                _buildMenuItem('Anterior', Icons.skip_previous, ''),
                _buildMenuItem('Siguiente', Icons.skip_next, ''),
              ],
            ],
          ),
        ],
      ),
    );
  }

  PopupMenuItem<String> _buildMenuItem(String title, IconData icon, String value) {
    return PopupMenuItem(
      value: title.toLowerCase(),
      child: Row(
        children: [
          Icon(icon),
          const SizedBox(width: 8),
          Expanded(child: Text(title)),
          if (value.isNotEmpty)
            Text(
              value,
              style: const TextStyle(color: Colors.grey),
            ),
        ],
      ),
    );
  }

  Widget _buildLyricsArea(String lyrics) {
    return GestureDetector(
      onTap: _toggleAutoScroll,
      onScaleUpdate: _handlePinchUpdate,
      onScaleEnd: (_) => _handlePinchEnd(),
      child: SingleChildScrollView(
        controller: _scrollController,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Text.rich(
            _parseLyricsWithChords(lyrics),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: _fontSize,
              height: 1.8,
              color: _isDarkMode ? Colors.white : Colors.black,
            ),
          ),
        ),
      ),
    );
  }

  TextSpan _parseLyricsWithChords(String text) {
    final lines = text.split('\n');
    final spans = <TextSpan>[];

    for (final line in lines) {
      if (line.trim().isEmpty) {
        spans.add(const TextSpan(text: '\n'));
        continue;
      }

      final chordRegex = RegExp(r'^(\s*[A-G][#b]?(?:m|maj|min|sus|dim|aug|add)?\d*\s*)+$');
      final isChordLine = chordRegex.hasMatch(line);

      if (isChordLine) {
        spans.add(TextSpan(
          text: '$line\n',
          style: TextStyle(
            color: Colors.amber[700],
            fontWeight: FontWeight.bold,
            fontSize: _fontSize * 0.85,
          ),
        ));
      } else {
        spans.add(TextSpan(
          text: '$line\n',
          style: TextStyle(
            color: _isDarkMode ? Colors.white : Colors.black,
          ),
        ));
      }
    }

    return TextSpan(children: spans);
  }

  void _handleSettingSelection(String value) {
    switch (value) {
      case 'tamaño texto':
        _showFontSizeDialog();
        break;
      case 'transposición':
        _showTranspositionDialog();
        break;
      case 'capo':
        _showCapoDialog();
        break;
      case 'velocidad':
        _showSpeedDialog();
        break;
      case 'tema claro':
      case 'tema oscuro':
      case 'theme':
        setState(() {
          _isDarkMode = !_isDarkMode;
        });
        break;
      case 'anterior':
        _previousSong();
        break;
      case 'siguiente':
        _nextSong();
        break;
    }
  }

  void _showFontSizeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tamaño de texto'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Slider(
              value: _fontSize,
              min: 16,
              max: 48,
              divisions: 8,
              label: _fontSize.toInt().toString(),
              onChanged: (value) {
                setState(() {
                  _fontSize = value;
                  _scale = value / 22.0;
                });
              },
            ),
            Text('${_fontSize.toInt()} pixels'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showTranspositionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Transposición'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.remove),
                  onPressed: () {
                    setState(() {
                      _currentTransposition = (_currentTransposition - 1).clamp(-11, 11);
                    });
                  },
                ),
                Container(
                  width: 60,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _currentTransposition == 0 ? '0' : '${_currentTransposition > 0 ? '+' : ''}$_currentTransposition',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () {
                    setState(() {
                      _currentTransposition = (_currentTransposition + 1).clamp(-11, 11);
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text('Semitonos: -11 a +11'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showCapoDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Posición de Capo'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.remove),
                  onPressed: () {
                    setState(() {
                      _currentCapo = (_currentCapo - 1).clamp(0, 12);
                    });
                  },
                ),
                Container(
                  width: 80,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _currentCapo == 0 ? 'Sin capo' : 'Traste $_currentCapo',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () {
                    setState(() {
                      _currentCapo = (_currentCapo + 1).clamp(0, 12);
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text('Trastes: 0 a 12 (0 = sin capo)'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showSpeedDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Velocidad de Scroll'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Slider(
              value: _scrollSpeed,
              min: 0.5,
              max: 2.0,
              divisions: 6,
              label: _scrollSpeed.toStringAsFixed(1),
              onChanged: (value) {
                setState(() {
                  _scrollSpeed = value;
                });
              },
            ),
            Text('${_scrollSpeed.toStringAsFixed(1)}x velocidad'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}