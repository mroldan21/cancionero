import '../models/song.dart';
import 'database_helper.dart';
// AGREGAR el import faltante
import '../models/setlist_model.dart';

class SongRepository {
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  final List<Song> _demoSongs = [];

  SongRepository() {
    _initializeDemoSongs();
  }

  void _initializeDemoSongs() {
    _demoSongs.addAll([
      Song(
        id: 1,
        title: "Alabado sea el Señor",
        artist: "John Newton",
        lyricsWithChords: """    C          G           Am
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
Te alabamos de verdad""",
        originalKey: "C",
        tempoBpm: 80,
        capoPosition: 0,
        isFavorite: true,
        playCount: 15,
        creationDate: DateTime(2024, 1, 1),
        modificationDate: DateTime(2024, 1, 15),
        notes: "Traditional hymn",
      ),
      Song(
        id: 2,
        title: "Gloria a Dios en el cielo",
        artist: "Carl Boberg",
        lyricsWithChords: """    G          D          Em
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
Tu reino no tendrá fin""",
        originalKey: "G",
        tempoBpm: 72,
        capoPosition: 0,
        isFavorite: false,
        playCount: 8,
        creationDate: DateTime(2024, 1, 2),
        modificationDate: DateTime(2024, 1, 10),
        notes: "Classic hymn of praise",
      ),
      Song(
        id: 3,
        title: "10,000 Reasons",
        artist: "Matt Redman",
        lyricsWithChords: """    C          G          Am
Bless the Lord oh my soul
    F          C          G
Oh my soul worship His holy name
    C          G          Am
Sing like never before oh my soul
    F          G          C
I'll worship Your holy name""",
        originalKey: "C",
        tempoBpm: 120,
        capoPosition: 0,
        isFavorite: true,
        playCount: 12,
        creationDate: DateTime(2024, 1, 3),
        modificationDate: DateTime(2024, 1, 20),
        notes: "Modern worship song",
      ),
      Song(
        id: 4,
        title: "Here I Am To Worship",
        artist: "Tim Hughes",
        lyricsWithChords: """    G          C          D
Light of the world You stepped down into darkness
    Em         C          G
Opened my eyes let me see
    G          C          D
Beauty that made this heart adore You
    Em         C    D    G
Hope of a life spent with You""",
        originalKey: "G",
        tempoBpm: 68,
        capoPosition: 3,
        isFavorite: false,
        playCount: 6,
        creationDate: DateTime(2024, 1, 4),
        modificationDate: DateTime(2024, 1, 12),
      ),
      Song(
        id: 5,
        title: "In Christ Alone",
        artist: "Keith Getty & Stuart Townend",
        lyricsWithChords: """    C          G          Am
In Christ alone my hope is found
    F          C          G
He is my light my strength my song
    C          G          Am
This Cornerstone this solid ground
    F          G          C
Firm through the fiercest drought and storm""",
        originalKey: "C",
        tempoBpm: 76,
        capoPosition: 0,
        isFavorite: true,
        playCount: 20,
        creationDate: DateTime(2024, 1, 5),
        modificationDate: DateTime(2024, 1, 25),
        notes: "Modern hymn",
      ),
    ]);
  }

  // ✅ CORREGIDO: Usar toJson() en lugar de toMap()
  Future<int> insertSong(Song song) async {
    try {
      return await _databaseHelper.insertSong(song);
    } catch (e) {
      print('Error inserting song: $e');
      // Fallback to demo songs for testing
      final newId = (_demoSongs.map((s) => s.id ?? 0).reduce((a, b) => a > b ? a : b)) + 1;
      final newSong = song.copyWith(id: newId);
      _demoSongs.add(newSong);
      return newId;
    }
  }

  // ✅ CORREGIDO: Usar fromJson() en lugar de fromMap()
  Future<List<Song>> getSongs() async {
    try {
      final songs = await _databaseHelper.getSongs();
      if (songs.isNotEmpty) {
        return songs;
      }
    } catch (e) {
      print('Error getting songs from database: $e');
    }
    
    // Fallback to demo songs
    return _demoSongs;
  }

  Future<Song?> getSongById(int id) async {
    try {
      final song = await _databaseHelper.getSongById(id);
      if (song != null) {
        return song;
      }
    } catch (e) {
      print('Error getting song by id: $e');
    }
    
    // Fallback to demo songs
    return _demoSongs.firstWhere((song) => song.id == id, orElse: () => _demoSongs.first);
  }

  // ✅ CORREGIDO: Usar toJson() en lugar de toMap()
  Future<int> updateSong(Song song) async {
    try {
      return await _databaseHelper.updateSong(song);
    } catch (e) {
      print('Error updating song: $e');
      // Update in demo songs
      final index = _demoSongs.indexWhere((s) => s.id == song.id);
      if (index != -1) {
        _demoSongs[index] = song;
        return 1;
      }
      return 0;
    }
  }

  Future<int> deleteSong(int id) async {
    try {
      return await _databaseHelper.deleteSong(id);
    } catch (e) {
      print('Error deleting song: $e');
      // Delete from demo songs
      final initialLength = _demoSongs.length;
      _demoSongs.removeWhere((song) => song.id == id);
      return initialLength - _demoSongs.length;
    }
  }

  Future<List<Song>> searchSongs(String query) async {
    final allSongs = await getSongs();
    if (query.isEmpty) {
      return allSongs;
    }
    
    final queryLower = query.toLowerCase();
    return allSongs.where((song) {
      return song.title.toLowerCase().contains(queryLower) ||
             (song.artist != null && song.artist!.toLowerCase().contains(queryLower)) ||
             song.lyricsWithChords.toLowerCase().contains(queryLower) ||
             (song.notes != null && song.notes!.toLowerCase().contains(queryLower));
    }).toList();
  }

  Future<List<Song>> getFavoriteSongs() async {
    final allSongs = await getSongs();
    return allSongs.where((song) => song.isFavorite).toList();
  }

  Future<void> toggleFavorite(int songId) async {
    final song = await getSongById(songId);
    if (song != null) {
      final updatedSong = song.copyWith(
        isFavorite: !song.isFavorite,
        modificationDate: DateTime.now(),
      );
      await updateSong(updatedSong);
    }
  }

  Future<void> incrementPlayCount(int songId) async {
    final song = await getSongById(songId);
    if (song != null) {
      final updatedSong = song.copyWith(
        playCount: song.playCount + 1,
        modificationDate: DateTime.now(),
      );
      await updateSong(updatedSong);
    }
  }

  // Methods for demo data management
  List<Song> getDemoSongs() {
    return List.from(_demoSongs);
  }

  void clearDemoSongs() {
    _demoSongs.clear();
  }

  void addDemoSong(Song song) {
    _demoSongs.add(song);
  }

  // ✅ CORREGIDO: Métodos para categorías
  Future<List<Song>> getSongsByCategory(int categoryId) async {
    // TODO: Implement when category relations are ready
    final allSongs = await getSongs();
    // For now, return all songs for testing
    return allSongs;
  }

  // ✅ CORREGIDO: Métodos para setlists
  Future<List<Song>> getSongsForSetlist(int setlistId) async {
    try {
      return await _databaseHelper.getSongsWithDetailsForSetlist(setlistId);
    } catch (e) {
      print('Error getting songs for setlist: $e');
      // Fallback to first 3 demo songs for testing
      return _demoSongs.take(3).toList();
    }
  }

  // Utility method to initialize database with demo data
  Future<void> initializeWithDemoData() async {
    try {
      final existingSongs = await _databaseHelper.getSongs();
      if (existingSongs.isEmpty) {
        for (final song in _demoSongs) {
          await _databaseHelper.insertSong(song);
        }
        print('Demo data initialized successfully');
      }
    } catch (e) {
      print('Error initializing demo data: $e');
    }
  }

  // Method to get statistics
  Future<Map<String, int>> getStatistics() async {
    final songs = await getSongs();
    return {
      'totalSongs': songs.length,
      'favoriteSongs': songs.where((s) => s.isFavorite).length,
      'totalPlays': songs.fold(0, (sum, song) => sum + song.playCount),
    };
  }

  // Method to get recently played songs
  Future<List<Song>> getRecentlyPlayed({int limit = 5}) async {
    final songs = await getSongs();
    songs.sort((a, b) => b.playCount.compareTo(a.playCount));
    return songs.take(limit).toList();
  }

  // Method to get newest songs
  Future<List<Song>> getNewestSongs({int limit = 5}) async {
    final songs = await getSongs();
    songs.sort((a, b) => b.creationDate.compareTo(a.creationDate));
    return songs.take(limit).toList();
  }

  // AGREGAR este método para inicializar setlists demo
  Future<void> initializeSetlistsDemoData() async {
    try {
      final dbHelper = DatabaseHelper();
      final existingSetlists = await dbHelper.getSetlists();
      
      if (existingSetlists.isEmpty) {
        print('🔄 Inicializando setlists demo...');
        
        // Crear setlists demo
        final demoSetlists = [
          Setlist(
            name: "Misa Dominical",
            eventDate: DateTime(2024, 2, 4),
            notes: "Misa de 10:00 AM",
            creationDate: DateTime.now(),
            modificationDate: DateTime.now(),
          ),
          Setlist(
            name: "Navidad 2024", 
            eventDate: DateTime(2024, 12, 24),
            notes: "Misa de Nochebuena",
            creationDate: DateTime.now(),
            modificationDate: DateTime.now(),
          ),
          Setlist(
            name: "Bautismo Juan Pérez",
            eventDate: DateTime(2024, 3, 15),
            notes: "Ceremonia de bautismo",
            creationDate: DateTime.now(), 
            modificationDate: DateTime.now(),
          ),
        ];
        
        for (final setlist in demoSetlists) {
          await dbHelper.insertSetlist(setlist);
        }
        
        print('✅ Setlists demo inicializados: ${demoSetlists.length} setlists');
      } else {
        print('✅ Ya existen ${existingSetlists.length} setlists');
      }
    } catch (e) {
      print('❌ Error inicializando setlists demo: $e');
    }
  }


}