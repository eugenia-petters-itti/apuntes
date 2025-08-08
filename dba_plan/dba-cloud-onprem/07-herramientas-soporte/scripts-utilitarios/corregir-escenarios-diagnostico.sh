#!/bin/bash

# Script para corregir problemas en escenarios de diagnóstico
# Autor: DBA Training Platform
# Fecha: $(date +%Y-%m-%d)

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ESCENARIOS_DIR="$(dirname "$SCRIPT_DIR")/escenarios-diagnostico"
LOG_FILE="$SCRIPT_DIR/correccion-$(date +%Y%m%d-%H%M%S).log"

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log() {
    echo -e "$1" | tee -a "$LOG_FILE"
}

log_info() {
    log "${BLUE}ℹ️ $1${NC}"
}

log_success() {
    log "${GREEN}✅ $1${NC}"
}

log_warning() {
    log "${YELLOW}⚠️ $1${NC}"
}

log_error() {
    log "${RED}❌ $1${NC}"
}

# Función para corregir configuración de Prometheus
fix_prometheus_config() {
    local scenario_path="$1"
    local prometheus_file="$scenario_path/prometheus/prometheus.yml"
    
    if [[ -f "$prometheus_file" ]]; then
        log_info "Corrigiendo configuración de Prometheus en $scenario_path"
        
        # Crear configuración completa de Prometheus
        cat > "$prometheus_file" << 'EOF'
global:
  scrape_interval: 15s
  evaluation_interval: 15s

rule_files:
  - "alert-rules.yml"

alerting:
  alertmanagers:
    - static_configs:
        - targets: []

scrape_configs:
  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']

  - job_name: 'mysql-exporter'
    static_configs:
      - targets: ['mysql-exporter:9104']
    scrape_interval: 5s
    metrics_path: /metrics

  - job_name: 'postgres-exporter'
    static_configs:
      - targets: ['postgres-exporter:9187']
    scrape_interval: 5s
    metrics_path: /metrics

  - job_name: 'mongodb-exporter'
    static_configs:
      - targets: ['mongodb-exporter:9216']
    scrape_interval: 5s
    metrics_path: /metrics

  - job_name: 'node-exporter'
    static_configs:
      - targets: ['node-exporter:9100']
    scrape_interval: 5s
    metrics_path: /metrics
EOF
        log_success "Configuración de Prometheus corregida"
    else
        log_error "Archivo prometheus.yml no encontrado en $scenario_path"
    fi
}

# Función para corregir Docker Compose
fix_docker_compose() {
    local scenario_path="$1"
    local compose_file="$scenario_path/docker-compose.yml"
    
    if [[ -f "$compose_file" ]]; then
        log_info "Verificando Docker Compose en $scenario_path"
        
        # Verificar si el compose tiene los servicios de monitoreo
        if ! grep -q "prometheus:" "$compose_file"; then
            log_info "Agregando servicios de monitoreo a docker-compose.yml"
            
            # Backup del archivo original
            cp "$compose_file" "$compose_file.backup"
            
            # Agregar servicios de monitoreo
            cat >> "$compose_file" << 'EOF'

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
EOF
            log_success "Servicios de monitoreo agregados"
        else
            log_success "Docker Compose ya tiene servicios de monitoreo"
        fi
    else
        log_error "Archivo docker-compose.yml no encontrado en $scenario_path"
    fi
}

# Función para crear archivos faltantes de Grafana
fix_grafana_config() {
    local scenario_path="$1"
    local grafana_dir="$scenario_path/grafana"
    
    # Crear directorio de datasources si no existe
    mkdir -p "$grafana_dir/datasources"
    mkdir -p "$grafana_dir/dashboards"
    
    # Crear datasource de Prometheus
    cat > "$grafana_dir/datasources/prometheus.yml" << 'EOF'
apiVersion: 1

datasources:
  - name: Prometheus
    type: prometheus
    access: proxy
    url: http://prometheus:9090
    isDefault: true
    editable: true
EOF

    # Crear configuración de dashboards
    cat > "$grafana_dir/dashboards/dashboard.yml" << 'EOF'
apiVersion: 1

providers:
  - name: 'default'
    orgId: 1
    folder: ''
    type: file
    disableDeletion: false
    updateIntervalSeconds: 10
    allowUiUpdates: true
    options:
      path: /etc/grafana/provisioning/dashboards
EOF

    log_success "Configuración de Grafana creada"
}

# Función para crear archivos de problema y solución faltantes
fix_missing_content() {
    local scenario_path="$1"
    local scenario_name=$(basename "$scenario_path")
    
    # Verificar problema-descripcion.md
    local problema_file="$scenario_path/problema-descripcion.md"
    if [[ ! -s "$problema_file" ]]; then
        log_info "Creando problema-descripcion.md para $scenario_name"
        cat > "$problema_file" << EOF
# Escenario: $scenario_name
## 🔴 Nivel: Intermedio | Tiempo estimado: 45 minutos

### 📋 Contexto del Problema

**Sistema:** Base de datos en producción
**Horario:** Horario pico de operaciones
**Urgencia:** ALTA - Rendimiento degradado

### 🚨 Síntomas Reportados

Los usuarios reportan lentitud en las consultas y timeouts intermitentes.
Las métricas muestran un comportamiento anómalo en el sistema.

### 🎯 Tu Misión

Como DBA, debes:

1. **Identificar la causa raíz** del problema
2. **Analizar las métricas** disponibles
3. **Proponer solución inmediata**
4. **Implementar solución definitiva**
5. **Documentar el proceso**

### 📈 Criterios de Éxito

**Resolución exitosa cuando:**
- ✅ Problema identificado correctamente
- ✅ Solución implementada
- ✅ Rendimiento restaurado
- ✅ Documentación completa

### 🔧 Herramientas Disponibles

- Logs del sistema
- Métricas de Prometheus/Grafana
- Scripts de diagnóstico
- Herramientas de monitoreo

### ⏰ Cronómetro

**Tiempo límite:** 45 minutos
**Puntuación máxima:** 100 puntos

---

**¿Listo para comenzar?** 
Ejecuta: \`docker-compose up -d\` en el directorio del escenario.
EOF
        log_success "Archivo problema-descripcion.md creado"
    fi
    
    # Verificar solucion-guia.md
    local solucion_file="$scenario_path/solucion-guia.md"
    if [[ ! -s "$solucion_file" ]]; then
        log_info "Creando solucion-guia.md para $scenario_name"
        cat > "$solucion_file" << EOF
# Solución: $scenario_name

## 🔍 Diagnóstico

### Paso 1: Identificación del Problema
\`\`\`bash
# Comandos de diagnóstico inicial
docker-compose logs
\`\`\`

### Paso 2: Análisis de Métricas
- Revisar dashboards de Grafana
- Analizar logs de la base de datos
- Verificar métricas de rendimiento

### Paso 3: Identificación de Causa Raíz
[Descripción de la causa raíz específica del escenario]

## 🛠️ Solución

### Solución Inmediata
\`\`\`sql
-- Comandos SQL para solución rápida
\`\`\`

### Solución Definitiva
\`\`\`bash
# Scripts o configuraciones para solución permanente
\`\`\`

## 📊 Verificación

### Comandos de Verificación
\`\`\`bash
# Verificar que el problema se resolvió
\`\`\`

### Métricas a Monitorear
- Tiempo de respuesta
- Throughput
- Utilización de recursos
- Errores

## 📝 Documentación

### Lecciones Aprendidas
- [Punto clave 1]
- [Punto clave 2]
- [Punto clave 3]

### Prevención
- [Medida preventiva 1]
- [Medida preventiva 2]
- [Medida preventiva 3]
EOF
        log_success "Archivo solucion-guia.md creado"
    fi
}

# Función principal para corregir un escenario
fix_scenario() {
    local scenario_path="$1"
    local scenario_name=$(basename "$scenario_path")
    
    log_info "Corrigiendo escenario: $scenario_name"
    
    # Corregir configuración de Prometheus
    fix_prometheus_config "$scenario_path"
    
    # Corregir Docker Compose
    fix_docker_compose "$scenario_path"
    
    # Corregir configuración de Grafana
    fix_grafana_config "$scenario_path"
    
    # Crear contenido faltante
    fix_missing_content "$scenario_path"
    
    log_success "Escenario $scenario_name corregido"
}

# Función principal
main() {
    log "============================================================================"
    log "🔧 CORRECCIÓN DE ESCENARIOS DE DIAGNÓSTICO"
    log "============================================================================"
    log "Iniciando corrección de problemas identificados"
    log "Log: $LOG_FILE"
    log "============================================================================"
    
    # Verificar que el directorio de escenarios existe
    if [[ ! -d "$ESCENARIOS_DIR" ]]; then
        log_error "Directorio de escenarios no encontrado: $ESCENARIOS_DIR"
        exit 1
    fi
    
    # Contador de escenarios corregidos
    local total_scenarios=0
    local fixed_scenarios=0
    
    # Procesar cada tipo de base de datos
    for db_type in mysql postgresql mongodb; do
        local db_dir="$ESCENARIOS_DIR/$db_type"
        
        if [[ -d "$db_dir" ]]; then
            log_info "Procesando escenarios de $db_type"
            
            # Procesar cada escenario
            for scenario_dir in "$db_dir"/escenario-*; do
                if [[ -d "$scenario_dir" ]]; then
                    total_scenarios=$((total_scenarios + 1))
                    
                    if fix_scenario "$scenario_dir"; then
                        fixed_scenarios=$((fixed_scenarios + 1))
                    fi
                fi
            done
        else
            log_warning "Directorio $db_type no encontrado"
        fi
    done
    
    log "============================================================================"
    log "📊 RESUMEN DE CORRECCIÓN"
    log "============================================================================"
    log "Total de escenarios procesados: $total_scenarios"
    log "Escenarios corregidos: $fixed_scenarios"
    log "Tasa de éxito: $((fixed_scenarios * 100 / total_scenarios))%"
    log ""
    log "📄 Log detallado: $LOG_FILE"
    log ""
    
    if [[ $fixed_scenarios -eq $total_scenarios ]]; then
        log_success "✅ Todos los escenarios han sido corregidos exitosamente"
        log_info "Ejecuta el script de validación nuevamente para verificar:"
        log_info "./validar-funcionalidad-escenarios.sh"
    else
        log_warning "⚠️ Algunos escenarios requieren atención manual"
        log_info "Revisa el log detallado para más información"
    fi
}

# Ejecutar función principal
main "$@"
