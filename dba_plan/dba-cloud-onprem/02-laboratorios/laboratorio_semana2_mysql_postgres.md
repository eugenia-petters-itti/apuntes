# Laboratorio Semana 2 - MySQL y PostgreSQL Avanzado
## DBA Cloud OnPrem Junior

### 🎯 Objetivos del Laboratorio
Al finalizar este laboratorio, el estudiante será capaz de:
- Crear y gestionar usuarios con diferentes niveles de permisos
- Realizar backups lógicos y físicos en ambos entornos
- Configurar y analizar herramientas de monitoreo OnPrem
- Optimizar parámetros de configuración para hardware específico
- Identificar y resolver problemas de performance

### 🖥️ Infraestructura Requerida
```yaml
# OnPrem (de laboratorios anteriores)
VM1 - MySQL OnPrem: Funcionando con datos de prueba
VM2 - PostgreSQL OnPrem: Funcionando con datos de prueba

# Cloud (de laboratorio anterior)
RDS MySQL: Funcionando
RDS PostgreSQL: Funcionando

# Herramientas adicionales
- Percona XtraBackup para MySQL
- MySQLTuner
- pgBadger para PostgreSQL
- pt-query-digest (Percona Toolkit)
```

---

## 📋 Laboratorio 1: Gestión Avanzada de Usuarios MySQL

### Paso 1: Instalación de Herramientas OnPrem
```bash
# En VM1 (MySQL OnPrem)
# Instalar Percona XtraBackup
wget https://repo.percona.com/apt/percona-release_latest.$(lsb_release -sc)_all.deb
sudo dpkg -i percona-release_latest.$(lsb_release -sc)_all.deb
sudo apt update
sudo apt install -y percona-xtrabackup-80

# Instalar MySQLTuner
wget http://mysqltuner.pl/ -O mysqltuner.pl
chmod +x mysqltuner.pl

# Instalar Percona Toolkit
sudo apt install -y percona-toolkit

# Verificar instalaciones
xtrabackup --version
perl mysqltuner.pl --help
pt-query-digest --version
```

### Paso 2: Crear Estructura de Usuarios Empresarial
```sql
-- Conectar a MySQL OnPrem
mysql -u root -p

-- Crear usuarios por roles
-- 1. DBA Senior (todos los privilegios)
CREATE USER 'dba_senior'@'%' IDENTIFIED BY 'DBAPass123!';
GRANT ALL PRIVILEGES ON *.* TO 'dba_senior'@'%' WITH GRANT OPTION;

-- 2. DBA Junior (privilegios limitados)
CREATE USER 'dba_junior'@'%' IDENTIFIED BY 'JuniorPass123!';
GRANT SELECT, INSERT, UPDATE, DELETE, CREATE, DROP, INDEX, ALTER ON *.* TO 'dba_junior'@'%';
GRANT SHOW DATABASES, SHOW VIEW, CREATE ROUTINE, ALTER ROUTINE ON *.* TO 'dba_junior'@'%';

-- 3. Developer (solo desarrollo)
CREATE USER 'developer'@'%' IDENTIFIED BY 'DevPass123!';
GRANT SELECT, INSERT, UPDATE, DELETE ON ecommerce_lab.* TO 'developer'@'%';
GRANT CREATE TEMPORARY TABLES ON ecommerce_lab.* TO 'developer'@'%';

-- 4. Analyst (solo lectura)
CREATE USER 'analyst'@'%' IDENTIFIED BY 'AnalystPass123!';
GRANT SELECT ON ecommerce_lab.* TO 'analyst'@'%';

-- 5. Application User (específico para app)
CREATE USER 'app_ecommerce'@'%' IDENTIFIED BY 'AppPass123!';
GRANT SELECT, INSERT, UPDATE, DELETE ON ecommerce_lab.customers TO 'app_ecommerce'@'%';
GRANT SELECT, INSERT, UPDATE, DELETE ON ecommerce_lab.orders TO 'app_ecommerce'@'%';
GRANT SELECT ON ecommerce_lab.products TO 'app_ecommerce'@'%';

-- 6. Backup User (solo para backups)
CREATE USER 'backup_user'@'localhost' IDENTIFIED BY 'BackupPass123!';
GRANT SELECT, LOCK TABLES, SHOW VIEW, EVENT, TRIGGER ON *.* TO 'backup_user'@'localhost';
GRANT RELOAD, PROCESS ON *.* TO 'backup_user'@'localhost';

FLUSH PRIVILEGES;

-- Verificar usuarios creados
SELECT user, host, account_locked, password_expired FROM mysql.user WHERE user NOT IN ('mysql.sys', 'mysql.session', 'mysql.infoschema');
```

### Paso 3: Probar Permisos de Usuarios
```bash
# Probar cada usuario
# Developer - debe poder hacer CRUD en ecommerce_lab
mysql -u developer -p -e "USE ecommerce_lab; SELECT COUNT(*) FROM customers;"
mysql -u developer -p -e "USE ecommerce_lab; INSERT INTO customers (name, email) VALUES ('Test User', 'test@test.com');"

# Analyst - solo lectura
mysql -u analyst -p -e "USE ecommerce_lab; SELECT COUNT(*) FROM orders;"
mysql -u analyst -p -e "USE ecommerce_lab; INSERT INTO customers (name, email) VALUES ('Should Fail', 'fail@test.com');" # Debe fallar

# App user - permisos específicos
mysql -u app_ecommerce -p -e "USE ecommerce_lab; SELECT * FROM customers LIMIT 5;"
mysql -u app_ecommerce -p -e "USE ecommerce_lab; UPDATE products SET price = 999.99 WHERE id = 1;" # Debe fallar
```

---

## 📋 Laboratorio 2: Backups Avanzados MySQL

### Paso 1: Backup Lógico con mysqldump
```bash
# Backup completo con opciones avanzadas
mysqldump -u backup_user -p \
    --single-transaction \
    --routines \
    --triggers \
    --events \
    --all-databases \
    --master-data=2 \
    --flush-logs \
    --hex-blob \
    --complete-insert > /backup/mysql/full_backup_$(date +%Y%m%d_%H%M%S).sql

# Backup de solo estructura
mysqldump -u backup_user -p \
    --no-data \
    --routines \
    --triggers \
    --events \
    ecommerce_lab > /backup/mysql/schema_only_$(date +%Y%m%d_%H%M%S).sql

# Backup de solo datos
mysqldump -u backup_user -p \
    --no-create-info \
    --complete-insert \
    ecommerce_lab > /backup/mysql/data_only_$(date +%Y%m%d_%H%M%S).sql

# Backup comprimido
mysqldump -u backup_user -p \
    --single-transaction \
    --all-databases | gzip > /backup/mysql/compressed_backup_$(date +%Y%m%d_%H%M%S).sql.gz
```

### Paso 2: Backup Físico con XtraBackup
```bash
# Crear directorio de backup
sudo mkdir -p /backup/mysql/xtrabackup
sudo chown mysql:mysql /backup/mysql/xtrabackup

# Backup completo con XtraBackup
sudo xtrabackup \
    --backup \
    --target-dir=/backup/mysql/xtrabackup/full_$(date +%Y%m%d_%H%M%S) \
    --user=backup_user \
    --password='BackupPass123!'

# Preparar backup para restore
BACKUP_DIR="/backup/mysql/xtrabackup/full_$(date +%Y%m%d)_*"
sudo xtrabackup --prepare --target-dir=$BACKUP_DIR

# Backup incremental (después del full)
sudo xtrabackup \
    --backup \
    --target-dir=/backup/mysql/xtrabackup/inc_$(date +%Y%m%d_%H%M%S) \
    --incremental-basedir=$BACKUP_DIR \
    --user=backup_user \
    --password='BackupPass123!'
```

### Paso 3: Prueba de Restauración
```bash
# Crear base de datos de prueba para restore
mysql -u root -p -e "CREATE DATABASE restore_test;"

# Restaurar desde mysqldump
mysql -u root -p restore_test < /backup/mysql/schema_only_*.sql

# Para XtraBackup (requiere detener MySQL)
# CUIDADO: Solo en entorno de prueba
sudo systemctl stop mysql
sudo rm -rf /var/lib/mysql/*
sudo xtrabackup --copy-back --target-dir=$BACKUP_DIR
sudo chown -R mysql:mysql /var/lib/mysql
sudo systemctl start mysql
```

---

## 📋 Laboratorio 3: Gestión Avanzada de Usuarios PostgreSQL

### Paso 1: Instalación de Herramientas OnPrem
```bash
# En VM2 (PostgreSQL OnPrem)
# Instalar pgBadger
sudo apt install -y pgbadger

# Instalar herramientas adicionales
sudo apt install -y postgresql-contrib

# Verificar instalación
pgbadger --version
```

### Paso 2: Configurar Logging para Análisis
```bash
# Editar postgresql.conf
sudo vim /etc/postgresql/12/main/postgresql.conf

# Agregar/modificar estas líneas:
log_destination = 'csvlog'
logging_collector = on
log_directory = 'pg_log'
log_filename = 'postgresql-%Y-%m-%d_%H%M%S.log'
log_rotation_age = 1d
log_rotation_size = 100MB
log_min_duration_statement = 1000  # Log queries > 1 segundo
log_line_prefix = '%t [%p]: [%l-1] user=%u,db=%d,app=%a,client=%h '
log_checkpoints = on
log_connections = on
log_disconnections = on
log_lock_waits = on
log_statement = 'ddl'

# Reiniciar PostgreSQL
sudo systemctl restart postgresql
```

### Paso 3: Crear Estructura de Usuarios PostgreSQL
```sql
-- Conectar como postgres
sudo -u postgres psql

-- Crear roles base
CREATE ROLE dba_role;
CREATE ROLE developer_role;
CREATE ROLE analyst_role;
CREATE ROLE app_role;

-- Configurar permisos de roles
-- DBA Role
GRANT CONNECT ON DATABASE testdb TO dba_role;
GRANT CREATE ON DATABASE testdb TO dba_role;
GRANT USAGE, CREATE ON SCHEMA public TO dba_role;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO dba_role;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO dba_role;

-- Developer Role
GRANT CONNECT ON DATABASE testdb TO developer_role;
GRANT USAGE ON SCHEMA public TO developer_role;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO developer_role;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO developer_role;

-- Analyst Role (solo lectura)
GRANT CONNECT ON DATABASE testdb TO analyst_role;
GRANT USAGE ON SCHEMA public TO analyst_role;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO analyst_role;

-- App Role (específico)
GRANT CONNECT ON DATABASE testdb TO app_role;
GRANT USAGE ON SCHEMA public TO app_role;
GRANT SELECT, INSERT, UPDATE, DELETE ON customers, orders TO app_role;
GRANT SELECT ON products TO app_role;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO app_role;

-- Crear usuarios y asignar roles
CREATE USER dba_senior WITH PASSWORD 'DBAPass123!' IN ROLE dba_role;
CREATE USER dba_junior WITH PASSWORD 'JuniorPass123!' IN ROLE developer_role;
CREATE USER developer WITH PASSWORD 'DevPass123!' IN ROLE developer_role;
CREATE USER analyst WITH PASSWORD 'AnalystPass123!' IN ROLE analyst_role;
CREATE USER app_ecommerce WITH PASSWORD 'AppPass123!' IN ROLE app_role;

-- Usuario específico para backups
CREATE USER backup_user WITH PASSWORD 'BackupPass123!' REPLICATION;

-- Verificar usuarios y roles
\du
```

---

## 📋 Laboratorio 4: Backups Avanzados PostgreSQL

### Paso 1: Backup Lógico con pg_dump
```bash
# Backup completo de base de datos
pg_dump -U postgres -h localhost -d testdb \
    --verbose \
    --format=custom \
    --compress=9 \
    --file=/backup/postgres/testdb_full_$(date +%Y%m%d_%H%M%S).backup

# Backup de solo esquema
pg_dump -U postgres -h localhost -d testdb \
    --schema-only \
    --verbose \
    --file=/backup/postgres/testdb_schema_$(date +%Y%m%d_%H%M%S).sql

# Backup de solo datos
pg_dump -U postgres -h localhost -d testdb \
    --data-only \
    --verbose \
    --format=custom \
    --file=/backup/postgres/testdb_data_$(date +%Y%m%d_%H%M%S).backup

# Backup de todas las bases de datos
pg_dumpall -U postgres -h localhost \
    --verbose \
    --file=/backup/postgres/cluster_full_$(date +%Y%m%d_%H%M%S).sql

# Backup de solo roles y tablespaces
pg_dumpall -U postgres -h localhost \
    --roles-only \
    --file=/backup/postgres/roles_$(date +%Y%m%d_%H%M%S).sql
```

### Paso 2: Backup Físico con pg_basebackup
```bash
# Crear directorio para backup físico
sudo mkdir -p /backup/postgres/basebackup
sudo chown postgres:postgres /backup/postgres/basebackup

# Configurar replicación en postgresql.conf
sudo vim /etc/postgresql/12/main/postgresql.conf
# Agregar:
# wal_level = replica
# max_wal_senders = 3
# wal_keep_segments = 64

# Configurar pg_hba.conf para replicación
sudo vim /etc/postgresql/12/main/pg_hba.conf
# Agregar:
# local   replication     backup_user                     md5

# Reiniciar PostgreSQL
sudo systemctl restart postgresql

# Realizar backup físico
sudo -u postgres pg_basebackup \
    -D /backup/postgres/basebackup/base_$(date +%Y%m%d_%H%M%S) \
    -U backup_user \
    -v \
    -P \
    -W \
    -X stream
```

### Paso 3: Configurar WAL Archiving
```bash
# Crear directorio para WAL archives
sudo mkdir -p /backup/postgres/wal_archive
sudo chown postgres:postgres /backup/postgres/wal_archive

# Configurar archiving en postgresql.conf
sudo vim /etc/postgresql/12/main/postgresql.conf
# Modificar:
# archive_mode = on
# archive_command = 'cp %p /backup/postgres/wal_archive/%f'

# Reiniciar PostgreSQL
sudo systemctl restart postgresql

# Verificar archiving
sudo -u postgres psql -c "SELECT pg_switch_wal();"
ls -la /backup/postgres/wal_archive/
```

---

## 📋 Laboratorio 5: Monitoreo y Tuning

### Paso 1: Análisis con MySQLTuner
```bash
# Ejecutar MySQLTuner en MySQL OnPrem
cd /home/student
./mysqltuner.pl --user root --pass 'MyS3cur3P@ss!'

# Generar reporte detallado
./mysqltuner.pl --user root --pass 'MyS3cur3P@ss!' --outputfile mysql_tuning_report.txt

# Analizar recomendaciones y aplicar cambios
sudo vim /etc/mysql/mysql.conf.d/mysqld.cnf

# Ejemplo de optimizaciones basadas en reporte:
# innodb_buffer_pool_size = 2G  # 70-80% de RAM disponible
# innodb_log_file_size = 256M
# max_connections = 150
# query_cache_size = 64M
# tmp_table_size = 64M
# max_heap_table_size = 64M

# Reiniciar MySQL
sudo systemctl restart mysql
```

### Paso 2: Análisis de Queries con pt-query-digest
```bash
# Habilitar slow query log si no está habilitado
mysql -u root -p -e "SET GLOBAL slow_query_log = 'ON';"
mysql -u root -p -e "SET GLOBAL long_query_time = 1;"

# Generar algunas queries lentas para análisis
mysql -u developer -p ecommerce_lab -e "
SELECT c.name, COUNT(o.id) as order_count, SUM(o.total) as total_spent
FROM customers c 
LEFT JOIN orders o ON c.id = o.customer_id 
GROUP BY c.id, c.name 
ORDER BY total_spent DESC;"

# Analizar slow query log
pt-query-digest /var/log/mysql/slow.log > mysql_slow_query_analysis.txt

# Ver top queries
head -50 mysql_slow_query_analysis.txt
```

### Paso 3: Análisis con pgBadger
```bash
# Generar actividad en PostgreSQL para análisis
psql -U developer -d testdb -c "
SELECT c.name, COUNT(o.id) as order_count, SUM(o.total) as total_spent
FROM customers c 
LEFT JOIN orders o ON c.customer_id = o.id 
GROUP BY c.id, c.name 
ORDER BY total_spent DESC;"

# Ejecutar pgBadger
pgbadger /var/log/postgresql/postgresql-*.log -o /tmp/pgbadger_report.html

# Ver reporte (copiar a máquina local para ver en browser)
echo "Reporte generado en: /tmp/pgbadger_report.html"
```

### Paso 4: Monitoreo en Tiempo Real
```sql
-- MySQL - Monitoreo de procesos activos
-- Ejecutar en una terminal separada
mysql -u root -p -e "
SELECT 
    ID, USER, HOST, DB, COMMAND, TIME, STATE, 
    LEFT(INFO, 50) as QUERY_START
FROM INFORMATION_SCHEMA.PROCESSLIST 
WHERE COMMAND != 'Sleep' 
ORDER BY TIME DESC;"

-- PostgreSQL - Monitoreo de actividad
sudo -u postgres psql -c "
SELECT 
    pid, usename, datname, client_addr, state, 
    query_start, LEFT(query, 50) as query_start
FROM pg_stat_activity 
WHERE state != 'idle' 
ORDER BY query_start DESC;"
```

---

## 🧪 Ejercicios de Evaluación

### Ejercicio 1: Gestión de Usuarios (25 puntos)
**Tiempo límite: 45 minutos**

**Tarea MySQL:** Crear un usuario `report_user` que solo pueda:
- Leer todas las tablas de `ecommerce_lab`
- Ejecutar SELECT con JOIN
- NO puede INSERT, UPDATE, DELETE
- NO puede acceder a otras bases de datos

**Tarea PostgreSQL:** Crear un usuario `maintenance_user` que pueda:
- Conectar a `testdb`
- Crear y eliminar índices
- Analizar tablas (ANALYZE)
- NO puede modificar datos

```sql
-- Solución esperada MySQL:
CREATE USER 'report_user'@'%' IDENTIFIED BY 'ReportPass123!';
GRANT SELECT ON ecommerce_lab.* TO 'report_user'@'%';
FLUSH PRIVILEGES;

-- Solución esperada PostgreSQL:
CREATE USER maintenance_user WITH PASSWORD 'MaintenancePass123!';
GRANT CONNECT ON DATABASE testdb TO maintenance_user;
GRANT USAGE ON SCHEMA public TO maintenance_user;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO maintenance_user;
-- Permisos adicionales para mantenimiento
```

**Criterios de evaluación:**
- Usuario creado correctamente (10 pts)
- Permisos asignados según especificación (10 pts)
- Verificación de restricciones (5 pts)

### Ejercicio 2: Backup y Restore (30 puntos)
**Tiempo límite: 60 minutos**

**Tarea:** 
1. Realizar backup físico de MySQL con XtraBackup
2. Realizar backup lógico de PostgreSQL con pg_dump
3. Simular pérdida de datos y restaurar

```bash
# Pasos esperados:
# 1. Backup físico MySQL
sudo xtrabackup --backup --target-dir=/backup/eval/mysql_backup --user=backup_user --password='BackupPass123!'

# 2. Backup PostgreSQL
pg_dump -U postgres -d testdb --format=custom --file=/backup/eval/postgres_backup.backup

# 3. Simular pérdida y restaurar
# (Instrucciones específicas proporcionadas durante el examen)
```

**Criterios de evaluación:**
- Backup físico MySQL exitoso (10 pts)
- Backup lógico PostgreSQL exitoso (10 pts)
- Restauración funcional (10 pts)

### Ejercicio 3: Análisis de Performance (25 puntos)
**Tiempo límite: 45 minutos**

**Tarea:** Usar MySQLTuner y pgBadger para analizar performance y proponer 3 optimizaciones específicas para cada motor.

**Entregable esperado:**
```markdown
## Análisis MySQL
### Problemas identificados:
1. [Problema específico del reporte MySQLTuner]
2. [Problema específico del reporte MySQLTuner]
3. [Problema específico del reporte MySQLTuner]

### Optimizaciones propuestas:
1. [Parámetro] = [Valor] - Razón: [Explicación]
2. [Parámetro] = [Valor] - Razón: [Explicación]
3. [Parámetro] = [Valor] - Razón: [Explicación]

## Análisis PostgreSQL
### Problemas identificados:
[Similar estructura]
```

**Criterios de evaluación:**
- Ejecuta herramientas correctamente (10 pts)
- Identifica problemas reales (10 pts)
- Propone optimizaciones válidas (5 pts)

### Ejercicio 4: Troubleshooting de Conectividad (20 puntos)
**Tiempo límite: 30 minutos**

**Escenario:** Se han introducido los siguientes problemas:
1. Usuario `developer` no puede conectar a MySQL
2. PostgreSQL rechaza conexiones remotas
3. Backup user no tiene permisos suficientes

```bash
# Comandos de diagnóstico esperados:
mysql -u developer -p -e "SELECT USER();"
psql -U developer -h postgres_vm_ip -d testdb -c "SELECT current_user;"
mysql -u backup_user -p -e "SHOW GRANTS FOR CURRENT_USER();"

# Verificación de configuración
sudo cat /etc/mysql/mysql.conf.d/mysqld.cnf | grep bind-address
sudo cat /etc/postgresql/12/main/pg_hba.conf | grep -v "^#"
```

**Criterios de evaluación:**
- Identifica todos los problemas (10 pts)
- Aplica soluciones correctas (10 pts)

---

## 📊 Rúbrica de Evaluación Final

### Distribución de Puntos
- **Ejercicio 1 - Gestión de usuarios:** 25 puntos
- **Ejercicio 2 - Backup y restore:** 30 puntos
- **Ejercicio 3 - Análisis de performance:** 25 puntos
- **Ejercicio 4 - Troubleshooting:** 20 puntos
- **Total:** 100 puntos

### Criterios de Aprobación
- **Excelente (90-100):** Domina gestión avanzada de usuarios, backups físicos/lógicos, y herramientas de análisis
- **Bueno (80-89):** Maneja conceptos básicos correctamente, requiere ayuda mínima en tareas avanzadas
- **Regular (70-79):** Ejecuta tareas básicas, dificultades con herramientas avanzadas
- **Insuficiente (<70):** No logra gestión básica de usuarios o backups

---

## 📝 Entregables del Laboratorio

### 1. Reporte de Configuración de Usuarios
```markdown
# Reporte Gestión de Usuarios - Semana 2
## Estudiante: [Nombre]

### MySQL Users Created
| Usuario | Host | Permisos | Propósito |
|---------|------|----------|-----------|
| dba_senior | % | ALL PRIVILEGES | Administración completa |
| developer | % | CRUD en ecommerce_lab | Desarrollo |
| analyst | % | SELECT en ecommerce_lab | Análisis |

### PostgreSQL Users Created
| Usuario | Roles | Base de Datos | Propósito |
|---------|-------|---------------|-----------|
| dba_senior | dba_role | testdb | Administración |
| developer | developer_role | testdb | Desarrollo |

### Pruebas de Permisos
- [ ] Developer puede hacer CRUD
- [ ] Analyst solo puede SELECT
- [ ] App user tiene permisos específicos
```

### 2. Scripts de Backup
```bash
#!/bin/bash
# mysql_backup_script.sh
# Script automatizado de backup MySQL

BACKUP_DIR="/backup/mysql"
DATE=$(date +%Y%m%d_%H%M%S)

# Backup lógico
mysqldump -u backup_user -p'BackupPass123!' \
    --single-transaction \
    --all-databases > $BACKUP_DIR/logical_$DATE.sql

# Backup físico
xtrabackup --backup \
    --target-dir=$BACKUP_DIR/physical_$DATE \
    --user=backup_user \
    --password='BackupPass123!'

echo "Backups completados: $DATE"
```

### 3. Reportes de Análisis
- Reporte MySQLTuner completo
- Análisis pt-query-digest
- Reporte pgBadger (HTML)
- Recomendaciones de optimización

Este laboratorio proporciona experiencia práctica profunda en administración avanzada de MySQL y PostgreSQL, preparando a los estudiantes para tareas reales de DBA en entornos de producción.
