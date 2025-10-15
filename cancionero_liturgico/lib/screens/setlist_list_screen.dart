import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // ← CORREGIDO
import '../services/song_provider.dart';  // ← CORREGIDO
import '../models/setlist.dart';          // ← CORREGIDO

class SetlistListScreen extends StatelessWidget {
  const SetlistListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Temporal: lista de setlists de ejemplo
    final setlists = [
      Setlist(
        name: 'Misa Domingo 10:00 AM',
        eventDate: DateTime.now().add(const Duration(days: 1)),
        notes: 'Misa dominical principal',
        songs: [],
      ),
      Setlist(
        name: 'Bautismo Juan Pérez',
        eventDate: DateTime.now().add(const Duration(days: 3)),
        notes: 'Ceremonia de bautismo',
        songs: [],
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Setlists'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              // TODO: Navegar a crear setlist
            },
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: setlists.length,
        itemBuilder: (context, index) {
          final setlist = setlists[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: ListTile(
              leading: const Icon(Icons.playlist_play),
              title: Text(setlist.name),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (setlist.eventDate != null)
                    Text('Fecha: ${_formatDate(setlist.eventDate!)}'),
                  Text('${setlist.songCount} canciones'),
                  if (setlist.notes.isNotEmpty)
                    Text(
                      setlist.notes,
                      style: Theme.of(context).textTheme.bodySmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
              trailing: IconButton(
                icon: const Icon(Icons.play_arrow),
                onPressed: () {
                  // TODO: Reproducir setlist
                },
              ),
              onTap: () {
                // TODO: Ver detalle del setlist
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: Crear nuevo setlist
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}