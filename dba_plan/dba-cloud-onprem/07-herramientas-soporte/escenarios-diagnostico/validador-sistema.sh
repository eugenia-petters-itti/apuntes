#!/bin/bash

# Validador Completo del Sistema de Escenarios
# Programa DBA Cloud OnPrem Junior

set -e

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Contadores
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0

# Función para logging
log_test() {
    local test_name="$1"
    local status="$2"
    local message="$3"
    
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    
    if [ "$status" = "PASS" ]; then
        echo -e "${GREEN}✅ $test_name${NC}: $message"
        PASSED_TESTS=$((PASSED_TESTS + 1))
    else
        echo -e "${RED}❌ $test_name${NC}: $message"
        FAILED_TESTS=$((FAILED_TESTS + 1))
    fi
}

# Función para verificar estructura de directorios
validate_directory_structure() {
    echo -e "${BLUE}🏗️  Validando estructura de directorios...${NC}"
    
    # Directorios principales
    required_dirs=(
        "mysql"
        "postgresql" 
        "mongodb"
        "herramientas-diagnostico"
        "plantillas-escenarios"
    )
    
    for dir in "${required_dirs[@]}"; do
        if [ -d "$dir" ]; then
            log_test "DIR_STRUCTURE" "PASS" "Directorio '$dir' existe"
        else
            log_test "DIR_STRUCTURE" "FAIL" "Directorio '$dir' faltante"
        fi
    done
    
    # Verificar escenarios por motor
    engines=("mysql" "postgresql" "mongodb")
    for engine in "${engines[@]}"; do
        scenario_count=$(find "$engine" -name "escenario-*" -type d | wc -l)
        if [ "$scenario_count" -eq 5 ]; then
            log_test "SCENARIO_COUNT" "PASS" "$engine tiene 5 escenarios"
        else
            log_test "SCENARIO_COUNT" "FAIL" "$engine tiene $scenario_count escenarios (esperados: 5)"
        fi
    done
}

# Función para validar archivos requeridos
validate_required_files() {
    echo -e "${BLUE}📄 Validando archivos requeridos...${NC}"
    
    # Archivos principales
    main_files=(
        "README.md"
        "GUIA-USO-RAPIDO.md"
        "gestor-escenarios.sh"
        "evaluador-automatico.py"
        "dashboard-instructor.html"
    )
    
    for file in "${main_files[@]}"; do
        if [ -f "$file" ]; then
            log_test "MAIN_FILES" "PASS" "Archivo '$file' existe"
        else
            log_test "MAIN_FILES" "FAIL" "Archivo '$file' faltante"
        fi
    done
    
    # Verificar archivos en cada escenario
    for scenario_dir in mysql/escenario-* postgresql/escenario-* mongodb/escenario-*; do
        if [ -d "$scenario_dir" ]; then
            scenario_name=$(basename "$scenario_dir")
            
            # Archivos requeridos por escenario
            required_files=(
                "problema-descripcion.md"
                "docker-compose.yml"
            )
            
            for file in "${required_files[@]}"; do
                if [ -f "$scenario_dir/$file" ]; then
                    log_test "SCENARIO_FILES" "PASS" "$scenario_name/$file existe"
                else
                    log_test "SCENARIO_FILES" "FAIL" "$scenario_name/$file faltante"
                fi
            done
            
            # Verificar estructura de subdirectorios
            required_subdirs=(
                "config"
                "init-scripts"
                "simuladores"
                "scripts-diagnostico"
                "grafana"
                "prometheus"
            )
            
            for subdir in "${required_subdirs[@]}"; do
                if [ -d "$scenario_dir/$subdir" ]; then
                    log_test "SCENARIO_DIRS" "PASS" "$scenario_name/$subdir existe"
                else
                    log_test "SCENARIO_DIRS" "FAIL" "$scenario_name/$subdir faltante"
                fi
            done
        fi
    done
}

# Función para validar Docker Compose
validate_docker_compose() {
    echo -e "${BLUE}🐳 Validando archivos Docker Compose...${NC}"
    
    # Verificar que Docker esté disponible
    if ! command -v docker >/dev/null 2>&1; then
        log_test "DOCKER_AVAILABLE" "FAIL" "Docker no está instalado"
        return
    fi
    
    if ! command -v docker-compose >/dev/null 2>&1; then
        log_test "DOCKER_COMPOSE_AVAILABLE" "FAIL" "Docker Compose no está instalado"
        return
    fi
    
    log_test "DOCKER_AVAILABLE" "PASS" "Docker está disponible"
    log_test "DOCKER_COMPOSE_AVAILABLE" "PASS" "Docker Compose está disponible"
    
    # Validar cada docker-compose.yml
    for compose_file in */escenario-*/docker-compose.yml; do
        if [ -f "$compose_file" ]; then
            scenario_path=$(dirname "$compose_file")
            scenario_name=$(basename "$scenario_path")
            
            cd "$scenario_path"
            
            if docker-compose config >/dev/null 2>&1; then
                log_test "DOCKER_COMPOSE_SYNTAX" "PASS" "$scenario_name docker-compose.yml válido"
            else
                log_test "DOCKER_COMPOSE_SYNTAX" "FAIL" "$scenario_name docker-compose.yml inválido"
            fi
            
            cd - >/dev/null
        fi
    done
}

# Función para validar scripts
validate_scripts() {
    echo -e "${BLUE}📜 Validando scripts...${NC}"
    
    # Verificar permisos de ejecución
    executable_scripts=(
        "gestor-escenarios.sh"
        "validador-sistema.sh"
        "herramientas-diagnostico/scripts-monitoring/system-monitor.sh"
    )
    
    for script in "${executable_scripts[@]}"; do
        if [ -f "$script" ]; then
            if [ -x "$script" ]; then
                log_test "SCRIPT_EXECUTABLE" "PASS" "$script es ejecutable"
            else
                log_test "SCRIPT_EXECUTABLE" "FAIL" "$script no es ejecutable"
                chmod +x "$script" 2>/dev/null && echo "  🔧 Permisos corregidos automáticamente"
            fi
        fi
    done
    
    # Verificar sintaxis de Python
    python_scripts=(
        "evaluador-automatico.py"
    )
    
    for script in "${python_scripts[@]}"; do
        if [ -f "$script" ]; then
            if python3 -m py_compile "$script" 2>/dev/null; then
                log_test "PYTHON_SYNTAX" "PASS" "$script sintaxis válida"
            else
                log_test "PYTHON_SYNTAX" "FAIL" "$script sintaxis inválida"
            fi
        fi
    done
}

# Función para validar puertos
validate_ports() {
    echo -e "${BLUE}🔌 Validando disponibilidad de puertos...${NC}"
    
    # Puertos comunes utilizados por los escenarios
    common_ports=(3000 3306 5432 8080 8081 8082 9090 9091 9092 27017)
    
    for port in "${common_ports[@]}"; do
        if lsof -i :$port >/dev/null 2>&1; then
            log_test "PORT_AVAILABILITY" "FAIL" "Puerto $port está en uso"
        else
            log_test "PORT_AVAILABILITY" "PASS" "Puerto $port disponible"
        fi
    done
}

# Función para validar recursos del sistema
validate_system_resources() {
    echo -e "${BLUE}💾 Validando recursos del sistema...${NC}"
    
    # Verificar espacio en disco (mínimo 10GB)
    available_space_kb=$(df . | awk 'NR==2 {print $4}')
    available_space_gb=$((available_space_kb / 1024 / 1024))
    
    if [ "$available_space_gb" -ge 10 ]; then
        log_test "DISK_SPACE" "PASS" "Espacio disponible: ${available_space_gb}GB"
    else
        log_test "DISK_SPACE" "FAIL" "Espacio insuficiente: ${available_space_gb}GB (mínimo: 10GB)"
    fi
    
    # Verificar memoria (si está disponible)
    if command -v free >/dev/null 2>&1; then
        available_mem_mb=$(free -m | awk 'NR==2{print $7}')
        if [ "$available_mem_mb" -ge 4096 ]; then
            log_test "MEMORY" "PASS" "Memoria disponible: ${available_mem_mb}MB"
        else
            log_test "MEMORY" "FAIL" "Memoria insuficiente: ${available_mem_mb}MB (recomendado: 4GB)"
        fi
    else
        log_test "MEMORY" "PASS" "Verificación de memoria omitida (macOS)"
    fi
}

# Función para test de integración básico
basic_integration_test() {
    echo -e "${BLUE}🧪 Ejecutando test de integración básico...${NC}"
    
    # Probar gestor de escenarios
    if [ -x "gestor-escenarios.sh" ]; then
        if ./gestor-escenarios.sh list >/dev/null 2>&1; then
            log_test "INTEGRATION_MANAGER" "PASS" "Gestor de escenarios funciona"
        else
            log_test "INTEGRATION_MANAGER" "FAIL" "Gestor de escenarios falla"
        fi
    fi
    
    # Probar evaluador automático
    if [ -f "evaluador-automatico.py" ]; then
        if python3 evaluador-automatico.py --help >/dev/null 2>&1; then
            log_test "INTEGRATION_EVALUATOR" "PASS" "Evaluador automático funciona"
        else
            log_test "INTEGRATION_EVALUATOR" "FAIL" "Evaluador automático falla"
        fi
    fi
}

# Función para generar reporte
generate_report() {
    echo ""
    echo "=" * 60
    echo -e "${BLUE}📊 REPORTE DE VALIDACIÓN${NC}"
    echo "=" * 60
    
    echo -e "📋 Total de pruebas: $TOTAL_TESTS"
    echo -e "${GREEN}✅ Pruebas exitosas: $PASSED_TESTS${NC}"
    echo -e "${RED}❌ Pruebas fallidas: $FAILED_TESTS${NC}"
    
    success_rate=$((PASSED_TESTS * 100 / TOTAL_TESTS))
    echo -e "📊 Tasa de éxito: $success_rate%"
    
    if [ "$FAILED_TESTS" -eq 0 ]; then
        echo ""
        echo -e "${GREEN}🎉 ¡SISTEMA COMPLETAMENTE VALIDADO!${NC}"
        echo -e "${GREEN}✅ Todos los escenarios están listos para usar${NC}"
    elif [ "$success_rate" -ge 80 ]; then
        echo ""
        echo -e "${YELLOW}⚠️  SISTEMA MAYORMENTE FUNCIONAL${NC}"
        echo -e "${YELLOW}🔧 Algunas correcciones menores requeridas${NC}"
    else
        echo ""
        echo -e "${RED}❌ SISTEMA REQUIERE ATENCIÓN${NC}"
        echo -e "${RED}🚨 Múltiples problemas detectados${NC}"
    fi
    
    echo ""
    echo -e "${BLUE}📝 Próximos pasos recomendados:${NC}"
    
    if [ "$FAILED_TESTS" -gt 0 ]; then
        echo "  1. Revisar y corregir los elementos fallidos"
        echo "  2. Re-ejecutar la validación"
    fi
    
    echo "  3. Probar un escenario completo:"
    echo "     ./gestor-escenarios.sh start mysql/escenario-01-deadlocks"
    echo "  4. Abrir dashboard de instructor:"
    echo "     open dashboard-instructor.html"
    
    # Guardar reporte
    timestamp=$(date +"%Y%m%d_%H%M%S")
    report_file="reports/validacion_$timestamp.txt"
    mkdir -p reports
    
    {
        echo "Reporte de Validación del Sistema"
        echo "Fecha: $(date)"
        echo "Total de pruebas: $TOTAL_TESTS"
        echo "Pruebas exitosas: $PASSED_TESTS"
        echo "Pruebas fallidas: $FAILED_TESTS"
        echo "Tasa de éxito: $success_rate%"
    } > "$report_file"
    
    echo ""
    echo -e "${BLUE}📄 Reporte guardado en: $report_file${NC}"
}

# Función principal
main() {
    echo -e "${BLUE}🔍 VALIDADOR COMPLETO DEL SISTEMA${NC}"
    echo -e "${BLUE}Programa DBA Cloud OnPrem Junior${NC}"
    echo ""
    
    # Ejecutar todas las validaciones
    validate_directory_structure
    echo ""
    
    validate_required_files
    echo ""
    
    validate_docker_compose
    echo ""
    
    validate_scripts
    echo ""
    
    validate_ports
    echo ""
    
    validate_system_resources
    echo ""
    
    basic_integration_test
    echo ""
    
    # Generar reporte final
    generate_report
}

# Ejecutar validación
main "$@"
