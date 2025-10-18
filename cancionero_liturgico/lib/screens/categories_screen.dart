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
  late Future<List<Category>> _allCategoriesFuture;
  late Future<List<Category>> _customCategoriesFuture;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() => setState(() {})); // Para reconstruir y actualizar el FAB
    _loadCategories();
  }

  void _loadCategories() {
    final categoryRepository = Provider.of<CategoryRepository>(context, listen: false);
    _allCategoriesFuture = categoryRepository.getAllCategories();
    _customCategoriesFuture = categoryRepository.getCustomCategories();
  }

  void _refreshCategories() {
    setState(() {
      _loadCategories();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
          _CategoryListView(
            key: const PageStorageKey('allCategories'),
            future: _allCategoriesFuture,
            onRefresh: _refreshCategories,
            reorderable: true, // Habilitar reordenamiento
          ),
          _CategoryListView(
            key: const PageStorageKey('customCategories'),
            future: _customCategoriesFuture,
            onRefresh: _refreshCategories,
            reorderable: true, // Habilitar reordenamiento
          ),
        ],
      ),
      floatingActionButton: _tabController.index == 1
          ? FloatingActionButton(
              onPressed: () => _showCategoryDialog(),
              tooltip: 'Crear categoría',
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  void _showCategoryDialog({Category? category}) {
    final isEditing = category != null;
    final TextEditingController nameController = TextEditingController(text: category?.name ?? '');
    String selectedColor = category?.color ?? '#FF5722'; // Color por defecto

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(isEditing ? 'Editar Categoría' : 'Nueva Categoría'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: 'Nombre'),
                    autofocus: true,
                  ),
                  const SizedBox(height: 20),
                  Wrap(
                    spacing: 8.0,
                    children: [
                      _buildColorChip(context, '#FF5722', selectedColor, (color) => setDialogState(() => selectedColor = color)),
                      _buildColorChip(context, '#4CAF50', selectedColor, (color) => setDialogState(() => selectedColor = color)),
                      _buildColorChip(context, '#2196F3', selectedColor, (color) => setDialogState(() => selectedColor = color)),
                      _buildColorChip(context, '#FFC107', selectedColor, (color) => setDialogState(() => selectedColor = color)),
                      _buildColorChip(context, '#9C27B0', selectedColor, (color) => setDialogState(() => selectedColor = color)),
                    ],
                  )
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final name = nameController.text.trim();
                    if (name.isNotEmpty) {
                      final categoryRepository = Provider.of<CategoryRepository>(context, listen: false);
                      final newCategory = Category(
                        id: category?.id,
                        name: name,
                        color: selectedColor,
                        isPredefined: category?.isPredefined ?? false, // Preservar el estado
                      );

                      if (isEditing) {
                        await categoryRepository.updateCategory(newCategory);
                      } else {
                        await categoryRepository.insertCategory(newCategory);
                      }
                      _refreshCategories();
                      if (context.mounted) Navigator.pop(context);
                    }
                  },
                  child: const Text('Guardar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildColorChip(BuildContext context, String color, String selectedColor, Function(String) onSelect) {
    final colorValue = _parseColor(color);
    return GestureDetector(
      onTap: () => onSelect(color),
      child: CircleAvatar(
        radius: 18,
        backgroundColor: colorValue,
        child: selectedColor == color ? const Icon(Icons.check, color: Colors.white) : null,
      ),
    );
  }
}

Color _parseColor(String? hexColor) {
  hexColor = hexColor?.toUpperCase().replaceAll("#", "");
  if (hexColor == null || hexColor.length != 6) {
    return Colors.grey; // Color por defecto si el formato es incorrecto
  }
  try {
    return Color(int.parse(hexColor, radix: 16) + 0xFF000000);
  } catch (e) {
    return Colors.grey;
  }
}

class _CategoryListView extends StatefulWidget {
  final Future<List<Category>> future;
  final VoidCallback onRefresh;
  final bool reorderable;

  const _CategoryListView({super.key, required this.future, required this.onRefresh, this.reorderable = false});

  @override
  State<_CategoryListView> createState() => _CategoryListViewState();
}

class _CategoryListViewState extends State<_CategoryListView> {
  List<Category> _categories = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void didUpdateWidget(covariant _CategoryListView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.future != oldWidget.future) {
      _loadData();
    }
  }

  void _loadData() {
    setState(() {
      _isLoading = true;
    });
    widget.future.then((value) {
      if (mounted) {
        setState(() {
          _categories = value;
          _isLoading = false;
        });
      }
    });
  }

  Widget _buildCategoryTile(Category category, int index) {
    final categoryColor = _parseColor(category.color);
    return Card(
      key: ValueKey(category.id),
      color: categoryColor.withOpacity(0.1),
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      child: ListTile(
        leading: Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: categoryColor,
            shape: BoxShape.circle,
          ),
        ),
        title: Text(category.name, style: const TextStyle(fontWeight: FontWeight.w500)),
        subtitle: category.isPredefined ? const Text('Categoría predefinida', style: TextStyle(fontSize: 12)) : null,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            FutureBuilder<int>(
              future: Provider.of<CategoryRepository>(context, listen: false).getSongCountForCategory(category.id!),
              builder: (context, countSnapshot) {
                if (countSnapshot.connectionState == ConnectionState.waiting) {
                  return const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2));
                } else if (countSnapshot.hasData && countSnapshot.data! > 0) {
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
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'edit') {
                  (context as Element).findAncestorStateOfType<_CategoriesScreenState>()?._showCategoryDialog(category: category);
                } else if (value == 'delete') {
                  _confirmDelete(context, category, widget.onRefresh);
                }
              },
              itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                const PopupMenuItem<String>(
                  value: 'edit',
                  child: Text('Editar'),
                ),
                if (!category.isPredefined)
                  const PopupMenuItem<String>(
                    value: 'delete',
                    child: Text('Eliminar'),
                  ),
              ],
            ),
            if (widget.reorderable)
              ReorderableDragStartListener(
                index: index,
                child: const Padding(
                  padding: EdgeInsets.only(left: 12.0, right: 4.0),
                  child: Icon(Icons.drag_handle),
                ),
              ),
          ],
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SongListScreen(categoryId: category.id),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_categories.isEmpty && widget.reorderable) {
      // Asumimos que una lista reordenable vacía es la de personalizadas
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            'Aún no tienes categorías personalizadas.\n¡Crea una con el botón +!',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ),
      );
    }

    if (widget.reorderable) {
      return ReorderableListView.builder(
        padding: const EdgeInsets.all(8.0),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final category = _categories[index];
          return _buildCategoryTile(category, index);
        },
        onReorder: (oldIndex, newIndex) {
          setState(() {
            if (newIndex > oldIndex) {
              newIndex -= 1;
            }
            final item = _categories.removeAt(oldIndex);
            _categories.insert(newIndex, item);
          });
          Provider.of<CategoryRepository>(context, listen: false).updateCategoryOrder(_categories);
        },
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8.0),
      itemCount: _categories.length,
      itemBuilder: (context, index) {
        final category = _categories[index];
        return _buildCategoryTile(category, index);
      },
    );
  }

  void _confirmDelete(BuildContext context, Category category, VoidCallback onRefresh) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmar Eliminación'),
          content: Text('¿Estás seguro de que quieres eliminar la categoría "${category.name}"? Las canciones no se eliminarán, solo se quitarán de esta categoría.'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
              onPressed: () async {
                final categoryRepository = Provider.of<CategoryRepository>(context, listen: false);
                await categoryRepository.deleteCategory(category.id!);
                onRefresh();
                if (context.mounted) Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}
