import 'dart:async';
import 'package:flutter/material.dart';

class AutoScrollController {
  final ScrollController scrollController;
  Timer? _scrollTimer;
  bool _isScrolling = false;
  double _currentPosition = 0;

  AutoScrollController({required this.scrollController});

  void startAutoScroll({
    required double pixelsPerSecond,
    required double maxScrollExtent,
  }) {
    if (_isScrolling) return;

    _isScrolling = true;
    _currentPosition = scrollController.offset;

    _scrollTimer = Timer.periodic(const Duration(milliseconds: 16), (timer) {
      _currentPosition += pixelsPerSecond / 60; // 60 FPS

      if (_currentPosition >= maxScrollExtent) {
        stopAutoScroll();
        return;
      }

      scrollController.jumpTo(_currentPosition);
    });
  }

  void stopAutoScroll() {
    _scrollTimer?.cancel();
    _scrollTimer = null;
    _isScrolling = false;
  }

  void pauseAutoScroll() {
    _scrollTimer?.cancel();
    _scrollTimer = null;
  }

  void resumeAutoScroll({
    required double pixelsPerSecond,
    required double maxScrollExtent,
  }) {
    if (!_isScrolling) return;
    startAutoScroll(
      pixelsPerSecond: pixelsPerSecond,
      maxScrollExtent: maxScrollExtent,
    );
  }

  bool get isScrolling => _isScrolling;

  void dispose() {
    _scrollTimer?.cancel();
    scrollController.dispose();
  }
}

class ScrollSpeedCalculator {
  static double calculateSpeedFromBPM(int bpm, int totalLines) {
    // Fórmula base: velocidad proporcional al tempo
    final double baseSpeed = bpm / 60.0; // Pixels por segundo base
    
    // Ajustar según longitud del texto (más líneas = más rápido)
    final double lengthFactor = totalLines / 50.0;
    
    return baseSpeed * 30.0 * lengthFactor.clamp(0.5, 3.0);
  }

  static double calculateSpeedFromDuration(int totalSeconds, int totalLines) {
    final double desiredDuration = totalSeconds.toDouble();
    final double totalPixels = totalLines * 40.0; // Aproximación de pixels por línea
    
    return totalPixels / desiredDuration;
  }
}