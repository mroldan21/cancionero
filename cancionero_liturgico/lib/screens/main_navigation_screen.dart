import 'package:flutter/material.dart';
import 'package:cancionero_liturgico/screens/categories_screen.dart';
import 'package:cancionero_liturgico/screens/setlist_list_screen.dart';
import 'package:cancionero_liturgico/screens/settings_screen.dart';
import 'package:cancionero_liturgico/screens/favorites_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const CategoriesScreen(),
    const SetlistListScreen(),
    const FavoritesScreen(),
    const SettingsScreen(),
  ];

  final List<String> _titles = [
    'Categorías',
    'Setlists',
    'Favoritos',
    'Ajustes',
  ];

  @override
  Widget build(BuildContext context) {
    print("[SCREEN] Build: MainNavigationScreen");
    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_selectedIndex]),
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.category), label: 'Categorías'),
          BottomNavigationBarItem(icon: Icon(Icons.list), label: 'Setlists'),
          BottomNavigationBarItem(icon: Icon(Icons.star), label: 'Favoritos'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Ajustes'),
        ],
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
      ),
    );
  }
}