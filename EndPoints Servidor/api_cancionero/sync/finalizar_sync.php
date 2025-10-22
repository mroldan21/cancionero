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
    $session_id = $input['session_id'] ?? '';
    $estado = $input['estado'] ?? 'completado'; // 'completado', 'cancelado', 'error'
    $detalles = $input['detalles'] ?? [];

    $database = new Database();
    $db = $database->getConnection();

    // Log del final de sincronización
    $query = "INSERT INTO logs_sincronizacion 
              (dispositivo_id, accion, detalles) 
              VALUES (?, 'FINALIZACION', ?)";
    $stmt = $db->prepare($query);
    $stmt->execute([
        $dispositivo_id,
        json_encode([
            'session_id' => $session_id,
            'estado' => $estado,
            'detalles' => $detalles,
            'timestamp' => date('c')
        ])
    ]);

    // Actualizar configuración de última actualización global si la sync fue exitosa
    if ($estado === 'completado') {
        $query = "UPDATE configuracion 
                  SET valor = ?, fecha_modificacion = CURRENT_TIMESTAMP 
                  WHERE clave = 'ultima_actualizacion'";
        $stmt = $db->prepare($query);
        $stmt->execute([date('c')]);
    }

    ResponseHelper::sendSuccess([
        'session_id' => $session_id,
        'estado' => $estado,
        'timestamp_finalizacion' => date('c')
    ], "Sincronización finalizada correctamente");

} catch (Exception $e) {
    error_log("Error en finalizar_sync: " . $e->getMessage());
    ResponseHelper::sendError("Error al finalizar sincronización: " . $e->getMessage());
}
?>