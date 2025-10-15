import 'package:flutter/material.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:scroll_to_index/scroll_to_index.dart';
import '../models/cancion_model.dart';
import '../services/transposition_service.dart';

class PresentationModeScreen extends StatefulWidget {
  final Cancion cancion;
  final List<Cancion>? setlistCanciones;
  final int initialIndex;

  const PresentationModeScreen({
    Key? key,
    required this.cancion,
    this.setlistCanciones,
    this.initialIndex = 0,
  }) : super(key: key);

  @override
  _PresentationModeScreenState createState() => _PresentationModeScreenState();
}

class _PresentationModeScreenState extends State<PresentationModeScreen> {
  late AutoScrollController _scrollController;
  late int _currentTransposicion;
  late int _currentCapo;
  bool _isScrolling = false;
  double _scrollSpeed = 1.0;
  double _fontSize = 24.0;
  bool _isDarkMode = true;
  int _currentSetlistIndex = 0;

  @override
  void initState() {
    super.initState();
    _scrollController = AutoScrollController();
    _currentTransposicion = 0;
    _currentCapo = widget.cancion.posicionCapo;
    _currentSetlistIndex = widget.initialIndex;
    
    // Activar wake lock para mantener pantalla encendida
    WakelockPlus.enable();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    // Desactivar wake lock al salir
    WakelockPlus.disable();
    super.dispose();
  }

  void _toggleScroll() {
    setState(() {
      _isScrolling = !_isScrolling;
    });

    if (_isScrolling) {
      _startAutoScroll();
    }
  }

  void _startAutoScroll() {
    Future.doWhile(() async {
      if (!_isScrolling) return false;
      
      // Calcular velocidad basada en tempo (RF-021)
      double velocidad = _calculateScrollSpeed();
      
      // Scroll suave
      await _scrollController.scrollToOffset(
        _scrollController.offset + velocidad,
        duration: const Duration(milliseconds: 1000),
      );
      
      // Verificar si llegó al final
      if (_scrollController.offset >= _scrollController.position.maxScrollExtent) {
        setState(() {
          _isScrolling = false;
        });
        return false;
      }
      
      return _isScrolling;
    });
  }

  double _calculateScrollSpeed() {
    // Algoritmo de scroll inteligente basado en tempo (Apéndice C)
    final tempo = widget.cancion.tempoBpm ?? 120;
    final factorBase = tempo / 60.0; // Negras por segundo
    final velocidadBase = factorBase * 50.0; // Pixels por segundo base
    
    return velocidadBase * _scrollSpeed;
  }

  String _getLetraTranspuesta() {
    if (_currentTransposicion == 0) {
      return widget.cancion.letraConAcordes;
    }
    
    return TransposicionService.transponerLetraCompleta(
      widget.cancion.letraConAcordes,
      _currentTransposicion,
    );
  }

  String _getTonalidadActual() {
    if (_currentTransposicion == 0) {
      return widget.cancion.tonalidadOriginal;
    }
    
    return TransposicionService.transponerAcorde(
      widget.cancion.tonalidadOriginal,
      _currentTransposicion,
    );
  }

  void _changeTransposicion(int semitonos) {
    setState(() {
      _currentTransposicion = semitonos;
    });
  }

  void _changeCapo(int capo) {
    setState(() {
      _currentCapo = capo;
    });
  }

  void _nextSong() {
    if (widget.setlistCanciones == null) return;
    
    final nextIndex = _currentSetlistIndex + 1;
    if (nextIndex < widget.setlistCanciones!.length) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => PresentationModeScreen(
            cancion: widget.setlistCanciones![nextIndex],
            setlistCanciones: widget.setlistCanciones,
            initialIndex: nextIndex,
          ),
        ),
      );
    }
  }

  void _previousSong() {
    if (widget.setlistCanciones == null) return;
    
    final prevIndex = _currentSetlistIndex - 1;
    if (prevIndex >= 0) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => PresentationModeScreen(
            cancion: widget.setlistCanciones![prevIndex],
            setlistCanciones: widget.setlistCanciones,
            initialIndex: prevIndex,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final letraTranspuesta = _getLetraTranspuesta();
    final tonalidadActual = _getTonalidadActual();
    final isSetlist = widget.setlistCanciones != null;

    return Scaffold(
      backgroundColor: _isDarkMode ? Colors.black : Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Header con información de la canción
            _buildHeader(tonalidadActual, isSetlist),
            
            // Área principal de la letra
            Expanded(
              child: _buildLyricsArea(letraTranspuesta),
            ),
            
            // Controles inferiores
            _buildControls(isSetlist),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(String tonalidadActual, bool isSetlist) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: _isDarkMode ? Colors.grey[900] : Colors.grey[100],
        border: Border(
          bottom: BorderSide(
            color: _isDarkMode ? Colors.grey[700]! : Colors.grey[300]!,
          ),
        ),
      ),
      child: Row(
        children: [
          // Información de la canción
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.cancion.titulo,
                  style: TextStyle(
                    color: _isDarkMode ? Colors.white : Colors.black,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (widget.cancion.autor != null && widget.cancion.autor!.isNotEmpty)
                  Text(
                    widget.cancion.autor!,
                    style: TextStyle(
                      color: _isDarkMode ? Colors.grey[400] : Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                Text(
                  'Tono: $tonalidadActual${_currentCapo > 0 ? ' | Capo: $_currentCapo' : ''}',
                  style: TextStyle(
                    color: _isDarkMode ? Colors.grey[400] : Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          
          // Indicador de setlist
          if (isSetlist)
            Text(
              '${_currentSetlistIndex + 1}/${widget.setlistCanciones!.length}',
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

  Widget _buildLyricsArea(String letraTranspuesta) {
    return SingleChildScrollView(
      controller: _scrollController,
      child: Container(
        padding: const EdgeInsets.all(20),
        child: Text.rich(
          _parseLyricsWithChords(letraTranspuesta),
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: _fontSize,
            height: 1.6,
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
        spans.add(const TextSpan(text: '\n\n'));
        continue;
      }

      // Detectar si la línea contiene acordes (empieza con espacios o acordes)
      final chordRegex = RegExp(r'^(\s*[A-G][#b]?(?:m|maj|min|sus|dim|aug|add)?\d*\s*)+$');
      final isChordLine = chordRegex.hasMatch(line);

      if (isChordLine) {
        // Línea de acordes
        spans.add(TextSpan(
          text: '$line\n',
          style: TextStyle(
            color: Colors.orangeAccent,
            fontWeight: FontWeight.bold,
            fontSize: _fontSize * 0.8,
          ),
        ));
      } else {
        // Línea de letra
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
          top: BorderSide(
            color: _isDarkMode ? Colors.grey[700]! : Colors.grey[300]!,
          ),
        ),
      ),
      child: Column(
        children: [
          // Fila 1: Navegación y scroll
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Navegación anterior
              if (isSetlist)
                IconButton(
                  icon: Icon(Icons.skip_previous, color: _isDarkMode ? Colors.white : Colors.black),
                  onPressed: _previousSong,
                  iconSize: 30,
                )
              else
                const SizedBox(width: 48),
              
              // Control de scroll automático
              Column(
                children: [
                  IconButton(
                    icon: Icon(
                      _isScrolling ? Icons.pause : Icons.play_arrow,
                      color: _isDarkMode ? Colors.white : Colors.black,
                      size: 30,
                    ),
                    onPressed: _toggleScroll,
                  ),
                  Text(
                    _isScrolling ? 'Pausar' : 'Scroll',
                    style: TextStyle(
                      color: _isDarkMode ? Colors.grey[400] : Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              
              // Velocidad de scroll
              Column(
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(Icons.remove, color: _isDarkMode ? Colors.white : Colors.black, size: 20),
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
                        icon: Icon(Icons.add, color: _isDarkMode ? Colors.white : Colors.black, size: 20),
                        onPressed: () {
                          setState(() {
                            _scrollSpeed = (_scrollSpeed + 0.1).clamp(0.5, 2.0);
                          });
                        },
                      ),
                    ],
                  ),
                  Text(
                    'Velocidad',
                    style: TextStyle(
                      color: _isDarkMode ? Colors.grey[400] : Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              
              // Navegación siguiente
              if (isSetlist)
                IconButton(
                  icon: Icon(Icons.skip_next, color: _isDarkMode ? Colors.white : Colors.black),
                  onPressed: _nextSong,
                  iconSize: 30,
                )
              else
                const SizedBox(width: 48),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Fila 2: Ajustes de visualización y transposición
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Tamaño de fuente
              Column(
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(Icons.text_decrease, color: _isDarkMode ? Colors.white : Colors.black, size: 20),
                        onPressed: () {
                          setState(() {
                            _fontSize = (_fontSize - 2).clamp(16.0, 32.0);
                          });
                        },
                      ),
                      Text(
                        'Aa',
                        style: TextStyle(
                          color: _isDarkMode ? Colors.white : Colors.black,
                          fontSize: 14,
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.text_increase, color: _isDarkMode ? Colors.white : Colors.black, size: 20),
                        onPressed: () {
                          setState(() {
                            _fontSize = (_fontSize + 2).clamp(16.0, 32.0);
                          });
                        },
                      ),
                    ],
                  ),
                  Text(
                    'Texto',
                    style: TextStyle(
                      color: _isDarkMode ? Colors.grey[400] : Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              
              // Transposición
              Column(
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(Icons.arrow_downward, color: _isDarkMode ? Colors.white : Colors.black, size: 20),
                        onPressed: () {
                          _changeTransposicion(_currentTransposicion - 1);
                        },
                      ),
                      Text(
                        _currentTransposicion == 0 
                            ? 'Tono' 
                            : '${_currentTransposicion > 0 ? '+' : ''}$_currentTransposicion',
                        style: TextStyle(
                          color: _isDarkMode ? Colors.white : Colors.black,
                          fontSize: 14,
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.arrow_upward, color: _isDarkMode ? Colors.white : Colors.black, size: 20),
                        onPressed: () {
                          _changeTransposicion(_currentTransposicion + 1);
                        },
                      ),
                    ],
                  ),
                  Text(
                    'Transp.',
                    style: TextStyle(
                      color: _isDarkMode ? Colors.grey[400] : Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              
              // Capo
              Column(
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(Icons.remove, color: _isDarkMode ? Colors.white : Colors.black, size: 20),
                        onPressed: () {
                          _changeCapo((_currentCapo - 1).clamp(0, 12));
                        },
                      ),
                      Text(
                        _currentCapo == 0 ? 'Sin capo' : 'Capo $_currentCapo',
                        style: TextStyle(
                          color: _isDarkMode ? Colors.white : Colors.black,
                          fontSize: 14,
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.add, color: _isDarkMode ? Colors.white : Colors.black, size: 20),
                        onPressed: () {
                          _changeCapo((_currentCapo + 1).clamp(0, 12));
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
              ),
              
              // Tema claro/oscuro
              Column(
                children: [
                  IconButton(
                    icon: Icon(
                      _isDarkMode ? Icons.light_mode : Icons.dark_mode,
                      color: _isDarkMode ? Colors.white : Colors.black,
                    ),
                    onPressed: () {
                      setState(() {
                        _isDarkMode = !_isDarkMode;
                      });
                    },
                  ),
                  Text(
                    _isDarkMode ? 'Oscuro' : 'Claro',
                    style: TextStyle(
                      color: _isDarkMode ? Colors.grey[400] : Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              
              // Botón de salir
              Column(
                children: [
                  IconButton(
                    icon: Icon(Icons.close, color: _isDarkMode ? Colors.white : Colors.black),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                  ),
                  Text(
                    'Salir',
                    style: TextStyle(
                      color: _isDarkMode ? Colors.grey[400] : Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}