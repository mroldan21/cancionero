class SyncSession {
  final String sessionId;
  final String dispositivoId;
  final String ultimaActualizacionServidor;
  final Map<String, dynamic> estadisticasServidor;
  final DateTime timestamp;

  SyncSession({
    required this.sessionId,
    required this.dispositivoId,
    required this.ultimaActualizacionServidor,
    required this.estadisticasServidor,
    required this.timestamp,
  });

  factory SyncSession.fromJson(Map<String, dynamic> json) {
    return SyncSession(
      sessionId: json['session_id'],
      dispositivoId: json['dispositivo_id'] ?? '',
      ultimaActualizacionServidor: json['ultima_actualizacion_servidor'] ?? '',
      estadisticasServidor: Map<String, dynamic>.from(json['estadisticas_servidor'] ?? {}),
      timestamp: DateTime.parse(json['timestamp']),
    );
  }
}

class CambioLocal {
  final String tipo; // 'crear', 'actualizar', 'eliminar'
  final String tabla; // 'songs', 'setlists'
  final Map<String, dynamic> datos;
  final DateTime timestamp;

  CambioLocal({
    required this.tipo,
    required this.tabla,
    required this.datos,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() {
    return {
      'tipo': tipo,
      'tabla': tabla,
      'datos': datos,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}

class ResultadoSync {
  final bool success;
  final String message;
  final int cancionesDescargadas;
  final int cancionesSubidas;
  final int cancionesEliminadas;
  final List<dynamic> errores;
  final DateTime timestamp;

  ResultadoSync({
    required this.success,
    required this.message,
    this.cancionesDescargadas = 0,
    this.cancionesSubidas = 0,
    this.cancionesEliminadas = 0,
    this.errores = const [],
    required this.timestamp,
  });

  factory ResultadoSync.fromJson(Map<String, dynamic> json) {
    return ResultadoSync(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      cancionesDescargadas: json['canciones_descargadas'] ?? 0,
      cancionesSubidas: json['canciones_subidas'] ?? 0,
      cancionesEliminadas: json['canciones_eliminadas'] ?? 0,
      errores: List<dynamic>.from(json['errores'] ?? []),
      timestamp: DateTime.parse(json['timestamp'] ?? DateTime.now().toIso8601String()),
    );
  }
}

class RespuestaDescarga {
  final List<Map<String, dynamic>> canciones;
  final List<int> cancionesEliminadas;
  final List<Map<String, dynamic>> setlists;
  final List<Map<String, dynamic>> setlistCanciones;
  final List<dynamic> categorias; // ← AÑADIR ESTE CAMPO
  final int totalCambios;
  final DateTime timestampServidor;

  RespuestaDescarga({
    required this.canciones,
    required this.cancionesEliminadas,
    required this.setlists,
    required this.setlistCanciones,
    required this.categorias, // ← AÑADIR ESTE CAMPO
    required this.totalCambios,
    required this.timestampServidor,
  });

  factory RespuestaDescarga.fromJson(Map<String, dynamic> json) {
    return RespuestaDescarga(
      canciones: List<Map<String, dynamic>>.from(json['canciones'] ?? []),
      cancionesEliminadas: List<int>.from(json['canciones_eliminadas'] ?? []),
      setlists: List<Map<String, dynamic>>.from(json['setlists'] ?? []),
      setlistCanciones: List<Map<String, dynamic>>.from(json['setlist_canciones'] ?? []),
      categorias: json['categorias'] ?? [], // ← AÑADIR ESTE CAMPO
      totalCambios: json['total_cambios'] ?? 0,
      timestampServidor: DateTime.parse(json['timestamp_servidor']),
    );
  }
}