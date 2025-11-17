import 'package:cancionero_liturgico/models/song.dart';
import 'package:cancionero_liturgico/services/database_helper.dart';

class SongRepository {
  final DatabaseHelper _databaseHelper = DatabaseHelper();

  static const String _songColumns = '''
    s.id, s.titulo, s.autor, s.letra_con_acordes, s.tonalidad_original,
    s.tempo_bpm, s.posicion_capo, s.es_favorita, s.contador_reproducciones,
    s.fecha_creacion, s.fecha_modificacion, s.notas, s.enlaces_video, s.preferred_font_size,
    s.activo, s.estado, s.fuente, s.hash_contenido, s.version
  ''';
  // --- CRUD Canciones ---
  Future<List<Song>> getAllSongs() async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT 
        $_songColumns,
        GROUP_CONCAT(cc.categoria_id) as categoria_ids
      FROM songs s
      LEFT JOIN cancion_categoria cc ON s.id = cc.cancion_id
      GROUP BY s.id
    ''');

    List<Song> songs = [];
    for (var map in maps) {
      final song = Song.fromMap(map);
      songs.add(song);
    }
    return songs;
  }

  Future<List<Song>> getSongsByCategory(int categoryId) async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT 
        $_songColumns,
        GROUP_CONCAT(cc.categoria_id) as categoria_ids
      FROM songs s
      INNER JOIN cancion_categoria cc ON s.id = cc.cancion_id
      WHERE cc.categoria_id = ?
      GROUP BY s.id
    ''', [categoryId]);

    List<Song> songs = [];
    for (var map in maps) {
      final song = Song.fromMap(map);
      songs.add(song);
    }
    return songs;
  }

  Future<List<Song>> getSongsByCategories(List<int> categoryIds) async {
    if (categoryIds.isEmpty) return getAllSongs();

    final db = await _databaseHelper.database;
    final placeholders = List.filled(categoryIds.length, '?').join(',');
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT 
        $_songColumns,
        GROUP_CONCAT(cc.categoria_id) as categoria_ids
      FROM songs s
      INNER JOIN cancion_categoria cc ON s.id = cc.cancion_id
      WHERE cc.categoria_id IN ($placeholders)
      GROUP BY s.id
    ''', categoryIds);

    List<Song> songs = [];
    for (var map in maps) {
      final song = Song.fromMap(map);
      songs.add(song);
    }
    return songs;
  }

  Future<List<Song>> searchSongs(String query) async {
    if (query.isEmpty) return getAllSongs();

    final db = await _databaseHelper.database;
    final lowerQuery = query.toLowerCase();
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT 
        $_songColumns,
        GROUP_CONCAT(cc.categoria_id) as categoria_ids
      FROM songs s
      LEFT JOIN cancion_categoria cc ON s.id = cc.cancion_id
      WHERE LOWER(s.titulo) LIKE ? 
         OR LOWER(s.autor) LIKE ? 
         OR LOWER(s.letra_con_acordes) LIKE ? 
         OR LOWER(s.notas) LIKE ?
      GROUP BY s.id
    ''', ['%$lowerQuery%', '%$lowerQuery%', '%$lowerQuery%', '%$lowerQuery%']);

    List<Song> songs = [];
    for (var map in maps) {
      final song = Song.fromMap(map);
      songs.add(song);
    }
    return songs;
  }

  Future<List<Song>> getFavoriteSongs() async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT 
        $_songColumns,
        GROUP_CONCAT(cc.categoria_id) as categoria_ids
      FROM songs s
      LEFT JOIN cancion_categoria cc ON s.id = cc.cancion_id
      WHERE s.es_favorita = 1
      GROUP BY s.id
    ''');

    List<Song> songs = [];
    for (var map in maps) {
      final song = Song.fromMap(map);
      songs.add(song);
    }
    return songs;
  }

  Future<Song?> getSongById(int songId) async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT 
        $_songColumns,
        GROUP_CONCAT(cc.categoria_id) as categoria_ids
      FROM songs s
      LEFT JOIN cancion_categoria cc ON s.id = cc.cancion_id
      WHERE s.id = ?
      GROUP BY s.id
    ''', [songId]);

    if (maps.isNotEmpty) {
      final song = Song.fromMap(maps.first);
      return song;
    }

    return null;
  }

  Future<int> insertSong(Song song) async {
    final db = await _databaseHelper.database;
    print("🎵 INSERT SONG: '${song.title}' con ${song.categoryIds.length} categorías");
    final int songId = await db.transaction((txn) async {
      return await txn.insert('songs', song.toMap());
    });
    // Debug de categorías después de insertar
    final categoriasDebug = await db.query('cancion_categoria', where: 'cancion_id = ?', whereArgs: [songId]);
    print("🏷️  RELACIONES CREADAS: ${categoriasDebug.length} para canción $songId");
    return songId;
  }

  Future<void> updateSong(Song song) async {
    if (song.id == null) return;

    final db = await _databaseHelper.database;
    await db.transaction((txn) async {
      await txn.update('songs', song.toMap(), where: 'id = ?', whereArgs: [song.id]);
    });
  }

  Future<void> deleteSong(int id) async {
    final db = await _databaseHelper.database;
    await db.delete('songs', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> setCategoriasForSong(int songId, List<int> categoryIds) async {
    final db = await _databaseHelper.database;
    await db.transaction((txn) async {
      await txn.delete('cancion_categoria', where: 'cancion_id = ?', whereArgs: [songId]);

      for (int catId in categoryIds) {
        await txn.insert('cancion_categoria', {
          'cancion_id': songId,
          'categoria_id': catId,
        });
      }
    });
  }

  Future<List<int>> getCategoriaIdsForSong(int songId) async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'cancion_categoria',
      columns: ['categoria_id'],
      where: 'cancion_id = ?',
      whereArgs: [songId],
    );
    return maps.map((map) => map['categoria_id'] as int).toList();
  }

  Future<void> toggleFavorite(int songId) async {
    final db = await _databaseHelper.database;
    // SOLUCIÓN: Usar una única consulta atómica para invertir el estado de favorito
    // y actualizar la fecha de modificación.
    await db.rawUpdate('''
      UPDATE songs 
      SET es_favorita = CASE WHEN es_favorita = 1 THEN 0 ELSE 1 END,
          fecha_modificacion = ?
      WHERE id = ?
    ''', [DateTime.now().toIso8601String(), songId]);
  }

  Future<void> incrementPlayCount(int songId) async {
    final db = await _databaseHelper.database;
    await db.rawUpdate('''
      UPDATE songs 
      SET contador_reproducciones = contador_reproducciones + 1, 
          fecha_modificacion = ? 
      WHERE id = ?
    ''', [DateTime.now().toIso8601String(), songId]);
  }

  // Nuevo método para obtener canciones modificadas después de una fecha (usado por SyncService)
  Future<List<Song>> getModifiedSongsAfter(DateTime date) async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT 
        $_songColumns,
        GROUP_CONCAT(cc.categoria_id) as categoria_ids
      FROM songs s
      LEFT JOIN cancion_categoria cc ON s.id = cc.cancion_id
      WHERE s.fecha_modificacion > ?
      GROUP BY s.id
    ''', [date.toIso8601String()]);

    List<Song> songs = [];
    for (var map in maps) {
      final song = Song.fromMap(map);
      songs.add(song);
    }
    return songs;
  }

  // Nuevo método para verificar si una canción existe (usado por SyncService)
  Future<bool> songExists(int songId) async {
    final db = await _databaseHelper.database;
    final result = await db.query(
      'songs',
      columns: ['id'],
      where: 'id = ?',
      whereArgs: [songId],
    );
    return result.isNotEmpty;
  }
}
