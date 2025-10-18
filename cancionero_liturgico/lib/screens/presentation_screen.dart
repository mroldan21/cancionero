import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:ui'; // For BackdropFilter
import 'package:cancionero_liturgico/models/setlist.dart';

import 'package:cancionero_liturgico/models/song.dart';
import 'package:cancionero_liturgico/services/song_provider.dart';
import 'package:cancionero_liturgico/services/theme_provider.dart';
import 'package:cancionero_liturgico/services/transposition_service.dart';
import 'package:cancionero_liturgico/services/presentation_state_service.dart';
import 'package:cancionero_liturgico/widgets/song_content_view.dart'; // MEJORA: Usar el nuevo widget optimizado
import 'package:cancionero_liturgico/utils/scroll_controller.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:cancionero_liturgico/services/song_repository.dart';

class PresentationScreen extends StatefulWidget {
  final Song song;
  final SetlistItem? setlistItem; // Nuevo: para recibir la configuración del setlist
  final VoidCallback? onNextSong;
  final VoidCallback? onPreviousSong;

  const PresentationScreen({
    super.key,
    required this.song,
    this.setlistItem,
    this.onNextSong,
    this.onPreviousSong,
  });

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
  late Song _currentSong; // Estado local para la canción
  int _capoFret = 0;

  @override
  void initState() {
    super.initState();
    // SOLUCIÓN: Inicializar _currentSong aquí para evitar el LateInitializationError.
    _currentSong = widget.song;

    // Si se proporciona un setlistItem, usar sus valores. Si no, cargar los guardados.
    if (widget.setlistItem != null) {
      _transpositionSemitones = widget.setlistItem!.transposition;
      _capoFret = widget.setlistItem!.capo ?? 0;
    } else {
      // Carga los ajustes iniciales, pero no los vuelve a cargar en didChangeDependencies
      final settings = Provider.of<PresentationStateService>(context, listen: false).getSettingsForSong(widget.song);
      _transpositionSemitones = settings.transposition;
      _capoFret = settings.capo;
    }
    WakelockPlus.enable();
  }

  @override
  void didChangeDependencies() {
    // Esta lógica se mantiene para cuando se navega entre canciones de un setlist
    // SOLUCIÓN: Sincronizar _currentSong con el provider.
    final songFromProvider = Provider.of<SongProvider>(context).currentSong;
    _currentSong = songFromProvider ?? widget.song;

    super.didChangeDependencies();
    if (!_dependenciesInitialized) {
      _dependenciesInitialized = true;
      _scrollAutoController = ScrollAutoController(
        scrollController: _scrollController,
        screenHeight: MediaQuery.of(context).size.height,
        songTempoBpm: _currentSong.tempoBpm,
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
    // Primero, detenemos el auto-scroll que usa el controller.
    if (_dependenciesInitialized) {
      _scrollAutoController.stop();
    }
    // Luego, liberamos el controller.
    _scrollController.dispose();
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

  // Lógica para guardar los cambios permanentemente
  Future<void> _saveChanges() async {
    if (_currentSong.id == null) return;

    final songProvider = Provider.of<SongProvider>(context, listen: false);
    final songRepository = Provider.of<SongRepository>(context, listen: false);

    // 1. Aplicar la transposición actual al contenido y a la tonalidad original.
    final finalContent = TranspositionService.transposeContent(_currentSong.content, _transpositionSemitones);
    final finalKey = TranspositionService.getTransposedOriginalKey(_currentSong.originalKey, _transpositionSemitones);

    // 2. Crear una nueva instancia de la canción con los cambios aplicados.
    final updatedSong = _currentSong.copyWith(
      content: finalContent,
      originalKey: finalKey,
      capoPosition: _capoFret,
      modificationDate: DateTime.now(),
    );

    // 3. Guardar la canción actualizada en la base de datos.
    await songRepository.updateSong(updatedSong);

    // 4. Actualizar el provider para que toda la app se entere del cambio.
    songProvider.setSelectedSong(updatedSong);

    // 5. Mostrar confirmación y actualizar el estado local.
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cambios guardados en la canción.'), backgroundColor: Colors.green),
      );
      setState(() {
        _currentSong = updatedSong; // La canción base ahora es la actualizada.
        _transpositionSemitones = 0; // La transposición se resetea a 0.
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    print("[SCREEN] Build: PresentationScreen");
    final themeProvider = Provider.of<ThemeProvider>(context);
    final displayedKey = TranspositionService.getTransposedOriginalKey(_currentSong.originalKey, _transpositionSemitones);
    final transposedContent = TranspositionService.transposeContent(_currentSong.content, _transpositionSemitones);

    return Scaffold(
      backgroundColor: themeProvider.isDarkMode ? Colors.black : Colors.white,
      body: Stack(
        children: [          // Main content
          GestureDetector(
            // MEJORA: Navegación por swipe horizontal
            onHorizontalDragEnd: (details) {
              if (details.primaryVelocity == 0) return; // No swipe
              if (details.primaryVelocity! < 0) {
                // Swipe a la izquierda -> Siguiente canción
                widget.onNextSong?.call();
              } else if (details.primaryVelocity! > 0) {
                // Swipe a la derecha -> Canción anterior
                widget.onPreviousSong?.call();
              }
            },
            child: SafeArea(
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
                            _currentSong.title,
                            style: TextStyle(fontSize: _fontSize * 0.8, fontWeight: FontWeight.bold, color: themeProvider.isDarkMode ? Colors.white : Colors.black),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.save, color: Colors.blue),
                          tooltip: 'Guardar cambios permanentemente',
                          onPressed: _saveChanges,
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
                        child: GestureDetector( // Envuelve el SingleChildScrollView para capturar todos los gestos
                          // MEJORA: Ocultar el panel con cualquier interacción sobre el área de la canción
                          onTap: () => setState(() => _showControls = false),
                          onPanDown: (_) => setState(() => _showControls = false),
                          onScaleStart: (details) {
                            _baseFontSize = _fontSize;
                            setState(() => _showControls = false);
                          },
                          onScaleUpdate: (details) {
                            setState(() {
                              _fontSize = (_baseFontSize * details.scale).clamp(12.0, 64.0);
                              if (_dependenciesInitialized) {
                                _scrollAutoController.setFontSize(_fontSize);
                              }
                            });
                          },
                          child: SingleChildScrollView( // El contenido scrolleable
                            controller: _scrollController,
                            child: SongContentView(text: transposedContent, fontSize: _fontSize), // MEJORA: Usar el nuevo widget
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
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
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildToneControls(),
                        const SizedBox(height: 20),
                        _buildControlGroup(
                          'Capo',
                          Icons.straighten,
                          () => setState(() {
                            _capoFret = (_capoFret - 1).clamp(0, 12);
                          }),
                          () => setState(() {
                            _capoFret = (_capoFret + 1).clamp(0, 12);
                          }),
                        ),
                        const SizedBox(height: 20),
                        _buildControlGroup(
                          'Fuente',
                          Icons.format_size,
                          () => setState(() {
                            _fontSize = (_fontSize - 2).clamp(12.0, 64.0);
                            if (_dependenciesInitialized) _scrollAutoController.setFontSize(_fontSize);
                          }),
                          () => setState(() {
                            _fontSize = (_fontSize + 2).clamp(12.0, 64.0);
                            if (_dependenciesInitialized) _scrollAutoController.setFontSize(_fontSize);
                          }),
                        ),
                        const SizedBox(height: 20),
                        _buildControlGroup(
                          'Velocidad',
                          Icons.speed,
                          () {
                            if (!_dependenciesInitialized) return;
                            _scrollAutoController.decreaseSpeed();
                          },
                          () {
                            if (!_dependenciesInitialized) return;
                            _scrollAutoController.increaseSpeed();
                          },
                        ),
                        const SizedBox(height: 20),
                        IconButton(
                          icon: Icon(themeProvider.isDarkMode ? Icons.wb_sunny : Icons.nights_stay, color: themeProvider.isDarkMode ? Colors.white : Colors.black),
                          onPressed: () => themeProvider.toggleTheme(),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Panel Toggle Button
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            top: MediaQuery.of(context).size.height / 2 - 30,
            right: _showControls ? 200 : 10,
            child: FloatingActionButton(
              heroTag: 'toggleControls', // Añadir heroTag para evitar conflictos
              backgroundColor: Colors.black.withOpacity(0.5),
              onPressed: () => setState(() => _showControls = !_showControls),
              child: Icon(_showControls ? Icons.arrow_forward_ios : Icons.arrow_back_ios, size: 18),
            ),
          ),

          // Play/Pause Button
          Positioned(
            bottom: 30,
            right: 16,
            child: FloatingActionButton(
              heroTag: 'playPause', // Añadir heroTag para evitar conflictos
              onPressed: _toggleAutoScroll,
              child: Icon(_isScrollingAutomatically ? Icons.pause : Icons.play_arrow),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToneControls() {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return Column(
      children: [
        Text('Tono', style: TextStyle(color: themeProvider.isDarkMode ? Colors.white : Colors.black, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () => setState(() {
                _transpositionSemitones--;
              }),
              style: ElevatedButton.styleFrom(shape: const CircleBorder(), padding: const EdgeInsets.all(15)),
              child: const Icon(Icons.remove),
            ),
            const SizedBox(width: 10),
            ElevatedButton(onPressed: () => setState(() {
                _transpositionSemitones++;
              }),
              style: ElevatedButton.styleFrom(shape: const CircleBorder(), padding: const EdgeInsets.all(15)),
              child: const Icon(Icons.add),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildControlGroup(String title, IconData icon, VoidCallback onRemove, VoidCallback onAdd) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: themeProvider.isDarkMode ? Colors.white : Colors.black),
            const SizedBox(width: 8),
            Text(title, style: TextStyle(color: themeProvider.isDarkMode ? Colors.white : Colors.black, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(onPressed: onRemove, style: ElevatedButton.styleFrom(shape: const CircleBorder(), padding: const EdgeInsets.all(12)), child: const Icon(Icons.remove)),
            const SizedBox(width: 10),
            ElevatedButton(onPressed: onAdd, style: ElevatedButton.styleFrom(shape: const CircleBorder(), padding: const EdgeInsets.all(12)), child: const Icon(Icons.add)),
          ],
        ),
      ],
    );
  }
}
