import 'package:cancionero_liturgico/models/song.dart';
import 'package:cancionero_liturgico/models/setlist_model.dart';
import 'package:cancionero_liturgico/models/setlist.dart'; // Importa SetlistItem
import 'package:cancionero_liturgico/services/database_helper.dart';

class SongRepository {
  final DatabaseHelper _databaseHelper = DatabaseHelper();

  static const String _songColumns = '''
    s.id, s.titulo, s.autor, s.letra_con_acordes, s.tonalidad_original,
    s.tempo_bpm, s.posicion_capo, s.es_favorita, s.contador_reproducciones,
    s.fecha_creacion, s.fecha_modificacion, s.notas, s.enlaces_video
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

  Future<void> insertSong(Song song) async {
    final db = await _databaseHelper.database;
    await db.transaction((txn) async {
      final songId = await txn.insert('songs', song.toMap());
    });
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

  Future<List<Setlist>> getAllSetlists() async {
    print("[DEBUG] getAllSetlists: Iniciando obtención de setlists.");
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> setlistMaps = await db.query('setlists', orderBy: 'nombre');
    print("[DEBUG] getAllSetlists: Encontrados ${setlistMaps.length} setlists en la tabla 'setlists'.");

    List<Setlist> setlists = [];
    for (var setlistMap in setlistMaps) {
      final setlist = Setlist.fromMap(setlistMap);
      print("[DEBUG] getAllSetlists: Procesando setlist '${setlist.name}' (ID: ${setlist.id}).");

      final songMaps = await db.query(
        'setlist_cancion',
        where: 'setlist_id = ?',
        whereArgs: [setlist.id],
        orderBy: 'orden ASC',
      );
      print("[DEBUG] getAllSetlists: Setlist '${setlist.name}' tiene ${songMaps.length} canciones asociadas.");

      List<SetlistItem> setlistItems = [];
      for (var songMap in songMaps) {
        final songId = songMap['cancion_id'] as int;
        final order = songMap['orden'] as int;
        final transposition = songMap['transposicion_semitonos'] as int? ?? 0;
        final capo = songMap['capo_personalizado'] as int?;
        print("[DEBUG] getAllSetlists:   - Buscando canción con ID: $songId.");

        // CORRECCIÓN: Usar una consulta que incluya los IDs de las categorías,
        // igual que en getSongById, para que Song.fromMap funcione correctamente.
        final songResult = await db.rawQuery('''
          SELECT $_songColumns, GROUP_CONCAT(cc.categoria_id) as categoria_ids
          FROM songs s
          LEFT JOIN cancion_categoria cc ON s.id = cc.cancion_id
          WHERE s.id = ?
          GROUP BY s.id
        ''', [songId]);
        print("[DEBUG] getAllSetlists:   - Resultado de la consulta para la canción ID $songId: ${songResult.isNotEmpty ? 'Encontrada' : 'NO Encontrada'}.");

        if (songResult.isNotEmpty) {
          final song = Song.fromMap(songResult.first);
          print("[DEBUG] getAllSetlists:   - SetlistItem para la canción '${song.title}' añadido correctamente.");
          setlistItems.add(SetlistItem(
            song: song,
            order: order,
            transposition: transposition,
            capo: capo,
          ));
        } else {
          print("[DEBUG] getAllSetlists:   - ¡ERROR! No se encontró la canción con ID: $songId en la tabla 'songs'. Este setlist podría estar incompleto.");
        }
      }
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
    print("[DEBUG] getAllSetlists: Finalizado. Devolviendo ${setlists.length} setlists completos.");
    return setlists;
  }

  Future<void> insertSetlist(Setlist setlist) async {
    final db = await _databaseHelper.database;
    await db.transaction((txn) async {
      final setlistId = await txn.insert('setlists', setlist.toMap());

      for (int i = 0; i < setlist.songs.length; i++) {
        final setlistItem = setlist.songs[i];
        await txn.insert('setlist_cancion', {
          'setlist_id': setlistId,
          'cancion_id': setlistItem.song.id!,
          'orden': i + 1,
          'transposicion_semitonos': setlistItem.transposition,
          'capo_personalizado': setlistItem.capo,
        });
      }
    });
  }

  Future<void> updateSetlist(Setlist setlist) async {
    if (setlist.id == null) return;

    final db = await _databaseHelper.database;
    await db.transaction((txn) async {
      await txn.update('setlists', setlist.toMap(), where: 'id = ?', whereArgs: [setlist.id]);

      await txn.delete('setlist_cancion', where: 'setlist_id = ?', whereArgs: [setlist.id]);

      for (int i = 0; i < setlist.songs.length; i++) {
        final setlistItem = setlist.songs[i];
        await txn.insert('setlist_cancion', {
          'setlist_id': setlist.id,
          'cancion_id': setlistItem.song.id!,
          'orden': i + 1,
          'transposicion_semitonos': setlistItem.transposition,
          'capo_personalizado': setlistItem.capo,
        });
      }
    });
  }

  Future<void> deleteSetlist(int id) async {
    final db = await _databaseHelper.database;
    await db.delete('setlists', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> toggleFavorite(int songId) async {
    final db = await _databaseHelper.database;
    final result = await db.query('songs', columns: ['es_favorita'], where: 'id = ?', whereArgs: [songId]);
    if (result.isNotEmpty) {
      final isFavorite = (result.first['es_favorita'] as int) == 1;
      await db.update('songs', {'es_favorita': isFavorite ? 0 : 1}, where: 'id = ?', whereArgs: [songId]);
    }
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
}
