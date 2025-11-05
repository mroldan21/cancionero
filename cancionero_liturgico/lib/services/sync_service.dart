import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:device_info_plus/device_info_plus.dart';
import '../models/sync_models.dart';
import '../models/song.dart';
import '../models/category.dart'; // Asegúrate que este modelo exista y sea correcto
import '../models/setlist_model.dart';
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
        print ("actualización de canción tipo: $tipo");
        // Convertir la canción a JSON para ser enviada
        final cancionJson = await _convertirCancionAJson(cancion);
        
        cambios.add(CambioLocal(
          tipo: tipo,
          tabla: 'songs',
          datos: cancionJson,
          timestamp: DateTime.now(),
        ));
      }
      
      // Recolectar cambios en setlists
      final setlistsLocales = await setlistRepository.getModifiedSetlistsAfter(ultimaSync);
      print("SYNC_DEBUG: 2.3. 📋 Setlists locales modificados encontrados: ${setlistsLocales.length}");

      // DEBUG DETALLADO Y PROCESAMIENTO DE SETLISTS
      for (final setlist in setlistsLocales) {
        print("SYNC_DEBUG: 2.3.1. Setlist: '${setlist.name}' (ID: ${setlist.id})");
        print("SYNC_DEBUG: 2.3.2. - Creación: ${setlist.creationDate}");
        print("SYNC_DEBUG: 2.3.3. - Modificación: ${setlist.modificationDate}");
        print("SYNC_DEBUG: 2.3.4. - Última sync: $ultimaSync");
        print("SYNC_DEBUG: 2.3.5. - Es después?: ${setlist.modificationDate.isAfter(ultimaSync)}");
        print("SYNC_DEBUG: 2.3.6. - Canciones: ${setlist.songs.length}");
        
        String tipo = setlist.creationDate.isAfter(ultimaSync) ? 'crear' : 'actualizar';
        print("SYNC_DEBUG: 2.3.7. - Tipo: $tipo");
        
        // Verificar el JSON que se enviará
        final setlistJson = setlist.toMap();
        setlistJson['canciones'] = setlist.songs.map((item) => {
          'cancion_id': item.song.id,
          'orden': item.order,
          'transposicion_semitonos': item.transposition,
          'capo_personalizado': item.capo,
        }).toList();
        
        print("SYNC_DEBUG: 2.3.8. - JSON a enviar: ${json.encode(setlistJson)}");

        print("SYNC_DEBUG: 2.3.8. - Canciones en setlist:");
        for (int i = 0; i < setlist.songs.length; i++) {
          final item = setlist.songs[i];
          print("SYNC_DEBUG:     $i. Canción ID: ${item.song.id}, Orden: ${item.order}, " +
                "Transposición: ${item.transposition}, Capo: ${item.capo}");
        }
        
        // AÑADIR EL SETLIST A LOS CAMBIOS (esto faltaba)
        cambios.add(CambioLocal(
          tipo: tipo,
          tabla: 'setlists', 
          datos: setlistJson,
          timestamp: DateTime.now(),
        ));
      }
      
      // COMPLETADO: Recolectar cambios en categorías (asumiendo que se pueden modificar)
      // Nota: La lógica para 'getModifiedCategoriesAfter' debería añadirse en CategoryRepository si es necesario.
      // Por ahora, este es un placeholder para mostrar dónde iría la lógica.
      /*
      final categoriasLocales = await categoryRepository.getModifiedCategoriesAfter(ultimaSync);
      for (final categoria in categoriasLocales) {
        // ... lógica para añadir cambios de categoría ...
      }
      */
      
      print("SYNC_DEBUG: 2.2. ✅ Total de cambios locales recolectados: ${cambios.length}");
      return cambios;
    } catch (e) {
      print('Error recolectando cambios locales: $e');
      throw Exception('Fallo al recolectar cambios locales: $e');
    }
  }

  //Funciones de procesamiento
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

    // En _subirCambiosLocales, después de recibir los cambios:
    _debugCambiosLocales(cambios);

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
    
    // Procesar categorías
    for (final categoriaData in cambios.categorias) {
      await _procesarCategoriaDescargada(categoriaData);
    }
    
    // Procesar setlists (que ahora incluyen sus canciones)
    for (final setlistData in cambios.setlists) {
      await _procesarSetlistDescargado(setlistData);
    }
    
    // El bucle para 'setlistCanciones' ya no es necesario.
    print("SYNC_DEBUG: 5.4. ✅ Finalizada la aplicación de cambios locales.");
  }

  // =======================================================================
  // MÉTODOS DE PROCESAMIENTO DE DATOS DESCARGADOS
  // =======================================================================

  Future<void> _procesarSetlistDescargado(Map<String, dynamic> setlistData) async {
    print("SYNC_DEBUG: 5.3.1. 📋 Procesando setlist descargado: '${setlistData['nombre']}' (ID: ${setlistData['id']})");
    
    try {
      // Convertir datos del servidor a modelo Setlist
      final setlist = Setlist(
        id: setlistData['id'] as int,
        name: setlistData['nombre'] as String,
        creationDate: DateTime.parse(setlistData['fecha_creacion'] as String),
        modificationDate: DateTime.parse(setlistData['fecha_modificacion'] as String),
        eventDate: setlistData['fecha_evento'] != null 
            ? DateTime.parse(setlistData['fecha_evento'] as String) 
            : null,
        notes: setlistData['notas'] as String?,
        // SOLUCIÓN: Mapear las canciones anidadas a objetos SetlistItem
        songs: (setlistData['canciones'] as List<dynamic>).map((itemData) {
          // Para crear el SetlistItem, necesitamos un objeto Song completo.
          // Como no lo tenemos aquí, creamos un objeto Song "parcial" solo con el ID.
          // El repositorio se encargará de usar este ID para la relación.
          final songConId = Song(
            id: itemData['cancion_id'] as int,
            title: '', // El resto de los campos no son necesarios para la relación
            content: '',
            originalKey: '',
            creationDate: DateTime.now(),
            modificationDate: DateTime.now(),
          );
          return SetlistItem(
            song: songConId,
            order: itemData['orden'] as int,
            transposition: itemData['transposicion_semitonos'] as int? ?? 0,
            capo: itemData['capo_personalizado'] as int?,
          );
        }).toList(),
      );

      // Verificar si el setlist existe localmente
      final setlistExistente = await setlistRepository.getSetlistById(setlist.id!);
      
      if (setlistExistente == null) {
        // Crear nuevo setlist
        print("SYNC_DEBUG: 5.3.2. ➕ Insertando nuevo setlist: '${setlist.name}'");
        await setlistRepository.insertSetlist(setlist);
      } else {
        // Actualizar setlist existente. El repositorio se encarga de borrar
        // las relaciones viejas y poner las nuevas que vienen en `setlist.songs`.
        print("SYNC_DEBUG: 5.3.2. 🔄 Actualizando setlist existente: '${setlist.name}'");
        await setlistRepository.updateSetlist(setlist);
      }
      
    } catch (e) {
      print("SYNC_DEBUG: 5.3.3. ❌ Error procesando setlist: $e");
      print("SYNC_DEBUG: 5.3.4. 📄 Datos del setlist: ${json.encode(setlistData)}");
    }
  }

  // NUEVO MÉTODO: Para procesar las categorías descargadas
  Future<void> _procesarCategoriaDescargada(Map<String, dynamic> catData) async {
    print("SYNC_DEBUG: 5.5. 🏷️  Procesando categoría descargada: '${catData['nombre']}'");
    try {
      final categoria = Category.fromMap(catData);
      
      // Verificar si la categoría ya existe por nombre
      final categoriaExistente = await categoryRepository.getCategoryByName(categoria.name);

      if (categoriaExistente == null) {
        print("SYNC_DEBUG: 5.5.1. ➕ Insertando nueva categoría: '${categoria.name}'");
        await categoryRepository.insertCategory(categoria);
      } else {
        // Si existe, la actualizamos para reflejar cambios de color, orden, etc.
        print("SYNC_DEBUG: 5.5.1. 🔄 Actualizando categoría existente: '${categoria.name}'");
        await categoryRepository.updateCategory(categoria.copyWith(id: categoriaExistente.id));
      }
    } catch (e) {
      print("SYNC_DEBUG: 5.5.2. ❌ Error procesando categoría: $e");
    }
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
  // Obtener nombres de categorías en lugar de IDs
  final categoryNames = await categoryRepository.getCategoryNamesByIds(cancion.categoryIds);

  return {
    'id': cancion.id,
    'titulo': cancion.title,
    'autor': cancion.author ?? '',
    'letra_con_acordes': cancion.content,
    'tonalidad_original': cancion.originalKey,
    'tempo_bpm': cancion.tempoBpm ?? 0,
    'posicion_capo': cancion.capoPosition,
    'es_favorita': cancion.isFavorite ? 1 : 0,
    'fecha_creacion': cancion.creationDate.toIso8601String(),
    'fecha_modificacion': cancion.modificationDate.toIso8601String(),
    'notas': cancion.notes ?? '',
    'enlaces_video': cancion.videoLinks != null && cancion.videoLinks!.isNotEmpty 
        ? json.encode(cancion.videoLinks) 
        : '[]',
    'preferred_font_size': cancion.preferredFontSize.toString(),
    'contador_reproducciones': cancion.playCount,
    'categorias': categoryNames, // ← Ahora es un array, no string
    'version': 1,
    'estado': 'activo',
  };
}

  // Método temporal para debuggear qué se está enviando
  void _debugCambiosLocales(List<CambioLocal> cambios) {
    print("SYNC_DEBUG: 📋 CONTENIDO DE LOS CAMBIOS A SUBIR:");
    for (int i = 0; i < cambios.length; i++) {
      final cambio = cambios[i];
      print("SYNC_DEBUG:   Cambio $i - Tipo: ${cambio.tipo}, Tabla: ${cambio.tabla}");
      print("SYNC_DEBUG:   Datos: ${json.encode(cambio.datos)}");
      print("SYNC_DEBUG:   ---");
    }
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

  // Future<void> _procesarSetlistDescargado(Map<String, dynamic> setlistData) async {
  //   // Implementar según tu modelo Setlist
  // }

  // Future<void> _procesarRelacionSetlistCancion(Map<String, dynamic> relacionData) async {
  //   // Implementar según tu modelo
  // }
}