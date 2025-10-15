import 'package:flutter/material.dart';
import '../models/category_model.dart';
import '../services/category_repository.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({Key? key}) : super(key: key);

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  final CategoryRepository _repository = CategoryRepository();
  List<Category> _categories = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      _categories = await _repository.getCategories();
    } catch (e) {
      print("Error loading categories: $e");
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _createNewCategory() {
    showDialog(
      context: context,
      builder: (context) => CategoryEditDialog(
        onSave: (category) async {
          try {
            await _repository.insertCategory(category);
            await _loadCategories();
          } catch (e) {
            print("Error creating category: $e");
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Categorías'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _createNewCategory,
            tooltip: 'Nueva Categoría',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildCategoriesList(),
    );
  }

  Widget _buildCategoriesList() {
    final predefinedCategories = _categories.where((c) => c.isPredefined).toList();
    final customCategories = _categories.where((c) => !c.isPredefined).toList();

    return ListView(
      children: [
        if (predefinedCategories.isNotEmpty) ...[
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Categorías Predefinidas',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          ...predefinedCategories.map((category) => _buildCategoryCard(category)),
        ],
        
        if (customCategories.isNotEmpty) ...[
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Mis Categorías',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          ...customCategories.map((category) => _buildCategoryCard(category)),
        ],

        if (_categories.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Text(
                'No hay categorías\nToca + para crear tu primera categoría',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildCategoryCard(Category category) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: _parseColor(category.color),
            shape: BoxShape.circle,
          ),
        ),
        title: Text(category.name),
        subtitle: category.isPredefined 
            ? const Text('Predefinida')
            : null,
        trailing: category.isPredefined
            ? null
            : IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () => _deleteCategory(category),
              ),
      ),
    );
  }

  Color _parseColor(String colorString) {
    try {
      return Color(int.parse(colorString.replaceFirst('#', '0xff')));
    } catch (e) {
      return Colors.blue;
    }
  }

  void _deleteCategory(Category category) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Categoría'),
        content: Text('¿Estás seguro de eliminar "${category.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await _repository.deleteCategory(category.id!);
                await _loadCategories();
              } catch (e) {
                print("Error deleting category: $e");
              }
            },
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class CategoryEditDialog extends StatefulWidget {
  final Function(Category) onSave;

  const CategoryEditDialog({Key? key, required this.onSave}) : super(key: key);

  @override
  State<CategoryEditDialog> createState() => _CategoryEditDialogState();
}

class _CategoryEditDialogState extends State<CategoryEditDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _colorController = TextEditingController(text: '#2196F3');

  final _colors = [
    {'name': 'Azul', 'value': '#2196F3'},
    {'name': 'Verde', 'value': '#4CAF50'},
    {'name': 'Rojo', 'value': '#F44336'},
    {'name': 'Amarillo', 'value': '#FFEB3B'},
    {'name': 'Naranja', 'value': '#FF9800'},
    {'name': 'Púrpura', 'value': '#9C27B0'},
    {'name': 'Rosa', 'value': '#E91E63'},
    {'name': 'Cyan', 'value': '#00BCD4'},
  ];

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Nueva Categoría'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Nombre de la categoría',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Por favor ingresa un nombre';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _colorController.text,
              decoration: const InputDecoration(
                labelText: 'Color',
                border: OutlineInputBorder(),
              ),
              items: _colors.map((color) {
                return DropdownMenuItem(
                  value: color['value'],
                  child: Row(
                    children: [
                      Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: _parseColor(color['value']!),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(color['name']!),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _colorController.text = value!;
                });
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _saveCategory,
          child: const Text('Crear'),
        ),
      ],
    );
  }

  Color _parseColor(String colorString) {
    return Color(int.parse(colorString.replaceFirst('#', '0xff')));
  }

  void _saveCategory() {
    if (_formKey.currentState!.validate()) {
      final category = Category(
        name: _nameController.text,
        color: _colorController.text,
        order: 0,
        isPredefined: false,
      );
      widget.onSave(category);
      Navigator.pop(context);
    }
  }
}