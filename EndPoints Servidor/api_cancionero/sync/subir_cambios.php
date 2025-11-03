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

    $resultados = [
        'canciones_creadas' => 0,
        'canciones_actualizadas' => 0,
        'canciones_eliminadas' => 0,
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
                    }
                    break;

                case 'eliminar':
                    if ($tabla === 'songs') {
                        $resultado = eliminarCancion($db, $datos);
                        $resultados['canciones_eliminadas']++;
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

// function actualizarCancion($db, $cancion_id, $datos, $hash) {
//     error_log("===== INICIO ACTUALIZAR CANCION ID: $cancion_id =====");
    
//     $query = "UPDATE songs SET
//                 titulo = ?, autor = ?, letra_con_acordes = ?, tonalidad_original = ?,
//                 tempo_bpm = ?, posicion_capo = ?, es_favorita = ?, preferred_font_size = ?,
//                 notas = ?, enlaces_video = ?, hash_contenido = ?, version = version + 1,
//                 fecha_modificacion = CURRENT_TIMESTAMP
//               WHERE id = ?";

//     $stmt = $db->prepare($query);
//     $params = [
//         $datos['titulo'],
//         $datos['autor'] ?? null,
//         $datos['letra_con_acordes'],
//         $datos['tonalidad_original'],
//         $datos['tempo_bpm'] ?? null,
//         $datos['posicion_capo'] ?? 0,
//         $datos['es_favorita'] ?? 0,
//         $datos['preferred_font_size'] ?? 16.0,
//         $datos['notas'] ?? null,
//         $datos['enlaces_video'] ?? null,
//         $hash,
//         $cancion_id
//     ];
    
//     error_log("Query: $query");
//     error_log("Parámetros: " . json_encode($params));
    
//     $result = $stmt->execute($params);
//     $rowCount = $stmt->rowCount();
    
//     error_log("Ejecución exitosa: " . ($result ? 'SÍ' : 'NO'));
//     error_log("Filas afectadas: $rowCount");
    
//     if (!$result) {
//         $errorInfo = $stmt->errorInfo();
//         error_log("Error en actualización: " . json_encode($errorInfo));
//     }

//     // Actualizar categorías si se proporcionan
//     if (isset($datos['categorias']) && !empty($datos['categorias'])) {
//         error_log("Procesando categorías para canción ID: $cancion_id");
        
//         // Eliminar categorías existentes
//         $queryDelete = "DELETE FROM cancion_categoria WHERE cancion_id = ?";
//         $stmtDelete = $db->prepare($queryDelete);
//         $deleteResult = $stmtDelete->execute([$cancion_id]);
//         error_log("Categorías eliminadas: " . ($deleteResult ? 'SÍ' : 'NO'));
        
//         // Insertar nuevas categorías
//         procesarCategoriasCancion($db, $cancion_id, $datos['categorias']);
//     }
    
//     error_log("===== FIN ACTUALIZAR CANCION ID: $cancion_id =====");
//     return $cancion_id;
// }

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
?>