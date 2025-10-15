import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/theme_provider.dart';
import 'screens/song_list_screen.dart';
import 'screens/setlist_list_screen.dart';
import 'screens/settings_screen.dart';

class CancioneroLiturgicoApp extends StatelessWidget {
  const CancioneroLiturgicoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => ThemeProvider(),
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'Cancionero Litúrgico',
            theme: ThemeProvider.lightTheme,
            darkTheme: ThemeProvider.darkTheme,
            themeMode: themeProvider.themeMode,
            home: const MainNavigationScreen(),
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }
}

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _selectedIndex = 0;

  static final List<Widget> _screens = [
    const SongListScreen(),
    const SetlistListScreen(),
    const SettingsScreen(),
  ];

  static const List<BottomNavigationBarItem> _navItems = [
    BottomNavigationBarItem(
      icon: Icon(Icons.music_note),
      label: 'Canciones',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.playlist_play),
      label: 'Setlists',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.settings),
      label: 'Configuración',
    ),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        items: _navItems,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}