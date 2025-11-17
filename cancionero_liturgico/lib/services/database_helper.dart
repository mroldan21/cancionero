import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    print("[DB] _initDatabase: Abriendo la base de datos...");
    String path = join(await getDatabasesPath(), 'cancionero.db');
    return await openDatabase(
      path,
      version: 9, // SOLICITUD: Incrementar versión para añadir categoría y setlist de ejemplo
      onCreate: _onCreate,
      onUpgrade: _onUpgrade, // Añadir callback de actualización
    );
  }

  // Nueva función para manejar actualizaciones de versión
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    print("[DB] _onUpgrade: Actualizando la base de datos de v$oldVersion a v$newVersion.");
    
    // Migración de v8 a v9: Agregar nuevas columnas a songs
    if (oldVersion < 9) {
      print("[DB] _onUpgrade: Agregando columnas: activo, estado, fuente, hash_contenido, version");
      await db.execute('ALTER TABLE songs ADD COLUMN activo INTEGER DEFAULT 1');
      await db.execute('ALTER TABLE songs ADD COLUMN estado TEXT DEFAULT "aprobado"');
      await db.execute('ALTER TABLE songs ADD COLUMN fuente TEXT');
      await db.execute('ALTER TABLE songs ADD COLUMN hash_contenido TEXT');
      await db.execute('ALTER TABLE songs ADD COLUMN version INTEGER DEFAULT 1');
      print("[DB] ✅ Columnas agregadas exitosamente");
    }
    
    // Si hay versiones anteriores que necesitan recreación completa
    if (oldVersion < 8) {
      print("[DB] _onUpgrade: Borrando todas las tablas existentes.");
      const tables = [
        'cancion_categoria',
        'setlist_cancion',
        'categories',
        'songs',
        'setlists',
        'configuracion'
      ];

      for (final table in tables) {
        await db.execute('DROP TABLE IF EXISTS $table;');
      }
      await _onCreate(db, newVersion);
    }
  }

  Future<void> _onCreate(Database db, int version) async {
    print("[DB] _onCreate: Creando tablas y datos semilla para la versión $version.");
    // Crear tablas según el modelo de datos actualizado
    await _createTables(db);

    // Insertar datos semilla (categorías predefinidas y canciones de ejemplo)
    await _insertSeedData(db);
  }

  // Función auxiliar para crear todas las tablas
  Future<void> _createTables(Database db) async {
    print("[DB] _createTables: Creando las tablas...");
    // Tabla de Categorías
    await db.execute('''
      CREATE TABLE categories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nombre TEXT NOT NULL UNIQUE,
        color TEXT,
        orden INTEGER DEFAULT 0,
        es_predefinida INTEGER DEFAULT 0 -- BOOLEANO: 0 = false, 1 = true
      )
    ''');

    // Tabla de Canciones
    await db.execute('''
      CREATE TABLE songs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        titulo TEXT NOT NULL,
        autor TEXT,
        letra_con_acordes TEXT NOT NULL,
        tonalidad_original TEXT NOT NULL,
        tempo_bpm INTEGER,
        posicion_capo INTEGER DEFAULT 0,
        es_favorita INTEGER DEFAULT 0,
        preferred_font_size REAL DEFAULT 16.0,
        contador_reproducciones INTEGER DEFAULT 0,
        fecha_creacion TEXT NOT NULL,
        fecha_modificacion TEXT NOT NULL,
        notas TEXT,
        enlaces_video TEXT,
        activo INTEGER DEFAULT 1,
        estado TEXT DEFAULT 'aprobado',
        fuente TEXT,
        hash_contenido TEXT,
        version INTEGER DEFAULT 1
      )
    ''');
    
    // Tabla de Relación Muchos a Muchos: Canciones y Categorías
    await db.execute('''
      CREATE TABLE cancion_categoria (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        cancion_id INTEGER NOT NULL,
        categoria_id INTEGER NOT NULL,
        FOREIGN KEY (cancion_id) REFERENCES songs (id) ON DELETE CASCADE,
        FOREIGN KEY (categoria_id) REFERENCES categories (id) ON DELETE CASCADE,
        UNIQUE(cancion_id, categoria_id)
      )
    ''');

    // Tabla de Setlists
    await db.execute('''
      CREATE TABLE setlists (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nombre TEXT NOT NULL UNIQUE,
        fecha_evento TEXT, -- Almacenar como TEXT en formato ISO
        notas TEXT,
        fecha_creacion TEXT NOT NULL, -- Almacenar como TEXT en formato ISO
        fecha_modificacion TEXT NOT NULL -- Almacenar como TEXT en formato ISO
      )
    ''');

    // Tabla de Relación con Configuración: Canciones en Setlists
    await db.execute('''
      CREATE TABLE setlist_cancion (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        setlist_id INTEGER NOT NULL,
        cancion_id INTEGER NOT NULL,
        orden INTEGER NOT NULL,
        transposicion_semitonos INTEGER DEFAULT 0,
        capo_personalizado INTEGER, -- Puede ser nulo si no se usa capo en esta instancia
        FOREIGN KEY (setlist_id) REFERENCES setlists (id) ON DELETE CASCADE,
        FOREIGN KEY (cancion_id) REFERENCES songs (id) ON DELETE CASCADE,
        UNIQUE(setlist_id, orden)
      )
    ''');

    // Tabla de Configuración (Key-Value)
    await db.execute('''
      CREATE TABLE configuracion (
        clave TEXT PRIMARY KEY,
        valor TEXT NOT NULL,
        fecha_modificacion TEXT NOT NULL -- Almacenar como TEXT en formato ISO
      )
    ''');

    // Crear índices para optimizar búsquedas y consultas
    await db.execute('CREATE INDEX idx_titulo ON songs (titulo);');
    await db.execute('CREATE INDEX idx_favoritas ON songs (es_favorita);');
    await db.execute('CREATE INDEX idx_fecha_modificacion_songs ON songs (fecha_modificacion);');
    await db.execute('CREATE INDEX idx_nombre_categoria ON categories (nombre);');
    await db.execute('CREATE INDEX idx_orden_categoria ON categories (orden);');
    await db.execute('CREATE INDEX idx_nombre_setlist ON setlists (nombre);');
    await db.execute('CREATE INDEX idx_fecha_evento_setlist ON setlists (fecha_evento);');
    await db.execute('CREATE INDEX idx_setlist_cancion_setlist ON setlist_cancion (setlist_id);');
    await db.execute('CREATE INDEX idx_setlist_cancion_orden ON setlist_cancion (setlist_id, orden);');
    print("[DB] _createTables: Tablas creadas exitosamente.");
  }

  // Función auxiliar para insertar datos semilla
  Future<void> _insertSeedData(Database db) async {
    print("[DB] _insertSeedData: Insertando datos semilla...");
    // Verificar si ya existen categorías (para evitar duplicados en reinicios)
    final categoryCountResult = await db.rawQuery('SELECT COUNT(*) as count FROM categories');
    final categoryCount = Sqflite.firstIntValue(categoryCountResult) ?? 0;

    if (categoryCount == 0) {
      await _insertPredefinedCategories(db);
    } else {
      print("[DB] _insertSeedData: Categorías ya existen ($categoryCount), omitiendo inserción.");
    }

    // Verificar si ya existen canciones (para evitar duplicados en reinicios)
    final songCountResult = await db.rawQuery('SELECT COUNT(*) as count FROM songs');
    final songCount = Sqflite.firstIntValue(songCountResult) ?? 0;

    if (songCount == 0) {
      // Insertar canciones y obtener el mapa de títulos a IDs en una sola llamada
      final songIdMap = await _insertExampleSongs(db);
      await _insertExampleSetlists(db, songIdMap);
    } else {
      print("[DB] _insertSeedData: Canciones ya existen ($songCount), omitiendo inserción.");
    }
  }


  // Función auxiliar para insertar categorías predefinidas
  Future<void> _insertPredefinedCategories(Database db) async {
    print("[DB] _insertPredefinedCategories: Insertando categorías predefinidas...");
    final predefinedCategories = [
      {'nombre': 'Entrada', 'color': '#4CAF50', 'orden': 1},
      {'nombre': 'Meditación', 'color': '#2196F3', 'orden': 2},
      {'nombre': 'Virgen María', 'color': '#E91E63', 'orden': 3},
      {'nombre': 'Comunión', 'color': '#FFC107', 'orden': 4},
      {'nombre': 'Ofertorio', 'color': '#FF9800', 'orden': 5},
      {'nombre': 'Salida', 'color': '#9C27B0', 'orden': 6},
      {'nombre': 'Adoración', 'color': '#FF5722', 'orden': 7},
      {'nombre': 'Penitencial', 'color': '#795548', 'orden': 8},
      {'nombre': 'Aleluya', 'color': '#FFEB3B', 'orden': 9},
      {'nombre': 'Canciones Mías', 'color': '#607D8B', 'orden': 10, 'es_predefinida': 0}, // SOLICITUD: Categoría personalizada
    ];

    for (var catData in predefinedCategories) {
      await db.insert('categories', {
        'nombre': catData['nombre'],
        'color': catData['color'],
        'orden': catData['orden'],
        'es_predefinida': catData['es_predefinida'] ?? 1, // Usar el valor del mapa o 1 por defecto
      });
    }
    print("[DB] _insertPredefinedCategories: ${predefinedCategories.length} categorías insertadas.");
  }

  
  // Función auxiliar para insertar canciones de ejemplo
  // Modificado para devolver un mapa de títulos a IDs
  Future<Map<String, int>> _insertExampleSongs(Database db) async {
    print("[DB] _insertExampleSongs: Insertando canciones de ejemplo...");
    // 1. Obtener IDs de categorías predefinidas para asociarlas
    Map<String, int> categoryMap = {};
    final categoryResults = await db.query('categories', columns: ['id', 'nombre']);
    for (var row in categoryResults) {
      // Asegurar cast explícito para nombre y id
      final catName = row['nombre'] as String;
      final catId = row['id'] as int;
      categoryMap[catName] = catId;
    }

    Map<String, int> songIdMap = {}; // Mapa para almacenar título -> ID
    final exampleSongs = [
      // ... (tu lista de exampleSongs aquí, igual que antes) ...
      {
        "titulo": "Ave María",
        "autor": "Franz Schubert",
        "letra_con_acordes": "    G              C              G              D\nDios te salve, María, llena eres de gracia\n    G              C              G              D\nEl Señor es contigo, bendita Tú eres\n    Em             C              G              D\nMadre del Señor, Ruega por nosotros\n    G              C              G              D\nQue pecadores invocamos tu nombre\n\n    G              C              G              D\nSanta María, Madre de Dios\n    Em             C              G              D\nRuega por nosotros, Ruega por nosotros\n    G              C              G              D\nSanta María, Madre de Dios\n    Em             C              G              D\nRuega por nosotros, Ruega por nosotros\n\n    G              C              G              D\nSanta María, Madre de Dios\n    Em             C              G              D\nRuega por nosotros, Ruega por nosotros\n    G              C              G              D\nSanta María, Madre de Dios\n    Em             C              G              D\nRuega por nosotros, Ruega por nosotros",
        "tonalidad_original": "G",
        "tempo_bpm": 70,
        "posicion_capo": 0,
        "preferred_font_size": 16.0, // SOLICITUD: Añadir valor por defecto
        "notas": "Canta el estribillo a capella",
        "enlaces_video": ["https://www.youtube.com/watch?v=ejemplo_ave_maria"],
        "categorias": ["Virgen María", "Adoración"]
      },
      {
        "titulo": "Alabado Sea el Señor",
        "autor": "Juan Pérez",
        "letra_con_acordes": "    G              Em             C              D\nAlabado sea el Señor, por su amor y compasión\n    G              Em             C              D\nPor su gracia infinita, por su bendición\n\n    Em             C              G              D\nCantemos con alegría, demos gracias al Señor\n    Em             C              G              D\nCon el corazón abierto, demos gloria al Señor",
        "tonalidad_original": "G",
        "tempo_bpm": 120,
        "posicion_capo": 2,
        "preferred_font_size": 18.0, // SOLICITUD: Añadir valor por defecto
        "notas": "Canta María el estribillo",
        "enlaces_video": ["https://www.youtube.com/watch?v=ejemplo_alabado"],
        "categorias": ["Entrada", "Adoración"]
      },
      {
        "titulo": "Canto de Meditación",
        "autor": "María López",
        "letra_con_acordes": "    Am             F              C              G\nEn silencio, en oración, me acerco a Ti\n    Am             F              C              G\nCon el alma en paz, Señor, te hablo aquí\n\n    F              C              G              Am\nTus palabras son mi luz, mi guía fiel\n    F              C              G              Am\nEn tus brazos, Padre mío, hallaré el bien",
        "tonalidad_original": "Am",
        "tempo_bpm": 72,
        "posicion_capo": 0,
        "preferred_font_size": 16.0, // SOLICITUD: Añadir valor por defecto
        "notas": "",
        "enlaces_video": [],
        "categorias": ["Meditación"]
      },
      {
        "titulo": "Gloria al Padre",
        "autor": "Coro Parroquial",
        "letra_con_acordes": "    C              F              G              Am\nGloria al Padre, al Hijo y al Espíritu Santo\n    C              F              G              Am\nDios de la vida, luz del amor\n\n    F              G              Am             Em\nDios de la vida, luz del amor\n    F              G              C              G\nDios de la vida, luz del amor\n\n    C              F              G              Am\nGloria al Padre, al Hijo y al Espíritu Santo\n    C              F              G              Am\nDios de la vida, luz del amor\n\n    F              G              Am             Em\nDios de la vida, luz del amor\n    F              G              C              G\nDios de la vida, luz del amor\n\n    C              F              G              Am\nGloria al Padre, al Hijo y al Espíritu Santo\n    C              F              G              Am\nDios de la vida, luz del amor\n\n    F              G              Am             Em\nDios de la vida, luz del amor\n    F              G              C              G\nDios de la vida, luz del amor\n\n    C              F              G              Am\nGloria al Padre, al Hijo y al Espíritu Santo\n    C              F              G              Am\nDios de la vida, luz del amor\n\n    F              G              Am             Em\nDios de la vida, luz del amor\n    F              G              C              G\nDios de la vida, luz del amor\n\n    C              F              G              Am\nGloria al Padre, al Hijo y al Espíritu Santo\n    C              F              G              Am\nDios de la vida, luz del amor\n\n    F              G              Am             Em\nDios de la vida, luz del amor\n    F              G              C              G\nDios de la vida, luz del amor\n\n    C              F              G              Am\nGloria al Padre, al Hijo y al Espíritu Santo\n    C              F              G              Am\nDios de la vida, luz del amor\n\n    F              G              Am             Em\nDios de la vida, luz del amor\n    F              G              C              G\nDios de la vida, luz del amor",
        "tonalidad_original": "C",
        "tempo_bpm": 110,
        "posicion_capo": 0,
        "preferred_font_size": 16.0, // SOLICITUD: Añadir valor por defecto
        "notas": "Cantar con entusiasmo",
        "enlaces_video": ["https://www.youtube.com/watch?v=ejemplo_gloria"],
        "categorias": ["Ofertorio", "Adoración"]
      },
      {
        "titulo": "Salida en Gloria",
        "autor": "Luis González",
        "letra_con_acordes": "    D              A              Bm             G\nSalgamos del templo, con Cristo en el corazón\n    D              A              Bm             G\nLlevemos su luz al mundo, con amor y devoción\n\n    A              G              D              A\nQue el Señor nos bendiga, nos guíe y nos proteja\n    A              G              D              A\nY que su paz nos llene, cada día de nuestra vida    D              A              Bm             G\nSalgamos del templo, con Cristo en el corazón\n    D              A              Bm             G\nLlevemos su luz al mundo, con amor y devoción\n\n    A              G              D              A\nQue el Señor nos bendiga, nos guíe y nos proteja\n    A              G              D              A\nY que su paz nos llene, cada día de nuestra vida    D              A              Bm             G\nSalgamos del templo, con Cristo en el corazón\n    D              A              Bm             G\nLlevemos su luz al mundo, con amor y devoción\n\n    A              G              D              A\nQue el Señor nos bendiga, nos guíe y nos proteja\n    A              G              D              A\nY que su paz nos llene, cada día de nuestra vida",
        "tonalidad_original": "D",
        "tempo_bpm": 95,
        "posicion_capo": 0,
        "preferred_font_size": 16.0, // SOLICITUD: Añadir valor por defecto
        "notas": "",
        "enlaces_video": [],
        "categorias": ["Salida"]
      }
    ];

    // 2. Iterar sobre las canciones de ejemplo
    for (var songData in exampleSongs) {
      // 3. Insertar la canción
      print("[DEBUG] _insertExampleSongs: Processing song '${songData['titulo']}'. preferred_font_size in map: ${songData['preferred_font_size']}");
      // Asegurar casts explícitos para campos requeridos y manejar campos opcionales
      final songId = await db.insert('songs', {
        'titulo': songData['titulo'] as String, // Cast explícito
        'autor': (songData['autor'] as String?)?.isNotEmpty == true ? songData['autor'] as String : null, // Cast y manejo de vacío
        'letra_con_acordes': songData['letra_con_acordes'] as String, // Cast explícito
        'tonalidad_original': songData['tonalidad_original'] as String, // Cast explícito
        'tempo_bpm': (songData['tempo_bpm'] as num?)?.toInt(), // Cast y conversión
        'posicion_capo': (songData['posicion_capo'] as num?)?.toInt() ?? 0, // Cast, conversión y valor por defecto
        'es_favorita': 0, // Por defecto no favorita
        'preferred_font_size': (songData['preferred_font_size'] as num?)?.toDouble(), // SOLICITUD: Leer valor del mapa
        'contador_reproducciones': 0, // Por defecto 0
        'fecha_creacion': DateTime.now().toIso8601String(), // Fecha actual
        'fecha_modificacion': DateTime.now().toIso8601String(), // Fecha actual
        'notas': (songData['notas'] as String?)?.isNotEmpty == true ? songData['notas'] as String : null, // Cast y manejo de vacío
        // 'enlaces_video': (songData['enlaces_video'] as List<dynamic>?)?.cast<String>()?.join(','), // Línea problemática original
        'enlaces_video': _convertVideoLinksToString(songData['enlaces_video']), // Usar función auxiliar
      });
      songIdMap[songData['titulo'] as String] = songId; // Guardar en el mapa

      // 4. Asociar categorías a la canción recién insertada
      // Cast explícito de la lista de categorías
      final categories = songData['categorias'] as List<dynamic>?;
      if (categories != null) {
        // Iterar sobre la lista de nombres de categorías de la canción
        for (dynamic catNameDynamic in categories) { // Recibir como dynamic
          // Cast explícito de cada nombre de categoría a String?
          String? catName = catNameDynamic as String?;
          if (catName != null) { // Verificar que no sea nulo
            // Buscar el ID de la categoría en el mapa obtenido anteriormente
            final catId = categoryMap[catName];
            if (catId != null) { // Verificar que la categoría exista en la base de datos
              // Insertar la relación en la tabla intermedia
              await db.insert('cancion_categoria', {
                'cancion_id': songId, // ID de la canción recién insertada
                'categoria_id': catId, // ID de la categoría asociada
              });
            }
            // Opcional: Loggear si una categoría nombrada no existe
            // else { print("Advertencia: Categoría '$catName' no encontrada para la canción."); }
          }
        }
      }
    }
    print("[DB] _insertExampleSongs: ${exampleSongs.length} canciones de ejemplo insertadas.");
    return songIdMap; // Devolver el mapa
  }

  // SOLICITUD: Función auxiliar para insertar setlists de ejemplo
  Future<void> _insertExampleSetlists(Database db, Map<String, int> songIdMap) async {
    print("[DB] _insertExampleSetlists: Insertando setlists de ejemplo...");
    final setlistCountResult = await db.rawQuery('SELECT COUNT(*) as count FROM setlists');
    final setlistCount = Sqflite.firstIntValue(setlistCountResult) ?? 0;

    if (setlistCount > 0) {
      print("[DB] _insertExampleSetlists: Setlists ya existen ($setlistCount), omitiendo inserción.");
      return;
    }

    // Insertar el setlist "Bautismo"
    final bautismoSetlistId = await db.insert('setlists', {
      'nombre': 'Bautismo', // SOLICITUD: Nombre del setlist
      'fecha_evento': DateTime.now().add(Duration(days: 7)).toIso8601String(),
      'notas': 'Setlist para la celebración de un bautismo.',
      'fecha_creacion': DateTime.now().toIso8601String(),
      'fecha_modificacion': DateTime.now().toIso8601String(),
    });
    print("[DB] _insertExampleSetlists: Setlist 'Bautismo' insertado con ID: $bautismoSetlistId.");

    // Asociar canciones al setlist "Bautismo"
    await db.insert('setlist_cancion', {'setlist_id': bautismoSetlistId, 'cancion_id': songIdMap['Ave María']!, 'orden': 1, 'transposicion_semitonos': 0, 'capo_personalizado': 0});
    await db.insert('setlist_cancion', {'setlist_id': bautismoSetlistId, 'cancion_id': songIdMap['Canto de Meditación']!, 'orden': 2, 'transposicion_semitonos': -2, 'capo_personalizado': 2});
    print("[DB] _insertExampleSetlists: Canciones asociadas al setlist 'Bautismo'.");

    print("[DB] _insertExampleSetlists: Setlists de ejemplo insertados.");
  }



  // Añadir esta función auxiliar dentro de DatabaseHelper
  String? _convertVideoLinksToString(dynamic videoLinksData) {
    if (videoLinksData == null) {
      return null;
    }
    if (videoLinksData is List) {
      try {
        // Intentar castear la lista a List<String>
        final stringList = videoLinksData.cast<String>();
        return stringList.join(',');
      } catch (e) {
        // Si el cast falla, puede ser que la lista tenga elementos no String
        // Opcional: loggear el error o manejarlo de otra manera
        print("Advertencia: No se pudo convertir enlaces_video a String. Error: $e");
        return null;
      }
    }
    // Si no es una lista, intentar convertirlo a String
    return videoLinksData.toString();
  }

  Future<void> debugBDCompleta() async {
    final db = await database;
    
    print("=== 🔍 DEBUG COMPLETO BD LOCAL ===");
    
    // 1. Tabla setlists
    final setlists = await db.query('setlists');
    print("🗂️  SETLISTS (${setlists.length}):");
    for (final s in setlists) {
      print("   ID: ${s['id']}, Nombre: '${s['nombre']}'");
    }
    
    // 2. Tabla setlist_cancion (CRÍTICO)
    final relaciones = await db.query('setlist_cancion');
    print("🔗 SETLIST_CANCION (${relaciones.length}):");
    for (final r in relaciones) {
      print("   ID: ${r['id']}, Setlist: ${r['setlist_id']}, Canción: ${r['cancion_id']}, Orden: ${r['orden']}");
    }
    
    // 3. Tabla songs
    final songs = await db.query('songs');
    print("🎵 SONGS (${songs.length}):");
    for (final s in songs) {
      print("   ID: ${s['id']}, Título: '${s['titulo']}'");
    }
    
    // 4. Tabla cancion_categoria
    final categoriasRel = await db.query('cancion_categoria');
    print("🏷️  CANCION_CATEGORIA (${categoriasRel.length}):");
    for (final cr in categoriasRel) {
      print("   Canción: ${cr['cancion_id']}, Categoría: ${cr['categoria_id']}");
    }
    
    print("=== 🏁 FIN DEBUG ===");
  }
}