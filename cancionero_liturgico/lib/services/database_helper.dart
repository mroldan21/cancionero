import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/song.dart';
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
      version: 3, // Incremented version for schema corrections
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Songs table - CORREGIDO a inglés consistente
    await db.execute('''
      CREATE TABLE songs(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        artist TEXT,
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

    // Categories table - CORREGIDO a inglés consistente
    await db.execute('''
      CREATE TABLE categories(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE,
        color TEXT DEFAULT "#4CAF50",
        order_index INTEGER DEFAULT 0,
        is_predefined INTEGER DEFAULT 0
      )
    ''');

    // Song-Category relation table - CORREGIDO a inglés
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
        FOREIGN KEY(song_id) REFERENCES songs(id) ON DELETE CASCADE
      )
    ''');

    // Insert predefined categories
    await _insertPredefinedCategories(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 3) {
      // Migrations for version 3 - CORRECCIONES DE CONSISTENCIA
      
      // Backup old data if tables exist
      bool oldSongsTableExists = false;
      bool oldCategoriesTableExists = false;
      
      try {
        await db.rawQuery('SELECT 1 FROM canciones LIMIT 1');
        oldSongsTableExists = true;
      } catch (_) {}
      
      try {
        await db.rawQuery('SELECT 1 FROM categorias LIMIT 1');
        oldCategoriesTableExists = true;
      } catch (_) {}

      // Create new tables with consistent English names
      await db.execute('''
        CREATE TABLE IF NOT EXISTS songs(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          title TEXT NOT NULL,
          artist TEXT,
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

      await db.execute('''
        CREATE TABLE IF NOT EXISTS categories(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL UNIQUE,
          color TEXT DEFAULT "#4CAF50",
          order_index INTEGER DEFAULT 0,
          is_predefined INTEGER DEFAULT 0
        )
      ''');

      // Migrate data from old tables if they exist
      if (oldSongsTableExists) {
        await db.rawQuery('''
          INSERT INTO songs (id, title, artist, lyrics_with_chords, original_key, 
                           tempo_bpm, capo_position, is_favorite, play_count, 
                           creation_date, modification_date, notes, video_links)
          SELECT id, titulo, autor, letra_con_acordes, tonalidad_original,
                 tempo_bpm, posicion_capo, es_favorita, contador_reproducciones,
                 fecha_creacion, fecha_modificacion, notas, enlaces_video
          FROM canciones
        ''');
      }

      if (oldCategoriesTableExists) {
        await db.rawQuery('''
          INSERT INTO categories (id, name, color, order_index, is_predefined)
          SELECT id, nombre, color, orden, es_predefinida
          FROM categorias
        ''');
      }

      // Create other tables if they don't exist
      await db.execute('''
        CREATE TABLE IF NOT EXISTS song_category(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          song_id INTEGER NOT NULL,
          category_id INTEGER NOT NULL,
          FOREIGN KEY(song_id) REFERENCES songs(id) ON DELETE CASCADE,
          FOREIGN KEY(category_id) REFERENCES categories(id) ON DELETE CASCADE,
          UNIQUE(song_id, category_id)
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
          FOREIGN KEY(song_id) REFERENCES songs(id) ON DELETE CASCADE
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

  Future<int> insertSong(Song song) async {
    final db = await database;
    return await db.insert('songs', {
      'title': song.title,
      'artist': song.artist,
      'lyrics_with_chords': song.lyricsWithChords,
      'original_key': song.originalKey,
      'tempo_bpm': song.tempoBpm,
      'capo_position': song.capoPosition,
      'is_favorite': song.isFavorite ? 1 : 0,
      'play_count': song.playCount,
      'creation_date': song.creationDate.toIso8601String(),
      'modification_date': song.modificationDate.toIso8601String(),
      'notes': song.notes,
      'video_links': song.videoLinks != null ? song.videoLinks!.join('||') : null,
    });
  }

  Future<List<Song>> getSongs() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('songs', orderBy: 'title');
    
    return List.generate(maps.length, (i) {
      return Song(
        id: maps[i]['id'],
        title: maps[i]['title'],
        artist: maps[i]['artist'],
        lyricsWithChords: maps[i]['lyrics_with_chords'],
        originalKey: maps[i]['original_key'],
        tempoBpm: maps[i]['tempo_bpm'],
        capoPosition: maps[i]['capo_position'] ?? 0,
        isFavorite: maps[i]['is_favorite'] == 1,
        playCount: maps[i]['play_count'] ?? 0,
        creationDate: DateTime.parse(maps[i]['creation_date']),
        modificationDate: DateTime.parse(maps[i]['modification_date']),
        notes: maps[i]['notes'],
        videoLinks: maps[i]['video_links'] != null 
            ? (maps[i]['video_links'] as String).split('||')
            : null,
      );
    });
  }

  Future<Song?> getSongById(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'songs',
      where: 'id = ?',
      whereArgs: [id],
    );
    
    if (maps.isNotEmpty) {
      return Song(
        id: maps[0]['id'],
        title: maps[0]['title'],
        artist: maps[0]['artist'],
        lyricsWithChords: maps[0]['lyrics_with_chords'],
        originalKey: maps[0]['original_key'],
        tempoBpm: maps[0]['tempo_bpm'],
        capoPosition: maps[0]['capo_position'] ?? 0,
        isFavorite: maps[0]['is_favorite'] == 1,
        playCount: maps[0]['play_count'] ?? 0,
        creationDate: DateTime.parse(maps[0]['creation_date']),
        modificationDate: DateTime.parse(maps[0]['modification_date']),
        notes: maps[0]['notes'],
        videoLinks: maps[0]['video_links'] != null 
            ? (maps[0]['video_links'] as String).split('||')
            : null,
      );
    }
    return null;
  }

  Future<int> updateSong(Song song) async {
    final db = await database;
    return await db.update(
      'songs',
      {
        'title': song.title,
        'artist': song.artist,
        'lyrics_with_chords': song.lyricsWithChords,
        'original_key': song.originalKey,
        'tempo_bpm': song.tempoBpm,
        'capo_position': song.capoPosition,
        'is_favorite': song.isFavorite ? 1 : 0,
        'play_count': song.playCount,
        'modification_date': DateTime.now().toIso8601String(),
        'notes': song.notes,
        'video_links': song.videoLinks != null ? song.videoLinks!.join('||') : null,
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

  Future<Category?> getCategoryById(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'categories',
      where: 'id = ?',
      whereArgs: [id],
    );
    
    if (maps.isNotEmpty) {
      return Category(
        id: maps[0]['id'],
        name: maps[0]['name'],
        color: maps[0]['color'],
        order: maps[0]['order_index'],
        isPredefined: maps[0]['is_predefined'] == 1,
      );
    }
    return null;
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

  // ========== SONG-CATEGORY RELATION METHODS ==========

  Future<int> addCategoryToSong(int songId, int categoryId) async {
    final db = await database;
    return await db.insert('song_category', {
      'song_id': songId,
      'category_id': categoryId,
    });
  }

  Future<List<Category>> getCategoriesForSong(int songId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT c.* FROM categories c
      INNER JOIN song_category sc ON c.id = sc.category_id
      WHERE sc.song_id = ?
      ORDER BY c.order_index
    ''', [songId]);
    
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

  Future<int> removeCategoryFromSong(int songId, int categoryId) async {
    final db = await database;
    return await db.delete(
      'song_category',
      where: 'song_id = ? AND category_id = ?',
      whereArgs: [songId, categoryId],
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

  Future<List<Song>> getSongsWithDetailsForSetlist(int setlistId) async {
    final db = await database;
    
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT s.*, ss.order_index, ss.transposition_semitones, ss.custom_capo
      FROM setlist_songs ss
      INNER JOIN songs s ON ss.song_id = s.id
      WHERE ss.setlist_id = ?
      ORDER BY ss.order_index
    ''', [setlistId]);
    
    return List.generate(maps.length, (i) {
      return Song(
        id: maps[i]['id'],
        title: maps[i]['title'],
        artist: maps[i]['artist'],
        lyricsWithChords: maps[i]['lyrics_with_chords'],
        originalKey: maps[i]['original_key'],
        tempoBpm: maps[i]['tempo_bpm'],
        capoPosition: maps[i]['custom_capo'] ?? maps[i]['capo_position'] ?? 0,
        isFavorite: maps[i]['is_favorite'] == 1,
        playCount: maps[i]['play_count'] ?? 0,
        creationDate: DateTime.parse(maps[i]['creation_date']),
        modificationDate: DateTime.parse(maps[i]['modification_date']),
        notes: maps[i]['notes'],
        videoLinks: maps[i]['video_links'] != null 
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
    await db.delete('song_category');
    await _insertPredefinedCategories(db);
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}