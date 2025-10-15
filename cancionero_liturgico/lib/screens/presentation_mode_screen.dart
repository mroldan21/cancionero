import 'package:flutter/material.dart';
import '../models/cancion_model.dart';
import '../services/transposition_service.dart';

class PresentationModeScreen extends StatefulWidget {
  final Cancion song;
  final List<Cancion>? setlistSongs;
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

  @override
  void initState() {
    super.initState();
    _currentCapo = widget.song.posicionCapo;
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
      return widget.song.letraConAcordes;
    }
    
    return _transposeLyrics(widget.song.letraConAcordes, _currentTransposition);
  }

  String _transposeLyrics(String lyrics, int semitones) {
    final lines = lyrics.split('\n');
    final transposedLines = <String>[];
    
    for (final line in lines) {
      final chordRegex = RegExp(r'([A-G][#b]?(?:m|maj|min|sus|dim|aug|add)?\d*)');
      final transposedLine = line.replaceAllMapped(chordRegex, (match) {
        return TranspositionService.transposeChord(match.group(0)!, semitones);
      });
      transposedLines.add(transposedLine);
    }
    
    return transposedLines.join('\n');
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

  @override
  Widget build(BuildContext context) {
    final transposedLyrics = _getTransposedLyrics();
    final isSetlist = widget.setlistSongs != null;

    return Scaffold(
      backgroundColor: _isDarkMode ? Colors.black87 : Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Header - Fijo en la parte superior
            _buildHeader(isSetlist),
            
            // Lyrics Area - Scrollable
            Expanded(
              child: _buildLyricsArea(transposedLyrics),
            ),
            
            // Controls - Fijo en la parte inferior
            _buildControls(isSetlist),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool isSetlist) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: _isDarkMode ? Colors.grey[900] : Colors.grey[100],
        border: Border(
          bottom: BorderSide(color: _isDarkMode ? Colors.grey[700]! : Colors.grey[300]!),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.song.titulo,
                  style: TextStyle(
                    color: _isDarkMode ? Colors.white : Colors.black,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  'Key: ${widget.song.tonalidadOriginal} • '
                  'Capo: $_currentCapo • '
                  'Transpose: ${_currentTransposition > 0 ? '+' : ''}$_currentTransposition',
                  style: TextStyle(
                    color: _isDarkMode ? Colors.grey[400] : Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          if (isSetlist)
            Text(
              '${_currentSongIndex + 1}/${widget.setlistSongs!.length}',
              style: TextStyle(
                color: _isDarkMode ? Colors.grey[400] : Colors.grey[600],
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLyricsArea(String lyrics) {
    return SingleChildScrollView(
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

  Widget _buildControls(bool isSetlist) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _isDarkMode ? Colors.grey[900] : Colors.grey[100],
        border: Border(
          top: BorderSide(color: _isDarkMode ? Colors.grey[700]! : Colors.grey[300]!),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // First row: Navigation and scroll
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              if (isSetlist)
                _buildControlButton(
                  icon: Icons.skip_previous,
                  label: 'Previous',
                  onPressed: _previousSong,
                )
              else
                const Spacer(),

              _buildControlButton(
                icon: _isAutoScrolling ? Icons.pause : Icons.play_arrow,
                label: _isAutoScrolling ? 'Pause' : 'Scroll',
                onPressed: _toggleAutoScroll,
              ),

              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.remove, size: 20),
                        onPressed: () {
                          setState(() {
                            _scrollSpeed = (_scrollSpeed - 0.1).clamp(0.5, 2.0);
                          });
                        },
                      ),
                      Text(
                        '${_scrollSpeed.toStringAsFixed(1)}x',
                        style: TextStyle(
                          color: _isDarkMode ? Colors.white : Colors.black,
                          fontSize: 14,
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.add, size: 20),
                        onPressed: () {
                          setState(() {
                            _scrollSpeed = (_scrollSpeed + 0.1).clamp(0.5, 2.0);
                          });
                        },
                      ),
                    ],
                  ),
                  Text(
                    'Speed',
                    style: TextStyle(
                      color: _isDarkMode ? Colors.grey[400] : Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),

              if (isSetlist)
                _buildControlButton(
                  icon: Icons.skip_next,
                  label: 'Next',
                  onPressed: _nextSong,
                )
              else
                const Spacer(),
            ],
          ),

          const SizedBox(height: 16),

          // Second row: Settings
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildFontSizeControls(),
              _buildTranspositionControls(),
              _buildCapoControls(),
              _buildControlButton(
                icon: _isDarkMode ? Icons.light_mode : Icons.dark_mode,
                label: _isDarkMode ? 'Light' : 'Dark',
                onPressed: () {
                  setState(() {
                    _isDarkMode = !_isDarkMode;
                  });
                },
              ),
              _buildControlButton(
                icon: Icons.close,
                label: 'Exit',
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: Icon(icon),
          onPressed: onPressed,
          color: _isDarkMode ? Colors.white : Colors.black,
        ),
        Text(
          label,
          style: TextStyle(
            color: _isDarkMode ? Colors.grey[400] : Colors.grey[600],
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildFontSizeControls() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(Icons.text_decrease, size: 20),
              onPressed: () {
                setState(() {
                  _fontSize = (_fontSize - 2).clamp(16.0, 32.0);
                });
              },
            ),
            Text(
              'Aa',
              style: TextStyle(
                fontSize: 14,
                color: _isDarkMode ? Colors.white : Colors.black,
              ),
            ),
            IconButton(
              icon: Icon(Icons.text_increase, size: 20),
              onPressed: () {
                setState(() {
                  _fontSize = (_fontSize + 2).clamp(16.0, 32.0);
                });
              },
            ),
          ],
        ),
        Text(
          'Text',
          style: TextStyle(
            color: _isDarkMode ? Colors.grey[400] : Colors.grey[600],
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildTranspositionControls() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(Icons.arrow_downward, size: 20),
              onPressed: () {
                setState(() {
                  _currentTransposition = (_currentTransposition - 1).clamp(-11, 11);
                });
              },
            ),
            Text(
              _currentTransposition == 0 ? '0' : '${_currentTransposition > 0 ? '+' : ''}$_currentTransposition',
              style: TextStyle(
                fontSize: 14,
                color: _isDarkMode ? Colors.white : Colors.black,
              ),
            ),
            IconButton(
              icon: Icon(Icons.arrow_upward, size: 20),
              onPressed: () {
                setState(() {
                  _currentTransposition = (_currentTransposition + 1).clamp(-11, 11);
                });
              },
            ),
          ],
        ),
        Text(
          'Transpose',
          style: TextStyle(
            color: _isDarkMode ? Colors.grey[400] : Colors.grey[600],
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildCapoControls() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(Icons.remove, size: 20),
              onPressed: () {
                setState(() {
                  _currentCapo = (_currentCapo - 1).clamp(0, 12);
                });
              },
            ),
            Text(
              _currentCapo == 0 ? 'No' : '$_currentCapo',
              style: TextStyle(
                fontSize: 14,
                color: _isDarkMode ? Colors.white : Colors.black,
              ),
            ),
            IconButton(
              icon: Icon(Icons.add, size: 20),
              onPressed: () {
                setState(() {
                  _currentCapo = (_currentCapo + 1).clamp(0, 12);
                });
              },
            ),
          ],
        ),
        Text(
          'Capo',
          style: TextStyle(
            color: _isDarkMode ? Colors.grey[400] : Colors.grey[600],
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}