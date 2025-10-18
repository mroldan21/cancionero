import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cancionero_liturgico/models/category.dart';
import 'package:cancionero_liturgico/models/song.dart';
import 'package:cancionero_liturgico/services/category_repository.dart';
import 'package:cancionero_liturgico/services/song_repository.dart';
import 'package:cancionero_liturgico/screens/song_list_screen.dart';
import 'package:cancionero_liturgico/widgets/song_search_delegate.dart';
import 'package:cancionero_liturgico/services/song_provider.dart';
import 'package:cancionero_liturgico/screens/song_detail_screen.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this); // 0: Todas, 1: Personalizadas
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    print("[SCREEN] Build: CategoriesScreen");
    return Scaffold(
      appBar: AppBar(
        title: const Text('Categorías'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: 'Buscar canción',
            onPressed: () async {
              final songRepository = Provider.of<SongRepository>(context, listen: false);
              final songs = await songRepository.getAllSongs();
              if (!context.mounted) return;

              final selectedSong = await showSearch<Song?>(
                context: context,
                delegate: SongSearchDelegate(songs),
              );

              if (selectedSong != null && context.mounted) {
                Provider.of<SongProvider>(context, listen: false).setSelectedSong(selectedSong);
                Navigator.push(context, MaterialPageRoute(builder: (context) => SongDetailScreen(song: selectedSong)));
              }
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Todas'),
            Tab(text: 'Personalizadas'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Vista de Todas las Categorías
          _CategoryListView(
            future: Provider.of<CategoryRepository>(context, listen: false).getAllCategories(),
          ),
          // Vista de Categorías Personalizadas
          _CategoryListView(
            future: Provider.of<CategoryRepository>(context, listen: false).getCustomCategories(),
          ),
        ],
      ),
    );
  }
}

// Widget separado para la lista de categorías, reutilizable en las pestañas
class _CategoryListView extends StatelessWidget {
  final Future<List<Category>> future;

  const _CategoryListView({required this.future});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Category>>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else {
          final categories = snapshot.data ?? [];
          return ListView.builder(
            itemCount: categories.length,
            padding: const EdgeInsets.all(8.0), // Añadir padding alrededor de la lista
            itemBuilder: (context, index) {
              final category = categories[index];
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 4.0),
                child: ListTile(
                  leading: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: Color(int.tryParse(category.color?.substring(1, 7) ?? '000000', radix: 16) ?? 0xFF000000),
                      shape: BoxShape.circle,
                    ),
                  ),
                  title: Text(category.name, style: const TextStyle(fontWeight: FontWeight.w500)),
                  subtitle: category.isPredefined ? const Text('Categoría predefinida', style: TextStyle(fontSize: 12)) : null,
                  trailing: FutureBuilder<int>(
                    // MEJORA: Obtener y mostrar la cantidad de canciones por categoría
                    future: Provider.of<CategoryRepository>(context, listen: false).getSongCountForCategory(category.id!),
                    builder: (context, countSnapshot) {
                      if (countSnapshot.connectionState == ConnectionState.waiting) {
                        return const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2));
                      } else if (countSnapshot.hasData && countSnapshot.data! > 0) {
                        // MEJORA: Mostrar la cantidad como un "bullet" o insignia
                        return CircleAvatar(
                          radius: 12,
                          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                          child: Text(
                            '${countSnapshot.data}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.onPrimaryContainer,
                            ),
                          ),
                        );
                      } else {
                        return const SizedBox.shrink();
                      }
                    },
                  ), 
                  onTap: () {
                    // Navegar a una lista de canciones filtradas por esta categoría
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SongListScreen(categoryId: category.id),
                      ),
                    );
                  },
                ),
              );
            },
          );
        }
      },
    );
  }
}
