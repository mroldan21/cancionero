import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/theme_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuración'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Tema
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Apariencia',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.light_mode),
                      const SizedBox(width: 12),
                      const Text('Modo oscuro'),
                      const Spacer(),
                      Switch(
                        value: themeProvider.themeMode == ThemeMode.dark,
                        onChanged: (value) {
                          themeProvider.setThemeMode(
                            value ? ThemeMode.dark : ThemeMode.light,
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Scroll automático
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Scroll Automático',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Row(
                    children: [
                      Icon(Icons.speed),
                      SizedBox(width: 12),
                      Text('Velocidad predeterminada'),
                      Spacer(),
                      Text('Medio'),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Slider(
                    value: 0.5,
                    onChanged: (value) {},
                    divisions: 4,
                    label: 'Medio',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Backup y datos
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Datos y Backup',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ListTile(
                    leading: const Icon(Icons.backup),
                    title: const Text('Crear Backup'),
                    onTap: () {
                      _showBackupDialog(context);
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.restore),
                    title: const Text('Restaurar Backup'),
                    onTap: () {
                      _showRestoreDialog(context);
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.import_export),
                    title: const Text('Exportar todas las canciones'),
                    onTap: () {
                      _exportAllSongs(context);
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Información de la app
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Información',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const ListTile(
                    leading: Icon(Icons.info),
                    title: Text('Versión'),
                    subtitle: Text('1.0.0'),
                  ),
                  ListTile(
                    leading: const Icon(Icons.bug_report),
                    title: const Text('Reportar problema'),
                    onTap: () {
                      // TODO: Abrir enlace de reporte
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showBackupDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Crear Backup'),
        content: const Text('¿Deseas crear un backup de todas tus canciones y setlists?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              // TODO: Implementar backup
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Backup creado exitosamente')),
              );
            },
            child: const Text('Crear Backup'),
          ),
        ],
      ),
    );
  }

  void _showRestoreDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Restaurar Backup'),
        content: const Text('¿Estás seguro? Esta acción sobrescribirá todos los datos actuales.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              // TODO: Implementar restauración
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Datos restaurados exitosamente')),
              );
            },
            child: const Text('Restaurar'),
          ),
        ],
      ),
    );
  }

  void _exportAllSongs(BuildContext context) {
    // TODO: Implementar exportación
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Canciones exportadas exitosamente')),
    );
  }
}