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
  Future<List<Setlist>> getModifiedSetlistsAfter(DateTime date) async {
    final db = await _databaseHelper.database;
    // 1. Buscamos los IDs de los setlists cuya fecha de modificación es más reciente que la última sincronización.
    final List<Map<String, dynamic>> setlistMaps = await db.query(
      'setlists',
      where: 'fecha_modificacion > ?',
      whereArgs: [date.toUtc().toIso8601String()],
    );

    if (setlistMaps.isEmpty) {
      return [];
    }

    // 2. Usamos la función existente `getAllSetlists` para obtener los objetos completos
    // y luego filtramos solo los que encontramos en el paso anterior.
    final allSetlists = await getAllSetlists();
    final modifiedIds = setlistMaps.map((m) => m['id'] as int).toSet();
    return allSetlists.where((s) => modifiedIds.contains(s.id)).toList();
  }

  // TODO: Implementar getSetlistById para obtener un solo setlist
  // TODO: Implementar setlistExists para el SyncService
}