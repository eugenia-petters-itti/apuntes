-- Script de Diagnóstico de Performance MySQL
-- Escenario: EduTech E-learning Platform
-- Uso: mysql -u root -p < performance-analyzer.sql

-- =====================================================
-- 1. INFORMACIÓN GENERAL DEL SISTEMA
-- =====================================================

SELECT 'INFORMACIÓN GENERAL DEL SISTEMA' as 'SECCIÓN';

-- Variables de configuración relacionadas con performance
SELECT 'CONFIGURACIÓN DE MEMORIA Y BUFFERS' as 'SUBSECCIÓN';
SHOW VARIABLES WHERE Variable_name IN (
    'innodb_buffer_pool_size',
    'innodb_buffer_pool_instances', 
    'key_buffer_size',
    'sort_buffer_size',
    'read_buffer_size',
    'join_buffer_size',
    'tmp_table_size',
    'max_heap_table_size'
);

-- =====================================================
-- 2. ANÁLISIS DE QUERIES LENTAS
-- =====================================================

SELECT 'ANÁLISIS DE QUERIES LENTAS' as 'SECCIÓN';

-- Top 10 queries más lentas desde el performance schema
SELECT 'TOP 10 QUERIES MÁS LENTAS' as 'SUBSECCIÓN';
SELECT 
    DIGEST_TEXT as 'Query_Pattern',
    COUNT_STAR as 'Execution_Count',
    ROUND(AVG_TIMER_WAIT/1000000000000, 2) as 'Avg_Time_Seconds',
    ROUND(MAX_TIMER_WAIT/1000000000000, 2) as 'Max_Time_Seconds',
    ROUND(SUM_TIMER_WAIT/1000000000000, 2) as 'Total_Time_Seconds',
    ROUND(AVG_ROWS_EXAMINED, 0) as 'Avg_Rows_Examined',
    ROUND(AVG_ROWS_SENT, 0) as 'Avg_Rows_Sent'
FROM performance_schema.events_statements_summary_by_digest 
WHERE DIGEST_TEXT IS NOT NULL
ORDER BY AVG_TIMER_WAIT DESC 
LIMIT 10;

-- Queries que no usan índices
SELECT 'QUERIES SIN ÍNDICES' as 'SUBSECCIÓN';
SELECT 
    DIGEST_TEXT as 'Query_Pattern',
    COUNT_STAR as 'Execution_Count',
    SUM_NO_INDEX_USED as 'No_Index_Used_Count',
    SUM_NO_GOOD_INDEX_USED as 'No_Good_Index_Used_Count',
    ROUND(AVG_TIMER_WAIT/1000000000000, 2) as 'Avg_Time_Seconds'
FROM performance_schema.events_statements_summary_by_digest 
WHERE SUM_NO_INDEX_USED > 0 OR SUM_NO_GOOD_INDEX_USED > 0
ORDER BY SUM_NO_INDEX_USED DESC, AVG_TIMER_WAIT DESC
LIMIT 10;

-- =====================================================
-- 3. ANÁLISIS DE ÍNDICES
-- =====================================================

SELECT 'ANÁLISIS DE ÍNDICES' as 'SECCIÓN';

-- Tablas sin índices secundarios (problemáticas)
SELECT 'TABLAS CON POCOS ÍNDICES' as 'SUBSECCIÓN';
SELECT 
    t.TABLE_NAME as 'Tabla',
    t.TABLE_ROWS as 'Filas_Estimadas',
    ROUND(t.DATA_LENGTH/1024/1024, 2) as 'Tamaño_MB',
    COUNT(s.INDEX_NAME) as 'Número_Índices'
FROM information_schema.TABLES t
LEFT JOIN information_schema.STATISTICS s ON t.TABLE_NAME = s.TABLE_NAME 
    AND t.TABLE_SCHEMA = s.TABLE_SCHEMA
WHERE t.TABLE_SCHEMA = 'edutech_db'
    AND t.TABLE_TYPE = 'BASE TABLE'
GROUP BY t.TABLE_NAME, t.TABLE_ROWS, t.DATA_LENGTH
HAVING COUNT(s.INDEX_NAME) <= 2  -- Solo PRIMARY KEY y tal vez uno más
ORDER BY t.TABLE_ROWS DESC;

-- Índices existentes por tabla
SELECT 'ÍNDICES EXISTENTES' as 'SUBSECCIÓN';
SELECT 
    TABLE_NAME as 'Tabla',
    INDEX_NAME as 'Índice',
    GROUP_CONCAT(COLUMN_NAME ORDER BY SEQ_IN_INDEX) as 'Columnas',
    NON_UNIQUE as 'No_Único',
    INDEX_TYPE as 'Tipo'
FROM information_schema.STATISTICS 
WHERE TABLE_SCHEMA = 'edutech_db'
    AND TABLE_NAME IN ('courses', 'enrollments', 'student_progress', 'lessons', 'course_reviews')
GROUP BY TABLE_NAME, INDEX_NAME, NON_UNIQUE, INDEX_TYPE
ORDER BY TABLE_NAME, INDEX_NAME;

-- =====================================================
-- 4. ANÁLISIS DE USO DE ÍNDICES
-- =====================================================

SELECT 'ANÁLISIS DE USO DE ÍNDICES' as 'SECCIÓN';

-- Estadísticas de uso de índices
SELECT 'ESTADÍSTICAS DE USO DE ÍNDICES' as 'SUBSECCIÓN';
SELECT 
    OBJECT_SCHEMA as 'Database',
    OBJECT_NAME as 'Table',
    INDEX_NAME as 'Index',
    COUNT_FETCH as 'Rows_Fetched',
    COUNT_INSERT as 'Rows_Inserted',
    COUNT_UPDATE as 'Rows_Updated',
    COUNT_DELETE as 'Rows_Deleted'
FROM performance_schema.table_io_waits_summary_by_index_usage
WHERE OBJECT_SCHEMA = 'edutech_db'
    AND OBJECT_NAME IN ('courses', 'enrollments', 'student_progress', 'lessons')
ORDER BY COUNT_FETCH DESC;

-- =====================================================
-- 5. ANÁLISIS DE TABLAS PROBLEMÁTICAS
-- =====================================================

SELECT 'ANÁLISIS DE TABLAS PROBLEMÁTICAS' as 'SECCIÓN';

-- Estadísticas de las tablas principales
SELECT 'ESTADÍSTICAS DE TABLAS PRINCIPALES' as 'SUBSECCIÓN';
SELECT 
    TABLE_NAME as 'Tabla',
    TABLE_ROWS as 'Filas_Estimadas',
    ROUND(DATA_LENGTH/1024/1024, 2) as 'Datos_MB',
    ROUND(INDEX_LENGTH/1024/1024, 2) as 'Índices_MB',
    ROUND((DATA_LENGTH + INDEX_LENGTH)/1024/1024, 2) as 'Total_MB',
    AUTO_INCREMENT as 'Siguiente_ID'
FROM information_schema.TABLES 
WHERE TABLE_SCHEMA = 'edutech_db'
    AND TABLE_TYPE = 'BASE TABLE'
ORDER BY (DATA_LENGTH + INDEX_LENGTH) DESC;

-- Análisis de cardinalidad de columnas (para índices)
SELECT 'CARDINALIDAD DE COLUMNAS CLAVE' as 'SUBSECCIÓN';

-- Cardinalidad en tabla courses
SELECT 'courses - category_id' as 'Tabla_Columna', COUNT(DISTINCT category_id) as 'Valores_Únicos', COUNT(*) as 'Total_Filas'
FROM courses
UNION ALL
SELECT 'courses - difficulty_level', COUNT(DISTINCT difficulty_level), COUNT(*) FROM courses
UNION ALL
SELECT 'courses - instructor_id', COUNT(DISTINCT instructor_id), COUNT(*) FROM courses
UNION ALL
SELECT 'courses - is_published', COUNT(DISTINCT is_published), COUNT(*) FROM courses;

-- Cardinalidad en tabla enrollments
SELECT 'enrollments - student_id' as 'Tabla_Columna', COUNT(DISTINCT student_id) as 'Valores_Únicos', COUNT(*) as 'Total_Filas'
FROM enrollments
UNION ALL
SELECT 'enrollments - course_id', COUNT(DISTINCT course_id), COUNT(*) FROM enrollments
UNION ALL
SELECT 'enrollments - is_completed', COUNT(DISTINCT is_completed), COUNT(*) FROM enrollments;

-- =====================================================
-- 6. ANÁLISIS DE OPERACIONES I/O
-- =====================================================

SELECT 'ANÁLISIS DE OPERACIONES I/O' as 'SECCIÓN';

-- I/O por tabla
SELECT 'I/O POR TABLA' as 'SUBSECCIÓN';
SELECT 
    OBJECT_SCHEMA as 'Database',
    OBJECT_NAME as 'Table',
    COUNT_READ as 'Lecturas',
    COUNT_WRITE as 'Escrituras',
    COUNT_FETCH as 'Fetch_Operations',
    COUNT_INSERT as 'Insert_Operations',
    COUNT_UPDATE as 'Update_Operations',
    COUNT_DELETE as 'Delete_Operations'
FROM performance_schema.table_io_waits_summary_by_table
WHERE OBJECT_SCHEMA = 'edutech_db'
ORDER BY (COUNT_READ + COUNT_WRITE) DESC
LIMIT 10;

-- =====================================================
-- 7. ANÁLISIS DE MEMORIA Y BUFFERS
-- =====================================================

SELECT 'ANÁLISIS DE MEMORIA Y BUFFERS' as 'SECCIÓN';

-- Estado del buffer pool de InnoDB
SELECT 'ESTADO DEL BUFFER POOL' as 'SUBSECCIÓN';
SHOW STATUS LIKE 'Innodb_buffer_pool%';

-- Estadísticas de tablas temporales
SELECT 'TABLAS TEMPORALES' as 'SUBSECCIÓN';
SHOW STATUS WHERE Variable_name IN (
    'Created_tmp_tables',
    'Created_tmp_disk_tables',
    'Created_tmp_files'
);

-- =====================================================
-- 8. QUERIES DE EJEMPLO PROBLEMÁTICAS
-- =====================================================

SELECT 'QUERIES DE EJEMPLO PROBLEMÁTICAS' as 'SECCIÓN';

-- Ejemplo 1: Dashboard query (muy lenta sin índices)
SELECT 'EJEMPLO 1: DASHBOARD QUERY (LENTA)' as 'SUBSECCIÓN';
EXPLAIN FORMAT=JSON
SELECT 
    c.course_id,
    c.title,
    c.instructor_id,
    (SELECT COUNT(*) FROM enrollments e WHERE e.course_id = c.course_id) AS total_enrollments,
    (SELECT AVG(rating) FROM course_reviews cr WHERE cr.course_id = c.course_id) AS avg_rating
FROM courses c
WHERE c.is_published = TRUE
ORDER BY c.created_at DESC
LIMIT 10;

-- Ejemplo 2: Search query (sin índices de texto)
SELECT 'EJEMPLO 2: SEARCH QUERY (SIN ÍNDICES)' as 'SUBSECCIÓN';
EXPLAIN FORMAT=JSON
SELECT 
    c.course_id,
    c.title,
    c.description
FROM courses c
WHERE c.title LIKE '%python%' 
   OR c.description LIKE '%python%'
   OR c.course_content LIKE '%python%'
ORDER BY c.created_at DESC
LIMIT 20;

-- Ejemplo 3: Report query (múltiples JOINs sin índices)
SELECT 'EJEMPLO 3: REPORT QUERY (MÚLTIPLES JOINS)' as 'SUBSECCIÓN';
EXPLAIN FORMAT=JSON
SELECT 
    c.course_id,
    c.title,
    COUNT(DISTINCT e.enrollment_id) AS total_students,
    AVG(e.progress_percentage) AS avg_progress
FROM courses c
LEFT JOIN enrollments e ON c.course_id = e.course_id
LEFT JOIN student_progress sp ON e.enrollment_id = sp.enrollment_id
WHERE c.instructor_id = 1
GROUP BY c.course_id, c.title;

-- =====================================================
-- 9. RECOMENDACIONES DE ÍNDICES
-- =====================================================

SELECT 'RECOMENDACIONES DE ÍNDICES' as 'SECCIÓN';

SELECT 'ÍNDICES RECOMENDADOS PARA OPTIMIZACIÓN' as 'SUBSECCIÓN';

SELECT 'courses' as 'Tabla', 'CREATE INDEX idx_courses_published_created ON courses(is_published, created_at DESC);' as 'Índice_Recomendado'
UNION ALL
SELECT 'courses', 'CREATE INDEX idx_courses_instructor ON courses(instructor_id);'
UNION ALL
SELECT 'courses', 'CREATE INDEX idx_courses_category ON courses(category_id);'
UNION ALL
SELECT 'courses', 'CREATE FULLTEXT INDEX idx_courses_search ON courses(title, description, course_content);'
UNION ALL
SELECT 'enrollments', 'CREATE INDEX idx_enrollments_student ON enrollments(student_id);'
UNION ALL
SELECT 'enrollments', 'CREATE INDEX idx_enrollments_course ON enrollments(course_id);'
UNION ALL
SELECT 'enrollments', 'CREATE INDEX idx_enrollments_completed ON enrollments(is_completed);'
UNION ALL
SELECT 'student_progress', 'CREATE INDEX idx_progress_enrollment ON student_progress(enrollment_id);'
UNION ALL
SELECT 'student_progress', 'CREATE INDEX idx_progress_lesson ON student_progress(lesson_id);'
UNION ALL
SELECT 'student_progress', 'CREATE INDEX idx_progress_completed ON student_progress(is_completed);'
UNION ALL
SELECT 'lessons', 'CREATE INDEX idx_lessons_course ON lessons(course_id);'
UNION ALL
SELECT 'course_reviews', 'CREATE INDEX idx_reviews_course ON course_reviews(course_id);'
UNION ALL
SELECT 'activity_logs', 'CREATE INDEX idx_activity_user_date ON activity_logs(user_id, created_at);';

-- =====================================================
-- 10. COMANDOS PARA MONITOREO CONTINUO
-- =====================================================

SELECT 'COMANDOS PARA MONITOREO CONTINUO' as 'SECCIÓN';

SELECT 'COMANDOS ÚTILES PARA MONITOREO' as 'SUBSECCIÓN';

SELECT 'SHOW PROCESSLIST; -- Ver queries en ejecución' as 'Comando'
UNION ALL
SELECT 'SHOW STATUS LIKE "Slow_queries"; -- Contador de queries lentas'
UNION ALL
SELECT 'SHOW STATUS LIKE "Created_tmp%"; -- Tablas temporales'
UNION ALL
SELECT 'SHOW STATUS LIKE "Innodb_buffer_pool_read%"; -- Eficiencia del buffer pool'
UNION ALL
SELECT 'SELECT * FROM sys.statements_with_full_table_scans; -- Queries con table scans'
UNION ALL
SELECT 'SELECT * FROM sys.schema_unused_indexes; -- Índices no utilizados';

-- Mostrar resumen final
SELECT 'RESUMEN FINAL' as 'SECCIÓN';
SELECT 'Revisa las queries lentas, crea los índices recomendados y monitorea la mejora' as 'Próximos_Pasos';
