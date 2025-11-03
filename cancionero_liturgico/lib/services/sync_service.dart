import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:device_info_plus/device_info_plus.dart';
import '../models/sync_models.dart';
import '../models/song.dart';
import '../models/category.dart'; // Asegúrate que este modelo exista y sea correcto
import '../models/setlist_model.dart'; // CORRECCIÓN: Importar el modelo correcto para Setlist
import './song_repository.dart';
import './category_repository.dart';
import '../models/setlist.dart'; // CORRECCIÓN: Importar el repositorio faltante
import './setlist_repository.dart'; // CORRECCIÓN: Importar el repositorio faltante


class SyncService {
  static const String _baseUrl = 'https://cincomasuno.ar/api_cancionero/sync';
  static final DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
  
  final SongRepository songRepository;
  final CategoryRepository categoryRepository;
  final SetlistRepository setlistRepository; // CORRECCIÓN: El repositorio faltaba en el constructor
  
  SyncService({
    required this.songRepository,
    required this.categoryRepository,
    required this.setlistRepository,
  });

  // Obtener ID único del dispositivo
  Future<String> _getDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    String? deviceId = prefs.getString('device_id');
    
    if (deviceId == null) {
      try {
        if (defaultTargetPlatform == TargetPlatform.android) {
          AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
          deviceId = androidInfo.id;
        } else if (defaultTargetPlatform == TargetPlatform.iOS) {
          IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
          deviceId = iosInfo.identifierForVendor;
        } else {
          deviceId = 'unknown_${DateTime.now().millisecondsSinceEpoch}';
        }
      } catch (e) {
        deviceId = 'fallback_${DateTime.now().millisecondsSinceEpoch}';
      }
      
      await prefs.setString('device_id', deviceId!);
    }
    
    return deviceId;
  }

  // Obtener última fecha de sincronización
  Future<DateTime> _getUltimaSincronizacion() async {
    final prefs = await SharedPreferences.getInstance();
    final String? ultimaSync = prefs.getString('ultima_sincronizacion');
    return ultimaSync != null ? DateTime.parse(ultimaSync) : DateTime(2000);
  }

  // Guardar última fecha de sincronización
  Future<void> _guardarUltimaSincronizacion(DateTime fecha) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('ultima_sincronizacion', fecha.toIso8601String());
  }

  // 1. Iniciar sincronización
  Future<SyncSession> _iniciarSincronizacion() async {
    final deviceId = await _getDeviceId();
    print("SYNC_DEBUG: 1. ➡️  Iniciando Sincronización para dispositivo: $deviceId");
    final ultimaSync = await _getUltimaSincronizacion();
    
    final requestBody = {
      'dispositivo_id': deviceId,
      'hash_local': await _generarHashLocal(),
      'version_app': '1.0.0',
      'ultima_sincronizacion': ultimaSync.toIso8601String(),
    };

    print("SYNC_DEBUG: 1.1. 📦 Enviando cuerpo de la petición a iniciar_sync.php: ${json.encode(requestBody)}");

    final response = await http.post(
      Uri.parse('$_baseUrl/iniciar_sync.php'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(requestBody),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['success'] == true) {
        print("SYNC_DEBUG: 1.2. ✅ Sesión obtenida del servidor: ${data['data']['session_id']}");
        return SyncSession.fromJson(data['data']);
      } else {
        throw Exception('Error del servidor: ${data['message']}');
      }
    } else {
      throw Exception('Error de conexión: ${response.statusCode}');
    }
  }

  // 2. Recolectar cambios locales
  Future<List<CambioLocal>> _recolectarCambiosLocales() async {
    try {
      print("SYNC_DEBUG: 2. 🔍 Recolectando cambios locales...");
      final List<CambioLocal> cambios = [];
      final ultimaSync = await _getUltimaSincronizacion();
      
      // Obtener canciones modificadas localmente
      final cancionesLocales = await songRepository.getModifiedSongsAfter(ultimaSync);
      
      for (final cancion in cancionesLocales) {
        print("SYNC_DEBUG: 2.1. 📄 Canción local modificada encontrada: '${cancion.title}' (ID: ${cancion.id})");
        // Determinar tipo de cambio
        String tipo = cancion.creationDate.isAfter(ultimaSync) ? 'crear' : 'actualizar';
        // Convertir la canción a JSON para ser enviada
        final cancionJson = await _convertirCancionAJson(cancion);
        
        cambios.add(CambioLocal(
          tipo: tipo,
          tabla: 'songs',
          datos: cancionJson,
          timestamp: DateTime.now(),
        ));
      }
      
      // TODO: Recolectar cambios en setlists y categorías
      // cambios.addAll(await _recolectarCambiosSetlists(ultimaSync));
      // cambios.addAll(await _recolectarCambiosCategorias(ultimaSync));
      
      print("SYNC_DEBUG: 2.2. ✅ Total de cambios locales recolectados: ${cambios.length}");
      return cambios;
    } catch (e) {
      print('Error recolectando cambios locales: $e');
      throw Exception('Fallo al recolectar cambios locales: $e');
    }
  }

  // 3. Subir cambios locales al servidor
  Future<ResultadoSync> _subirCambiosLocales(String sessionId, List<CambioLocal> cambios) async {
    final deviceId = await _getDeviceId();
    print("SYNC_DEBUG: 3. 📤 Subiendo ${cambios.length} cambios al servidor...");
    
    final response = await http.post(
      Uri.parse('$_baseUrl/subir_cambios.php'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'dispositivo_id': deviceId,
        'session_id': sessionId,
        'cambios': cambios.map((c) => c.toJson()).toList(),
      }),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['success'] == true) {
        print("SYNC_DEBUG: 3.1. ✅ Respuesta del servidor a la subida: ${data['message']}");
        return ResultadoSync.fromJson(data['data']);
      } else {
        throw Exception('Error al subir cambios: ${data['message']}');
      }
    } else {
      throw Exception('Error de conexión: ${response.statusCode}');
    }
  }

  // 4. Descargar cambios del servidor
  Future<RespuestaDescarga> _descargarCambiosServidor(String sessionId) async {
    final deviceId = await _getDeviceId();
    print("SYNC_DEBUG: 4. 📥 Descargando cambios del servidor...");
    final ultimaSync = await _getUltimaSincronizacion();
    
    final response = await http.post(
      Uri.parse('$_baseUrl/descargar_cambios.php'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'dispositivo_id': deviceId,
        'session_id': sessionId,
        'ultima_sincronizacion': ultimaSync.toIso8601String(),
      }),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['success'] == true) {
        print("SYNC_DEBUG: 4.1. ✅ Cambios descargados: ${data['data']['total_cambios']}");
        return RespuestaDescarga.fromJson(data['data']);
      } else {
        throw Exception('Error al descargar cambios: ${data['message']}');
      }
    } else {
      throw Exception('Error de conexión: ${response.statusCode}');
    }
  }

  // 5. Aplicar cambios del servidor localmente
  Future<void> _aplicarCambiosLocales(RespuestaDescarga cambios) async {
    print("SYNC_DEBUG: 5. 🔄 Aplicando cambios en la base de datos local...");
    // Procesar canciones nuevas/actualizadas
    for (final cancionData in cambios.canciones) {
      print("SYNC_DEBUG: 5.1. 🎶 Procesando canción descargada: ${cancionData['titulo']}");
      await _procesarCancionDescargada(cancionData);
    }
    
    // Procesar canciones eliminadas
    for (final idEliminado in cambios.cancionesEliminadas) {
      print("SYNC_DEBUG: 5.2. 🗑️ Eliminando canción con ID: $idEliminado");
      await songRepository.deleteSong(idEliminado);
    }
    
    // Procesar setlists
    for (final setlistData in cambios.setlists) {
      await _procesarSetlistDescargado(setlistData);
    }
    
    // Procesar relaciones setlist-canción
    for (final relacionData in cambios.setlistCanciones) {
      await _procesarRelacionSetlistCancion(relacionData);
    }
    print("SYNC_DEBUG: 5.4. ✅ Finalizada la aplicación de cambios locales.");
  }

  // 6. Finalizar sincronización
  Future<void> _finalizarSincronizacion(String sessionId, String estado, [Map<String, dynamic>? detalles]) async {
    final deviceId = await _getDeviceId();
    print("SYNC_DEBUG: 6. 🏁 Finalizando sesión de sincronización con estado: '$estado'");
    
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/finalizar_sync.php'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'dispositivo_id': deviceId,
          'session_id': sessionId,
          'estado': estado,
          'detalles': detalles ?? {},
        }),
      );

      if (response.statusCode != 200) {
        print('Error al finalizar sync: ${response.statusCode}');
      }
    } catch (e) {
      print('Error finalizando sync: $e');
    }
  }

  // FUNCIÓN PRINCIPAL - Se ejecuta al pulsar el botón
  Future<ResultadoSync> sincronizarAhora() async {
    String sessionId = '';
    
    try {
      print('--- INICIO DEL PROCESO DE SINCRONIZACIÓN ---');
      
      // Paso 1: Iniciar sesión de sync
      final session = await _iniciarSincronizacion();
      sessionId = session.sessionId;
      
      // Paso 2: Recolectar cambios locales
      final cambiosLocales = await _recolectarCambiosLocales();
      
      // Paso 3: Subir cambios locales
      ResultadoSync resultadoSubida;
      if (cambiosLocales.isNotEmpty) {
        resultadoSubida = await _subirCambiosLocales(sessionId, cambiosLocales);
      } else {
        print("SYNC_DEBUG: 3. ✨ No hay cambios locales para subir.");
        resultadoSubida = ResultadoSync(
          success: true,
          message: 'Sin cambios locales para subir',
          timestamp: DateTime.now(),
        );
      }
      
      // Paso 4: Descargar cambios del servidor
      final cambiosServidor = await _descargarCambiosServidor(sessionId);
      
      // Paso 5: Aplicar cambios localmente
      if (cambiosServidor.totalCambios > 0) {
        await _aplicarCambiosLocales(cambiosServidor);
      }
      
      // Paso 6: Actualizar última fecha de sync
      await _guardarUltimaSincronizacion(DateTime.now());
      
      // Paso 7: Finalizar con éxito
      await _finalizarSincronizacion(sessionId, 'completado', {
        'cambios_subidos': cambiosLocales.length,
        'cambios_descargados': cambiosServidor.totalCambios,
      });
      
      print('--- 🎉 SINCRONIZACIÓN COMPLETADA EXITOSAMENTE 🎉 ---');
      
      return ResultadoSync(
        success: true,
        message: 'Sincronización completada',
        cancionesSubidas: cambiosLocales.length,
        cancionesDescargadas: cambiosServidor.canciones.length,
        cancionesEliminadas: cambiosServidor.cancionesEliminadas.length,
        timestamp: DateTime.now(),
      );
      
    } catch (e) {
      print('--- ❌ ERROR FATAL EN SINCRONIZACIÓN: $e ---');
      
      // Finalizar con error
      if (sessionId.isNotEmpty) {
        await _finalizarSincronizacion(sessionId, 'error', {
          'error': e.toString(),
        });
      }
      
      return ResultadoSync(
        success: false,
        message: 'Error de sincronización: $e',
        timestamp: DateTime.now(),
      );
    }
  }

  // Métodos auxiliares
  Future<String> _generarHashLocal() async {
    // Generar hash basado en las canciones locales
    final canciones = await songRepository.getAllSongs();
    final contenido = canciones.map((c) => 
      '${c.title}${c.author}${c.content}${c.originalKey}'
    ).join('');
    
    // Usar un algoritmo simple de hash (en producción usaría package:crypto)
    return _simpleHash(contenido);
  }

  String _simpleHash(String input) {
    var hash = 0;
    for (var i = 0; i < input.length; i++) {
      hash = (hash << 5) - hash + input.codeUnitAt(i);
      hash = hash & hash; // Convert to 32bit integer
    }
    return hash.toString();
  }

  Future<Map<String, dynamic>> _convertirCancionAJson(Song cancion) async {
    // CORRECCIÓN: Mapear desde el modelo local (camelCase) a las claves del JSON (snake_case) que espera el servidor.
    // Obtener los nombres de las categorías a partir de sus IDs
    final categoryNames = await categoryRepository.getCategoryNamesByIds(cancion.categoryIds);

    return {
      'id': cancion.id,
      'titulo': cancion.title,
      'autor': cancion.author,
      'letra_con_acordes': cancion.content,
      'tonalidad_original': cancion.originalKey,
      'tempo_bpm': cancion.tempoBpm,
      'posicion_capo': cancion.capoPosition,
      'es_favorita': cancion.isFavorite ? 1 : 0,
      'preferred_font_size': cancion.preferredFontSize,
      'contador_reproducciones': cancion.playCount,
      'fecha_creacion': cancion.creationDate.toIso8601String(),
      'fecha_modificacion': cancion.modificationDate.toIso8601String(),
      'notas': cancion.notes,
      'enlaces_video': cancion.videoLinks != null ? json.encode(cancion.videoLinks) : null,
      'categorias': categoryNames,
    };
  }

  Future<void> _procesarCancionDescargada(Map<String, dynamic> cancionData) async {
    print("SYNC_DEBUG: 5.1.1. ⚙️  Datos JSON recibidos: ${json.encode(cancionData)}");
    // 1. Crear el objeto Song desde los datos del servidor
    final cancion = Song(
      id: cancionData['id'] as int,
      title: cancionData['titulo'] as String,
      author: cancionData['autor'] as String?,
      content: cancionData['letra_con_acordes'] as String,
      originalKey: cancionData['tonalidad_original'] as String,
      tempoBpm: cancionData['tempo_bpm'] as int?,
      capoPosition: (cancionData['posicion_capo'] as int?) ?? 0,
      isFavorite: (cancionData['es_favorita'] as int? ?? 0) == 1,
      // CORRECCIÓN: Parsear de forma segura el tamaño de fuente, que puede venir como String desde PHP.
      preferredFontSize: double.tryParse(cancionData['preferred_font_size']?.toString() ?? '16.0') ?? 16.0,
      playCount: (cancionData['contador_reproducciones'] as int?) ?? 0,
      notes: cancionData['notas'],
      videoLinks: cancionData['enlaces_video'] != null && (cancionData['enlaces_video'] as String).isNotEmpty
          ? List<String>.from(json.decode(cancionData['enlaces_video']))
          : null,
      creationDate: DateTime.parse(cancionData['fecha_creacion'] as String),
      modificationDate: DateTime.parse(cancionData['fecha_modificacion'] as String),
      // categoryIds se poblará después de procesar las categorías
    );

    // 2. Procesar y asignar categorías
    List<int> categoryIds = [];
    if (cancionData['categorias'] != null) {
      final categoriasNombres = cancionData['categorias'].toString().split(',');
      final List<Category> categorias = [];
      for (final nombre in categoriasNombres) {
        if (nombre.trim().isNotEmpty) {
          categorias.add(await categoryRepository.getOrCreateCategoryByName(nombre.trim()));
        }
      }
      categoryIds = categorias.map((c) => c.id!).toList();
    }

    final remoteSong = cancion.copyWith(categoryIds: categoryIds);

    // 3. Comparar con la versión local antes de actualizar
    final localSong = await songRepository.getSongById(remoteSong.id!);

    if (localSong == null) {
      // La canción no existe localmente, la insertamos.
      print("SYNC_DEBUG: 5.1.2. ➕ Insertando nueva canción: '${remoteSong.title}'");
      await songRepository.insertSong(remoteSong);
      // También necesitamos insertar las relaciones de categoría
      await songRepository.setCategoriasForSong(remoteSong.id!, remoteSong.categoryIds);
    } else {
      // La canción existe, comparamos si son diferentes.
      // Esta comparación asume que has implementado `operator ==` en el modelo Song.
      if (localSong != remoteSong) {
        print("SYNC_DEBUG: 5.1.2. 🔄 Actualizando canción existente porque se detectaron cambios: '${remoteSong.title}'");
        // Solo actualizamos si hay diferencias reales.
        await songRepository.updateSong(remoteSong);
        // También actualizamos las categorías por si han cambiado.
        await songRepository.setCategoriasForSong(remoteSong.id!, remoteSong.categoryIds);
      } else {
        // No hay diferencias, no hacemos nada.
        print("SYNC_DEBUG: 5.1.2. ✨ Omitiendo actualización para '${remoteSong.title}', no hay cambios detectados.");
      }
    }
  }

  Future<void> _procesarSetlistDescargado(Map<String, dynamic> setlistData) async {
    // Implementar según tu modelo Setlist
  }

  Future<void> _procesarRelacionSetlistCancion(Map<String, dynamic> relacionData) async {
    // Implementar según tu modelo
  }
}