-- Vista para estadísticas
CREATE VIEW vw_estadisticas_canciones AS
SELECT 
    COUNT(*) as total_canciones,
    SUM(es_favorita) as total_favoritas,
    AVG(tempo_bpm) as tempo_promedio,
    COUNT(DISTINCT tonalidad_original) as tonalidades_diferentes,
    MAX(fecha_modificacion) as ultima_actualizacion
FROM songs 
WHERE activo = 1;

-- Vista para reporte de uso
CREATE VIEW vw_reporte_uso AS
SELECT 
    ds.id as dispositivo_id,
    ds.ultima_sincronizacion,
    ds.version_app,
    COUNT(ls.id) as total_sincronizaciones,
    MAX(ls.fecha_log) as ultima_actividad
FROM dispositivos_sincronizacion ds
LEFT JOIN logs_sincronizacion ls ON ds.id = ls.dispositivo_id
GROUP BY ds.id, ds.ultima_sincronizacion, ds.version_app;