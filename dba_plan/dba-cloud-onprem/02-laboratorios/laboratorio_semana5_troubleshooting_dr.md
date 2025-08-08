# Laboratorio Semana 5 - Troubleshooting y Disaster Recovery
## DBA Cloud OnPrem Junior

### 🎯 Objetivos del Laboratorio
Al finalizar este laboratorio, el estudiante será capaz de:
- Diagnosticar y resolver problemas complejos OnPrem
- Ejecutar procedimientos completos de disaster recovery
- Configurar alta disponibilidad híbrida
- Simular y recuperarse de fallos críticos
- Documentar procedimientos de contingencia

### 🖥️ Infraestructura Requerida
```yaml
# Todas las VMs de laboratorios anteriores
VM1 - MySQL OnPrem: Con datos críticos
VM2 - PostgreSQL OnPrem: Con datos críticos
VM3 - MongoDB OnPrem: Con datos críticos
VM4 - Monitoring Server: Prometheus + Grafana funcionando

# AWS Cloud
RDS MySQL: Funcionando como backup secundario
RDS PostgreSQL: Funcionando como backup secundario
DocumentDB: Funcionando como backup secundario

# Herramientas adicionales
- Scripts de simulación de fallos
- Herramientas de recovery
- Documentación de procedimientos
```

---

## 📋 Laboratorio 1: Preparación de Escenarios de Fallo

### Paso 1: Crear Datos Críticos de Prueba
```sql
-- En MySQL OnPrem (VM1)
mysql -u root -p

CREATE DATABASE critical_app;
USE critical_app;

CREATE TABLE transactions (
    id INT PRIMARY KEY AUTO_INCREMENT,
    user_id INT NOT NULL,
    amount DECIMAL(10,2) NOT NULL,
    transaction_type ENUM('credit', 'debit') NOT NULL,
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    status ENUM('pending', 'completed', 'failed') DEFAULT 'pending',
    INDEX idx_user_timestamp (user_id, timestamp),
    INDEX idx_status (status)
);

CREATE TABLE user_balances (
    user_id INT PRIMARY KEY,
    current_balance DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- Insertar datos críticos
INSERT INTO user_balances (user_id, current_balance) VALUES
(1001, 5000.00), (1002, 3500.50), (1003, 7200.25), (1004, 1250.75), (1005, 9800.00);

INSERT INTO transactions (user_id, amount, transaction_type, status) VALUES
(1001, 500.00, 'debit', 'completed'),
(1002, 1000.00, 'credit', 'completed'),
(1003, 250.50, 'debit', 'pending'),
(1004, 750.25, 'credit', 'completed'),
(1005, 300.00, 'debit', 'failed');

-- Crear procedimiento crítico
DELIMITER //
CREATE PROCEDURE ProcessTransaction(
    IN p_user_id INT,
    IN p_amount DECIMAL(10,2),
    IN p_type ENUM('credit', 'debit')
)
BEGIN
    DECLARE current_bal DECIMAL(10,2);
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;
    
    START TRANSACTION;
    
    SELECT current_balance INTO current_bal 
    FROM user_balances 
    WHERE user_id = p_user_id FOR UPDATE;
    
    IF p_type = 'debit' AND current_bal < p_amount THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Insufficient funds';
    END IF;
    
    INSERT INTO transactions (user_id, amount, transaction_type, status)
    VALUES (p_user_id, p_amount, p_type, 'completed');
    
    IF p_type = 'credit' THEN
        UPDATE user_balances 
        SET current_balance = current_balance + p_amount 
        WHERE user_id = p_user_id;
    ELSE
        UPDATE user_balances 
        SET current_balance = current_balance - p_amount 
        WHERE user_id = p_user_id;
    END IF;
    
    COMMIT;
END //
DELIMITER ;
```

```sql
-- En PostgreSQL OnPrem (VM2)
sudo -u postgres psql

CREATE DATABASE critical_analytics;
\c critical_analytics

CREATE TABLE sales_data (
    id SERIAL PRIMARY KEY,
    product_id INTEGER NOT NULL,
    customer_id INTEGER NOT NULL,
    sale_amount DECIMAL(10,2) NOT NULL,
    sale_date DATE NOT NULL,
    region VARCHAR(50) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE daily_summaries (
    summary_date DATE PRIMARY KEY,
    total_sales DECIMAL(12,2) NOT NULL,
    transaction_count INTEGER NOT NULL,
    avg_transaction DECIMAL(10,2) NOT NULL,
    top_region VARCHAR(50),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Insertar datos críticos
INSERT INTO sales_data (product_id, customer_id, sale_amount, sale_date, region) VALUES
(101, 2001, 1500.00, '2024-01-15', 'North'),
(102, 2002, 2300.50, '2024-01-15', 'South'),
(103, 2003, 890.25, '2024-01-15', 'East'),
(104, 2004, 3200.75, '2024-01-15', 'West'),
(105, 2005, 1750.00, '2024-01-15', 'North');

-- Crear función crítica
CREATE OR REPLACE FUNCTION generate_daily_summary(p_date DATE)
RETURNS VOID AS $$
BEGIN
    INSERT INTO daily_summaries (
        summary_date, 
        total_sales, 
        transaction_count, 
        avg_transaction, 
        top_region
    )
    SELECT 
        p_date,
        SUM(sale_amount),
        COUNT(*),
        AVG(sale_amount),
        (SELECT region FROM sales_data WHERE sale_date = p_date 
         GROUP BY region ORDER BY SUM(sale_amount) DESC LIMIT 1)
    FROM sales_data 
    WHERE sale_date = p_date
    ON CONFLICT (summary_date) DO UPDATE SET
        total_sales = EXCLUDED.total_sales,
        transaction_count = EXCLUDED.transaction_count,
        avg_transaction = EXCLUDED.avg_transaction,
        top_region = EXCLUDED.top_region;
END;
$$ LANGUAGE plpgsql;

-- Ejecutar función
SELECT generate_daily_summary('2024-01-15');
```

### Paso 2: Configurar Replicación MySQL
```bash
# En VM1 (MySQL Master)
# Editar configuración MySQL
sudo vim /etc/mysql/mysql.conf.d/mysqld.cnf

# Agregar configuración de replicación
[mysqld]
server-id = 1
log-bin = mysql-bin
binlog-format = ROW
gtid-mode = ON
enforce-gtid-consistency = ON
log-slave-updates = ON
binlog-do-db = critical_app

# Reiniciar MySQL
sudo systemctl restart mysql

# Crear usuario de replicación
mysql -u root -p << 'EOF'
CREATE USER 'repl_user'@'%' IDENTIFIED BY 'ReplPass123!';
GRANT REPLICATION SLAVE ON *.* TO 'repl_user'@'%';
FLUSH PRIVILEGES;
SHOW MASTER STATUS;
EOF
```

### Paso 3: Configurar Streaming Replication PostgreSQL
```bash
# En VM2 (PostgreSQL Master)
# Editar postgresql.conf
sudo vim /etc/postgresql/12/main/postgresql.conf

# Configurar replicación
wal_level = replica
max_wal_senders = 3
max_replication_slots = 3
hot_standby = on
archive_mode = on
archive_command = 'cp %p /var/lib/postgresql/12/main/archive/%f'

# Crear directorio de archive
sudo mkdir -p /var/lib/postgresql/12/main/archive
sudo chown postgres:postgres /var/lib/postgresql/12/main/archive

# Editar pg_hba.conf
sudo vim /etc/postgresql/12/main/pg_hba.conf

# Agregar línea para replicación
host    replication     repl_user       0.0.0.0/0               md5

# Reiniciar PostgreSQL
sudo systemctl restart postgresql

# Crear usuario de replicación
sudo -u postgres psql << 'EOF'
CREATE USER repl_user WITH REPLICATION PASSWORD 'ReplPass123!';
SELECT pg_create_physical_replication_slot('replication_slot_1');
EOF
```

---

## 📋 Laboratorio 2: Simulación de Fallos Críticos

### Paso 1: Scripts de Simulación de Fallos
```bash
# Crear directorio para scripts de simulación
mkdir -p ~/disaster_simulation
cd ~/disaster_simulation

# Script 1: Simular fallo de disco MySQL
cat > simulate_mysql_disk_failure.sh << 'EOF'
#!/bin/bash
echo "=== SIMULANDO FALLO DE DISCO MYSQL ==="
echo "ADVERTENCIA: Este script simulará un fallo crítico"
read -p "¿Continuar? (yes/no): " confirm

if [ "$confirm" = "yes" ]; then
    echo "Simulando corrupción de tablespace..."
    sudo systemctl stop mysql
    
    # Simular corrupción (NO hacer en producción)
    sudo dd if=/dev/zero of=/var/lib/mysql/critical_app/transactions.ibd bs=1024 count=10 2>/dev/null
    
    echo "Fallo simulado. MySQL no podrá iniciar correctamente."
    echo "Usar script de recovery para restaurar."
else
    echo "Simulación cancelada."
fi
EOF

# Script 2: Simular fallo de red
cat > simulate_network_failure.sh << 'EOF'
#!/bin/bash
echo "=== SIMULANDO FALLO DE RED ==="
echo "Bloqueando puertos de base de datos..."

# Bloquear puertos
sudo iptables -A INPUT -p tcp --dport 3306 -j DROP
sudo iptables -A INPUT -p tcp --dport 5432 -j DROP
sudo iptables -A INPUT -p tcp --dport 27017 -j DROP

echo "Puertos bloqueados. Bases de datos inaccesibles desde red."
echo "Para restaurar: sudo iptables -F"
EOF

# Script 3: Simular fallo de memoria
cat > simulate_memory_pressure.sh << 'EOF'
#!/bin/bash
echo "=== SIMULANDO PRESIÓN DE MEMORIA ==="
echo "Creando proceso que consume memoria..."

# Crear proceso que consume memoria
stress --vm 1 --vm-bytes 3G --timeout 300s &
STRESS_PID=$!

echo "Proceso de stress iniciado (PID: $STRESS_PID)"
echo "Monitorear comportamiento de bases de datos"
echo "Para detener: kill $STRESS_PID"
EOF

# Script 4: Simular corrupción PostgreSQL
cat > simulate_postgres_corruption.sh << 'EOF'
#!/bin/bash
echo "=== SIMULANDO CORRUPCIÓN POSTGRESQL ==="
read -p "¿Continuar con simulación de corrupción? (yes/no): " confirm

if [ "$confirm" = "yes" ]; then
    sudo systemctl stop postgresql
    
    # Simular corrupción de archivo de datos
    sudo dd if=/dev/zero of=/var/lib/postgresql/12/main/base/$(sudo -u postgres psql -d critical_analytics -t -c "SELECT oid FROM pg_database WHERE datname='critical_analytics';")/$(sudo -u postgres psql -d critical_analytics -t -c "SELECT relfilenode FROM pg_class WHERE relname='sales_data';") bs=1024 count=5 2>/dev/null
    
    echo "Corrupción simulada en tabla sales_data"
    echo "PostgreSQL puede no iniciar o mostrar errores de corrupción"
else
    echo "Simulación cancelada."
fi
EOF

# Hacer scripts ejecutables
chmod +x *.sh
```

### Paso 2: Scripts de Diagnóstico
```bash
# Script de diagnóstico completo
cat > diagnose_system.sh << 'EOF'
#!/bin/bash
echo "=== DIAGNÓSTICO COMPLETO DEL SISTEMA ==="
echo "Fecha: $(date)"
echo

echo "=== ESTADO DE SERVICIOS ==="
systemctl status mysql --no-pager -l
echo
systemctl status postgresql --no-pager -l
echo
systemctl status mongod --no-pager -l
echo

echo "=== USO DE RECURSOS ==="
echo "CPU y Memoria:"
top -bn1 | head -20
echo

echo "Espacio en disco:"
df -h
echo

echo "=== CONECTIVIDAD DE RED ==="
echo "Puertos en escucha:"
netstat -tlnp | grep -E "(3306|5432|27017)"
echo

echo "=== LOGS RECIENTES ==="
echo "MySQL errors (últimas 20 líneas):"
sudo tail -20 /var/log/mysql/error.log 2>/dev/null || echo "Log no encontrado"
echo

echo "PostgreSQL errors (últimas 20 líneas):"
sudo tail -20 /var/log/postgresql/postgresql-12-main.log 2>/dev/null || echo "Log no encontrado"
echo

echo "MongoDB errors (últimas 20 líneas):"
sudo tail -20 /var/log/mongodb/mongod.log 2>/dev/null || echo "Log no encontrado"
echo

echo "=== VERIFICACIÓN DE INTEGRIDAD ==="
echo "Verificando conectividad a bases de datos..."

# Test MySQL
mysql -u root -p'MyS3cur3P@ss!' -e "SELECT 'MySQL OK' as status;" 2>/dev/null || echo "MySQL: ERROR"

# Test PostgreSQL
sudo -u postgres psql -c "SELECT 'PostgreSQL OK' as status;" 2>/dev/null || echo "PostgreSQL: ERROR"

# Test MongoDB
mongosh --quiet --eval "print('MongoDB OK')" 2>/dev/null || echo "MongoDB: ERROR"

echo
echo "=== DIAGNÓSTICO COMPLETADO ==="
EOF

chmod +x diagnose_system.sh
```

---

## 📋 Laboratorio 3: Procedimientos de Recovery

### Paso 1: Recovery MySQL desde Backup Físico
```bash
# Script de recovery MySQL
cat > mysql_disaster_recovery.sh << 'EOF'
#!/bin/bash
echo "=== PROCEDIMIENTO DE DISASTER RECOVERY MYSQL ==="

BACKUP_DIR="/backup/mysql/disaster_recovery"
MYSQL_DATA_DIR="/var/lib/mysql"

echo "1. Deteniendo MySQL..."
sudo systemctl stop mysql

echo "2. Respaldando datos corruptos..."
sudo mv $MYSQL_DATA_DIR ${MYSQL_DATA_DIR}_corrupted_$(date +%Y%m%d_%H%M%S)

echo "3. Restaurando desde backup físico..."
if [ -d "$BACKUP_DIR/latest" ]; then
    sudo cp -R $BACKUP_DIR/latest $MYSQL_DATA_DIR
    sudo chown -R mysql:mysql $MYSQL_DATA_DIR
    sudo chmod -R 750 $MYSQL_DATA_DIR
    
    echo "4. Iniciando MySQL..."
    sudo systemctl start mysql
    
    echo "5. Verificando integridad..."
    sleep 5
    mysql -u root -p'MyS3cur3P@ss!' -e "CHECK TABLE critical_app.transactions;" || echo "Verificación falló"
    
    echo "6. Verificando datos críticos..."
    mysql -u root -p'MyS3cur3P@ss!' -e "SELECT COUNT(*) as transaction_count FROM critical_app.transactions;"
    mysql -u root -p'MyS3cur3P@ss!' -e "SELECT SUM(current_balance) as total_balance FROM critical_app.user_balances;"
    
    echo "Recovery completado exitosamente"
else
    echo "ERROR: Backup no encontrado en $BACKUP_DIR/latest"
    echo "Creando backup de emergencia..."
    sudo mkdir -p $BACKUP_DIR/latest
    # En caso real, restaurar desde backup remoto o cloud
fi
EOF

chmod +x mysql_disaster_recovery.sh
```

### Paso 2: Recovery PostgreSQL con PITR
```bash
# Script de Point-in-Time Recovery PostgreSQL
cat > postgres_pitr_recovery.sh << 'EOF'
#!/bin/bash
echo "=== POINT-IN-TIME RECOVERY POSTGRESQL ==="

BACKUP_DIR="/backup/postgres/pitr"
PG_DATA_DIR="/var/lib/postgresql/12/main"
ARCHIVE_DIR="/var/lib/postgresql/12/main/archive"

read -p "Ingrese timestamp para recovery (YYYY-MM-DD HH:MM:SS): " RECOVERY_TIME

echo "1. Deteniendo PostgreSQL..."
sudo systemctl stop postgresql

echo "2. Respaldando datos actuales..."
sudo mv $PG_DATA_DIR ${PG_DATA_DIR}_backup_$(date +%Y%m%d_%H%M%S)

echo "3. Restaurando base backup..."
if [ -d "$BACKUP_DIR/base_backup" ]; then
    sudo cp -R $BACKUP_DIR/base_backup $PG_DATA_DIR
    sudo chown -R postgres:postgres $PG_DATA_DIR
    
    echo "4. Configurando recovery..."
    sudo -u postgres tee $PG_DATA_DIR/recovery.conf > /dev/null << EOF_RECOVERY
restore_command = 'cp $ARCHIVE_DIR/%f %p'
recovery_target_time = '$RECOVERY_TIME'
recovery_target_action = 'promote'
EOF_RECOVERY
    
    echo "5. Iniciando PostgreSQL en modo recovery..."
    sudo systemctl start postgresql
    
    echo "6. Esperando recovery..."
    sleep 10
    
    echo "7. Verificando recovery..."
    sudo -u postgres psql -d critical_analytics -c "SELECT COUNT(*) FROM sales_data;"
    sudo -u postgres psql -d critical_analytics -c "SELECT * FROM daily_summaries ORDER BY summary_date DESC LIMIT 5;"
    
    echo "PITR Recovery completado"
else
    echo "ERROR: Base backup no encontrado"
fi
EOF

chmod +x postgres_pitr_recovery.sh
```

### Paso 3: Recovery MongoDB con Replica Set
```bash
# Script de recovery MongoDB
cat > mongodb_recovery.sh << 'EOF'
#!/bin/bash
echo "=== RECOVERY MONGODB REPLICA SET ==="

BACKUP_DIR="/backup/mongodb/disaster"
MONGO_DATA_DIR="/var/lib/mongodb"

echo "1. Deteniendo MongoDB..."
sudo systemctl stop mongod

echo "2. Respaldando datos corruptos..."
sudo mv $MONGO_DATA_DIR ${MONGO_DATA_DIR}_corrupted_$(date +%Y%m%d_%H%M%S)
sudo mkdir -p $MONGO_DATA_DIR
sudo chown mongodb:mongodb $MONGO_DATA_DIR

echo "3. Restaurando desde backup..."
if [ -d "$BACKUP_DIR/latest" ]; then
    sudo mongorestore --dir $BACKUP_DIR/latest
    
    echo "4. Reinicializando replica set..."
    sudo systemctl start mongod
    sleep 5
    
    mongosh --eval "
    rs.initiate({
        _id: 'rs0',
        members: [{ _id: 0, host: 'localhost:27017' }]
    })
    "
    
    echo "5. Verificando datos..."
    mongosh --eval "
    use ecommerce_mongo
    print('Customers count:', db.customers.countDocuments())
    print('Products count:', db.products.countDocuments())
    print('Orders count:', db.orders.countDocuments())
    "
    
    echo "MongoDB recovery completado"
else
    echo "ERROR: Backup no encontrado"
fi
EOF

chmod +x mongodb_recovery.sh
```

---

## 📋 Laboratorio 4: Configuración de Alta Disponibilidad

### Paso 1: Configurar MySQL Master-Slave
```bash
# Script para configurar slave MySQL
cat > setup_mysql_slave.sh << 'EOF'
#!/bin/bash
echo "=== CONFIGURANDO MYSQL SLAVE ==="

# Configurar como slave del RDS (simulando HA híbrida)
RDS_ENDPOINT="terraform-mysql-lab.xxxxx.us-east-1.rds.amazonaws.com"

read -p "Ingrese endpoint del Master RDS: " MASTER_HOST
read -p "Ingrese posición del binlog: " MASTER_LOG_POS

mysql -u root -p << EOF_SQL
STOP SLAVE;
CHANGE MASTER TO
    MASTER_HOST='$MASTER_HOST',
    MASTER_USER='repl_user',
    MASTER_PASSWORD='ReplPass123!',
    MASTER_LOG_FILE='mysql-bin.000001',
    MASTER_LOG_POS=$MASTER_LOG_POS;
START SLAVE;
SHOW SLAVE STATUS\G
EOF_SQL

echo "Configuración de slave completada"
EOF

chmod +x setup_mysql_slave.sh
```

### Paso 2: Configurar PostgreSQL Standby
```bash
# Script para configurar standby PostgreSQL
cat > setup_postgres_standby.sh << 'EOF'
#!/bin/bash
echo "=== CONFIGURANDO POSTGRESQL STANDBY ==="

MASTER_HOST="postgres-vm-ip"
PG_DATA_DIR="/var/lib/postgresql/12/standby"

echo "1. Creando directorio standby..."
sudo mkdir -p $PG_DATA_DIR
sudo chown postgres:postgres $PG_DATA_DIR

echo "2. Realizando backup base desde master..."
sudo -u postgres pg_basebackup -h $MASTER_HOST -D $PG_DATA_DIR -U repl_user -v -P -W -X stream

echo "3. Configurando recovery.conf..."
sudo -u postgres tee $PG_DATA_DIR/recovery.conf > /dev/null << 'EOF_RECOVERY'
standby_mode = 'on'
primary_conninfo = 'host=MASTER_HOST port=5432 user=repl_user password=ReplPass123!'
primary_slot_name = 'replication_slot_1'
EOF_RECOVERY

echo "4. Configurando postgresql.conf para standby..."
sudo -u postgres sed -i "s/#hot_standby = off/hot_standby = on/" $PG_DATA_DIR/postgresql.conf
sudo -u postgres sed -i "s/#port = 5432/port = 5433/" $PG_DATA_DIR/postgresql.conf

echo "Standby configurado en puerto 5433"
EOF

chmod +x setup_postgres_standby.sh
```

---

## 🧪 Ejercicios de Evaluación Final

### Ejercicio 1: Diagnóstico Completo (25 puntos)
**Tiempo límite: 45 minutos**

**Escenario:** Se han introducido múltiples fallos:
1. MySQL no puede iniciar (tablespace corrupto)
2. PostgreSQL acepta conexiones pero queries fallan
3. MongoDB tiene problemas de autenticación
4. Red intermitente

**Tarea:** Usar herramientas de diagnóstico para identificar y documentar todos los problemas.

```bash
# Comandos esperados de diagnóstico:
./diagnose_system.sh
sudo tail -f /var/log/mysql/error.log
sudo -u postgres psql -c "SELECT * FROM pg_stat_activity;"
mongosh --eval "db.runCommand({connectionStatus: 1})"
ping -c 4 [target-hosts]
netstat -tlnp | grep -E "(3306|5432|27017)"
```

**Criterios de evaluación:**
- Identifica todos los problemas (15 pts)
- Documenta diagnóstico correctamente (5 pts)
- Propone plan de recovery (5 pts)

### Ejercicio 2: Disaster Recovery Completo (35 puntos)
**Tiempo límite: 90 minutos**

**Escenario:** Fallo catastrófico del servidor MySQL principal.

**Tarea:** 
1. Ejecutar procedimiento completo de DR
2. Restaurar desde backup físico
3. Verificar integridad de datos críticos
4. Configurar nuevo master
5. Documentar tiempo de recovery (RTO/RPO)

```bash
# Procedimiento esperado:
./simulate_mysql_disk_failure.sh  # Simular fallo
./mysql_disaster_recovery.sh      # Ejecutar recovery
# Verificar datos críticos
mysql -u root -p -e "CALL critical_app.ProcessTransaction(1001, 100.00, 'debit');"
# Documentar RTO/RPO
```

**Criterios de evaluación:**
- Recovery exitoso (20 pts)
- Datos íntegros post-recovery (10 pts)
- Documentación de RTO/RPO (5 pts)

### Ejercicio 3: Configuración de Alta Disponibilidad (25 puntos)
**Tiempo límite: 60 minutos**

**Tarea:** 
1. Configurar replicación MySQL OnPrem → RDS
2. Configurar standby PostgreSQL
3. Probar failover manual
4. Verificar sincronización de datos

**Criterios de evaluación:**
- Replicación configurada correctamente (15 pts)
- Failover funcional (5 pts)
- Datos sincronizados (5 pts)

### Ejercicio 4: Automatización de Recovery (15 puntos)
**Tiempo límite: 30 minutos**

**Tarea:** Crear script que:
1. Detecte automáticamente tipo de fallo
2. Ejecute procedimiento de recovery apropiado
3. Envíe notificaciones de estado
4. Genere reporte post-recovery

**Criterios de evaluación:**
- Script funciona correctamente (10 pts)
- Maneja múltiples tipos de fallo (3 pts)
- Genera reportes útiles (2 pts)

---

## 📊 Rúbrica de Evaluación Final

### Distribución de Puntos
- **Ejercicio 1 - Diagnóstico:** 25 puntos
- **Ejercicio 2 - Disaster Recovery:** 35 puntos
- **Ejercicio 3 - Alta Disponibilidad:** 25 puntos
- **Ejercicio 4 - Automatización:** 15 puntos
- **Total:** 100 puntos

### Criterios de Aprobación
- **Excelente (90-100):** Domina troubleshooting complejo, ejecuta DR exitosamente, configura HA
- **Bueno (80-89):** Diagnostica problemas básicos, ejecuta recovery con ayuda mínima
- **Regular (70-79):** Identifica problemas obvios, requiere ayuda para recovery
- **Insuficiente (<70):** No puede diagnosticar o ejecutar procedimientos básicos de recovery

---

## 📝 Entregables Finales

### 1. Runbook de Disaster Recovery
```markdown
# Runbook - Disaster Recovery
## Procedimientos Críticos

### MySQL Disaster Recovery
**RTO Target:** 30 minutos
**RPO Target:** 15 minutos

#### Pasos:
1. Detectar fallo: [comandos específicos]
2. Evaluar daño: [checklist]
3. Ejecutar recovery: [script específico]
4. Verificar integridad: [queries de validación]
5. Notificar stakeholders: [contactos]

### PostgreSQL PITR
**RTO Target:** 45 minutos
**RPO Target:** 5 minutos

#### Pasos:
[Procedimiento detallado]

### MongoDB Recovery
**RTO Target:** 20 minutos
**RPO Target:** 10 minutos

#### Pasos:
[Procedimiento detallado]
```

### 2. Scripts de Automatización
- `auto_recovery.sh` - Recovery automatizado
- `health_check.sh` - Verificación de salud
- `failover.sh` - Failover automatizado
- `backup_verify.sh` - Verificación de backups

### 3. Documentación de Incidentes
```markdown
# Reporte de Incidente - [Fecha]
## Resumen
- **Inicio:** [timestamp]
- **Resolución:** [timestamp]
- **RTO Actual:** [tiempo]
- **RPO Actual:** [tiempo]

## Causa Raíz
[Análisis detallado]

## Acciones Correctivas
[Lista de mejoras]

## Lecciones Aprendidas
[Conocimientos adquiridos]
```

Este laboratorio final proporciona experiencia práctica completa en troubleshooting avanzado y disaster recovery, preparando a los estudiantes para situaciones críticas reales en entornos de producción.
