# 💾 Backup con mydumper - Parte 3: Optimización y Mejores Prácticas

## ⚡ Optimización de Performance

### **Configuración Óptima para 200GB+**

#### **Parámetros mydumper Optimizados**
```bash
#!/bin/bash
# optimized_mydumper_200gb.sh

# Configuración optimizada para bases de datos grandes
mydumper \
  --host="$MYSQL_HOST" \
  --user="$MYSQL_USER" \
  --password="$MYSQL_PASS" \
  --outputdir="$BACKUP_PATH" \
  --threads=16 \                    # Más threads para paralelización
  --compress \                      # Compresión para reducir I/O
  --build-empty-files \             # Crear archivos vacíos para tablas sin datos
  --routines \                      # Incluir stored procedures
  --events \                        # Incluir eventos
  --triggers \                      # Incluir triggers
  --single-transaction \            # Consistencia transaccional
  --master-data=2 \                 # Información de replicación comentada
  --less-locking \                  # Reducir bloqueos
  --long-query-guard=3600 \         # Timeout para queries largas (1 hora)
  --kill-long-queries \             # Matar queries que excedan el timeout
  --chunk-filesize=128 \            # Tamaño de chunk en MB
  --rows=1000000 \                  # Filas por chunk
  --regex='^(?!(mysql|information_schema|performance_schema|sys))' # Excluir DBs del sistema
```

#### **Configuración del Sistema para Mejor Performance**
```bash
#!/bin/bash
# optimize_system_for_backup.sh

echo "⚙️ Optimizando sistema para backup de 200GB+"

# Aumentar límites de archivos abiertos
echo "fs.file-max = 2097152" >> /etc/sysctl.conf
echo "* soft nofile 65536" >> /etc/security/limits.conf
echo "* hard nofile 65536" >> /etc/security/limits.conf

# Optimizar I/O scheduler para SSD
echo noop > /sys/block/sda/queue/scheduler

# Aumentar buffer de red
echo "net.core.rmem_max = 134217728" >> /etc/sysctl.conf
echo "net.core.wmem_max = 134217728" >> /etc/sysctl.conf

# Aplicar cambios
sysctl -p

echo "✅ Sistema optimizado para backup"
```

#### **Configuración MySQL/MariaDB para Backup**
```sql
-- Configuraciones temporales para mejorar performance de backup
SET GLOBAL innodb_buffer_pool_dump_at_shutdown = OFF;
SET GLOBAL innodb_buffer_pool_load_at_startup = OFF;
SET GLOBAL innodb_io_capacity = 2000;
SET GLOBAL innodb_io_capacity_max = 4000;
SET GLOBAL innodb_read_io_threads = 8;
SET GLOBAL innodb_write_io_threads = 8;

-- Configurar timeouts para evitar desconexiones
SET GLOBAL wait_timeout = 28800;
SET GLOBAL interactive_timeout = 28800;
SET GLOBAL net_read_timeout = 600;
SET GLOBAL net_write_timeout = 600;
```

### **Monitoreo de Performance Durante Backup**
```bash
#!/bin/bash
# monitor_backup_performance.sh

BACKUP_PATH="$1"
MYSQL_HOST="$2"

if [ -z "$BACKUP_PATH" ] || [ -z "$MYSQL_HOST" ]; then
    echo "Uso: $0 <backup_path> <mysql_host>"
    exit 1
fi

echo "📊 Monitoreando performance del backup..."

while true; do
    # Monitorear progreso del backup
    if [ -d "$BACKUP_PATH" ]; then
        CURRENT_SIZE=$(du -sh "$BACKUP_PATH" 2>/dev/null | cut -f1)
        FILE_COUNT=$(find "$BACKUP_PATH" -name "*.sql*" 2>/dev/null | wc -l)
        
        # Monitorear I/O del sistema
        IO_STATS=$(iostat -x 1 1 | tail -n +4 | head -1)
        CPU_USAGE=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1)
        
        # Monitorear conexiones MySQL
        CONNECTIONS=$(mysql -h "$MYSQL_HOST" -u backup_user -p -e "SHOW STATUS LIKE 'Threads_connected';" -s -N 2>/dev/null | awk '{print $2}')
        
        echo "$(date '+%H:%M:%S') - Tamaño: $CURRENT_SIZE, Archivos: $FILE_COUNT, CPU: ${CPU_USAGE}%, Conexiones: $CONNECTIONS"
    fi
    
    sleep 30
done
```

## 🔧 Configuraciones Avanzadas

### **Backup Selectivo por Esquemas**
```bash
#!/bin/bash
# selective_backup.sh

# Lista de esquemas a incluir (excluir esquemas grandes no críticos)
INCLUDE_SCHEMAS="production_db,analytics_db,user_data"

mydumper \
  --host="$MYSQL_HOST" \
  --user="$MYSQL_USER" \
  --password="$MYSQL_PASS" \
  --outputdir="$BACKUP_PATH" \
  --threads=12 \
  --compress \
  --single-transaction \
  --master-data=2 \
  --regex="^($INCLUDE_SCHEMAS)\." \
  --routines \
  --events \
  --triggers

echo "✅ Backup selectivo completado para esquemas: $INCLUDE_SCHEMAS"
```

### **Backup con Exclusión de Tablas Grandes**
```bash
#!/bin/bash
# backup_exclude_large_tables.sh

# Tablas a excluir (logs, cache, etc.)
EXCLUDE_TABLES="logs.access_log,cache.session_data,temp.processing_queue"

mydumper \
  --host="$MYSQL_HOST" \
  --user="$MYSQL_USER" \
  --password="$MYSQL_PASS" \
  --outputdir="$BACKUP_PATH" \
  --threads=12 \
  --compress \
  --single-transaction \
  --master-data=2 \
  --ignore-table="$EXCLUDE_TABLES" \
  --routines \
  --events \
  --triggers

echo "✅ Backup completado excluyendo tablas: $EXCLUDE_TABLES"
```

### **Backup Incremental Simulado**
```bash
#!/bin/bash
# incremental_backup_simulation.sh

LAST_BACKUP_DATE="$1"
BACKUP_PATH="$2"

if [ -z "$LAST_BACKUP_DATE" ]; then
    echo "Uso: $0 <last_backup_date> <backup_path>"
    echo "Ejemplo: $0 '2024-12-01 00:00:00' /backup/incremental"
    exit 1
fi

# Backup solo de tablas modificadas después de la fecha especificada
mydumper \
  --host="$MYSQL_HOST" \
  --user="$MYSQL_USER" \
  --password="$MYSQL_PASS" \
  --outputdir="$BACKUP_PATH" \
  --threads=8 \
  --compress \
  --single-transaction \
  --master-data=2 \
  --where="updated_at > '$LAST_BACKUP_DATE'" \
  --routines \
  --events \
  --triggers

echo "✅ Backup incremental simulado completado desde: $LAST_BACKUP_DATE"
```

## 🚀 Estrategias de Transferencia Optimizada

### **Transferencia Paralela a RDS**
```bash
#!/bin/bash
# parallel_transfer_to_rds.sh

BACKUP_PATH="$1"
RDS_HOST="$2"
RDS_USER="$3"
RDS_PASS="$4"

if [ $# -ne 4 ]; then
    echo "Uso: $0 <backup_path> <rds_host> <rds_user> <rds_pass>"
    exit 1
fi

echo "🚀 Transferencia paralela a RDS..."

# Configurar RDS para importación rápida
mysql -h "$RDS_HOST" -u "$RDS_USER" -p"$RDS_PASS" << 'EOF'
SET GLOBAL innodb_flush_log_at_trx_commit = 0;
SET GLOBAL sync_binlog = 0;
SET GLOBAL foreign_key_checks = 0;
SET GLOBAL unique_checks = 0;
SET GLOBAL autocommit = 0;
SET GLOBAL innodb_buffer_pool_size = 4294967296; -- 4GB
EOF

# Función para restaurar archivo individual
restore_file() {
    local file="$1"
    local table_name=$(basename "$file" .sql.gz)
    
    echo "📥 Restaurando: $table_name"
    
    if [[ "$file" == *.gz ]]; then
        gunzip -c "$file" | mysql -h "$RDS_HOST" -u "$RDS_USER" -p"$RDS_PASS"
    else
        mysql -h "$RDS_HOST" -u "$RDS_USER" -p"$RDS_PASS" < "$file"
    fi
    
    if [ $? -eq 0 ]; then
        echo "✅ $table_name restaurado"
    else
        echo "❌ Error restaurando $table_name"
    fi
}

# Exportar función para uso en paralelo
export -f restore_file
export RDS_HOST RDS_USER RDS_PASS

# Restaurar archivos en paralelo (4 procesos simultáneos)
find "$BACKUP_PATH" -name "*.sql*" -not -name "*-schema-create.sql" | \
    parallel -j 4 restore_file {}

# Restaurar configuraciones normales
mysql -h "$RDS_HOST" -u "$RDS_USER" -p"$RDS_PASS" << 'EOF'
SET GLOBAL innodb_flush_log_at_trx_commit = 1;
SET GLOBAL sync_binlog = 1;
SET GLOBAL foreign_key_checks = 1;
SET GLOBAL unique_checks = 1;
SET GLOBAL autocommit = 1;
EOF

echo "✅ Transferencia paralela completada"
```

### **Transferencia vía S3 (Recomendado para archivos grandes)**
```bash
#!/bin/bash
# transfer_via_s3.sh

BACKUP_PATH="$1"
S3_BUCKET="your-backup-bucket"
S3_PREFIX="mariadb-backups/$(date +%Y/%m/%d)"

echo "☁️ Transfiriendo backup a S3..."

# Comprimir backup completo
tar -czf "${BACKUP_PATH}.tar.gz" -C "$(dirname $BACKUP_PATH)" "$(basename $BACKUP_PATH)"

# Subir a S3 con encriptación
aws s3 cp "${BACKUP_PATH}.tar.gz" \
    "s3://$S3_BUCKET/$S3_PREFIX/" \
    --server-side-encryption AES256 \
    --storage-class STANDARD_IA

echo "✅ Backup subido a S3: s3://$S3_BUCKET/$S3_PREFIX/"

# Script para descargar y restaurar desde S3
cat > "restore_from_s3.sh" << EOF
#!/bin/bash
# Descargar desde S3
aws s3 cp "s3://$S3_BUCKET/$S3_PREFIX/$(basename ${BACKUP_PATH}).tar.gz" .

# Extraer
tar -xzf "$(basename ${BACKUP_PATH}).tar.gz"

# Restaurar en RDS
myloader \\
  --host=your-rds-endpoint.amazonaws.com \\
  --user=admin \\
  --password=rds_password \\
  --directory="$(basename $BACKUP_PATH)" \\
  --threads=8 \\
  --overwrite-tables
EOF

chmod +x restore_from_s3.sh
echo "📄 Script de restauración desde S3 creado: restore_from_s3.sh"
```

## 📊 Métricas y Benchmarking

### **Script de Benchmarking**
```bash
#!/bin/bash
# benchmark_backup_methods.sh

DB_SIZE_GB="200"
MYSQL_HOST="localhost"
MYSQL_USER="backup_user"
MYSQL_PASS="password"
BACKUP_DIR="/backup/benchmark"

echo "🏁 BENCHMARK DE MÉTODOS DE BACKUP ($DB_SIZE_GB GB)"
echo "================================================="

# Crear directorio de benchmark
mkdir -p "$BACKUP_DIR"

# Función para medir tiempo
measure_time() {
    local method="$1"
    local command="$2"
    
    echo "📊 Probando método: $method"
    
    local start_time=$(date +%s)
    eval "$command"
    local end_time=$(date +%s)
    
    local duration=$((end_time - start_time))
    local minutes=$((duration / 60))
    local seconds=$((duration % 60))
    
    echo "⏱️  $method: ${minutes}m ${seconds}s"
    
    # Calcular tamaño del backup
    if [ -d "$BACKUP_DIR/$method" ]; then
        local size=$(du -sh "$BACKUP_DIR/$method" | cut -f1)
        echo "📦 Tamaño: $size"
    fi
    
    echo "---"
}

# Benchmark mydumper
measure_time "mydumper" "
mydumper \\
  --host='$MYSQL_HOST' \\
  --user='$MYSQL_USER' \\
  --password='$MYSQL_PASS' \\
  --outputdir='$BACKUP_DIR/mydumper' \\
  --threads=8 \\
  --compress \\
  --single-transaction \\
  --master-data=2
"

# Benchmark mysqldump (para comparación)
measure_time "mysqldump" "
mysqldump \\
  --host='$MYSQL_HOST' \\
  --user='$MYSQL_USER' \\
  --password='$MYSQL_PASS' \\
  --single-transaction \\
  --routines \\
  --triggers \\
  --all-databases \\
  --master-data=2 | gzip > '$BACKUP_DIR/mysqldump.sql.gz'
"

echo "🏆 Benchmark completado"
echo "📊 Resultados guardados en: $BACKUP_DIR"
```

### **Métricas de Performance**
```bash
#!/bin/bash
# collect_performance_metrics.sh

BACKUP_PATH="$1"
MYSQL_HOST="$2"

echo "📈 MÉTRICAS DE PERFORMANCE"
echo "========================="

# Métricas del sistema
echo "💻 Sistema:"
echo "   CPU cores: $(nproc)"
echo "   RAM total: $(free -h | grep Mem | awk '{print $2}')"
echo "   Disco disponible: $(df -h /backup | tail -1 | awk '{print $4}')"

# Métricas de MySQL
echo "🗄️  MySQL:"
mysql -h "$MYSQL_HOST" -u backup_user -p -e "
SELECT 
    ROUND(SUM(data_length + index_length) / 1024 / 1024 / 1024, 2) AS 'DB Size (GB)',
    COUNT(*) AS 'Total Tables'
FROM information_schema.tables 
WHERE table_schema NOT IN ('information_schema', 'mysql', 'performance_schema', 'sys');
"

# Métricas del backup
if [ -d "$BACKUP_PATH" ]; then
    echo "💾 Backup:"
    echo "   Tamaño: $(du -sh $BACKUP_PATH | cut -f1)"
    echo "   Archivos: $(find $BACKUP_PATH -name "*.sql*" | wc -l)"
    echo "   Compresión: $(find $BACKUP_PATH -name "*.gz" | wc -l) archivos comprimidos"
fi

# Métricas de red (si es backup remoto)
echo "🌐 Red:"
ping -c 3 "$MYSQL_HOST" | tail -1 | awk -F'/' '{print "   Latencia promedio: " $5 "ms"}'
```

## 🔒 Seguridad y Encriptación

### **Backup con Encriptación**
```bash
#!/bin/bash
# encrypted_backup.sh

BACKUP_PATH="$1"
ENCRYPTION_KEY="/etc/mysql/backup.key"

# Generar clave de encriptación si no existe
if [ ! -f "$ENCRYPTION_KEY" ]; then
    openssl rand -base64 32 > "$ENCRYPTION_KEY"
    chmod 600 "$ENCRYPTION_KEY"
    echo "🔑 Clave de encriptación generada: $ENCRYPTION_KEY"
fi

echo "🔒 Realizando backup encriptado..."

# Backup con mydumper
mydumper \
  --host="$MYSQL_HOST" \
  --user="$MYSQL_USER" \
  --password="$MYSQL_PASS" \
  --outputdir="$BACKUP_PATH" \
  --threads=8 \
  --compress \
  --single-transaction \
  --master-data=2

# Encriptar archivos del backup
echo "🔐 Encriptando archivos..."
find "$BACKUP_PATH" -name "*.sql*" -exec gpg --cipher-algo AES256 --compress-algo 1 --symmetric --batch --passphrase-file "$ENCRYPTION_KEY" {} \;

# Eliminar archivos no encriptados
find "$BACKUP_PATH" -name "*.sql" -delete
find "$BACKUP_PATH" -name "*.sql.gz" -delete

echo "✅ Backup encriptado completado"
echo "🔑 Para desencriptar: gpg --decrypt --batch --passphrase-file $ENCRYPTION_KEY archivo.gpg"
```

### **Verificación de Integridad**
```bash
#!/bin/bash
# verify_backup_integrity.sh

BACKUP_PATH="$1"

echo "🔍 Verificando integridad del backup..."

# Crear checksums
find "$BACKUP_PATH" -name "*.sql*" -exec sha256sum {} \; > "$BACKUP_PATH/checksums.sha256"

echo "✅ Checksums creados: $BACKUP_PATH/checksums.sha256"

# Verificar checksums
if sha256sum -c "$BACKUP_PATH/checksums.sha256"; then
    echo "✅ Integridad del backup verificada"
else
    echo "❌ Error de integridad detectado"
    exit 1
fi

# Verificar que archivos SQL son válidos
echo "🔍 Verificando sintaxis SQL..."
for sql_file in $(find "$BACKUP_PATH" -name "*.sql"); do
    if mysql --help > /dev/null 2>&1; then
        # Verificación básica de sintaxis
        if head -10 "$sql_file" | grep -q "CREATE\|INSERT\|DROP"; then
            echo "✅ $sql_file: Sintaxis válida"
        else
            echo "⚠️  $sql_file: Verificar manualmente"
        fi
    fi
done
```

## 📋 Mejores Prácticas

### **Checklist de Mejores Prácticas**

#### **Antes del Backup**
- [ ] Verificar espacio en disco (mínimo 40% del tamaño de la DB)
- [ ] Confirmar que mydumper está actualizado
- [ ] Verificar conectividad a la base de datos
- [ ] Configurar usuario de backup con permisos mínimos necesarios
- [ ] Planificar ventana de mantenimiento si es necesario

#### **Durante el Backup**
- [ ] Monitorear progreso y performance
- [ ] Verificar que no hay errores en logs
- [ ] Monitorear uso de CPU y I/O
- [ ] Verificar que la replicación no se vea afectada

#### **Después del Backup**
- [ ] Verificar integridad de archivos
- [ ] Confirmar que información de binlog está presente
- [ ] Probar restauración en entorno de pruebas
- [ ] Documentar tiempo y tamaño del backup
- [ ] Archivar o transferir backup según política de retención

### **Configuración de Retención**
```bash
#!/bin/bash
# backup_retention.sh

BACKUP_DIR="/backup/mydumper"
RETENTION_DAYS=30

echo "🗂️  Aplicando política de retención ($RETENTION_DAYS días)..."

# Eliminar backups antiguos
find "$BACKUP_DIR" -type d -name "backup_*" -mtime +$RETENTION_DAYS -exec rm -rf {} \;

# Comprimir backups de más de 7 días
find "$BACKUP_DIR" -type d -name "backup_*" -mtime +7 -not -name "*.tar.gz" -exec tar -czf {}.tar.gz {} \; -exec rm -rf {} \;

echo "✅ Política de retención aplicada"
```

### **Automatización con Cron**
```bash
# Agregar a crontab
# crontab -e

# Backup completo semanal (domingos a las 2 AM)
0 2 * * 0 /scripts/complete_backup_replication.sh >> /var/log/weekly-backup.log 2>&1

# Verificación diaria de replicación (cada 6 horas)
0 */6 * * * /scripts/monitor_replication.sh >> /var/log/replication-monitor.log 2>&1

# Limpieza de backups antiguos (diario a las 4 AM)
0 4 * * * /scripts/backup_retention.sh >> /var/log/backup-cleanup.log 2>&1

# Verificación de integridad (semanal, lunes a las 6 AM)
0 6 * * 1 /scripts/verify_backup_integrity.sh /backup/mydumper/latest >> /var/log/backup-verification.log 2>&1
```

## 🎯 Resumen Final y Recomendaciones

### **Configuración Recomendada para tu Caso (200GB)**
```bash
# Comando optimizado final
mydumper \
  --host=your-do-ip \
  --user=backup_user \
  --password=BackupPassword123! \
  --outputdir=/backup/mydumper/$(date +%Y%m%d_%H%M%S) \
  --threads=12 \
  --compress \
  --build-empty-files \
  --routines \
  --events \
  --triggers \
  --single-transaction \
  --master-data=2 \
  --less-locking \
  --long-query-guard=3600 \
  --chunk-filesize=128 \
  --rows=1000000
```

### **Tiempos Esperados**
- **Backup**: 2-4 horas (vs 8-12 con mysqldump)
- **Transferencia**: 30-60 minutos
- **Restauración**: 1-2 horas
- **Total**: 4-7 horas (vs 16-24 con mysqldump)

### **Beneficios Finales**
- ⚡ **5-10x más rápido** que mysqldump
- 🔄 **Información de replicación** incluida automáticamente
- 📦 **Compresión integrada** (60-70% reducción)
- 🤖 **Scripts automatizados** para reducir errores
- ✅ **100% compatible** con tu escenario MariaDB → RDS

¡Con esta documentación completa tienes todo lo necesario para implementar una estrategia de backup eficiente para tu replicación de 200GB+!
