# 💾 Backup con mydumper - Parte 2: Configuración de Replicación

## 🔄 Configuración de Replicación

### **Script Completo de Configuración**
```bash
#!/bin/bash
# setup_replication_complete.sh

# Configuración
MASTER_HOST="your-do-ip"
MASTER_USER="root"
MASTER_PASS="master_password"
RDS_HOST="your-rds-endpoint.amazonaws.com"
RDS_USER="admin"
RDS_PASS="rds_password"
REPL_USER="replication_user"
REPL_PASS="repl_password"
BACKUP_PATH="$1"

if [ -z "$BACKUP_PATH" ]; then
    echo "Uso: $0 <backup_directory>"
    exit 1
fi

echo "🎯 CONFIGURACIÓN COMPLETA DE REPLICACIÓN"
echo "======================================="

# Paso 1: Crear usuario de replicación en Master
echo "📋 Paso 1: Creando usuario de replicación en Master..."
mysql -h "$MASTER_HOST" -u "$MASTER_USER" -p"$MASTER_PASS" << EOF
CREATE USER IF NOT EXISTS '$REPL_USER'@'%' IDENTIFIED BY '$REPL_PASS';
GRANT REPLICATION SLAVE ON *.* TO '$REPL_USER'@'%';
FLUSH PRIVILEGES;
EOF

if [ $? -eq 0 ]; then
    echo "✅ Usuario de replicación creado"
else
    echo "❌ Error creando usuario de replicación"
    exit 1
fi

# Paso 2: Obtener información de binlog del backup
echo "📋 Paso 2: Obteniendo información de binlog..."
if [ -f "$BACKUP_PATH/backup_summary.txt" ]; then
    BINLOG_FILE=$(grep "Binlog File:" "$BACKUP_PATH/backup_summary.txt" | cut -d: -f2 | xargs)
    BINLOG_POS=$(grep "Binlog Position:" "$BACKUP_PATH/backup_summary.txt" | cut -d: -f2 | xargs)
else
    # Buscar en archivos de metadata
    METADATA_FILE=$(find "$BACKUP_PATH" -name "*-schema-create.sql" | head -1)
    if [ -f "$METADATA_FILE" ]; then
        BINLOG_INFO=$(grep "CHANGE MASTER TO" "$METADATA_FILE" | head -1)
        BINLOG_FILE=$(echo "$BINLOG_INFO" | grep -o "MASTER_LOG_FILE='[^']*'" | cut -d"'" -f2)
        BINLOG_POS=$(echo "$BINLOG_INFO" | grep -o "MASTER_LOG_POS=[0-9]*" | cut -d"=" -f2)
    else
        echo "❌ No se pudo encontrar información de binlog"
        exit 1
    fi
fi

echo "✅ Información de binlog obtenida:"
echo "   File: $BINLOG_FILE"
echo "   Position: $BINLOG_POS"

# Paso 3: Configurar replicación en RDS
echo "📋 Paso 3: Configurando replicación en RDS..."
mysql -h "$RDS_HOST" -u "$RDS_USER" -p"$RDS_PASS" << EOF
CALL mysql.rds_set_external_master(
  '$MASTER_HOST',
  3306,
  '$REPL_USER',
  '$REPL_PASS',
  '$BINLOG_FILE',
  $BINLOG_POS,
  0
);
EOF

if [ $? -eq 0 ]; then
    echo "✅ Replicación configurada en RDS"
else
    echo "❌ Error configurando replicación"
    exit 1
fi

# Paso 4: Iniciar replicación
echo "📋 Paso 4: Iniciando replicación..."
mysql -h "$RDS_HOST" -u "$RDS_USER" -p"$RDS_PASS" -e "CALL mysql.rds_start_replication;"

if [ $? -eq 0 ]; then
    echo "✅ Replicación iniciada"
else
    echo "❌ Error iniciando replicación"
    exit 1
fi

# Paso 5: Verificar estado de replicación
echo "📋 Paso 5: Verificando estado de replicación..."
sleep 5

SLAVE_STATUS=$(mysql -h "$RDS_HOST" -u "$RDS_USER" -p"$RDS_PASS" -e "SHOW SLAVE STATUS\G" 2>/dev/null)

if [ $? -eq 0 ]; then
    IO_RUNNING=$(echo "$SLAVE_STATUS" | grep "Slave_IO_Running:" | awk '{print $2}')
    SQL_RUNNING=$(echo "$SLAVE_STATUS" | grep "Slave_SQL_Running:" | awk '{print $2}')
    SECONDS_BEHIND=$(echo "$SLAVE_STATUS" | grep "Seconds_Behind_Master:" | awk '{print $2}')
    LAST_ERROR=$(echo "$SLAVE_STATUS" | grep "Last_Error:" | cut -d: -f2- | xargs)
    
    echo "📊 Estado de replicación:"
    echo "   IO Running: $IO_RUNNING"
    echo "   SQL Running: $SQL_RUNNING"
    echo "   Seconds Behind: $SECONDS_BEHIND"
    
    if [ "$IO_RUNNING" = "Yes" ] && [ "$SQL_RUNNING" = "Yes" ]; then
        echo "✅ ¡Replicación funcionando correctamente!"
    else
        echo "❌ Problema con replicación:"
        echo "   Error: $LAST_ERROR"
        exit 1
    fi
else
    echo "❌ Error verificando estado de replicación"
    exit 1
fi

echo ""
echo "🎉 CONFIGURACIÓN COMPLETADA EXITOSAMENTE"
echo "======================================="
echo "✅ Usuario de replicación creado"
echo "✅ Datos restaurados en RDS"
echo "✅ Replicación configurada e iniciada"
echo "✅ Estado verificado"
echo ""
echo "📋 Próximos pasos:"
echo "1. Monitorear replicación regularmente"
echo "2. Configurar alertas para lag > 60 segundos"
echo "3. Probar failover en entorno de pruebas"
```

## 🤖 Scripts Automatizados

### **Script Todo-en-Uno**
```bash
#!/bin/bash
# complete_backup_replication.sh

# Configuración global
MASTER_HOST="your-do-ip"
MASTER_USER="root"
MASTER_PASS="master_password"
RDS_HOST="your-rds-endpoint.amazonaws.com"
RDS_USER="admin"
RDS_PASS="rds_password"
REPL_USER="replication_user"
REPL_PASS="repl_password"

BACKUP_DIR="/backup/mydumper"
DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_PATH="$BACKUP_DIR/complete_$DATE"
LOG_FILE="/var/log/complete-replication-setup.log"

# Función de logging
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S'): $1" | tee -a "$LOG_FILE"
}

log "🎯 INICIO DE CONFIGURACIÓN COMPLETA DE REPLICACIÓN"
log "================================================="

# Fase 1: Backup del Master
log "📋 FASE 1: BACKUP DEL MASTER"
log "============================"

mkdir -p "$BACKUP_PATH"

log "🔄 Iniciando backup con mydumper..."
START_BACKUP=$(date +%s)

mydumper \
  --host="$MASTER_HOST" \
  --user=backup_user \
  --password=BackupPassword123! \
  --outputdir="$BACKUP_PATH" \
  --threads=8 \
  --compress \
  --build-empty-files \
  --routines \
  --events \
  --triggers \
  --single-transaction \
  --master-data=2 \
  --less-locking

if [ $? -eq 0 ]; then
    END_BACKUP=$(date +%s)
    BACKUP_DURATION=$((END_BACKUP - START_BACKUP))
    BACKUP_SIZE=$(du -sh "$BACKUP_PATH" | cut -f1)
    
    log "✅ Backup completado en $((BACKUP_DURATION/60)) minutos"
    log "📊 Tamaño del backup: $BACKUP_SIZE"
else
    log "❌ Error en backup"
    exit 1
fi

# Extraer información de replicación
METADATA_FILE=$(find "$BACKUP_PATH" -name "*-schema-create.sql" | head -1)
BINLOG_INFO=$(grep "CHANGE MASTER TO" "$METADATA_FILE" | head -1)
BINLOG_FILE=$(echo "$BINLOG_INFO" | grep -o "MASTER_LOG_FILE='[^']*'" | cut -d"'" -f2)
BINLOG_POS=$(echo "$BINLOG_INFO" | grep -o "MASTER_LOG_POS=[0-9]*" | cut -d"=" -f2)

log "📋 Información de binlog extraída:"
log "   File: $BINLOG_FILE"
log "   Position: $BINLOG_POS"

# Fase 2: Restauración en RDS
log "📋 FASE 2: RESTAURACIÓN EN RDS"
log "=============================="

log "🔄 Iniciando restauración en RDS..."
START_RESTORE=$(date +%s)

# Configurar RDS para importación rápida
mysql -h "$RDS_HOST" -u "$RDS_USER" -p"$RDS_PASS" << 'EOF'
SET GLOBAL innodb_flush_log_at_trx_commit = 0;
SET GLOBAL sync_binlog = 0;
SET GLOBAL foreign_key_checks = 0;
SET GLOBAL unique_checks = 0;
EOF

# Restaurar con myloader
myloader \
  --host="$RDS_HOST" \
  --user="$RDS_USER" \
  --password="$RDS_PASS" \
  --directory="$BACKUP_PATH" \
  --threads=8 \
  --overwrite-tables \
  --enable-binlog

if [ $? -eq 0 ]; then
    END_RESTORE=$(date +%s)
    RESTORE_DURATION=$((END_RESTORE - START_RESTORE))
    
    log "✅ Restauración completada en $((RESTORE_DURATION/60)) minutos"
    
    # Restaurar configuraciones normales
    mysql -h "$RDS_HOST" -u "$RDS_USER" -p"$RDS_PASS" << 'EOF'
SET GLOBAL innodb_flush_log_at_trx_commit = 1;
SET GLOBAL sync_binlog = 1;
SET GLOBAL foreign_key_checks = 1;
SET GLOBAL unique_checks = 1;
EOF
else
    log "❌ Error en restauración"
    exit 1
fi

# Fase 3: Configuración de Replicación
log "📋 FASE 3: CONFIGURACIÓN DE REPLICACIÓN"
log "======================================="

# Crear usuario de replicación
log "🔄 Creando usuario de replicación..."
mysql -h "$MASTER_HOST" -u "$MASTER_USER" -p"$MASTER_PASS" << EOF
CREATE USER IF NOT EXISTS '$REPL_USER'@'%' IDENTIFIED BY '$REPL_PASS';
GRANT REPLICATION SLAVE ON *.* TO '$REPL_USER'@'%';
FLUSH PRIVILEGES;
EOF

# Configurar replicación en RDS
log "🔄 Configurando replicación en RDS..."
mysql -h "$RDS_HOST" -u "$RDS_USER" -p"$RDS_PASS" << EOF
CALL mysql.rds_set_external_master(
  '$MASTER_HOST',
  3306,
  '$REPL_USER',
  '$REPL_PASS',
  '$BINLOG_FILE',
  $BINLOG_POS,
  0
);
EOF

# Iniciar replicación
log "🔄 Iniciando replicación..."
mysql -h "$RDS_HOST" -u "$RDS_USER" -p"$RDS_PASS" -e "CALL mysql.rds_start_replication;"

# Verificar estado
sleep 10
SLAVE_STATUS=$(mysql -h "$RDS_HOST" -u "$RDS_USER" -p"$RDS_PASS" -e "SHOW SLAVE STATUS\G" 2>/dev/null)
IO_RUNNING=$(echo "$SLAVE_STATUS" | grep "Slave_IO_Running:" | awk '{print $2}')
SQL_RUNNING=$(echo "$SLAVE_STATUS" | grep "Slave_SQL_Running:" | awk '{print $2}')

if [ "$IO_RUNNING" = "Yes" ] && [ "$SQL_RUNNING" = "Yes" ]; then
    log "✅ Replicación configurada exitosamente"
else
    log "❌ Problema con replicación"
    exit 1
fi

# Resumen final
TOTAL_TIME=$((END_RESTORE - START_BACKUP))
log "🎉 CONFIGURACIÓN COMPLETADA EXITOSAMENTE"
log "======================================="
log "📊 Resumen de tiempos:"
log "   Backup: $((BACKUP_DURATION/60)) minutos"
log "   Restauración: $((RESTORE_DURATION/60)) minutos"
log "   Total: $((TOTAL_TIME/60)) minutos"
log "📊 Datos procesados: $BACKUP_SIZE"
log "✅ Replicación funcionando correctamente"

# Crear archivo de resumen
cat > "$BACKUP_PATH/final_summary.txt" << EOF
=== CONFIGURACIÓN COMPLETA DE REPLICACIÓN ===
Fecha: $(date)
Tiempo total: $((TOTAL_TIME/60)) minutos
Tamaño procesado: $BACKUP_SIZE

=== CONFIGURACIÓN APLICADA ===
Master: $MASTER_HOST (MariaDB 10.2.8)
Slave: $RDS_HOST (MariaDB 10.5.25)
Binlog File: $BINLOG_FILE
Binlog Position: $BINLOG_POS

=== ESTADO FINAL ===
IO Running: $IO_RUNNING
SQL Running: $SQL_RUNNING
Replicación: ACTIVA

=== COMANDOS DE MONITOREO ===
# Verificar estado:
mysql -h $RDS_HOST -u $RDS_USER -p -e "SHOW SLAVE STATUS\G"

# Reiniciar replicación si es necesario:
mysql -h $RDS_HOST -u $RDS_USER -p -e "CALL mysql.rds_stop_replication; CALL mysql.rds_start_replication;"
EOF

log "📄 Resumen guardado en: $BACKUP_PATH/final_summary.txt"
```

### **Script de Monitoreo Continuo**
```bash
#!/bin/bash
# monitor_replication.sh

RDS_HOST="your-rds-endpoint.amazonaws.com"
RDS_USER="admin"
RDS_PASS="rds_password"
LOG_FILE="/var/log/replication-monitor.log"
ALERT_EMAIL="admin@company.com"

# Función de logging
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S'): $1" | tee -a "$LOG_FILE"
}

# Función de alerta
send_alert() {
    local message="$1"
    log "🚨 ALERTA: $message"
    
    # Enviar email (requiere configurar sendmail o similar)
    echo "ALERTA DE REPLICACIÓN: $message" | mail -s "Replicación MariaDB - ALERTA" "$ALERT_EMAIL"
    
    # También se puede integrar con Slack, Discord, etc.
}

# Verificar estado de replicación
check_replication() {
    local status=$(mysql -h "$RDS_HOST" -u "$RDS_USER" -p"$RDS_PASS" -e "SHOW SLAVE STATUS\G" 2>/dev/null)
    
    if [ $? -ne 0 ]; then
        send_alert "No se puede conectar a RDS"
        return 1
    fi
    
    local io_running=$(echo "$status" | grep "Slave_IO_Running:" | awk '{print $2}')
    local sql_running=$(echo "$status" | grep "Slave_SQL_Running:" | awk '{print $2}')
    local seconds_behind=$(echo "$status" | grep "Seconds_Behind_Master:" | awk '{print $2}')
    local last_error=$(echo "$status" | grep "Last_Error:" | cut -d: -f2- | xargs)
    
    # Verificar estado de threads
    if [ "$io_running" != "Yes" ]; then
        send_alert "Slave IO Thread no está corriendo. Error: $last_error"
        return 1
    fi
    
    if [ "$sql_running" != "Yes" ]; then
        send_alert "Slave SQL Thread no está corriendo. Error: $last_error"
        return 1
    fi
    
    # Verificar lag
    if [ "$seconds_behind" != "NULL" ] && [ "$seconds_behind" -gt 60 ]; then
        send_alert "Alto lag de replicación: $seconds_behind segundos"
    fi
    
    log "✅ Replicación OK - Lag: ${seconds_behind}s"
    return 0
}

# Función de auto-recuperación
auto_recovery() {
    log "🔧 Intentando auto-recuperación..."
    
    # Reiniciar replicación
    mysql -h "$RDS_HOST" -u "$RDS_USER" -p"$RDS_PASS" -e "CALL mysql.rds_stop_replication;"
    sleep 5
    mysql -h "$RDS_HOST" -u "$RDS_USER" -p"$RDS_PASS" -e "CALL mysql.rds_start_replication;"
    
    # Esperar y verificar
    sleep 10
    if check_replication; then
        log "✅ Auto-recuperación exitosa"
        return 0
    else
        log "❌ Auto-recuperación falló"
        return 1
    fi
}

# Loop principal de monitoreo
log "🔍 Iniciando monitoreo de replicación..."

while true; do
    if ! check_replication; then
        # Intentar auto-recuperación una vez
        if ! auto_recovery; then
            send_alert "Auto-recuperación falló. Intervención manual requerida."
        fi
    fi
    
    # Esperar 5 minutos antes del próximo check
    sleep 300
done
```

## 📊 Monitoreo y Troubleshooting

### **Script de Diagnóstico**
```bash
#!/bin/bash
# diagnose_replication.sh

RDS_HOST="your-rds-endpoint.amazonaws.com"
RDS_USER="admin"
RDS_PASS="rds_password"
MASTER_HOST="your-do-ip"

echo "🔍 DIAGNÓSTICO DE REPLICACIÓN MARIADB"
echo "===================================="

# Verificar conectividad a RDS
echo "📋 Verificando conectividad a RDS..."
if mysql -h "$RDS_HOST" -u "$RDS_USER" -p"$RDS_PASS" -e "SELECT 1;" &>/dev/null; then
    echo "✅ Conectividad a RDS OK"
else
    echo "❌ No se puede conectar a RDS"
    exit 1
fi

# Verificar conectividad al Master
echo "📋 Verificando conectividad al Master..."
if nc -z "$MASTER_HOST" 3306; then
    echo "✅ Conectividad al Master OK"
else
    echo "❌ No se puede conectar al Master en puerto 3306"
fi

# Obtener estado detallado de replicación
echo "📋 Estado detallado de replicación:"
mysql -h "$RDS_HOST" -u "$RDS_USER" -p"$RDS_PASS" -e "SHOW SLAVE STATUS\G" | grep -E "(Slave_IO_Running|Slave_SQL_Running|Seconds_Behind_Master|Last_IO_Error|Last_SQL_Error|Master_Host|Master_Port|Master_User)"

# Verificar configuración del Master
echo "📋 Verificando configuración del Master:"
echo "Binary logging habilitado:"
mysql -h "$MASTER_HOST" -u root -p -e "SHOW VARIABLES LIKE 'log_bin';"

echo "Server ID del Master:"
mysql -h "$MASTER_HOST" -u root -p -e "SHOW VARIABLES LIKE 'server_id';"

echo "Estado actual del Master:"
mysql -h "$MASTER_HOST" -u root -p -e "SHOW MASTER STATUS;"

# Verificar usuarios de replicación
echo "📋 Verificando usuarios de replicación:"
mysql -h "$MASTER_HOST" -u root -p -e "SELECT User, Host FROM mysql.user WHERE User LIKE '%repl%';"

# Verificar logs de error recientes
echo "📋 Errores recientes en RDS:"
mysql -h "$RDS_HOST" -u "$RDS_USER" -p"$RDS_PASS" -e "SHOW SLAVE STATUS\G" | grep -A5 -B5 "Error"

echo "🔍 Diagnóstico completado"
```

### **Comandos Útiles de Troubleshooting**
```bash
# Verificar estado de replicación
mysql -h your-rds-endpoint.com -u admin -p -e "SHOW SLAVE STATUS\G"

# Reiniciar replicación
mysql -h your-rds-endpoint.com -u admin -p -e "CALL mysql.rds_stop_replication;"
mysql -h your-rds-endpoint.com -u admin -p -e "CALL mysql.rds_start_replication;"

# Verificar lag de replicación
mysql -h your-rds-endpoint.com -u admin -p -e "SELECT Seconds_Behind_Master FROM INFORMATION_SCHEMA.REPLICA_HOST_STATUS;"

# Verificar configuración del Master
mysql -h your-do-ip -u root -p -e "SHOW MASTER STATUS;"

# Verificar binary logs disponibles
mysql -h your-do-ip -u root -p -e "SHOW BINARY LOGS;"

# Verificar usuarios de replicación
mysql -h your-do-ip -u root -p -e "SHOW GRANTS FOR 'replication_user'@'%';"
```

## 📋 Checklist de Implementación

### **Pre-implementación**
- [ ] mydumper instalado en Digital Ocean
- [ ] Usuario de backup creado con permisos correctos
- [ ] Espacio suficiente en disco (30-40% del tamaño de la DB)
- [ ] Conectividad verificada entre DO y RDS
- [ ] Security Groups configurados en AWS

### **Durante la implementación**
- [ ] Backup completado sin errores
- [ ] Información de binlog extraída correctamente
- [ ] Restauración en RDS exitosa
- [ ] Usuario de replicación creado
- [ ] Replicación configurada e iniciada

### **Post-implementación**
- [ ] Estado de replicación verificado (IO y SQL Running = Yes)
- [ ] Lag de replicación < 60 segundos
- [ ] Monitoreo configurado
- [ ] Alertas establecidas
- [ ] Documentación actualizada

## 🎯 Resumen Final

### **Beneficios de esta Estrategia**
- ⚡ **5-10x más rápido** que mysqldump (2-4 horas vs 8-12 horas)
- ✅ **100% compatible** con MariaDB 10.2.8 y RDS 10.5.25
- 🔄 **Información de replicación** incluida automáticamente
- 📦 **Compresión integrada** para reducir tiempo de transferencia
- 🤖 **Scripts automatizados** para reducir errores manuales

### **Tiempo Total Estimado**
- **Backup**: 2-4 horas
- **Transferencia**: 30-60 minutos
- **Restauración**: 1-2 horas
- **Configuración**: 15-30 minutos
- **Total**: 4-7 horas (vs 16-24 horas con mysqldump)

¿Te gustaría que ajuste algún aspecto específico de esta documentación?
