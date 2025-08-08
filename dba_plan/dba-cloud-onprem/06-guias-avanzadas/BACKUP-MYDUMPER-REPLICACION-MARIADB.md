# 💾 Backup con mydumper para Replicación MariaDB 200GB+

## 🎯 Escenario Específico
- **Master**: MariaDB 10.2.8 en Digital Ocean VM (200GB+)
- **Slave**: AWS RDS MariaDB 10.5.25
- **Problema**: mysqldump demasiado lento (8-12 horas)
- **Solución**: mydumper (2-4 horas, 5-10x más rápido)

## 📋 Índice
- [¿Por qué mydumper?](#por-qué-mydumper)
- [Instalación](#instalación)
- [Configuración](#configuración)
- [Backup del Master](#backup-del-master)
- [Restauración en RDS](#restauración-en-rds)
- [Configuración de Replicación](#configuración-de-replicación)
- [Scripts Automatizados](#scripts-automatizados)
- [Monitoreo y Troubleshooting](#monitoreo-y-troubleshooting)

## 🚀 ¿Por qué mydumper?

### **Ventajas sobre mysqldump**
- ⚡ **5-10x más rápido** (paralelización multi-thread)
- 📦 **Archivos separados** por tabla (más manejable)
- 🔄 **Menos bloqueos** durante backup
- 📊 **Información de replicación** incluida automáticamente
- 🗜️ **Compresión integrada**
- ✅ **100% compatible** con MariaDB y RDS

### **Comparación de Tiempos (200GB)**
| Herramienta | Tiempo Backup | Tiempo Restauración | Downtime |
|-------------|---------------|-------------------|----------|
| **mysqldump** | 8-12 horas | 6-10 horas | Alto |
| **mydumper** | 2-4 horas | 1-2 horas | Bajo |

## 🔧 Instalación

### **En Digital Ocean (Ubuntu/Debian)**
```bash
# Actualizar repositorios
sudo apt-get update

# Instalar mydumper
sudo apt-get install mydumper

# Verificar instalación
mydumper --version
myloader --version
```

### **En Digital Ocean (CentOS/RHEL)**
```bash
# Instalar EPEL repository
sudo yum install epel-release

# Instalar mydumper
sudo yum install mydumper

# Verificar instalación
mydumper --version
```

### **Instalación desde Código Fuente (Versión más reciente)**
```bash
# Instalar dependencias
sudo apt-get install libmysqlclient-dev libglib2.0-dev zlib1g-dev libpcre3-dev libssl-dev cmake

# Clonar repositorio
git clone https://github.com/mydumper/mydumper.git
cd mydumper

# Compilar
cmake .
make

# Instalar
sudo make install

# Verificar
mydumper --version
```

## ⚙️ Configuración

### **1. Crear Usuario de Backup**
```sql
-- Conectar a MariaDB en Digital Ocean
mysql -u root -p

-- Crear usuario específico para backup
CREATE USER 'backup_user'@'localhost' IDENTIFIED BY 'BackupPassword123!';

-- Otorgar permisos necesarios
GRANT SELECT, RELOAD, LOCK TABLES, REPLICATION CLIENT, SHOW VIEW, EVENT, TRIGGER ON *.* TO 'backup_user'@'localhost';

-- Aplicar cambios
FLUSH PRIVILEGES;

-- Verificar permisos
SHOW GRANTS FOR 'backup_user'@'localhost';
```

### **2. Configurar Directorio de Backup**
```bash
# Crear directorio de backup
sudo mkdir -p /backup/mydumper
sudo chown $USER:$USER /backup/mydumper

# Verificar espacio disponible (necesitas ~30-40% del tamaño de la DB)
df -h /backup

# Para 200GB de datos, necesitas ~80GB de espacio libre
```

### **3. Configuración de Red para RDS**
```bash
# Verificar conectividad a RDS
telnet your-rds-endpoint.amazonaws.com 3306

# Si no funciona, verificar Security Groups en AWS
# Permitir puerto 3306 desde IP de Digital Ocean
```

## 💾 Backup del Master

### **Script de Backup Básico**
```bash
#!/bin/bash
# backup_master_mydumper.sh

# Configuración
MYSQL_HOST="localhost"
MYSQL_USER="backup_user"
MYSQL_PASS="BackupPassword123!"
BACKUP_DIR="/backup/mydumper"
DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_PATH="$BACKUP_DIR/backup_$DATE"

# Crear directorio de backup
mkdir -p "$BACKUP_PATH"

echo "🔄 Iniciando backup con mydumper..."
echo "📅 Fecha: $(date)"
echo "📁 Destino: $BACKUP_PATH"

# Ejecutar mydumper
mydumper \
  --host="$MYSQL_HOST" \
  --user="$MYSQL_USER" \
  --password="$MYSQL_PASS" \
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

# Verificar resultado
if [ $? -eq 0 ]; then
    echo "✅ Backup completado exitosamente"
    
    # Mostrar información del backup
    echo "📊 Información del backup:"
    echo "   Archivos creados: $(find $BACKUP_PATH -name "*.sql*" | wc -l)"
    echo "   Tamaño total: $(du -sh $BACKUP_PATH | cut -f1)"
    
    # Buscar información de replicación
    METADATA_FILE=$(find "$BACKUP_PATH" -name "*-schema-create.sql" | head -1)
    if [ -f "$METADATA_FILE" ]; then
        BINLOG_INFO=$(grep "CHANGE MASTER TO" "$METADATA_FILE" | head -1)
        echo "📋 Información de binlog encontrada:"
        echo "   $BINLOG_INFO"
        
        # Extraer valores específicos
        BINLOG_FILE=$(echo "$BINLOG_INFO" | grep -o "MASTER_LOG_FILE='[^']*'" | cut -d"'" -f2)
        BINLOG_POS=$(echo "$BINLOG_INFO" | grep -o "MASTER_LOG_POS=[0-9]*" | cut -d"=" -f2)
        
        echo "   Binlog File: $BINLOG_FILE"
        echo "   Binlog Position: $BINLOG_POS"
        
        # Guardar información para uso posterior
        cat > "$BACKUP_PATH/replication_info.txt" << EOF
BINLOG_FILE=$BINLOG_FILE
BINLOG_POS=$BINLOG_POS
BACKUP_DATE=$DATE
BACKUP_PATH=$BACKUP_PATH
EOF
    fi
    
    echo "✅ Backup completado en: $BACKUP_PATH"
else
    echo "❌ Error durante el backup"
    exit 1
fi
```

### **Script de Backup Avanzado con Monitoreo**
```bash
#!/bin/bash
# backup_master_advanced.sh

# Configuración
MYSQL_HOST="localhost"
MYSQL_USER="backup_user"
MYSQL_PASS="BackupPassword123!"
BACKUP_DIR="/backup/mydumper"
DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_PATH="$BACKUP_DIR/backup_$DATE"
LOG_FILE="/var/log/mydumper-backup.log"

# Función de logging
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S'): $1" | tee -a "$LOG_FILE"
}

# Verificaciones previas
log "🔍 Iniciando verificaciones previas..."

# Verificar espacio en disco
AVAILABLE_SPACE=$(df /backup | tail -1 | awk '{print $4}')
REQUIRED_SPACE=83886080  # 80GB en KB
if [ "$AVAILABLE_SPACE" -lt "$REQUIRED_SPACE" ]; then
    log "❌ Espacio insuficiente en disco"
    exit 1
fi

# Verificar conectividad a MySQL
if ! mysql -h "$MYSQL_HOST" -u "$MYSQL_USER" -p"$MYSQL_PASS" -e "SELECT 1;" &>/dev/null; then
    log "❌ No se puede conectar a MySQL"
    exit 1
fi

log "✅ Verificaciones completadas"

# Crear directorio de backup
mkdir -p "$BACKUP_PATH"

# Obtener información de la base de datos antes del backup
DB_SIZE=$(mysql -h "$MYSQL_HOST" -u "$MYSQL_USER" -p"$MYSQL_PASS" -e "
SELECT ROUND(SUM(data_length + index_length) / 1024 / 1024 / 1024, 2) AS 'DB Size (GB)'
FROM information_schema.tables;" -s -N)

log "📊 Tamaño de la base de datos: ${DB_SIZE}GB"

# Iniciar backup con monitoreo
log "🔄 Iniciando backup con mydumper..."
START_TIME=$(date +%s)

# Ejecutar mydumper en background para poder monitorear
mydumper \
  --host="$MYSQL_HOST" \
  --user="$MYSQL_USER" \
  --password="$MYSQL_PASS" \
  --outputdir="$BACKUP_PATH" \
  --threads=8 \
  --compress \
  --build-empty-files \
  --routines \
  --events \
  --triggers \
  --single-transaction \
  --master-data=2 \
  --less-locking \
  --verbose=3 &

MYDUMPER_PID=$!

# Monitorear progreso
while kill -0 $MYDUMPER_PID 2>/dev/null; do
    if [ -d "$BACKUP_PATH" ]; then
        CURRENT_SIZE=$(du -sh "$BACKUP_PATH" 2>/dev/null | cut -f1)
        FILE_COUNT=$(find "$BACKUP_PATH" -name "*.sql*" 2>/dev/null | wc -l)
        log "📈 Progreso: $CURRENT_SIZE, $FILE_COUNT archivos"
    fi
    sleep 60
done

# Esperar a que termine mydumper
wait $MYDUMPER_PID
MYDUMPER_EXIT_CODE=$?

END_TIME=$(date +%s)
DURATION=$((END_TIME - START_TIME))

if [ $MYDUMPER_EXIT_CODE -eq 0 ]; then
    log "✅ Backup completado en $((DURATION/60)) minutos"
    
    # Información final del backup
    FINAL_SIZE=$(du -sh "$BACKUP_PATH" | cut -f1)
    FILE_COUNT=$(find "$BACKUP_PATH" -name "*.sql*" | wc -l)
    
    log "📊 Estadísticas finales:"
    log "   Tamaño: $FINAL_SIZE"
    log "   Archivos: $FILE_COUNT"
    log "   Tiempo: $((DURATION/60)) minutos"
    
    # Extraer información de replicación
    METADATA_FILE=$(find "$BACKUP_PATH" -name "*-schema-create.sql" | head -1)
    if [ -f "$METADATA_FILE" ]; then
        BINLOG_INFO=$(grep "CHANGE MASTER TO" "$METADATA_FILE" | head -1)
        BINLOG_FILE=$(echo "$BINLOG_INFO" | grep -o "MASTER_LOG_FILE='[^']*'" | cut -d"'" -f2)
        BINLOG_POS=$(echo "$BINLOG_INFO" | grep -o "MASTER_LOG_POS=[0-9]*" | cut -d"=" -f2)
        
        log "📋 Información de replicación:"
        log "   Binlog File: $BINLOG_FILE"
        log "   Binlog Position: $BINLOG_POS"
        
        # Crear archivo de información
        cat > "$BACKUP_PATH/backup_summary.txt" << EOF
=== BACKUP SUMMARY ===
Date: $(date)
Duration: $((DURATION/60)) minutes
Size: $FINAL_SIZE
Files: $FILE_COUNT
Database Size: ${DB_SIZE}GB

=== REPLICATION INFO ===
Binlog File: $BINLOG_FILE
Binlog Position: $BINLOG_POS

=== RDS CONFIGURATION COMMAND ===
CALL mysql.rds_set_external_master(
  'your-do-ip',
  3306,
  'replication_user',
  'replication_password',
  '$BINLOG_FILE',
  $BINLOG_POS,
  0
);
EOF
        
        log "📄 Resumen guardado en: $BACKUP_PATH/backup_summary.txt"
    fi
    
else
    log "❌ Error durante el backup (código: $MYDUMPER_EXIT_CODE)"
    exit 1
fi
```

## 📥 Restauración en RDS

### **Script de Restauración Básico**
```bash
#!/bin/bash
# restore_to_rds.sh

# Configuración RDS
RDS_HOST="your-rds-endpoint.amazonaws.com"
RDS_USER="admin"
RDS_PASS="rds_password"
BACKUP_PATH="$1"

if [ -z "$BACKUP_PATH" ]; then
    echo "Uso: $0 <backup_directory>"
    echo "Ejemplo: $0 /backup/mydumper/backup_20241208_143000"
    exit 1
fi

if [ ! -d "$BACKUP_PATH" ]; then
    echo "❌ Directorio de backup no existe: $BACKUP_PATH"
    exit 1
fi

echo "🔄 Restaurando backup en RDS..."
echo "📁 Origen: $BACKUP_PATH"
echo "🎯 Destino: $RDS_HOST"

# Verificar conectividad a RDS
if ! mysql -h "$RDS_HOST" -u "$RDS_USER" -p"$RDS_PASS" -e "SELECT 1;" &>/dev/null; then
    echo "❌ No se puede conectar a RDS"
    exit 1
fi

echo "✅ Conectividad a RDS verificada"

# Configurar RDS para importación rápida
echo "⚙️ Configurando RDS para importación rápida..."
mysql -h "$RDS_HOST" -u "$RDS_USER" -p"$RDS_PASS" << 'EOF'
SET GLOBAL innodb_flush_log_at_trx_commit = 0;
SET GLOBAL sync_binlog = 0;
SET GLOBAL foreign_key_checks = 0;
SET GLOBAL unique_checks = 0;
SET GLOBAL autocommit = 0;
EOF

echo "✅ RDS configurado para importación"

# Restaurar con myloader
echo "📥 Iniciando restauración con myloader..."
START_TIME=$(date +%s)

myloader \
  --host="$RDS_HOST" \
  --user="$RDS_USER" \
  --password="$RDS_PASS" \
  --directory="$BACKUP_PATH" \
  --threads=8 \
  --overwrite-tables \
  --enable-binlog \
  --verbose=3

MYLOADER_EXIT_CODE=$?
END_TIME=$(date +%s)
DURATION=$((END_TIME - START_TIME))

if [ $MYLOADER_EXIT_CODE -eq 0 ]; then
    echo "✅ Restauración completada en $((DURATION/60)) minutos"
    
    # Restaurar configuraciones normales de RDS
    echo "⚙️ Restaurando configuraciones normales de RDS..."
    mysql -h "$RDS_HOST" -u "$RDS_USER" -p"$RDS_PASS" << 'EOF'
SET GLOBAL innodb_flush_log_at_trx_commit = 1;
SET GLOBAL sync_binlog = 1;
SET GLOBAL foreign_key_checks = 1;
SET GLOBAL unique_checks = 1;
SET GLOBAL autocommit = 1;
EOF
    
    echo "✅ Configuraciones RDS restauradas"
    
    # Mostrar información de replicación si está disponible
    if [ -f "$BACKUP_PATH/backup_summary.txt" ]; then
        echo ""
        echo "📋 INFORMACIÓN PARA CONFIGURAR REPLICACIÓN:"
        echo "=========================================="
        grep -A 10 "=== RDS CONFIGURATION COMMAND ===" "$BACKUP_PATH/backup_summary.txt" | tail -n +2
    fi
    
else
    echo "❌ Error durante la restauración (código: $MYLOADER_EXIT_CODE)"
    exit 1
fi
```
