import 'package:sqflite/sqflite.dart';
import 'package:cancionero_liturgico/models/song.dart';
import 'package:cancionero_liturgico/models/setlist_model.dart';
import 'package:cancionero_liturgico/models/setlist.dart'; // Importa SetlistItem
import 'package:cancionero_liturgico/services/database_helper.dart';

class SongRepository {
  final DatabaseHelper _databaseHelper = DatabaseHelper();

  // --- CRUD Canciones ---
  Future<List<Song>> getAllSongs() async {
    final db = await _databaseHelper.database;
    // Consulta para obtener todas las canciones con sus categorías
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT s.*, GROUP_CONCAT(cc.categoria_id) as categoria_ids
      FROM songs s
      LEFT JOIN cancion_categoria cc ON s.id = cc.cancion_id
      GROUP BY s.id
    ''');

    List<Song> songs = [];
    for (var map in maps) {
      final song = Song.fromMap(map);
      // Opcional: Cargar las categorías aquí si es necesario para la UI principal
      // song.categories = await getCategoriasPorCancion(song.id!);
      songs.add(song);
    }
    return songs;
  }

  Future<List<Song>> getSongsByCategory(int categoryId) async {
    final db = await _databaseHelper.database;
    // Consulta para obtener canciones filtradas por una categoría específica
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT s.*, GROUP_CONCAT(cc.categoria_id) as categoria_ids
      FROM songs s
      INNER JOIN cancion_categoria cc ON s.id = cc.cancion_id
      WHERE cc.categoria_id = ?
      GROUP BY s.id
    ''', [categoryId]);

    List<Song> songs = [];
    for (var map in maps) {
      final song = Song.fromMap(map);
      // Opcional: Cargar las categorías aquí si es necesario
      // song.categories = await getCategoriasPorCancion(song.id!);
      songs.add(song);
    }
    return songs;
  }

  // Nuevo método para obtener canciones filtradas por múltiples categorías
  Future<List<Song>> getSongsByCategories(List<int> categoryIds) async {
    if (categoryIds.isEmpty) return getAllSongs(); // Si no hay categorías, devolver todas

    final db = await _databaseHelper.database;
    // Construir la cláusula IN dinámicamente
    final placeholders = List.filled(categoryIds.length, '?').join(',');
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT s.*, GROUP_CONCAT(cc.categoria_id) as categoria_ids
      FROM songs s
      INNER JOIN cancion_categoria cc ON s.id = cc.cancion_id
      WHERE cc.categoria_id IN ($placeholders)
      GROUP BY s.id
    ''', categoryIds);

    List<Song> songs = [];
    for (var map in maps) {
      final song = Song.fromMap(map);
      // Opcional: Cargar las categorías aquí si es necesario
      // song.categories = await getCategoriasPorCancion(song.id!);
      songs.add(song);
    }
    return songs;
  }

  // Nuevo método para buscar canciones por texto en múltiples campos
  Future<List<Song>> searchSongs(String query) async {
    if (query.isEmpty) return getAllSongs(); // Si no hay búsqueda, devolver todas

    final db = await _databaseHelper.database;
    final lowerQuery = query.toLowerCase(); // Para búsquedas insensibles a mayúsculas
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT s.*, GROUP_CONCAT(cc.categoria_id) as categoria_ids
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
      // Opcional: Cargar las categorías aquí si es necesario
      // song.categories = await getCategoriasPorCancion(song.id!);
      songs.add(song);
    }
    return songs;
  }

  // Nuevo método para obtener canciones favoritas
  Future<List<Song>> getFavoriteSongs() async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT s.*, GROUP_CONCAT(cc.categoria_id) as categoria_ids
      FROM songs s
      LEFT JOIN cancion_categoria cc ON s.id = cc.cancion_id
      WHERE s.es_favorita = 1
      GROUP BY s.id
    ''');

    List<Song> songs = [];
    for (var map in maps) {
      final song = Song.fromMap(map);
      // Opcional: Cargar las categorías aquí si es necesario
      // song.categories = await getCategoriasPorCancion(song.id!);
      songs.add(song);
    }
    return songs;
  }

  Future<void> insertSong(Song song) async {
    final db = await _databaseHelper.database;
    await db.transaction((txn) async {
      // 1. Insertar la canción
      final songId = await txn.insert('songs', song.toMap());

      // 2. Insertar las relaciones con categorías (si las hubiera)
      // NOTA: Este método asume que el ID de la categoría ya está disponible.
      // La lógica para obtener/crear categorías por nombre se podría mover aquí o mantener externa.
      // Por ahora, asumimos que se manejan previamente si es necesario.
      // Si Song.model incluyera directamente IDs de categorías, se usarían aquí.
      // Por ejemplo, si Song tuviera List<int> categoryIds:
      // for (int catId in song.categoryIds) {
      //   await txn.insert('cancion_categoria', {
      //     'cancion_id': songId,
      //     'categoria_id': catId,
      //   });
      // }
      // Dado que el modelo actual no tiene una lista de IDs directamente,
      // la asignación de categorías se debería manejar en un método separado o
      // se debería adaptar la lógica de inserción/edición de canciones para
      // manejar la relación después de obtener el ID de la canción.
      // Por ahora, solo insertamos la canción principal.
    });
  }

  // ... (resto del archivo igual) ...
  Future<void> updateSong(Song song) async {
    if (song.id == null) return; // No se puede actualizar sin ID

    final db = await _databaseHelper.database;
    await db.transaction((txn) async {
      // 1. Actualizar la canción principal (ahora incluye content transpuesto y originalKey transpuesta)
      await txn.update('songs', song.toMap(), where: 'id = ?', whereArgs: [song.id]);

      // 2. Opcional: Actualizar relaciones con categorías (borrar y reinsertar, o manejo más complejo)
      // await txn.delete('cancion_categoria', where: 'cancion_id = ?', whereArgs: [song.id]);
      // Luego insertar las nuevas relaciones como en insertSong
      // Por simplicidad en esta actualización, no se manejan categorías aquí directamente.
      // Se podría implementar un método updateSongWithCategories.
    });
  }
// ... (resto del archivo igual) ...

  Future<void> deleteSong(int id) async {
    final db = await _databaseHelper.database;
    // Debido a ON DELETE CASCADE en la base de datos, se eliminarán
    // automáticamente las entradas en cancion_categoria y setlist_cancion.
    await db.delete('songs', where: 'id = ?', whereArgs: [id]);
  }

  // --- Gestión de Categorías por Canción ---
  // Método para asignar categorías a una canción (borra antiguas y agrega nuevas)
  Future<void> setCategoriasForSong(int songId, List<int> categoryIds) async {
    final db = await _databaseHelper.database;
    await db.transaction((txn) async {
      // Borrar relaciones antiguas
      await txn.delete('cancion_categoria', where: 'cancion_id = ?', whereArgs: [songId]);

      // Insertar nuevas relaciones
      for (int catId in categoryIds) {
        await txn.insert('cancion_categoria', {
          'cancion_id': songId,
          'categoria_id': catId,
        });
      }
    });
  }

  // Método para obtener IDs de categorías asociadas a una canción
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

  // --- CRUD Setlists ---
  Future<List<Setlist>> getAllSetlists() async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> setlistMaps = await db.query('setlists', orderBy: 'nombre');

    List<Setlist> setlists = [];
    for (var setlistMap in setlistMaps) {
      final setlist = Setlist.fromMap(setlistMap);

      // Cargar las canciones del setlist con sus configuraciones personalizadas
      final songMaps = await db.query(
        'setlist_cancion',
        where: 'setlist_id = ?',
        whereArgs: [setlist.id],
        orderBy: 'orden ASC',
      );

      List<SetlistItem> setlistItems = [];
      for (var songMap in songMaps) {
        final songId = songMap['cancion_id'] as int;
        final order = songMap['orden'] as int;
        final transposition = songMap['transposicion_semitonos'] as int? ?? 0;
        final capo = songMap['capo_personalizado'] as int?; // Puede ser nulo

        // Obtener el objeto Song completo
        final songResult = await db.query('songs', where: 'id = ?', whereArgs: [songId]);
        if (songResult.isNotEmpty) {
          final song = Song.fromMap(songResult.first);
          setlistItems.add(SetlistItem(
            song: song,
            order: order,
            transposition: transposition,
            capo: capo,
          ));
        }
      }
      // Crear un nuevo objeto Setlist con las canciones cargadas
      setlists.add(Setlist(
        id: setlist.id,
        name: setlist.name,
        eventDate: setlist.eventDate,
        notes: setlist.notes,
        creationDate: setlist.creationDate,
        modificationDate: setlist.modificationDate,
        songs: setlistItems,
      ));
    }
    return setlists;
  }

  Future<void> insertSetlist(Setlist setlist) async {
    final db = await _databaseHelper.database;
    await db.transaction((txn) async {
      // 1. Insertar el setlist
      final setlistId = await txn.insert('setlists', setlist.toMap());

      // 2. Insertar las canciones del setlist con sus configuraciones
      for (int i = 0; i < setlist.songs.length; i++) {
        final setlistItem = setlist.songs[i];
        await txn.insert('setlist_cancion', {
          'setlist_id': setlistId,
          'cancion_id': setlistItem.song.id!,
          'orden': i + 1, // Orden empieza en 1
          'transposicion_semitonos': setlistItem.transposition,
          'capo_personalizado': setlistItem.capo, // Puede ser nulo
        });
      }
    });
  }

  Future<void> updateSetlist(Setlist setlist) async {
    if (setlist.id == null) return; // No se puede actualizar sin ID

    final db = await _databaseHelper.database;
    await db.transaction((txn) async {
      // 1. Actualizar el setlist
      await txn.update('setlists', setlist.toMap(), where: 'id = ?', whereArgs: [setlist.id]);

      // 2. Borrar canciones antiguas
      await txn.delete('setlist_cancion', where: 'setlist_id = ?', whereArgs: [setlist.id]);

      // 3. Insertar canciones nuevas con sus configuraciones
      for (int i = 0; i < setlist.songs.length; i++) {
        final setlistItem = setlist.songs[i];
        await txn.insert('setlist_cancion', {
          'setlist_id': setlist.id,
          'cancion_id': setlistItem.song.id!,
          'orden': i + 1,
          'transposicion_semitonos': setlistItem.transposition,
          'capo_personalizado': setlistItem.capo, // Puede ser nulo
        });
      }
    });
  }

  Future<void> deleteSetlist(int id) async {
    final db = await _databaseHelper.database;
    // Debido a ON DELETE CASCADE en la base de datos, se eliminarán
    // automáticamente las entradas en setlist_cancion.
    await db.delete('setlists', where: 'id = ?', whereArgs: [id]);
  }

  // --- Marcar/Desmarcar Favorito ---
  Future<void> toggleFavorite(int songId) async {
    final db = await _databaseHelper.database;
    // Obtener el estado actual de favorito
    final result = await db.query('songs', columns: ['es_favorita'], where: 'id = ?', whereArgs: [songId]);
    if (result.isNotEmpty) {
      final isFavorite = (result.first['es_favorita'] as int) == 1;
      // Actualizar el estado invirtiendo el valor
      await db.update('songs', {'es_favorita': isFavorite ? 0 : 1}, where: 'id = ?', whereArgs: [songId]);
    }
  }

  // --- Incrementar Contador de Reproducciones ---
  Future<void> incrementPlayCount(int songId) async {
    final db = await _databaseHelper.database;
    await db.rawUpdate('''
      UPDATE songs 
      SET contador_reproducciones = contador_reproducciones + 1, 
          fecha_modificacion = ? 
      WHERE id = ?
    ''', [DateTime.now().toIso8601String(), songId]);
  }
}