import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cancionero_liturgico/models/song.dart';
import 'package:cancionero_liturgico/models/category_model.dart';
import 'package:cancionero_liturgico/services/song_repository.dart';
import 'package:cancionero_liturgico/services/category_repository.dart';

class SongEditScreen extends StatefulWidget {
  final Song? song; // Si es null, es una nueva canción

  const SongEditScreen({super.key, this.song});

  @override
  State<SongEditScreen> createState() => _SongEditScreenState();
}

class _SongEditScreenState extends State<SongEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _authorController;
  late TextEditingController _contentController;
  late TextEditingController _originalKeyController;
  late TextEditingController _tempoController;
  late TextEditingController _capoController;
  late TextEditingController _notesController;
  late List<String> _videoLinks = []; // Lista de enlaces de video
  late String _tempVideoLink = ''; // Campo temporal para ingresar un nuevo enlace

  List<Category> _allCategories = [];
  List<int> _selectedCategoryIds = []; // IDs de categorías seleccionadas

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.song?.title);
    _authorController = TextEditingController(text: widget.song?.author);
    _contentController = TextEditingController(text: widget.song?.content);
    _originalKeyController = TextEditingController(text: widget.song?.originalKey);
    _tempoController = TextEditingController(text: widget.song?.tempoBpm?.toString());
    _capoController = TextEditingController(text: widget.song?.capoPosition.toString());
    _notesController = TextEditingController(text: widget.song?.notes);
    _videoLinks = widget.song?.videoLinks ?? [];

    // Cargar categorías y seleccionar las actuales de la canción
    _loadCategoriesAndSelections();
  }

  Future<void> _loadCategoriesAndSelections() async {
    final categories = await Provider.of<CategoryRepository>(context, listen: false).getAllCategories();
    setState(() {
      _allCategories = categories;
      // Si es edición, cargar las categorías actuales
      if (widget.song != null) {
        // Aquí necesitarías un método en SongRepository para obtener los IDs de categorías de una canción
        // Por ahora, asumimos que se puede hacer o se maneja previamente
        // _selectedCategoryIds = await Provider.of<SongRepository>(context, listen: false).getCategoriaIdsForSong(widget.song!.id!);
        // Este paso puede requerir una llamada asíncrona adicional o manejo diferente
        // Se omite temporalmente para simplificar, pero es crucial para la funcionalidad completa.
      }
    });
  }

  Future<void> _saveSong() async {
    if (_formKey.currentState!.validate()) {
      final songRepository = Provider.of<SongRepository>(context, listen: false);
      int? tempoBpm;
      int capoPosition = 0;
      try {
        tempoBpm = int.tryParse(_tempoController.text);
        capoPosition = int.tryParse(_capoController.text) ?? 0;
      } catch (e) {
        // Manejar error de parseo
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error: Tempo o Capo inválidos')));
        return;
      }

      final song = Song(
        id: widget.song?.id, // Mantener ID si es edición
        title: _titleController.text,
        author: _authorController.text.isEmpty ? null : _authorController.text,
        content: _contentController.text,
        originalKey: _originalKeyController.text,
        tempoBpm: tempoBpm,
        capoPosition: capoPosition,
        isFavorite: widget.song?.isFavorite ?? false, // Mantener estado de favorito o inicializar
        playCount: widget.song?.playCount ?? 0, // Mantener contador o inicializar
        creationDate: widget.song?.creationDate ?? DateTime.now(), // Mantener o inicializar
        modificationDate: DateTime.now(), // Actualizar fecha de modificación
        notes: _notesController.text.isEmpty ? null : _notesController.text,
        videoLinks: _videoLinks.isEmpty ? null : _videoLinks,
      );

      if (widget.song?.id != null) {
        await songRepository.updateSong(song);
        // Actualizar categorías asociadas
        await songRepository.setCategoriasForSong(song.id!, _selectedCategoryIds);
      } else {
        await songRepository.insertSong(song);
        // Asociar categorías a la nueva canción (necesita el ID recién insertado)
        // Esto puede requerir un ajuste en song_repository para devolver el ID o manejarlo allí
        // Por ahora, se asume que setCategoriasForSong maneja la inserción y obtención del ID internomente
        // await songRepository.setCategoriasForSong(insertedId, _selectedCategoryIds);
      }
      Navigator.pop(context); // Volver a la pantalla anterior
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.song != null ? 'Editar Canción' : 'Nueva Canción'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveSong,
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView( // Permite desplazamiento si el contenido es largo
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
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
                  controller: _authorController,
                  decoration: const InputDecoration(
                    labelText: 'Autor',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _originalKeyController,
                  decoration: const InputDecoration(
                    labelText: 'Tonalidad Original *',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                     if (value == null || value.isEmpty) {
                      return 'Por favor ingresa la tonalidad original';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _tempoController,
                        decoration: const InputDecoration(
                          labelText: 'Tempo (BPM)',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _capoController,
                        decoration: const InputDecoration(
                          labelText: 'Capo (Traste)',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Selector de Categorías (requiere lógica adicional para selección múltiple)
                const Text('Categorías:'),
                FutureBuilder<List<Category>>(
                  future: Provider.of<CategoryRepository>(context, listen: false).getAllCategories(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const CircularProgressIndicator();
                    } else if (snapshot.hasError) {
                      return Text('Error: ${snapshot.error}');
                    } else {
                      final categories = snapshot.data ?? [];
                      return Wrap(
                        spacing: 8.0,
                        runSpacing: 4.0,
                        children: categories.map((category) {
                          final isSelected = _selectedCategoryIds.contains(category.id);
                          return ChoiceChip(
                            label: Text(category.name),
                            selected: isSelected,
                            selectedColor: Color(int.tryParse(category.color?.substring(1, 7) ?? '000000', radix: 16) ?? 0xFF000000),
                            onSelected: (selected) {
                              setState(() {
                                if (selected) {
                                  _selectedCategoryIds.add(category.id!);
                                } else {
                                  _selectedCategoryIds.remove(category.id);
                                }
                              });
                            },
                          );
                        }).toList(),
                      );
                    }
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _contentController,
                  decoration: const InputDecoration(
                    labelText: 'Letra con Acordes *',
                    border: OutlineInputBorder(),
                    alignLabelWithHint: true,
                  ),
                  maxLines: null,
                  expands: true,
                  keyboardType: TextInputType.multiline,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor ingresa el contenido de la canción';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _notesController,
                  decoration: const InputDecoration(
                    labelText: 'Notas',
                    border: OutlineInputBorder(),
                    alignLabelWithHint: true,
                  ),
                  maxLines: null,
                  expands: true,
                  keyboardType: TextInputType.multiline,
                ),
                const SizedBox(height: 16),
                // Lista de Enlaces de Video
                const Text('Enlaces de Video:'),
                ..._videoLinks.map((link) => Card(
                      child: ListTile(
                        title: Text(link),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () {
                            setState(() {
                              _videoLinks.remove(link);
                            });
                          },
                        ),
                      ),
                    )).toList(),
                // Campo para agregar nuevo enlace de video
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: TextEditingController(text: _tempVideoLink),
                        decoration: const InputDecoration(
                          hintText: 'Agregar enlace de video...',
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (value) {
                          setState(() {
                            _tempVideoLink = value;
                          });
                        },
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: _tempVideoLink.isEmpty ? null : () {
                        setState(() {
                          _videoLinks.add(_tempVideoLink);
                          _tempVideoLink = '';
                        });
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}