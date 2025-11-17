import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/database_helper.dart';
import 'package:cancionero_liturgico/models/setlist_model.dart';
import 'package:cancionero_liturgico/screens/song_detail_screen.dart';
import 'package:cancionero_liturgico/services/setlist_repository.dart';
import 'package:cancionero_liturgico/screens/setlist_management_screen.dart';
import 'package:cancionero_liturgico/services/song_provider.dart';

class SetlistListScreen extends StatefulWidget {
  const SetlistListScreen({super.key});

  @override
  State<SetlistListScreen> createState() => _SetlistListScreenState();
}

class _SetlistListScreenState extends State<SetlistListScreen> {
  late Future<List<Setlist>> _setlistsFuture;

  @override
  void initState() {
    super.initState();
    _loadSetlists();
    _debugBD(); // Agrega esta línea
  }

  void _loadSetlists() {
    setState(() {
      _setlistsFuture = Provider.of<SetlistRepository>(context, listen: false).getAllSetlists();
    });
  }

  void _debugBD() async {
    print("DEBUG: _debugBD() iniciado"); // ← Agrega esta línea
    // Espera un poco para que la BD esté lista
    await Future.delayed(Duration(milliseconds: 500));
    final databaseHelper = DatabaseHelper();
    await databaseHelper.debugBDCompleta();
  }

  Future<void> _navigateAndRefresh(Widget screen) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => screen),
    );
    if (result == true) {
      _loadSetlists();
    }
  }

  @override
  Widget build(BuildContext context) {
    print("[SCREEN] Build: SetlistListScreen");
    return Scaffold(
      appBar: AppBar(title: const Text('Eventos programados')),
      body: FutureBuilder<List<Setlist>>(
        future: _setlistsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            // SOLICITUD: Reemplazar el indicador de carga simple por uno grande y centrado.
            return Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 100,
                    height: 100,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  Icon(Icons.sync,
                      size: 60, color: Theme.of(context).colorScheme.primary),
                ],
              ),
            );
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else {
            final setlists = snapshot.data ?? [];
            return ListView.builder(
              itemCount: setlists.length,
              itemBuilder: (context, index) {
                final setlist = setlists[index];
                // SOLICITUD: Imprimir todos los parámetros del setlist para depuración.
                print("""
                  [DEBUG] SetlistListScreen build item:
                    - Setlist ID: ${setlist.id}
                    - Name: ${setlist.name}
                    - Event Date: ${setlist.eventDate?.toIso8601String()}
                    - Notes: ${setlist.notes}
                    - Song Count: ${setlist.songs.length}
                    - Creation Date: ${setlist.creationDate.toIso8601String()}
                    - Modification Date: ${setlist.modificationDate.toIso8601String()}
                  """); // Fin del print de depuración
                return ListTile(
                  title: Text(setlist.name),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (setlist.eventDate != null) Text('Fecha: ${setlist.eventDate!.toString().split(' ').first}'), // Mostrar solo la fecha
                      Text('Canciones: ${setlist.songs.length}'), // Mostrar cantidad de canciones
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (setlist.songs.isNotEmpty) // Solo mostrar el botón si hay canciones
                        ElevatedButton(
                          onPressed: () {
                            final songProvider = Provider.of<SongProvider>(context, listen: false);
                            // Establecer la primera canción del setlist como la activa
                            songProvider.setSelectedSetlistItem(setlist.songs.first, 0);

                            // Navegar a la pantalla de detalle, que actuará como modo presentación
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => SongDetailScreen(song: setlist.songs.first.song, setlistItems: setlist.songs),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            shape: const CircleBorder(),
                            padding: const EdgeInsets.all(8),
                            backgroundColor: Theme.of(context).colorScheme.primary,
                            foregroundColor: Theme.of(context).colorScheme.onPrimary,
                          ),
                          child: const Icon(Icons.play_arrow, size: 30),
                        ),
                      const SizedBox(width: 8), // Espacio entre el botón de play y el de editar
                      // SOLICITUD: Reemplazar el icono de chevron por un botón de edición más claro y con mejor espaciado.
                      IconButton(
                        icon: const Icon(Icons.edit),
                        tooltip: 'Editar Setlist',
                        style: IconButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
                          foregroundColor: Theme.of(context).colorScheme.onSecondaryContainer,
                        ),
                        onPressed: () {
                          _navigateAndRefresh(SetlistManagementScreen(setlist: setlist));
                        },
                      ),
                    ],
                  ),
                );
              },
            );
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _navigateAndRefresh(const SetlistManagementScreen());
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}