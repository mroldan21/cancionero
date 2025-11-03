import 'package:cancionero_liturgico/models/category.dart';
import 'package:cancionero_liturgico/services/database_helper.dart';

class CategoryRepository {
  final DatabaseHelper _databaseHelper = DatabaseHelper();

  Future<List<Category>> getAllCategories() async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query('categories', orderBy: 'orden ASC, nombre ASC');

    return List.generate(maps.length, (i) {
      return Category.fromMap(maps[i]);
    });
  }

  Future<List<String>> getAllCategoryNames() async {
    final categories = await getAllCategories();
    return categories.map((category) => category.name).toList();
  }

  // Nuevo método para obtener categorías predefinidas
  Future<List<Category>> getPredefinedCategories() async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'categories',
      where: 'es_predefinida = ?',
      whereArgs: [1], // 1 para true
      orderBy: 'orden ASC, nombre ASC',
    );

    return List.generate(maps.length, (i) {
      return Category.fromMap(maps[i]);
    });
  }

  // Nuevo método para obtener categorías personalizadas
  Future<List<Category>> getCustomCategories() async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'categories',
      where: 'es_predefinida = ?',
      whereArgs: [0], // 0 para false
      orderBy: 'nombre ASC',
    );

    return List.generate(maps.length, (i) {
      return Category.fromMap(maps[i]);
    });
  }

  Future<void> insertCategory(Category category) async {
    final db = await _databaseHelper.database;
    await db.insert('categories', category.toMap());
  }

  Future<void> updateCategory(Category category) async {
    if (category.id == null) return; // No se puede actualizar sin ID

    final db = await _databaseHelper.database;
    await db.update('categories', category.toMap(),
        where: 'id = ?', whereArgs: [category.id]);
  }

  Future<void> deleteCategory(int id) async {
    final db = await _databaseHelper.database;
    // Debido a ON DELETE CASCADE en la base de datos, se eliminarán
    // automáticamente las entradas en cancion_categoria.
    await db.delete('categories', where: 'id = ?', whereArgs: [id]);
  }

  // Nuevo método para verificar si una categoría es predefinida
  Future<bool> isPredefinedCategory(int categoryId) async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'categories',
      columns: ['es_predefinida'],
      where: 'id = ?',
      whereArgs: [categoryId],
    );
    if (maps.isNotEmpty) {
      return (maps.first['es_predefinida'] as int) == 1;
    }
    return false; // Si no existe, no es predefinida
  }

  Future<int> getSongCountForCategory(int categoryId) async {
    final db = await _databaseHelper.database;
    final result = await db.rawQuery('''
      SELECT COUNT(*) as count
      FROM cancion_categoria
      WHERE categoria_id = ?
    ''', [categoryId]);
    final count = result.first['count'] as int;
    return count;
  }

  Future<void> updateCategoryOrder(List<Category> categories) async {
    final db = await _databaseHelper.database;
    final batch = db.batch();
    for (var i = 0; i < categories.length; i++) {
      final category = categories[i];
      batch.update('categories', {'orden': i}, where: 'id = ?', whereArgs: [category.id]);
    }
    await batch.commit(noResult: true);
  }

  // Nuevo método para obtener nombres de categorías por sus IDs (usado por SyncService)
  Future<List<String>> getCategoryNamesByIds(List<int> ids) async {
    if (ids.isEmpty) {
      return [];
    }
    final db = await _databaseHelper.database;
    final placeholders = List.filled(ids.length, '?').join(',');
    final List<Map<String, dynamic>> maps = await db.query(
      'categories',
      columns: ['nombre'],
      where: 'id IN ($placeholders)',
      whereArgs: ids,
    );

    return maps.map((map) => map['nombre'] as String).toList();
  }

  // Nuevo método para obtener una categoría por su nombre (usado por SyncService)
  Future<Category?> getCategoryByName(String name) async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'categories',
      where: 'LOWER(nombre) = LOWER(?)', // Búsqueda insensible a mayúsculas
      whereArgs: [name],
      limit: 1,
    );

    if (maps.isNotEmpty) {
      return Category.fromMap(maps.first);
    }
    return null;
  }

  // Nuevo método para obtener o crear una categoría por su nombre (usado por SyncService)
  Future<Category> getOrCreateCategoryByName(String name) async {
    final db = await _databaseHelper.database; // CORRECCIÓN: Faltaba inicializar la instancia de la BD.
    Category? category = await getCategoryByName(name);
    if (category == null) {
      // Crear categoría personalizada si no existe
      final newCategory = Category(
        name: name, // CORRECCIÓN: El parámetro del constructor es 'name', no 'nombre'.
        color: '#607D8B', // Color por defecto para categorías personalizadas
        isPredefined: false, // CORRECCIÓN: El parámetro del constructor es 'isPredefined', no 'esPredefinida'.
      );
      final newId = await db.insert('categories', newCategory.toMap());
      category = newCategory.copyWith(id: newId);
    }
    // Aseguramos que la categoría devuelta tenga un ID
    // Si la categoría existía, ya tenía ID. Si se creó, se lo acabamos de asignar.
    // El '!' es seguro aquí porque la lógica anterior garantiza que no será nulo.
    return category!;
  }
}