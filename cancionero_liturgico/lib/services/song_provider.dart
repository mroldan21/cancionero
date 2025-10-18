import 'package:flutter/foundation.dart';
import 'package:cancionero_liturgico/models/song.dart';
import 'package:cancionero_liturgico/models/setlist.dart'; // Importa SetlistItem

class SongProvider with ChangeNotifier {
  Song? _selectedSong;
  SetlistItem? _selectedSetlistItem; // Nuevo: para manejar canción con config específica en setlist
  int _currentSetlistIndex = -1; // Nuevo: índice de la canción actual en el setlist

  // Getters para la canción actualmente mostrada/activa
  Song? get currentSong {
    // Si hay un SetlistItem seleccionado, devuelve la canción transpuesta/ajustada de ahí
    if (_selectedSetlistItem != null) {
      // Opcional: Crear una copia temporal de la canción con el contenido transpuesto
      // Esto evita modificar el objeto original, pero puede ser ineficiente si se llama frecuentemente.
      // Una alternativa es calcular la transposición en la vista o en un servicio al mostrarla.
      // Por ahora, devolvemos la canción original del SetlistItem.
      // El contenido transpuesto se debería calcular en la vista o en un helper.
      return _selectedSetlistItem!.song;
    }
    // Si no hay setlist activo, devuelve la canción seleccionada individualmente
    return _selectedSong;
  }

  // Nuevo getter: Transposición aplicada a la canción actual (0 si es individual, personalizada si es de setlist)
  int get currentTransposition {
    if (_selectedSetlistItem != null) {
      return _selectedSetlistItem!.transposition;
    }
    // Si se guarda una transposición global temporalmente en SongProvider para canciones individuales:
    // return _globalTranspositionForSelectedSong ?? 0;
    // Por ahora, asumimos 0 para canciones individuales no transpuestas globalmente aquí.
    return 0;
  }

  // Nuevo getter: Capo aplicado a la canción actual (null si es individual o no se usa, personalizado si es de setlist)
  int? get currentCapo {
     if (_selectedSetlistItem != null) {
      return _selectedSetlistItem!.capo;
    }
    // Si se guarda un capo global temporalmente en SongProvider para canciones individuales:
    // return _globalCapoForSelectedSong;
    // Por ahora, asumimos null para canciones individuales no configuradas globalmente aquí.
    return null;
  }

  // Nuevo getter: Indica si la canción actual forma parte de un setlist
  bool get isCurrentSongFromSetlist => _selectedSetlistItem != null;

  // Nuevo getter: Nombre del setlist actual (si aplica)
  String? get currentSetlistName => _selectedSetlistItem?.song.title; // Usar nombre del setlist si está disponible en SetlistItem o se guarda por separado

  // Nuevo getter: Índice de la canción actual en el setlist (si aplica)
  int get currentSetlistIndex => _currentSetlistIndex;

  // Nuevo getter: Total de canciones en el setlist activo (si aplica)
  // Este getter requiere que se almacene la lista completa del setlist activo
  // o que se calcule desde donde se activó el setlist.
  // Por ahora, lo dejamos como un placeholder o se implementa cuando se maneje el setlist completo en el provider.
  // int get currentSetlistTotal => _currentSetlist?.songs.length ?? 0;

  // Métodos para seleccionar una canción individual
  void setSelectedSong(Song? song) {
    // Optimización: No notificar si la canción seleccionada es la misma.
    if (_selectedSong == song) return;

    _selectedSong = song;
    _selectedSetlistItem = null; // Limpiar selección de setlist
    _currentSetlistIndex = -1; // Reiniciar índice
    notifyListeners();
  }

  void clearSelectedSong() {
    // Optimización: Solo notificar si realmente había una canción seleccionada.
    if (_selectedSong == null && _selectedSetlistItem == null) return;

    _selectedSong = null;
    _selectedSetlistItem = null;
    _currentSetlistIndex = -1;
    notifyListeners();
  }

  // Métodos para seleccionar una canción dentro de un setlist
  void setSelectedSetlistItem(SetlistItem? item, int index) {
    // Optimización: No notificar si el ítem del setlist es el mismo.
    if (_selectedSetlistItem == item && _currentSetlistIndex == index) return;

    _selectedSetlistItem = item;
    _currentSetlistIndex = index;
    _selectedSong = null; // Limpiar selección individual
    notifyListeners();
  }

  // Nuevo método: Limpiar estado de setlist activo
  void clearSetlistItem() {
    _selectedSetlistItem = null;
    _currentSetlistIndex = -1;
    // Opcionalmente, si se desea volver a una canción individual previamente seleccionada:
    // No se limpia _selectedSong aquí a menos que se desee.
    notifyListeners();
  }

  // Nuevo método: Navegar a la canción anterior en el setlist activo
  // Este método necesitaría recibir la lista completa del setlist para calcular el índice anterior
  // y llamar a setSelectedSetlistItem.
  // void goToPreviousSetlistItem(List<SetlistItem> currentSetlist) {
  //   if (_currentSetlistIndex > 0 && currentSetlist.length > _currentSetlistIndex) {
  //     setSelectedSetlistItem(currentSetlist[_currentSetlistIndex - 1], _currentSetlistIndex - 1);
  //   }
  // }

  // Nuevo método: Navegar a la canción siguiente en el setlist activo
  // void goToNextSetlistItem(List<SetlistItem> currentSetlist) {
  //   if (_currentSetlistIndex < currentSetlist.length - 1) {
  //     setSelectedSetlistItem(currentSetlist[_currentSetlistIndex + 1], _currentSetlistIndex + 1);
  //   }
  // }
}