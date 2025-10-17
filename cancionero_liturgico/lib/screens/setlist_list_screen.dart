import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cancionero_liturgico/models/setlist_model.dart';
import 'package:cancionero_liturgico/services/song_repository.dart';
import 'package:cancionero_liturgico/screens/setlist_management_screen.dart';

class SetlistListScreen extends StatelessWidget {
  const SetlistListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Setlists')),
      body: FutureBuilder<List<Setlist>>(
        future: Provider.of<SongRepository>(context, listen: false).getAllSetlists(),
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
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SetlistManagementScreen(setlist: setlist), // Pasar el setlist para edición
                      ),
                    );
                  },
                );
              },
            );
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const SetlistManagementScreen()), // Pasar null para nuevo setlist
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}