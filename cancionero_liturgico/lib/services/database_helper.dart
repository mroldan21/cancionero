import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/cancion_model.dart';
import '../models/category_model.dart';
import '../models/setlist_model.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'cancionero_liturgico.db');
    return await openDatabase(
      path,
      version: 2, // Incremented version for schema changes
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Songs table
    await db.execute('''
      CREATE TABLE songs(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        author TEXT,
        lyrics_with_chords TEXT NOT NULL,
        original_key TEXT NOT NULL,
        tempo_bpm INTEGER,
        capo_position INTEGER DEFAULT 0,
        is_favorite INTEGER DEFAULT 0,
        play_count INTEGER DEFAULT 0,
        creation_date TEXT NOT NULL,
        modification_date TEXT NOT NULL,
        notes TEXT,
        video_links TEXT
      )
    ''');

    // Categories table
    await db.execute('''
      CREATE TABLE categories(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE,
        color TEXT DEFAULT "#4CAF50",
        order_index INTEGER DEFAULT 0,
        is_predefined INTEGER DEFAULT 0
      )
    ''');

    // Song-Category relation table
    await db.execute('''
      CREATE TABLE song_category(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        song_id INTEGER NOT NULL,
        category_id INTEGER NOT NULL,
        FOREIGN KEY(song_id) REFERENCES songs(id) ON DELETE CASCADE,
        FOREIGN KEY(category_id) REFERENCES categories(id) ON DELETE CASCADE,
        UNIQUE(song_id, category_id)
      )
    ''');

    // Setlists table
    await db.execute('''
      CREATE TABLE setlists(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        event_date TEXT,
        notes TEXT,
        creation_date TEXT NOT NULL,
        modification_date TEXT NOT NULL
      )
    ''');

    // Setlist-Songs relation table
    await db.execute('''
      CREATE TABLE setlist_songs(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        setlist_id INTEGER NOT NULL,
        song_id INTEGER NOT NULL,
        order_index INTEGER NOT NULL,
        transposition_semitones INTEGER DEFAULT 0,
        custom_capo INTEGER,
        FOREIGN KEY(setlist_id) REFERENCES setlists(id) ON DELETE CASCADE,
        FOREIGN KEY(song_id) REFERENCES songs(id) ON DELETE CASCADE,
        UNIQUE(setlist_id, song_id, order_index)
      )
    ''');

    // Insert predefined categories
    await _insertPredefinedCategories(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Migrations for version 2
      await db.execute('''
        CREATE TABLE IF NOT EXISTS categories(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL UNIQUE,
          color TEXT DEFAULT "#4CAF50",
          order_index INTEGER DEFAULT 0,
          is_predefined INTEGER DEFAULT 0
        )
      ''');
      
      await db.execute('''
        CREATE TABLE IF NOT EXISTS setlists(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          event_date TEXT,
          notes TEXT,
          creation_date TEXT NOT NULL,
          modification_date TEXT NOT NULL
        )
      ''');
      
      await db.execute('''
        CREATE TABLE IF NOT EXISTS setlist_songs(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          setlist_id INTEGER NOT NULL,
          song_id INTEGER NOT NULL,
          order_index INTEGER NOT NULL,
          transposition_semitones INTEGER DEFAULT 0,
          custom_capo INTEGER,
          FOREIGN KEY(setlist_id) REFERENCES setlists(id) ON DELETE CASCADE,
          FOREIGN KEY(song_id) REFERENCES songs(id) ON DELETE CASCADE,
          UNIQUE(setlist_id, song_id, order_index)
        )
      ''');
      
      await _insertPredefinedCategories(db);
    }
  }

  Future<void> _insertPredefinedCategories(Database db) async {
    final categories = [
      {'name': 'Entrada', 'color': '#4CAF50', 'order_index': 1, 'is_predefined': 1},
      {'name': 'Meditación', 'color': '#2196F3', 'order_index': 2, 'is_predefined': 1},
      {'name': 'Virgen María', 'color': '#E91E63', 'order_index': 3, 'is_predefined': 1},
      {'name': 'Comunión', 'color': '#FFC107', 'order_index': 4, 'is_predefined': 1},
      {'name': 'Ofertorio', 'color': '#FF9800', 'order_index': 5, 'is_predefined': 1},
      {'name': 'Salida', 'color': '#9C27B0', 'order_index': 6, 'is_predefined': 1},
      {'name': 'Adoración', 'color': '#FF5722', 'order_index': 7, 'is_predefined': 1},
      {'name': 'Penitencial', 'color': '#795548', 'order_index': 8, 'is_predefined': 1},
      {'name': 'Aleluya', 'color': '#FFEB3B', 'order_index': 9, 'is_predefined': 1},
    ];

    for (var category in categories) {
      await db.insert('categories', category, conflictAlgorithm: ConflictAlgorithm.ignore);
    }
  }

  // ========== SONG METHODS ==========

  Future<int> insertSong(Cancion song) async {
    final db = await database;
    return await db.insert('songs', {
      'title': song.titulo,
      'author': song.autor,
      'lyrics_with_chords': song.letraConAcordes,
      'original_key': song.tonalidadOriginal,
      'tempo_bpm': song.tempoBpm,
      'capo_position': song.posicionCapo,
      'is_favorite': song.esFavorita ? 1 : 0,
      'play_count': song.contadorReproducciones,
      'creation_date': song.fechaCreacion.toIso8601String(),
      'modification_date': song.fechaModificacion.toIso8601String(),
      'notes': song.notas,
      'video_links': song.enlacesVideo != null ? song.enlacesVideo!.join('||') : null,
    });
  }

  Future<List<Cancion>> getSongs() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('songs', orderBy: 'title');
    
    return List.generate(maps.length, (i) {
      return Cancion(
        id: maps[i]['id'],
        titulo: maps[i]['title'],
        autor: maps[i]['author'],
        letraConAcordes: maps[i]['lyrics_with_chords'],
        tonalidadOriginal: maps[i]['original_key'],
        tempoBpm: maps[i]['tempo_bpm'],
        posicionCapo: maps[i]['capo_position'],
        esFavorita: maps[i]['is_favorite'] == 1,
        contadorReproducciones: maps[i]['play_count'],
        fechaCreacion: DateTime.parse(maps[i]['creation_date']),
        fechaModificacion: DateTime.parse(maps[i]['modification_date']),
        notas: maps[i]['notes'],
        enlacesVideo: maps[i]['video_links'] != null 
            ? (maps[i]['video_links'] as String).split('||')
            : null,
      );
    });
  }

  Future<int> updateSong(Cancion song) async {
    final db = await database;
    return await db.update(
      'songs',
      {
        'title': song.titulo,
        'author': song.autor,
        'lyrics_with_chords': song.letraConAcordes,
        'original_key': song.tonalidadOriginal,
        'tempo_bpm': song.tempoBpm,
        'capo_position': song.posicionCapo,
        'is_favorite': song.esFavorita ? 1 : 0,
        'play_count': song.contadorReproducciones,
        'modification_date': DateTime.now().toIso8601String(),
        'notes': song.notas,
        'video_links': song.enlacesVideo != null ? song.enlacesVideo!.join('||') : null,
      },
      where: 'id = ?',
      whereArgs: [song.id],
    );
  }

  Future<int> deleteSong(int id) async {
    final db = await database;
    return await db.delete(
      'songs',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ========== CATEGORY METHODS ==========

  Future<int> insertCategory(Category category) async {
    final db = await database;
    return await db.insert('categories', {
      'name': category.name,
      'color': category.color,
      'order_index': category.order,
      'is_predefined': category.isPredefined ? 1 : 0,
    });
  }

  Future<List<Category>> getCategories() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'categories', 
      orderBy: 'order_index'
    );
    
    return List.generate(maps.length, (i) {
      return Category(
        id: maps[i]['id'],
        name: maps[i]['name'],
        color: maps[i]['color'],
        order: maps[i]['order_index'],
        isPredefined: maps[i]['is_predefined'] == 1,
      );
    });
  }

  Future<int> updateCategory(Category category) async {
    final db = await database;
    return await db.update(
      'categories',
      {
        'name': category.name,
        'color': category.color,
        'order_index': category.order,
      },
      where: 'id = ?',
      whereArgs: [category.id],
    );
  }

  Future<int> deleteCategory(int id) async {
    final db = await database;
    return await db.delete(
      'categories',
      where: 'id = ? AND is_predefined = 0',
      whereArgs: [id],
    );
  }

  // ========== SETLIST METHODS ==========

  Future<int> insertSetlist(Setlist setlist) async {
    final db = await database;
    return await db.insert('setlists', {
      'name': setlist.name,
      'event_date': setlist.eventDate?.toIso8601String(),
      'notes': setlist.notes,
      'creation_date': setlist.creationDate.toIso8601String(),
      'modification_date': setlist.modificationDate.toIso8601String(),
    });
  }

  Future<List<Setlist>> getSetlists() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'setlists',
      orderBy: 'creation_date DESC',
    );
    
    return List.generate(maps.length, (i) {
      return Setlist(
        id: maps[i]['id'],
        name: maps[i]['name'],
        eventDate: maps[i]['event_date'] != null 
            ? DateTime.parse(maps[i]['event_date'])
            : null,
        notes: maps[i]['notes'],
        creationDate: DateTime.parse(maps[i]['creation_date']),
        modificationDate: DateTime.parse(maps[i]['modification_date']),
      );
    });
  }

  Future<Setlist?> getSetlistById(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'setlists',
      where: 'id = ?',
      whereArgs: [id],
    );
    
    if (maps.isNotEmpty) {
      return Setlist(
        id: maps[0]['id'],
        name: maps[0]['name'],
        eventDate: maps[0]['event_date'] != null 
            ? DateTime.parse(maps[0]['event_date'])
            : null,
        notes: maps[0]['notes'],
        creationDate: DateTime.parse(maps[0]['creation_date']),
        modificationDate: DateTime.parse(maps[0]['modification_date']),
      );
    }
    return null;
  }

  Future<int> updateSetlist(Setlist setlist) async {
    final db = await database;
    return await db.update(
      'setlists',
      {
        'name': setlist.name,
        'event_date': setlist.eventDate?.toIso8601String(),
        'notes': setlist.notes,
        'modification_date': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [setlist.id],
    );
  }

  Future<int> deleteSetlist(int id) async {
    final db = await database;
    return await db.delete(
      'setlists',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ========== SETLIST-SONG RELATION METHODS ==========

  Future<int> addSongToSetlist(int setlistId, int songId, int orderIndex, 
      {int transposition = 0, int? customCapo}) async {
    final db = await database;
    return await db.insert('setlist_songs', {
      'setlist_id': setlistId,
      'song_id': songId,
      'order_index': orderIndex,
      'transposition_semitones': transposition,
      'custom_capo': customCapo,
    });
  }

  Future<List<SetlistSong>> getSongsForSetlist(int setlistId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'setlist_songs',
      where: 'setlist_id = ?',
      whereArgs: [setlistId],
      orderBy: 'order_index',
    );
    
    return List.generate(maps.length, (i) {
      return SetlistSong(
        id: maps[i]['id'],
        setlistId: maps[i]['setlist_id'],
        songId: maps[i]['song_id'],
        order: maps[i]['order_index'],
        transpositionSemitones: maps[i]['transposition_semitones'],
        customCapo: maps[i]['custom_capo'],
      );
    });
  }

  Future<List<Cancion>> getSongsWithDetailsForSetlist(int setlistId) async {
    final db = await database;
    
    // Join setlist_songs with songs table to get full song details
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT s.*, ss.order_index, ss.transposition_semitones, ss.custom_capo
      FROM setlist_songs ss
      INNER JOIN songs s ON ss.song_id = s.id
      WHERE ss.setlist_id = ?
      ORDER BY ss.order_index
    ''', [setlistId]);
    
    return List.generate(maps.length, (i) {
      return Cancion(
        id: maps[i]['id'],
        titulo: maps[i]['title'],
        autor: maps[i]['author'],
        letraConAcordes: maps[i]['lyrics_with_chords'],
        tonalidadOriginal: maps[i]['original_key'],
        tempoBpm: maps[i]['tempo_bpm'],
        posicionCapo: maps[i]['custom_capo'] ?? maps[i]['capo_position'],
        esFavorita: maps[i]['is_favorite'] == 1,
        contadorReproducciones: maps[i]['play_count'],
        fechaCreacion: DateTime.parse(maps[i]['creation_date']),
        fechaModificacion: DateTime.parse(maps[i]['modification_date']),
        notas: maps[i]['notes'],
        enlacesVideo: maps[i]['video_links'] != null 
            ? (maps[i]['video_links'] as String).split('||')
            : null,
      );
    });
  }

  Future<int> updateSetlistSongOrder(int setlistSongId, int newOrder) async {
    final db = await database;
    return await db.update(
      'setlist_songs',
      {
        'order_index': newOrder,
      },
      where: 'id = ?',
      whereArgs: [setlistSongId],
    );
  }

  Future<int> removeSongFromSetlist(int setlistSongId) async {
    final db = await database;
    return await db.delete(
      'setlist_songs',
      where: 'id = ?',
      whereArgs: [setlistSongId],
    );
  }

  Future<int> getSetlistSongCount(int setlistId) async {
    final db = await database;
    final List<Map<String, dynamic>> result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM setlist_songs WHERE setlist_id = ?',
      [setlistId],
    );
    return result.first['count'] as int;
  }

  // ========== UTILITY METHODS ==========

  Future<void> clearDatabase() async {
    final db = await database;
    await db.delete('songs');
    await db.delete('categories');
    await db.delete('setlists');
    await db.delete('setlist_songs');
    await _insertPredefinedCategories(db);
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}