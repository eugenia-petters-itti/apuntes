# 🐘 PostgreSQL Commands Cheatsheet
## Comandos Esenciales para DBAs

### 🔧 **CONEXIÓN Y BÁSICOS**
```sql
-- Conectar a PostgreSQL
psql -h hostname -U username -d database_name
psql -U postgres

-- Ver bases de datos
\l

-- Conectar a base de datos
\c database_name

-- Ver tablas
\dt

-- Describir tabla
\d table_name
\d+ table_name  -- Con más detalles
```

### 📊 **DIAGNÓSTICO DE PERFORMANCE**
```sql
-- Ver procesos activos
SELECT * FROM pg_stat_activity;

-- Terminar proceso
SELECT pg_terminate_backend(pid);

-- Ver configuración
SHOW ALL;
SHOW shared_buffers;

-- Ver estadísticas de tablas
SELECT * FROM pg_stat_user_tables;

-- Analizar query
EXPLAIN ANALYZE SELECT * FROM table_name;
```

### 🔒 **LOCKS Y BLOQUEOS**
```sql
-- Ver locks actuales
SELECT * FROM pg_locks;

-- Ver procesos bloqueados
SELECT blocked_locks.pid AS blocked_pid,
       blocking_locks.pid AS blocking_pid,
       blocked_activity.query AS blocked_statement
FROM pg_catalog.pg_locks blocked_locks
JOIN pg_catalog.pg_stat_activity blocked_activity ON blocked_activity.pid = blocked_locks.pid
JOIN pg_catalog.pg_locks blocking_locks ON blocking_locks.locktype = blocked_locks.locktype;
```

### 🧹 **VACUUM Y MANTENIMIENTO**
```sql
-- VACUUM básico
VACUUM table_name;

-- VACUUM completo
VACUUM FULL table_name;

-- ANALYZE para estadísticas
ANALYZE table_name;

-- Ver estadísticas de VACUUM
SELECT * FROM pg_stat_user_tables;

-- Ver bloat de tablas
SELECT schemaname, tablename, 
       pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) as size
FROM pg_tables;
```
