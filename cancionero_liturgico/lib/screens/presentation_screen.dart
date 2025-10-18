import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:ui'; // For BackdropFilter

import 'package:cancionero_liturgico/models/song.dart';
import 'package:cancionero_liturgico/services/song_provider.dart';
import 'package:cancionero_liturgico/services/theme_provider.dart';
import 'package:cancionero_liturgico/services/transposition_service.dart';
import 'package:cancionero_liturgico/widgets/chord_text.dart';
import 'package:cancionero_liturgico/utils/scroll_controller.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:cancionero_liturgico/services/song_repository.dart';

class PresentationScreen extends StatefulWidget {
  final Song song;

  const PresentationScreen({super.key, required this.song});

  @override
  State<PresentationScreen> createState() => _PresentationScreenState();
}

class _PresentationScreenState extends State<PresentationScreen> {
  final ScrollController _scrollController = ScrollController();
  late ScrollAutoController _scrollAutoController;
  double _fontSize = 24.0;
  double _baseFontSize = 24.0;
  bool _isScrollingAutomatically = false;
  bool _dependenciesInitialized = false;
  bool _showControls = false;

  int _transpositionSemitones = 0;
  int _capoFret = 0;

  @override
  void initState() {
    super.initState();
    _capoFret = widget.song.capoPosition;
    WakelockPlus.enable();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_dependenciesInitialized) {
      _dependenciesInitialized = true;
      _scrollAutoController = ScrollAutoController(
        scrollController: _scrollController,
        screenHeight: MediaQuery.of(context).size.height,
        songTempoBpm: widget.song.tempoBpm,
        totalLines: widget.song.content.split('\n').length,
        fontSize: _fontSize,
      );
      final songRepository = Provider.of<SongRepository>(context, listen: false);
      if (widget.song.id != null) {
        songRepository.incrementPlayCount(widget.song.id!);
      }
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    if (_dependenciesInitialized) {
      _scrollAutoController.stop();
    }
    WakelockPlus.disable();
    super.dispose();
  }

  void _toggleAutoScroll() {
    if (!_dependenciesInitialized) return;
    if (_scrollAutoController.isRunning) {
      _scrollAutoController.pause();
      setState(() => _isScrollingAutomatically = false);
    } else {
      _scrollAutoController.start();
      setState(() => _isScrollingAutomatically = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    print("[SCREEN] Build: PresentationScreen");
    final themeProvider = Provider.of<ThemeProvider>(context);
    final displayedKey = TranspositionService.getTransposedOriginalKey(widget.song.originalKey, _transpositionSemitones);
    final transposedContent = TranspositionService.transposeContent(widget.song.content, _transpositionSemitones);

    return Scaffold(
      backgroundColor: themeProvider.isDarkMode ? Colors.black : Colors.white,
      body: Stack(
        children: [
          // Main content
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          widget.song.title,
                          style: TextStyle(fontSize: _fontSize * 0.8, fontWeight: FontWeight.bold, color: themeProvider.isDarkMode ? Colors.white : Colors.black),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.red),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  Text(
                    'Tono: $displayedKey | Capo: ${_capoFret != 0 ? 'Traste $_capoFret' : 'No'}',
                    style: TextStyle(fontSize: _fontSize * 0.6, color: themeProvider.isDarkMode ? Colors.grey[400] : Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: Scrollbar(
                      controller: _scrollController,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: _toggleAutoScroll,
                        onScaleStart: (details) => _baseFontSize = _fontSize,
                        onScaleUpdate: (details) {
                          setState(() {
                            _fontSize = (_baseFontSize * details.scale).clamp(12.0, 64.0);
                            if (_dependenciesInitialized) {
                              _scrollAutoController.setFontSize(_fontSize);
                            }
                          });
                        },
                        child: SingleChildScrollView(
                          controller: _scrollController,
                          physics: const NeverScrollableScrollPhysics(),
                          child: ChordText(transposedContent, fontSize: _fontSize),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Sliding Controls Panel
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            right: _showControls ? 0 : -200,
            top: 0,
            bottom: 0,
            child: ClipRRect(
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(16), bottomLeft: Radius.circular(16)),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                child: Container(
                  width: 200,
                  color: themeProvider.isDarkMode ? Colors.black.withOpacity(0.7) : Colors.white.withOpacity(0.7),
                  child: SafeArea(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildControlGroup(
                          'Tono',
                          () => setState(() => _transpositionSemitones--),
                          () => setState(() => _transpositionSemitones++),
                        ),
                        _buildControlGroup(
                          'Capo',
                          () => setState(() => _capoFret = (_capoFret - 1).clamp(0, 12)),
                          () => setState(() => _capoFret = (_capoFret + 1).clamp(0, 12)),
                        ),
                        _buildControlGroup(
                          'Fuente',
                          () => setState(() {
                            _fontSize = (_fontSize - 2).clamp(12.0, 64.0);
                            if (_dependenciesInitialized) _scrollAutoController.setFontSize(_fontSize);
                          }),
                          () => setState(() {
                            _fontSize = (_fontSize + 2).clamp(12.0, 64.0);
                            if (_dependenciesInitialized) _scrollAutoController.setFontSize(_fontSize);
                          }),
                        ),
                        IconButton(
                          icon: Icon(themeProvider.isDarkMode ? Icons.wb_sunny : Icons.nights_stay, color: themeProvider.isDarkMode ? Colors.white : Colors.black),
                          onPressed: () => themeProvider.toggleTheme(),
                        ),
                        IconButton(
                          icon: Icon(_isScrollingAutomatically ? Icons.pause : Icons.play_arrow, color: themeProvider.isDarkMode ? Colors.white : Colors.black),
                          onPressed: _toggleAutoScroll,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.black.withOpacity(0.5),
        onPressed: () => setState(() => _showControls = !_showControls),
        child: Icon(_showControls ? Icons.arrow_forward_ios : Icons.arrow_back_ios),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerRight,
    );
  }

  Widget _buildControlGroup(String title, VoidCallback onRemove, VoidCallback onAdd) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return Column(
      children: [
        Text(title, style: TextStyle(color: themeProvider.isDarkMode ? Colors.white : Colors.black, fontWeight: FontWeight.bold)),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(icon: Icon(Icons.remove, color: themeProvider.isDarkMode ? Colors.white : Colors.black), onPressed: onRemove),
            IconButton(icon: Icon(Icons.add, color: themeProvider.isDarkMode ? Colors.white : Colors.black), onPressed: onAdd),
          ],
        ),
      ],
    );
  }
}
