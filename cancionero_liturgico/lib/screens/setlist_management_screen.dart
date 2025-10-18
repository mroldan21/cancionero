import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cancionero_liturgico/models/setlist_model.dart';
import 'package:cancionero_liturgico/models/setlist.dart';
import 'package:cancionero_liturgico/models/song.dart';
import 'package:cancionero_liturgico/services/song_repository.dart';
import 'package:cancionero_liturgico/widgets/song_item.dart';

class SetlistManagementScreen extends StatefulWidget {
  final Setlist? setlist; // Si es null, es un nuevo setlist

  const SetlistManagementScreen({super.key, this.setlist});

  @override
  State<SetlistManagementScreen> createState() => _SetlistManagementScreenState();
}

class _SetlistManagementScreenState extends State<SetlistManagementScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _eventDateController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  List<Song> _allSongs = [];
  List<SetlistItem> _selectedItems = []; // MEJORA: Usar SetlistItem para mantener el orden y la configuración
  List<Song> _filteredSongs = []; // Para la lista de búsqueda
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    // Cargar datos si se está editando un setlist existente
    if (widget.setlist != null) {
      _nameController.text = widget.setlist!.name;
      if (widget.setlist!.eventDate != null) {
        _eventDateController.text = widget.setlist!.eventDate!.toString().split(' ').first; // Formato YYYY-MM-DD
      }
      _notesController.text = widget.setlist!.notes ?? '';
      _selectedItems = List.from(widget.setlist!.songs); // Cargar los SetlistItems existentes
    }
    _loadSongs();
  }

  Future<void> _loadSongs() async {
    final repo = Provider.of<SongRepository>(context, listen: false);
    _allSongs = await repo.getAllSongs();
    setState(() {
      _filteredSongs = _allSongs.where((song) => song.title.toLowerCase().contains(_searchQuery.toLowerCase())).toList();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _eventDateController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _saveSetlist() async {
    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('El nombre del setlist es obligatorio')));
      return;
    }

    final songRepository = Provider.of<SongRepository>(context, listen: false);
    final setlist = Setlist(
      id: widget.setlist?.id, // Mantener ID si es edición
      name: _nameController.text,
      eventDate: _eventDateController.text.isNotEmpty ? DateTime.parse(_eventDateController.text) : null,
      notes: _notesController.text.isNotEmpty ? _notesController.text : null,
      creationDate: widget.setlist?.creationDate ?? DateTime.now(),
      modificationDate: DateTime.now(),
      songs: _selectedItems, // MEJORA: Usar la lista de SetlistItem que ya tiene el orden correcto
    );

    if (widget.setlist?.id != null) {
      await songRepository.updateSetlist(setlist);
    } else {
      await songRepository.insertSetlist(setlist);
    }
    // Devolver 'true' para indicar que se guardaron cambios y la lista debe refrescarse.
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.setlist != null ? 'Editar Setlist' : 'Nuevo Setlist'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveSetlist,
          ),
        ],
      ),
      body: Column(
        children: [
          // Formulario de propiedades del Setlist
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nombre del Setlist *',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _eventDateController,
                  decoration: const InputDecoration(
                    labelText: 'Fecha del Evento',
                    border: OutlineInputBorder(),
                  ),
                  readOnly: true, // Permitir solo selección de fecha
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _eventDateController.text.isNotEmpty ? DateTime.parse(_eventDateController.text) : DateTime.now(),
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                    );
                    if (date != null) {
                      setState(() {
                        _eventDateController.text = date.toString().split(' ').first;
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _notesController,
                  decoration: const InputDecoration(
                    labelText: 'Notas',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          // Separador
          const Divider(),
          // Lista de Canciones Seleccionadas
          Expanded(
            flex: 1,
            child: ReorderableListView.builder(
              itemCount: _selectedItems.length,
              onReorder: (int oldIndex, int newIndex) {
                setState(() {
                  if (oldIndex < newIndex) {
                    newIndex -= 1;
                  }
                  final item = _selectedItems.removeAt(oldIndex);
                  _selectedItems.insert(newIndex, item);
                });
              },
              itemBuilder: (context, index) {
                final item = _selectedItems[index];
                final song = item.song;
                // SOLUCIÓN: Usar ObjectKey(item) para garantizar una clave única incluso si la canción se repite.
                return ListTile(
                  key: ObjectKey(item),
                  leading: CircleAvatar(
                    child: Text('${index + 1}'),
                  ),
                  title: Text(song.title),
                  subtitle: Builder(
                    builder: (context) {
                      // Ahora el capo se lee directamente de la canción
                      final capoText = song.capoPosition > 0 ? 'Capo: ${song.capoPosition}' : null;
                      final keyText = 'Tono: ${song.originalKey}';
                      return Text(capoText != null ? '$keyText | $capoText' : keyText);
                    },
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete),
                    tooltip: 'Quitar de la lista',
                    onPressed: () {
                      setState(() {
                        _selectedItems.removeAt(index);
                      });
                    },
                  ),
                );
              },
            ),
          ),
          // Separador
          const Divider(),
          // Campo de búsqueda para añadir canciones
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Buscar canciones...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (query) {
                setState(() {
                  _searchQuery = query;
                  _filteredSongs = _allSongs.where((song) => song.title.toLowerCase().contains(query.toLowerCase())).toList();
                });
              },
            ),
          ),
          // Lista de Todas las Canciones (filtrada) para agregar
          Expanded(
            flex: 1,
            child: ListView.builder(
              itemCount: _filteredSongs.length,
              itemBuilder: (context, index) {
                final song = _filteredSongs[index];
                // Aunque una canción puede estar varias veces, aquí solo la marcamos si ya está al menos una vez.
                final isSelected = _selectedItems.any((item) => item.song.id == song.id);
                return SongItem(
                  song: song,
                  onTap: () {
                    // Permitir agregar la misma canción varias veces
                    setState(() {
                      _selectedItems.add(SetlistItem(
                        song: song,
                        order: _selectedItems.length + 1, // El orden se recalculará al guardar
                      ));
                    });
                  },
                  isSelected: isSelected,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}