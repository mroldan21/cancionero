import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cancionero_liturgico/models/song.dart';
import 'package:cancionero_liturgico/services/song_provider.dart';
import 'package:cancionero_liturgico/services/theme_provider.dart';
import 'package:cancionero_liturgico/services/transposition_service.dart';
import 'package:cancionero_liturgico/widgets/chord_text.dart';
import 'package:cancionero_liturgico/utils/scroll_controller.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
// --- CORRECCIÓN 1: Añadir importación faltante ---
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
  double _fontSize = 24.0; // Tamaño de fuente inicial
  bool _isScrollingAutomatically = false;

  @override
  void initState() {
    super.initState();
    // Inicializar ScrollAutoController
    _scrollAutoController = ScrollAutoController(
      scrollController: _scrollController,
      screenHeight: MediaQuery.of(context).size.height,
      songTempoBpm: widget.song.tempoBpm, // Usar tempo de la canción original
      totalLines: widget.song.content.split('\n').length, // Aproximación
      fontSize: _fontSize,
    );

    // Activar wakelock al entrar
    WakelockPlus.enable();

    // Incrementar contador de reproducciones al mostrar la canción
    final songRepository = Provider.of<SongRepository>(context, listen: false);
    if (widget.song.id != null) {
      songRepository.incrementPlayCount(widget.song.id!);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _scrollAutoController.stop(); // Asegurar que se detenga al salir
    WakelockPlus.disable(); // Desactivar wakelock al salir
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final songProvider = Provider.of<SongProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final currentSong = songProvider.currentSong ?? widget.song;
    // La transposición y capo ya están aplicadas en el 'content' y 'originalKey' de 'currentSong'
    // No necesitamos calcularlas aquí si la canción ya está transpuesta permanentemente.
    final currentTransposition = 0; // Siempre 0 porque el contenido ya está transpuesto
    final currentCapo = currentSong.capoPosition; // Usar capo de la canción transpuesta

    // --- CORRECCIÓN 2: Usar el método correcto ---
    // Calcular la tonalidad mostrada (ya transpuesta)
    String displayedKey = TranspositionService.getTransposedOriginalKey(currentSong.originalKey, currentTransposition);

    return Scaffold(
      backgroundColor: themeProvider.isDarkMode ? Colors.black : Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Título y metadatos
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      currentSong.title,
                      style: TextStyle(fontSize: _fontSize * 0.8, fontWeight: FontWeight.bold, color: themeProvider.isDarkMode ? Colors.white : Colors.black),
                    ),
                  ),
                  // Botón para salir
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.red),
                    onPressed: () {
                      Navigator.of(context).pop(); // Sale de la pantalla de presentación
                    },
                  ),
                ],
              ),
              Text(
                'Tono: $displayedKey${currentTransposition != 0 ? ' (+${currentTransposition})' : ''} | Capo: ${currentCapo != 0 ? 'Traste $currentCapo' : 'No'}',
                style: TextStyle(fontSize: _fontSize * 0.6, color: themeProvider.isDarkMode ? Colors.grey[400] : Colors.grey[600]),
              ),
              const SizedBox(height: 8),
              // Contenido con acordes
              Expanded(
                child: Scrollbar(
                  controller: _scrollController,
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    // --- CORRECCIÓN 3: Pasar el texto como argumento posicional ---
                    child: ChordText(
                      currentSong.content, // Argumento posicional 'text'
                      fontSize: _fontSize, // Argumento nombrado
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      // Controles flotantes
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Control de tamaño de fuente
          FloatingActionButton(
            heroTag: 'font_size',
            onPressed: () {
              setState(() {
                _fontSize = _fontSize == 32.0 ? 16.0 : _fontSize + 4.0; // Ciclar entre tamaños
                // --- CORRECCIÓN 4: Actualizar tamaño en el controlador de scroll ---
                // El constructor de ScrollAutoController ya recibe fontSize.
                // Para cambiarlo dinámicamente, necesitamos recrear el controlador o tener un método.
                // La forma más limpia es pasar el tamaño actualizado en el constructor o tener un setter público.
                // Asumiendo que el controlador tiene un setter público para fontSize (ver ScrollAutoController actualizado abajo)
                _scrollAutoController.setFontSize(_fontSize);
              });
            },
            child: Text(_fontSize.toStringAsFixed(0)),
          ),
          const SizedBox(height: 8),
          // Control de tema
          FloatingActionButton(
            heroTag: 'theme_toggle',
            onPressed: () {
              themeProvider.toggleTheme();
            },
            child: Icon(themeProvider.isDarkMode ? Icons.wb_sunny : Icons.nights_stay),
          ),
          const SizedBox(height: 8),
          // Control de scroll automático
          FloatingActionButton(
            heroTag: 'scroll_auto',
            onPressed: () {
              if (_scrollAutoController.isRunning) {
                _scrollAutoController.pause();
                setState(() {
                  _isScrollingAutomatically = false;
                });
              } else {
                _scrollAutoController.start();
                setState(() {
                  _isScrollingAutomatically = true;
                });
              }
            },
            child: Icon(_isScrollingAutomatically ? Icons.pause : Icons.play_arrow),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}