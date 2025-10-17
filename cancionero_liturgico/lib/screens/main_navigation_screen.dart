import 'package:flutter/material.dart';
import 'package:cancionero_liturgico/screens/categories_screen.dart';
import 'package:cancionero_liturgico/screens/setlist_list_screen.dart';
import 'package:cancionero_liturgico/screens/settings_screen.dart';
import 'package:cancionero_liturgico/screens/presentation_mode_screen.dart';
import 'package:cancionero_liturgico/screens/favorites_screen.dart'; // Importar la nueva pantalla

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _selectedIndex = 0;

  // Mantener las instancias de las pantallas para preservar el estado
  final List<Widget> _screens = [
    const CategoriesScreen(), // 0 - Categorías (con pestañas internas)
    const SetlistListScreen(), // 1 - Setlists
    const FavoritesScreen(), // 2 - Favoritos
    const SettingsScreen(), // 3 - Ajustes
    const PresentationModeScreen(), // 4 - Presentación
  ];

  // Etiquetas para las pestañas
  final List<String> _titles = [
    'Categorías',
    'Setlists',
    'Favoritos',
    'Ajustes',
    'Presentación',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_selectedIndex]), // Actualizar título según pestaña
      ),
      body: IndexedStack( // Usar IndexedStack para mantener el estado de las pantallas
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed, // Opcional: para mejor distribución
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.category), label: 'Categorías'),
          BottomNavigationBarItem(icon: Icon(Icons.list), label: 'Setlists'),
          BottomNavigationBarItem(icon: Icon(Icons.star), label: 'Favoritos'), // Nuevo ícono
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Ajustes'),
          BottomNavigationBarItem(icon: Icon(Icons.present_to_all), label: 'Presentación'),
        ],
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index; // Cambiar índice seleccionado
          });
        },
      ),
    );
  }
}