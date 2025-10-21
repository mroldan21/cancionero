-- Insertar categorías predefinidas
INSERT INTO categories (nombre, color, orden, es_predefinida) VALUES
('Entrada', '#4CAF50', 1, 1),
('Meditación', '#2196F3', 2, 1),
('Virgen María', '#E91E63', 3, 1),
('Comunión', '#FFC107', 4, 1),
('Ofertorio', '#FF9800', 5, 1),
('Salida', '#9C27B0', 6, 1),
('Adoración', '#FF5722', 7, 1),
('Penitencial', '#795548', 8, 1),
('Aleluya', '#FFEB3B', 9, 1),
('Canciones Mías', '#607D8B', 10, 0);

-- Insertar configuración inicial
INSERT INTO configuracion (clave, valor, descripcion) VALUES
('version_esquema', '1.0', 'Versión del esquema de base de datos'),
('ultima_actualizacion', NOW(), 'Fecha de última actualización global'),
('url_servidor', 'https://tudominio.com/api', 'URL base del servidor API'),
('sync_automatica', '1', 'Habilitar sincronización automática'),
('tamanio_fuente_default', '16.0', 'Tamaño de fuente predeterminado');