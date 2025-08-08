-- Script de Diagnóstico de Deadlocks MySQL
-- Escenario: TechStore E-commerce
-- Uso: mysql -u root -p < deadlock-diagnostic.sql

-- =====================================================
-- 1. INFORMACIÓN GENERAL DEL SISTEMA
-- =====================================================

SELECT 'INFORMACIÓN GENERAL DEL SISTEMA' as 'SECCIÓN';

-- Estado general de InnoDB
SHOW ENGINE INNODB STATUS\G

-- Variables relacionadas con deadlocks
SELECT 'CONFIGURACIÓN DE DEADLOCKS' as 'SUBSECCIÓN';
SHOW VARIABLES LIKE '%deadlock%';
SHOW VARIABLES LIKE '%lock_wait%';
SHOW VARIABLES LIKE '%timeout%';

-- =====================================================
-- 2. ESTADÍSTICAS DE DEADLOCKS
-- =====================================================

SELECT 'ESTADÍSTICAS DE DEADLOCKS' as 'SECCIÓN';

-- Estadísticas de deadlocks desde el inicio
SELECT 
    VARIABLE_NAME as 'Métrica',
    VARIABLE_VALUE as 'Valor'
FROM performance_schema.global_status 
WHERE VARIABLE_NAME IN (
    'Innodb_deadlocks',
    'Innodb_lock_timeouts',
    'Innodb_row_lock_waits',
    'Innodb_row_lock_time',
    'Innodb_row_lock_time_avg'
);

-- =====================================================
-- 3. PROCESOS ACTIVOS Y LOCKS
-- =====================================================

SELECT 'PROCESOS ACTIVOS' as 'SECCIÓN';

-- Procesos actualmente ejecutándose
SELECT 
    ID as 'Process_ID',
    USER as 'Usuario',
    HOST as 'Host',
    DB as 'Database',
    COMMAND as 'Comando',
    TIME as 'Tiempo_Seg',
    STATE as 'Estado',
    LEFT(INFO, 100) as 'Query_Truncada'
FROM INFORMATION_SCHEMA.PROCESSLIST 
WHERE COMMAND != 'Sleep'
ORDER BY TIME DESC;

-- =====================================================
-- 4. LOCKS ACTUALES (Performance Schema)
-- =====================================================

SELECT 'LOCKS ACTUALES' as 'SECCIÓN';

-- Locks de datos actuales
SELECT 
    r.trx_id as 'Transaction_ID',
    r.trx_mysql_thread_id as 'Thread_ID',
    r.trx_query as 'Query',
    l.lock_table as 'Tabla_Bloqueada',
    l.lock_type as 'Tipo_Lock',
    l.lock_mode as 'Modo_Lock',
    l.lock_status as 'Estado_Lock'
FROM information_schema.innodb_trx r
LEFT JOIN information_schema.innodb_locks l ON r.trx_id = l.lock_trx_id
ORDER BY r.trx_started;

-- =====================================================
-- 5. TRANSACCIONES ESPERANDO LOCKS
-- =====================================================

SELECT 'TRANSACCIONES ESPERANDO' as 'SECCIÓN';

-- Transacciones que están esperando locks
SELECT 
    w.requesting_trx_id as 'Trx_Esperando',
    w.requested_lock_id as 'Lock_Solicitado',
    w.blocking_trx_id as 'Trx_Bloqueando',
    w.blocking_lock_id as 'Lock_Bloqueante'
FROM information_schema.innodb_lock_waits w;

-- =====================================================
-- 6. ANÁLISIS DE TABLAS PROBLEMÁTICAS
-- =====================================================

SELECT 'ANÁLISIS DE TABLAS' as 'SECCIÓN';

-- Estadísticas de las tablas principales
SELECT 
    TABLE_NAME as 'Tabla',
    TABLE_ROWS as 'Filas_Estimadas',
    DATA_LENGTH as 'Tamaño_Datos_Bytes',
    INDEX_LENGTH as 'Tamaño_Indices_Bytes',
    AUTO_INCREMENT as 'Siguiente_ID'
FROM information_schema.TABLES 
WHERE TABLE_SCHEMA = 'techstore_db'
AND TABLE_NAME IN ('orders', 'inventory', 'payments', 'order_items')
ORDER BY TABLE_ROWS DESC;

-- =====================================================
-- 7. QUERIES LENTAS RECIENTES
-- =====================================================

SELECT 'QUERIES LENTAS RECIENTES' as 'SECCIÓN';

-- Top 10 queries más lentas (requiere slow query log habilitado)
SELECT 
    start_time as 'Inicio',
    user_host as 'Usuario_Host',
    query_time as 'Tiempo_Query',
    lock_time as 'Tiempo_Lock',
    rows_sent as 'Filas_Enviadas',
    rows_examined as 'Filas_Examinadas',
    LEFT(sql_text, 200) as 'Query_Truncada'
FROM mysql.slow_log 
WHERE start_time >= DATE_SUB(NOW(), INTERVAL 10 MINUTE)
ORDER BY query_time DESC 
LIMIT 10;

-- =====================================================
-- 8. ANÁLISIS DE PATRONES DE ACCESO
-- =====================================================

SELECT 'PATRONES DE ACCESO' as 'SECCIÓN';

-- Análisis de órdenes recientes por minuto
SELECT 
    DATE_FORMAT(created_at, '%H:%i') as 'Minuto',
    COUNT(*) as 'Ordenes_Creadas',
    AVG(total_amount) as 'Monto_Promedio'
FROM orders 
WHERE created_at >= DATE_SUB(NOW(), INTERVAL 30 MINUTE)
GROUP BY DATE_FORMAT(created_at, '%H:%i')
ORDER BY Minuto DESC
LIMIT 10;

-- Productos más accedidos (potenciales hotspots)
SELECT 
    i.product_id as 'Producto_ID',
    i.stock as 'Stock_Actual',
    COUNT(oi.product_id) as 'Veces_Vendido_Ultima_Hora'
FROM inventory i
LEFT JOIN order_items oi ON i.product_id = oi.product_id
LEFT JOIN orders o ON oi.order_id = o.order_id
WHERE o.created_at >= DATE_SUB(NOW(), INTERVAL 1 HOUR) OR o.created_at IS NULL
GROUP BY i.product_id, i.stock
ORDER BY Veces_Vendido_Ultima_Hora DESC
LIMIT 20;

-- =====================================================
-- 9. RECOMENDACIONES DE DIAGNÓSTICO
-- =====================================================

SELECT 'PASOS SIGUIENTES RECOMENDADOS' as 'SECCIÓN';

SELECT '1. Revisar SHOW ENGINE INNODB STATUS para deadlocks recientes' as 'Paso';
SELECT '2. Analizar patrones en mysql.slow_log' as 'Paso';
SELECT '3. Identificar transacciones de larga duración' as 'Paso';
SELECT '4. Verificar orden de acceso a tablas en transacciones' as 'Paso';
SELECT '5. Considerar índices adicionales en tablas hotspot' as 'Paso';
SELECT '6. Evaluar isolation level de transacciones' as 'Paso';
SELECT '7. Implementar retry logic en aplicación' as 'Paso';

-- =====================================================
-- 10. COMANDOS ÚTILES PARA INVESTIGACIÓN ADICIONAL
-- =====================================================

SELECT 'COMANDOS ADICIONALES ÚTILES' as 'SECCIÓN';

SELECT 'SHOW ENGINE INNODB STATUS\\G -- Estado detallado de InnoDB' as 'Comando';
SELECT 'SELECT * FROM performance_schema.events_waits_current; -- Waits actuales' as 'Comando';
SELECT 'SELECT * FROM performance_schema.mutex_instances; -- Mutex status' as 'Comando';
SELECT 'SHOW OPEN TABLES WHERE In_use > 0; -- Tablas en uso' as 'Comando';
