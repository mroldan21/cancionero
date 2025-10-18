import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cancionero_liturgico/models/setlist_model.dart';
import 'package:cancionero_liturgico/screens/song_detail_screen.dart';
import 'package:cancionero_liturgico/services/song_repository.dart';
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
  }

  void _loadSetlists() {
    setState(() {
      _setlistsFuture = Provider.of<SongRepository>(context, listen: false).getAllSetlists();
    });
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
    return Scaffold(
      appBar: AppBar(title: const Text('Setlists')),
      body: FutureBuilder<List<Setlist>>(
        future: _setlistsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else {
            final setlists = snapshot.data ?? [];
            return ListView.builder(
              itemCount: setlists.length,
              itemBuilder: (context, index) {
                final setlist = setlists[index];
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
                          child: const Icon(Icons.play_arrow, size: 24),
                        ),
                      const SizedBox(width: 8), // Espacio entre el botón de play y el de editar
                      const Icon(Icons.chevron_right), // Icono para editar
                    ],
                  ),
                  onTap: () {
                    _navigateAndRefresh(SetlistManagementScreen(setlist: setlist));
                  },
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