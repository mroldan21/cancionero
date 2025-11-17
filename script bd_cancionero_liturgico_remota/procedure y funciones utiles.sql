DELIMITER //

-- Función para generar hash de contenido de canción
CREATE FUNCTION fn_generar_hash_contenido(
    p_titulo VARCHAR(200),
    p_autor VARCHAR(100),
    p_letra TEXT,
    p_tonalidad VARCHAR(10),
    p_tempo INT,
    p_capo INT,
    p_notas TEXT
) RETURNS VARCHAR(64) DETERMINISTIC
BEGIN
    RETURN SHA2(CONCAT(
        COALESCE(p_titulo, ''),
        COALESCE(p_autor, ''),
        COALESCE(p_letra, ''),
        COALESCE(p_tonalidad, ''),
        COALESCE(p_tempo, 0),
        COALESCE(p_capo, 0),
        COALESCE(p_notas, '')
    ), 256);
END //

-- Procedure para obtener cambios para sincronización
CREATE PROCEDURE sp_obtener_cambios_canciones(
    IN p_desde_fecha TIMESTAMP,
    IN p_dispositivo_id VARCHAR(100)
)
BEGIN
    -- Obtener canciones nuevas o modificadas
    SELECT 
        s.id,
        s.titulo,
        s.autor,
        s.letra_con_acordes,
        s.tonalidad_original,
        s.tempo_bpm,
        s.posicion_capo,
        s.es_favorita,
        s.preferred_font_size,
        s.notas,
        s.enlaces_video,
        s.fecha_creacion,
        s.fecha_modificacion,
        s.hash_contenido,
        s.version,
        GROUP_CONCAT(DISTINCT c.nombre) as categorias
    FROM songs s
    LEFT JOIN cancion_categoria cc ON s.id = cc.cancion_id
    LEFT JOIN categories c ON cc.categoria_id = c.id
    WHERE s.activo = 1 
      AND s.fecha_modificacion > p_desde_fecha
    GROUP BY s.id
    ORDER BY s.fecha_modificacion DESC;
    
    -- Actualizar registro del dispositivo
    INSERT INTO dispositivos_sincronizacion 
    (id, ultima_sincronizacion, ultima_ip)
    VALUES (p_dispositivo_id, NOW(), @remote_ip)
    ON DUPLICATE KEY UPDATE 
    ultima_sincronizacion = NOW(), 
    ultima_ip = @remote_ip;
    
    -- Log de la sincronización
    INSERT INTO logs_sincronizacion 
    (dispositivo_id, accion, detalles)
    VALUES (p_dispositivo_id, 'DESCARGA', 
        JSON_OBJECT('desde_fecha', p_desde_fecha));
END //

-- Procedure para insertar/actualizar canción
CREATE PROCEDURE sp_upsert_cancion(
    IN p_titulo VARCHAR(200),
    IN p_autor VARCHAR(100),
    IN p_letra_con_acordes TEXT,
    IN p_tonalidad_original VARCHAR(10),
    IN p_tempo_bpm INT,
    IN p_posicion_capo INT,
    IN p_notas TEXT,
    IN p_enlaces_video TEXT,
    IN p_categorias_json JSON
)
BEGIN
    DECLARE v_cancion_id BIGINT;
    DECLARE v_hash_actual VARCHAR(64);
    DECLARE v_categoria_nombre VARCHAR(100);
    DECLARE v_categoria_id BIGINT;
    DECLARE i INT DEFAULT 0;
    
    -- Generar hash del contenido
    SET v_hash_actual = fn_generar_hash_contenido(
        p_titulo, p_autor, p_letra_con_acordes,
        p_tonalidad_original, p_tempo_bpm, 
        p_posicion_capo, p_notas
    );
    
    -- Buscar si ya existe la canción (por título y hash)
    SELECT id INTO v_cancion_id 
    FROM songs 
    WHERE titulo = p_titulo AND hash_contenido = v_hash_actual
    LIMIT 1;
    
    IF v_cancion_id IS NULL THEN
        -- Insertar nueva canción
        INSERT INTO songs (
            titulo, autor, letra_con_acordes, tonalidad_original,
            tempo_bpm, posicion_capo, notas, enlaces_video, hash_contenido
        ) VALUES (
            p_titulo, p_autor, p_letra_con_acordes, p_tonalidad_original,
            p_tempo_bpm, p_posicion_capo, p_notas, p_enlaces_video, v_hash_actual
        );
        
        SET v_cancion_id = LAST_INSERT_ID();
    ELSE
        -- Actualizar canción existente
        UPDATE songs SET
            autor = p_autor,
            letra_con_acordes = p_letra_con_acordes,
            tonalidad_original = p_tonalidad_original,
            tempo_bpm = p_tempo_bpm,
            posicion_capo = p_posicion_capo,
            notas = p_notas,
            enlaces_video = p_enlaces_video,
            fecha_modificacion = NOW(),
            version = version + 1
        WHERE id = v_cancion_id;
        
        -- Limpiar categorías anteriores
        DELETE FROM cancion_categoria WHERE cancion_id = v_cancion_id;
    END IF;
    
    -- Procesar categorías
    WHILE i < JSON_LENGTH(p_categorias_json) DO
        SET v_categoria_nombre = JSON_UNQUOTE(
            JSON_EXTRACT(p_categorias_json, CONCAT('$[', i, ']'))
        );
        
        -- Buscar ID de la categoría
        SELECT id INTO v_categoria_id 
        FROM categories 
        WHERE nombre = v_categoria_nombre 
        LIMIT 1;
        
        -- Si la categoría no existe, crearla
        IF v_categoria_id IS NULL THEN
            INSERT INTO categories (nombre, es_predefinida)
            VALUES (v_categoria_nombre, 0);
            SET v_categoria_id = LAST_INSERT_ID();
        END IF;
        
        -- Asociar categoría a la canción
        INSERT IGNORE INTO cancion_categoria (cancion_id, categoria_id)
        VALUES (v_cancion_id, v_categoria_id);
        
        SET i = i + 1;
    END WHILE;
    
    SELECT v_cancion_id as id;
END //

DELIMITER ;