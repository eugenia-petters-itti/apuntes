# ✅ Checklist - Replicación MariaDB DO → AWS RDS

## 🎯 Resumen Rápido
**Escenario**: MariaDB 10.2.8 (Digital Ocean) → MariaDB 10.5.25 (AWS RDS)  
**Tipo**: Master-Slave Replication  
**Factibilidad**: ✅ **SÍ ES FACTIBLE**

## 📋 Pre-requisitos

### ✅ Verificaciones Iniciales
- [ ] **Compatibilidad de versiones**: 10.2.8 → 10.5.25 ✅ Compatible
- [ ] **Conectividad de red**: Digital Ocean → AWS (puerto 3306)
- [ ] **Permisos AWS**: Security Group permite acceso desde DO
- [ ] **Permisos DO**: Firewall permite salida a AWS
- [ ] **Credenciales**: Root en DO, Admin en RDS

### ✅ Configuración de Red
```bash
# Verificar conectividad
telnet your-rds-endpoint.amazonaws.com 3306

# Configurar Security Group AWS
# Permitir puerto 3306 desde IP de Digital Ocean

# Configurar firewall Digital Ocean
sudo ufw allow out 3306
```

## 🔧 Configuración Master (Digital Ocean)

### ✅ Configurar my.cnf
```ini
[mysqld]
server-id = 1
log-bin = mysql-bin
binlog-format = ROW
expire_logs_days = 7
max_binlog_size = 100M
bind-address = 0.0.0.0
```

### ✅ Comandos Esenciales
```sql
-- Crear usuario de replicación
CREATE USER 'replication_user'@'%' IDENTIFIED BY 'StrongPassword123!';
GRANT REPLICATION SLAVE ON *.* TO 'replication_user'@'%';
FLUSH PRIVILEGES;

-- Obtener posición del master
FLUSH TABLES WITH READ LOCK;
SHOW MASTER STATUS;
-- Anotar: File y Position
UNLOCK TABLES;
```

## 🔧 Configuración Slave (AWS RDS)

### ✅ Comandos RDS
```sql
-- Configurar master externo
CALL mysql.rds_set_external_master(
  'digital-ocean-ip',
  3306,
  'replication_user',
  'StrongPassword123!',
  'mysql-bin.000001',  -- File del SHOW MASTER STATUS
  154,                 -- Position del SHOW MASTER STATUS
  0                    -- SSL (0=disabled, 1=enabled)
);

-- Iniciar replicación
CALL mysql.rds_start_replication;

-- Verificar estado
SHOW SLAVE STATUS\G
```

## 🔍 Verificación

### ✅ Estado Saludable
```sql
-- Verificar estos campos en SHOW SLAVE STATUS\G
Slave_IO_Running: Yes
Slave_SQL_Running: Yes
Seconds_Behind_Master: 0 (o < 60)
Last_Error: (vacío)
```

### ✅ Prueba Funcional
```sql
-- En Master (DO)
CREATE DATABASE test_replication;
USE test_replication;
CREATE TABLE test (id INT, data VARCHAR(100));
INSERT INTO test VALUES (1, 'Replication working');

-- En Slave (RDS) - después de unos segundos
USE test_replication;
SELECT * FROM test;  -- Debe mostrar el registro
```

## 🚨 Problemas Comunes y Soluciones

### ❌ Error 1236: Could not find first log file
**Causa**: Binlog file/position incorrectos  
**Solución**: Verificar `SHOW MASTER STATUS` y reconfigurar

### ❌ Error 2003: Can't connect to MySQL server
**Causa**: Problemas de conectividad  
**Solución**: Verificar Security Groups y firewall

### ❌ Error 1045: Access denied
**Causa**: Credenciales incorrectas  
**Solución**: Verificar usuario y permisos de replicación

### ❌ Slave_IO_Running: No
**Causa**: Problemas de conexión o credenciales  
**Solución**: 
```sql
CALL mysql.rds_stop_replication;
CALL mysql.rds_start_replication;
```

### ❌ High Lag (Seconds_Behind_Master > 60)
**Causa**: Carga alta o instancia subdimensionada  
**Solución**: Escalar RDS o optimizar queries

## 📊 Monitoreo

### ✅ Script de Monitoreo
```bash
#!/bin/bash
# Verificar estado cada 5 minutos
mysql -h your-rds-endpoint.com -u admin -p -e "
SELECT 
    Slave_IO_Running,
    Slave_SQL_Running,
    Seconds_Behind_Master,
    Last_Error
FROM INFORMATION_SCHEMA.REPLICA_HOST_STATUS;"
```

### ✅ Alertas Recomendadas
- Lag > 60 segundos
- Slave_IO_Running = No
- Slave_SQL_Running = No
- Errores en Last_Error

## 🔄 Comandos de Mantenimiento

### ✅ Reiniciar Replicación
```sql
CALL mysql.rds_stop_replication;
CALL mysql.rds_start_replication;
```

### ✅ Cambiar Posición
```sql
-- Obtener nueva posición del master
SHOW MASTER STATUS;

-- Reconfigurar en RDS
CALL mysql.rds_stop_replication;
CALL mysql.rds_set_external_master(
  'host', 3306, 'user', 'pass', 'new-file', new-position, 0
);
CALL mysql.rds_start_replication;
```

### ✅ Verificar Lag
```sql
SELECT Seconds_Behind_Master 
FROM INFORMATION_SCHEMA.REPLICA_HOST_STATUS;
```

## 💰 Consideraciones de Costo

### ✅ Transferencia de Datos
- **DO → AWS**: ~$0.01/GB
- **Monitorear**: Uso mensual de transferencia
- **Optimizar**: Usar compresión si es posible

### ✅ Instancia RDS
- **Dimensionar**: Según carga de trabajo
- **Ahorrar**: Reserved Instances para uso continuo

## 🎯 Mejores Prácticas

### ✅ Seguridad
- [ ] Usar SSL para replicación
- [ ] Credenciales fuertes
- [ ] Restringir acceso por IP

### ✅ Performance
- [ ] Monitorear lag constantemente
- [ ] Dimensionar RDS apropiadamente
- [ ] Optimizar queries en master

### ✅ Backup
- [ ] Backup regular del master
- [ ] Backup de RDS automático
- [ ] Documentar procedimientos

### ✅ Documentación
- [ ] Documentar configuración
- [ ] Procedimientos de failover
- [ ] Contactos de emergencia

## 🚀 Scripts Automatizados

### ✅ Archivos Disponibles
- `setup-mariadb-replication.sh` - Configuración automatizada
- `troubleshoot-replication.sh` - Diagnóstico de problemas
- `monitor_replication.sh` - Monitoreo continuo

### ✅ Uso
```bash
# Configuración inicial
./setup-mariadb-replication.sh

# Monitoreo
./monitor_replication.sh

# Troubleshooting
./troubleshoot-replication.sh
```

## ✅ Checklist Final

### Pre-implementación
- [ ] Verificar compatibilidad de versiones
- [ ] Configurar conectividad de red
- [ ] Preparar credenciales
- [ ] Planificar ventana de mantenimiento

### Implementación
- [ ] Configurar binary logging en master
- [ ] Crear usuario de replicación
- [ ] Obtener posición inicial
- [ ] Configurar slave en RDS
- [ ] Iniciar replicación
- [ ] Verificar funcionamiento

### Post-implementación
- [ ] Configurar monitoreo
- [ ] Establecer alertas
- [ ] Documentar procedimientos
- [ ] Entrenar equipo
- [ ] Planificar mantenimiento

---

## 🎯 Resumen Ejecutivo

**✅ FACTIBLE**: La replicación MariaDB 10.2.8 → 10.5.25 es completamente soportada

**⚠️ LIMITACIÓN**: RDS solo puede ser slave, no master

**🔧 COMPLEJIDAD**: Media - requiere configuración cuidadosa pero es estándar

**💰 COSTO**: ~$0.01/GB transferencia + costo instancia RDS

**⏱️ TIEMPO**: 2-4 horas implementación + configuración monitoreo

**🎯 RECOMENDACIÓN**: Implementar con SSL, monitoreo robusto y plan de contingencia

---

*¿Necesitas ayuda con algún paso específico? Los scripts automatizados pueden facilitar mucho el proceso.*
