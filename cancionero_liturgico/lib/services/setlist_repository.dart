import 'package:cancionero_liturgico/models/setlist_model.dart';
import 'package:cancionero_liturgico/models/song.dart';
import 'package:cancionero_liturgico/services/database_helper.dart';

class SetlistRepository {
  final DatabaseHelper _databaseHelper = DatabaseHelper();

  // Columnas de Song para reutilizar en las consultas
  static const String _songColumns = '''
    s.id, s.titulo, s.autor, s.letra_con_acordes, s.tonalidad_original,
    s.tempo_bpm, s.posicion_capo, s.es_favorita, s.contador_reproducciones,
    s.fecha_creacion, s.fecha_modificacion, s.notas, s.enlaces_video, s.preferred_font_size
  ''';

  Future<List<Setlist>> getAllSetlists() async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> setlistMaps = await db.query('setlists', orderBy: 'nombre');

    List<Setlist> setlists = [];
    for (var setlistMap in setlistMaps) {
      final setlist = Setlist.fromMap(setlistMap);

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
        final capo = songMap['capo_personalizado'] as int?;

        final songResult = await db.rawQuery('''
          SELECT $_songColumns, GROUP_CONCAT(cc.categoria_id) as categoria_ids
          FROM songs s
          LEFT JOIN cancion_categoria cc ON s.id = cc.cancion_id
          WHERE s.id = ?
          GROUP BY s.id
        ''', [songId]);

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
      setlists.add(setlist.copyWith(songs: setlistItems));
    }
    return setlists;
  }

  Future<void> insertSetlist(Setlist setlist) async {
    final db = await _databaseHelper.database;
    await db.transaction((txn) async {
      final setlistId = await txn.insert('setlists', setlist.toMap());

      for (final item in setlist.songs) {
        await txn.insert('setlist_cancion', {
          'setlist_id': setlistId,
          'cancion_id': item.song.id!,
          'orden': item.order,
          'transposicion_semitonos': item.transposition,
          'capo_personalizado': item.capo,
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

      for (final item in setlist.songs) {
        await txn.insert('setlist_cancion', {
          'setlist_id': setlist.id,
          'cancion_id': item.song.id!,
          'orden': item.order,
          'transposicion_semitonos': item.transposition,
          'capo_personalizado': item.capo,
        });
      }
    });
  }

  Future<void> deleteSetlist(int id) async {
    final db = await _databaseHelper.database;
    await db.delete('setlists', where: 'id = ?', whereArgs: [id]);
  }

  /// Busca en la base de datos todos los setlists que han sido modificados
  /// después de la fecha proporcionada.
  // Future<List<Setlist>> getModifiedSetlistsAfter(DateTime date) async {
  //   final db = await _databaseHelper.database;
  //   // 1. Buscamos los IDs de los setlists cuya fecha de modificación es más reciente que la última sincronización.
  //   final List<Map<String, dynamic>> setlistMaps = await db.query(
  //     'setlists',
  //     where: 'fecha_modificacion > ?',
  //     whereArgs: [date.toUtc().toIso8601String()],
  //   );

  Future<List<Setlist>> getModifiedSetlistsAfter(DateTime date) async {
    final db = await _databaseHelper.database;
    
    print("SYNC_DEBUG: 🗓️  Buscando setlists modificados después de: $date");
    print("SYNC_DEBUG: 🗓️  Fecha local proporcionada: ${date.toLocal()}");
    print("SYNC_DEBUG: 🗓️  Fecha en UTC: ${date.toUtc().toIso8601String()}");
    
    // Usar la fecha local para la comparación, no UTC
    final fechaComparacion = date.toLocal().toIso8601String();
    print("SYNC_DEBUG: 🗓️  Usando para comparación: $fechaComparacion");
    
    // DEBUG: Ver qué hay en la tabla setlists
    final todosSetlistsDB = await db.query('setlists');
    print("SYNC_DEBUG: 📊 Total setlists en tabla: ${todosSetlistsDB.length}");
    for (final setlistRow in todosSetlistsDB) {
      final fechaModBD = setlistRow['fecha_modificacion'] as String;
      final fechaModDateTime = DateTime.parse(fechaModBD);
      print("SYNC_DEBUG: 📊 Setlist DB - ID: ${setlistRow['id']}, Nombre: ${setlistRow['nombre']}");
      print("SYNC_DEBUG: 📊   - Fecha modificación en BD: $fechaModBD");
      print("SYNC_DEBUG: 📊   - Fecha modificación local: ${fechaModDateTime.toLocal()}");
      print("SYNC_DEBUG: 📊   - Es después de $date?: ${fechaModDateTime.isAfter(date)}");
    }
    
    // Buscar setlists modificados - usar fecha local
    final setlistMaps = await db.query(
      'setlists',
      where: 'fecha_modificacion > ?',
      whereArgs: [fechaComparacion], // Usar fecha local
    );

    print("SYNC_DEBUG: 📋 Setlists modificados encontrados en consulta BD: ${setlistMaps.length}");


    List<Setlist> setlists = [];
    
    for (final setlistMap in setlistMaps) {
      final setlist = Setlist.fromMap(setlistMap);
      
      print("SYNC_DEBUG: 🔍 Procesando setlist ID: ${setlist.id} - '${setlist.name}'");
      
      // Obtener canciones del setlist
      final songMaps = await db.query(
        'setlist_cancion',
        where: 'setlist_id = ?',
        whereArgs: [setlist.id],
        orderBy: 'orden ASC',
      );

      print("SYNC_DEBUG: 🎵 Canciones en setlist: ${songMaps.length}");

      List<SetlistItem> setlistItems = [];
      for (var songMap in songMaps) {
        final songId = songMap['cancion_id'] as int;
        final order = songMap['orden'] as int;
        final transposition = songMap['transposicion_semitonos'] as int? ?? 0;
        final capo = songMap['capo_personalizado'] as int?;

        // Obtener canción
        final songResult = await db.rawQuery('''
          SELECT $_songColumns, GROUP_CONCAT(cc.categoria_id) as categoria_ids
          FROM songs s
          LEFT JOIN cancion_categoria cc ON s.id = cc.cancion_id
          WHERE s.id = ?
          GROUP BY s.id
        ''', [songId]);

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
      
      setlists.add(setlist.copyWith(songs: setlistItems));
    }
    
    return setlists;
  }
  //   if (setlistMaps.isEmpty) {
  //     return [];
  //   }

  //   // 2. Usamos la función existente `getAllSetlists` para obtener los objetos completos
  //   // y luego filtramos solo los que encontramos en el paso anterior.
  //   final allSetlists = await getAllSetlists();
  //   final modifiedIds = setlistMaps.map((m) => m['id'] as int).toSet();
  //   return allSetlists.where((s) => modifiedIds.contains(s.id)).toList();
  // }

  /// Obtiene un único setlist por su ID, incluyendo todas sus canciones.
  Future<Setlist?> getSetlistById(int id) async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> setlistMaps = await db.query(
      'setlists',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (setlistMaps.isEmpty) {
      return null;
    }

    final setlist = Setlist.fromMap(setlistMaps.first);

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
      final capo = songMap['capo_personalizado'] as int?;

      final songResult = await db.rawQuery('''
        SELECT $_songColumns, GROUP_CONCAT(cc.categoria_id) as categoria_ids
        FROM songs s
        LEFT JOIN cancion_categoria cc ON s.id = cc.cancion_id
        WHERE s.id = ?
        GROUP BY s.id
      ''', [songId]);

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

    return setlist.copyWith(songs: setlistItems);
  }

  /// Verifica si un setlist con el ID proporcionado existe en la base de datos.
  Future<bool> setlistExists(int id) async {
    final db = await _databaseHelper.database;
    final result = await db.query('setlists', columns: ['id'], where: 'id = ?', whereArgs: [id], limit: 1);
    return result.isNotEmpty;
  }

  // En SetlistRepository, agrega este método para debugging
  Future<void> actualizarFechaModificacionSetlist(int setlistId) async {
    final db = await _databaseHelper.database;
    await db.update(
      'setlists',
      {'fecha_modificacion': DateTime.now().toUtc().toIso8601String()},
      where: 'id = ?',
      whereArgs: [setlistId],
    );
    print("SYNC_DEBUG: 📅 Fecha de modificación actualizada para setlist ID: $setlistId");
  }

}