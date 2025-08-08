# 🔄 Guía de Replicación MariaDB: Digital Ocean VM → AWS RDS

## 📋 Escenario
- **Origen**: MariaDB 10.2.8 en VM Digital Ocean
- **Destino**: AWS RDS MariaDB 10.5.25
- **Tipo**: Replicación Master-Slave (Binlog-based)

## ⚠️ Consideraciones Críticas de Compatibilidad

### **Compatibilidad de Versiones**
```sql
-- MariaDB 10.2.8 → 10.5.25 es COMPATIBLE
-- ✅ Replicación soportada (upgrade path válido)
-- ⚠️ Algunas funciones nuevas no estarán disponibles en el master
```

### **Limitaciones AWS RDS**
- ❌ **No se puede configurar como Master** (RDS no permite binlog externo)
- ✅ **Solo puede ser Slave/Replica** de fuente externa
- ✅ **Soporta replicación desde fuentes externas**

## 🎯 Arquitectura de Replicación

```
┌─────────────────────┐    Binlog Replication    ┌─────────────────────┐
│   Digital Ocean     │ ────────────────────────► │      AWS RDS        │
│   MariaDB 10.2.8    │         (Master)          │   MariaDB 10.5.25   │
│     (Master)        │                           │      (Slave)        │
└─────────────────────┘                           └─────────────────────┘
```

## 🔧 Prerrequisitos

### **1. Configuración de Red**
```bash
# Verificar conectividad desde DO a AWS
telnet your-rds-endpoint.amazonaws.com 3306

# Configurar Security Groups en AWS
# Permitir puerto 3306 desde IP de Digital Ocean
```

### **2. Verificar Versiones**
```sql
-- En Digital Ocean (Master)
SELECT VERSION();
-- Debe mostrar: 10.2.8-MariaDB

-- En AWS RDS (Slave)  
SELECT VERSION();
-- Debe mostrar: 10.5.25-MariaDB
```

### **3. Verificar Configuración RDS**
```sql
-- Verificar que RDS soporte replicación externa
SHOW VARIABLES LIKE 'log_slave_updates';
SHOW VARIABLES LIKE 'read_only';
```

## ⚙️ Configuración del Master (Digital Ocean)

### **1. Configurar my.cnf en Digital Ocean**
```ini
# /etc/mysql/mariadb.conf.d/50-server.cnf
[mysqld]
# Server ID único
server-id = 1

# Habilitar binary logging
log-bin = mysql-bin
binlog-format = ROW

# Configuraciones de replicación
expire_logs_days = 7
max_binlog_size = 100M

# Configuraciones de red
bind-address = 0.0.0.0

# Configuraciones de seguridad para replicación
ssl-ca = /etc/mysql/ssl/ca-cert.pem
ssl-cert = /etc/mysql/ssl/server-cert.pem  
ssl-key = /etc/mysql/ssl/server-key.pem

# Configuraciones de performance
innodb_flush_log_at_trx_commit = 1
sync_binlog = 1

# Configuraciones específicas para RDS compatibility
binlog_checksum = CRC32
master_verify_checksum = ON
slave_sql_verify_checksum = ON
```

### **2. Reiniciar MariaDB**
```bash
sudo systemctl restart mariadb
sudo systemctl status mariadb
```

### **3. Crear Usuario de Replicación**
```sql
-- Conectar como root
mysql -u root -p

-- Crear usuario para replicación
CREATE USER 'replication_user'@'%' IDENTIFIED BY 'StrongPassword123!';

-- Otorgar permisos de replicación
GRANT REPLICATION SLAVE ON *.* TO 'replication_user'@'%';

-- Configurar SSL (recomendado)
GRANT USAGE ON *.* TO 'replication_user'@'%' REQUIRE SSL;

-- Aplicar cambios
FLUSH PRIVILEGES;

-- Verificar usuario creado
SELECT User, Host, ssl_type FROM mysql.user WHERE User = 'replication_user';
```

### **4. Obtener Posición del Master**
```sql
-- Bloquear escrituras temporalmente
FLUSH TABLES WITH READ LOCK;

-- Obtener posición actual del binlog
SHOW MASTER STATUS;
-- Anotar: File y Position

-- Ejemplo de output:
-- +------------------+----------+--------------+------------------+
-- | File             | Position | Binlog_Do_DB | Binlog_Ignore_DB |
-- +------------------+----------+--------------+------------------+
-- | mysql-bin.000001 |      154 |              |                  |
-- +------------------+----------+--------------+------------------+
```

### **5. Crear Backup Consistente (Opcional pero Recomendado)**
```bash
# En otra terminal (mientras las tablas están bloqueadas)
mysqldump -u root -p \
  --single-transaction \
  --routines \
  --triggers \
  --all-databases \
  --master-data=2 > master_backup.sql

# Verificar que el backup incluye la posición
head -30 master_backup.sql | grep "CHANGE MASTER"
```

### **6. Desbloquear Tablas**
```sql
-- Volver a la sesión original
UNLOCK TABLES;
```

## 🔧 Configuración del Slave (AWS RDS)

### **1. Verificar Configuración RDS**
```sql
-- Conectar a RDS
mysql -h your-rds-endpoint.amazonaws.com -u admin -p

-- Verificar configuraciones
SHOW VARIABLES LIKE 'server_id';
SHOW VARIABLES LIKE 'log_slave_updates';
SHOW VARIABLES LIKE 'read_only';
```

### **2. Restaurar Backup (Si se creó)**
```bash
# Restaurar backup en RDS
mysql -h your-rds-endpoint.amazonaws.com -u admin -p < master_backup.sql
```

### **3. Configurar Replicación en RDS**
```sql
-- Conectar a RDS
mysql -h your-rds-endpoint.amazonaws.com -u admin -p

-- Configurar conexión al master
CALL mysql.rds_set_external_master(
  'digital-ocean-ip-or-hostname',
  3306,
  'replication_user',
  'StrongPassword123!',
  'mysql-bin.000001',  -- File del SHOW MASTER STATUS
  154,                 -- Position del SHOW MASTER STATUS
  0                    -- SSL (0=disabled, 1=enabled)
);

-- Si usas SSL (recomendado):
CALL mysql.rds_set_external_master_with_auto_position(
  'digital-ocean-ip-or-hostname',
  3306,
  'replication_user',
  'StrongPassword123!',
  0,  -- auto_position (0 para usar binlog position)
  1   -- SSL enabled
);
```

### **4. Iniciar Replicación**
```sql
-- Iniciar el slave
CALL mysql.rds_start_replication;

-- Verificar estado
SHOW SLAVE STATUS\G

-- Verificar campos importantes:
-- Slave_IO_Running: Yes
-- Slave_SQL_Running: Yes
-- Seconds_Behind_Master: 0 (o número pequeño)
-- Last_Error: (debe estar vacío)
```

## 🔍 Verificación y Monitoreo

### **1. Verificar Replicación Funcionando**
```sql
-- En el Master (Digital Ocean)
CREATE DATABASE test_replication;
USE test_replication;
CREATE TABLE test_table (id INT PRIMARY KEY, data VARCHAR(100));
INSERT INTO test_table VALUES (1, 'Test replication');

-- En el Slave (AWS RDS) - después de unos segundos
USE test_replication;
SELECT * FROM test_table;
-- Debe mostrar el registro insertado
```

### **2. Monitoreo Continuo**
```sql
-- En RDS, verificar estado regularmente
SHOW SLAVE STATUS\G

-- Campos críticos a monitorear:
-- Slave_IO_Running: Yes
-- Slave_SQL_Running: Yes  
-- Seconds_Behind_Master: < 60
-- Last_IO_Error: (vacío)
-- Last_SQL_Error: (vacío)
```

### **3. Script de Monitoreo Automatizado**
```bash
#!/bin/bash
# monitor_replication.sh

RDS_HOST="your-rds-endpoint.amazonaws.com"
RDS_USER="admin"
RDS_PASS="your-password"

# Verificar estado de replicación
mysql -h $RDS_HOST -u $RDS_USER -p$RDS_PASS -e "
SELECT 
    IF(Slave_IO_Running='Yes' AND Slave_SQL_Running='Yes', 'OK', 'ERROR') as Status,
    Seconds_Behind_Master,
    Last_IO_Error,
    Last_SQL_Error
FROM INFORMATION_SCHEMA.REPLICA_HOST_STATUS;" 2>/dev/null

# Alertar si hay problemas
if [ $? -ne 0 ]; then
    echo "ERROR: No se puede conectar a RDS o replicación detenida"
    # Enviar alerta (email, Slack, etc.)
fi
```

## ⚠️ Consideraciones Importantes

### **1. Diferencias de Versión**
```sql
-- Funciones disponibles en 10.5 pero no en 10.2:
-- - JSON functions mejoradas
-- - Window functions adicionales
-- - Nuevos tipos de datos

-- ⚠️ NO usar estas funciones en el master si planeas replicar
```

### **2. Configuraciones de Seguridad**
```bash
# Firewall en Digital Ocean
sudo ufw allow from aws-rds-ip to any port 3306

# Security Group en AWS
# Permitir puerto 3306 desde IP de Digital Ocean
```

### **3. SSL/TLS (Altamente Recomendado)**
```bash
# En Digital Ocean, generar certificados
sudo mysql_ssl_rsa_setup --uid=mysql

# Verificar certificados
ls -la /var/lib/mysql/*.pem

# Configurar RDS para usar SSL
CALL mysql.rds_set_external_master_with_auto_position(
  'digital-ocean-host',
  3306,
  'replication_user', 
  'password',
  0,
  1  -- SSL enabled
);
```

### **4. Manejo de Errores Comunes**

#### **Error 1236: Could not find first log file**
```sql
-- Solución: Verificar nombre y posición del binlog
SHOW MASTER STATUS;
-- Reconfigurar con valores correctos
```

#### **Error 2003: Can't connect to MySQL server**
```bash
# Verificar conectividad de red
telnet digital-ocean-ip 3306

# Verificar firewall y security groups
```

#### **Error 1045: Access denied**
```sql
-- Verificar usuario y permisos
SELECT User, Host FROM mysql.user WHERE User = 'replication_user';
SHOW GRANTS FOR 'replication_user'@'%';
```

## 📊 Monitoreo y Alertas

### **1. Métricas Clave**
```sql
-- Lag de replicación
SELECT Seconds_Behind_Master FROM INFORMATION_SCHEMA.REPLICA_HOST_STATUS;

-- Estado de conexión
SELECT Slave_IO_Running, Slave_SQL_Running FROM INFORMATION_SCHEMA.REPLICA_HOST_STATUS;

-- Errores recientes
SELECT Last_IO_Error, Last_SQL_Error FROM INFORMATION_SCHEMA.REPLICA_HOST_STATUS;
```

### **2. CloudWatch Integration (AWS)**
```bash
# Crear custom metric para lag
aws cloudwatch put-metric-data \
  --namespace "Database/Replication" \
  --metric-data MetricName=SecondsBehindMaster,Value=$LAG,Unit=Seconds
```

### **3. Alertas Recomendadas**
- Lag > 60 segundos
- Slave_IO_Running = No
- Slave_SQL_Running = No
- Errores en Last_IO_Error o Last_SQL_Error

## 🔄 Procedimientos de Mantenimiento

### **1. Reiniciar Replicación**
```sql
-- Detener replicación
CALL mysql.rds_stop_replication;

-- Reiniciar replicación
CALL mysql.rds_start_replication;
```

### **2. Cambiar Posición de Replicación**
```sql
-- Obtener nueva posición del master
-- En Digital Ocean:
SHOW MASTER STATUS;

-- En RDS, reconfigurar:
CALL mysql.rds_stop_replication;
CALL mysql.rds_set_external_master(
  'digital-ocean-host',
  3306,
  'replication_user',
  'password',
  'new-binlog-file',
  new-position,
  0
);
CALL mysql.rds_start_replication;
```

### **3. Failover Manual (Si es necesario)**
```sql
-- En RDS, detener replicación
CALL mysql.rds_stop_replication;

-- Hacer RDS escribible
-- (Esto requiere cambios en aplicación)
```

## 💰 Consideraciones de Costo

### **Transferencia de Datos**
- Digital Ocean → AWS: ~$0.01/GB
- Monitorear uso mensual de transferencia
- Considerar compresión de binlog si es posible

### **Instancia RDS**
- Usar instancia apropiada para carga de trabajo
- Considerar Reserved Instances para ahorro

## 🚨 Plan de Contingencia

### **1. Si Falla la Replicación**
```bash
# Script de recuperación automática
#!/bin/bash
# recovery_replication.sh

# Verificar si replicación está funcionando
STATUS=$(mysql -h $RDS_HOST -u $RDS_USER -p$RDS_PASS -e "SHOW SLAVE STATUS\G" | grep "Slave_SQL_Running" | awk '{print $2}')

if [ "$STATUS" != "Yes" ]; then
    echo "Replicación detenida, intentando reiniciar..."
    mysql -h $RDS_HOST -u $RDS_USER -p$RDS_PASS -e "CALL mysql.rds_stop_replication;"
    sleep 5
    mysql -h $RDS_HOST -u $RDS_USER -p$RDS_PASS -e "CALL mysql.rds_start_replication;"
fi
```

### **2. Backup de Emergencia**
```bash
# Backup automático diario
mysqldump -h $RDS_HOST -u $RDS_USER -p$RDS_PASS \
  --single-transaction \
  --routines \
  --triggers \
  --all-databases > "rds_backup_$(date +%Y%m%d).sql"
```

## ✅ Checklist de Implementación

### **Pre-implementación:**
- [ ] Verificar compatibilidad de versiones
- [ ] Configurar conectividad de red
- [ ] Crear usuario de replicación
- [ ] Configurar SSL (recomendado)

### **Implementación:**
- [ ] Configurar binlog en master
- [ ] Obtener posición inicial
- [ ] Configurar slave en RDS
- [ ] Iniciar replicación
- [ ] Verificar funcionamiento

### **Post-implementación:**
- [ ] Configurar monitoreo
- [ ] Establecer alertas
- [ ] Documentar procedimientos
- [ ] Entrenar equipo en mantenimiento

---

## 🎯 Resumen

La replicación MariaDB 10.2.8 (DO) → 10.5.25 (RDS) es **factible y soportada**. Los puntos clave son:

✅ **Ventajas:**
- Compatibilidad de versiones garantizada
- RDS maneja automáticamente muchas tareas de mantenimiento
- Escalabilidad automática en AWS

⚠️ **Limitaciones:**
- RDS solo puede ser slave, no master
- Algunas funciones avanzadas de 10.5 no disponibles en master
- Dependencia de conectividad de red entre proveedores

🔧 **Recomendaciones:**
- Usar SSL para seguridad
- Monitorear lag constantemente
- Tener plan de contingencia
- Considerar migración completa a RDS a largo plazo

¿Te gustaría que profundice en algún aspecto específico de la implementación?
