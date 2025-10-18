import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cancionero_liturgico/models/song.dart';
import 'package:cancionero_liturgico/screens/song_detail_screen.dart';
import 'package:cancionero_liturgico/services/song_provider.dart';
import 'package:cancionero_liturgico/widgets/song_item.dart';

class SongSearchDelegate extends SearchDelegate<Song?> {
  final List<Song> searchList;

  SongSearchDelegate(this.searchList);

  @override
  String get searchFieldLabel => 'Buscar en título, autor o letra...';

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
          showSuggestions(context);
        },
      ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildResultsAndSuggestions();
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return _buildResultsAndSuggestions();
  }

  Widget _buildResultsAndSuggestions() {
    final lowerCaseQuery = query.toLowerCase();
    final results = searchList.where((song) {
      return song.title.toLowerCase().contains(lowerCaseQuery) ||
          (song.author?.toLowerCase().contains(lowerCaseQuery) ?? false) ||
          song.content.toLowerCase().contains(lowerCaseQuery);
    }).toList();

    if (results.isEmpty && query.isNotEmpty) {
      return const Center(
        child: Text('No se encontraron resultados.'),
      );
    }

    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (context, index) {
        final song = results[index];
        return SongItem(
          song: song,
          onTap: () {
            // Cerrar la búsqueda y navegar al detalle
            close(context, song);
          },
        );
      },
    );
  }
}
