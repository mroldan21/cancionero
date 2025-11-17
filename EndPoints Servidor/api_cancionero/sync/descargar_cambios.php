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
    // FILTRAR: Solo canciones aprobadas y activas
    $query = "SELECT 
                s.id, s.titulo, s.autor, s.letra_con_acordes, s.tonalidad_original,
                s.tempo_bpm, s.posicion_capo, s.es_favorita, s.preferred_font_size,
                s.contador_reproducciones, s.fecha_creacion, s.fecha_modificacion,
                s.notas, s.enlaces_video, s.activo, s.estado, s.fuente, s.hash_contenido, s.version,
                GROUP_CONCAT(DISTINCT c.nombre) as categorias
            FROM songs s
            LEFT JOIN cancion_categoria cc ON s.id = cc.cancion_id
            LEFT JOIN categories c ON cc.categoria_id = c.id
            WHERE s.fecha_modificacion > ?
              AND s.estado = 'aprobado'
              -- AND s.activo = 1
            GROUP BY s.id
            ORDER BY s.fecha_modificacion DESC";

    $stmt = $db->prepare($query);
    $stmt->execute([$ultima_sync]);
    $canciones = $stmt->fetchAll();

    // CORRECCIÓN: La lógica de eliminación se maneja en otro endpoint o no se usa.
    // Por ahora, devolvemos un array vacío para mantener la estructura de la respuesta.
    // Si tienes una tabla de 'elementos_eliminados', la consulta iría aquí.
    $eliminadas = [];
    
    // --- INICIO: LÓGICA MEJORADA PARA SETLISTS ---
    // 1. Obtener los setlists modificados
    $query = "SELECT id, nombre, fecha_evento, notas, fecha_creacion, fecha_modificacion 
            FROM setlists WHERE fecha_modificacion > ?";
    $stmt = $db->prepare($query);
    $stmt->execute([$ultima_sync]);
    $setlists_modificados = $stmt->fetchAll(PDO::FETCH_ASSOC);

    // 2. Obtener TODAS las relaciones setlist-canciones modificadas
    $query_relaciones = "SELECT setlist_id, cancion_id, orden, transposicion_semitonos, capo_personalizado 
                        FROM setlist_cancion ";
    $stmt_relaciones = $db->prepare($query_relaciones);
    $stmt_relaciones->execute();
    $setlist_canciones = $stmt_relaciones->fetchAll(PDO::FETCH_ASSOC);
    // --- FIN: LÓGICA MEJORADA PARA SETLISTS ---

    // --- INICIO: LÓGICA PARA CATEGORÍAS ---
    // Obtener todas las categorías modificadas o creadas después de la última sync.
    // Asumimos que la tabla 'categories' tiene un campo 'fecha_modificacion'. Si no, hay que añadirlo.
    // Por ahora, descargaremos todas las que no son predefinidas para asegurar consistencia.
    $query_categorias = "SELECT id, nombre, color, orden, es_predefinida FROM categories WHERE fecha_modificacion > ?";
    $stmt_categorias = $db->prepare($query_categorias);
    $stmt_categorias->execute([$ultima_sync]);
    $categorias = $stmt_categorias->fetchAll(PDO::FETCH_ASSOC);
    // --- FIN: LÓGICA PARA CATEGORÍAS ---

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
        'setlists' => $setlists_modificados, // Solo datos del setlist, sin canciones anidadas
        'setlist_canciones' => $setlist_canciones, // Relaciones por separado
        'categorias' => $categorias, // Devolver las categorías
        'total_cambios' => count($canciones) + count($eliminadas) + count($setlists_modificados) + count($setlist_canciones) + count($categorias),
        'timestamp_servidor' => date('c')
    ], "Cambios descargados correctamente");

} catch (Exception $e) {
    error_log("Error en descargar_cambios: " . $e->getMessage());
    ResponseHelper::sendError("Error al descargar cambios: " . $e->getMessage());
}
?>