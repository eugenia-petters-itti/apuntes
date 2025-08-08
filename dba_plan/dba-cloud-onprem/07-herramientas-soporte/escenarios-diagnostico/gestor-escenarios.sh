#!/bin/bash

# Gestor Centralizado de Escenarios de Diagnóstico
# Programa DBA Cloud OnPrem Junior

set -e

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuración
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_DIR="$SCRIPT_DIR/logs"
REPORTS_DIR="$SCRIPT_DIR/reports"

# Crear directorios necesarios
mkdir -p "$LOG_DIR" "$REPORTS_DIR"

# Función para mostrar ayuda
show_help() {
    echo -e "${BLUE}🎯 Gestor de Escenarios de Diagnóstico DBA${NC}"
    echo ""
    echo "Uso: $0 [COMANDO] [OPCIONES]"
    echo ""
    echo -e "${YELLOW}Comandos disponibles:${NC}"
    echo "  list                    - Listar todos los escenarios disponibles"
    echo "  start <escenario>       - Iniciar un escenario específico"
    echo "  stop <escenario>        - Detener un escenario específico"
    echo "  status [escenario]      - Ver estado de escenarios"
    echo "  logs <escenario>        - Ver logs de un escenario"
    echo "  clean [escenario]       - Limpiar escenario(s)"
    echo "  test <escenario>        - Probar que un escenario funciona"
    echo "  report <escenario>      - Generar reporte de diagnóstico"
    echo "  health                  - Verificar salud del sistema"
    echo ""
    echo -e "${YELLOW}Ejemplos:${NC}"
    echo "  $0 list"
    echo "  $0 start mysql/escenario-01-deadlocks"
    echo "  $0 status"
    echo "  $0 clean all"
    echo ""
}

# Función para listar escenarios
list_scenarios() {
    echo -e "${BLUE}📋 Escenarios Disponibles:${NC}"
    echo ""
    
    echo -e "${GREEN}🐬 MySQL (5 escenarios):${NC}"
    for dir in mysql/escenario-*; do
        if [ -d "$dir" ]; then
            scenario_name=$(basename "$dir")
            problem_type=$(echo "$scenario_name" | cut -d'-' -f3-)
            echo "  • $dir - $(echo $problem_type | tr '-' ' ' | sed 's/\b\w/\U&/g')"
        fi
    done
    
    echo ""
    echo -e "${GREEN}🐘 PostgreSQL (5 escenarios):${NC}"
    for dir in postgresql/escenario-*; do
        if [ -d "$dir" ]; then
            scenario_name=$(basename "$dir")
            problem_type=$(echo "$scenario_name" | cut -d'-' -f3-)
            echo "  • $dir - $(echo $problem_type | tr '-' ' ' | sed 's/\b\w/\U&/g')"
        fi
    done
    
    echo ""
    echo -e "${GREEN}🍃 MongoDB (5 escenarios):${NC}"
    for dir in mongodb/escenario-*; do
        if [ -d "$dir" ]; then
            scenario_name=$(basename "$dir")
            problem_type=$(echo "$scenario_name" | cut -d'-' -f3-)
            echo "  • $dir - $(echo $problem_type | tr '-' ' ' | sed 's/\b\w/\U&/g')"
        fi
    done
    echo ""
}

# Función para iniciar escenario
start_scenario() {
    local scenario="$1"
    
    if [ -z "$scenario" ]; then
        echo -e "${RED}❌ Error: Especifica un escenario${NC}"
        echo "Uso: $0 start <escenario>"
        echo "Ejemplo: $0 start mysql/escenario-01-deadlocks"
        return 1
    fi
    
    if [ ! -d "$scenario" ]; then
        echo -e "${RED}❌ Error: Escenario '$scenario' no encontrado${NC}"
        return 1
    fi
    
    if [ ! -f "$scenario/docker-compose.yml" ]; then
        echo -e "${RED}❌ Error: docker-compose.yml no encontrado en '$scenario'${NC}"
        return 1
    fi
    
    echo -e "${BLUE}🚀 Iniciando escenario: $scenario${NC}"
    
    cd "$scenario"
    
    # Verificar que Docker esté corriendo
    if ! docker info >/dev/null 2>&1; then
        echo -e "${RED}❌ Error: Docker no está corriendo${NC}"
        return 1
    fi
    
    # Iniciar servicios
    echo "📦 Levantando servicios..."
    docker-compose up -d
    
    # Esperar a que los servicios estén listos
    echo "⏳ Esperando que los servicios estén listos..."
    sleep 10
    
    # Verificar estado
    echo "🔍 Verificando estado de servicios..."
    docker-compose ps
    
    echo ""
    echo -e "${GREEN}✅ Escenario '$scenario' iniciado correctamente${NC}"
    echo ""
    echo -e "${YELLOW}📊 Interfaces disponibles:${NC}"
    
    # Detectar puertos según el tipo de escenario
    if [[ "$scenario" == *"mysql"* ]]; then
        echo "  • MySQL: localhost:3306"
        echo "  • phpMyAdmin: http://localhost:8080"
    elif [[ "$scenario" == *"postgresql"* ]]; then
        echo "  • PostgreSQL: localhost:5432"
        echo "  • pgAdmin: http://localhost:8081"
    elif [[ "$scenario" == *"mongodb"* ]]; then
        echo "  • MongoDB: localhost:27017"
        echo "  • Mongo Express: http://localhost:8082"
    fi
    
    echo "  • Grafana: http://localhost:3000 (admin/admin)"
    echo "  • Prometheus: http://localhost:9090"
    echo ""
    echo -e "${YELLOW}📖 Próximos pasos:${NC}"
    echo "  1. Lee: $scenario/problema-descripcion.md"
    echo "  2. Analiza los síntomas con las herramientas"
    echo "  3. Ejecuta: $0 logs $scenario (para ver logs en tiempo real)"
    echo "  4. Cuando termines: $0 stop $scenario"
    
    cd - >/dev/null
}

# Función para detener escenario
stop_scenario() {
    local scenario="$1"
    
    if [ -z "$scenario" ]; then
        echo -e "${RED}❌ Error: Especifica un escenario${NC}"
        return 1
    fi
    
    if [ ! -d "$scenario" ]; then
        echo -e "${RED}❌ Error: Escenario '$scenario' no encontrado${NC}"
        return 1
    fi
    
    echo -e "${YELLOW}🛑 Deteniendo escenario: $scenario${NC}"
    
    cd "$scenario"
    docker-compose down
    cd - >/dev/null
    
    echo -e "${GREEN}✅ Escenario '$scenario' detenido${NC}"
}

# Función para ver estado
show_status() {
    local scenario="$1"
    
    if [ -n "$scenario" ]; then
        # Estado de un escenario específico
        if [ ! -d "$scenario" ]; then
            echo -e "${RED}❌ Error: Escenario '$scenario' no encontrado${NC}"
            return 1
        fi
        
        echo -e "${BLUE}📊 Estado del escenario: $scenario${NC}"
        cd "$scenario"
        docker-compose ps
        cd - >/dev/null
    else
        # Estado general
        echo -e "${BLUE}📊 Estado General del Sistema${NC}"
        echo ""
        
        # Verificar Docker
        if docker info >/dev/null 2>&1; then
            echo -e "${GREEN}✅ Docker: Funcionando${NC}"
        else
            echo -e "${RED}❌ Docker: No disponible${NC}"
        fi
        
        # Verificar contenedores activos
        active_containers=$(docker ps --format "table {{.Names}}\t{{.Status}}" | grep -E "(mysql|postgres|mongo)" | wc -l)
        echo -e "${BLUE}📦 Contenedores activos: $active_containers${NC}"
        
        if [ "$active_containers" -gt 0 ]; then
            echo ""
            echo -e "${YELLOW}Contenedores de escenarios activos:${NC}"
            docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep -E "(mysql|postgres|mongo)" || true
        fi
        
        # Uso de recursos
        echo ""
        echo -e "${BLUE}💾 Uso de Recursos:${NC}"
        docker system df
    fi
}

# Función para ver logs
show_logs() {
    local scenario="$1"
    
    if [ -z "$scenario" ]; then
        echo -e "${RED}❌ Error: Especifica un escenario${NC}"
        return 1
    fi
    
    if [ ! -d "$scenario" ]; then
        echo -e "${RED}❌ Error: Escenario '$scenario' no encontrado${NC}"
        return 1
    fi
    
    echo -e "${BLUE}📋 Logs del escenario: $scenario${NC}"
    echo "Presiona Ctrl+C para salir"
    echo ""
    
    cd "$scenario"
    docker-compose logs -f
    cd - >/dev/null
}

# Función para limpiar
clean_scenarios() {
    local scenario="$1"
    
    if [ "$scenario" = "all" ]; then
        echo -e "${YELLOW}🧹 Limpiando todos los escenarios...${NC}"
        
        # Detener todos los contenedores de escenarios
        docker ps -q --filter "name=mysql" --filter "name=postgres" --filter "name=mongo" | xargs -r docker stop
        docker ps -aq --filter "name=mysql" --filter "name=postgres" --filter "name=mongo" | xargs -r docker rm
        
        # Limpiar volúmenes huérfanos
        docker volume prune -f
        
        # Limpiar redes huérfanas
        docker network prune -f
        
        echo -e "${GREEN}✅ Limpieza completa realizada${NC}"
        
    elif [ -n "$scenario" ]; then
        if [ ! -d "$scenario" ]; then
            echo -e "${RED}❌ Error: Escenario '$scenario' no encontrado${NC}"
            return 1
        fi
        
        echo -e "${YELLOW}🧹 Limpiando escenario: $scenario${NC}"
        
        cd "$scenario"
        docker-compose down -v
        cd - >/dev/null
        
        echo -e "${GREEN}✅ Escenario '$scenario' limpiado${NC}"
    else
        echo -e "${RED}❌ Error: Especifica un escenario o 'all'${NC}"
        return 1
    fi
}

# Función para probar escenario
test_scenario() {
    local scenario="$1"
    
    if [ -z "$scenario" ]; then
        echo -e "${RED}❌ Error: Especifica un escenario${NC}"
        return 1
    fi
    
    if [ ! -d "$scenario" ]; then
        echo -e "${RED}❌ Error: Escenario '$scenario' no encontrado${NC}"
        return 1
    fi
    
    echo -e "${BLUE}🧪 Probando escenario: $scenario${NC}"
    
    cd "$scenario"
    
    # Verificar archivos necesarios
    echo "📋 Verificando archivos..."
    
    required_files=("docker-compose.yml" "problema-descripcion.md")
    for file in "${required_files[@]}"; do
        if [ -f "$file" ]; then
            echo -e "  ✅ $file"
        else
            echo -e "  ❌ $file - ${RED}FALTANTE${NC}"
        fi
    done
    
    # Probar docker-compose
    echo "🐳 Validando docker-compose..."
    if docker-compose config >/dev/null 2>&1; then
        echo -e "  ✅ docker-compose.yml válido"
    else
        echo -e "  ❌ docker-compose.yml - ${RED}INVÁLIDO${NC}"
        cd - >/dev/null
        return 1
    fi
    
    cd - >/dev/null
    echo -e "${GREEN}✅ Escenario '$scenario' pasa todas las pruebas${NC}"
}

# Función para verificar salud del sistema
health_check() {
    echo -e "${BLUE}🏥 Verificación de Salud del Sistema${NC}"
    echo ""
    
    # Verificar Docker
    echo "🐳 Docker:"
    if docker info >/dev/null 2>&1; then
        docker_version=$(docker --version | cut -d' ' -f3 | cut -d',' -f1)
        echo -e "  ✅ Docker $docker_version funcionando"
    else
        echo -e "  ❌ Docker no disponible"
        return 1
    fi
    
    # Verificar Docker Compose
    echo "📦 Docker Compose:"
    if command -v docker-compose >/dev/null 2>&1; then
        compose_version=$(docker-compose --version | cut -d' ' -f3 | cut -d',' -f1)
        echo -e "  ✅ Docker Compose $compose_version disponible"
    else
        echo -e "  ❌ Docker Compose no disponible"
    fi
    
    # Verificar espacio en disco
    echo "💾 Espacio en disco:"
    available_space=$(df -h . | awk 'NR==2 {print $4}')
    echo -e "  📊 Espacio disponible: $available_space"
    
    # Verificar memoria
    echo "🧠 Memoria:"
    if command -v free >/dev/null 2>&1; then
        available_mem=$(free -h | awk 'NR==2{printf "%.1fG", $7/1024}')
        echo -e "  📊 Memoria disponible: $available_mem"
    else
        echo -e "  ℹ️  Información de memoria no disponible en macOS"
    fi
    
    # Verificar puertos comunes
    echo "🔌 Puertos:"
    common_ports=(3000 3306 5432 8080 8081 8082 9090 27017)
    for port in "${common_ports[@]}"; do
        if lsof -i :$port >/dev/null 2>&1; then
            echo -e "  ⚠️  Puerto $port en uso"
        else
            echo -e "  ✅ Puerto $port disponible"
        fi
    done
    
    echo ""
    echo -e "${GREEN}✅ Verificación de salud completada${NC}"
}

# Función principal
main() {
    case "${1:-}" in
        "list"|"ls")
            list_scenarios
            ;;
        "start")
            start_scenario "$2"
            ;;
        "stop")
            stop_scenario "$2"
            ;;
        "status")
            show_status "$2"
            ;;
        "logs")
            show_logs "$2"
            ;;
        "clean")
            clean_scenarios "$2"
            ;;
        "test")
            test_scenario "$2"
            ;;
        "health")
            health_check
            ;;
        "help"|"-h"|"--help"|"")
            show_help
            ;;
        *)
            echo -e "${RED}❌ Comando desconocido: $1${NC}"
            echo ""
            show_help
            exit 1
            ;;
    esac
}

# Ejecutar función principal
main "$@"
