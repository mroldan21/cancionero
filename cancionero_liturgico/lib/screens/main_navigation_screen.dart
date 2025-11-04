import 'package:flutter/material.dart';
import '../services/database_helper.dart';
import '../services/category_repository.dart';
import 'package:provider/provider.dart';
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

  // final List<Widget> _screens = [
  //   const CategoriesScreen(),
  //   const SetlistListScreen(),
  //   const FavoritesScreen(),
  //   const SettingsScreen(),
  // ];

  // En main_navigation_screen.dart, reemplaza temporalmente:
  final List<Widget> _screens = [
    Scaffold(  // ← Pantalla de prueba simple
      body: Center(
        child: Text("🎯 CATEGORÍAS DE PRUEBA", 
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
      ),
    ),
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

  void _debugCategorias() async {
    final databaseHelper = DatabaseHelper();
    await databaseHelper.debugBDCompleta();
    
    // También debug específico de categorías si tienes el método
    final categoryRepository = Provider.of<CategoryRepository>(context, listen: false);
    // Si tienes el método debugCategoriasConConteo, descomenta:
    // await categoryRepository.debugCategoriasConConteo();
  }

  @override
  Widget build(BuildContext context) {
    print("[SCREEN] Build: MainNavigationScreen");
    print("🏠 MAIN NAVIGATION - Índice actual: $_selectedIndex");
    print("📱 MAIN NAVIGATION - Número de screens: ${_screens.length}");
  
    for (int i = 0; i < _screens.length; i++) {
      print("   - Índice $i: ${_screens[i].runtimeType}");
    }

    // TEMPORAL: Forzar CategoriesScreen para debug
    Widget forcedBody = _screens[0]; // Siempre mostrar CategoriesScreen
    print("🎯 TEMPORAL: Forzando pantalla: ${forcedBody.runtimeType}");

    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_selectedIndex]),
      ),
      body: forcedBody,
      // body: IndexedStack(
      //   index: _selectedIndex,
      //   children: _screens,
      // ),
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
      floatingActionButton: FloatingActionButton(
        onPressed: _debugCategorias,
        child: Icon(Icons.bug_report),
        backgroundColor: Colors.red,
      ),
    );
  }
}