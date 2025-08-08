#!/bin/bash

# Script para corregir formato de docker-compose.yml
# Autor: DBA Training Platform

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ESCENARIOS_DIR="$(dirname "$SCRIPT_DIR")/escenarios-diagnostico"

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${BLUE}ℹ️ $1${NC}"
}

log_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

log_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Función para corregir un archivo docker-compose.yml
fix_compose_file() {
    local compose_file="$1"
    local temp_file="${compose_file}.temp"
    
    if [[ ! -f "$compose_file" ]]; then
        log_error "Archivo no encontrado: $compose_file"
        return 1
    fi
    
    log_info "Corrigiendo formato de $(basename "$compose_file")"
    
    # Crear archivo temporal con formato correcto
    cat > "$temp_file" << 'EOF'
version: '3.8'

services:
  mysql-db:
    image: mysql:8.0
    container_name: escenario-mysql
    environment:
      MYSQL_ROOT_PASSWORD: dba2024!
      MYSQL_DATABASE: training_db
      MYSQL_USER: app_user
      MYSQL_PASSWORD: app_pass
    ports:
      - "3306:3306"
    volumes:
      - ./init-scripts:/docker-entrypoint-initdb.d
    networks:
      - db-network

  simulator:
    build: ./simuladores
    container_name: escenario-simulator
    depends_on:
      - mysql-db
    environment:
      DB_HOST: mysql-db
      DB_USER: app_user
      DB_PASS: app_pass
      DB_NAME: training_db
    networks:
      - db-network

  prometheus:
    image: prom/prometheus:latest
    container_name: prometheus
    ports:
      - "9090:9090"
    volumes:
      - ./prometheus:/etc/prometheus
    command:
      - '--config.file=/etc/prometheus/prometheus.yml'
      - '--storage.tsdb.path=/prometheus'
      - '--web.console.libraries=/etc/prometheus/console_libraries'
      - '--web.console.templates=/etc/prometheus/consoles'
      - '--web.enable-lifecycle'
    networks:
      - db-network

  grafana:
    image: grafana/grafana:latest
    container_name: grafana
    ports:
      - "3000:3000"
    volumes:
      - ./grafana/datasources:/etc/grafana/provisioning/datasources
      - ./grafana/dashboards:/etc/grafana/provisioning/dashboards
    environment:
      - GF_SECURITY_ADMIN_PASSWORD=admin123
    networks:
      - db-network

  mysql-exporter:
    image: prom/mysqld-exporter:latest
    container_name: mysql-exporter
    ports:
      - "9104:9104"
    environment:
      - DATA_SOURCE_NAME=app_user:app_pass@(mysql-db:3306)/training_db
    depends_on:
      - mysql-db
    networks:
      - db-network

networks:
  db-network:
    driver: bridge
EOF
    
    # Reemplazar archivo original
    mv "$temp_file" "$compose_file"
    log_success "Archivo corregido: $(basename "$compose_file")"
}

# Función para crear docker-compose específico para PostgreSQL
create_postgres_compose() {
    local compose_file="$1"
    local temp_file="${compose_file}.temp"
    
    cat > "$temp_file" << 'EOF'
version: '3.8'

services:
  postgres-db:
    image: postgres:15
    container_name: escenario-postgres
    environment:
      POSTGRES_DB: training_db
      POSTGRES_USER: app_user
      POSTGRES_PASSWORD: app_pass
    ports:
      - "5432:5432"
    volumes:
      - ./init-scripts:/docker-entrypoint-initdb.d
    networks:
      - db-network

  simulator:
    build: ./simuladores
    container_name: escenario-simulator
    depends_on:
      - postgres-db
    environment:
      DB_HOST: postgres-db
      DB_USER: app_user
      DB_PASS: app_pass
      DB_NAME: training_db
    networks:
      - db-network

  prometheus:
    image: prom/prometheus:latest
    container_name: prometheus
    ports:
      - "9090:9090"
    volumes:
      - ./prometheus:/etc/prometheus
    command:
      - '--config.file=/etc/prometheus/prometheus.yml'
      - '--storage.tsdb.path=/prometheus'
      - '--web.console.libraries=/etc/prometheus/console_libraries'
      - '--web.console.templates=/etc/prometheus/consoles'
      - '--web.enable-lifecycle'
    networks:
      - db-network

  grafana:
    image: grafana/grafana:latest
    container_name: grafana
    ports:
      - "3000:3000"
    volumes:
      - ./grafana/datasources:/etc/grafana/provisioning/datasources
      - ./grafana/dashboards:/etc/grafana/provisioning/dashboards
    environment:
      - GF_SECURITY_ADMIN_PASSWORD=admin123
    networks:
      - db-network

  postgres-exporter:
    image: prometheuscommunity/postgres-exporter:latest
    container_name: postgres-exporter
    ports:
      - "9187:9187"
    environment:
      - DATA_SOURCE_NAME=postgresql://app_user:app_pass@postgres-db:5432/training_db?sslmode=disable
    depends_on:
      - postgres-db
    networks:
      - db-network

networks:
  db-network:
    driver: bridge
EOF
    
    mv "$temp_file" "$compose_file"
}

# Función para crear docker-compose específico para MongoDB
create_mongodb_compose() {
    local compose_file="$1"
    local temp_file="${compose_file}.temp"
    
    cat > "$temp_file" << 'EOF'
version: '3.8'

services:
  mongodb:
    image: mongo:6.0
    container_name: escenario-mongodb
    environment:
      MONGO_INITDB_ROOT_USERNAME: admin
      MONGO_INITDB_ROOT_PASSWORD: admin123
      MONGO_INITDB_DATABASE: training_db
    ports:
      - "27017:27017"
    volumes:
      - ./init-scripts:/docker-entrypoint-initdb.d
    networks:
      - db-network

  simulator:
    build: ./simuladores
    container_name: escenario-simulator
    depends_on:
      - mongodb
    environment:
      DB_HOST: mongodb
      DB_USER: admin
      DB_PASS: admin123
      DB_NAME: training_db
    networks:
      - db-network

  prometheus:
    image: prom/prometheus:latest
    container_name: prometheus
    ports:
      - "9090:9090"
    volumes:
      - ./prometheus:/etc/prometheus
    command:
      - '--config.file=/etc/prometheus/prometheus.yml'
      - '--storage.tsdb.path=/prometheus'
      - '--web.console.libraries=/etc/prometheus/console_libraries'
      - '--web.console.templates=/etc/prometheus/consoles'
      - '--web.enable-lifecycle'
    networks:
      - db-network

  grafana:
    image: grafana/grafana:latest
    container_name: grafana
    ports:
      - "3000:3000"
    volumes:
      - ./grafana/datasources:/etc/grafana/provisioning/datasources
      - ./grafana/dashboards:/etc/grafana/provisioning/dashboards
    environment:
      - GF_SECURITY_ADMIN_PASSWORD=admin123
    networks:
      - db-network

  mongodb-exporter:
    image: percona/mongodb_exporter:latest
    container_name: mongodb-exporter
    ports:
      - "9216:9216"
    environment:
      - MONGODB_URI=mongodb://admin:admin123@mongodb:27017
    depends_on:
      - mongodb
    networks:
      - db-network

networks:
  db-network:
    driver: bridge
EOF
    
    mv "$temp_file" "$compose_file"
}

# Función principal
main() {
    echo "============================================================================"
    echo "🔧 CORRECCIÓN DE FORMATO DOCKER-COMPOSE"
    echo "============================================================================"
    
    local total_fixed=0
    
    # Procesar escenarios de MySQL
    for scenario_dir in "$ESCENARIOS_DIR"/mysql/escenario-*; do
        if [[ -d "$scenario_dir" ]]; then
            fix_compose_file "$scenario_dir/docker-compose.yml"
            total_fixed=$((total_fixed + 1))
        fi
    done
    
    # Procesar escenarios de PostgreSQL
    for scenario_dir in "$ESCENARIOS_DIR"/postgresql/escenario-*; do
        if [[ -d "$scenario_dir" ]]; then
            create_postgres_compose "$scenario_dir/docker-compose.yml"
            log_success "PostgreSQL compose creado: $(basename "$scenario_dir")"
            total_fixed=$((total_fixed + 1))
        fi
    done
    
    # Procesar escenarios de MongoDB
    for scenario_dir in "$ESCENARIOS_DIR"/mongodb/escenario-*; do
        if [[ -d "$scenario_dir" ]]; then
            create_mongodb_compose "$scenario_dir/docker-compose.yml"
            log_success "MongoDB compose creado: $(basename "$scenario_dir")"
            total_fixed=$((total_fixed + 1))
        fi
    done
    
    echo "============================================================================"
    echo "📊 RESUMEN"
    echo "============================================================================"
    echo "Total de archivos corregidos: $total_fixed"
    log_success "Todos los archivos docker-compose.yml han sido corregidos"
    echo ""
    log_info "Ahora puedes ejecutar la validación nuevamente:"
    log_info "./validar-funcionalidad-escenarios.sh"
}

# Ejecutar función principal
main "$@"
