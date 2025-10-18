import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/song.dart';
import '../services/song_repository.dart';
import 'package:cancionero_liturgico/models/category.dart';
import 'package:cancionero_liturgico/services/category_repository.dart';

class SongEditScreen extends StatefulWidget {
  // La canción es opcional. Si es null, es una nueva canción.
  final Song? song;

  // El constructor ya no es 'const'
  const SongEditScreen({Key? key, this.song}) : super(key: key);

  @override
  _SongEditScreenState createState() => _SongEditScreenState();
}

class _SongEditScreenState extends State<SongEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _authorController;
  late TextEditingController _originalKeyController;
  late TextEditingController _tempoController;
  late TextEditingController _capoController;
  late TextEditingController _contentController;
  late TextEditingController _notesController;
  late TextEditingController _videoLinksController;
  
  // Nuevas variables de estado para las categorías
  List<Category> _allCategories = [];
  Set<int> _selectedCategoryIds = {};
  bool _isLoadingCategories = true;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    final categoryRepo = Provider.of<CategoryRepository>(context, listen: false);
    final songRepo = Provider.of<SongRepository>(context, listen: false);

    final categories = await categoryRepo.getAllCategories();
    final songCategoryIds = widget.song?.id != null
        ? await songRepo.getCategoriaIdsForSong(widget.song!.id!)
        : <int>[];

    if (!mounted) return;

    // Si estamos editando, rellenar los campos. Si no, se quedan vacíos.
    _titleController = TextEditingController(text: widget.song?.title ?? '');
    _authorController = TextEditingController(text: widget.song?.author ?? '');
    _originalKeyController = TextEditingController(text: widget.song?.originalKey ?? '');
    _tempoController = TextEditingController(text: widget.song?.tempoBpm?.toString() ?? '');
    _capoController = TextEditingController(text: widget.song?.capoPosition?.toString() ?? '0');
    _contentController = TextEditingController(text: widget.song?.content ?? '');
    _notesController = TextEditingController(text: widget.song?.notes ?? '');
    _videoLinksController = TextEditingController(text: widget.song?.videoLinks?.join(', ') ?? '');

    setState(() {
      _allCategories = categories;
      _selectedCategoryIds = Set.from(songCategoryIds);
      _isLoadingCategories = false;
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _authorController.dispose();
    _originalKeyController.dispose();
    _tempoController.dispose();
    _capoController.dispose();
    _contentController.dispose();
    _notesController.dispose();
    _videoLinksController.dispose();
    super.dispose();
  }

  Future<void> _saveSong() async {
    if (_formKey.currentState!.validate()) {
      try {
        final songRepository = Provider.of<SongRepository>(context, listen: false);
        int songId;
        
        // Crear o actualizar la canción
        final songToSave = Song(
          id: widget.song?.id,
          title: _titleController.text,
          author: _authorController.text.isNotEmpty ? _authorController.text : null,
          originalKey: _originalKeyController.text.isNotEmpty ? _originalKeyController.text : 'C',
          tempoBpm: int.tryParse(_tempoController.text),
          capoPosition: int.tryParse(_capoController.text) ?? 0,
          content: _contentController.text,
          notes: _notesController.text.isNotEmpty ? _notesController.text : null,
          videoLinks: _videoLinksController.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
          
          // Campos que no se editan aquí pero deben mantenerse
          isFavorite: widget.song?.isFavorite ?? false, // El favorito se cambia en la vista de detalle
          playCount: widget.song?.playCount ?? 0,
          creationDate: widget.song?.creationDate ?? DateTime.now(),
          preferredFontSize: widget.song?.preferredFontSize, // SOLUCIÓN: Preservar el valor existente
          modificationDate: DateTime.now(),
        );

        if (songToSave.id != null) {
          songId = songToSave.id!;
          await songRepository.updateSong(songToSave);
        } else {
          songId = await songRepository.insertSong(songToSave);
        }

        await songRepository.setCategoriasForSong(songId, _selectedCategoryIds.toList());
        Navigator.of(context).pop(true); // Devuelve 'true' para indicar éxito
        
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al guardar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text( // El título cambia si estamos creando o editando
          widget.song == null ? 'Nueva Canción' : 'Editar Canción',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Theme.of(context).primaryColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.save, color: Colors.white),
            onPressed: _saveSong,
            tooltip: 'Guardar canción',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // Campo de título
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'Título *',
                  border: OutlineInputBorder(),
                  hintText: 'Ingresa el título de la canción',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'El título es obligatorio';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _authorController,
                decoration: InputDecoration(
                  labelText: 'Autor',
                  border: OutlineInputBorder(),
                  hintText: 'Ej: Juan Pérez',
                ),
              ),
              SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _originalKeyController,
                      decoration: InputDecoration(
                        labelText: 'Tono Original *',
                        border: OutlineInputBorder(),
                        hintText: 'Ej: C, G, Am',
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'El tono es obligatorio';
                        }
                        return null;
                      },
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _tempoController,
                      decoration: InputDecoration(
                        labelText: 'Tempo (BPM)',
                        border: OutlineInputBorder(),
                        hintText: 'Ej: 120',
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _capoController,
                      decoration: InputDecoration(
                        labelText: 'Capo',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20),
              
              // Campo de contenido
              Text(
                'Contenido',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                  fontSize: 14,
                ),
              ),
              SizedBox(height: 6),
              TextFormField(
                controller: _contentController,
                maxLines: 15,
                minLines: 10,
                decoration: InputDecoration(
                  hintText: 'Ingresa la letra y acordes de la canción...',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _notesController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Notas Adicionales',
                  hintText: 'Anotaciones sobre la ejecución, estructura, etc.',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _videoLinksController,
                decoration: InputDecoration(
                  labelText: 'Enlaces de Video',
                  hintText: 'Separar múltiples enlaces con comas',
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 24),
              Text(
                'Categorías',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              _isLoadingCategories
                  ? const Center(child: CircularProgressIndicator())
                  : Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade400),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Wrap(
                        spacing: 8.0,
                        runSpacing: 4.0,
                        children: _allCategories.map((category) {
                          final isSelected = _selectedCategoryIds.contains(category.id);
                          return ChoiceChip(
                            label: Text(category.name),
                            selected: isSelected,
                            onSelected: (selected) {
                              setState(() {
                                if (selected) {
                                  _selectedCategoryIds.add(category.id!);
                                } else {
                                  _selectedCategoryIds.remove(category.id!);
                                }
                              });
                            },
                          );
                        }).toList(),
                      ),
                    ),
              SizedBox(height: 24),

              // Botones de acción
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        side: BorderSide(color: Theme.of(context).primaryColor),
                      ),
                      child: Text(
                        'Cancelar',
                        style: TextStyle(
                          color: Theme.of(context).primaryColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _saveSong,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor,
                        padding: EdgeInsets.symmetric(vertical: 12),
                        elevation: 2,
                      ),
                      child: Text(
                        'Guardar',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}