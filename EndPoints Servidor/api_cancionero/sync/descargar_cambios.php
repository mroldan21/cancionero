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

    // Obtener canciones modificadas/creadas después de la última sync
    $query = "SELECT 
                s.*,
                GROUP_CONCAT(DISTINCT c.nombre) as categorias
              FROM songs s
              LEFT JOIN cancion_categoria cc ON s.id = cc.cancion_id
              LEFT JOIN categories c ON cc.categoria_id = c.id
              WHERE s.activo = 1 
                AND s.fecha_modificacion > ?
              GROUP BY s.id
              ORDER BY s.fecha_modificacion DESC";

    $stmt = $db->prepare($query);
    $stmt->execute([$ultima_sync]);
    $canciones = $stmt->fetchAll();

    // Obtener IDs de canciones eliminadas (marcadas como inactivas)
    $query = "SELECT id FROM songs 
              WHERE activo = 0 AND fecha_modificacion > ?";
    $stmt = $db->prepare($query);
    $stmt->execute([$ultima_sync]);
    $eliminadas = $stmt->fetchAll(PDO::FETCH_COLUMN, 0);

    // Obtener setlists modificados
    $query = "SELECT * FROM setlists 
              WHERE activo = 1 AND fecha_modificacion > ?";
    $stmt = $db->prepare($query);
    $stmt->execute([$ultima_sync]);
    $setlists = $stmt->fetchAll();

    // Obtener relaciones setlist-canción modificadas
    $query = "SELECT sc.* FROM setlist_cancion sc
              INNER JOIN setlists s ON sc.setlist_id = s.id
              WHERE s.activo = 1 AND sc.fecha_creacion > ?";
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