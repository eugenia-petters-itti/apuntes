#!/bin/bash
# install_mongodb_onprem.sh
# Script de instalación automatizada de MongoDB OnPrem para laboratorios DBA
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
MONGODB_VERSION="6.0"
ADMIN_PASSWORD="AdminPass123!"
LOG_FILE="/var/log/mongodb_installation.log"

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
        "openssl"
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

# Configurar repositorio MongoDB
setup_mongodb_repo() {
    info "Configurando repositorio MongoDB..."
    
    # Importar clave pública de MongoDB
    wget -qO - https://www.mongodb.org/static/pgp/server-$MONGODB_VERSION.asc | sudo apt-key add - || error "Fallo al agregar clave GPG"
    
    # Crear archivo de lista de fuentes
    echo "deb [ arch=amd64,arm64 ] https://repo.mongodb.org/apt/ubuntu $(lsb_release -sc)/mongodb-org/$MONGODB_VERSION multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-$MONGODB_VERSION.list
    
    # Actualizar lista de paquetes
    sudo apt update || error "Fallo al actualizar después de agregar repositorio MongoDB"
    
    log "Repositorio MongoDB configurado"
}

# Instalar MongoDB
install_mongodb() {
    info "Instalando MongoDB $MONGODB_VERSION..."
    
    # Instalar MongoDB y herramientas
    sudo apt install -y \
        mongodb-org \
        mongodb-database-tools \
        mongodb-mongosh \
        || error "Fallo al instalar MongoDB"
    
    # Prevenir actualizaciones automáticas
    echo "mongodb-org hold" | sudo dpkg --set-selections
    echo "mongodb-org-database hold" | sudo dpkg --set-selections
    echo "mongodb-org-server hold" | sudo dpkg --set-selections
    echo "mongodb-org-shell hold" | sudo dpkg --set-selections
    echo "mongodb-org-mongos hold" | sudo dpkg --set-selections
    echo "mongodb-org-tools hold" | sudo dpkg --set-selections
    
    log "MongoDB $MONGODB_VERSION instalado"
}

# Configurar MongoDB
configure_mongodb() {
    info "Configurando MongoDB..."
    
    # Crear directorios necesarios
    sudo mkdir -p /var/lib/mongodb
    sudo mkdir -p /var/log/mongodb
    sudo mkdir -p /etc/ssl/mongodb
    
    # Configurar permisos
    sudo chown mongodb:mongodb /var/lib/mongodb
    sudo chown mongodb:mongodb /var/log/mongodb
    sudo chown mongodb:mongodb /etc/ssl/mongodb
    
    # Backup de configuración original
    sudo cp /etc/mongod.conf /etc/mongod.conf.backup
    
    # Crear archivo de configuración
    sudo tee /etc/mongod.conf > /dev/null << EOF
# mongod.conf - MongoDB configuration for DBA Lab

# Where to store data
storage:
  dbPath: /var/lib/mongodb
  journal:
    enabled: true
  engine: wiredTiger
  wiredTiger:
    engineConfig:
      cacheSizeGB: 1
      journalCompressor: snappy
      directoryForIndexes: false
    collectionConfig:
      blockCompressor: snappy
    indexConfig:
      prefixCompression: true

# Where to write logging data
systemLog:
  destination: file
  logAppend: true
  path: /var/log/mongodb/mongod.log
  logRotate: rename
  verbosity: 0
  component:
    accessControl:
      verbosity: 0
    command:
      verbosity: 0

# Network interfaces
net:
  port: 27017
  bindIp: 0.0.0.0
  maxIncomingConnections: 200
  wireObjectCheck: true
  ipv6: false

# Process management
processManagement:
  timeZoneInfo: /usr/share/zoneinfo
  fork: true
  pidFilePath: /var/run/mongodb/mongod.pid

# Security
security:
  authorization: enabled
  keyFile: /etc/ssl/mongodb/mongodb-keyfile

# Replication
replication:
  replSetName: "rs0"

# Sharding (disabled for single instance)
#sharding:

# Enterprise-Only Options
#auditLog:

# SNMP (disabled)
#snmp:

# Profiling and Monitoring
operationProfiling:
  slowOpThresholdMs: 1000
  mode: slowOp

# SetParameter options
setParameter:
  enableLocalhostAuthBypass: false
  authenticationMechanisms: SCRAM-SHA-1,SCRAM-SHA-256
EOF

    log "MongoDB configurado"
}

# Crear certificados SSL
create_ssl_certificates() {
    info "Creando certificados SSL..."
    
    cd /etc/ssl/mongodb
    
    # Generar clave privada
    sudo openssl genrsa -out mongodb-server.key 2048
    
    # Generar certificado auto-firmado
    sudo openssl req -new -x509 -key mongodb-server.key -out mongodb-server.crt -days 365 -subj "/C=US/ST=State/L=City/O=Organization/OU=IT/CN=mongodb-server"
    
    # Combinar clave y certificado
    sudo cat mongodb-server.key mongodb-server.crt > mongodb-server.pem
    
    # Crear keyfile para replica set
    sudo openssl rand -base64 756 > mongodb-keyfile
    
    # Configurar permisos
    sudo chown mongodb:mongodb /etc/ssl/mongodb/*
    sudo chmod 600 /etc/ssl/mongodb/mongodb-server.key
    sudo chmod 644 /etc/ssl/mongodb/mongodb-server.crt
    sudo chmod 600 /etc/ssl/mongodb/mongodb-server.pem
    sudo chmod 600 /etc/ssl/mongodb/mongodb-keyfile
    
    log "Certificados SSL creados"
}

# Configurar servicio
configure_service() {
    info "Configurando servicio MongoDB..."
    
    # Habilitar servicio
    sudo systemctl enable mongod || error "Fallo al habilitar servicio MongoDB"
    
    # Iniciar servicio
    sudo systemctl start mongod || error "Fallo al iniciar MongoDB"
    
    # Verificar estado
    if sudo systemctl is-active --quiet mongod; then
        log "Servicio MongoDB configurado y ejecutándose"
    else
        error "Servicio MongoDB no está ejecutándose"
    fi
}

# Configurar replica set
configure_replica_set() {
    info "Configurando replica set..."
    
    # Esperar a que MongoDB esté listo
    sleep 5
    
    # Inicializar replica set
    mongosh --eval "
    rs.initiate({
      _id: 'rs0',
      members: [
        { _id: 0, host: 'localhost:27017' }
      ]
    })
    " || error "Fallo al inicializar replica set"
    
    # Esperar a que el replica set esté listo
    sleep 10
    
    log "Replica set configurado"
}

# Crear usuarios de administración
create_admin_users() {
    info "Creando usuarios de administración..."
    
    # Crear usuario administrador
    mongosh --eval "
    use admin
    db.createUser({
      user: 'admin',
      pwd: '$ADMIN_PASSWORD',
      roles: [
        { role: 'userAdminAnyDatabase', db: 'admin' },
        { role: 'readWriteAnyDatabase', db: 'admin' },
        { role: 'dbAdminAnyDatabase', db: 'admin' },
        { role: 'clusterAdmin', db: 'admin' }
      ]
    })
    " || error "Fallo al crear usuario administrador"
    
    log "Usuario administrador creado"
}

# Reiniciar con autenticación
restart_with_auth() {
    info "Reiniciando MongoDB con autenticación..."
    
    # Detener MongoDB
    sudo systemctl stop mongod
    
    # Actualizar configuración para habilitar SSL
    sudo tee /etc/mongod.conf > /dev/null << EOF
# mongod.conf - MongoDB configuration for DBA Lab with SSL

# Where to store data
storage:
  dbPath: /var/lib/mongodb
  journal:
    enabled: true
  engine: wiredTiger
  wiredTiger:
    engineConfig:
      cacheSizeGB: 1
      journalCompressor: snappy
      directoryForIndexes: false
    collectionConfig:
      blockCompressor: snappy
    indexConfig:
      prefixCompression: true

# Where to write logging data
systemLog:
  destination: file
  logAppend: true
  path: /var/log/mongodb/mongod.log
  logRotate: rename
  verbosity: 0

# Network interfaces
net:
  port: 27017
  bindIp: 0.0.0.0
  maxIncomingConnections: 200
  tls:
    mode: requireTLS
    certificateKeyFile: /etc/ssl/mongodb/mongodb-server.pem
    allowConnectionsWithoutCertificates: true

# Process management
processManagement:
  timeZoneInfo: /usr/share/zoneinfo
  fork: true
  pidFilePath: /var/run/mongodb/mongod.pid

# Security
security:
  authorization: enabled
  keyFile: /etc/ssl/mongodb/mongodb-keyfile

# Replication
replication:
  replSetName: "rs0"

# Profiling and Monitoring
operationProfiling:
  slowOpThresholdMs: 1000
  mode: slowOp

# SetParameter options
setParameter:
  enableLocalhostAuthBypass: false
  authenticationMechanisms: SCRAM-SHA-1,SCRAM-SHA-256
EOF

    # Reiniciar MongoDB
    sudo systemctl start mongod || error "Fallo al reiniciar MongoDB con SSL"
    
    # Esperar a que esté listo
    sleep 10
    
    log "MongoDB reiniciado con SSL y autenticación"
}

# Crear usuarios de laboratorio
create_lab_users() {
    info "Creando usuarios de laboratorio..."
    
    # Conectar con SSL y crear usuarios
    mongosh --tls --tlsAllowInvalidCertificates -u admin -p "$ADMIN_PASSWORD" --authenticationDatabase admin --eval "
    use admin
    
    // Crear usuario desarrollador
    db.createUser({
      user: 'developer',
      pwd: 'DevPass123!',
      roles: [
        { role: 'readWrite', db: 'lab_test' },
        { role: 'dbAdmin', db: 'lab_test' }
      ]
    })
    
    // Crear usuario analista (solo lectura)
    db.createUser({
      user: 'analyst',
      pwd: 'AnalystPass123!',
      roles: [
        { role: 'read', db: 'lab_test' }
      ]
    })
    
    // Crear usuario aplicación
    db.createUser({
      user: 'app_user',
      pwd: 'AppPass123!',
      roles: [
        { role: 'readWrite', db: 'lab_test' }
      ]
    })
    
    // Crear usuario backup
    db.createUser({
      user: 'backup_user',
      pwd: 'BackupPass123!',
      roles: [
        { role: 'backup', db: 'admin' },
        { role: 'readAnyDatabase', db: 'admin' }
      ]
    })
    
    // Listar usuarios
    db.getUsers()
    " || error "Fallo al crear usuarios de laboratorio"
    
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
    
    # Permitir MongoDB
    sudo ufw allow 27017/tcp
    
    # Mostrar estado
    sudo ufw status verbose
    
    log "Firewall configurado"
}

# Crear base de datos de prueba
create_test_database() {
    info "Creando base de datos de prueba..."
    
    mongosh --tls --tlsAllowInvalidCertificates -u admin -p "$ADMIN_PASSWORD" --authenticationDatabase admin --eval "
    use lab_test
    
    // Crear colección de usuarios
    db.users.insertMany([
      {
        username: 'admin',
        email: 'admin@lab.com',
        fullName: 'Administrator User',
        role: 'admin',
        createdAt: new Date(),
        isActive: true
      },
      {
        username: 'testuser1',
        email: 'test1@lab.com',
        fullName: 'Test User One',
        role: 'user',
        createdAt: new Date(),
        isActive: true
      },
      {
        username: 'analyst',
        email: 'analyst@lab.com',
        fullName: 'Data Analyst',
        role: 'analyst',
        createdAt: new Date(),
        isActive: true
      }
    ])
    
    // Crear colección de productos
    db.products.insertMany([
      {
        name: 'Laptop Dell XPS 13',
        price: 899.99,
        category: 'Electronics',
        stock: 10,
        tags: ['laptop', 'dell', 'portable'],
        createdAt: new Date()
      },
      {
        name: 'Mouse Logitech',
        price: 29.99,
        category: 'Electronics',
        stock: 50,
        tags: ['mouse', 'logitech', 'wireless'],
        createdAt: new Date()
      }
    ])
    
    // Crear índices
    db.users.createIndex({ username: 1 }, { unique: true })
    db.users.createIndex({ email: 1 }, { unique: true })
    db.products.createIndex({ category: 1, price: 1 })
    db.products.createIndex({ tags: 1 })
    
    // Mostrar estadísticas
    print('Users created:', db.users.countDocuments())
    print('Products created:', db.products.countDocuments())
    print('Indexes created:', db.users.getIndexes().length + db.products.getIndexes().length)
    " || error "Fallo al crear base de datos de prueba"
    
    log "Base de datos de prueba creada"
}

# Verificar instalación
verify_installation() {
    info "Verificando instalación..."
    
    # Verificar servicio
    if ! sudo systemctl is-active --quiet mongod; then
        error "Servicio MongoDB no está ejecutándose"
    fi
    
    # Verificar puerto
    if ! netstat -tlnp | grep -q ":27017"; then
        error "MongoDB no está escuchando en puerto 27017"
    fi
    
    # Verificar conexión con SSL
    if ! mongosh --tls --tlsAllowInvalidCertificates -u admin -p "$ADMIN_PASSWORD" --authenticationDatabase admin --eval "db.adminCommand('ismaster')" &>/dev/null; then
        error "No se puede conectar a MongoDB con SSL"
    fi
    
    # Verificar replica set
    if ! mongosh --tls --tlsAllowInvalidCertificates -u admin -p "$ADMIN_PASSWORD" --authenticationDatabase admin --eval "rs.status()" &>/dev/null; then
        error "Replica set no está funcionando"
    fi
    
    log "Verificación completada exitosamente"
}

# Crear script de información del sistema
create_info_script() {
    info "Creando script de información..."
    
    cat > ~/mongodb_lab_info.sh << 'EOF'
#!/bin/bash
# Script de información del laboratorio MongoDB

echo "=== INFORMACIÓN DEL LABORATORIO MONGODB ==="
echo "Fecha: $(date)"
echo

echo "=== VERSIÓN MONGODB ==="
mongosh --tls --tlsAllowInvalidCertificates -u admin -p'AdminPass123!' --authenticationDatabase admin --quiet --eval "db.version()"
echo

echo "=== ESTADO DEL SERVICIO ==="
sudo systemctl status mongod --no-pager -l
echo

echo "=== ESTADO DEL REPLICA SET ==="
mongosh --tls --tlsAllowInvalidCertificates -u admin -p'AdminPass123!' --authenticationDatabase admin --quiet --eval "rs.status().members.forEach(function(member) { print('Member:', member.name, 'State:', member.stateStr) })"
echo

echo "=== USUARIOS CREADOS ==="
mongosh --tls --tlsAllowInvalidCertificates -u admin -p'AdminPass123!' --authenticationDatabase admin --quiet --eval "db.getUsers().forEach(function(user) { print('User:', user.user, 'Roles:', user.roles.map(r => r.role).join(', ')) })"
echo

echo "=== BASES DE DATOS ==="
mongosh --tls --tlsAllowInvalidCertificates -u admin -p'AdminPass123!' --authenticationDatabase admin --quiet --eval "db.adminCommand('listDatabases').databases.forEach(function(db) { print('Database:', db.name, 'Size:', (db.sizeOnDisk/1024/1024).toFixed(2) + 'MB') })"
echo

echo "=== FIREWALL STATUS ==="
sudo ufw status verbose
echo

echo "=== PUERTOS EN ESCUCHA ==="
netstat -tlnp | grep :27017
echo

echo "=== DATOS DE PRUEBA ==="
mongosh --tls --tlsAllowInvalidCertificates -u admin -p'AdminPass123!' --authenticationDatabase admin --quiet --eval "
use lab_test
print('Users count:', db.users.countDocuments())
print('Products count:', db.products.countDocuments())
"
EOF

    chmod +x ~/mongodb_lab_info.sh
    log "Script de información creado en ~/mongodb_lab_info.sh"
}

# Mostrar resumen final
show_summary() {
    echo
    echo -e "${GREEN}===================================${NC}"
    echo -e "${GREEN}  INSTALACIÓN MONGODB COMPLETADA   ${NC}"
    echo -e "${GREEN}===================================${NC}"
    echo
    echo -e "${BLUE}Información de conexión:${NC}"
    echo "  Host: localhost (o IP de esta máquina)"
    echo "  Puerto: 27017"
    echo "  SSL: Habilitado (certificado auto-firmado)"
    echo "  Usuario admin: admin"
    echo "  Password admin: $ADMIN_PASSWORD"
    echo
    echo -e "${BLUE}Usuarios de laboratorio creados:${NC}"
    echo "  admin / AdminPass123! (administrador completo)"
    echo "  developer / DevPass123! (desarrollo)"
    echo "  analyst / AnalystPass123! (solo lectura)"
    echo "  app_user / AppPass123! (aplicación)"
    echo "  backup_user / BackupPass123! (backups)"
    echo
    echo -e "${BLUE}Base de datos de prueba:${NC}"
    echo "  Nombre: lab_test"
    echo "  Colecciones: users, products"
    echo "  Datos de prueba incluidos"
    echo "  Índices creados"
    echo
    echo -e "${BLUE}Archivos importantes:${NC}"
    echo "  Configuración: /etc/mongod.conf"
    echo "  Logs: /var/log/mongodb/mongod.log"
    echo "  SSL Cert: /etc/ssl/mongodb/mongodb-server.pem"
    echo "  Keyfile: /etc/ssl/mongodb/mongodb-keyfile"
    echo "  Log de instalación: $LOG_FILE"
    echo "  Script de info: ~/mongodb_lab_info.sh"
    echo
    echo -e "${BLUE}Comandos útiles:${NC}"
    echo "  Conectar como admin: mongosh --tls --tlsAllowInvalidCertificates -u admin -p --authenticationDatabase admin"
    echo "  Ver estado: sudo systemctl status mongod"
    echo "  Ver logs: sudo tail -f /var/log/mongodb/mongod.log"
    echo "  Información del lab: ~/mongodb_lab_info.sh"
    echo
    echo -e "${GREEN}¡Instalación exitosa! MongoDB está listo para usar.${NC}"
    echo
}

# Función principal
main() {
    echo -e "${BLUE}================================${NC}"
    echo -e "${BLUE}  INSTALADOR MONGODB PARA LABS   ${NC}"
    echo -e "${BLUE}================================${NC}"
    echo
    
    check_root
    check_os
    check_resources
    update_system
    install_dependencies
    setup_mongodb_repo
    install_mongodb
    configure_mongodb
    create_ssl_certificates
    configure_service
    configure_replica_set
    create_admin_users
    restart_with_auth
    create_lab_users
    configure_firewall
    create_test_database
    verify_installation
    create_info_script
    show_summary
}

# Ejecutar función principal
main "$@"
