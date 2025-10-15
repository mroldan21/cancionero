import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/song.dart';

class SongRepository {
  static Database? _database;
  static const String _tableName = 'songs';

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final databasePath = await getDatabasesPath();
    final path = join(databasePath, 'cancionero.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDatabase,
    );
  }

  Future<void> _createDatabase(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $_tableName (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        artist TEXT,
        lyricsWithChords TEXT NOT NULL,
        originalKey TEXT NOT NULL,
        tempoBpm INTEGER,
        capoPosition INTEGER DEFAULT 0,
        isFavorite INTEGER DEFAULT 0,
        createdAt INTEGER NOT NULL,
        updatedAt INTEGER NOT NULL
      )
    ''');
  }

  // CRUD Operations
  Future<int> insertSong(Song song) async {
    final db = await database;
    return await db.insert(_tableName, song.toMap());
  }

  Future<List<Song>> getAllSongs() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      orderBy: 'title ASC',
    );
    return List.generate(maps.length, (i) => Song.fromMap(maps[i]));
  }

  Future<Song?> getSongById(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return Song.fromMap(maps.first);
    }
    return null;
  }

  Future<int> updateSong(Song song) async {
    final db = await database;
    return await db.update(
      _tableName,
      song.toMap(),
      where: 'id = ?',
      whereArgs: [song.id],
    );
  }

  Future<int> deleteSong(int id) async {
    final db = await database;
    return await db.delete(
      _tableName,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<Song>> searchSongs(String query) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      where: 'title LIKE ? OR artist LIKE ? OR lyricsWithChords LIKE ?',
      whereArgs: ['%$query%', '%$query%', '%$query%'],
      orderBy: 'title ASC',
    );
    return List.generate(maps.length, (i) => Song.fromMap(maps[i]));
  }

  Future<void> close() async {
    final db = await database;
    db.close();
  }

  Future<void> addSampleSongs() async {
  final db = await database;
  
  // Verificar si ya existen canciones
  final count = Sqflite.firstIntValue(
    await db.rawQuery('SELECT COUNT(*) FROM $_tableName')
  );
  
  if (count! > 0) return; // Ya hay canciones, no agregar muestras
  
  // CANCIONES MÁS LARGAS PARA PROBAR SCROLL
  final sampleSongs = [
    Song(
      title: "Alabado Sea el Señor",
      artist: "Juan Pérez",
      lyricsWithChords: """
    C          G           Am
Alabado sea el Señor nuestro Dios
    F         C           G
Por su inmenso amor y compasión

    C          Em         F
Gloria al Padre, gloria al Hijo
    G          C          G
Y gloria al Espíritu Santo

    Am        Em         F
Te damos gracias por tu gran bondad
    C          G          C
Por tu misericordia y tu verdad

    F         C          G
Cantamos con alegría y devoción
    Am        F          G
Elevamos nuestras voces en oración

    C          G           Am
En la mañana al despertar
    F         C           G
Tu nombre quiero glorificar

    C          Em         F
En el trabajo y en el descanso
    G          C          G
Tu presencia es mi regalo

    Am        Em         F
En los momentos de dificultad
    C          G          C
Eres mi fuerza y mi bondad

    F         C          G
Cuando la noche llega al final
    Am        F          G
Contigo quiero caminar

    C          G           Am
Las aves cantan tu loor
    F         C           G
Las flores muestran tu color

    C          Em         F
Los ríos fluyen hacia el mar
    G          C          G
Todo te quiere alabar

    Am        Em         F
Las montañas altas y el valle
    C          G          C
Proclaman que tú eres grande

    F         C          G
El sol, la luna y las estrellas
    Am        F          G
Cuentan tus obras tan bellas

    C          G           Am
Por todo lo que has creado
    F         C           G
Sea tu nombre ensalzado

    C          Em         F
Hoy y por la eternidad
    G          C          C7
Te alabamos de verdad
      """,
      originalKey: "C",
      tempoBpm: 120,
    ),
    Song(
      title: "Gloria a Dios en el Cielo",
      artist: "María García",
      lyricsWithChords: """
    G          D          Em
Gloria a Dios en el cielo
    C          G          D
Y en la tierra paz a los hombres

    Em         C          G
Te alabamos, te bendecimos
    D          G          C
Te adoramos, te glorificamos

    G          D          Em
Por tu inmensa gloria te damos gracias
    C          G          D
Señor Dios, Rey celestial

    Em         C          G
Dios Padre todopoderoso
    D          G          C
Señor, Hijo único, Jesucristo

    G          D          Em
Señor Dios, Cordero de Dios
    C          G          D
Hijo del Padre

    Em         C          G
Tú que quitas el pecado del mundo
    D          G          C
Ten piedad de nosotros

    G          D          Em
Tú que quitas el pecado del mundo
    C          G          D
Atiende nuestra súplica

    Em         C          G
Tú que estás a la derecha del Padre
    D          G          C
Ten piedad de nosotros

    G          D          Em
Porque sólo tú eres Santo
    C          G          D
Sólo tú Señor

    Em         C          G
Sólo tú Altísimo, Jesucristo
    D          G          C
Con el Espíritu Santo

    G          D          Em
En la gloria de Dios Padre
    C          G          D
Amén, amén, aleluya

    Em         C          G
Los ángeles cantan tu gloria
    D          G          C
Los santos te adoran

    G          D          Em
Los mártires proclaman tu nombre
    C          G          D
La iglesia te venera

    Em         C          G
Desde el oriente hasta el occidente
    D          G          C
Tu nombre es alabado

    G          D          Em
De generación en generación
    C          G          D
Tu amor permanece

    Em         C          G
Por los siglos de los siglos
    D          G          C
Tu reino no tendrá fin
      """,
      originalKey: "G",
      tempoBpm: 110,
    ),
    Song(
      title: "Santo, Santo, Santo",
      artist: "Comunidad de Fe",
      lyricsWithChords: """
    D          A          Bm
Santo, santo, santo es el Señor
    G          D          A
Dios del universo, lleno está el cielo

    Bm         G          D
Bendito el que viene en nombre del Señor
    A          D          G
Hosanna en las alturas, hosanna

    D          A          Bm
Los cielos y la tierra proclaman tu gloria
    G          D          A
Los mares y los ríos cantan tu victoria

    Bm         G          D
Las montañas elevan su canto a ti
    A          D          G
Y los valles repiten tu nombre aquí

    D          A          Bm
Santo eres desde la eternidad
    G          D          A
Y por siempre santo serás

    Bm         G          D
Antes que el mundo existiera
    A          D          G
Ya eras Dios y Rey de la tierra

    D          A          Bm
Los querubines y serafines
    G          D          A
Cubren sus rostros ante ti

    Bm         G          D
Y cantan sin cesar día y noche
    A          D          G
Santo, santo, santo es el Señor

    D          A          Bm
Tu trono está fundado en justicia
    G          D          A
Y en juicio tu reino permanece

    Bm         G          D
Tu manto es la luz y la verdad
    A          D          G
Tu cetro es amor y bondad

    D          A          Bm
Los ancianos se postran ante ti
    G          D          A
Y depositan sus coronas

    Bm         G          D
Reconociendo que sólo tú
    A          D          G
Eres digno de toda alabanza

    D          A          Bm
Las naciones vendrán a adorarte
    G          D          A
Y los pueblos a glorificarte

    Bm         G          D
Porque grande eres y haces maravillas
    A          D          G
Tú solo eres Dios, no hay otro

    D          A          Bm
Santo, santo, santo
    G          D          A
Mereces toda la honra

    Bm         G          D
Santo, santo, santo
    A          D          G
Mereces toda la gloria

    D          A          Bm
Santo, santo, santo
    G          D          A
Mereces toda alabanza

    Bm         G          D
Por los siglos de los siglos
    A          D          G
Amén, amén, aleluya
      """,
      originalKey: "D",
      tempoBpm: 90,
    ),
    Song(
      title: "Cordero de Dios",
      artist: "Coros Litúrgicos",
      lyricsWithChords: """
    Am         E7         Am
Cordero de Dios que quitas el pecado
    G          C          E7
Ten piedad de nosotros, ten piedad

    Am         E7         Am
Cordero de Dios que quitas el pecado
    G          C          E7
Danos la paz, danos la paz

    Am         E7         Am
Tú que fuiste inmolado por nosotros
    G          C          E7
En la cruz del Calvario moriste

    Am         E7         Am
Para darnos vida eterna
    G          C          E7
Y limpiarnos de toda culpa

    Am         E7         Am
Tu sangre preciosa nos redime
    G          C          E7
Tu sacrificio nos salva

    Am         E7         Am
No hay otro nombre bajo el cielo
    G          C          E7
En el cual podamos ser salvos

    Am         E7         Am
Sólo en ti, Jesús, hay perdón
    G          C          E7
Sólo en ti hay redención

    Am         E7         Am
Por las llagas de tu cuerpo
    G          C          E7
Fuimos sanados y liberados

    Am         E7         Am
Por tu resurrección gloriosa
    G          C          E7
Tenemos esperanza de vida

    Am         E7         Am
Cordero inmolado desde la fundación
    G          C          E7
Del mundo, tú eres digno

    Am         E7         Am
De recibir el poder y las riquezas
    G          C          E7
La sabiduría y la fortaleza

    Am         E7         Am
La honra, la gloria y la alabanza
    G          C          E7
Por siempre y para siempre

    Am         E7         Am
Todas las criaturas en el cielo
    G          C          E7
Y en la tierra y debajo de la tierra

    Am         E7         Am
Y en el mar, a ti sea la alabanza
    G          C          E7
Y la honra y la gloria y el poder

    Am         E7         Am
Por los siglos de los siglos
    G          C          E7
Amén, aleluya, amén
      """,
      originalKey: "Am",
      tempoBpm: 70,
    ),
  ];

  // Insertar canciones de ejemplo
  for (final song in sampleSongs) {
    await db.insert(_tableName, song.toMap());
  }
}
}