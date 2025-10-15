import 'package:flutter/material.dart';
import 'package:provider/provider.dart';  // ← CON package:
import 'services/song_provider.dart';     // ← SIN ../ (misma carpeta)
import 'app.dart';                        // ← SIN ../

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => SongProvider()),
      ],
      child: const CancioneroLiturgicoApp(),
    ),
  );
}