#!/bin/bash
# install_mysql_onprem.sh
# Script de instalación automatizada de MySQL OnPrem para laboratorios DBA
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
MYSQL_ROOT_PASSWORD="MyS3cur3P@ss!"
MYSQL_VERSION="8.0"
LOG_FILE="/var/log/mysql_installation.log"

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

# Configurar repositorio MySQL
setup_mysql_repo() {
    info "Configurando repositorio MySQL..."
    
    # Descargar y agregar clave GPG
    wget -qO - https://repo.mysql.com/RPM-GPG-KEY-mysql-2022 | sudo apt-key add - || error "Fallo al agregar clave GPG"
    
    # Agregar repositorio
    echo "deb http://repo.mysql.com/apt/ubuntu/ $(lsb_release -sc) mysql-apt-config" | sudo tee /etc/apt/sources.list.d/mysql.list
    echo "deb http://repo.mysql.com/apt/ubuntu/ $(lsb_release -sc) mysql-$MYSQL_VERSION" | sudo tee -a /etc/apt/sources.list.d/mysql.list
    echo "deb http://repo.mysql.com/apt/ubuntu/ $(lsb_release -sc) mysql-tools" | sudo tee -a /etc/apt/sources.list.d/mysql.list
    
    # Actualizar lista de paquetes
    sudo apt update || error "Fallo al actualizar después de agregar repositorio MySQL"
    
    log "Repositorio MySQL configurado"
}

# Preconfigurar MySQL
preconfigure_mysql() {
    info "Preconfigurando MySQL..."
    
    # Preconfigurar password root
    echo "mysql-server mysql-server/root_password password $MYSQL_ROOT_PASSWORD" | sudo debconf-set-selections
    echo "mysql-server mysql-server/root_password_again password $MYSQL_ROOT_PASSWORD" | sudo debconf-set-selections
    
    log "MySQL preconfigurado"
}

# Instalar MySQL
install_mysql() {
    info "Instalando MySQL Server..."
    
    # Instalar MySQL Server y cliente
    sudo DEBIAN_FRONTEND=noninteractive apt install -y mysql-server mysql-client || error "Fallo al instalar MySQL"
    
    log "MySQL Server instalado"
}

# Configurar MySQL
configure_mysql() {
    info "Configurando MySQL..."
    
    # Crear directorio de configuración personalizada
    sudo mkdir -p /etc/mysql/conf.d
    
    # Crear archivo de configuración personalizada
    sudo tee /etc/mysql/conf.d/lab-config.cnf > /dev/null << EOF
[mysqld]
# Configuración para laboratorio DBA
bind-address = 0.0.0.0
port = 3306

# Configuración de memoria
innodb_buffer_pool_size = 1G
innodb_log_file_size = 256M
innodb_log_buffer_size = 16M

# Configuración de conexiones
max_connections = 200
max_connect_errors = 1000000

# Configuración de logs
log_error = /var/log/mysql/error.log
slow_query_log = 1
slow_query_log_file = /var/log/mysql/slow.log
long_query_time = 2
log_queries_not_using_indexes = 1

# Configuración de binlog
log_bin = mysql-bin
binlog_format = ROW
expire_logs_days = 7
max_binlog_size = 100M

# Configuración de seguridad
local_infile = 0
skip_show_database

# Configuración de charset
character_set_server = utf8mb4
collation_server = utf8mb4_unicode_ci

# Configuración de timezone
default_time_zone = '+00:00'

[mysql]
default_character_set = utf8mb4

[client]
default_character_set = utf8mb4
EOF

    log "Archivo de configuración creado"
}

# Configurar servicio
configure_service() {
    info "Configurando servicio MySQL..."
    
    # Habilitar servicio
    sudo systemctl enable mysql || error "Fallo al habilitar servicio MySQL"
    
    # Reiniciar servicio con nueva configuración
    sudo systemctl restart mysql || error "Fallo al reiniciar MySQL"
    
    # Verificar estado
    if sudo systemctl is-active --quiet mysql; then
        log "Servicio MySQL configurado y ejecutándose"
    else
        error "Servicio MySQL no está ejecutándose"
    fi
}

# Configurar seguridad inicial
secure_mysql() {
    info "Configurando seguridad inicial..."
    
    # Crear script de seguridad personalizado
    cat > /tmp/mysql_secure.sql << EOF
-- Eliminar usuarios anónimos
DELETE FROM mysql.user WHERE User='';

-- Eliminar base de datos test
DROP DATABASE IF EXISTS test;
DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';

-- Deshabilitar login remoto para root (se habilitará después con restricciones)
DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');

-- Recargar privilegios
FLUSH PRIVILEGES;
EOF

    # Ejecutar script de seguridad
    mysql -u root -p"$MYSQL_ROOT_PASSWORD" < /tmp/mysql_secure.sql || error "Fallo al ejecutar configuración de seguridad"
    
    # Limpiar archivo temporal
    rm -f /tmp/mysql_secure.sql
    
    log "Configuración de seguridad aplicada"
}

# Crear usuarios de laboratorio
create_lab_users() {
    info "Creando usuarios de laboratorio..."
    
    cat > /tmp/create_users.sql << EOF
-- Crear usuarios para laboratorio
CREATE USER 'dbadmin'@'%' IDENTIFIED BY 'Admin123!';
GRANT ALL PRIVILEGES ON *.* TO 'dbadmin'@'%' WITH GRANT OPTION;

CREATE USER 'readonly'@'%' IDENTIFIED BY 'Read123!';
GRANT SELECT ON *.* TO 'readonly'@'%';

CREATE USER 'readwrite'@'%' IDENTIFIED BY 'Write123!';
GRANT SELECT, INSERT, UPDATE, DELETE ON *.* TO 'readwrite'@'%';

CREATE USER 'backup_user'@'localhost' IDENTIFIED BY 'BackupPass123!';
GRANT SELECT, LOCK TABLES, SHOW VIEW, EVENT, TRIGGER ON *.* TO 'backup_user'@'localhost';
GRANT RELOAD, PROCESS ON *.* TO 'backup_user'@'localhost';

CREATE USER 'repl_user'@'%' IDENTIFIED BY 'ReplPass123!';
GRANT REPLICATION SLAVE ON *.* TO 'repl_user'@'%';

CREATE USER 'exporter'@'localhost' IDENTIFIED BY 'ExporterPass123!';
GRANT PROCESS, REPLICATION CLIENT, SELECT ON *.* TO 'exporter'@'localhost';

-- Recargar privilegios
FLUSH PRIVILEGES;

-- Mostrar usuarios creados
SELECT user, host FROM mysql.user WHERE user NOT IN ('mysql.sys', 'mysql.session', 'mysql.infoschema');
EOF

    mysql -u root -p"$MYSQL_ROOT_PASSWORD" < /tmp/create_users.sql || error "Fallo al crear usuarios de laboratorio"
    rm -f /tmp/create_users.sql
    
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
    
    # Permitir MySQL
    sudo ufw allow 3306/tcp
    
    # Mostrar estado
    sudo ufw status verbose
    
    log "Firewall configurado"
}

# Crear base de datos de prueba
create_test_database() {
    info "Creando base de datos de prueba..."
    
    cat > /tmp/create_testdb.sql << EOF
-- Crear base de datos de prueba
CREATE DATABASE IF NOT EXISTS lab_test CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

USE lab_test;

-- Crear tabla de ejemplo
CREATE TABLE users (
    id INT PRIMARY KEY AUTO_INCREMENT,
    username VARCHAR(50) UNIQUE NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    full_name VARCHAR(100) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_username (username),
    INDEX idx_email (email),
    INDEX idx_created (created_at)
);

-- Insertar datos de prueba
INSERT INTO users (username, email, full_name) VALUES
('admin', 'admin@lab.com', 'Administrator User'),
('testuser1', 'test1@lab.com', 'Test User One'),
('testuser2', 'test2@lab.com', 'Test User Two'),
('analyst', 'analyst@lab.com', 'Data Analyst'),
('developer', 'dev@lab.com', 'Developer User');

-- Crear tabla de logs para pruebas
CREATE TABLE activity_logs (
    id INT PRIMARY KEY AUTO_INCREMENT,
    user_id INT,
    action VARCHAR(100) NOT NULL,
    details TEXT,
    ip_address VARCHAR(45),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id),
    INDEX idx_user_action (user_id, action),
    INDEX idx_created (created_at)
);

-- Insertar logs de prueba
INSERT INTO activity_logs (user_id, action, details, ip_address) VALUES
(1, 'LOGIN', 'Admin user logged in', '192.168.1.100'),
(2, 'CREATE', 'Created new record', '192.168.1.101'),
(3, 'UPDATE', 'Updated user profile', '192.168.1.102'),
(4, 'QUERY', 'Ran analytics query', '192.168.1.103'),
(5, 'LOGIN', 'Developer logged in', '192.168.1.104');

-- Mostrar estadísticas
SELECT 'Users created' as info, COUNT(*) as count FROM users
UNION ALL
SELECT 'Logs created' as info, COUNT(*) as count FROM activity_logs;
EOF

    mysql -u root -p"$MYSQL_ROOT_PASSWORD" < /tmp/create_testdb.sql || error "Fallo al crear base de datos de prueba"
    rm -f /tmp/create_testdb.sql
    
    log "Base de datos de prueba creada"
}

# Verificar instalación
verify_installation() {
    info "Verificando instalación..."
    
    # Verificar servicio
    if ! sudo systemctl is-active --quiet mysql; then
        error "Servicio MySQL no está ejecutándose"
    fi
    
    # Verificar puerto
    if ! netstat -tlnp | grep -q ":3306"; then
        error "MySQL no está escuchando en puerto 3306"
    fi
    
    # Verificar conexión root
    if ! mysql -u root -p"$MYSQL_ROOT_PASSWORD" -e "SELECT VERSION();" &>/dev/null; then
        error "No se puede conectar como root"
    fi
    
    # Verificar usuarios de laboratorio
    local users=("dbadmin" "readonly" "readwrite" "backup_user")
    for user in "${users[@]}"; do
        if ! mysql -u root -p"$MYSQL_ROOT_PASSWORD" -e "SELECT user FROM mysql.user WHERE user='$user';" | grep -q "$user"; then
            error "Usuario $user no encontrado"
        fi
    done
    
    # Verificar base de datos de prueba
    if ! mysql -u root -p"$MYSQL_ROOT_PASSWORD" -e "USE lab_test; SELECT COUNT(*) FROM users;" &>/dev/null; then
        error "Base de datos de prueba no accesible"
    fi
    
    log "Verificación completada exitosamente"
}

# Crear script de información del sistema
create_info_script() {
    info "Creando script de información..."
    
    cat > ~/mysql_lab_info.sh << 'EOF'
#!/bin/bash
# Script de información del laboratorio MySQL

echo "=== INFORMACIÓN DEL LABORATORIO MYSQL ==="
echo "Fecha: $(date)"
echo

echo "=== VERSIÓN MYSQL ==="
mysql -u root -p'MyS3cur3P@ss!' -e "SELECT VERSION();"
echo

echo "=== ESTADO DEL SERVICIO ==="
sudo systemctl status mysql --no-pager -l
echo

echo "=== USUARIOS CREADOS ==="
mysql -u root -p'MyS3cur3P@ss!' -e "SELECT user, host FROM mysql.user WHERE user NOT IN ('mysql.sys', 'mysql.session', 'mysql.infoschema');"
echo

echo "=== BASES DE DATOS ==="
mysql -u root -p'MyS3cur3P@ss!' -e "SHOW DATABASES;"
echo

echo "=== CONFIGURACIÓN IMPORTANTE ==="
mysql -u root -p'MyS3cur3P@ss!' -e "SHOW VARIABLES LIKE 'bind_address';"
mysql -u root -p'MyS3cur3P@ss!' -e "SHOW VARIABLES LIKE 'port';"
mysql -u root -p'MyS3cur3P@ss!' -e "SHOW VARIABLES LIKE 'max_connections';"
mysql -u root -p'MyS3cur3P@ss!' -e "SHOW VARIABLES LIKE 'innodb_buffer_pool_size';"
echo

echo "=== FIREWALL STATUS ==="
sudo ufw status verbose
echo

echo "=== PUERTOS EN ESCUCHA ==="
netstat -tlnp | grep :3306
echo

echo "=== DATOS DE PRUEBA ==="
mysql -u root -p'MyS3cur3P@ss!' -e "USE lab_test; SELECT COUNT(*) as users_count FROM users; SELECT COUNT(*) as logs_count FROM activity_logs;"
EOF

    chmod +x ~/mysql_lab_info.sh
    log "Script de información creado en ~/mysql_lab_info.sh"
}

# Mostrar resumen final
show_summary() {
    echo
    echo -e "${GREEN}================================${NC}"
    echo -e "${GREEN}  INSTALACIÓN MYSQL COMPLETADA  ${NC}"
    echo -e "${GREEN}================================${NC}"
    echo
    echo -e "${BLUE}Información de conexión:${NC}"
    echo "  Host: localhost (o IP de esta máquina)"
    echo "  Puerto: 3306"
    echo "  Usuario root: root"
    echo "  Password root: $MYSQL_ROOT_PASSWORD"
    echo
    echo -e "${BLUE}Usuarios de laboratorio creados:${NC}"
    echo "  dbadmin / Admin123! (todos los privilegios)"
    echo "  readonly / Read123! (solo lectura)"
    echo "  readwrite / Write123! (CRUD)"
    echo "  backup_user / BackupPass123! (backups)"
    echo "  repl_user / ReplPass123! (replicación)"
    echo "  exporter / ExporterPass123! (monitoreo)"
    echo
    echo -e "${BLUE}Base de datos de prueba:${NC}"
    echo "  Nombre: lab_test"
    echo "  Tablas: users, activity_logs"
    echo "  Datos de prueba incluidos"
    echo
    echo -e "${BLUE}Archivos importantes:${NC}"
    echo "  Configuración: /etc/mysql/conf.d/lab-config.cnf"
    echo "  Log de errores: /var/log/mysql/error.log"
    echo "  Log de queries lentas: /var/log/mysql/slow.log"
    echo "  Log de instalación: $LOG_FILE"
    echo "  Script de info: ~/mysql_lab_info.sh"
    echo
    echo -e "${BLUE}Comandos útiles:${NC}"
    echo "  Conectar como root: mysql -u root -p"
    echo "  Ver estado: sudo systemctl status mysql"
    echo "  Ver logs: sudo tail -f /var/log/mysql/error.log"
    echo "  Información del lab: ~/mysql_lab_info.sh"
    echo
    echo -e "${GREEN}¡Instalación exitosa! MySQL está listo para usar.${NC}"
    echo
}

# Función principal
main() {
    echo -e "${BLUE}================================${NC}"
    echo -e "${BLUE}  INSTALADOR MYSQL PARA LABS    ${NC}"
    echo -e "${BLUE}================================${NC}"
    echo
    
    check_root
    check_os
    check_resources
    update_system
    install_dependencies
    setup_mysql_repo
    preconfigure_mysql
    install_mysql
    configure_mysql
    configure_service
    secure_mysql
    create_lab_users
    configure_firewall
    create_test_database
    verify_installation
    create_info_script
    show_summary
}

# Ejecutar función principal
main "$@"
