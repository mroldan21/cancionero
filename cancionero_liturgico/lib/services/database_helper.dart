// Agregar en _onCreate después de la tabla canciones:
await db.execute('''
  CREATE TABLE categories(
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL UNIQUE,
    color TEXT DEFAULT "#4CAF50",
    order_index INTEGER DEFAULT 0,
    is_predefined INTEGER DEFAULT 0
  )
''');

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