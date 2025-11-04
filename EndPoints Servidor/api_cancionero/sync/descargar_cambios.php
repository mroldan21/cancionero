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

    ResponseHelper::validateRequired($input, ['dispositivo_id', 'ultima_sincronizacion']);

    $dispositivo_id = $input['dispositivo_id'];
    $ultima_sync = $input['ultima_sincronizacion'];
    $session_id = $input['session_id'] ?? '';

    $database = new Database();
    $db = $database->getConnection();
    $db->exec("SET time_zone = '-03:00'");

    // Obtener canciones modificadas/creadas después de la última sync
    // Consulta CORREGIDA - usando nombres exactos de Flutter
    $query = "SELECT 
                s.id, s.titulo, s.autor, s.letra_con_acordes, s.tonalidad_original,
                s.tempo_bpm, s.posicion_capo, s.es_favorita, s.preferred_font_size,
                s.contador_reproducciones, s.fecha_creacion, s.fecha_modificacion,
                s.notas, s.enlaces_video,
                GROUP_CONCAT(DISTINCT c.nombre) as categorias
            FROM songs s
            LEFT JOIN cancion_categoria cc ON s.id = cc.cancion_id
            LEFT JOIN categories c ON cc.categoria_id = c.id
            WHERE s.fecha_modificacion > ?
            GROUP BY s.id
            ORDER BY s.fecha_modificacion DESC";

    $stmt = $db->prepare($query);
    $stmt->execute([$ultima_sync]);
    $canciones = $stmt->fetchAll();

    // CORRECCIÓN: La lógica de eliminación se maneja en otro endpoint o no se usa.
    // Por ahora, devolvemos un array vacío para mantener la estructura de la respuesta.
    // Si tienes una tabla de 'elementos_eliminados', la consulta iría aquí.
    $eliminadas = [];

    // Obtener setlists modificados
    // CORRECCIÓN: Se elimina la condición 'activo = 1' que no existe.
    $query = "SELECT * FROM setlists 
              WHERE fecha_modificacion > ?";
    $stmt = $db->prepare($query);
    $stmt->execute([$ultima_sync]);
    $setlists = $stmt->fetchAll();

    // CORRECCIÓN: Obtener todas las relaciones para los setlists que han sido modificados.
    // La tabla 'setlist_cancion' no tiene su propio timestamp.
    $query = "SELECT sc.* FROM setlist_cancion sc
              INNER JOIN setlists s ON sc.setlist_id = s.id
              WHERE s.fecha_modificacion > ?";
    $stmt = $db->prepare($query);
    $stmt->execute([$ultima_sync]);
    $setlist_canciones = $stmt->fetchAll();

    // Log de la descarga
    $query = "INSERT INTO logs_sincronizacion 
              (dispositivo_id, accion, detalles, canciones_descargadas) 
              VALUES (?, 'DESCARGA', ?, ?)";
    $stmt = $db->prepare($query);
    $stmt->execute([
        $dispositivo_id,
        json_encode(['session_id' => $session_id]),
        count($canciones)
    ]);

    // Actualizar última sincronización del dispositivo
    $query = "UPDATE dispositivos_sincronizacion 
              SET ultima_sincronizacion = CURRENT_TIMESTAMP 
              WHERE id = ?";
    $stmt = $db->prepare($query);
    $stmt->execute([$dispositivo_id]);

    ResponseHelper::sendSuccess([
        'canciones' => $canciones,
        'canciones_eliminadas' => $eliminadas,
        'setlists' => $setlists,
        'setlist_canciones' => $setlist_canciones,
        'total_cambios' => count($canciones) + count($eliminadas) + count($setlists),
        'timestamp_servidor' => date('c')
    ], "Cambios descargados correctamente");

} catch (Exception $e) {
    error_log("Error en descargar_cambios: " . $e->getMessage());
    ResponseHelper::sendError("Error al descargar cambios: " . $e->getMessage());
}
?>