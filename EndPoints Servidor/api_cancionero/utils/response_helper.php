<?php
class ResponseHelper {
    public static function sendSuccess($data = null, $message = "Success") {
        header('Content-Type: application/json');
        http_response_code(200);
        echo json_encode([
            'success' => true,
            'message' => $message,
            'data' => $data,
            'timestamp' => date('c')
        ]);
        exit;
    }

    public static function sendError($message = "Error", $code = 400, $details = null) {
        header('Content-Type: application/json');
        http_response_code($code);
        echo json_encode([
            'success' => false,
            'message' => $message,
            'details' => $details,
            'timestamp' => date('c')
        ]);
        exit;
    }

    public static function validateRequired($data, $requiredFields) {
        $missing = [];
        foreach ($requiredFields as $field) {
            if (!isset($data[$field]) || empty($data[$field])) {
                $missing[] = $field;
            }
        }
        if (!empty($missing)) {
            self::sendError("Campos requeridos faltantes: " . implode(', ', $missing));
        }
    }
}
?>