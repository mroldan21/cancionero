-- Crear base de datos
CREATE DATABASE IF NOT EXISTS USE bd_cancionero_liturgico_remota;
 
CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

USE bd_cancionero_liturgico_remota;

-- Tabla de Categorías
CREATE TABLE categories (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    nombre VARCHAR(100) NOT NULL UNIQUE,
    color VARCHAR(20),
    orden INT DEFAULT 0,
    es_predefinida TINYINT(1) DEFAULT 1,
    fecha_creacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    fecha_modificacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    INDEX idx_nombre (nombre),
    INDEX idx_orden (orden),
    INDEX idx_predefinida (es_predefinida)
) ENGINE=InnoDB;

-- Tabla de Canciones
CREATE TABLE songs (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    titulo VARCHAR(200) NOT NULL,
    autor VARCHAR(100),
    letra_con_acordes TEXT NOT NULL,
    tonalidad_original VARCHAR(10) NOT NULL,
    tempo_bpm INT,
    posicion_capo INT DEFAULT 0,
    es_favorita TINYINT(1) DEFAULT 0,
    preferred_font_size DECIMAL(4,2) DEFAULT 16.00,
    contador_reproducciones INT DEFAULT 0,
    fecha_creacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    fecha_modificacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    notas TEXT,
    enlaces_video TEXT,
    activo TINYINT(1) DEFAULT 1,
    
    -- Campos para sync y control
    hash_contenido VARCHAR(64),
    version INT DEFAULT 1,
    fuente_original ENUM('MANUAL', 'WORD_IMPORT', 'OCR_IMAGE', 'WEBSITE', 'AUDIO') DEFAULT 'MANUAL',
    estado_procesamiento ENUM('PENDIENTE', 'PROCESANDO', 'FALLO', 'FINALIZADO') DEFAULT 'FINALIZADO',
    confidence_score FLOAT DEFAULT 1.0,
    
    INDEX idx_titulo (titulo),
    INDEX idx_favoritas (es_favorita),
    INDEX idx_fecha_modificacion (fecha_modificacion),
    INDEX idx_activo (activo),
    INDEX idx_fuente (fuente_original),
    INDEX idx_hash (hash_contenido),
    FULLTEXT idx_busqueda (titulo, autor, letra_con_acordes, notas)
) ENGINE=InnoDB;

-- Tabla de Relación Muchos a Muchos: Canciones y Categorías
CREATE TABLE cancion_categoria (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    cancion_id BIGINT NOT NULL,
    categoria_id BIGINT NOT NULL,
    fecha_asociacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (cancion_id) REFERENCES songs(id) ON DELETE CASCADE,
    FOREIGN KEY (categoria_id) REFERENCES categories(id) ON DELETE CASCADE,
    UNIQUE KEY uk_cancion_categoria (cancion_id, categoria_id),
    
    INDEX idx_cancion (cancion_id),
    INDEX idx_categoria (categoria_id)
) ENGINE=InnoDB;

-- Tabla de Setlists
CREATE TABLE setlists (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    nombre VARCHAR(100) NOT NULL UNIQUE,
    fecha_evento DATETIME,
    notas TEXT,
    fecha_creacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    fecha_modificacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    activo TINYINT(1) DEFAULT 1,
    
    INDEX idx_nombre (nombre),
    INDEX idx_fecha_evento (fecha_evento),
    INDEX idx_activo (activo)
) ENGINE=InnoDB;

-- Tabla de Relación con Configuración: Canciones en Setlists
CREATE TABLE setlist_cancion (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    setlist_id BIGINT NOT NULL,
    cancion_id BIGINT NOT NULL,
    orden INT NOT NULL,
    transposicion_semitonos INT DEFAULT 0,
    capo_personalizado INT,
    fecha_creacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (setlist_id) REFERENCES setlists(id) ON DELETE CASCADE,
    FOREIGN KEY (cancion_id) REFERENCES songs(id) ON DELETE CASCADE,
    UNIQUE KEY uk_setlist_orden (setlist_id, orden),
    
    INDEX idx_setlist (setlist_id),
    INDEX idx_orden (setlist_id, orden),
    INDEX idx_cancion (cancion_id)
) ENGINE=InnoDB;

-- Tabla de Configuración (Key-Value)
CREATE TABLE configuracion (
    clave VARCHAR(50) PRIMARY KEY,
    valor TEXT NOT NULL,
    fecha_modificacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    descripcion TEXT,
    
    INDEX idx_clave (clave)
) ENGINE=InnoDB;

-- Tabla para control de sincronización de dispositivos
CREATE TABLE dispositivos_sincronizacion (
    id VARCHAR(100) PRIMARY KEY, -- device_id de Flutter
    ultima_sincronizacion TIMESTAMP NULL,
    hash_actual VARCHAR(64),
    version_app VARCHAR(50),
    ultima_ip VARCHAR(45),
    sistema_operativo VARCHAR(50),
    fecha_registro TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    INDEX idx_ultima_sync (ultima_sincronizacion),
    INDEX idx_version (version_app)
) ENGINE=InnoDB;

-- Tabla para logs de sincronización
CREATE TABLE logs_sincronizacion (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    dispositivo_id VARCHAR(100) NOT NULL,
    accion ENUM('DESCARGA', 'SUBIDA', 'ERROR', 'INICIO') NOT NULL,
    detalles JSON,
    canciones_descargadas INT DEFAULT 0,
    canciones_subidas INT DEFAULT 0,
    fecha_log TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    INDEX idx_dispositivo (dispositivo_id),
    INDEX idx_fecha (fecha_log),
    INDEX idx_accion (accion)
) ENGINE=InnoDB;

-- Tabla para archivos multimedia (futura expansión)
CREATE TABLE archivos_multimedia (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    cancion_id BIGINT NOT NULL,
    tipo_archivo ENUM('DOCX', 'IMAGE', 'AUDIO', 'VIDEO', 'PDF') NOT NULL,
    nombre_archivo VARCHAR(255) NOT NULL,
    ruta_almacenamiento VARCHAR(500),
    tamano_bytes BIGINT,
    mime_type VARCHAR(100),
    fecha_subida TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (cancion_id) REFERENCES songs(id) ON DELETE CASCADE,
    
    INDEX idx_cancion (cancion_id),
    INDEX idx_tipo (tipo_archivo)
) ENGINE=InnoDB;