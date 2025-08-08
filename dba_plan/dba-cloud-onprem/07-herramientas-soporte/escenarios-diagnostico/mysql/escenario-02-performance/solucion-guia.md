# Guía de Solución: Performance MySQL
## Escenario EduTech E-learning Platform

### 🎯 Proceso de Diagnóstico Paso a Paso

#### **PASO 1: Identificación de Queries Lentas (8 minutos)**

**Comandos de diagnóstico inmediato:**
```sql
-- Ver queries actualmente ejecutándose
SHOW PROCESSLIST;

-- Verificar configuración de slow query log
SHOW VARIABLES LIKE 'slow_query_log%';
SHOW VARIABLES LIKE 'long_query_time';

-- Ver contador de queries lentas
SHOW STATUS LIKE 'Slow_queries';
```

**🔍 Ejecutar script de diagnóstico completo:**
```bash
# Dentro del contenedor MySQL
mysql -u root -pdba2024! edutech_db < /scripts/performance-analyzer.sql > /reports/performance-analysis.txt
```

**Hallazgos esperados:**
- ✅ Slow query log muestra 150+ queries/minuto
- ✅ Queries de dashboard tardan 15-30 segundos
- ✅ Búsquedas con LIKE tardan 10-20 segundos
- ✅ Reportes con JOINs tardan 20-45 segundos

#### **PASO 2: Análisis de Índices Faltantes (7 minutos)**

**Verificar índices existentes:**
```sql
-- Ver índices por tabla
SELECT 
    TABLE_NAME,
    INDEX_NAME,
    GROUP_CONCAT(COLUMN_NAME ORDER BY SEQ_IN_INDEX) as COLUMNS
FROM information_schema.STATISTICS 
WHERE TABLE_SCHEMA = 'edutech_db'
GROUP BY TABLE_NAME, INDEX_NAME
ORDER BY TABLE_NAME;

-- Verificar uso de índices
SELECT * FROM performance_schema.table_io_waits_summary_by_index_usage
WHERE OBJECT_SCHEMA = 'edutech_db'
ORDER BY COUNT_FETCH DESC;
```

**🔍 Problema identificado:**
- ❌ Tabla `courses`: Solo PRIMARY KEY
- ❌ Tabla `enrollments`: Solo PRIMARY KEY y UNIQUE
- ❌ Tabla `student_progress`: Solo PRIMARY KEY
- ❌ Tabla `lessons`: Solo PRIMARY KEY
- ❌ Sin índices FULLTEXT para búsquedas

#### **PASO 3: Análisis de Planes de Ejecución (10 minutos)**

**Analizar queries problemáticas:**
```sql
-- Query 1: Dashboard (subconsultas lentas)
EXPLAIN FORMAT=JSON
SELECT 
    c.course_id,
    c.title,
    (SELECT COUNT(*) FROM enrollments e WHERE e.course_id = c.course_id) AS total_enrollments,
    (SELECT AVG(rating) FROM course_reviews cr WHERE cr.course_id = c.course_id) AS avg_rating
FROM courses c
WHERE c.is_published = TRUE
ORDER BY c.created_at DESC
LIMIT 10;

-- Query 2: Búsqueda de texto (sin índices FULLTEXT)
EXPLAIN FORMAT=JSON
SELECT c.course_id, c.title
FROM courses c
WHERE c.title LIKE '%python%' 
   OR c.description LIKE '%python%';

-- Query 3: Reporte con JOINs (sin índices en FK)
EXPLAIN FORMAT=JSON
SELECT 
    c.course_id,
    COUNT(DISTINCT e.enrollment_id) AS total_students
FROM courses c
LEFT JOIN enrollments e ON c.course_id = e.course_id
WHERE c.instructor_id = 1
GROUP BY c.course_id;
```

**🔍 Problemas en planes de ejecución:**
- ❌ **Full table scans** en todas las tablas grandes
- ❌ **Using filesort** para ORDER BY
- ❌ **Using temporary** para GROUP BY
- ❌ **No index used** en JOINs

#### **PASO 4: Implementación de Solución (15 minutos)**

**A) Crear índices básicos:**
```sql
-- Índices para tabla courses
CREATE INDEX idx_courses_published_created ON courses(is_published, created_at DESC);
CREATE INDEX idx_courses_instructor ON courses(instructor_id);
CREATE INDEX idx_courses_category ON courses(category_id);

-- Índice FULLTEXT para búsquedas
CREATE FULLTEXT INDEX idx_courses_search ON courses(title, description, course_content);

-- Índices para tabla enrollments
CREATE INDEX idx_enrollments_student ON enrollments(student_id);
CREATE INDEX idx_enrollments_course ON enrollments(course_id);
CREATE INDEX idx_enrollments_completed ON enrollments(is_completed);

-- Índices para tabla student_progress
CREATE INDEX idx_progress_enrollment ON student_progress(enrollment_id);
CREATE INDEX idx_progress_lesson ON student_progress(lesson_id);
CREATE INDEX idx_progress_completed ON student_progress(is_completed);

-- Índices para tabla lessons
CREATE INDEX idx_lessons_course ON lessons(course_id);

-- Índices para tabla course_reviews
CREATE INDEX idx_reviews_course ON course_reviews(course_id);

-- Índice para logs de actividad
CREATE INDEX idx_activity_user_date ON activity_logs(user_id, created_at);
```

**B) Optimizar queries problemáticas:**
```sql
-- ANTES: Dashboard con subconsultas (lento)
-- DESPUÉS: Dashboard con JOINs y agregaciones
SELECT 
    c.course_id,
    c.title,
    c.instructor_id,
    u.first_name AS instructor_name,
    c.category_id,
    cc.category_name,
    c.difficulty_level,
    c.price,
    COALESCE(stats.total_enrollments, 0) AS total_enrollments,
    COALESCE(stats.total_completions, 0) AS total_completions,
    COALESCE(stats.avg_rating, 0) AS avg_rating,
    COALESCE(stats.total_reviews, 0) AS total_reviews
FROM courses c
JOIN users u ON c.instructor_id = u.user_id
JOIN course_categories cc ON c.category_id = cc.category_id
LEFT JOIN (
    SELECT 
        e.course_id,
        COUNT(*) AS total_enrollments,
        COUNT(CASE WHEN e.is_completed = TRUE THEN 1 END) AS total_completions,
        AVG(cr.rating) AS avg_rating,
        COUNT(DISTINCT cr.review_id) AS total_reviews
    FROM enrollments e
    LEFT JOIN course_reviews cr ON e.course_id = cr.course_id
    GROUP BY e.course_id
) stats ON c.course_id = stats.course_id
WHERE c.is_published = TRUE
ORDER BY c.created_at DESC
LIMIT 20;

-- ANTES: Búsqueda con LIKE (lento)
-- DESPUÉS: Búsqueda con FULLTEXT
SELECT 
    c.course_id,
    c.title,
    c.description,
    c.price,
    MATCH(c.title, c.description, c.course_content) AGAINST('python' IN NATURAL LANGUAGE MODE) AS relevance_score
FROM courses c
WHERE MATCH(c.title, c.description, c.course_content) AGAINST('python' IN NATURAL LANGUAGE MODE)
    AND c.is_published = TRUE
ORDER BY relevance_score DESC
LIMIT 50;
```

**C) Optimizar configuración MySQL:**
```sql
-- Aumentar buffer pool (si es posible)
SET GLOBAL innodb_buffer_pool_size = 512*1024*1024; -- 512MB

-- Optimizar configuración de memoria
SET GLOBAL sort_buffer_size = 2*1024*1024; -- 2MB
SET GLOBAL join_buffer_size = 1*1024*1024; -- 1MB
SET GLOBAL tmp_table_size = 64*1024*1024; -- 64MB
SET GLOBAL max_heap_table_size = 64*1024*1024; -- 64MB
```

#### **PASO 5: Verificación de Resultados (5 minutos)**

**Verificar mejora de performance:**
```sql
-- Verificar que los índices se están usando
EXPLAIN FORMAT=JSON
SELECT c.course_id, c.title
FROM courses c
WHERE c.is_published = TRUE
ORDER BY c.created_at DESC
LIMIT 10;

-- Verificar estadísticas de índices
SELECT 
    OBJECT_NAME as 'Table',
    INDEX_NAME as 'Index',
    COUNT_FETCH as 'Rows_Fetched'
FROM performance_schema.table_io_waits_summary_by_index_usage
WHERE OBJECT_SCHEMA = 'edutech_db'
    AND COUNT_FETCH > 0
ORDER BY COUNT_FETCH DESC;

-- Verificar reducción de queries lentas
SHOW STATUS LIKE 'Slow_queries';

-- Verificar eficiencia del buffer pool
SHOW STATUS LIKE 'Innodb_buffer_pool_read%';
```

**Métricas de éxito esperadas:**
- ✅ Dashboard carga en <5 segundos (antes: 30-45s)
- ✅ Búsquedas responden en <2 segundos (antes: 10-20s)
- ✅ Reportes completan en <10 segundos (antes: 20-45s)
- ✅ Slow queries <10/minuto (antes: 150+/minuto)
- ✅ Plans de ejecución muestran "Using index"

### 🚀 Implementación Completa

#### **Script de optimización completo:**
```sql
-- performance-optimization.sql
USE edutech_db;

-- 1. Crear todos los índices necesarios
CREATE INDEX idx_courses_published_created ON courses(is_published, created_at DESC);
CREATE INDEX idx_courses_instructor ON courses(instructor_id);
CREATE INDEX idx_courses_category ON courses(category_id);
CREATE FULLTEXT INDEX idx_courses_search ON courses(title, description, course_content);

CREATE INDEX idx_enrollments_student ON enrollments(student_id);
CREATE INDEX idx_enrollments_course ON enrollments(course_id);
CREATE INDEX idx_enrollments_completed ON enrollments(is_completed);

CREATE INDEX idx_progress_enrollment ON student_progress(enrollment_id);
CREATE INDEX idx_progress_lesson ON student_progress(lesson_id);
CREATE INDEX idx_progress_completed ON student_progress(is_completed);

CREATE INDEX idx_lessons_course ON lessons(course_id);
CREATE INDEX idx_reviews_course ON course_reviews(course_id);
CREATE INDEX idx_activity_user_date ON activity_logs(user_id, created_at);

-- 2. Crear vista optimizada para dashboard
CREATE OR REPLACE VIEW dashboard_course_summary_optimized AS
SELECT 
    c.course_id,
    c.title,
    c.instructor_id,
    u.first_name AS instructor_name,
    c.category_id,
    cc.category_name,
    c.difficulty_level,
    c.price,
    COALESCE(e_stats.total_enrollments, 0) AS total_enrollments,
    COALESCE(e_stats.total_completions, 0) AS total_completions,
    COALESCE(r_stats.avg_rating, 0) AS avg_rating,
    COALESCE(r_stats.total_reviews, 0) AS total_reviews,
    c.created_at
FROM courses c
JOIN users u ON c.instructor_id = u.user_id
JOIN course_categories cc ON c.category_id = cc.category_id
LEFT JOIN (
    SELECT 
        course_id,
        COUNT(*) AS total_enrollments,
        COUNT(CASE WHEN is_completed = TRUE THEN 1 END) AS total_completions
    FROM enrollments
    GROUP BY course_id
) e_stats ON c.course_id = e_stats.course_id
LEFT JOIN (
    SELECT 
        course_id,
        AVG(rating) AS avg_rating,
        COUNT(*) AS total_reviews
    FROM course_reviews
    GROUP BY course_id
) r_stats ON c.course_id = r_stats.course_id
WHERE c.is_published = TRUE;

-- 3. Actualizar estadísticas de tablas
ANALYZE TABLE courses, enrollments, student_progress, lessons, course_reviews;

SELECT 'Optimización completada - verificar performance' AS Status;
```

### 📊 Verificación Final

**Comandos de verificación:**
```bash
# 1. Ejecutar optimización
mysql -u root -pdba2024! edutech_db < performance-optimization.sql

# 2. Verificar mejora en tiempo real
mysql -u root -pdba2024! -e "
SELECT 
    DIGEST_TEXT,
    COUNT_STAR,
    ROUND(AVG_TIMER_WAIT/1000000000000, 2) as Avg_Seconds
FROM performance_schema.events_statements_summary_by_digest 
WHERE DIGEST_TEXT LIKE '%courses%'
ORDER BY AVG_TIMER_WAIT DESC LIMIT 5;"

# 3. Monitorear queries lentas
tail -f /var/log/mysql/slow.log
```

### 🎓 Lecciones Aprendidas

**Conceptos clave demostrados:**
1. **Índices son críticos** para performance en tablas grandes
2. **FULLTEXT indexes** para búsquedas de texto eficientes
3. **Evitar subconsultas** en favor de JOINs optimizados
4. **Análisis de planes de ejecución** es esencial
5. **Monitoreo continuo** previene degradación

**Mejores prácticas aplicadas:**
- Índices compuestos para queries complejas
- Índices en foreign keys para JOINs
- FULLTEXT para búsquedas de texto
- Vistas optimizadas para queries frecuentes
- Configuración de memoria apropiada

### 🏆 Puntuación del Escenario

**Criterios de evaluación:**
- **Identificación de queries lentas**: 25 puntos
- **Análisis correcto de índices faltantes**: 25 puntos
- **Creación de índices apropiados**: 30 puntos
- **Optimización de queries**: 15 puntos
- **Verificación de mejora**: 5 puntos

**Tiempo total utilizado**: _____ minutos (máximo 30)
**Pistas utilizadas**: _____ (penalización: -10 puntos cada una)
**Puntuación final**: _____ / 100 puntos
