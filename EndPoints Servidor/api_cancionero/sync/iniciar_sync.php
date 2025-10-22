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

    ResponseHelper::validateRequired($input, ['dispositivo_id']);

    $dispositivo_id = $input['dispositivo_id'];
    $hash_local = $input['hash_local'] ?? '';
    $version_app = $input['version_app'] ?? '1.0.0';

    $database = new Database();
    $db = $database->getConnection();

    // Registrar inicio de sincronización
    $query = "INSERT INTO dispositivos_sincronizacion 
              (id, ultima_sincronizacion, hash_actual, version_app, ultima_ip) 
              VALUES (?, NULL, ?, ?, ?)
              ON DUPLICATE KEY UPDATE 
              hash_actual = VALUES(hash_actual),
              version_app = VALUES(version_app),
              ultima_ip = VALUES(ultima_ip)";

    $stmt = $db->prepare($query);
    $stmt->execute([
        $dispositivo_id,
        $hash_local,
        $version_app,
        $_SERVER['REMOTE_ADDR']
    ]);

    // Obtener información del servidor
    $query = "SELECT valor as ultima_actualizacion 
              FROM configuracion 
              WHERE clave = 'ultima_actualizacion'";
    $stmt = $db->prepare($query);
    $stmt->execute();
    $server_info = $stmt->fetch();

    // Obtener estadísticas
    $query = "SELECT 
                COUNT(*) as total_canciones,
                COUNT(DISTINCT categoria_id) as total_categorias,
                COUNT(DISTINCT setlist_id) as total_setlists
              FROM songs s
              LEFT JOIN cancion_categoria cc ON s.id = cc.cancion_id
              LEFT JOIN setlist_cancion sc ON s.id = sc.cancion_id
              WHERE s.activo = 1";
    $stmt = $db->prepare($query);
    $stmt->execute();
    $stats = $stmt->fetch();

    ResponseHelper::sendSuccess([
        'session_id' => uniqid('sync_', true),
        'ultima_actualizacion_servidor' => $server_info['ultima_actualizacion'],
        'estadisticas_servidor' => $stats,
        'timestamp' => date('c')
    ], "Sincronización iniciada correctamente");

} catch (Exception $e) {
    error_log("Error en iniciar_sync: " . $e->getMessage());
    ResponseHelper::sendError("Error al iniciar sincronización: " . $e->getMessage());
}
?>