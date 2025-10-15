import 'package:flutter/material.dart';
import '../models/setlist_model.dart';
import '../models/song.dart';
import '../screens/presentation_mode_screen.dart';
import '../services/database_helper.dart';

class SetlistManagementScreen extends StatefulWidget {
  const SetlistManagementScreen({Key? key}) : super(key: key);

  @override
  State<SetlistManagementScreen> createState() => _SetlistManagementScreenState();
}

class _SetlistManagementScreenState extends State<SetlistManagementScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  List<Setlist> _setlists = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSetlists();
  }

  Future<void> _loadSetlists() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      _setlists = await _dbHelper.getSetlists();
    } catch (e) {
      print("Error loading setlists: $e");
      // Show error message to user
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading setlists: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  void _createNewSetlist() {
    showDialog(
      context: context,
      builder: (context) => SetlistEditDialog(
        onSave: (setlist) async {
          // TODO: Implement save setlist
          await _loadSetlists();
        },
      ),
    );
  }

  void _viewSetlist(Setlist setlist) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SetlistDetailScreen(setlist: setlist),
      ),
    );
  }

  void _deleteSetlist(Setlist setlist) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Setlist'),
        content: Text('Are you sure you want to delete "${setlist.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              // TODO: Implement delete setlist
              Navigator.pop(context);
              await _loadSetlists();
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Setlists'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _createNewSetlist,
            tooltip: 'Create New Setlist',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _setlists.isEmpty
              ? const Center(
                  child: Text(
                    'No setlists yet\nTap + to create your first setlist',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                )
              : ListView.builder(
                  itemCount: _setlists.length,
                  itemBuilder: (context, index) {
                    final setlist = _setlists[index];
                    return _buildSetlistCard(setlist);
                  },
                ),
    );
  }

  Widget _buildSetlistCard(Setlist setlist) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: const Icon(Icons.playlist_play, size: 32),
        title: Text(
          setlist.name,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (setlist.eventDate != null)
              Text(
                'Date: ${_formatDate(setlist.eventDate!)}',
                style: const TextStyle(fontSize: 14),
              ),
            if (setlist.notes != null && setlist.notes!.isNotEmpty)
              Text(
                setlist.notes!,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'edit') {
              // TODO: Implement edit
            } else if (value == 'delete') {
              _deleteSetlist(setlist);
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'edit', child: Text('Edit')),
            const PopupMenuItem(value: 'delete', child: Text('Delete')),
          ],
        ),
        onTap: () => _viewSetlist(setlist),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

class SetlistEditDialog extends StatefulWidget {
  final Function(Setlist) onSave;

  const SetlistEditDialog({Key? key, required this.onSave}) : super(key: key);

  @override
  State<SetlistEditDialog> createState() => _SetlistEditDialogState();
}

class _SetlistEditDialogState extends State<SetlistEditDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _notesController = TextEditingController();
  DateTime? _selectedDate;

  void _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _saveSetlist() {
    if (_formKey.currentState!.validate()) {
      final setlist = Setlist(
        name: _nameController.text,
        eventDate: _selectedDate,
        notes: _notesController.text.isEmpty ? null : _notesController.text,
        creationDate: DateTime.now(),
        modificationDate: DateTime.now(),
      );
      
      // Save to database
      widget.onSave(setlist);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Create New Setlist'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Setlist Name',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    readOnly: true,
                    controller: TextEditingController(
                      text: _selectedDate != null 
                          ? _formatDate(_selectedDate!) 
                          : '',
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Event Date (Optional)',
                      border: OutlineInputBorder(),
                      suffixIcon: Icon(Icons.calendar_today),
                    ),
                    onTap: _selectDate,
                  ),
                ),
                if (_selectedDate != null)
                  IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      setState(() {
                        _selectedDate = null;
                      });
                    },
                  ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Notes (Optional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _saveSetlist,
          child: const Text('Create'),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

class SetlistDetailScreen extends StatefulWidget {
  final Setlist setlist;

  const SetlistDetailScreen({Key? key, required this.setlist}) : super(key: key);

  @override
  State<SetlistDetailScreen> createState() => _SetlistDetailScreenState();
}

class _SetlistDetailScreenState extends State<SetlistDetailScreen> {
  List<Song> _songs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSongs();
  }

  Future<void> _loadSongs() async {
    // TODO: Load actual songs for this setlist
    await Future.delayed(const Duration(milliseconds: 500));
    setState(() {
      _songs = [
        Song(
          id: 1,
          titulo: "Amazing Grace",
          autor: "John Newton",
          letraConAcordes: "    C          G\nAmazing grace how sweet the sound",
          tonalidadOriginal: "C",
          tempoBpm: 80,
          posicionCapo: 0,
          esFavorita: true,
          contadorReproducciones: 5,
          fechaCreacion: DateTime.now(),
          fechaModificacion: DateTime.now(),
        ),
        Song(
          id: 2,
          titulo: "How Great Thou Art",
          autor: "Carl Boberg",
          letraConAcordes: "    G          D\nThen sings my soul my Savior God to Thee",
          tonalidadOriginal: "G",
          tempoBpm: 72,
          posicionCapo: 0,
          esFavorita: false,
          contadorReproducciones: 3,
          fechaCreacion: DateTime.now(),
          fechaModificacion: DateTime.now(),
        ),
      ];
      _isLoading = false;
    });
  }

  void _addSongsToSetlist() {
    // TODO: Implement song selection
  }

  void _playSetlist() {
    if (_songs.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PresentationModeScreen(
            song: _songs.first,
            setlistSongs: _songs,
            initialIndex: 0,
          ),
        ),
      );
    }
  }

  void _reorderSongs(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final Cancion item = _songs.removeAt(oldIndex);
      _songs.insert(newIndex, item);
    });
    // TODO: Save new order to database
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.setlist.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.play_arrow),
            onPressed: _playSetlist,
            tooltip: 'Play Setlist',
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _addSongsToSetlist,
            tooltip: 'Add Songs',
          ),
        ],
      ),
      body: Column(
        children: [
          // Setlist Info
          Card(
            margin: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (widget.setlist.eventDate != null)
                    Text(
                      'Event Date: ${_formatDate(widget.setlist.eventDate!)}',
                      style: const TextStyle(fontSize: 16),
                    ),
                  if (widget.setlist.notes != null && widget.setlist.notes!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        'Notes: ${widget.setlist.notes!}',
                        style: const TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                    ),
                ],
              ),
            ),
          ),
          // Songs List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ReorderableListView.builder(
                    itemCount: _songs.length,
                    onReorder: _reorderSongs,
                    itemBuilder: (context, index) {
                      final song = _songs[index];
                      return _buildSongCard(song, index);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  // CORREGIR el método _buildSongCard:
  Widget _buildSongCard(Song song, int index) {
    return Card(
      key: Key('song_${song.id}'),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: const Icon(Icons.music_note),
        title: Text(
          song.title, // ← CORREGIDO
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: song.artist != null ? Text(song.artist!) : null, // ← CORREGIDO
        trailing: const Icon(Icons.drag_handle),
        onTap: () {
          // TODO: Navigate to song details or presentation mode
        },
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}