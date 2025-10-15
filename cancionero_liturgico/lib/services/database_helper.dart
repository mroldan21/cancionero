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
      version: 2, // Incrementar versión por cambios en esquema
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Tabla de canciones (ya existe, verificar si necesita cambios)
    await db.execute('''
      CREATE TABLE canciones(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        titulo TEXT NOT NULL,
        autor TEXT,
        letra_con_acordes TEXT NOT NULL,
        tonalidad_original TEXT NOT NULL,
        tempo_bpm INTEGER,
        posicion_capo INTEGER DEFAULT 0,
        es_favorita INTEGER DEFAULT 0,
        contador_reproducciones INTEGER DEFAULT 0,
        fecha_creacion TEXT NOT NULL,
        fecha_modificacion TEXT NOT NULL,
        notas TEXT,
        enlaces_video TEXT
      )
    ''');

    // Tabla de categorías
    await db.execute('''
      CREATE TABLE categorias(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nombre TEXT NOT NULL UNIQUE,
        color TEXT DEFAULT "#4CAF50",
        orden INTEGER DEFAULT 0,
        es_predefinida INTEGER DEFAULT 0
      )
    ''');

    // Tabla de relación canciones-categorías
    await db.execute('''
      CREATE TABLE cancion_categoria(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        cancion_id INTEGER NOT NULL,
        categoria_id INTEGER NOT NULL,
        FOREIGN KEY(cancion_id) REFERENCES canciones(id) ON DELETE CASCADE,
        FOREIGN KEY(categoria_id) REFERENCES categorias(id) ON DELETE CASCADE,
        UNIQUE(cancion_id, categoria_id)
      )
    ''');

    // Tabla de setlists
    await db.execute('''
      CREATE TABLE setlists(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nombre TEXT NOT NULL,
        fecha_evento TEXT,
        notas TEXT,
        fecha_creacion TEXT NOT NULL,
        fecha_modificacion TEXT NOT NULL
      )
    ''');

    // Tabla de relación setlists-canciones
    await db.execute('''
      CREATE TABLE setlist_cancion(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        setlist_id INTEGER NOT NULL,
        cancion_id INTEGER NOT NULL,
        orden INTEGER NOT NULL,
        transposicion_semitonos INTEGER DEFAULT 0,
        capo_personalizado INTEGER,
        FOREIGN KEY(setlist_id) REFERENCES setlists(id) ON DELETE CASCADE,
        FOREIGN KEY(cancion_id) REFERENCES canciones(id) ON DELETE CASCADE,
        UNIQUE(setlist_id, cancion_id, orden)
      )
    ''');

    // Insertar categorías predefinidas
    await _insertarCategoriasPredefinidas(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Migraciones para versión 2
      await db.execute('''
        CREATE TABLE IF NOT EXISTS categorias(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          nombre TEXT NOT NULL UNIQUE,
          color TEXT DEFAULT "#4CAF50",
          orden INTEGER DEFAULT 0,
          es_predefinida INTEGER DEFAULT 0
        )
      ''');
      
      await _insertarCategoriasPredefinidas(db);
    }
  }

  Future<void> _insertarCategoriasPredefinidas(Database db) async {
    final categorias = [
      Categoria(nombre: "Entrada", color: "#4CAF50", orden: 1, esPredefinida: true),
      Categoria(nombre: "Meditación", color: "#2196F3", orden: 2, esPredefinida: true),
      Categoria(nombre: "Virgen María", color: "#E91E63", orden: 3, esPredefinida: true),
      Categoria(nombre: "Comunión", color: "#FFC107", orden: 4, esPredefinida: true),
      Categoria(nombre: "Ofertorio", color: "#FF9800", orden: 5, esPredefinida: true),
      Categoria(nombre: "Salida", color: "#9C27B0", orden: 6, esPredefinida: true),
      Categoria(nombre: "Adoración", color: "#FF5722", orden: 7, esPredefinida: true),
      Categoria(nombre: "Penitencial", color: "#795548", orden: 8, esPredefinida: true),
      Categoria(nombre: "Aleluya", color: "#FFEB3B", orden: 9, esPredefinida: true),
    ];

    for (var categoria in categorias) {
      await db.insert('categorias', categoria.toJson());
    }
  }

  // ========== MÉTODOS PARA CATEGORÍAS ==========
  
  Future<int> insertCategoria(Categoria categoria) async {
    final db = await database;
    return await db.insert('categorias', categoria.toJson());
  }

  Future<List<Categoria>> getCategorias() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('categorias', orderBy: 'orden');
    return List.generate(maps.length, (i) => Categoria.fromJson(maps[i]));
  }

  // ========== MÉTODOS PARA SETLISTS ==========
  
  Future<int> insertSetlist(Setlist setlist) async {
    final db = await database;
    return await db.insert('setlists', setlist.toJson());
  }

  Future<List<Setlist>> getSetlists() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('setlists', orderBy: 'fecha_creacion DESC');
    return List.generate(maps.length, (i) => Setlist.fromJson(maps[i]));
  }
}