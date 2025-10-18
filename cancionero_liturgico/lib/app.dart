import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cancionero_liturgico/screens/main_navigation_screen.dart';
import 'package:cancionero_liturgico/services/song_provider.dart';
import 'package:cancionero_liturgico/services/theme_provider.dart';
import 'package:cancionero_liturgico/services/category_repository.dart';
import 'package:cancionero_liturgico/services/song_repository.dart';
import 'package:cancionero_liturgico/services/presentation_state_service.dart';

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
        // MEJORA: Registrar el nuevo servicio para que esté disponible en la app.
        ChangeNotifierProvider(
          create: (context) => PresentationStateService(
            Provider.of<SongRepository>(context, listen: false),
          ),
        ),
      ],
      // MEJORA: Simplificar la estructura para asegurar que el contexto del Provider
      // esté siempre por encima de MaterialApp.
      child: Builder(builder: (context) {
        final themeProvider = Provider.of<ThemeProvider>(context);
        return MaterialApp(
          title: 'Cancionero Litúrgico',
          theme: themeProvider.currentTheme,
          home: const MainNavigationScreen(),
          debugShowCheckedModeBanner: false,
        );
      }),
    );
  }
}