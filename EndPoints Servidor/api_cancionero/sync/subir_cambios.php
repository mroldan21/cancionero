<?php
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

if ($_SERVER['REQUEST_METHOD'] == 'OPTIONS') {
    exit(0);
}

// --- INICIO: Configuración de Logs ---
$log_dir = __DIR__ . '/../logs';
if (!file_exists($log_dir)) {
    // Intentar crear el directorio con permisos de escritura
    mkdir($log_dir, 0777, true);
}
$log_file = $log_dir . '/sync_uploads.log';
ini_set('log_errors', 1);
ini_set('error_log', $log_file);
// --- FIN: Configuración de Logs ---

require_once '../config/database.php';
require_once '../utils/response_helper.php';

try {
    $input = json_decode(file_get_contents('php://input'), true);
    
    if (!$input) {
        ResponseHelper::sendError("Datos JSON inválidos");
    }

    ResponseHelper::validateRequired($input, ['dispositivo_id', 'cambios']);

    $dispositivo_id = $input['dispositivo_id'];
    $cambios = $input['cambios'];
    $session_id = $input['session_id'] ?? uniqid('sync_', true);

    $database = new Database();
    $db = $database->getConnection();
    $db->exec("SET time_zone = '-03:00'");

    $resultados = [
        'canciones_creadas' => 0,
        'canciones_actualizadas' => 0,
        'canciones_eliminadas' => 0,
        'setlists_creados' => 0,
        'setlists_actualizados' => 0,
        'setlists_eliminados' => 0,
        'errores' => []
    ];

    // Procesar cada cambio
    foreach ($cambios as $cambio) {
        try {
            $tipo = $cambio['tipo']; // 'crear', 'actualizar', 'eliminar'
            $tabla = $cambio['tabla']; // 'songs', 'setlists', etc.
            $datos = $cambio['datos'];

            switch ($tipo) {
                case 'crear':
                case 'actualizar':
                    if ($tabla === 'songs') {
                        $resultado = procesarCancion($db, $datos, $tipo);
                        
                        // Verificar si se creó o actualizó
                        $queryCheck = "SELECT id FROM songs WHERE id = ?";
                        $stmtCheck = $db->prepare($queryCheck);
                        $stmtCheck->execute([$datos['id']]);
                        if ($stmtCheck->fetch()) {
                            if ($tipo === 'crear') {
                                $resultados['canciones_creadas']++;
                                error_log("📊 Contador: Canción creada - ID: {$datos['id']}");
                            } else {
                                $resultados['canciones_actualizadas']++;
                                error_log("📊 Contador: Canción actualizada - ID: {$datos['id']}");
                            }
                        }
                    } elseif ($tabla === 'setlists') {
                        // COMPLETADO: Procesar la subida de setlists
                        $resultado = procesarSetlist($db, $datos, $tipo);
                        if ($tipo === 'crear') {
                            $resultados['setlists_creados']++;
                            error_log("📊 Contador: Setlist creado - ID: {$datos['id']}");
                        } else {
                            $resultados['setlists_actualizados']++;
                            error_log("📊 Contador: Setlist actualizado - ID: {$datos['id']}");
                        }
                    }
                    break;

                case 'eliminar':
                    if ($tabla === 'songs') {
                        $resultado = eliminarCancion($db, $datos);
                        $resultados['canciones_eliminadas']++;
                    } elseif ($tabla === 'setlists') {
                        $resultado = eliminarSetlist($db, $datos);
                        $resultados['setlists_eliminados']++;
                    }
                    break;
            }

        } catch (Exception $e) {
            $resultados['errores'][] = [
                'cambio' => $cambio,
                'error' => $e->getMessage()
            ];
            error_log("Error procesando cambio: " . $e->getMessage());
        }
    }

    // Log de la subida
    $query = "INSERT INTO logs_sincronizacion 
              (dispositivo_id, accion, detalles, canciones_subidas) 
              VALUES (?, 'SUBIDA', ?, ?)";
    $stmt = $db->prepare($query);
    $stmt->execute([
        $dispositivo_id,
        json_encode($resultados),
        $resultados['canciones_creadas'] + $resultados['canciones_actualizadas']
    ]);

    ResponseHelper::sendSuccess($resultados, "Cambios subidos correctamente");

} catch (Exception $e) {
    error_log("Error en subir_cambios: " . $e->getMessage());
    ResponseHelper::sendError("Error al subir cambios: " . $e->getMessage());
}

// Función para procesar canción (crear o actualizar)
// function procesarCancion($db, $datos, $tipo) {
//     // --- INICIO: Logs de depuración solicitados ---
//     error_log("===== INICIO PROCESAR CANCION =====");
//     error_log("Tipo de operación: " . $tipo);
//     error_log("Datos recibidos para canción: " . json_encode($datos));
//     if (isset($datos['categorias'])) {
//         error_log("Tipo de 'categorias': " . gettype($datos['categorias']));
//         if (is_array($datos['categorias'])) {
//             error_log("Valor de 'categorias': " . implode(', ', $datos['categorias']));
//         } else {
//             error_log("Valor de 'categorias': " . $datos['categorias']);
//         }
//     } else {
//         error_log("El campo 'categorias' no está presente en los datos.");
//     }
//     // --- FIN: Logs de depuración ---
//     // Generar hash del contenido
//     $hash = hash('sha256', 
//         $datos['titulo'] . 
//         ($datos['autor'] ?? '') . 
//         $datos['letra_con_acordes'] . 
//         $datos['tonalidad_original'] . 
//         ($datos['tempo_bpm'] ?? 0) . 
//         ($datos['posicion_capo'] ?? 0) . 
//         ($datos['notas'] ?? '')
//     );

//     if ($tipo === 'crear') {
//         // Verificar si ya existe por título y hash
//         $query = "SELECT id FROM songs WHERE titulo = ? AND hash_contenido = ?";
//         $stmt = $db->prepare($query);
//         $stmt->execute([$datos['titulo'], $hash]);
//         $existente = $stmt->fetch();

//         if ($existente) {
//             // Actualizar en lugar de crear
//             return actualizarCancion($db, $existente['id'], $datos, $hash);
//         }

//         // Crear nueva canción
//         $query = "INSERT INTO songs (
//                     titulo, autor, letra_con_acordes, tonalidad_original,
//                     tempo_bpm, posicion_capo, es_favorita, preferred_font_size,
//                     notas, enlaces_video, hash_contenido
//                 ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)";

//         $stmt = $db->prepare($query);
//         $stmt->execute([
//             $datos['titulo'],
//             $datos['autor'] ?? null,
//             $datos['letra_con_acordes'],
//             $datos['tonalidad_original'],
//             $datos['tempo_bpm'] ?? null,
//             $datos['posicion_capo'] ?? 0,
//             $datos['es_favorita'] ?? 0,
//             $datos['preferred_font_size'] ?? 16.0,
//             $datos['notas'] ?? null,
//             $datos['enlaces_video'] ?? null,
//             $hash
//         ]);

//         $cancion_id = $db->lastInsertId();

//         // Procesar categorías si existen
//         if (isset($datos['categorias']) && !empty($datos['categorias'])) {
//         //if (isset($datos['categorias']) && is_array($datos['categorias'])) {
//             procesarCategoriasCancion($db, $cancion_id, $datos['categorias']);
//         }

//         return $cancion_id;

//     } else { // actualizar
//         return actualizarCancion($db, $datos['id'], $datos, $hash);
//     }
// }

function procesarCancion($db, $datos, $tipo) {
    // Generar hash del contenido
    $hash = hash('sha256', 
        $datos['titulo'] . 
        ($datos['autor'] ?? '') . 
        $datos['letra_con_acordes'] . 
        $datos['tonalidad_original'] . 
        ($datos['tempo_bpm'] ?? 0) . 
        ($datos['posicion_capo'] ?? 0) . 
        ($datos['notas'] ?? '')
    );

    // VERIFICAR SI LA CANCIÓN EXISTE EN LA BD
    $queryCheck = "SELECT id FROM songs WHERE id = ?";
    $stmtCheck = $db->prepare($queryCheck);
    $stmtCheck->execute([$datos['id']]);
    $cancionExistente = $stmtCheck->fetch();

    if (!$cancionExistente) {
        // LA CANCIÓN NO EXISTE - CREARLA
        error_log("Canción ID {$datos['id']} no existe. Creándola...");
        return crearCancionConId($db, $datos, $hash);
    } else {
        // LA CANCIÓN EXISTE - ACTUALIZARLA
        error_log("Canción ID {$datos['id']} existe. Actualizándola...");
        return actualizarCancion($db, $datos['id'], $datos, $hash);
    }
}

// NUEVA FUNCIÓN: Crear canción con ID específico
function crearCancionConId($db, $datos, $hash) {
    $query = "INSERT INTO songs (
                id, titulo, autor, letra_con_acordes, tonalidad_original,
                tempo_bpm, posicion_capo, es_favorita, preferred_font_size,
                notas, enlaces_video, hash_contenido, fecha_creacion, fecha_modificacion
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, NOW(), NOW())";

    $stmt = $db->prepare($query);
    $result = $stmt->execute([
        $datos['id'], // Usar el ID que viene de Flutter
        $datos['titulo'],
        $datos['autor'] ?? null,
        $datos['letra_con_acordes'],
        $datos['tonalidad_original'],
        $datos['tempo_bpm'] ?? null,
        $datos['posicion_capo'] ?? 0,
        $datos['es_favorita'] ?? 0,
        $datos['preferred_font_size'] ?? 16.0,
        $datos['notas'] ?? null,
        $datos['enlaces_video'] ?? null,
        $hash
    ]);

    if ($result) {
        $cancion_id = $datos['id']; // Usar el ID que ya conocemos
        
        error_log("✅ Canción creada exitosamente con ID: $cancion_id");

        // Procesar categorías si existen
        if (isset($datos['categorias']) && !empty($datos['categorias'])) {
            procesarCategoriasCancion($db, $cancion_id, $datos['categorias']);
        }

        return $cancion_id;
    } else {
        $errorInfo = $stmt->errorInfo();
        error_log("❌ Error creando canción: " . json_encode($errorInfo));
        throw new Exception("Error al crear canción: " . $errorInfo[2]);
    }
}

// MODIFICAR la función actualizarCancion para mejor logging
function actualizarCancion($db, $cancion_id, $datos, $hash) {
    error_log("===== INICIO ACTUALIZAR CANCION ID: $cancion_id =====");
    
    $query = "UPDATE songs SET
                titulo = ?, autor = ?, letra_con_acordes = ?, tonalidad_original = ?,
                tempo_bpm = ?, posicion_capo = ?, es_favorita = ?, preferred_font_size = ?,
                notas = ?, enlaces_video = ?, hash_contenido = ?, version = version + 1,
                fecha_modificacion = CURRENT_TIMESTAMP
              WHERE id = ?";

    $stmt = $db->prepare($query);
    $params = [
        $datos['titulo'],
        $datos['autor'] ?? null,
        $datos['letra_con_acordes'],
        $datos['tonalidad_original'],
        $datos['tempo_bpm'] ?? null,
        $datos['posicion_capo'] ?? 0,
        $datos['es_favorita'] ?? 0,
        $datos['preferred_font_size'] ?? 16.0,
        $datos['notas'] ?? null,
        $datos['enlaces_video'] ?? null,
        $hash,
        $cancion_id
    ];
    
    $result = $stmt->execute($params);
    $rowCount = $stmt->rowCount();
    
    error_log("Filas afectadas en actualización: $rowCount");
    
    if ($rowCount > 0) {
        error_log("✅ Canción ID $cancion_id actualizada exitosamente");
        
        // Actualizar categorías si se proporcionan
        if (isset($datos['categorias']) && !empty($datos['categorias'])) {
            error_log("Procesando categorías para canción ID: $cancion_id");
            
            // Eliminar categorías existentes
            $queryDelete = "DELETE FROM cancion_categoria WHERE cancion_id = ?";
            $stmtDelete = $db->prepare($queryDelete);
            $deleteResult = $stmtDelete->execute([$cancion_id]);
            error_log("Categorías eliminadas: " . ($deleteResult ? 'SÍ' : 'NO'));
            
            // Insertar nuevas categorías
            procesarCategoriasCancion($db, $cancion_id, $datos['categorias']);
        }
    } else {
        error_log("⚠️  No se actualizó la canción ID $cancion_id (posiblemente no hay cambios)");
    }
    
    error_log("===== FIN ACTUALIZAR CANCION ID: $cancion_id =====");
    return $cancion_id;
}

function procesarCategoriasCancion($db, $cancion_id, $categorias) {
    foreach ($categorias as $categoria_nombre) {
        // Buscar o crear categoría
        $query = "SELECT id FROM categories WHERE nombre = ?";
        $stmt = $db->prepare($query);
        $stmt->execute([$categoria_nombre]);
        $categoria = $stmt->fetch();

        if (!$categoria) {
            // Crear categoría personalizada
            $query = "INSERT INTO categories (nombre, es_predefinida) VALUES (?, 0)";
            $stmt = $db->prepare($query);
            $stmt->execute([$categoria_nombre]);
            $categoria_id = $db->lastInsertId();
        } else {
            $categoria_id = $categoria['id'];
        }

        // Asociar categoría a canción
        $query = "INSERT IGNORE INTO cancion_categoria (cancion_id, categoria_id) VALUES (?, ?)";
        $stmt = $db->prepare($query);
        $stmt->execute([$cancion_id, $categoria_id]);
    }
}

function eliminarCancion($db, $datos) {
    // Marcar como inactiva en lugar de eliminar
    $query = "UPDATE songs SET activo = 0, fecha_modificacion = CURRENT_TIMESTAMP WHERE id = ?";
    $stmt = $db->prepare($query);
    $stmt->execute([$datos['id']]);
    return $stmt->rowCount();
}

// --- INICIO: Funciones para procesar Setlists ---

function procesarSetlist($db, $datos, $tipo) {
    error_log("====== 🎯 INICIO PROCESAR SETLIST ======");
    error_log("📦 Datos COMPLETOS recibidos:");
    error_log(json_encode($datos, JSON_PRETTY_PRINT));
    error_log("🔧 Tipo: $tipo");
    error_log("🆔 Setlist ID: {$datos['id']}");
    error_log("📛 Nombre: {$datos['nombre']}");
    error_log("📅 Fecha creación: {$datos['fecha_creacion']}");
    error_log("📅 Fecha modificación: {$datos['fecha_modificacion']}");
    error_log("🎵 Número de canciones: " . (isset($datos['canciones']) ? count($datos['canciones']) : 0));

    // VERIFICAR SI EL SETLIST EXISTE EN LA BD REMOTA
    $queryCheck = "SELECT id FROM setlists WHERE id = ?";
    $stmtCheck = $db->prepare($queryCheck);
    $stmtCheck->execute([$datos['id']]);
    $setlistExistente = $stmtCheck->fetch();

    error_log($setlistExistente ? "✅ Setlist EXISTE en BD remota" : "❌ Setlist NO EXISTE en BD remota");

    if (!$setlistExistente) {
        // EL SETLIST NO EXISTE - CREARLO
        error_log("Setlist ID {$datos['id']} no existe en BD remota. Creándolo...");
        return crearSetlistConId($db, $datos);
    } else {
        // EL SETLIST EXISTE - ACTUALIZARLO
        error_log("Setlist ID {$datos['id']} existe en BD remota. Actualizándolo...");
        return actualizarSetlist($db, $datos['id'], $datos);
    }
}

// FUNCIÓN MEJORADA: Crear setlist con ID específico
function crearSetlistConId($db, $datos) {
    $query = "INSERT INTO setlists (id, nombre, fecha_evento, notas, fecha_creacion, fecha_modificacion) 
              VALUES (?, ?, ?, ?, ?, ?)";
    $stmt = $db->prepare($query);
    $result = $stmt->execute([
        $datos['id'], // Usar el ID que viene de Flutter
        $datos['nombre'],
        $datos['fecha_evento'] ?? null,
        $datos['notas'] ?? null,
        $datos['fecha_creacion'],
        $datos['fecha_modificacion']
    ]);

    if ($result) {
        $setlist_id = $datos['id'];
        error_log("✅ Setlist creado exitosamente con ID: $setlist_id");

        // Procesar canciones del setlist
        procesarCancionesSetlist($db, $setlist_id, $datos['canciones'] ?? []);
        
        return $setlist_id;
    } else {
        $errorInfo = $stmt->errorInfo();
        error_log("❌ Error creando setlist: " . json_encode($errorInfo));
        throw new Exception("Error al crear setlist: " . $errorInfo[2]);
    }
}

// FUNCIÓN MEJORADA: Actualizar setlist existente
function actualizarSetlist($db, $setlist_id, $datos) {
    $query = "UPDATE setlists SET 
                nombre = ?, fecha_evento = ?, notas = ?, fecha_modificacion = ?
              WHERE id = ?";
    $stmt = $db->prepare($query);
    $result = $stmt->execute([
        $datos['nombre'],
        $datos['fecha_evento'] ?? null,
        $datos['notas'] ?? null,
        $datos['fecha_modificacion'],
        $setlist_id
    ]);

    if ($result) {
        $rowCount = $stmt->rowCount();
        if ($rowCount > 0) {
            error_log("✅ Setlist ID $setlist_id actualizado exitosamente (filas afectadas: $rowCount)");
        } else {
            error_log("⚠️  Setlist ID $setlist_id no se actualizó (posiblemente sin cambios)");
        }
        
        // Procesar canciones del setlist (siempre actualizar las relaciones)
        procesarCancionesSetlist($db, $setlist_id, $datos['canciones'] ?? []);
        
    } else {
        $errorInfo = $stmt->errorInfo();
        error_log("❌ Error actualizando setlist: " . json_encode($errorInfo));
        throw new Exception("Error al actualizar setlist: " . $errorInfo[2]);
    }

    return $setlist_id;
}

// FUNCIÓN MEJORADA: Procesar canciones del setlist
function procesarCancionesSetlist($db, $setlist_id, $canciones) {
    error_log("🔄 Procesando " . count($canciones) . " canciones para setlist ID: $setlist_id");
    
    // DEBUG: Log detallado de cada canción recibida
    foreach ($canciones as $index => $cancionItem) {
        error_log("🎵 Canción $index: " . json_encode($cancionItem));
    }

    if (empty($canciones)) {
        error_log("ℹ️  No hay canciones para procesar en setlist ID: $setlist_id");
        return;
    }

    // 1. Borramos las asociaciones existentes
    $queryDelete = "DELETE FROM setlist_cancion WHERE setlist_id = ?";
    $stmtDelete = $db->prepare($queryDelete);
    $deleteResult = $stmtDelete->execute([$setlist_id]);
    $deletedRows = $stmtDelete->rowCount();
    error_log("🗑️  Relaciones antiguas eliminadas: $deletedRows filas");

    // 2. Insertamos las nuevas asociaciones
    $queryInsert = "INSERT INTO setlist_cancion 
                    (setlist_id, cancion_id, orden, transposicion_semitonos, capo_personalizado) 
                    VALUES (?, ?, ?, ?, ?)";
    $stmtInsert = $db->prepare($queryInsert);

    $insertCount = 0;
    $errors = 0;
    
    foreach ($canciones as $index => $cancionItem) {
        try {
            // Validación más estricta
            if (!isset($cancionItem['cancion_id']) || !isset($cancionItem['orden'])) {
                error_log("❌ Canción en índice $index falta datos requeridos: " . json_encode($cancionItem));
                $errors++;
                continue;
            }
            
            // Validar que cancion_id sea numérico y mayor a 0
            $cancion_id = $cancionItem['cancion_id'];
            if (!is_numeric($cancion_id) || $cancion_id <= 0) {
                error_log("❌ Canción ID inválido en índice $index: $cancion_id");
                $errors++;
                continue;
            }
            
            $result = $stmtInsert->execute([
                $setlist_id,
                $cancion_id,
                $cancionItem['orden'],
                $cancionItem['transposicion_semitonos'] ?? 0,
                $cancionItem['capo_personalizado'] ?? null
            ]);
            
            if ($result) {
                $insertCount++;
                error_log("✅ Canción $cancion_id insertada correctamente (orden: {$cancionItem['orden']})");
            } else {
                $errorInfo = $stmtInsert->errorInfo();
                error_log("❌ Error insertando canción $cancion_id: " . json_encode($errorInfo));
                $errors++;
            }
            
        } catch (Exception $e) {
            error_log("❌ Excepción insertando canción {$cancionItem['cancion_id']}: " . $e->getMessage());
            $errors++;
        }
    }
    
    error_log("🎯 RESUMEN Setlist $setlist_id: $insertCount insertadas, $errors errores de " . count($canciones) . " canciones");
}

// FUNCIÓN ELIMINAR SETLIST (MANTENER ESTA FUNCIÓN)
// SOLUCIÓN: Modificar para usar una transacción y asegurar el borrado de asociaciones.
function eliminarSetlist($db, $datos) {
    error_log("===== ELIMINANDO SETLIST ID: {$datos['id']} =====");
    $setlist_id = $datos['id'];

    try {
        $db->beginTransaction();

        // 1. Eliminar las asociaciones en la tabla 'setlist_cancion'
        $query_relaciones = "DELETE FROM setlist_cancion WHERE setlist_id = ?";
        $stmt_relaciones = $db->prepare($query_relaciones);
        $stmt_relaciones->execute([$setlist_id]);
        $relaciones_eliminadas = $stmt_relaciones->rowCount();
        error_log("🗑️  Relaciones eliminadas para setlist ID $setlist_id: $relaciones_eliminadas filas");

        // 2. Eliminar el setlist principal de la tabla 'setlists'
        $query_setlist = "DELETE FROM setlists WHERE id = ?";
        $stmt_setlist = $db->prepare($query_setlist);
        $stmt_setlist->execute([$setlist_id]);
        $setlist_eliminado_count = $stmt_setlist->rowCount();

        $db->commit();
        error_log("✅ Transacción completada. Setlist ID $setlist_id eliminado.");

        return $setlist_eliminado_count;

    } catch (Exception $e) {
        $db->rollBack();
        error_log("❌ ERROR al eliminar setlist ID $setlist_id. Transacción revertida. Error: " . $e->getMessage());
        throw $e; // Relanzar la excepción para que el manejador principal la capture.
    }
}

// --- FIN: Funciones para procesar Setlists ---
?>