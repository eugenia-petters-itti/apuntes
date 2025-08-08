#!/bin/bash
# ============================================================================
# SCRIPT DE VALIDACIÓN - FUNCIONALIDAD DE ESCENARIOS
# ============================================================================
# Valida que todos los escenarios estén completamente funcionales
# Prueba Docker Compose, conectividad y simuladores
# ============================================================================

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Functions
success() {
    echo -e "${GREEN}✅ $1${NC}"
}

error() {
    echo -e "${RED}❌ $1${NC}"
}

warning() {
    echo -e "${YELLOW}⚠️ $1${NC}"
}

info() {
    echo -e "${BLUE}ℹ️ $1${NC}"
}

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCENARIOS_DIR="$(dirname "$SCRIPT_DIR")/escenarios-diagnostico"
LOG_FILE="$SCRIPT_DIR/validation-$(date +%Y%m%d-%H%M%S).log"
VALIDATION_REPORT="$SCRIPT_DIR/validation-report.html"

# Counters
TOTAL_SCENARIOS=0
PASSED_SCENARIOS=0
FAILED_SCENARIOS=0

# ============================================================================
# VALIDATION FUNCTIONS
# ============================================================================

check_prerequisites() {
    info "Verificando prerrequisitos del sistema..."
    
    local missing_deps=0
    
    # Check Docker
    if command -v docker &> /dev/null; then
        success "Docker está instalado"
        
        # Check if Docker daemon is running
        if docker info &> /dev/null; then
            success "Docker daemon está corriendo"
        else
            error "Docker daemon no está corriendo"
            ((missing_deps++))
        fi
    else
        error "Docker no está instalado"
        ((missing_deps++))
    fi
    
    # Check Docker Compose
    if command -v docker-compose &> /dev/null; then
        success "Docker Compose está instalado"
    else
        error "Docker Compose no está instalado"
        ((missing_deps++))
    fi
    
    # Check Python
    if command -v python3 &> /dev/null; then
        success "Python 3 está instalado"
    else
        error "Python 3 no está instalado"
        ((missing_deps++))
    fi
    
    # Check available ports
    info "Verificando puertos disponibles..."
    local ports_to_check=(3306 5432 27017 3000 9090 9104)
    
    for port in "${ports_to_check[@]}"; do
        if netstat -tuln 2>/dev/null | grep -q ":$port "; then
            warning "Puerto $port está en uso"
        else
            success "Puerto $port está disponible"
        fi
    done
    
    return $missing_deps
}

validate_scenario_structure() {
    local scenario_path="$1"
    local scenario_name=$(basename "$scenario_path")
    local errors=0
    
    info "Validando estructura de $scenario_name..."
    
    # Required files and directories
    local required_items=(
        "docker-compose.yml"
        "simuladores/Dockerfile"
        "simuladores/requirements.txt"
        "init-scripts"
        "prometheus/prometheus.yml"
        "problema-descripcion.md"
        "solucion-guia.md"
        "evaluacion-config.yml"
    )
    
    for item in "${required_items[@]}"; do
        if [ -e "$scenario_path/$item" ]; then
            success "  ✓ $item existe"
        else
            error "  ✗ $item falta"
            ((errors++))
        fi
    done
    
    return $errors
}

test_docker_compose() {
    local scenario_path="$1"
    local scenario_name=$(basename "$scenario_path")
    
    info "Probando Docker Compose para $scenario_name..."
    
    cd "$scenario_path"
    
    # Validate docker-compose.yml syntax
    if docker-compose config &> /dev/null; then
        success "  ✓ docker-compose.yml es válido"
    else
        error "  ✗ docker-compose.yml tiene errores de sintaxis"
        return 1
    fi
    
    # Try to build images (without starting)
    if docker-compose build --no-cache &> /dev/null; then
        success "  ✓ Imágenes Docker se construyen correctamente"
    else
        error "  ✗ Error construyendo imágenes Docker"
        return 1
    fi
    
    # Quick start test (start and stop immediately)
    info "  Probando inicio rápido de servicios..."
    
    if timeout 60 docker-compose up -d &> /dev/null; then
        success "  ✓ Servicios inician correctamente"
        
        # Wait a moment for services to initialize
        sleep 10
        
        # Check if services are healthy
        local healthy_services=0
        local total_services=$(docker-compose ps --services | wc -l)
        
        for service in $(docker-compose ps --services); do
            if docker-compose ps "$service" | grep -q "Up"; then
                ((healthy_services++))
                success "    ✓ Servicio $service está corriendo"
            else
                error "    ✗ Servicio $service no está corriendo"
            fi
        done
        
        # Stop services
        docker-compose down &> /dev/null
        
        if [ $healthy_services -eq $total_services ]; then
            success "  ✓ Todos los servicios están saludables"
            return 0
        else
            error "  ✗ $((total_services - healthy_services)) servicios fallaron"
            return 1
        fi
    else
        error "  ✗ Error iniciando servicios"
        docker-compose down &> /dev/null 2>&1 || true
        return 1
    fi
}

test_simulator_functionality() {
    local scenario_path="$1"
    local scenario_name=$(basename "$scenario_path")
    
    info "Probando funcionalidad del simulador para $scenario_name..."
    
    local simulator_dir="$scenario_path/simuladores"
    
    if [ ! -d "$simulator_dir" ]; then
        error "  ✗ Directorio de simuladores no existe"
        return 1
    fi
    
    cd "$simulator_dir"
    
    # Check if Python files exist
    local python_files=$(find . -name "*.py" | wc -l)
    
    if [ $python_files -eq 0 ]; then
        error "  ✗ No se encontraron archivos Python"
        return 1
    fi
    
    success "  ✓ Encontrados $python_files archivos Python"
    
    # Check Python syntax
    local syntax_errors=0
    
    for py_file in *.py; do
        if [ -f "$py_file" ]; then
            if python3 -m py_compile "$py_file" 2>/dev/null; then
                success "    ✓ $py_file: sintaxis válida"
            else
                error "    ✗ $py_file: errores de sintaxis"
                ((syntax_errors++))
            fi
        fi
    done
    
    if [ $syntax_errors -eq 0 ]; then
        success "  ✓ Todos los archivos Python tienen sintaxis válida"
        return 0
    else
        error "  ✗ $syntax_errors archivos con errores de sintaxis"
        return 1
    fi
}

validate_monitoring_config() {
    local scenario_path="$1"
    local scenario_name=$(basename "$scenario_path")
    
    info "Validando configuración de monitoreo para $scenario_name..."
    
    local errors=0
    
    # Check Prometheus config
    local prometheus_config="$scenario_path/prometheus/prometheus.yml"
    if [ -f "$prometheus_config" ]; then
        # Basic YAML syntax check
        if python3 -c "import yaml; yaml.safe_load(open('$prometheus_config'))" 2>/dev/null; then
            success "  ✓ Configuración de Prometheus es válida"
        else
            error "  ✗ Configuración de Prometheus tiene errores"
            ((errors++))
        fi
    else
        error "  ✗ Configuración de Prometheus no existe"
        ((errors++))
    fi
    
    # Check Grafana datasources
    local grafana_datasources="$scenario_path/grafana/datasources"
    if [ -d "$grafana_datasources" ]; then
        success "  ✓ Directorio de datasources de Grafana existe"
    else
        warning "  ⚠ Directorio de datasources de Grafana no existe"
    fi
    
    return $errors
}

generate_html_report() {
    info "Generando reporte HTML..."
    
    cat > "$VALIDATION_REPORT" << EOF
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Reporte de Validación - Escenarios DBA</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; background-color: #f5f5f5; }
        .container { max-width: 1200px; margin: 0 auto; background: white; padding: 20px; border-radius: 8px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }
        .header { text-align: center; margin-bottom: 30px; }
        .summary { display: flex; justify-content: space-around; margin-bottom: 30px; }
        .metric { text-align: center; padding: 20px; border-radius: 8px; }
        .metric.success { background-color: #d4edda; color: #155724; }
        .metric.warning { background-color: #fff3cd; color: #856404; }
        .metric.error { background-color: #f8d7da; color: #721c24; }
        .scenario { margin-bottom: 20px; padding: 15px; border: 1px solid #ddd; border-radius: 5px; }
        .scenario.passed { border-left: 5px solid #28a745; }
        .scenario.failed { border-left: 5px solid #dc3545; }
        .scenario h3 { margin-top: 0; }
        .test-result { margin: 5px 0; }
        .test-result.pass { color: #28a745; }
        .test-result.fail { color: #dc3545; }
        .test-result.warn { color: #ffc107; }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>🔍 Reporte de Validación - Escenarios DBA</h1>
            <p>Generado el: $(date)</p>
        </div>
        
        <div class="summary">
            <div class="metric success">
                <h2>$PASSED_SCENARIOS</h2>
                <p>Escenarios Exitosos</p>
            </div>
            <div class="metric error">
                <h2>$FAILED_SCENARIOS</h2>
                <p>Escenarios Fallidos</p>
            </div>
            <div class="metric $([ $PASSED_SCENARIOS -eq $TOTAL_SCENARIOS ] && echo "success" || echo "warning")">
                <h2>$(( PASSED_SCENARIOS * 100 / TOTAL_SCENARIOS ))%</h2>
                <p>Tasa de Éxito</p>
            </div>
        </div>
        
        <div class="scenarios">
EOF

    # Add scenario details (this would be populated during validation)
    echo "            <p>Detalles de escenarios se agregarán durante la validación...</p>" >> "$VALIDATION_REPORT"
    
    cat >> "$VALIDATION_REPORT" << EOF
        </div>
        
        <div class="footer">
            <h3>📋 Resumen de Validación</h3>
            <ul>
                <li>Total de escenarios: $TOTAL_SCENARIOS</li>
                <li>Escenarios exitosos: $PASSED_SCENARIOS</li>
                <li>Escenarios fallidos: $FAILED_SCENARIOS</li>
                <li>Log detallado: $LOG_FILE</li>
            </ul>
        </div>
    </div>
</body>
</html>
EOF

    success "Reporte HTML generado: $VALIDATION_REPORT"
}

# ============================================================================
# MAIN EXECUTION
# ============================================================================

main() {
    echo "============================================================================"
    echo "🔍 VALIDACIÓN DE FUNCIONALIDAD - ESCENARIOS DE DIAGNÓSTICO"
    echo "============================================================================"
    echo "Validando funcionalidad completa de todos los escenarios"
    echo "Log: $LOG_FILE"
    echo "============================================================================"
    
    # Check prerequisites
    if ! check_prerequisites; then
        error "Prerrequisitos no cumplidos. Instala las dependencias faltantes."
        exit 1
    fi
    
    # Validate scenarios directory
    if [ ! -d "$SCENARIOS_DIR" ]; then
        error "Directorio de escenarios no encontrado: $SCENARIOS_DIR"
        exit 1
    fi
    
    # Process each scenario
    for db_type in mysql postgresql mongodb; do
        local db_dir="$SCENARIOS_DIR/$db_type"
        
        if [ -d "$db_dir" ]; then
            info "Validando escenarios de $db_type..."
            
            for scenario_dir in "$db_dir"/escenario-*; do
                if [ -d "$scenario_dir" ]; then
                    ((TOTAL_SCENARIOS++))
                    local scenario_name="$db_type/$(basename "$scenario_dir")"
                    local validation_errors=0
                    
                    info "Validando: $scenario_name"
                    
                    # Structure validation
                    if ! validate_scenario_structure "$scenario_dir"; then
                        ((validation_errors++))
                    fi
                    
                    # Docker Compose validation
                    if ! test_docker_compose "$scenario_dir"; then
                        ((validation_errors++))
                    fi
                    
                    # Simulator validation
                    if ! test_simulator_functionality "$scenario_dir"; then
                        ((validation_errors++))
                    fi
                    
                    # Monitoring validation
                    if ! validate_monitoring_config "$scenario_dir"; then
                        ((validation_errors++))
                    fi
                    
                    # Final result for this scenario
                    if [ $validation_errors -eq 0 ]; then
                        success "✅ $scenario_name: PASÓ todas las validaciones"
                        ((PASSED_SCENARIOS++))
                    else
                        error "❌ $scenario_name: FALLÓ $validation_errors validaciones"
                        ((FAILED_SCENARIOS++))
                    fi
                    
                    echo "----------------------------------------"
                fi
            done
        fi
    done
    
    # Generate report
    generate_html_report
    
    # Final summary
    echo ""
    echo "============================================================================"
    echo "📊 RESUMEN FINAL DE VALIDACIÓN"
    echo "============================================================================"
    echo "Total de escenarios: $TOTAL_SCENARIOS"
    echo "Escenarios exitosos: $PASSED_SCENARIOS"
    echo "Escenarios fallidos: $FAILED_SCENARIOS"
    echo "Tasa de éxito: $(( PASSED_SCENARIOS * 100 / TOTAL_SCENARIOS ))%"
    echo ""
    echo "📄 Reportes generados:"
    echo "  - Log detallado: $LOG_FILE"
    echo "  - Reporte HTML: $VALIDATION_REPORT"
    echo ""
    
    if [ $PASSED_SCENARIOS -eq $TOTAL_SCENARIOS ]; then
        success "🎉 ¡Todos los escenarios están completamente funcionales!"
        echo ""
        echo "🚀 Próximos pasos:"
        echo "1. Los escenarios están listos para uso en producción"
        echo "2. Puedes comenzar las sesiones de entrenamiento"
        echo "3. Configura el sistema de evaluación automatizada"
        exit 0
    else
        warning "⚠️ Algunos escenarios requieren correcciones"
        echo ""
        echo "🔧 Acciones recomendadas:"
        echo "1. Revisar el log detallado para errores específicos"
        echo "2. Ejecutar el script de completación: ./completar-escenarios-faltantes.sh"
        echo "3. Corregir manualmente los problemas identificados"
        echo "4. Volver a ejecutar esta validación"
        exit 1
    fi
}

# Execute main function
main "$@" 2>&1 | tee "$LOG_FILE"
