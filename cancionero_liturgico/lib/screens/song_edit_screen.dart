import 'package:flutter/material.dart';
import '../models/song.dart';

class SongEditScreen extends StatefulWidget {
  final Song? existingSong;

  const SongEditScreen({super.key, this.existingSong});

  @override
  State<SongEditScreen> createState() => _SongEditScreenState();
}

class _SongEditScreenState extends State<SongEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _artistController = TextEditingController();
  final _lyricsController = TextEditingController();
  final _keyController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.existingSong != null) {
      _titleController.text = widget.existingSong!.title;
      _artistController.text = widget.existingSong!.artist;
      _lyricsController.text = widget.existingSong!.lyricsWithChords;
      _keyController.text = widget.existingSong!.originalKey;
    }
  }

  void _saveSong() {
    if (_formKey.currentState!.validate()) {
      final newSong = Song(
        id: widget.existingSong?.id,
        title: _titleController.text,
        artist: _artistController.text,
        lyricsWithChords: _lyricsController.text,
        originalKey: _keyController.text.isEmpty ? 'C' : _keyController.text,
      );

      // TODO: Guardar en base de datos
      print('Canción guardada: ${newSong.title}');
      
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existingSong == null ? 'Nueva Canción' : 'Editar Canción'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveSong,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Título *',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingresa un título';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _artistController,
                decoration: const InputDecoration(
                  labelText: 'Artista',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _keyController,
                decoration: const InputDecoration(
                  labelText: 'Tonalidad (ej: C, G, Am)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Letra con acordes:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: TextFormField(
                  controller: _lyricsController,
                  decoration: const InputDecoration(
                    hintText: 'Ejemplo:\n    C          G\nAlabado sea el Señor...',
                    border: OutlineInputBorder(),
                    alignLabelWithHint: true,
                  ),
                  maxLines: null,
                  expands: true,
                  textAlignVertical: TextAlignVertical.top,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor ingresa la letra con acordes';
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _artistController.dispose();
    _lyricsController.dispose();
    _keyController.dispose();
    super.dispose();
  }
}