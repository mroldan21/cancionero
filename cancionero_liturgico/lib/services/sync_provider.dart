import 'package:flutter/foundation.dart';
import './sync_service.dart';
import '../models/sync_models.dart';

class SyncProvider with ChangeNotifier {
  final SyncService syncService;
  
  bool _sincronizando = false;
  String _estado = '';
  double _progreso = 0.0;
  ResultadoSync? _ultimoResultado;

  bool get sincronizando => _sincronizando;
  String get estado => _estado;
  double get progreso => _progreso;
  ResultadoSync? get ultimoResultado => _ultimoResultado;

  SyncProvider({required this.syncService});

  Future<ResultadoSync> sincronizar() async {
    if (_sincronizando) {
      throw Exception('Ya hay una sincronización en curso');
    }

    _sincronizando = true;
    _estado = 'Iniciando...';
    _progreso = 0.0;
    notifyListeners();

    try {
      _actualizarProgreso('Conectando con servidor...', 0.1);
      
      final resultado = await syncService.sincronizarAhora();
      
      _ultimoResultado = resultado;
      _actualizarProgreso('Completado', 1.0);
      
      return resultado;
      
    } catch (e) {
      _ultimoResultado = ResultadoSync(
        success: false,
        message: e.toString(),
        timestamp: DateTime.now(),
      );
      throw e;
    } finally {
      _sincronizando = false;
      notifyListeners();
      
      // Resetear después de 3 segundos
      Future.delayed(Duration(seconds: 3), () {
        _estado = '';
        _progreso = 0.0;
        notifyListeners();
      });
    }
  }

  void _actualizarProgreso(String estado, double progreso) {
    _estado = estado;
    _progreso = progreso;
    notifyListeners();
  }

  void limpiarEstado() {
    _ultimoResultado = null;
    _estado = '';
    _progreso = 0.0;
    notifyListeners();
  }
}