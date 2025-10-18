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

  // Nuevo método para contar canciones asociadas a una categoría
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
}