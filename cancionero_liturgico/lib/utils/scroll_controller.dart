import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ScrollAutoController {
  final ScrollController _scrollController;
  final double _screenHeight; // Altura de la pantalla para cálculos
  final int? _songTempoBpm; // Tempo de la canción (puede ser nulo)
  final int _totalLines; // Aproximación del total de líneas de la canción
  double _fontSize; // Ahora es mutable y se puede cambiar
  double _userFactor = 1.0; // Factor de ajuste del usuario (0.5x - 2.0x)
  double _defaultSpeed = 30.0; // Velocidad predeterminada en px/seg si no hay tempo
  bool _isScrolling = false;
  Timer? _timer;

  ScrollAutoController({
    required ScrollController scrollController,
    required double screenHeight,
    int? songTempoBpm,
    required int totalLines,
    required double fontSize, // Recibe fontSize en el constructor
  })  : _scrollController = scrollController,
        _screenHeight = screenHeight,
        _songTempoBpm = songTempoBpm,
        _totalLines = totalLines,
        _fontSize = fontSize; // Inicializa el campo interno

  // Carga el factor de ajuste del usuario desde SharedPreferences
  Future<void> loadUserFactor() async {
    final prefs = await SharedPreferences.getInstance();
    _userFactor = prefs.getDouble('scroll_factor_adjust') ?? 1.0;
  }

  // Calcula la velocidad de scroll basada en tempo, líneas y factor de ajuste
  double _calculateSpeed() {
    if (_songTempoBpm == null) {
      // Si no hay tempo, usar velocidad predeterminada ajustada por el factor del usuario
      return _defaultSpeed * _userFactor;
    }

    // Duración estimada de la canción en segundos
    // Suposición: ~4 compases por línea, 4/4, tempo en negras
    const compasesPorLinea = 2.0;
    const negrasPorCompas = 4.0;
    final duracionEstimadaSegundos = (_totalLines * compasesPorLinea * negrasPorCompas) / (_songTempoBpm.toDouble() / 60.0);

    // Altura promedio de una línea según tamaño de fuente
    final lineHeight = _getAverageLineHeight();

    // Velocidad en pixels por segundo para completar el scroll en la duración estimada
    final totalHeight = _totalLines * lineHeight;
    final velocidadBase = totalHeight / duracionEstimadaSegundos;

    // Aplicar factor de ajuste del usuario
    return velocidadBase * _userFactor;
  }

  // Estima la altura promedio de una línea según el tamaño de fuente
  double _getAverageLineHeight() {
    // Valores aproximados, podrían ajustarse o calcularse dinámicamente
    if (_fontSize < 16) return 30.0;
    if (_fontSize < 20) return 40.0;
    if (_fontSize < 24) return 50.0;
    if (_fontSize < 28) return 60.0;
    return 70.0;
  }

  // Inicia el scroll automático
  void start() async {
    if (_isScrolling) return;
    await loadUserFactor(); // Carga el factor antes de calcular la velocidad
    _isScrolling = true;
    final speed = _calculateSpeed();
    final millisecondsPerFrame = 1000 ~/ 60; // ~60 FPS

    _timer = Timer.periodic(Duration(milliseconds: millisecondsPerFrame), (timer) {
      if (!_isScrolling || _scrollController.hasClients == false) {
        timer.cancel();
        return;
      }
      final scrollIncrement = (speed / 60.0); // px por frame a 60 FPS
      _scrollController.jumpTo(_scrollController.offset + scrollIncrement);

      // Detener si se alcanza el final
      if (_scrollController.position.atEdge && _scrollController.position.pixels != 0) {
        stop();
      }
    });
  }

  // Pausa el scroll automático
  void pause() {
    _isScrolling = false;
    _timer?.cancel();
  }

  // Detiene el scroll y vuelve al inicio
  void stop() {
    pause();
    // SOLUCIÓN: Solo intentar saltar al inicio si el controlador todavía está adjunto a una vista.
    // Esto evita el error "ScrollController not attached" cuando se llama desde dispose().
    if (_scrollController.hasClients) {
      _scrollController.jumpTo(0.0);
    }
  }

  // Verifica si está actualmente en scroll automático
  bool get isRunning => _isScrolling;

  // Ajusta el factor de velocidad del usuario y reinicia si está corriendo
  void adjustSpeedFactor(double newFactor) {
    _userFactor = newFactor.clamp(0.5, 2.0); // Limitar entre 0.5x y 2.0x
    // Guardar el nuevo factor en SharedPreferences
    SharedPreferences.getInstance().then((prefs) {
      prefs.setDouble('scroll_factor_adjust', _userFactor);
    });

    if (_isScrolling) {
      pause();
      start(); // Reiniciar con el nuevo factor
    }
  }

  void increaseSpeed() {
    adjustSpeedFactor(_userFactor + 0.1);
  }

  void decreaseSpeed() {
    adjustSpeedFactor(_userFactor - 0.1);
  }

  // Cambia la velocidad predeterminada (cuando no hay tempo)
  void setDefaultSpeed(double speed) {
    _defaultSpeed = speed;
    // Si se está corriendo y no hay tempo, recalcular velocidad
    if (_isScrolling && _songTempoBpm == null) {
      pause();
      start();
    }
  }

  // --- CORRECCIÓN 4: Nuevo setter público para actualizar _fontSize ---
  void setFontSize(double newSize) {
    _fontSize = newSize;
    // Opcionalmente, recalcular la velocidad si el scroll está corriendo
    // para que el cambio de tamaño afecte la velocidad de scroll.
    if (_isScrolling) {
        pause();
        start(); // Reinicia con el nuevo tamaño y recalcula velocidad
    }
  }
}