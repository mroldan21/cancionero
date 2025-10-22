<?php
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

if ($_SERVER['REQUEST_METHOD'] == 'OPTIONS') {
    exit(0);
}

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
                        if ($tipo === 'crear') $resultados['canciones_creadas']++;
                        else $resultados['canciones_actualizadas']++;
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

    if ($tipo === 'crear') {
        // Verificar si ya existe por título y hash
        $query = "SELECT id FROM songs WHERE titulo = ? AND hash_contenido = ?";
        $stmt = $db->prepare($query);
        $stmt->execute([$datos['titulo'], $hash]);
        $existente = $stmt->fetch();

        if ($existente) {
            // Actualizar en lugar de crear
            return actualizarCancion($db, $existente['id'], $datos, $hash);
        }

        // Crear nueva canción
        $query = "INSERT INTO songs (
                    titulo, autor, letra_con_acordes, tonalidad_original,
                    tempo_bpm, posicion_capo, es_favorita, preferred_font_size,
                    notas, enlaces_video, hash_contenido
                ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)";

        $stmt = $db->prepare($query);
        $stmt->execute([
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

        $cancion_id = $db->lastInsertId();

        // Procesar categorías si existen
        if (isset($datos['categorias']) && is_array($datos['categorias'])) {
            procesarCategoriasCancion($db, $cancion_id, $datos['categorias']);
        }

        return $cancion_id;

    } else { // actualizar
        return actualizarCancion($db, $datos['id'], $datos, $hash);
    }
}

function actualizarCancion($db, $cancion_id, $datos, $hash) {
    $query = "UPDATE songs SET
                titulo = ?, autor = ?, letra_con_acordes = ?, tonalidad_original = ?,
                tempo_bpm = ?, posicion_capo = ?, es_favorita = ?, preferred_font_size = ?,
                notas = ?, enlaces_video = ?, hash_contenido = ?, version = version + 1,
                fecha_modificacion = CURRENT_TIMESTAMP
              WHERE id = ?";

    $stmt = $db->prepare($query);
    $stmt->execute([
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
    ]);

    // Actualizar categorías si se proporcionan
    if (isset($datos['categorias']) && is_array($datos['categorias'])) {
        // Eliminar categorías existentes
        $query = "DELETE FROM cancion_categoria WHERE cancion_id = ?";
        $stmt = $db->prepare($query);
        $stmt->execute([$cancion_id]);

        // Insertar nuevas categorías
        procesarCategoriasCancion($db, $cancion_id, $datos['categorias']);
    }

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
?>