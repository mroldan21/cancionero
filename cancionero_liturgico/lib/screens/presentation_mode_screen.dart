import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cancionero_liturgico/models/setlist_model.dart';
import 'package:cancionero_liturgico/services/song_provider.dart';
import 'package:cancionero_liturgico/screens/presentation_screen.dart';

class PresentationModeScreen extends StatelessWidget {
  final Setlist? setlist; // Si se pasa un setlist, reproduce ese; si no, usa la canción seleccionada individualmente

  const PresentationModeScreen({super.key, this.setlist});

  @override
  Widget build(BuildContext context) {
    final songProvider = Provider.of<SongProvider>(context);

    if (setlist != null && setlist!.songs.isNotEmpty) {
      // Si se proporciona un setlist, iniciar reproducción del setlist
      // Esto implica manejar la navegación entre canciones del setlist
      // y posiblemente iniciar el scroll automático si está configurado
      return _SetlistPresentationController(setlist: setlist!);
    } else {
      // Si no hay setlist, verificar si hay una canción individual seleccionada
      final selectedSong = songProvider.currentSong;
      if (selectedSong == null) {
        return const Scaffold(
          body: Center(child: Text('Selecciona una canción o un setlist para presentar')),
        );
      }
      // Presentar la canción individual
      return PresentationScreen(song: selectedSong);
    }
  }
}

// Widget interno para controlar la reproducción de un setlist
class _SetlistPresentationController extends StatefulWidget {
  final Setlist setlist;

  const _SetlistPresentationController({required this.setlist});

  @override
  State<_SetlistPresentationController> createState() => _SetlistPresentationControllerState();
}

class _SetlistPresentationControllerState extends State<_SetlistPresentationController> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    if (widget.setlist.songs.isEmpty) {
      return const Scaffold(
        body: Center(child: Text('El setlist está vacío.')),
      );
    }

    final currentItem = widget.setlist.songs[_currentIndex];
    final songProvider = Provider.of<SongProvider>(context, listen: false);

    // Seleccionar el SetlistItem actual en SongProvider para que PresentationScreen lo use
    songProvider.setSelectedSetlistItem(currentItem, _currentIndex);

    return WillPopScope(
      onWillPop: () async {
        // Limpiar la selección del setlist en SongProvider al salir
        songProvider.clearSetlistItem();
        return true; // Permitir salir
      },
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              // Barra de estado del setlist
              Container(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () {
                        if (_currentIndex > 0) {
                          setState(() {
                            _currentIndex--;
                          });
                        }
                      },
                    ),
                    Text(
                      '${_currentIndex + 1} de ${widget.setlist.songs.length}',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    IconButton(
                      icon: const Icon(Icons.arrow_forward),
                      onPressed: () {
                        if (_currentIndex < widget.setlist.songs.length - 1) {
                          setState(() {
                            _currentIndex++;
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),
              // Separador
              const Divider(height: 1),
              // Pantalla de presentación de la canción actual
              Expanded(
                child: PresentationScreen(song: currentItem.song), // Pasa la canción del item
              ),
            ],
          ),
        ),
      ),
    );
  }
}