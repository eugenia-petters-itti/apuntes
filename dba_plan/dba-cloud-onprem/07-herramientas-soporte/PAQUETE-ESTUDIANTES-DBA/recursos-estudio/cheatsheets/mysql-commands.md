# 🐬 MySQL Commands Cheatsheet
## Comandos Esenciales para DBAs

### 🔧 **CONEXIÓN Y BÁSICOS**

```sql
-- Conectar a MySQL
mysql -u root -p
mysql -h hostname -u username -p database_name

-- Ver bases de datos
SHOW DATABASES;

-- Usar base de datos
USE database_name;

-- Ver tablas
SHOW TABLES;

-- Describir tabla
DESCRIBE table_name;
SHOW CREATE TABLE table_name;
```

### 📊 **DIAGNÓSTICO DE PERFORMANCE**

```sql
-- Ver procesos activos
SHOW PROCESSLIST;
SHOW FULL PROCESSLIST;

-- Matar proceso
KILL process_id;

-- Ver variables del sistema
SHOW VARIABLES LIKE 'innodb%';
SHOW VARIABLES LIKE '%buffer%';

-- Ver estado del servidor
SHOW STATUS;
SHOW STATUS LIKE 'Innodb%';

-- Ver queries lentas
SHOW STATUS LIKE 'Slow_queries';

-- Analizar query
EXPLAIN SELECT * FROM table_name WHERE condition;
EXPLAIN FORMAT=JSON SELECT * FROM table_name;
```

### 🔒 **DEADLOCKS Y LOCKS**

```sql
-- Ver estado de InnoDB (incluye deadlocks)
SHOW ENGINE INNODB STATUS\G

-- Ver transacciones activas
SELECT * FROM information_schema.innodb_trx;

-- Ver locks actuales
SELECT * FROM information_schema.innodb_locks;

-- Ver esperas de locks
SELECT * FROM information_schema.innodb_lock_waits;

-- Ver estadísticas de deadlocks
SHOW STATUS LIKE 'Innodb_deadlocks';
```

### 📈 **ÍNDICES Y OPTIMIZACIÓN**

```sql
-- Ver índices de una tabla
SHOW INDEX FROM table_name;

-- Crear índice
CREATE INDEX idx_name ON table_name (column_name);
CREATE INDEX idx_composite ON table_name (col1, col2);

-- Índice único
CREATE UNIQUE INDEX idx_unique ON table_name (column_name);

-- Eliminar índice
DROP INDEX idx_name ON table_name;

-- Analizar tabla (actualizar estadísticas)
ANALYZE TABLE table_name;

-- Optimizar tabla
OPTIMIZE TABLE table_name;

-- Ver uso de índices
SELECT * FROM sys.schema_unused_indexes;
```

### 💾 **GESTIÓN DE MEMORIA**

```sql
-- Ver configuración de buffer pool
SHOW VARIABLES LIKE 'innodb_buffer_pool_size';
SHOW STATUS LIKE 'Innodb_buffer_pool%';

-- Ver uso de memoria
SHOW STATUS LIKE 'Created_tmp%';
SHOW VARIABLES LIKE '%tmp%';

-- Configurar variables (temporal)
SET GLOBAL innodb_buffer_pool_size = 1073741824; -- 1GB
SET SESSION sort_buffer_size = 2097152; -- 2MB
```

### 🔄 **REPLICACIÓN**

```sql
-- Ver estado del master
SHOW MASTER STATUS;

-- Ver estado del slave
SHOW SLAVE STATUS\G

-- Iniciar/detener replicación
START SLAVE;
STOP SLAVE;

-- Ver logs binarios
SHOW BINARY LOGS;
SHOW BINLOG EVENTS IN 'mysql-bin.000001';

-- Ver posición actual
SHOW MASTER STATUS;
```

### 🛠️ **MANTENIMIENTO**

```sql
-- Verificar tabla
CHECK TABLE table_name;

-- Reparar tabla
REPAIR TABLE table_name;

-- Ver tamaño de tablas
SELECT 
    table_name,
    ROUND(((data_length + index_length) / 1024 / 1024), 2) AS 'Size (MB)'
FROM information_schema.tables 
WHERE table_schema = 'database_name'
ORDER BY (data_length + index_length) DESC;

-- Ver fragmentación
SELECT 
    table_name,
    data_free,
    ROUND(data_free/1024/1024, 2) AS 'Fragmentation (MB)'
FROM information_schema.tables 
WHERE table_schema = 'database_name' 
AND data_free > 0;
```

### 👥 **USUARIOS Y PERMISOS**

```sql
-- Ver usuarios
SELECT user, host FROM mysql.user;

-- Crear usuario
CREATE USER 'username'@'host' IDENTIFIED BY 'password';

-- Otorgar permisos
GRANT ALL PRIVILEGES ON database.* TO 'username'@'host';
GRANT SELECT, INSERT ON database.table TO 'username'@'host';

-- Ver permisos
SHOW GRANTS FOR 'username'@'host';

-- Eliminar usuario
DROP USER 'username'@'host';

-- Recargar permisos
FLUSH PRIVILEGES;
```

### 📋 **BACKUP Y RECOVERY**

```sql
-- Backup con mysqldump
mysqldump -u root -p database_name > backup.sql
mysqldump -u root -p --all-databases > full_backup.sql

-- Backup de tabla específica
mysqldump -u root -p database_name table_name > table_backup.sql

-- Restaurar backup
mysql -u root -p database_name < backup.sql

-- Backup binario (para replicación)
mysqldump -u root -p --master-data=2 --single-transaction database_name > backup.sql
```

### 🔍 **PERFORMANCE SCHEMA**

```sql
-- Habilitar Performance Schema
-- En my.cnf: performance_schema = ON

-- Ver queries más lentas
SELECT * FROM performance_schema.events_statements_summary_by_digest 
ORDER BY avg_timer_wait DESC LIMIT 10;

-- Ver uso de índices
SELECT * FROM performance_schema.table_io_waits_summary_by_index_usage
WHERE object_schema = 'database_name'
ORDER BY count_fetch DESC;

-- Ver esperas de I/O
SELECT * FROM performance_schema.file_summary_by_event_name
ORDER BY sum_timer_wait DESC;
```

### ⚙️ **CONFIGURACIÓN IMPORTANTE**

```sql
-- Variables críticas para performance
SHOW VARIABLES WHERE Variable_name IN (
    'innodb_buffer_pool_size',
    'innodb_log_file_size',
    'max_connections',
    'query_cache_size',
    'sort_buffer_size',
    'join_buffer_size',
    'tmp_table_size',
    'max_heap_table_size'
);

-- Configuración de logs
SHOW VARIABLES LIKE '%log%';

-- Configuración de timeouts
SHOW VARIABLES LIKE '%timeout%';
```

### 🚨 **COMANDOS DE EMERGENCIA**

```sql
-- Ver conexiones por usuario
SELECT user, count(*) FROM information_schema.processlist 
GROUP BY user;

-- Matar todas las conexiones de un usuario
SELECT CONCAT('KILL ', id, ';') FROM information_schema.processlist 
WHERE user = 'username';

-- Ver tablas bloqueadas
SHOW OPEN TABLES WHERE In_use > 0;

-- Forzar unlock de tablas
UNLOCK TABLES;

-- Ver espacio libre
SELECT 
    table_schema,
    ROUND(SUM(data_length + index_length) / 1024 / 1024, 1) AS 'DB Size in MB' 
FROM information_schema.tables 
GROUP BY table_schema;
```

### 📝 **LOGS IMPORTANTES**

```bash
# Ubicaciones típicas de logs
/var/log/mysql/error.log          # Error log
/var/log/mysql/mysql-slow.log     # Slow query log
/var/log/mysql/mysql-bin.*        # Binary logs

# Ver logs en tiempo real
tail -f /var/log/mysql/error.log
tail -f /var/log/mysql/mysql-slow.log

# Analizar slow query log
mysqldumpslow /var/log/mysql/mysql-slow.log
```

### 🎯 **TIPS DE TROUBLESHOOTING**

1. **Siempre empezar con:** `SHOW PROCESSLIST;`
2. **Para deadlocks:** `SHOW ENGINE INNODB STATUS\G`
3. **Para performance:** `EXPLAIN` en queries lentas
4. **Para memoria:** Revisar `Created_tmp_disk_tables`
5. **Para replicación:** `SHOW SLAVE STATUS\G`

### 🔗 **COMANDOS ÚTILES DEL SISTEMA**

```bash
# Ver uso de MySQL
ps aux | grep mysql
top -p $(pgrep mysql)

# Ver conexiones de red
netstat -tlnp | grep 3306
ss -tlnp | grep 3306

# Ver archivos abiertos por MySQL
lsof -u mysql

# Reiniciar MySQL
sudo systemctl restart mysql
sudo service mysql restart
```

---

**💡 Tip:** Guarda este cheatsheet y tenlo siempre a mano durante los escenarios. ¡Te ahorrará mucho tiempo!
