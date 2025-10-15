import 'package:flutter/material.dart';
import '../models/setlist_model.dart';
import '../models/song.dart';
import '../services/database_helper.dart';
import 'presentation_mode_screen.dart';

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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading setlists: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _crearNuevoSetlist() {
    showDialog(
      context: context,
      builder: (context) => SetlistEditDialog(
        onSave: (setlist) async {
          try {
            await _dbHelper.insertSetlist(setlist);
            await _loadSetlists();
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Setlist "${setlist.name}" created successfully'),
                  backgroundColor: Colors.green,
                ),
              );
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Error creating setlist: $e'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
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
              try {
                await _dbHelper.deleteSetlist(setlist.id!);
                Navigator.pop(context);
                await _loadSetlists();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Setlist "${setlist.name}" deleted successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                Navigator.pop(context);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error deleting setlist: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
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
            onPressed: _crearNuevoSetlist,
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
              // TODO: Implement edit setlist functionality
              _showEditDialog(setlist);
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

  void _showEditDialog(Setlist setlist) {
    showDialog(
      context: context,
      builder: (context) => SetlistEditDialog(
        setlist: setlist,
        onSave: (updatedSetlist) async {
          try {
            await _dbHelper.updateSetlist(updatedSetlist);
            await _loadSetlists();
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Setlist "${updatedSetlist.name}" updated successfully'),
                  backgroundColor: Colors.green,
                ),
              );
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Error updating setlist: $e'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        },
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

class SetlistEditDialog extends StatefulWidget {
  final Setlist? setlist;
  final Function(Setlist) onSave;

  const SetlistEditDialog({Key? key, this.setlist, required this.onSave}) : super(key: key);

  @override
  State<SetlistEditDialog> createState() => _SetlistEditDialogState();
}

class _SetlistEditDialogState extends State<SetlistEditDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _notesController = TextEditingController();
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    if (widget.setlist != null) {
      _nameController.text = widget.setlist!.name;
      _notesController.text = widget.setlist!.notes ?? '';
      _selectedDate = widget.setlist!.eventDate;
    }
  }

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
        id: widget.setlist?.id,
        name: _nameController.text,
        eventDate: _selectedDate,
        notes: _notesController.text.isEmpty ? null : _notesController.text,
        creationDate: widget.setlist?.creationDate ?? DateTime.now(),
        modificationDate: DateTime.now(),
      );
      widget.onSave(setlist);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.setlist == null ? 'Create New Setlist' : 'Edit Setlist'),
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
          child: Text(widget.setlist == null ? 'Create' : 'Update'),
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
  final DatabaseHelper _dbHelper = DatabaseHelper();
  List<Song> _songs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSongs();
  }

  Future<void> _loadSongs() async {
    try {
      _songs = await _dbHelper.getSongsWithDetailsForSetlist(widget.setlist.id!);
    } catch (e) {
      print("Error loading setlist songs: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading songs: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _addSongsToSetlist() {
    // TODO: Implement song selection dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Songs'),
        content: const Text('Song selection feature coming soon...'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
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
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No songs in this setlist to play'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  void _reorderSongs(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final Song item = _songs.removeAt(oldIndex);
      _songs.insert(newIndex, item);
    });
    
    // TODO: Save new order to database
    // This would require updating all song orders in the setlist_songs table
  }

  void _removeSongFromSetlist(int songId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Song'),
        content: const Text('Are you sure you want to remove this song from the setlist?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              // TODO: Implement remove song from setlist
              // await _dbHelper.removeSongFromSetlist(songId);
              await _loadSongs();
            },
            child: const Text('Remove', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.setlist.name),
        actions: [
          if (_songs.isNotEmpty)
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
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        'Event Date: ${_formatDate(widget.setlist.eventDate!)}',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  if (widget.setlist.notes != null && widget.setlist.notes!.isNotEmpty)
                    Text(
                      'Notes: ${widget.setlist.notes!}',
                      style: const TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      '${_songs.length} song${_songs.length != 1 ? 's' : ''}',
                      style: const TextStyle(fontSize: 14, color: Colors.blue),
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
                : _songs.isEmpty
                    ? const Center(
                        child: Text(
                          'No songs in this setlist\nTap + to add songs',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      )
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

  Widget _buildSongCard(Song song, int index) {
    return Card(
      key: Key('song_${song.id}_$index'),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: const Icon(Icons.music_note),
        title: Text(
          song.title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: song.artist != null ? Text(song.artist!) : null,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.slideshow, size: 20),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PresentationModeScreen(song: song),
                  ),
                );
              },
              tooltip: 'Presentation Mode',
            ),
            const Icon(Icons.drag_handle, color: Colors.grey),
          ],
        ),
        onTap: () {
          // TODO: Navigate to song details or presentation mode for single song
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PresentationModeScreen(song: song),
            ),
          );
        },
        onLongPress: () => _removeSongFromSetlist(song.id!),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}