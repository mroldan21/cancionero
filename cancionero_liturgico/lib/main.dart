import 'package:flutter/material.dart';
import 'services/song_repository.dart'; // ✅ AGREGAR ESTE IMPORT
import 'screens/main_navigation_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // ✅ INICIALIZACIÓN CORRECTA usando SongRepository que ya existe
  await _initializeApp();  
  
  runApp(const MyApp());
}

Future<void> _initializeApp() async {
  try {
    print('🚀 Inicializando aplicación...');
    final repository = SongRepository(); // ✅ USAR SongRepository que ya existe
    
    // ✅ LLAMAR AL MÉTODO QUE YA EXISTE en SongRepository
    await repository.initializeWithDemoData();

    // ✅ INICIALIZAR SETLISTS (NUEVO)
    await repository.initializeSetlistsDemoData();
    
    print('✅ Aplicación inicializada correctamente');
  } catch (e) {
    print('❌ Error en inicialización: $e');
  }
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cancionero Litúrgico',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const MainNavigationScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}