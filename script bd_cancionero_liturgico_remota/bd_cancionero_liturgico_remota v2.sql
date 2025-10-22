-- Crear base de datos
CREATE DATABASE IF NOT EXISTS bd_cancionero_liturgico_remota 
CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

USE bd_cancionero_liturgico_remota;

-- Tabla de Categorías (EXACTA a Flutter)
CREATE TABLE categories (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    nombre VARCHAR(100) NOT NULL UNIQUE,
    color VARCHAR(20),
    orden INT DEFAULT 0,
    es_predefinida TINYINT(1) DEFAULT 1,
    fecha_creacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    fecha_modificacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- Tabla de Canciones (EXACTA a Flutter)
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
    
    -- Campos adicionales SOLO para sync (no en Flutter)
    activo TINYINT(1) DEFAULT 1,
    hash_contenido VARCHAR(64),
    version INT DEFAULT 1
) ENGINE=InnoDB;

-- Tabla de Relación Canciones-Categorías (EXACTA a Flutter)
CREATE TABLE cancion_categoria (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    cancion_id BIGINT NOT NULL,
    categoria_id BIGINT NOT NULL,
    FOREIGN KEY (cancion_id) REFERENCES songs(id) ON DELETE CASCADE,
    FOREIGN KEY (categoria_id) REFERENCES categories(id) ON DELETE CASCADE,
    UNIQUE(cancion_id, categoria_id)
) ENGINE=InnoDB;

-- Tabla de Setlists (EXACTA a Flutter)
CREATE TABLE setlists (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    nombre VARCHAR(100) NOT NULL UNIQUE,
    fecha_evento DATETIME,
    notas TEXT,
    fecha_creacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    fecha_modificacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- Tabla de Relación Setlists-Canciones (EXACTA a Flutter)
CREATE TABLE setlist_cancion (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    setlist_id BIGINT NOT NULL,
    cancion_id BIGINT NOT NULL,
    orden INT NOT NULL,
    transposicion_semitonos INT DEFAULT 0,
    capo_personalizado INT,
    FOREIGN KEY (setlist_id) REFERENCES setlists(id) ON DELETE CASCADE,
    FOREIGN KEY (cancion_id) REFERENCES songs(id) ON DELETE CASCADE,
    UNIQUE(setlist_id, orden)
) ENGINE=InnoDB;

-- Tablas adicionales SOLO para sincronización (no existen en Flutter)

CREATE TABLE configuracion (
    clave VARCHAR(50) PRIMARY KEY,
    valor TEXT NOT NULL,
    fecha_modificacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB;

CREATE TABLE dispositivos_sincronizacion (
    id VARCHAR(100) PRIMARY KEY,
    ultima_sincronizacion TIMESTAMP NULL,
    hash_actual VARCHAR(64),
    version_app VARCHAR(50),
    ultima_ip VARCHAR(45),
    fecha_registro TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

CREATE TABLE logs_sincronizacion (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    dispositivo_id VARCHAR(100) NOT NULL,
    accion VARCHAR(20) NOT NULL,
    detalles JSON,
    canciones_descargadas INT DEFAULT 0,
    canciones_subidas INT DEFAULT 0,
    fecha_log TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;