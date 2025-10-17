import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cancionero_liturgico/screens/main_navigation_screen.dart';
import 'package:cancionero_liturgico/services/song_provider.dart';
import 'package:cancionero_liturgico/services/theme_provider.dart';
import 'package:cancionero_liturgico/services/category_repository.dart';
import 'package:cancionero_liturgico/services/song_repository.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SongProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        Provider(create: (_) => CategoryRepository()),
        Provider(create: (_) => SongRepository()),
        // Añadir aquí otros providers si se crean (ej: SyncService, ConfigService)
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'Cancionero Litúrgico',
            theme: themeProvider.currentTheme,
            home: const MainNavigationScreen(),
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }
}