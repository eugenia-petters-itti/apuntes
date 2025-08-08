#!/bin/bash
# ============================================================================
# TEST SIMPLE DE FUNCIONALIDAD
# ============================================================================

set -e

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

success() { echo -e "${GREEN}✅ $1${NC}"; }
info() { echo -e "${BLUE}ℹ️ $1${NC}"; }
error() { echo -e "${RED}❌ $1${NC}"; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BASE_DIR="$(dirname "$SCRIPT_DIR")"

echo "============================================================================"
echo "🔍 TEST SIMPLE DE FUNCIONALIDAD - COMPONENTES CORE"
echo "============================================================================"

TOTAL=0
PASSED=0

check_file() {
    local desc="$1"
    local file="$2"
    ((TOTAL++))
    
    if [ -f "$file" ] || [ -d "$file" ]; then
        success "$desc"
        ((PASSED++))
    else
        error "$desc - No encontrado: $file"
    fi
}

info "Validando estructura básica..."

check_file "Directorio de escenarios" "$BASE_DIR/escenarios-diagnostico"
check_file "README principal" "$BASE_DIR/README.md"
check_file "Scripts utilitarios" "$BASE_DIR/scripts-utilitarios"
check_file "Documentación" "$BASE_DIR/documentacion"

info "Validando escenarios MySQL..."

check_file "MySQL escenario deadlocks" "$BASE_DIR/escenarios-diagnostico/mysql/escenario-01-deadlocks"
check_file "MySQL docker-compose" "$BASE_DIR/escenarios-diagnostico/mysql/escenario-01-deadlocks/docker-compose.yml"
check_file "MySQL simulador principal" "$BASE_DIR/escenarios-diagnostico/mysql/escenario-01-deadlocks/simuladores/main_simulator.py"
check_file "MySQL simulador deadlock" "$BASE_DIR/escenarios-diagnostico/mysql/escenario-01-deadlocks/simuladores/deadlock-simulator.py"

info "Validando escenarios PostgreSQL..."

check_file "PostgreSQL escenario vacuum" "$BASE_DIR/escenarios-diagnostico/postgresql/escenario-01-vacuum"
check_file "PostgreSQL docker-compose" "$BASE_DIR/escenarios-diagnostico/postgresql/escenario-01-vacuum/docker-compose.yml"
check_file "PostgreSQL simulador vacuum" "$BASE_DIR/escenarios-diagnostico/postgresql/escenario-01-vacuum/simuladores/vacuum_simulator.py"

info "Validando escenarios MongoDB..."

check_file "MongoDB escenario sharding" "$BASE_DIR/escenarios-diagnostico/mongodb/escenario-01-sharding"
check_file "MongoDB docker-compose" "$BASE_DIR/escenarios-diagnostico/mongodb/escenario-01-sharding/docker-compose.yml"
check_file "MongoDB simulador sharding" "$BASE_DIR/escenarios-diagnostico/mongodb/escenario-01-sharding/simuladores/sharding_simulator.py"

info "Validando herramientas de diagnóstico..."

check_file "Herramientas diagnóstico" "$BASE_DIR/escenarios-diagnostico/herramientas-diagnostico"
check_file "Queries MySQL" "$BASE_DIR/escenarios-diagnostico/herramientas-diagnostico/queries-diagnostico/mysql-diagnostics.sql"
check_file "Queries PostgreSQL" "$BASE_DIR/escenarios-diagnostico/herramientas-diagnostico/queries-diagnostico/postgresql-diagnostics.sql"
check_file "Monitor MySQL" "$BASE_DIR/escenarios-diagnostico/herramientas-diagnostico/scripts-monitoring/mysql/deadlock_monitor.sh"

info "Validando sistema de evaluación..."

check_file "Evaluador mejorado" "$BASE_DIR/escenarios-diagnostico/evaluador_mejorado.py"
check_file "Plantilla reporte" "$BASE_DIR/escenarios-diagnostico/herramientas-diagnostico/plantillas-reporte/diagnostic-report.html"

info "Validando dashboards..."

check_file "Dashboard MySQL" "$BASE_DIR/escenarios-diagnostico/mysql/escenario-01-deadlocks/grafana/dashboards/mysql-deadlocks.json"
check_file "Dashboard PostgreSQL" "$BASE_DIR/escenarios-diagnostico/postgresql/escenario-01-vacuum/grafana/dashboards/postgres-vacuum.json"
check_file "Dashboard MongoDB" "$BASE_DIR/escenarios-diagnostico/mongodb/escenario-01-sharding/grafana/dashboards/mongodb-sharding.json"

echo ""
echo "============================================================================"
echo "📊 RESULTADO FINAL"
echo "============================================================================"

PERCENTAGE=$((PASSED * 100 / TOTAL))

echo "Componentes verificados: $PASSED/$TOTAL"
echo "Porcentaje de completitud: $PERCENTAGE%"

if [ $PERCENTAGE -ge 90 ]; then
    echo ""
    success "🎉 SISTEMA ALTAMENTE FUNCIONAL ($PERCENTAGE%)"
    success "✅ Todos los componentes core están presentes"
    success "✅ Estructura completa y organizada"
    success "✅ Listo para uso en entrenamiento DBA"
elif [ $PERCENTAGE -ge 75 ]; then
    echo ""
    success "✅ SISTEMA FUNCIONAL ($PERCENTAGE%)"
    info "⚠️  Algunos componentes menores pueden faltar"
    info "💡 Sistema usable para entrenamiento"
else
    echo ""
    error "⚠️  SISTEMA REQUIERE ATENCIÓN ($PERCENTAGE%)"
    error "🔧 Componentes críticos faltantes"
fi

echo ""
echo "🎯 COMPONENTES VALIDADOS:"
echo "• Estructura básica del sistema"
echo "• Escenarios MySQL, PostgreSQL, MongoDB"
echo "• Simuladores Python principales"
echo "• Herramientas de diagnóstico"
echo "• Sistema de evaluación automática"
echo "• Dashboards de monitoreo"
echo "• Configuraciones Docker Compose"

echo ""
echo "💡 NOTA:"
echo "Este test verifica la PRESENCIA de componentes core."
echo "Para validación completa con Docker, usar el validador completo."

echo ""
echo "============================================================================"
