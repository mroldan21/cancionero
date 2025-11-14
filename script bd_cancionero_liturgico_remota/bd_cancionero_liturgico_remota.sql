-- phpMyAdmin SQL Dump
-- version 4.9.5deb2
-- https://www.phpmyadmin.net/
--
-- Servidor: localhost:3306
-- Tiempo de generación: 05-11-2025 a las 10:30:56
-- Versión del servidor: 8.0.42-0ubuntu0.20.04.1
-- Versión de PHP: 7.4.3-4ubuntu2.29

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
SET AUTOCOMMIT = 0;
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Base de datos: `bd_cancionero_liturgico_remota`
--

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `cancion_categoria`
--

CREATE TABLE `cancion_categoria` (
  `id` bigint NOT NULL,
  `cancion_id` bigint NOT NULL,
  `categoria_id` bigint NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `categories`
--

CREATE TABLE `categories` (
  `id` bigint NOT NULL,
  `nombre` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `color` varchar(20) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `orden` int DEFAULT '0',
  `es_predefinida` tinyint(1) DEFAULT '1',
  `fecha_creacion` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `fecha_modificacion` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `configuracion`
--

CREATE TABLE `configuracion` (
  `clave` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL,
  `valor` text COLLATE utf8mb4_unicode_ci NOT NULL,
  `fecha_modificacion` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `dispositivos_sincronizacion`
--

CREATE TABLE `dispositivos_sincronizacion` (
  `id` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `ultima_sincronizacion` timestamp NULL DEFAULT NULL,
  `hash_actual` varchar(64) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `version_app` varchar(50) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `ultima_ip` varchar(45) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `fecha_registro` timestamp NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `logs_sincronizacion`
--

CREATE TABLE `logs_sincronizacion` (
  `id` bigint NOT NULL,
  `dispositivo_id` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `accion` varchar(20) COLLATE utf8mb4_unicode_ci NOT NULL,
  `detalles` json DEFAULT NULL,
  `canciones_descargadas` int DEFAULT '0',
  `canciones_subidas` int DEFAULT '0',
  `fecha_log` timestamp NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `setlists`
--

CREATE TABLE `setlists` (
  `id` bigint NOT NULL,
  `nombre` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `fecha_evento` datetime DEFAULT NULL,
  `notas` text COLLATE utf8mb4_unicode_ci,
  `fecha_creacion` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `fecha_modificacion` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `setlist_cancion`
--

CREATE TABLE `setlist_cancion` (
  `id` bigint NOT NULL,
  `setlist_id` bigint NOT NULL,
  `cancion_id` bigint NOT NULL,
  `orden` int NOT NULL,
  `transposicion_semitonos` int DEFAULT '0',
  `capo_personalizado` int DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `songs`
--

CREATE TABLE `songs` (
  `id` bigint NOT NULL,
  `titulo` varchar(200) COLLATE utf8mb4_unicode_ci NOT NULL,
  `autor` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `letra_con_acordes` text COLLATE utf8mb4_unicode_ci NOT NULL,
  `tonalidad_original` varchar(10) COLLATE utf8mb4_unicode_ci NOT NULL,
  `tempo_bpm` int DEFAULT NULL,
  `posicion_capo` int DEFAULT '0',
  `es_favorita` tinyint(1) DEFAULT '0',
  `preferred_font_size` decimal(4,2) DEFAULT '16.00',
  `contador_reproducciones` int DEFAULT '0',
  `fecha_creacion` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `fecha_modificacion` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `notas` text COLLATE utf8mb4_unicode_ci,
  `enlaces_video` text COLLATE utf8mb4_unicode_ci,
  `activo` tinyint(1) DEFAULT '1',
  `hash_contenido` varchar(64) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `version` int DEFAULT '1'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Índices para tablas volcadas
--

--
-- Indices de la tabla `cancion_categoria`
--
ALTER TABLE `cancion_categoria`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `cancion_id` (`cancion_id`,`categoria_id`),
  ADD KEY `categoria_id` (`categoria_id`);

--
-- Indices de la tabla `categories`
--
ALTER TABLE `categories`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `nombre` (`nombre`);

--
-- Indices de la tabla `configuracion`
--
ALTER TABLE `configuracion`
  ADD PRIMARY KEY (`clave`);

--
-- Indices de la tabla `dispositivos_sincronizacion`
--
ALTER TABLE `dispositivos_sincronizacion`
  ADD PRIMARY KEY (`id`);

--
-- Indices de la tabla `logs_sincronizacion`
--
ALTER TABLE `logs_sincronizacion`
  ADD PRIMARY KEY (`id`);

--
-- Indices de la tabla `setlists`
--
ALTER TABLE `setlists`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `nombre` (`nombre`);

--
-- Indices de la tabla `setlist_cancion`
--
ALTER TABLE `setlist_cancion`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `setlist_id` (`setlist_id`,`orden`),
  ADD KEY `cancion_id` (`cancion_id`);

--
-- Indices de la tabla `songs`
--
ALTER TABLE `songs`
  ADD PRIMARY KEY (`id`);

--
-- AUTO_INCREMENT de las tablas volcadas
--

--
-- AUTO_INCREMENT de la tabla `cancion_categoria`
--
ALTER TABLE `cancion_categoria`
  MODIFY `id` bigint NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT de la tabla `categories`
--
ALTER TABLE `categories`
  MODIFY `id` bigint NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT de la tabla `logs_sincronizacion`
--
ALTER TABLE `logs_sincronizacion`
  MODIFY `id` bigint NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT de la tabla `setlists`
--
ALTER TABLE `setlists`
  MODIFY `id` bigint NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT de la tabla `setlist_cancion`
--
ALTER TABLE `setlist_cancion`
  MODIFY `id` bigint NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT de la tabla `songs`
--
ALTER TABLE `songs`
  MODIFY `id` bigint NOT NULL AUTO_INCREMENT;

--
-- Restricciones para tablas volcadas
--

--
-- Filtros para la tabla `cancion_categoria`
--
ALTER TABLE `cancion_categoria`
  ADD CONSTRAINT `cancion_categoria_ibfk_1` FOREIGN KEY (`cancion_id`) REFERENCES `songs` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `cancion_categoria_ibfk_2` FOREIGN KEY (`categoria_id`) REFERENCES `categories` (`id`) ON DELETE CASCADE;

--
-- Filtros para la tabla `setlist_cancion`
--
ALTER TABLE `setlist_cancion`
  ADD CONSTRAINT `setlist_cancion_ibfk_1` FOREIGN KEY (`setlist_id`) REFERENCES `setlists` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `setlist_cancion_ibfk_2` FOREIGN KEY (`cancion_id`) REFERENCES `songs` (`id`) ON DELETE CASCADE;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
