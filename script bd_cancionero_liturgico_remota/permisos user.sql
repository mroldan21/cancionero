-- Crear usuario específico para la aplicación
CREATE USER 'cancionero_user'@'%' IDENTIFIED BY 'Cachifor123$';

-- Otorgar permisos
GRANT SELECT, INSERT, UPDATE, DELETE ON bd_cancionero_liturgico_remota.* TO 'cancionero_user'@'%';
GRANT EXECUTE ON bd_cancionero_liturgico_remota.* TO 'cancionero_user'@'%';

FLUSH PRIVILEGES;