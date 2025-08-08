# Performance y Troubleshooting Avanzado: OnPrem vs Cloud
## Aspectos críticos que marcan la diferencia entre un DBA junior y senior

### 🎯 Introducción
El performance tuning y troubleshooting tienen matices completamente diferentes entre OnPrem y Cloud. Esta guía cubre aspectos avanzados que muchos DBAs no dominan, incluyendo análisis de wait events, optimización de I/O, gestión de memoria y diagnóstico de problemas complejos.

---

## 📊 **ANÁLISIS DE PERFORMANCE: METODOLOGÍA AVANZADA**

### **OnPrem - Análisis Holístico del Sistema**

#### **MySQL OnPrem - Performance Schema Avanzado:**
```sql
-- Análisis de wait events (lo que muchos DBAs no usan)
SELECT 
    event_name,
    count_star,
    sum_timer_wait/1000000000000 as total_wait_time_sec,
    avg_timer_wait/1000000000000 as avg_wait_time_sec
FROM performance_schema.events_waits_summary_global_by_event_name 
WHERE count_star > 0 
ORDER BY sum_timer_wait DESC 
LIMIT 20;

-- Análisis de I/O por tabla (crítico para performance)
SELECT 
    object_schema,
    object_name,
    count_read,
    count_write,
    sum_timer_read/1000000000000 as read_time_sec,
    sum_timer_write/1000000000000 as write_time_sec,
    (sum_timer_read + sum_timer_write)/1000000000000 as total_io_time
FROM performance_schema.table_io_waits_summary_by_table 
WHERE object_schema NOT IN ('mysql', 'performance_schema', 'information_schema')
ORDER BY total_io_time DESC 
LIMIT 20;

-- Análisis de memoria por thread (avanzado)
SELECT 
    thread_id,
    user,
    host,
    current_memory/1024/1024 as current_memory_mb,
    max_memory/1024/1024 as max_memory_mb
FROM performance_schema.memory_summary_by_thread_by_event_name msbtben
JOIN performance_schema.threads t ON msbtben.thread_id = t.thread_id
WHERE event_name = 'memory/sql/THD::main_mem_root'
ORDER BY current_memory DESC 
LIMIT 20;
```

#### **PostgreSQL OnPrem - Análisis Profundo:**
```sql
-- Análisis de wait events (PostgreSQL 10+)
SELECT 
    wait_event_type,
    wait_event,
    count(*) as waiting_sessions,
    round(100.0 * count(*) / sum(count(*)) OVER (), 2) as pct
FROM pg_stat_activity 
WHERE wait_event IS NOT NULL
GROUP BY wait_event_type, wait_event
ORDER BY waiting_sessions DESC;

-- Análisis de I/O por tabla
SELECT 
    schemaname,
    tablename,
    heap_blks_read,
    heap_blks_hit,
    round(100.0 * heap_blks_hit / (heap_blks_hit + heap_blks_read), 2) as cache_hit_ratio,
    idx_blks_read,
    idx_blks_hit,
    round(100.0 * idx_blks_hit / (idx_blks_hit + idx_blks_read), 2) as idx_cache_hit_ratio
FROM pg_statio_user_tables 
WHERE heap_blks_read + heap_blks_hit > 0
ORDER BY heap_blks_read + idx_blks_read DESC;

-- Análisis de queries más costosas (con pg_stat_statements)
SELECT 
    query,
    calls,
    total_time/1000 as total_time_sec,
    mean_time/1000 as mean_time_sec,
    rows,
    100.0 * shared_blks_hit / nullif(shared_blks_hit + shared_blks_read, 0) as hit_percent
FROM pg_stat_statements 
ORDER BY total_time DESC 
LIMIT 20;
```

#### **Análisis a Nivel de Sistema Operativo:**
```bash
# I/O analysis (crítico para DBAs OnPrem)
iostat -x 1 10
# Buscar: %util > 80%, await > 10ms, svctm alto

# Memory analysis
free -h
cat /proc/meminfo | grep -E "(MemTotal|MemFree|Buffers|Cached|Dirty)"

# CPU analysis específico para DB
top -p $(pgrep -d',' mysqld)
# o
top -p $(pgrep -d',' postgres)

# Network analysis (muchos lo olvidan)
sar -n DEV 1 10
netstat -i
ss -tuln | grep -E "(3306|5432)"
```

### **RDS - Herramientas Específicas de AWS**

#### **Performance Insights - Análisis Avanzado:**
```bash
# Performance Insights API (lo que muchos no usan)
aws pi get-resource-metrics \
    --service-type RDS \
    --identifier db-ABCDEFGHIJKLMNOP \
    --start-time 2024-01-01T00:00:00Z \
    --end-time 2024-01-01T01:00:00Z \
    --metric-queries file://metric-queries.json

# Enhanced Monitoring - métricas del SO
aws logs filter-log-events \
    --log-group-name RDSOSMetrics \
    --start-time 1640995200000 \
    --filter-pattern "{ $.instanceID = \"db-instance-id\" }"
```

#### **CloudWatch Metrics Avanzadas:**
```bash
# Métricas que muchos DBAs no monitorean
aws cloudwatch get-metric-statistics \
    --namespace AWS/RDS \
    --metric-name DatabaseConnections \
    --dimensions Name=DBInstanceIdentifier,Value=mydb \
    --start-time 2024-01-01T00:00:00Z \
    --end-time 2024-01-01T01:00:00Z \
    --period 300 \
    --statistics Average,Maximum

# Métricas de I/O críticas
aws cloudwatch get-metric-statistics \
    --namespace AWS/RDS \
    --metric-name ReadIOPS \
    --metric-name WriteIOPS \
    --metric-name ReadLatency \
    --metric-name WriteLatency
```

---

## 🔧 **TROUBLESHOOTING AVANZADO: CASOS REALES**

### **Caso 1: Degradación Súbita de Performance**

#### **OnPrem - Diagnóstico Completo:**
```bash
# 1. Verificar recursos del sistema PRIMERO
top
free -h
iostat -x 1 5

# 2. Verificar procesos de DB
# MySQL:
mysql -e "SHOW PROCESSLIST;" | grep -v "Sleep"
mysql -e "SHOW ENGINE INNODB STATUS\G" | grep -A 20 "LATEST DETECTED DEADLOCK"

# PostgreSQL:
psql -c "SELECT pid, usename, application_name, state, query_start, query FROM pg_stat_activity WHERE state != 'idle';"
```

#### **Análisis de Locks (Crítico):**
```sql
-- MySQL - Análisis de locks avanzado
SELECT 
    r.trx_id waiting_trx_id,
    r.trx_mysql_thread_id waiting_thread,
    r.trx_query waiting_query,
    b.trx_id blocking_trx_id,
    b.trx_mysql_thread_id blocking_thread,
    b.trx_query blocking_query
FROM information_schema.innodb_lock_waits w
INNER JOIN information_schema.innodb_trx b ON b.trx_id = w.blocking_trx_id
INNER JOIN information_schema.innodb_trx r ON r.trx_id = w.requesting_trx_id;

-- PostgreSQL - Análisis de locks
SELECT 
    blocked_locks.pid AS blocked_pid,
    blocked_activity.usename AS blocked_user,
    blocking_locks.pid AS blocking_pid,
    blocking_activity.usename AS blocking_user,
    blocked_activity.query AS blocked_statement,
    blocking_activity.query AS current_statement_in_blocking_process
FROM pg_catalog.pg_locks blocked_locks
JOIN pg_catalog.pg_stat_activity blocked_activity ON blocked_activity.pid = blocked_locks.pid
JOIN pg_catalog.pg_locks blocking_locks ON blocking_locks.locktype = blocked_locks.locktype
    AND blocking_locks.database IS NOT DISTINCT FROM blocked_locks.database
    AND blocking_locks.relation IS NOT DISTINCT FROM blocked_locks.relation
    AND blocking_locks.page IS NOT DISTINCT FROM blocked_locks.page
    AND blocking_locks.tuple IS NOT DISTINCT FROM blocked_locks.tuple
    AND blocking_locks.virtualxid IS NOT DISTINCT FROM blocked_locks.virtualxid
    AND blocking_locks.transactionid IS NOT DISTINCT FROM blocked_locks.transactionid
    AND blocking_locks.classid IS NOT DISTINCT FROM blocked_locks.classid
    AND blocking_locks.objid IS NOT DISTINCT FROM blocked_locks.objid
    AND blocking_locks.objsubid IS NOT DISTINCT FROM blocked_locks.objsubid
    AND blocking_locks.pid != blocked_locks.pid
JOIN pg_catalog.pg_stat_activity blocking_activity ON blocking_activity.pid = blocking_locks.pid
WHERE NOT blocked_locks.granted;
```

#### **RDS - Limitaciones en Troubleshooting:**
```sql
-- En RDS NO puedes:
-- - Ver métricas del SO directamente
-- - Acceder a logs del sistema operativo
-- - Usar herramientas como iostat, top, etc.

-- Debes depender de:
-- - Performance Insights
-- - Enhanced Monitoring
-- - CloudWatch Metrics
-- - RDS Events

-- Ejemplo de diagnóstico limitado:
-- Solo puedes ver wait events a través de Performance Insights
-- No puedes correlacionar con métricas específicas del SO
```

### **Caso 2: Problema de Memoria (Muy Común)**

#### **OnPrem - Análisis Detallado:**
```bash
# MySQL - Análisis de memoria
mysql -e "SHOW VARIABLES LIKE '%buffer%';"
mysql -e "SHOW STATUS LIKE 'Innodb_buffer_pool_%';"

# Cálculo de hit ratio del buffer pool
mysql -e "
SELECT 
    ROUND(100 - (Innodb_buffer_pool_reads * 100 / Innodb_buffer_pool_read_requests), 2) AS buffer_pool_hit_ratio
FROM 
    (SELECT VARIABLE_VALUE AS Innodb_buffer_pool_reads FROM information_schema.GLOBAL_STATUS WHERE VARIABLE_NAME = 'Innodb_buffer_pool_reads') AS reads,
    (SELECT VARIABLE_VALUE AS Innodb_buffer_pool_read_requests FROM information_schema.GLOBAL_STATUS WHERE VARIABLE_NAME = 'Innodb_buffer_pool_read_requests') AS requests;
"

# PostgreSQL - Análisis de memoria
psql -c "SELECT name, setting, unit FROM pg_settings WHERE name IN ('shared_buffers', 'work_mem', 'maintenance_work_mem', 'effective_cache_size');"

# Hit ratio de cache
psql -c "
SELECT 
    'Buffer Cache Hit Ratio' as metric,
    round(100.0 * sum(heap_blks_hit) / (sum(heap_blks_hit) + sum(heap_blks_read)), 2) as percentage
FROM pg_statio_user_tables
UNION ALL
SELECT 
    'Index Cache Hit Ratio' as metric,
    round(100.0 * sum(idx_blks_hit) / (sum(idx_blks_hit) + sum(idx_blks_read)), 2) as percentage
FROM pg_statio_user_tables;
"
```

#### **Análisis de Memoria del SO:**
```bash
# Verificar si la DB está usando swap (CRÍTICO)
cat /proc/$(pgrep mysqld)/status | grep -E "(VmSwap|VmRSS)"
# o
cat /proc/$(pgrep postgres)/status | grep -E "(VmSwap|VmRSS)"

# Si VmSwap > 0, tienes un problema serio de memoria

# Análisis de dirty pages (puede causar stalls)
cat /proc/meminfo | grep -E "(Dirty|Writeback)"
# Si Dirty es muy alto, puede causar problemas de I/O
```

#### **RDS - Diagnóstico Limitado:**
```bash
# En RDS solo puedes ver:
# - Métricas de CloudWatch (FreeableMemory, SwapUsage)
# - Enhanced Monitoring (si está habilitado)
# - Performance Insights

# NO puedes:
# - Acceder a /proc/meminfo
# - Ver detalles específicos de memoria por proceso
# - Modificar parámetros del kernel relacionados con memoria
```

### **Caso 3: Problema de I/O (Muy Técnico)**

#### **OnPrem - Análisis Profundo:**
```bash
# Análisis de I/O por dispositivo
iostat -x 1 10
# Métricas clave:
# - %util: > 80% indica saturación
# - await: tiempo promedio de espera (< 10ms ideal)
# - svctm: tiempo de servicio (obsoleto en kernels nuevos)

# Análisis de I/O por proceso
iotop -p $(pgrep mysqld)
# o
iotop -p $(pgrep postgres)

# Análisis de filesystem
df -h
# Verificar que no esté > 85% lleno

# Análisis de mount options (crítico para performance)
mount | grep -E "(mysql|postgres)"
# Buscar opciones como noatime, nobarrier (para performance)
```

#### **MySQL OnPrem - I/O Específico:**
```sql
-- Análisis de I/O por tabla
SELECT 
    table_schema,
    table_name,
    io_read_requests,
    io_read,
    io_read_bytes,
    io_write_requests,
    io_write,
    io_write_bytes
FROM sys.io_global_by_file_by_bytes 
WHERE file LIKE '%.ibd'
ORDER BY io_read_bytes + io_write_bytes DESC 
LIMIT 20;

-- Análisis de InnoDB I/O
SHOW ENGINE INNODB STATUS\G
-- Buscar sección "FILE I/O"
-- Verificar pending reads/writes
```

#### **PostgreSQL OnPrem - I/O Específico:**
```sql
-- Análisis de I/O por tabla
SELECT 
    schemaname,
    tablename,
    heap_blks_read * 8192 as heap_read_bytes,
    heap_blks_hit * 8192 as heap_hit_bytes,
    idx_blks_read * 8192 as idx_read_bytes,
    idx_blks_hit * 8192 as idx_hit_bytes
FROM pg_statio_user_tables
ORDER BY heap_blks_read + idx_blks_read DESC;

-- Análisis de WAL
SELECT 
    name,
    setting,
    unit
FROM pg_settings 
WHERE name IN ('wal_buffers', 'checkpoint_segments', 'checkpoint_completion_target');
```

#### **RDS - Métricas de I/O:**
```bash
# CloudWatch metrics para I/O
aws cloudwatch get-metric-statistics \
    --namespace AWS/RDS \
    --metric-name ReadIOPS \
    --metric-name WriteIOPS \
    --metric-name ReadLatency \
    --metric-name WriteLatency \
    --metric-name ReadThroughput \
    --metric-name WriteThroughput

# LIMITACIÓN: No puedes ver I/O por tabla específica
# LIMITACIÓN: No puedes optimizar a nivel de filesystem
# LIMITACIÓN: No puedes cambiar mount options
```

---

## ⚡ **OPTIMIZACIÓN AVANZADA DE PERFORMANCE**

### **MySQL OnPrem - Tuning Avanzado**

#### **InnoDB Buffer Pool Optimization:**
```sql
-- Análisis del buffer pool
SELECT 
    POOL_ID,
    POOL_SIZE,
    FREE_BUFFERS,
    DATABASE_PAGES,
    OLD_DATABASE_PAGES,
    MODIFIED_DATABASE_PAGES,
    PENDING_DECOMPRESS,
    PENDING_READS,
    PENDING_FLUSH_LRU,
    PENDING_FLUSH_LIST
FROM INFORMATION_SCHEMA.INNODB_BUFFER_POOL_STATS;

-- Configuración óptima (en my.cnf)
[mysqld]
# Buffer pool = 70-80% de RAM total
innodb_buffer_pool_size = 8G
# Múltiples instancias para reducir contención
innodb_buffer_pool_instances = 8
# Preload buffer pool al inicio
innodb_buffer_pool_load_at_startup = 1
innodb_buffer_pool_dump_at_shutdown = 1
```

#### **Query Cache Optimization (MySQL < 8.0):**
```sql
-- Análisis del query cache
SHOW STATUS LIKE 'Qcache%';

-- Configuración óptima
SET GLOBAL query_cache_size = 268435456; -- 256MB
SET GLOBAL query_cache_type = 1;
SET GLOBAL query_cache_limit = 2097152; -- 2MB

-- IMPORTANTE: Query cache fue removido en MySQL 8.0
-- Usar ProxySQL o similar para caching en MySQL 8.0+
```

### **PostgreSQL OnPrem - Tuning Avanzado**

#### **Shared Buffers Optimization:**
```sql
-- Análisis de buffer usage
SELECT 
    c.relname,
    count(*) as buffers
FROM pg_buffercache b
INNER JOIN pg_class c ON b.relfilenode = pg_relation_filenode(c.oid)
WHERE b.reldatabase IN (
    SELECT oid FROM pg_database WHERE datname = current_database()
)
GROUP BY c.relname
ORDER BY 2 DESC
LIMIT 20;

-- Configuración óptima (postgresql.conf)
shared_buffers = 2GB                    # 25% de RAM
effective_cache_size = 6GB              # 75% de RAM
work_mem = 256MB                        # Para sorts/joins
maintenance_work_mem = 1GB              # Para VACUUM, CREATE INDEX
```

#### **WAL Optimization:**
```sql
-- Configuración WAL para performance
wal_buffers = 64MB
checkpoint_completion_target = 0.9
checkpoint_timeout = 15min
max_wal_size = 4GB
min_wal_size = 1GB

-- Para workloads de escritura intensiva
synchronous_commit = off                # CUIDADO: puede perder transacciones
wal_compression = on                    # PostgreSQL 9.5+
```

### **RDS - Optimización Limitada**

#### **Parameter Groups - Lo Máximo Que Puedes Hacer:**
```bash
# MySQL RDS - Parámetros clave
aws rds modify-db-parameter-group \
    --db-parameter-group-name mydb-params \
    --parameters \
        ParameterName=innodb_buffer_pool_size,ParameterValue="{DBInstanceClassMemory*3/4}",ApplyMethod=pending-reboot \
        ParameterName=max_connections,ParameterValue=200,ApplyMethod=immediate

# PostgreSQL RDS - Parámetros clave
aws rds modify-db-parameter-group \
    --db-parameter-group-name mydb-params \
    --parameters \
        ParameterName=shared_buffers,ParameterValue="{DBInstanceClassMemory/4}",ApplyMethod=pending-reboot \
        ParameterName=work_mem,ParameterValue=4096,ApplyMethod=immediate
```

#### **Limitaciones Críticas en RDS:**
```bash
# NO puedes optimizar:
# - Configuración del SO (kernel parameters)
# - Filesystem (mount options, scheduler)
# - Hardware específico (RAID, SSD vs HDD)
# - Memoria a nivel de SO
# - Network stack tuning

# Solo puedes optimizar:
# - Parámetros de la base de datos
# - Instance class (scale up/down)
# - Storage type (gp2, gp3, io1, io2)
```

---

## 🚨 **PROBLEMAS CRÍTICOS QUE MUCHOS NO DETECTAN**

### **1. Memory Leaks en Aplicaciones**

#### **Síntomas OnPrem:**
```bash
# Conexiones que crecen constantemente
mysql -e "SHOW STATUS LIKE 'Threads_connected';"
# Si crece sin parar = memory leak en app

# Memoria de procesos DB creciendo
ps aux | grep mysqld | awk '{print $6}' # RSS memory
# Si crece constantemente = problema
```

#### **Síntomas RDS:**
```bash
# CloudWatch metrics
aws cloudwatch get-metric-statistics \
    --namespace AWS/RDS \
    --metric-name DatabaseConnections
# Si crece sin parar = memory leak

# FreeableMemory decreciendo constantemente
aws cloudwatch get-metric-statistics \
    --namespace AWS/RDS \
    --metric-name FreeableMemory
```

### **2. Fragmentación de Índices (Muy Común)**

#### **MySQL OnPrem - Detección:**
```sql
-- Fragmentación de tablas InnoDB
SELECT 
    table_schema,
    table_name,
    ROUND(data_length/1024/1024, 2) as data_mb,
    ROUND(index_length/1024/1024, 2) as index_mb,
    ROUND(data_free/1024/1024, 2) as free_mb,
    ROUND(data_free/(data_length+index_length+data_free)*100, 2) as fragmentation_pct
FROM information_schema.tables 
WHERE table_schema NOT IN ('information_schema', 'mysql', 'performance_schema')
AND data_free > 0
ORDER BY fragmentation_pct DESC;

-- Solución: OPTIMIZE TABLE (bloquea la tabla)
OPTIMIZE TABLE fragmented_table;
-- O mejor: ALTER TABLE fragmented_table ENGINE=InnoDB; (online en MySQL 5.6+)
```

#### **PostgreSQL OnPrem - Detección:**
```sql
-- Bloat en tablas
SELECT 
    schemaname,
    tablename,
    n_tup_ins,
    n_tup_upd,
    n_tup_del,
    n_dead_tup,
    ROUND(100 * n_dead_tup / (n_tup_ins + n_tup_upd + n_tup_del), 2) as dead_tuple_pct
FROM pg_stat_user_tables
WHERE n_tup_ins + n_tup_upd + n_tup_del > 0
ORDER BY dead_tuple_pct DESC;

-- Solución: VACUUM FULL (bloquea) o pg_repack (online)
VACUUM FULL bloated_table;
```

### **3. Slow Query Log Overflow**

#### **OnPrem - Problema Común:**
```bash
# Slow query log llenando disco
ls -lh /var/log/mysql/slow.log
# Si es > 1GB, tienes problema

# Solución temporal
mysql -e "SET GLOBAL slow_query_log = 'OFF';"
mv /var/log/mysql/slow.log /var/log/mysql/slow.log.old
mysql -e "SET GLOBAL slow_query_log = 'ON';"
```

#### **RDS - Problema de Costos:**
```bash
# Logs en CloudWatch pueden generar costos altos
# Si slow_query_log está habilitado y tienes muchas queries lentas
# Solución: Filtrar logs o deshabilitar temporalmente
```

---

## 📋 **CHECKLIST DE TROUBLESHOOTING AVANZADO**

### **Cuando Performance se Degrada Súbitamente:**

#### **Paso 1 - Verificación Inmediata (2 minutos):**
- [ ] ✅ Verificar conexiones activas
- [ ] ✅ Verificar procesos bloqueados
- [ ] ✅ Verificar espacio en disco
- [ ] ✅ Verificar memoria disponible

#### **Paso 2 - Análisis de Sistema (5 minutos):**
- [ ] ✅ Verificar CPU usage
- [ ] ✅ Verificar I/O wait
- [ ] ✅ Verificar network usage
- [ ] ✅ Verificar logs de error

#### **Paso 3 - Análisis de Base de Datos (10 minutos):**
- [ ] ✅ Analizar queries activas
- [ ] ✅ Verificar locks y deadlocks
- [ ] ✅ Analizar wait events
- [ ] ✅ Verificar buffer pool/cache hit ratio

#### **Paso 4 - Análisis Profundo (30 minutos):**
- [ ] ✅ Analizar slow query log
- [ ] ✅ Verificar fragmentación
- [ ] ✅ Analizar plan de ejecución de queries problemáticas
- [ ] ✅ Verificar estadísticas de tablas

### **Herramientas por Plataforma:**

#### **OnPrem Tools:**
```bash
# Sistema
top, htop, iostat, sar, vmstat, netstat

# MySQL
mysqladmin, pt-query-digest, pt-online-schema-change, 
percona-toolkit, mysql-sys schema

# PostgreSQL
pg_stat_statements, pgbadger, pg_stat_activity,
pg_locks, pg_stat_user_tables
```

#### **RDS Tools:**
```bash
# AWS Native
Performance Insights, Enhanced Monitoring, CloudWatch,
RDS Events, Parameter Groups

# Third-party
DataDog, New Relic, AppDynamics, Percona Monitoring
```

---

## 🎯 **CONCLUSIONES PARA DBAs AVANZADOS**

### **Diferencias Clave en Troubleshooting:**

1. **OnPrem:** Control total pero responsabilidad total
2. **RDS:** Herramientas limitadas pero especializadas
3. **Híbrido:** Requiere dominio de ambos enfoques

### **Skills Críticos para DBAs Senior:**

1. **Análisis de Wait Events** - Diferencia entre junior y senior
2. **Correlación de Métricas** - Sistema + Base de Datos
3. **Optimización Proactiva** - No solo reactiva
4. **Automatización** - Scripts y alertas inteligentes

### **Recomendación Final:**
**Un DBA senior debe poder diagnosticar problemas complejos en ambos entornos, entender las limitaciones de cada plataforma, y diseñar soluciones que aprovechen las fortalezas específicas de cada una.**
