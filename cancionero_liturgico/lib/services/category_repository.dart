import '../models/category_model.dart';
import 'database_helper.dart';

class CategoryRepository {
  final DatabaseHelper _databaseHelper = DatabaseHelper();

  Future<List<Category>> getCategories() async {
    return await _databaseHelper.getCategories();
  }

  Future<int> insertCategory(Category category) async {
    return await _databaseHelper.insertCategory(category);
  }

  Future<int> updateCategory(Category category) async {
    return await _databaseHelper.updateCategory(category);
  }

  Future<int> deleteCategory(int id) async {
    return await _databaseHelper.deleteCategory(id);
  }

  Future<void> addCategoryToSong(int songId, int categoryId) async {
    return await _databaseHelper.addCategoryToSong(songId, categoryId);
  }

  Future<void> removeCategoryFromSong(int songId, int categoryId) async {
    return await _databaseHelper.removeCategoryFromSong(songId, categoryId);
  }

  Future<List<Category>> getCategoriesForSong(int songId) async {
    return await _databaseHelper.getCategoriesForSong(songId);
  }

  Future<List<Song>> getSongsByCategory(int categoryId) async {
    // TODO: Implementar cuando esté listo
    return [];
  }
}