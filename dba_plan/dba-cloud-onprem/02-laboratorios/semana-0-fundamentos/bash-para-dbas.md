# 🐚 Bash para DBAs - Fundamentos Esenciales

## 🎯 Objetivos del Módulo
- Dominar comandos Bash esenciales para administración de bases de datos
- Crear scripts de automatización para tareas DBA comunes
- Implementar monitoreo y alertas con Bash
- Integrar Bash con herramientas de base de datos

## 📋 Contenido del Curso

### **Módulo 1: Fundamentos de Bash para DBAs**
- Comandos esenciales del sistema
- Navegación y manipulación de archivos
- Pipes y redirección para logs de DB
- Variables de entorno para conexiones

### **Módulo 2: Scripts de Automatización DBA**
- Scripts de backup automatizado
- Monitoreo de performance
- Gestión de logs de base de datos
- Alertas y notificaciones

### **Módulo 3: Integración con Bases de Datos**
- Conexiones automatizadas a MySQL/PostgreSQL/MongoDB
- Procesamiento de resultados de queries
- Generación de reportes automatizados
- Mantenimiento programado

## 🛠️ Laboratorio 1: Comandos Esenciales para DBAs

### **Ejercicio 1.1: Navegación y Exploración del Sistema**
```bash
#!/bin/bash
# lab1_1_system_exploration.sh

echo "🔍 LABORATORIO 1.1: Exploración del Sistema para DBAs"
echo "=================================================="

# 1. Verificar información del sistema
echo "📊 Información del Sistema:"
echo "OS: $(uname -a)"
echo "Memoria total: $(free -h | grep Mem | awk '{print $2}')"
echo "Espacio en disco:"
df -h | grep -E "(Filesystem|/dev/)"

# 2. Verificar procesos de base de datos
echo -e "\n🗄️ Procesos de Base de Datos:"
ps aux | grep -E "(mysql|postgres|mongo)" | grep -v grep

# 3. Verificar puertos de base de datos
echo -e "\n🌐 Puertos de Base de Datos:"
netstat -tlnp | grep -E "(3306|5432|27017)"

# 4. Verificar logs del sistema
echo -e "\n📝 Logs Recientes del Sistema:"
tail -5 /var/log/syslog 2>/dev/null || tail -5 /var/log/messages 2>/dev/null

# EJERCICIO PRÁCTICO
echo -e "\n📋 EJERCICIO PRÁCTICO:"
echo "1. Encuentra todos los archivos de configuración de MySQL:"
echo "   find /etc -name '*mysql*' -type f 2>/dev/null"
echo ""
echo "2. Verifica el tamaño de los directorios de datos:"
echo "   du -sh /var/lib/mysql* 2>/dev/null"
echo ""
echo "3. Lista los últimos 10 archivos modificados en /var/log:"
echo "   ls -lt /var/log | head -10"
```

### **Ejercicio 1.2: Manipulación de Archivos de Log**
```bash
#!/bin/bash
# lab1_2_log_manipulation.sh

echo "📝 LABORATORIO 1.2: Manipulación de Logs de Base de Datos"
echo "======================================================="

# Crear logs de ejemplo para práctica
LOG_DIR="/tmp/dba_lab_logs"
mkdir -p "$LOG_DIR"

# Generar logs de ejemplo
cat > "$LOG_DIR/mysql_error.log" << 'EOF'
2024-12-08 10:15:23 [ERROR] Access denied for user 'test'@'localhost'
2024-12-08 10:16:45 [WARNING] Table 'users' is marked as crashed
2024-12-08 10:17:12 [ERROR] Disk full (/tmp); waiting for someone to free some space
2024-12-08 10:18:33 [INFO] Starting MySQL Community Server 8.0.25
2024-12-08 10:19:44 [ERROR] Connection refused from 192.168.1.100
2024-12-08 10:20:15 [WARNING] Slow query detected: SELECT * FROM large_table
EOF

cat > "$LOG_DIR/postgres.log" << 'EOF'
2024-12-08 10:15:23 LOG: database system is ready to accept connections
2024-12-08 10:16:45 ERROR: relation "missing_table" does not exist
2024-12-08 10:17:12 WARNING: checkpoint segments are being created too frequently
2024-12-08 10:18:33 ERROR: could not connect to server: Connection refused
2024-12-08 10:19:44 LOG: autovacuum launcher started
2024-12-08 10:20:15 ERROR: deadlock detected
EOF

echo "📊 Análisis de Logs - Comandos Esenciales:"
echo ""

# 1. Contar errores por tipo
echo "1. Contar errores en MySQL:"
echo "   grep -c ERROR $LOG_DIR/mysql_error.log"
grep -c ERROR "$LOG_DIR/mysql_error.log"

echo ""
echo "2. Extraer solo errores con timestamp:"
echo "   grep ERROR $LOG_DIR/mysql_error.log"
grep ERROR "$LOG_DIR/mysql_error.log"

echo ""
echo "3. Buscar patrones específicos (conexiones rechazadas):"
echo "   grep -i 'connection.*refused' $LOG_DIR/*.log"
grep -i 'connection.*refused' "$LOG_DIR"/*.log

echo ""
echo "4. Contar líneas por tipo de log:"
echo "   awk '{print \$4}' $LOG_DIR/mysql_error.log | sort | uniq -c"
awk '{print $4}' "$LOG_DIR/mysql_error.log" | sort | uniq -c

echo ""
echo "5. Extraer logs de las últimas 2 horas (simulado):"
echo "   tail -n 3 $LOG_DIR/mysql_error.log"
tail -n 3 "$LOG_DIR/mysql_error.log"

# EJERCICIO PRÁCTICO
echo -e "\n📋 EJERCICIO PRÁCTICO:"
echo "Completa estos comandos:"
echo ""
echo "1. Encuentra todas las líneas que contienen 'ERROR' en todos los logs:"
echo "   grep -r ERROR $LOG_DIR/"
echo ""
echo "2. Cuenta cuántas veces aparece cada tipo de mensaje:"
echo "   cat $LOG_DIR/*.log | awk '{print \$4}' | sort | uniq -c"
echo ""
echo "3. Extrae solo los timestamps de los errores:"
echo "   grep ERROR $LOG_DIR/*.log | awk '{print \$1, \$2}'"
```

### **Ejercicio 1.3: Variables y Conexiones de Base de Datos**
```bash
#!/bin/bash
# lab1_3_db_connections.sh

echo "🔗 LABORATORIO 1.3: Variables y Conexiones de Base de Datos"
echo "=========================================================="

# Configuración de variables de conexión
DB_HOST="localhost"
DB_USER="dba_user"
DB_PASS="dba_password"
MYSQL_PORT="3306"
POSTGRES_PORT="5432"
MONGO_PORT="27017"

echo "📋 Configuración de Variables de Conexión:"
echo "Host: $DB_HOST"
echo "Usuario: $DB_USER"
echo "Puerto MySQL: $MYSQL_PORT"
echo "Puerto PostgreSQL: $POSTGRES_PORT"
echo "Puerto MongoDB: $MONGO_PORT"

# Función para verificar conectividad
check_connectivity() {
    local host="$1"
    local port="$2"
    local service="$3"
    
    if timeout 5 bash -c "</dev/tcp/$host/$port" 2>/dev/null; then
        echo "✅ $service ($host:$port) - Conectividad OK"
        return 0
    else
        echo "❌ $service ($host:$port) - Sin conectividad"
        return 1
    fi
}

echo -e "\n🌐 Verificación de Conectividad:"
check_connectivity "$DB_HOST" "$MYSQL_PORT" "MySQL"
check_connectivity "$DB_HOST" "$POSTGRES_PORT" "PostgreSQL"
check_connectivity "$DB_HOST" "$MONGO_PORT" "MongoDB"

# Ejemplos de comandos de conexión
echo -e "\n💻 Comandos de Conexión:"
echo "MySQL:"
echo "  mysql -h $DB_HOST -P $MYSQL_PORT -u $DB_USER -p"
echo ""
echo "PostgreSQL:"
echo "  psql -h $DB_HOST -p $POSTGRES_PORT -U $DB_USER -d postgres"
echo ""
echo "MongoDB:"
echo "  mongosh --host $DB_HOST --port $MONGO_PORT"

# Script de conexión automatizada
echo -e "\n🤖 Script de Conexión Automatizada:"
cat << 'EOF'
#!/bin/bash
# connect_to_db.sh
DB_TYPE="$1"
QUERY="$2"

case "$DB_TYPE" in
    "mysql")
        mysql -h $DB_HOST -u $DB_USER -p$DB_PASS -e "$QUERY"
        ;;
    "postgres")
        PGPASSWORD=$DB_PASS psql -h $DB_HOST -U $DB_USER -d postgres -c "$QUERY"
        ;;
    *)
        echo "Uso: $0 {mysql|postgres} 'QUERY'"
        ;;
esac
EOF

# EJERCICIO PRÁCTICO
echo -e "\n📋 EJERCICIO PRÁCTICO:"
echo "1. Crea variables para tu entorno de base de datos"
echo "2. Escribe una función que verifique si un servicio está corriendo"
echo "3. Crea un script que se conecte a diferentes bases de datos según parámetros"
```

## 🛠️ Laboratorio 2: Scripts de Automatización DBA

### **Ejercicio 2.1: Script de Backup Automatizado**
```bash
#!/bin/bash
# lab2_1_automated_backup.sh

echo "💾 LABORATORIO 2.1: Script de Backup Automatizado"
echo "==============================================="

# Configuración
BACKUP_DIR="/backup/automated"
DATE=$(date +%Y%m%d_%H%M%S)
LOG_FILE="/var/log/dba_backup.log"

# Función de logging
log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S'): $1" | tee -a "$LOG_FILE"
}

# Función de backup MySQL
backup_mysql() {
    local db_name="$1"
    local backup_file="$BACKUP_DIR/mysql_${db_name}_$DATE.sql"
    
    log_message "Iniciando backup de MySQL: $db_name"
    
    # Crear directorio si no existe
    mkdir -p "$BACKUP_DIR"
    
    # Simular backup (en producción usar mysqldump real)
    cat > "$backup_file" << EOF
-- MySQL Backup Simulado
-- Database: $db_name
-- Date: $(date)
-- 
CREATE DATABASE IF NOT EXISTS $db_name;
USE $db_name;
-- Aquí irían las tablas y datos reales
EOF
    
    if [ $? -eq 0 ]; then
        log_message "✅ Backup MySQL completado: $backup_file"
        
        # Comprimir backup
        gzip "$backup_file"
        log_message "📦 Backup comprimido: ${backup_file}.gz"
        
        return 0
    else
        log_message "❌ Error en backup MySQL: $db_name"
        return 1
    fi
}

# Función de backup PostgreSQL
backup_postgres() {
    local db_name="$1"
    local backup_file="$BACKUP_DIR/postgres_${db_name}_$DATE.sql"
    
    log_message "Iniciando backup de PostgreSQL: $db_name"
    
    mkdir -p "$BACKUP_DIR"
    
    # Simular backup PostgreSQL
    cat > "$backup_file" << EOF
-- PostgreSQL Backup Simulado
-- Database: $db_name
-- Date: $(date)
-- 
CREATE DATABASE $db_name;
\c $db_name;
-- Aquí irían las tablas y datos reales
EOF
    
    if [ $? -eq 0 ]; then
        log_message "✅ Backup PostgreSQL completado: $backup_file"
        gzip "$backup_file"
        return 0
    else
        log_message "❌ Error en backup PostgreSQL: $db_name"
        return 1
    fi
}

# Función principal de backup
main_backup() {
    log_message "🚀 Iniciando proceso de backup automatizado"
    
    # Lista de bases de datos a respaldar
    MYSQL_DBS=("production" "analytics" "users")
    POSTGRES_DBS=("inventory" "reports")
    
    local success_count=0
    local total_count=0
    
    # Backup MySQL
    for db in "${MYSQL_DBS[@]}"; do
        ((total_count++))
        if backup_mysql "$db"; then
            ((success_count++))
        fi
    done
    
    # Backup PostgreSQL
    for db in "${POSTGRES_DBS[@]}"; do
        ((total_count++))
        if backup_postgres "$db"; then
            ((success_count++))
        fi
    done
    
    # Resumen
    log_message "📊 Resumen de backups: $success_count/$total_count exitosos"
    
    # Limpiar backups antiguos (más de 7 días)
    find "$BACKUP_DIR" -name "*.sql.gz" -mtime +7 -delete
    log_message "🧹 Backups antiguos eliminados"
    
    # Enviar notificación si hay errores
    if [ $success_count -lt $total_count ]; then
        log_message "⚠️ Algunos backups fallaron. Revisar logs."
        # Aquí se podría enviar email o notificación
    fi
}

# Ejecutar backup
main_backup

echo ""
echo "📋 EJERCICIO PRÁCTICO:"
echo "1. Modifica el script para incluir verificación de espacio en disco"
echo "2. Agrega una función para enviar notificaciones por email"
echo "3. Implementa rotación de logs del script"
echo "4. Agrega validación de integridad de los backups"
```

### **Ejercicio 2.2: Monitoreo de Performance**
```bash
#!/bin/bash
# lab2_2_performance_monitoring.sh

echo "📊 LABORATORIO 2.2: Monitoreo de Performance"
echo "==========================================="

# Configuración
ALERT_THRESHOLD_CPU=80
ALERT_THRESHOLD_MEMORY=85
ALERT_THRESHOLD_DISK=90
LOG_FILE="/var/log/dba_monitoring.log"

# Función de logging con niveles
log_with_level() {
    local level="$1"
    local message="$2"
    echo "$(date '+%Y-%m-%d %H:%M:%S') [$level]: $message" | tee -a "$LOG_FILE"
}

# Función para obtener uso de CPU
get_cpu_usage() {
    # Usar top para obtener CPU usage
    local cpu_usage=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1)
    echo "${cpu_usage%.*}"  # Remover decimales
}

# Función para obtener uso de memoria
get_memory_usage() {
    local mem_usage=$(free | grep Mem | awk '{printf "%.0f", $3/$2 * 100.0}')
    echo "$mem_usage"
}

# Función para obtener uso de disco
get_disk_usage() {
    local disk_usage=$(df / | tail -1 | awk '{print $5}' | cut -d'%' -f1)
    echo "$disk_usage"
}

# Función para verificar procesos de base de datos
check_db_processes() {
    log_with_level "INFO" "Verificando procesos de base de datos"
    
    # MySQL
    if pgrep mysqld > /dev/null; then
        local mysql_count=$(pgrep mysqld | wc -l)
        log_with_level "INFO" "MySQL: $mysql_count procesos activos"
    else
        log_with_level "WARNING" "MySQL: No hay procesos activos"
    fi
    
    # PostgreSQL
    if pgrep postgres > /dev/null; then
        local postgres_count=$(pgrep postgres | wc -l)
        log_with_level "INFO" "PostgreSQL: $postgres_count procesos activos"
    else
        log_with_level "WARNING" "PostgreSQL: No hay procesos activos"
    fi
    
    # MongoDB
    if pgrep mongod > /dev/null; then
        local mongo_count=$(pgrep mongod | wc -l)
        log_with_level "INFO" "MongoDB: $mongo_count procesos activos"
    else
        log_with_level "WARNING" "MongoDB: No hay procesos activos"
    fi
}

# Función para verificar conexiones de base de datos
check_db_connections() {
    log_with_level "INFO" "Verificando conexiones de base de datos"
    
    # Conexiones MySQL (puerto 3306)
    local mysql_connections=$(netstat -an | grep :3306 | grep ESTABLISHED | wc -l)
    log_with_level "INFO" "MySQL: $mysql_connections conexiones activas"
    
    # Conexiones PostgreSQL (puerto 5432)
    local postgres_connections=$(netstat -an | grep :5432 | grep ESTABLISHED | wc -l)
    log_with_level "INFO" "PostgreSQL: $postgres_connections conexiones activas"
    
    # Conexiones MongoDB (puerto 27017)
    local mongo_connections=$(netstat -an | grep :27017 | grep ESTABLISHED | wc -l)
    log_with_level "INFO" "MongoDB: $mongo_connections conexiones activas"
}

# Función principal de monitoreo
monitor_system() {
    log_with_level "INFO" "🔍 Iniciando monitoreo del sistema"
    
    # Obtener métricas del sistema
    local cpu_usage=$(get_cpu_usage)
    local memory_usage=$(get_memory_usage)
    local disk_usage=$(get_disk_usage)
    
    # Log de métricas
    log_with_level "INFO" "Métricas del sistema - CPU: ${cpu_usage}%, Memoria: ${memory_usage}%, Disco: ${disk_usage}%"
    
    # Verificar alertas
    if [ "$cpu_usage" -gt "$ALERT_THRESHOLD_CPU" ]; then
        log_with_level "ALERT" "🚨 Alto uso de CPU: ${cpu_usage}% (umbral: ${ALERT_THRESHOLD_CPU}%)"
    fi
    
    if [ "$memory_usage" -gt "$ALERT_THRESHOLD_MEMORY" ]; then
        log_with_level "ALERT" "🚨 Alto uso de memoria: ${memory_usage}% (umbral: ${ALERT_THRESHOLD_MEMORY}%)"
    fi
    
    if [ "$disk_usage" -gt "$ALERT_THRESHOLD_DISK" ]; then
        log_with_level "ALERT" "🚨 Alto uso de disco: ${disk_usage}% (umbral: ${ALERT_THRESHOLD_DISK}%)"
    fi
    
    # Verificar procesos y conexiones
    check_db_processes
    check_db_connections
    
    # Generar reporte
    generate_report "$cpu_usage" "$memory_usage" "$disk_usage"
}

# Función para generar reporte
generate_report() {
    local cpu="$1"
    local memory="$2"
    local disk="$3"
    
    local report_file="/tmp/system_report_$(date +%Y%m%d_%H%M%S).txt"
    
    cat > "$report_file" << EOF
=== REPORTE DE MONITOREO DEL SISTEMA ===
Fecha: $(date)
Servidor: $(hostname)

=== MÉTRICAS DEL SISTEMA ===
CPU Usage: ${cpu}%
Memory Usage: ${memory}%
Disk Usage: ${disk}%

=== PROCESOS DE BASE DE DATOS ===
$(ps aux | grep -E "(mysql|postgres|mongo)" | grep -v grep)

=== CONEXIONES ACTIVAS ===
MySQL (3306): $(netstat -an | grep :3306 | grep ESTABLISHED | wc -l)
PostgreSQL (5432): $(netstat -an | grep :5432 | grep ESTABLISHED | wc -l)
MongoDB (27017): $(netstat -an | grep :27017 | grep ESTABLISHED | wc -l)

=== TOP 10 PROCESOS POR CPU ===
$(ps aux --sort=-%cpu | head -11)

=== TOP 10 PROCESOS POR MEMORIA ===
$(ps aux --sort=-%mem | head -11)
EOF
    
    log_with_level "INFO" "📄 Reporte generado: $report_file"
}

# Ejecutar monitoreo
monitor_system

echo ""
echo "📋 EJERCICIO PRÁCTICO:"
echo "1. Modifica los umbrales de alerta según tu entorno"
echo "2. Agrega monitoreo de I/O de disco"
echo "3. Implementa alertas por email cuando se superen los umbrales"
echo "4. Crea un dashboard simple que muestre las métricas en tiempo real"
```

## 🔧 Ejercicios Prácticos Avanzados

### **Ejercicio Integrado: Sistema de Monitoreo Completo**
```bash
#!/bin/bash
# advanced_dba_monitoring_system.sh

echo "🎯 EJERCICIO INTEGRADO: Sistema de Monitoreo DBA Completo"
echo "======================================================="

# Este ejercicio combina todos los conceptos aprendidos
# Los estudiantes deben completar las funciones faltantes

# Configuración global
CONFIG_FILE="/etc/dba_monitor.conf"
LOG_DIR="/var/log/dba_monitor"
BACKUP_DIR="/backup/automated"

# Crear configuración si no existe
create_config() {
    if [ ! -f "$CONFIG_FILE" ]; then
        cat > "$CONFIG_FILE" << 'EOF'
# Configuración del Sistema de Monitoreo DBA
DB_HOST=localhost
MYSQL_USER=monitor_user
MYSQL_PASS=monitor_pass
POSTGRES_USER=monitor_user
POSTGRES_PASS=monitor_pass

# Umbrales de alerta
CPU_THRESHOLD=80
MEMORY_THRESHOLD=85
DISK_THRESHOLD=90
CONNECTION_THRESHOLD=100

# Configuración de notificaciones
ALERT_EMAIL=dba@company.com
SLACK_WEBHOOK=https://hooks.slack.com/your/webhook/url
EOF
        echo "✅ Archivo de configuración creado: $CONFIG_FILE"
    fi
}

# Cargar configuración
load_config() {
    if [ -f "$CONFIG_FILE" ]; then
        source "$CONFIG_FILE"
        echo "✅ Configuración cargada desde: $CONFIG_FILE"
    else
        echo "❌ Archivo de configuración no encontrado"
        create_config
        source "$CONFIG_FILE"
    fi
}

# EJERCICIO 1: Completar función de verificación de salud de DB
check_database_health() {
    echo "🏥 Verificando salud de las bases de datos..."
    
    # TODO: Los estudiantes deben implementar:
    # 1. Verificar conectividad a MySQL
    # 2. Verificar conectividad a PostgreSQL
    # 3. Obtener métricas básicas de cada DB
    # 4. Verificar replicación si está configurada
    
    echo "📋 TAREA: Implementar verificación de salud de DB"
    echo "   - Conectividad"
    echo "   - Métricas de performance"
    echo "   - Estado de replicación"
}

# EJERCICIO 2: Completar función de backup inteligente
intelligent_backup() {
    echo "🧠 Sistema de backup inteligente..."
    
    # TODO: Los estudiantes deben implementar:
    # 1. Verificar espacio disponible antes del backup
    # 2. Seleccionar método de backup según tamaño de DB
    # 3. Implementar backup incremental vs completo
    # 4. Verificar integridad del backup
    
    echo "📋 TAREA: Implementar backup inteligente"
    echo "   - Verificación de espacio"
    echo "   - Selección automática de método"
    echo "   - Verificación de integridad"
}

# EJERCICIO 3: Completar sistema de alertas
send_alert() {
    local alert_type="$1"
    local message="$2"
    
    echo "🚨 Enviando alerta: $alert_type"
    
    # TODO: Los estudiantes deben implementar:
    # 1. Envío de email
    # 2. Notificación a Slack
    # 3. Log de alertas
    # 4. Escalamiento según severidad
    
    echo "📋 TAREA: Implementar sistema de alertas"
    echo "   - Email notifications"
    echo "   - Slack integration"
    echo "   - Alert escalation"
}

# Función principal
main() {
    echo "🚀 Iniciando Sistema de Monitoreo DBA"
    
    # Cargar configuración
    load_config
    
    # Crear directorios necesarios
    mkdir -p "$LOG_DIR" "$BACKUP_DIR"
    
    # Ejecutar verificaciones
    check_database_health
    intelligent_backup
    
    echo ""
    echo "🎓 EJERCICIOS PARA COMPLETAR:"
    echo "1. Implementar check_database_health()"
    echo "2. Implementar intelligent_backup()"
    echo "3. Implementar send_alert()"
    echo "4. Crear cron jobs para automatización"
    echo "5. Agregar dashboard web simple"
}

# Ejecutar programa principal
main

echo ""
echo "📚 RECURSOS ADICIONALES:"
echo "- Manual de Bash: man bash"
echo "- Guía de scripting: https://tldp.org/LDP/Bash-Beginners-Guide/html/"
echo "- Ejemplos de scripts DBA: /opt/dba-training/scripts/"
```

## 📋 Evaluación y Certificación

### **Criterios de Evaluación - Bash para DBAs**
- **Comandos básicos (20%)**: Navegación, manipulación de archivos, pipes
- **Scripts de automatización (30%)**: Backup, monitoreo, mantenimiento
- **Integración con DB (25%)**: Conexiones, queries, procesamiento de resultados
- **Mejores prácticas (15%)**: Logging, manejo de errores, seguridad
- **Proyecto final (10%)**: Sistema completo de monitoreo

### **Proyecto Final: Sistema DBA Automatizado**
Los estudiantes deben crear un sistema que incluya:
1. **Script de backup automatizado** con rotación y verificación
2. **Sistema de monitoreo** con alertas configurables
3. **Dashboard simple** para visualizar métricas
4. **Documentación completa** del sistema
5. **Cron jobs** para automatización

¿Te gustaría que continúe con el módulo de Python para DBAs o prefieres que ajuste algo del contenido de Bash?
