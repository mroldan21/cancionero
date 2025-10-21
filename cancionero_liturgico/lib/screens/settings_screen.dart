import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cancionero_liturgico/services/theme_provider.dart';
// import 'package:file_picker/file_picker.dart'; // Ya no se necesita
// import 'dart:convert'; // Ya no se necesita
// import 'dart:io'; // Ya no se necesita

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    print("[SCREEN] Build: SettingsScreen");
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Ajustes')),
      body: ListView(
        children: [
          // --- Sección Visualización ---
          const ListTile(title: Text('VISUALIZACIÓN', style: TextStyle(fontWeight: FontWeight.bold))),
          SwitchListTile(
            title: const Text('Modo Oscuro'),
            value: themeProvider.isDarkMode,
            onChanged: (value) {
              themeProvider.toggleTheme();
            },
          ),
          // ListTile( // Ejemplo de selector de tamaño de fuente
          //   title: const Text('Tamaño de Fuente'),
          //   subtitle: Text(_getFontSizeLabel()), // Obtener desde SharedPreferences
          //   onTap: () {
          //     // Mostrar diálogo para seleccionar tamaño
          //     _showFontSizeDialog(context);
          //   },
          // ),
          // ListTile( // Ejemplo de selector de notación
          //   title: const Text('Notación de Acordes'),
          //   subtitle: Text(_getNotationLabel()), // Obtener desde SharedPreferences
          //   onTap: () {
          //     // Mostrar diálogo para seleccionar notación
          //     _showNotationDialog(context);
          //   },
          // ),

          // --- Sección Scroll Automático ---
          const Divider(),
          const ListTile(title: Text('SCROLL AUTOMÁTICO', style: TextStyle(fontWeight: FontWeight.bold))),
          // ListTile( // Ejemplo de selector de velocidad predeterminada
          //   title: const Text('Velocidad Predeterminada'),
          //   subtitle: Text(_getScrollSpeedLabel()), // Obtener desde SharedPreferences
          //   onTap: () {
          //     // Mostrar diálogo para seleccionar velocidad
          //     _showScrollSpeedDialog(context);
          //   },
          // ),
          // --- CORRECCIÓN 1: Colocar el FutureBuilder aquí ---
          FutureBuilder<double>(
            future: _loadScrollFactor(), // Llamar a la función estática o moverla a una clase State
            builder: (context, snapshot) {
              double factor = snapshot.data ?? 1.0;
              return ListTile(
                title: const Text('Factor de Ajuste del Tempo'),
                subtitle: Text('${factor.toStringAsFixed(1)}x'),
                trailing: SizedBox(
                  width: 150,
                  child: Slider(
                    value: factor,
                    min: 0.5,
                    max: 2.0,
                    divisions: 30, // 0.5 a 2.0 en pasos de 0.05
                    label: factor.toStringAsFixed(1),
                    // --- CORRECCIÓN 2: Eliminar setState ---
                    onChanged: (value) async {
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.setDouble('scroll_factor_adjust', value);
                      // setState(() {}); // Eliminado: No es necesario en un StatefulWidget padre ni en un StatelessWidget
                      // El FutureBuilder se reconstruirá automáticamente en la próxima reconstrucción del widget padre
                      // o cuando se vuelva a visitar esta pantalla si se almacena el valor globalmente y se escucha.
                    },
                  ),
                ),
              );
            },
          ),

          // --- Sección Sincronización ---
          const Divider(),
          const ListTile(title: Text('SINCRONIZACIÓN', style: TextStyle(fontWeight: FontWeight.bold))),
          // ListTile( // Ejemplo de campo para URL de BD central
          //   title: const Text('URL Base de Datos Central'),
          //   subtitle: Text(_getCentralDbUrl()), // Obtener desde SharedPreferences
          //   onTap: () {
          //     // Mostrar diálogo para ingresar/editar URL
          //     _showDbUrlDialog(context);
          //   },
          // ),
          // SwitchListTile( // Ejemplo de toggle para sincronización automática
          //   title: const Text('Sincronizar al Abrir'),
          //   value: _isAutoSyncEnabled(), // Obtener desde SharedPreferences
          //   onChanged: (value) async {
          //     final prefs = await SharedPreferences.getInstance();
          //     await prefs.setBool('sync_auto', value);
          //   },
          // ),
          ListTile(
            title: const Text('Sincronizar Ahora'),
            leading: const Icon(Icons.sync),
            onTap: () {
              // Llamar a la lógica de sincronización
              // final syncService = Provider.of<SyncService>(context, listen: false);
              // syncService.synchronize();
              print("Sincronización manual iniciada (simulada)");
            },
          ),
          // Mostrar última fecha de sincronización
          // FutureBuilder<String>(
          //   future: _getLastSyncDate(),
          //   builder: (context, snapshot) {
          //     return ListTile(
          //       title: const Text('Última Sincronización'),
          //       subtitle: Text(snapshot.data ?? 'Nunca'),
          //     );
          //   },
          // ),

          // --- Sección Datos ---
          const Divider(),
          const ListTile(title: Text('DATOS', style: TextStyle(fontWeight: FontWeight.bold))),
          ListTile(
            title: const Text('Crear Backup'),
            leading: const Icon(Icons.backup),
            onTap: () {
              // Llamar a la lógica de backup
              print("Crear backup (simulado)");
            },
          ),
          ListTile(
            title: const Text('Restaurar desde Backup'),
            leading: const Icon(Icons.restore),
            onTap: () {
              // Llamar a la lógica de restauración
              print("Restaurar backup (simulado)");
            },
          ),
          ListTile(
            title: const Text('Importar Canción'),
            leading: const Icon(Icons.file_upload),
            onTap: () {
              // Llamar a la lógica de importación
              print("Importar canción (simulado)");
            },
          ),
          // --- ELIMINADO: Botón de Importar Datos de Prueba ---
          // ListTile(
          //   title: const Text('Importar Datos de Prueba'),
          //   leading: const Icon(Icons.upload_file),
          //   onTap: () async {
          //     await _importarDatosPrueba(context, songRepository);
          //   },
          // ),
        ],
      ),
    );
  }

  // --- CORRECCIÓN 1: Definir la función como un método estático o moverla ---
  // Dado que SettingsScreen es Stateless, la función no puede ser un método de instancia
  // porque FutureBuilder la llama antes de que el widget se construya completamente.
  // La mejor práctica es usar una función estática o moverla a un servicio/provider.
  // Para este caso, una función estática es suficiente.
  static Future<double> _loadScrollFactor() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble('scroll_factor_adjust') ?? 1.0;
  }
}