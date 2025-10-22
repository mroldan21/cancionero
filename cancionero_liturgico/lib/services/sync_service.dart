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
    final ultimaSync = await _getUltimaSincronizacion();
    
    final response = await http.post(
      Uri.parse('$_baseUrl/iniciar_sync.php'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'dispositivo_id': deviceId,
        'hash_local': await _generarHashLocal(),
        'version_app': '1.0.0',
        'ultima_sincronizacion': ultimaSync.toIso8601String(),
      }),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['success'] == true) {
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
      final List<CambioLocal> cambios = [];
      final ultimaSync = await _getUltimaSincronizacion();
      
      // Obtener canciones modificadas localmente
      final cancionesLocales = await songRepository.getCancionesModificadasDespuesDe(ultimaSync);
      
      for (final cancion in cancionesLocales) {
        // Determinar tipo de cambio
        String tipo = cancion.fechaCreacion.isAfter(ultimaSync) ? 'crear' : 'actualizar';
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
      
      return cambios;
    } catch (e) {
      print('Error recolectando cambios locales: $e');
      throw Exception('Fallo al recolectar cambios locales: $e');
    }
  }

  // 3. Subir cambios locales al servidor
  Future<ResultadoSync> _subirCambiosLocales(String sessionId, List<CambioLocal> cambios) async {
    final deviceId = await _getDeviceId();
    
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
    // Procesar canciones nuevas/actualizadas
    for (final cancionData in cambios.canciones) {
      await _procesarCancionDescargada(cancionData);
    }
    
    // Procesar canciones eliminadas
    for (final idEliminado in cambios.cancionesEliminadas) {
      await songRepository.eliminarCancion(idEliminado);
    }
    
    // Procesar setlists
    for (final setlistData in cambios.setlists) {
      await _procesarSetlistDescargado(setlistData);
    }
    
    // Procesar relaciones setlist-canción
    for (final relacionData in cambios.setlistCanciones) {
      await _procesarRelacionSetlistCancion(relacionData);
    }
  }

  // 6. Finalizar sincronización
  Future<void> _finalizarSincronizacion(String sessionId, String estado, [Map<String, dynamic>? detalles]) async {
    final deviceId = await _getDeviceId();
    
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
      print('🔄 Iniciando proceso de sincronización...');
      
      // Paso 1: Iniciar sesión de sync
      final session = await _iniciarSincronizacion();
      sessionId = session.sessionId;
      print('✅ Sesión de sync iniciada: $sessionId');
      
      // Paso 2: Recolectar cambios locales
      final cambiosLocales = await _recolectarCambiosLocales();
      print('📤 ${cambiosLocales.length} cambios locales recolectados');
      
      // Paso 3: Subir cambios locales
      ResultadoSync resultadoSubida;
      if (cambiosLocales.isNotEmpty) {
        resultadoSubida = await _subirCambiosLocales(sessionId, cambiosLocales);
        print('✅ ${resultadoSubida.cancionesSubidas} cambios subidos al servidor');
      } else {
        resultadoSubida = ResultadoSync(
          success: true,
          message: 'Sin cambios locales para subir',
          timestamp: DateTime.now(),
        );
      }
      
      // Paso 4: Descargar cambios del servidor
      final cambiosServidor = await _descargarCambiosServidor(sessionId);
      print('📥 ${cambiosServidor.totalCambios} cambios descargados del servidor');
      
      // Paso 5: Aplicar cambios localmente
      if (cambiosServidor.totalCambios > 0) {
        await _aplicarCambiosLocales(cambiosServidor);
        print('✅ Cambios del servidor aplicados localmente');
      }
      
      // Paso 6: Actualizar última fecha de sync
      await _guardarUltimaSincronizacion(DateTime.now());
      
      // Paso 7: Finalizar con éxito
      await _finalizarSincronizacion(sessionId, 'completado', {
        'cambios_subidos': cambiosLocales.length,
        'cambios_descargados': cambiosServidor.totalCambios,
      });
      
      print('🎉 Sincronización completada exitosamente');
      
      return ResultadoSync(
        success: true,
        message: 'Sincronización completada',
        cancionesSubidas: cambiosLocales.length,
        cancionesDescargadas: cambiosServidor.canciones.length,
        cancionesEliminadas: cambiosServidor.cancionesEliminadas.length,
        timestamp: DateTime.now(),
      );
      
    } catch (e) {
      print('❌ Error en sincronización: $e');
      
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
    final canciones = await songRepository.obtenerTodasCanciones();
    final contenido = canciones.map((c) => 
      '${c.titulo}${c.autor}${c.letraConAcordes}${c.tonalidadOriginal}'
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
      'notas': cancion.notas,
      'enlaces_video': cancion.videoLinks != null ? json.encode(cancion.videoLinks) : null,
      'categorias': categoryNames,
    };
  }

  Future<void> _procesarCancionDescargada(Map<String, dynamic> cancionData) async {
    // CORRECCIÓN: Mapear desde las claves del JSON (snake_case) a las propiedades del modelo local (camelCase).
    final cancion = Song(
      id: cancionData['id'] as int,
      title: cancionData['titulo'] as String,
      author: cancionData['autor'] as String?,
      content: cancionData['letra_con_acordes'] as String,
      originalKey: cancionData['tonalidad_original'] as String,
      tempoBpm: cancionData['tempo_bpm'] as int?,
      capoPosition: (cancionData['posicion_capo'] as int?) ?? 0,
      isFavorite: (cancionData['es_favorita'] as int?) == 1,
      preferredFontSize: (cancionData['preferred_font_size'] as num?)?.toDouble() ?? 16.0,
      playCount: (cancionData['contador_reproducciones'] as int?) ?? 0,
      notas: cancionData['notas'],
      videoLinks: cancionData['enlaces_video'] != null && (cancionData['enlaces_video'] as String).isNotEmpty
          ? List<String>.from(json.decode(cancionData['enlaces_video']))
          : null,
      creationDate: DateTime.parse(cancionData['fecha_creacion'] as String),
      modificationDate: DateTime.parse(cancionData['fecha_modificacion'] as String),
      // categoryIds se poblará después de procesar las categorías
    );

    // Procesar categorías
    if (cancionData['categorias'] != null) {
      final categoriasNombres = cancionData['categorias'].toString().split(',');
      final categorias = await Future.wait(
        categoriasNombres.map((nombre) => _obtenerOCrearCategoria(nombre.trim()))
      );
      // Asignar los IDs de las categorías obtenidas/creadas al campo `categoryIds` del objeto `Song`
      final songWithCategories = cancion.copyWith(
        categoryIds: categorias.where((c) => c != null).map((c) => c!.id!).toList()
      );
      
      // Guardar canción con las categorías asociadas
      if (await songRepository.existeCancion(songWithCategories.id)) {
        await songRepository.updateSong(songWithCategories);
      } else {
        await songRepository.insertSong(songWithCategories);
      }
    } else {
      // Guardar canción sin categorías
      if (await songRepository.existeCancion(cancion.id)) {
        await songRepository.updateSong(cancion);
      } else {
        await songRepository.insertSong(cancion);
      }
    }
  }

  Future<Category?> _obtenerOCrearCategoria(String nombre) async {
    var categoria = await categoryRepository.obtenerCategoriaPorNombre(nombre);
    if (categoria == null) {
      // Crear categoría personalizada
      categoria = Category(
        nombre: nombre,
        color: '#607D8B', // Color por defecto para categorías personalizadas
        esPredefinida: false,
      );
      await categoryRepository.insertCategory(categoria);
    }
    return categoria;
  }

  Future<void> _procesarSetlistDescargado(Map<String, dynamic> setlistData) async {
    // Implementar según tu modelo Setlist
  }

  Future<void> _procesarRelacionSetlistCancion(Map<String, dynamic> relacionData) async {
    // Implementar según tu modelo
  }
}