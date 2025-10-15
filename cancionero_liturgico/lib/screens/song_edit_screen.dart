import 'package:flutter/material.dart';
import '../models/song.dart';
import '../services/database_helper.dart';
import 'presentation_mode_screen.dart';

class SongEditScreen extends StatefulWidget {
  final Song? song;

  const SongEditScreen({Key? key, this.song}) : super(key: key);

  @override
  State<SongEditScreen> createState() => _SongEditScreenState();
}

class _SongEditScreenState extends State<SongEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _dbHelper = DatabaseHelper();
  
  final _titleController = TextEditingController();
  final _artistController = TextEditingController();
  final _lyricsController = TextEditingController();
  final _originalKeyController = TextEditingController();
  final _tempoController = TextEditingController();
  final _capoController = TextEditingController();
  final _notesController = TextEditingController();

  bool _isFavorite = false;
  bool _isLoading = false;
  bool get isEditing => widget.song != null;

  @override
  void initState() {
    super.initState();
    if (isEditing) {
      _loadSongData();
    } else {
      _originalKeyController.text = 'C';
      _capoController.text = '0';
    }
  }

  void _loadSongData() {
    final song = widget.song!;
    _titleController.text = song.title;
    _artistController.text = song.artist ?? '';
    _lyricsController.text = song.lyricsWithChords;
    _originalKeyController.text = song.originalKey;
    _tempoController.text = song.tempoBpm?.toString() ?? '';
    _capoController.text = song.capoPosition.toString();
    _notesController.text = song.notes ?? '';
    _isFavorite = song.isFavorite;
  }

  Future<void> _saveSong() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final song = Song(
          id: isEditing ? widget.song!.id : null,
          title: _titleController.text,
          artist: _artistController.text.isEmpty ? null : _artistController.text,
          lyricsWithChords: _lyricsController.text,
          originalKey: _originalKeyController.text,
          tempoBpm: _tempoController.text.isEmpty ? null : int.tryParse(_tempoController.text),
          capoPosition: int.tryParse(_capoController.text) ?? 0,
          isFavorite: _isFavorite,
          playCount: isEditing ? widget.song!.playCount : 0,
          creationDate: isEditing ? widget.song!.creationDate : DateTime.now(),
          modificationDate: DateTime.now(),
          notes: _notesController.text.isEmpty ? null : _notesController.text,
        );

        if (isEditing) {
          await _dbHelper.updateSong(song);
        } else {
          await _dbHelper.insertSong(song);
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Song "${song.title}" ${isEditing ? 'updated' : 'created'} successfully'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error saving song: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  void _openPresentationMode() {
    if (_formKey.currentState!.validate()) {
      // Create a temporary song object with current form data for presentation
      final tempSong = Song(
        title: _titleController.text,
        artist: _artistController.text.isEmpty ? null : _artistController.text,
        lyricsWithChords: _lyricsController.text,
        originalKey: _originalKeyController.text,
        tempoBpm: _tempoController.text.isEmpty ? null : int.tryParse(_tempoController.text),
        capoPosition: int.tryParse(_capoController.text) ?? 0,
        isFavorite: _isFavorite,
        playCount: 0,
        creationDate: DateTime.now(),
        modificationDate: DateTime.now(),
        notes: _notesController.text.isEmpty ? null : _notesController.text,
      );

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PresentationModeScreen(song: tempSong),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Song' : 'New Song'),
        actions: [
          // Presentation Mode Button - only when editing existing song or form is valid
          if (isEditing || _formKey.currentState?.validate() == true)
            IconButton(
              icon: const Icon(Icons.slideshow),
              onPressed: _openPresentationMode,
              tooltip: 'Presentation Mode',
            ),
          // Favorite Toggle
          IconButton(
            icon: Icon(_isFavorite ? Icons.favorite : Icons.favorite_border),
            onPressed: () {
              setState(() {
                _isFavorite = !_isFavorite;
              });
            },
            tooltip: _isFavorite ? 'Remove from favorites' : 'Add to favorites',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'Song Title *',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a song title';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    // Artist
                    TextFormField(
                      controller: _artistController,
                      decoration: const InputDecoration(
                        labelText: 'Artist',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Key and Capo in one row
                    Row(
                      children: [
                        // Original Key
                        Expanded(
                          child: TextFormField(
                            controller: _originalKeyController,
                            decoration: const InputDecoration(
                              labelText: 'Key *',
                              border: OutlineInputBorder(),
                              hintText: 'C, G, Am, etc.',
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter the key';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        
                        // Capo Position
                        Expanded(
                          child: TextFormField(
                            controller: _capoController,
                            decoration: const InputDecoration(
                              labelText: 'Capo Position',
                              border: OutlineInputBorder(),
                              hintText: '0',
                            ),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Tempo
                    TextFormField(
                      controller: _tempoController,
                      decoration: const InputDecoration(
                        labelText: 'Tempo (BPM)',
                        border: OutlineInputBorder(),
                        hintText: '120',
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 16),

                    // Lyrics with Chords
                    TextFormField(
                      controller: _lyricsController,
                      decoration: const InputDecoration(
                        labelText: 'Lyrics with Chords *',
                        border: OutlineInputBorder(),
                        alignLabelWithHint: true,
                        hintText: 'Format:\n    C          G\nLyrics line with chords above',
                      ),
                      maxLines: 10,
                      minLines: 5,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter the lyrics';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Notes
                    TextFormField(
                      controller: _notesController,
                      decoration: const InputDecoration(
                        labelText: 'Notes',
                        border: OutlineInputBorder(),
                        hintText: 'Additional notes or instructions...',
                      ),
                      maxLines: 3,
                    ),
                  ],
                ),
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _saveSong,
        child: const Icon(Icons.save),
        tooltip: 'Save Song',
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _artistController.dispose();
    _lyricsController.dispose();
    _originalKeyController.dispose();
    _tempoController.dispose();
    _capoController.dispose();
    _notesController.dispose();
    super.dispose();
  }
}