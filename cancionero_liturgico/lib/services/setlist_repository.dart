import 'package:cancionero_liturgico/models/setlist_model.dart';
import 'package:cancionero_liturgico/models/song.dart';
import 'package:cancionero_liturgico/services/database_helper.dart';
import 'package:sqflite/sqflite.dart';

class SetlistRepository {
  final DatabaseHelper _databaseHelper = DatabaseHelper();

  // Columnas de Song para reutilizar en las consultas
  static const String _songColumns = '''
    s.id, s.titulo, s.autor, s.letra_con_acordes, s.tonalidad_original,
    s.tempo_bpm, s.posicion_capo, s.es_favorita, s.contador_reproducciones,
    s.fecha_creacion, s.fecha_modificacion, s.notas, s.enlaces_video, s.preferred_font_size
  ''';

  
  // En SetlistRepository, modifica getAllSetlists() con logging:
  Future<List<Setlist>> getAllSetlists() async {
    final db = await _databaseHelper.database;
    print("SETLIST_DEBUG: 1. 📋 Obteniendo todos los setlists de la BD");
    
    final List<Map<String, dynamic>> setlistMaps = await db.query('setlists', orderBy: 'nombre');
    print("SETLIST_DEBUG: 2. 📊 Setlists encontrados en tabla: ${setlistMaps.length}");

    List<Setlist> setlists = [];
    for (var setlistMap in setlistMaps) {
      final setlist = Setlist.fromMap(setlistMap);
      print("SETLIST_DEBUG: 3. 🔍 Procesando setlist: '${setlist.name}' (ID: ${setlist.id})");

      // Obtener canciones del setlist
      final songMaps = await db.query(
        'setlist_cancion',
        where: 'setlist_id = ?',
        whereArgs: [setlist.id],
        orderBy: 'orden ASC',
      );
      
      print("SETLIST_DEBUG: 4. 🎵 Relaciones encontradas en setlist_cancion: ${songMaps.length}");

      List<SetlistItem> setlistItems = [];
      for (var songMap in songMaps) {
        final songId = songMap['cancion_id'] as int;
        final order = songMap['orden'] as int;
        final transposition = songMap['transposicion_semitonos'] as int? ?? 0;
        final capo = songMap['capo_personalizado'] as int?;

        print("SETLIST_DEBUG: 5. 🔗 Relación - Canción ID: $songId, Orden: $order");

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
          print("SETLIST_DEBUG: 6. ✅ Canción agregada: '${song.title}'");
        } else {
          print("SETLIST_DEBUG: 6. ❌ Canción NO encontrada ID: $songId");
        }
      }
      
      setlists.add(setlist.copyWith(songs: setlistItems));
      print("SETLIST_DEBUG: 7. ✅ Setlist completado: '${setlist.name}' con ${setlistItems.length} canciones");
    }
    
    print("SETLIST_DEBUG: 8. 🏁 TOTAL setlists cargados: ${setlists.length}");
    return setlists;
  }

  Future<void> insertSetlist(Setlist setlist) async {
    final db = await _databaseHelper.database;
    print("💾 INSERT SETLIST: '${setlist.name}' con ${setlist.songs.length} canciones");
    
    int? setlistIdFinal; // ← Variable para guardar el ID
    
    await db.transaction((txn) async {
      // 1. Insertar setlist
      final setlistId = await txn.insert('setlists', setlist.toMap());
      setlistIdFinal = setlistId; // ← Guardar el ID
      print("✅ Setlist insertado ID: $setlistId");
      
      // 2. Insertar cada relación
      for (final item in setlist.songs) {
        print("🔗 Insertando relación: Setlist $setlistId -> Canción ${item.song.id}, Orden ${item.order}");
        
        final result = await txn.insert('setlist_cancion', {
          'setlist_id': setlistId,
          'cancion_id': item.song.id!,
          'orden': item.order,
          'transposicion_semitonos': item.transposition,
          'capo_personalizado': item.capo,
        });
        
        print("✅ Relación insertada con ID: $result");
      }
      
      // 3. VERIFICAR que las relaciones se insertaron
      final relacionesVerificadas = await txn.query('setlist_cancion', where: 'setlist_id = ?', whereArgs: [setlistId]);
      print("🔍 VERIFICACIÓN: ${relacionesVerificadas.length} relaciones para setlist $setlistId");
    });
    
    // 4. VERIFICAR FUERA de la transacción - USAR setlistIdFinal
    if (setlistIdFinal != null) {
      final relacionesFinal = await db.query('setlist_cancion', where: 'setlist_id = ?', whereArgs: [setlistIdFinal]);
      print("🏁 VERIFICACIÓN FINAL: ${relacionesFinal.length} relaciones persistentes para setlist $setlistIdFinal");
    } else {
      print("❌ ERROR: setlistIdFinal es null");
    }
  }

  Future<void> updateSetlist(Setlist setlist) async {
    if (setlist.id == null) return;

    final db = await _databaseHelper.database;
    print("💾 ACTUALIZANDO setlist: '${setlist.name}' con ${setlist.songs.length} canciones");
    
    await db.transaction((txn) async {
      // 1. Actualizar setlist
      await txn.update('setlists', setlist.toMap(), where: 'id = ?', whereArgs: [setlist.id]);
      print("✅ Setlist actualizado ID: ${setlist.id}");
      
      // 2. Eliminar relaciones existentes
      final deletedCount = await txn.delete('setlist_cancion', where: 'setlist_id = ?', whereArgs: [setlist.id]);
      print("🗑️  Relaciones eliminadas: $deletedCount");
      
      // 3. Insertar nuevas relaciones
      int relacionesInsertadas = 0;
      for (final item in setlist.songs) {
        print("🔗 Insertando relación: Setlist ${setlist.id} -> Canción ${item.song.id}, Orden ${item.order}");
        
        final result = await txn.insert('setlist_cancion', {
          'setlist_id': setlist.id,
          'cancion_id': item.song.id!,
          'orden': item.order,
          'transposicion_semitonos': item.transposition,
          'capo_personalizado': item.capo,
        });
        
        print("✅ Relación insertada con ID: $result");
        relacionesInsertadas++;
      }
      
      // 4. VERIFICAR dentro de la transacción
      final relacionesVerificadas = await txn.query('setlist_cancion', where: 'setlist_id = ?', whereArgs: [setlist.id]);
      print("🔍 VERIFICACIÓN: ${relacionesVerificadas.length} relaciones para setlist ${setlist.id}");
    });
    
    // 5. VERIFICAR FUERA de la transacción
    final relacionesFinal = await db.query('setlist_cancion', where: 'setlist_id = ?', whereArgs: [setlist.id]);
    print("🏁 VERIFICACIÓN FINAL: ${relacionesFinal.length} relaciones persistentes para setlist ${setlist.id}");
  }

  Future<void> deleteSetlist(int id) async {
    final db = await _databaseHelper.database;
    await db.delete('setlists', where: 'id = ?', whereArgs: [id]);
  }

  /// Busca en la base de datos todos los setlists que han sido modificados
  /// después de la fecha proporcionada.
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

  Future<void> agregarCancionASetlist({
    required int setlistId,
    required int cancionId,
    required int orden,
    required int transposicionSemitonos,
    required int capoPersonalizado,
  }) async {
    try {
      print("SETLIST_REPO_DEBUG: 1. 💾 Intentando guardar relación en BD");
      print("SETLIST_REPO_DEBUG: 2. 📝 Datos: setlist=$setlistId, cancion=$cancionId, orden=$orden");
      
      final db = await _databaseHelper.database;
      
      final resultado = await db.insert(
        'setlist_cancion',
        {
          'setlist_id': setlistId,
          'cancion_id': cancionId,
          'orden': orden,
          'transposicion_semitonos': transposicionSemitonos,
          'capo_personalizado': capoPersonalizado,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      
      print("SETLIST_REPO_DEBUG: 3. ✅ Insert exitoso, resultado: $resultado");
      
      // VERIFICACIÓN INMEDIATA - leer lo que acabamos de guardar
      final verificacion = await db.query(
        'setlist_cancion',
        where: 'setlist_id = ? AND cancion_id = ?',
        whereArgs: [setlistId, cancionId],
      );
      
      print("SETLIST_REPO_DEBUG: 4. 🔍 Verificación post-insert: ${verificacion.length} registros encontrados");
      
    } catch (e, stackTrace) {
      print("SETLIST_REPO_DEBUG: 5. ❌ ERROR en agregarCancionASetlist: $e");
      print("SETLIST_REPO_DEBUG: 6. 📍 StackTrace: $stackTrace");
      rethrow;
    }
  }
}