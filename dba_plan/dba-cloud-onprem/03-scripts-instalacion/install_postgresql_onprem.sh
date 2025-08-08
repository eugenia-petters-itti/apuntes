#!/bin/bash
# install_postgresql_onprem.sh
# Script de instalación automatizada de PostgreSQL OnPrem para laboratorios DBA
# Versión: 1.0
# Autor: DBA Training Team

set -e  # Salir si hay errores

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Variables de configuración
POSTGRES_VERSION="14"
POSTGRES_PASSWORD="Postgres123!"
LOG_FILE="/var/log/postgresql_installation.log"

# Función para logging
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | sudo tee -a $LOG_FILE
    echo -e "${GREEN}[INFO]${NC} $1"
}

error() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - ERROR: $1" | sudo tee -a $LOG_FILE
    echo -e "${RED}[ERROR]${NC} $1"
    exit 1
}

warning() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - WARNING: $1" | sudo tee -a $LOG_FILE
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

# Verificar si se ejecuta como root
check_root() {
    if [[ $EUID -eq 0 ]]; then
        error "Este script no debe ejecutarse como root. Usa un usuario con sudo."
    fi
}

# Verificar sistema operativo
check_os() {
    if [[ ! -f /etc/os-release ]]; then
        error "No se puede determinar el sistema operativo"
    fi
    
    . /etc/os-release
    if [[ "$ID" != "ubuntu" ]]; then
        error "Este script está diseñado para Ubuntu. OS detectado: $ID"
    fi
    
    log "Sistema operativo verificado: $PRETTY_NAME"
}

# Verificar recursos del sistema
check_resources() {
    info "Verificando recursos del sistema..."
    
    # Verificar RAM (mínimo 2GB)
    RAM_GB=$(free -g | awk '/^Mem:/{print $2}')
    if [[ $RAM_GB -lt 2 ]]; then
        warning "RAM disponible: ${RAM_GB}GB. Recomendado: 4GB o más"
    else
        log "RAM verificada: ${RAM_GB}GB"
    fi
    
    # Verificar espacio en disco (mínimo 10GB)
    DISK_GB=$(df -BG / | awk 'NR==2{print $4}' | sed 's/G//')
    if [[ $DISK_GB -lt 10 ]]; then
        error "Espacio insuficiente en disco: ${DISK_GB}GB. Mínimo requerido: 10GB"
    else
        log "Espacio en disco verificado: ${DISK_GB}GB disponibles"
    fi
}

# Actualizar sistema
update_system() {
    info "Actualizando sistema..."
    sudo apt update || error "Fallo al actualizar lista de paquetes"
    sudo apt upgrade -y || error "Fallo al actualizar paquetes"
    log "Sistema actualizado correctamente"
}

# Instalar dependencias
install_dependencies() {
    info "Instalando dependencias..."
    
    local packages=(
        "curl"
        "wget" 
        "vim"
        "htop"
        "net-tools"
        "tree"
        "unzip"
        "software-properties-common"
        "apt-transport-https"
        "ca-certificates"
        "gnupg"
        "lsb-release"
        "locales"
    )
    
    for package in "${packages[@]}"; do
        if ! dpkg -l | grep -q "^ii  $package "; then
            sudo apt install -y "$package" || error "Fallo al instalar $package"
            log "Instalado: $package"
        else
            log "$package ya está instalado"
        fi
    done
}

# Configurar locales
configure_locales() {
    info "Configurando locales..."
    
    # Generar locales necesarios
    sudo locale-gen en_US.UTF-8
    sudo update-locale LANG=en_US.UTF-8
    
    log "Locales configurados"
}

# Configurar repositorio PostgreSQL
setup_postgresql_repo() {
    info "Configurando repositorio PostgreSQL..."
    
    # Importar clave de firma
    wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add - || error "Fallo al agregar clave GPG"
    
    # Agregar repositorio
    echo "deb http://apt.postgresql.org/pub/repos/apt/ $(lsb_release -cs)-pgdg main" | sudo tee /etc/apt/sources.list.d/pgdg.list
    
    # Actualizar lista de paquetes
    sudo apt update || error "Fallo al actualizar después de agregar repositorio PostgreSQL"
    
    log "Repositorio PostgreSQL configurado"
}

# Instalar PostgreSQL
install_postgresql() {
    info "Instalando PostgreSQL $POSTGRES_VERSION..."
    
    # Instalar PostgreSQL y herramientas adicionales
    sudo apt install -y \
        postgresql-$POSTGRES_VERSION \
        postgresql-client-$POSTGRES_VERSION \
        postgresql-contrib-$POSTGRES_VERSION \
        postgresql-server-dev-$POSTGRES_VERSION \
        pgbadger \
        || error "Fallo al instalar PostgreSQL"
    
    log "PostgreSQL $POSTGRES_VERSION instalado"
}

# Configurar PostgreSQL
configure_postgresql() {
    info "Configurando PostgreSQL..."
    
    # Configurar password para usuario postgres
    sudo -u postgres psql -c "ALTER USER postgres PASSWORD '$POSTGRES_PASSWORD';" || error "Fallo al configurar password postgres"
    
    # Obtener directorio de configuración
    local config_dir="/etc/postgresql/$POSTGRES_VERSION/main"
    
    # Backup de configuración original
    sudo cp "$config_dir/postgresql.conf" "$config_dir/postgresql.conf.backup"
    sudo cp "$config_dir/pg_hba.conf" "$config_dir/pg_hba.conf.backup"
    
    # Configurar postgresql.conf
    sudo tee "$config_dir/postgresql.conf" > /dev/null << EOF
# PostgreSQL configuration for DBA Lab
# Version: $POSTGRES_VERSION

#------------------------------------------------------------------------------
# FILE LOCATIONS
#------------------------------------------------------------------------------
data_directory = '/var/lib/postgresql/$POSTGRES_VERSION/main'
hba_file = '/etc/postgresql/$POSTGRES_VERSION/main/pg_hba.conf'
ident_file = '/etc/postgresql/$POSTGRES_VERSION/main/pg_ident.conf'
external_pid_file = '/var/run/postgresql/$POSTGRES_VERSION-main.pid'

#------------------------------------------------------------------------------
# CONNECTIONS AND AUTHENTICATION
#------------------------------------------------------------------------------
listen_addresses = '*'
port = 5432
max_connections = 200
superuser_reserved_connections = 3
unix_socket_directories = '/var/run/postgresql'
ssl = on
ssl_cert_file = '/etc/ssl/certs/ssl-cert-snakeoil.pem'
ssl_key_file = '/etc/ssl/private/ssl-cert-snakeoil.key'

#------------------------------------------------------------------------------
# RESOURCE USAGE (except WAL)
#------------------------------------------------------------------------------
shared_buffers = 256MB
huge_pages = try
temp_buffers = 8MB
max_prepared_transactions = 0
work_mem = 4MB
maintenance_work_mem = 64MB
max_stack_depth = 2MB
dynamic_shared_memory_type = posix

#------------------------------------------------------------------------------
# WRITE AHEAD LOG
#------------------------------------------------------------------------------
wal_level = replica
fsync = on
synchronous_commit = on
wal_sync_method = fsync
full_page_writes = on
wal_compression = off
wal_log_hints = off
wal_buffers = 16MB
wal_writer_delay = 200ms
commit_delay = 0
commit_siblings = 5
checkpoint_timeout = 5min
max_wal_size = 1GB
min_wal_size = 80MB
checkpoint_completion_target = 0.5
checkpoint_warning = 30s
archive_mode = on
archive_command = 'cp %p /var/lib/postgresql/$POSTGRES_VERSION/main/archive/%f'
max_wal_senders = 10
max_replication_slots = 10
hot_standby = on
max_standby_archive_delay = 30s
max_standby_streaming_delay = 30s
wal_receiver_status_interval = 10s
hot_standby_feedback = off
wal_receiver_timeout = 60s

#------------------------------------------------------------------------------
# QUERY TUNING
#------------------------------------------------------------------------------
enable_bitmapscan = on
enable_hashagg = on
enable_hashjoin = on
enable_indexscan = on
enable_indexonlyscan = on
enable_material = on
enable_mergejoin = on
enable_nestloop = on
enable_seqscan = on
enable_sort = on
enable_tidscan = on
random_page_cost = 4.0
cpu_tuple_cost = 0.01
cpu_index_tuple_cost = 0.005
cpu_operator_cost = 0.0025
effective_cache_size = 1GB
default_statistics_target = 100

#------------------------------------------------------------------------------
# ERROR REPORTING AND LOGGING
#------------------------------------------------------------------------------
log_destination = 'csvlog'
logging_collector = on
log_directory = 'pg_log'
log_filename = 'postgresql-%Y-%m-%d_%H%M%S.log'
log_file_mode = 0600
log_truncate_on_rotation = off
log_rotation_age = 1d
log_rotation_size = 100MB
log_min_messages = warning
log_min_error_statement = error
log_min_duration_statement = 1000
log_checkpoints = on
log_connections = on
log_disconnections = on
log_duration = off
log_error_verbosity = default
log_hostname = off
log_line_prefix = '%t [%p]: [%l-1] user=%u,db=%d,app=%a,client=%h '
log_lock_waits = on
log_statement = 'ddl'
log_replication_commands = off
log_temp_files = 10MB
log_timezone = 'UTC'

#------------------------------------------------------------------------------
# RUNTIME STATISTICS
#------------------------------------------------------------------------------
track_activities = on
track_counts = on
track_io_timing = on
track_functions = all
track_activity_query_size = 1024
stats_temp_directory = 'pg_stat_tmp'

#------------------------------------------------------------------------------
# AUTOVACUUM PARAMETERS
#------------------------------------------------------------------------------
autovacuum = on
log_autovacuum_min_duration = 0
autovacuum_max_workers = 3
autovacuum_naptime = 1min
autovacuum_vacuum_threshold = 50
autovacuum_analyze_threshold = 50
autovacuum_vacuum_scale_factor = 0.2
autovacuum_analyze_scale_factor = 0.1
autovacuum_freeze_max_age = 200000000
autovacuum_multixact_freeze_max_age = 400000000
autovacuum_vacuum_cost_delay = 20ms
autovacuum_vacuum_cost_limit = -1

#------------------------------------------------------------------------------
# CLIENT CONNECTION DEFAULTS
#------------------------------------------------------------------------------
search_path = '"$user", public'
default_tablespace = ''
temp_tablespaces = ''
check_function_bodies = on
default_transaction_isolation = 'read committed'
default_transaction_read_only = off
default_transaction_deferrable = off
session_replication_role = 'origin'
statement_timeout = 0
lock_timeout = 0
idle_in_transaction_session_timeout = 0
vacuum_freeze_min_age = 50000000
vacuum_freeze_table_age = 150000000
vacuum_multixact_freeze_min_age = 5000000
vacuum_multixact_freeze_table_age = 150000000
bytea_output = 'hex'
xmlbinary = 'base64'
xmloption = 'content'
gin_fuzzy_search_limit = 0
gin_pending_list_limit = 4MB

#------------------------------------------------------------------------------
# LOCK MANAGEMENT
#------------------------------------------------------------------------------
deadlock_timeout = 1s
max_locks_per_transaction = 64
max_pred_locks_per_transaction = 64

#------------------------------------------------------------------------------
# VERSION/PLATFORM COMPATIBILITY
#------------------------------------------------------------------------------
array_nulls = on
backslash_quote = safe_encoding
default_with_oids = off
escape_string_warning = on
lo_compat_privileges = off
operator_precedence_warning = off
quote_all_identifiers = off
sql_inheritance = on
standard_conforming_strings = on
synchronize_seqscans = on
transform_null_equals = off

#------------------------------------------------------------------------------
# ERROR HANDLING
#------------------------------------------------------------------------------
exit_on_error = off
restart_after_crash = on

#------------------------------------------------------------------------------
# CONFIG FILE INCLUDES
#------------------------------------------------------------------------------
# include_dir = 'conf.d'
# include_if_exists = 'exists.conf'
# include = 'special.conf'

#------------------------------------------------------------------------------
# CUSTOMIZED OPTIONS
#------------------------------------------------------------------------------
shared_preload_libraries = 'pg_stat_statements'
pg_stat_statements.max = 10000
pg_stat_statements.track = all
timezone = 'UTC'
datestyle = 'iso, mdy'
intervalstyle = 'postgres'
lc_messages = 'en_US.UTF-8'
lc_monetary = 'en_US.UTF-8'
lc_numeric = 'en_US.UTF-8'
lc_time = 'en_US.UTF-8'
default_text_search_config = 'pg_catalog.english'
EOF

    # Configurar pg_hba.conf
    sudo tee "$config_dir/pg_hba.conf" > /dev/null << EOF
# PostgreSQL Client Authentication Configuration File for DBA Lab
# TYPE  DATABASE        USER            ADDRESS                 METHOD

# "local" is for Unix domain socket connections only
local   all             postgres                                peer
local   all             all                                     md5

# IPv4 local connections:
host    all             all             127.0.0.1/32            md5
host    all             all             0.0.0.0/0               md5

# IPv6 local connections:
host    all             all             ::1/128                 md5

# Allow replication connections from localhost, by a user with the
# replication privilege.
local   replication     all                                     peer
host    replication     all             127.0.0.1/32            md5
host    replication     all             ::1/128                 md5
host    replication     all             0.0.0.0/0               md5
EOF

    # Crear directorio de archive
    sudo mkdir -p "/var/lib/postgresql/$POSTGRES_VERSION/main/archive"
    sudo chown postgres:postgres "/var/lib/postgresql/$POSTGRES_VERSION/main/archive"
    
    log "PostgreSQL configurado"
}

# Configurar servicio
configure_service() {
    info "Configurando servicio PostgreSQL..."
    
    # Habilitar servicio
    sudo systemctl enable postgresql || error "Fallo al habilitar servicio PostgreSQL"
    
    # Reiniciar servicio con nueva configuración
    sudo systemctl restart postgresql || error "Fallo al reiniciar PostgreSQL"
    
    # Verificar estado
    if sudo systemctl is-active --quiet postgresql; then
        log "Servicio PostgreSQL configurado y ejecutándose"
    else
        error "Servicio PostgreSQL no está ejecutándose"
    fi
}

# Crear usuarios de laboratorio
create_lab_users() {
    info "Creando usuarios de laboratorio..."
    
    # Crear roles base
    sudo -u postgres psql << EOF
-- Crear roles base
CREATE ROLE dba_role;
CREATE ROLE developer_role;
CREATE ROLE analyst_role;
CREATE ROLE app_role;

-- Configurar permisos de roles
GRANT CONNECT ON DATABASE postgres TO dba_role;
GRANT CREATE ON DATABASE postgres TO dba_role;
GRANT USAGE, CREATE ON SCHEMA public TO dba_role;

GRANT CONNECT ON DATABASE postgres TO developer_role;
GRANT USAGE ON SCHEMA public TO developer_role;

GRANT CONNECT ON DATABASE postgres TO analyst_role;
GRANT USAGE ON SCHEMA public TO analyst_role;

GRANT CONNECT ON DATABASE postgres TO app_role;
GRANT USAGE ON SCHEMA public TO app_role;

-- Crear usuarios
CREATE USER dbadmin WITH PASSWORD 'Admin123!' IN ROLE dba_role;
ALTER USER dbadmin CREATEDB CREATEROLE;

CREATE USER readonly WITH PASSWORD 'Read123!' IN ROLE analyst_role;
CREATE USER readwrite WITH PASSWORD 'Write123!' IN ROLE developer_role;
CREATE USER app_user WITH PASSWORD 'AppPass123!' IN ROLE app_role;

-- Usuario para backups
CREATE USER backup_user WITH PASSWORD 'BackupPass123!' REPLICATION;

-- Usuario para replicación
CREATE USER repl_user WITH PASSWORD 'ReplPass123!' REPLICATION;

-- Usuario para monitoreo
CREATE USER postgres_exporter WITH PASSWORD 'ExporterPass123!';
GRANT pg_monitor TO postgres_exporter;

-- Mostrar usuarios creados
\du
EOF

    log "Usuarios de laboratorio creados"
}

# Configurar firewall
configure_firewall() {
    info "Configurando firewall..."
    
    # Verificar si ufw está instalado
    if ! command -v ufw &> /dev/null; then
        sudo apt install -y ufw || error "Fallo al instalar ufw"
    fi
    
    # Configurar reglas básicas
    sudo ufw --force enable
    sudo ufw default deny incoming
    sudo ufw default allow outgoing
    
    # Permitir SSH (importante!)
    sudo ufw allow ssh
    
    # Permitir PostgreSQL
    sudo ufw allow 5432/tcp
    
    # Mostrar estado
    sudo ufw status verbose
    
    log "Firewall configurado"
}

# Crear base de datos de prueba
create_test_database() {
    info "Creando base de datos de prueba..."
    
    sudo -u postgres psql << 'EOF'
-- Crear base de datos de prueba
CREATE DATABASE lab_test WITH 
    OWNER = dbadmin
    ENCODING = 'UTF8'
    LC_COLLATE = 'en_US.UTF-8'
    LC_CTYPE = 'en_US.UTF-8'
    TABLESPACE = pg_default
    CONNECTION LIMIT = -1;

-- Conectar a la base de datos de prueba
\c lab_test

-- Crear extensiones útiles
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pg_stat_statements";

-- Crear tabla de usuarios
CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    username VARCHAR(50) UNIQUE NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    full_name VARCHAR(100) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Crear índices
CREATE INDEX idx_users_username ON users(username);
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_created ON users(created_at);

-- Crear tabla de logs
CREATE TABLE activity_logs (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id),
    action VARCHAR(100) NOT NULL,
    details TEXT,
    ip_address INET,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Crear índices para logs
CREATE INDEX idx_logs_user_action ON activity_logs(user_id, action);
CREATE INDEX idx_logs_created ON activity_logs(created_at);

-- Insertar datos de prueba
INSERT INTO users (username, email, full_name) VALUES
('admin', 'admin@lab.com', 'Administrator User'),
('testuser1', 'test1@lab.com', 'Test User One'),
('testuser2', 'test2@lab.com', 'Test User Two'),
('analyst', 'analyst@lab.com', 'Data Analyst'),
('developer', 'dev@lab.com', 'Developer User');

-- Insertar logs de prueba
INSERT INTO activity_logs (user_id, action, details, ip_address) VALUES
(1, 'LOGIN', 'Admin user logged in', '192.168.1.100'),
(2, 'CREATE', 'Created new record', '192.168.1.101'),
(3, 'UPDATE', 'Updated user profile', '192.168.1.102'),
(4, 'QUERY', 'Ran analytics query', '192.168.1.103'),
(5, 'LOGIN', 'Developer logged in', '192.168.1.104');

-- Crear función de ejemplo
CREATE OR REPLACE FUNCTION get_user_activity_count(p_user_id INTEGER)
RETURNS INTEGER AS $$
BEGIN
    RETURN (SELECT COUNT(*) FROM activity_logs WHERE user_id = p_user_id);
END;
$$ LANGUAGE plpgsql;

-- Otorgar permisos a roles
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO dba_role;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO dba_role;
GRANT ALL PRIVILEGES ON ALL FUNCTIONS IN SCHEMA public TO dba_role;

GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO developer_role;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO developer_role;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO developer_role;

GRANT SELECT ON ALL TABLES IN SCHEMA public TO analyst_role;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO analyst_role;

GRANT SELECT, INSERT, UPDATE, DELETE ON users, activity_logs TO app_role;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO app_role;

-- Mostrar estadísticas
SELECT 'Users created' as info, COUNT(*) as count FROM users
UNION ALL
SELECT 'Logs created' as info, COUNT(*) as count FROM activity_logs;

-- Mostrar información de la base de datos
SELECT 
    datname as database_name,
    pg_size_pretty(pg_database_size(datname)) as size,
    datcollate as collation,
    datctype as ctype
FROM pg_database 
WHERE datname = 'lab_test';
EOF

    log "Base de datos de prueba creada"
}

# Verificar instalación
verify_installation() {
    info "Verificando instalación..."
    
    # Verificar servicio
    if ! sudo systemctl is-active --quiet postgresql; then
        error "Servicio PostgreSQL no está ejecutándose"
    fi
    
    # Verificar puerto
    if ! netstat -tlnp | grep -q ":5432"; then
        error "PostgreSQL no está escuchando en puerto 5432"
    fi
    
    # Verificar conexión postgres
    if ! sudo -u postgres psql -c "SELECT version();" &>/dev/null; then
        error "No se puede conectar como postgres"
    fi
    
    # Verificar usuarios de laboratorio
    local users=("dbadmin" "readonly" "readwrite" "backup_user")
    for user in "${users[@]}"; do
        if ! sudo -u postgres psql -c "SELECT usename FROM pg_user WHERE usename='$user';" | grep -q "$user"; then
            error "Usuario $user no encontrado"
        fi
    done
    
    # Verificar base de datos de prueba
    if ! sudo -u postgres psql -d lab_test -c "SELECT COUNT(*) FROM users;" &>/dev/null; then
        error "Base de datos de prueba no accesible"
    fi
    
    log "Verificación completada exitosamente"
}

# Crear script de información del sistema
create_info_script() {
    info "Creando script de información..."
    
    cat > ~/postgresql_lab_info.sh << 'EOF'
#!/bin/bash
# Script de información del laboratorio PostgreSQL

echo "=== INFORMACIÓN DEL LABORATORIO POSTGRESQL ==="
echo "Fecha: $(date)"
echo

echo "=== VERSIÓN POSTGRESQL ==="
sudo -u postgres psql -c "SELECT version();"
echo

echo "=== ESTADO DEL SERVICIO ==="
sudo systemctl status postgresql --no-pager -l
echo

echo "=== USUARIOS CREADOS ==="
sudo -u postgres psql -c "\du"
echo

echo "=== BASES DE DATOS ==="
sudo -u postgres psql -c "\l"
echo

echo "=== CONFIGURACIÓN IMPORTANTE ==="
sudo -u postgres psql -c "SHOW listen_addresses;"
sudo -u postgres psql -c "SHOW port;"
sudo -u postgres psql -c "SHOW max_connections;"
sudo -u postgres psql -c "SHOW shared_buffers;"
sudo -u postgres psql -c "SHOW work_mem;"
echo

echo "=== FIREWALL STATUS ==="
sudo ufw status verbose
echo

echo "=== PUERTOS EN ESCUCHA ==="
netstat -tlnp | grep :5432
echo

echo "=== DATOS DE PRUEBA ==="
sudo -u postgres psql -d lab_test -c "SELECT COUNT(*) as users_count FROM users; SELECT COUNT(*) as logs_count FROM activity_logs;"
echo

echo "=== ESTADÍSTICAS DE ACTIVIDAD ==="
sudo -u postgres psql -d lab_test -c "SELECT schemaname, tablename, n_tup_ins, n_tup_upd, n_tup_del FROM pg_stat_user_tables;"
EOF

    chmod +x ~/postgresql_lab_info.sh
    log "Script de información creado en ~/postgresql_lab_info.sh"
}

# Mostrar resumen final
show_summary() {
    echo
    echo -e "${GREEN}=====================================${NC}"
    echo -e "${GREEN}  INSTALACIÓN POSTGRESQL COMPLETADA  ${NC}"
    echo -e "${GREEN}=====================================${NC}"
    echo
    echo -e "${BLUE}Información de conexión:${NC}"
    echo "  Host: localhost (o IP de esta máquina)"
    echo "  Puerto: 5432"
    echo "  Usuario postgres: postgres"
    echo "  Password postgres: $POSTGRES_PASSWORD"
    echo
    echo -e "${BLUE}Usuarios de laboratorio creados:${NC}"
    echo "  dbadmin / Admin123! (administrador completo)"
    echo "  readonly / Read123! (solo lectura)"
    echo "  readwrite / Write123! (CRUD)"
    echo "  app_user / AppPass123! (aplicación)"
    echo "  backup_user / BackupPass123! (backups)"
    echo "  repl_user / ReplPass123! (replicación)"
    echo "  postgres_exporter / ExporterPass123! (monitoreo)"
    echo
    echo -e "${BLUE}Base de datos de prueba:${NC}"
    echo "  Nombre: lab_test"
    echo "  Tablas: users, activity_logs"
    echo "  Extensiones: uuid-ossp, pg_stat_statements"
    echo "  Datos de prueba incluidos"
    echo
    echo -e "${BLUE}Archivos importantes:${NC}"
    echo "  Configuración: /etc/postgresql/$POSTGRES_VERSION/main/postgresql.conf"
    echo "  Autenticación: /etc/postgresql/$POSTGRES_VERSION/main/pg_hba.conf"
    echo "  Logs: /var/log/postgresql/postgresql-$POSTGRES_VERSION-main.log"
    echo "  Archive: /var/lib/postgresql/$POSTGRES_VERSION/main/archive/"
    echo "  Log de instalación: $LOG_FILE"
    echo "  Script de info: ~/postgresql_lab_info.sh"
    echo
    echo -e "${BLUE}Comandos útiles:${NC}"
    echo "  Conectar como postgres: sudo -u postgres psql"
    echo "  Conectar a lab_test: psql -U dbadmin -d lab_test -h localhost"
    echo "  Ver estado: sudo systemctl status postgresql"
    echo "  Ver logs: sudo tail -f /var/log/postgresql/postgresql-$POSTGRES_VERSION-main.log"
    echo "  Información del lab: ~/postgresql_lab_info.sh"
    echo
    echo -e "${GREEN}¡Instalación exitosa! PostgreSQL está listo para usar.${NC}"
    echo
}

# Función principal
main() {
    echo -e "${BLUE}====================================${NC}"
    echo -e "${BLUE}  INSTALADOR POSTGRESQL PARA LABS   ${NC}"
    echo -e "${BLUE}====================================${NC}"
    echo
    
    check_root
    check_os
    check_resources
    update_system
    install_dependencies
    configure_locales
    setup_postgresql_repo
    install_postgresql
    configure_postgresql
    configure_service
    create_lab_users
    configure_firewall
    create_test_database
    verify_installation
    create_info_script
    show_summary
}

# Ejecutar función principal
main "$@"
