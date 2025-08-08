# 🔍 SCRIPTS DE AUTO-EVALUACIÓN
## DBA Cloud OnPrem Junior - Verifica tu progreso automáticamente

### 🎯 **INTRODUCCIÓN**
Estos scripts te permiten verificar automáticamente tu progreso en cada semana del programa. Ejecuta los scripts correspondientes para asegurar que has completado correctamente todos los objetivos.

---

## 📋 **SCRIPT GENERAL DE VERIFICACIÓN**

### **Script Principal: check_overall_progress.sh**
```bash
#!/bin/bash

# DBA Cloud OnPrem Junior - Script de Verificación General
# Versión: 1.0
# Autor: Programa DBA

echo "=============================================="
echo "  DBA CLOUD ONPREM JUNIOR - VERIFICACIÓN"
echo "=============================================="
echo ""

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Función para verificar servicios
check_service() {
    local service=$1
    local port=$2
    local host=${3:-localhost}
    
    if nc -z $host $port 2>/dev/null; then
        echo -e "${GREEN}✅ $service está ejecutándose en $host:$port${NC}"
        return 0
    else
        echo -e "${RED}❌ $service NO está ejecutándose en $host:$port${NC}"
        return 1
    fi
}

# Función para verificar archivos
check_file() {
    local file=$1
    local description=$2
    
    if [ -f "$file" ]; then
        echo -e "${GREEN}✅ $description encontrado: $file${NC}"
        return 0
    else
        echo -e "${RED}❌ $description NO encontrado: $file${NC}"
        return 1
    fi
}

# Función para verificar directorios
check_directory() {
    local dir=$1
    local description=$2
    
    if [ -d "$dir" ]; then
        echo -e "${GREEN}✅ $description encontrado: $dir${NC}"
        return 0
    else
        echo -e "${RED}❌ $description NO encontrado: $dir${NC}"
        return 1
    fi
}

# Función para verificar comandos
check_command() {
    local cmd=$1
    local description=$2
    
    if command -v $cmd >/dev/null 2>&1; then
        echo -e "${GREEN}✅ $description instalado: $(which $cmd)${NC}"
        return 0
    else
        echo -e "${RED}❌ $description NO instalado${NC}"
        return 1
    fi
}

# Variables de conteo
total_checks=0
passed_checks=0

echo -e "${BLUE}1. VERIFICANDO HERRAMIENTAS BÁSICAS${NC}"
echo "----------------------------------------"

# Verificar herramientas básicas
tools=("git:Git" "aws:AWS CLI" "terraform:Terraform" "mysql:MySQL Client" "psql:PostgreSQL Client" "mongo:MongoDB Client")

for tool in "${tools[@]}"; do
    IFS=':' read -r cmd desc <<< "$tool"
    total_checks=$((total_checks + 1))
    if check_command "$cmd" "$desc"; then
        passed_checks=$((passed_checks + 1))
    fi
done

echo ""
echo -e "${BLUE}2. VERIFICANDO SERVICIOS ONPREM${NC}"
echo "----------------------------------------"

# Verificar servicios OnPrem
services=("MySQL:3306:192.168.56.10" "PostgreSQL:5432:192.168.56.11" "MongoDB:27017:192.168.56.12" "Prometheus:9090:192.168.56.13" "Grafana:3000:192.168.56.13")

for service in "${services[@]}"; do
    IFS=':' read -r name port host <<< "$service"
    total_checks=$((total_checks + 1))
    if check_service "$name" "$port" "$host"; then
        passed_checks=$((passed_checks + 1))
    fi
done

echo ""
echo -e "${BLUE}3. VERIFICANDO CONECTIVIDAD AWS${NC}"
echo "----------------------------------------"

# Verificar AWS
total_checks=$((total_checks + 1))
if aws sts get-caller-identity >/dev/null 2>&1; then
    echo -e "${GREEN}✅ AWS CLI configurado correctamente${NC}"
    passed_checks=$((passed_checks + 1))
else
    echo -e "${RED}❌ AWS CLI NO configurado${NC}"
fi

# Verificar conectividad a AWS
total_checks=$((total_checks + 1))
if ping -c 1 ec2.us-east-1.amazonaws.com >/dev/null 2>&1; then
    echo -e "${GREEN}✅ Conectividad a AWS OK${NC}"
    passed_checks=$((passed_checks + 1))
else
    echo -e "${RED}❌ Sin conectividad a AWS${NC}"
fi

echo ""
echo -e "${BLUE}4. VERIFICANDO DATASETS${NC}"
echo "----------------------------------------"

# Verificar datasets
datasets=("/home/dbastudent/datasets/mysql_ecommerce_dataset.sql:Dataset MySQL E-commerce" "/home/dbastudent/datasets/postgresql_analytics_dataset.sql:Dataset PostgreSQL Analytics" "/home/dbastudent/datasets/mongodb_social_dataset.js:Dataset MongoDB Social")

for dataset in "${datasets[@]}"; do
    IFS=':' read -r file desc <<< "$dataset"
    total_checks=$((total_checks + 1))
    if check_file "$file" "$desc"; then
        passed_checks=$((passed_checks + 1))
    fi
done

echo ""
echo -e "${BLUE}5. RESUMEN FINAL${NC}"
echo "----------------------------------------"

percentage=$((passed_checks * 100 / total_checks))

echo "Verificaciones completadas: $passed_checks/$total_checks ($percentage%)"

if [ $percentage -ge 90 ]; then
    echo -e "${GREEN}🎉 EXCELENTE! Tu entorno está completamente configurado${NC}"
elif [ $percentage -ge 70 ]; then
    echo -e "${YELLOW}⚠️  BUENO! Algunas configuraciones necesitan atención${NC}"
else
    echo -e "${RED}🚨 ATENCIÓN! Muchas configuraciones faltan o están incorrectas${NC}"
fi

echo ""
echo "Para verificaciones específicas por semana, ejecuta:"
echo "  ./check_week0_progress.sh"
echo "  ./check_week1_progress.sh"
echo "  ./check_week2_progress.sh"
echo "  ./check_week3_progress.sh"
echo "  ./check_week4_progress.sh"
echo "  ./check_week5_progress.sh"
echo ""
```

---

## 📊 **SCRIPTS POR SEMANA**

### **Script Semana 0: check_week0_progress.sh**
```bash
#!/bin/bash

echo "=============================================="
echo "    VERIFICACIÓN SEMANA 0 - FUNDAMENTOS"
echo "=============================================="

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

total_checks=0
passed_checks=0

echo -e "${BLUE}VERIFICANDO INSTALACIONES ONPREM${NC}"
echo "----------------------------------------"

# Verificar MySQL OnPrem
echo "Verificando MySQL OnPrem..."
total_checks=$((total_checks + 1))
if mysql -h 192.168.56.10 -u dbadmin -pDBAAdmin2024! -e "SELECT VERSION();" >/dev/null 2>&1; then
    echo -e "${GREEN}✅ MySQL OnPrem funcionando${NC}"
    passed_checks=$((passed_checks + 1))
else
    echo -e "${RED}❌ MySQL OnPrem NO funcionando${NC}"
fi

# Verificar dataset MySQL
total_checks=$((total_checks + 1))
if mysql -h 192.168.56.10 -u dbadmin -pDBAAdmin2024! -e "USE ecommerce; SELECT COUNT(*) FROM products;" >/dev/null 2>&1; then
    echo -e "${GREEN}✅ Dataset MySQL cargado${NC}"
    passed_checks=$((passed_checks + 1))
else
    echo -e "${RED}❌ Dataset MySQL NO cargado${NC}"
fi

# Verificar PostgreSQL OnPrem
echo "Verificando PostgreSQL OnPrem..."
total_checks=$((total_checks + 1))
if PGPASSWORD=DBAAdmin2024! psql -h 192.168.56.11 -U dbadmin -d postgres -c "SELECT version();" >/dev/null 2>&1; then
    echo -e "${GREEN}✅ PostgreSQL OnPrem funcionando${NC}"
    passed_checks=$((passed_checks + 1))
else
    echo -e "${RED}❌ PostgreSQL OnPrem NO funcionando${NC}"
fi

# Verificar dataset PostgreSQL
total_checks=$((total_checks + 1))
if PGPASSWORD=DBAAdmin2024! psql -h 192.168.56.11 -U dbadmin -d analytics_db -c "SELECT COUNT(*) FROM user_events;" >/dev/null 2>&1; then
    echo -e "${GREEN}✅ Dataset PostgreSQL cargado${NC}"
    passed_checks=$((passed_checks + 1))
else
    echo -e "${RED}❌ Dataset PostgreSQL NO cargado${NC}"
fi

# Verificar MongoDB OnPrem
echo "Verificando MongoDB OnPrem..."
total_checks=$((total_checks + 1))
if mongo --host 192.168.56.12:27017 -u dbadmin -p DBAAdmin2024! --authenticationDatabase admin --eval "db.version()" >/dev/null 2>&1; then
    echo -e "${GREEN}✅ MongoDB OnPrem funcionando${NC}"
    passed_checks=$((passed_checks + 1))
else
    echo -e "${RED}❌ MongoDB OnPrem NO funcionando${NC}"
fi

# Verificar dataset MongoDB
total_checks=$((total_checks + 1))
if mongo --host 192.168.56.12:27017 -u dbadmin -p DBAAdmin2024! --authenticationDatabase admin --eval "use social_media; db.users.count()" >/dev/null 2>&1; then
    echo -e "${GREEN}✅ Dataset MongoDB cargado${NC}"
    passed_checks=$((passed_checks + 1))
else
    echo -e "${RED}❌ Dataset MongoDB NO cargado${NC}"
fi

# Verificar Prometheus
echo "Verificando herramientas de monitoreo..."
total_checks=$((total_checks + 1))
if curl -s http://192.168.56.13:9090/api/v1/status/config >/dev/null 2>&1; then
    echo -e "${GREEN}✅ Prometheus funcionando${NC}"
    passed_checks=$((passed_checks + 1))
else
    echo -e "${RED}❌ Prometheus NO funcionando${NC}"
fi

# Verificar Grafana
total_checks=$((total_checks + 1))
if curl -s http://192.168.56.13:3000/api/health >/dev/null 2>&1; then
    echo -e "${GREEN}✅ Grafana funcionando${NC}"
    passed_checks=$((passed_checks + 1))
else
    echo -e "${RED}❌ Grafana NO funcionando${NC}"
fi

echo ""
echo -e "${BLUE}RESUMEN SEMANA 0${NC}"
echo "----------------------------------------"
percentage=$((passed_checks * 100 / total_checks))
echo "Verificaciones completadas: $passed_checks/$total_checks ($percentage%)"

if [ $percentage -ge 90 ]; then
    echo -e "${GREEN}🎉 SEMANA 0 COMPLETADA EXITOSAMENTE!${NC}"
    echo -e "${GREEN}Estás listo para la Semana 1 - Arquitecturas Híbridas${NC}"
elif [ $percentage -ge 70 ]; then
    echo -e "${YELLOW}⚠️  SEMANA 0 PARCIALMENTE COMPLETADA${NC}"
    echo -e "${YELLOW}Revisa las configuraciones faltantes antes de continuar${NC}"
else
    echo -e "${RED}🚨 SEMANA 0 INCOMPLETA${NC}"
    echo -e "${RED}Debes completar las configuraciones antes de continuar${NC}"
fi
```

### **Script Semana 1: check_week1_progress.sh**
```bash
#!/bin/bash

echo "=============================================="
echo "   VERIFICACIÓN SEMANA 1 - HÍBRIDO CLOUD"
echo "=============================================="

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

total_checks=0
passed_checks=0

echo -e "${BLUE}VERIFICANDO RECURSOS AWS${NC}"
echo "----------------------------------------"

# Verificar RDS MySQL
echo "Verificando RDS MySQL..."
total_checks=$((total_checks + 1))
rds_endpoint=$(aws rds describe-db-instances --db-instance-identifier dba-lab-mysql --query 'DBInstances[0].Endpoint.Address' --output text 2>/dev/null)
if [ "$rds_endpoint" != "None" ] && [ "$rds_endpoint" != "" ]; then
    echo -e "${GREEN}✅ RDS MySQL creado: $rds_endpoint${NC}"
    passed_checks=$((passed_checks + 1))
    
    # Verificar conectividad a RDS MySQL
    total_checks=$((total_checks + 1))
    if mysql -h $rds_endpoint -u dbadmin -pDBAAdmin2024! -e "SELECT VERSION();" >/dev/null 2>&1; then
        echo -e "${GREEN}✅ Conectividad a RDS MySQL OK${NC}"
        passed_checks=$((passed_checks + 1))
    else
        echo -e "${RED}❌ Sin conectividad a RDS MySQL${NC}"
    fi
else
    echo -e "${RED}❌ RDS MySQL NO encontrado${NC}"
fi

# Verificar RDS PostgreSQL
echo "Verificando RDS PostgreSQL..."
total_checks=$((total_checks + 1))
rds_pg_endpoint=$(aws rds describe-db-instances --db-instance-identifier dba-lab-postgresql --query 'DBInstances[0].Endpoint.Address' --output text 2>/dev/null)
if [ "$rds_pg_endpoint" != "None" ] && [ "$rds_pg_endpoint" != "" ]; then
    echo -e "${GREEN}✅ RDS PostgreSQL creado: $rds_pg_endpoint${NC}"
    passed_checks=$((passed_checks + 1))
    
    # Verificar conectividad a RDS PostgreSQL
    total_checks=$((total_checks + 1))
    if PGPASSWORD=DBAAdmin2024! psql -h $rds_pg_endpoint -U dbadmin -d postgres -c "SELECT version();" >/dev/null 2>&1; then
        echo -e "${GREEN}✅ Conectividad a RDS PostgreSQL OK${NC}"
        passed_checks=$((passed_checks + 1))
    else
        echo -e "${RED}❌ Sin conectividad a RDS PostgreSQL${NC}"
    fi
else
    echo -e "${RED}❌ RDS PostgreSQL NO encontrado${NC}"
fi

# Verificar DocumentDB
echo "Verificando DocumentDB..."
total_checks=$((total_checks + 1))
docdb_endpoint=$(aws docdb describe-db-clusters --db-cluster-identifier dba-lab-docdb --query 'DBClusters[0].Endpoint' --output text 2>/dev/null)
if [ "$docdb_endpoint" != "None" ] && [ "$docdb_endpoint" != "" ]; then
    echo -e "${GREEN}✅ DocumentDB creado: $docdb_endpoint${NC}"
    passed_checks=$((passed_checks + 1))
    
    # Verificar conectividad a DocumentDB
    total_checks=$((total_checks + 1))
    if mongo --ssl --host $docdb_endpoint:27017 --sslCAFile rds-combined-ca-bundle.pem --username dbadmin --password DBAAdmin2024! --eval "db.version()" >/dev/null 2>&1; then
        echo -e "${GREEN}✅ Conectividad a DocumentDB OK${NC}"
        passed_checks=$((passed_checks + 1))
    else
        echo -e "${RED}❌ Sin conectividad a DocumentDB${NC}"
    fi
else
    echo -e "${RED}❌ DocumentDB NO encontrado${NC}"
fi

# Verificar VPC
echo "Verificando infraestructura de red..."
total_checks=$((total_checks + 1))
vpc_id=$(aws ec2 describe-vpcs --filters "Name=tag:Name,Values=DBA-Lab-VPC" --query 'Vpcs[0].VpcId' --output text 2>/dev/null)
if [ "$vpc_id" != "None" ] && [ "$vpc_id" != "" ]; then
    echo -e "${GREEN}✅ VPC creada: $vpc_id${NC}"
    passed_checks=$((passed_checks + 1))
else
    echo -e "${RED}❌ VPC NO encontrada${NC}"
fi

# Verificar migración de datos
echo "Verificando migración de datos..."
total_checks=$((total_checks + 1))
if [ "$rds_endpoint" != "None" ] && [ "$rds_endpoint" != "" ]; then
    if mysql -h $rds_endpoint -u dbadmin -pDBAAdmin2024! -e "USE ecommerce; SELECT COUNT(*) FROM products;" >/dev/null 2>&1; then
        echo -e "${GREEN}✅ Datos migrados a RDS MySQL${NC}"
        passed_checks=$((passed_checks + 1))
    else
        echo -e "${RED}❌ Datos NO migrados a RDS MySQL${NC}"
    fi
else
    echo -e "${RED}❌ No se puede verificar migración - RDS MySQL no disponible${NC}"
fi

echo ""
echo -e "${BLUE}RESUMEN SEMANA 1${NC}"
echo "----------------------------------------"
percentage=$((passed_checks * 100 / total_checks))
echo "Verificaciones completadas: $passed_checks/$total_checks ($percentage%)"

if [ $percentage -ge 90 ]; then
    echo -e "${GREEN}🎉 SEMANA 1 COMPLETADA EXITOSAMENTE!${NC}"
    echo -e "${GREEN}Arquitectura híbrida OnPrem + Cloud funcionando${NC}"
elif [ $percentage -ge 70 ]; then
    echo -e "${YELLOW}⚠️  SEMANA 1 PARCIALMENTE COMPLETADA${NC}"
    echo -e "${YELLOW}Revisa las configuraciones de AWS faltantes${NC}"
else
    echo -e "${RED}🚨 SEMANA 1 INCOMPLETA${NC}"
    echo -e "${RED}Debes completar la configuración híbrida${NC}"
fi
```

---

## 🔧 **SCRIPTS DE DIAGNÓSTICO ESPECÍFICOS**

### **Script de Diagnóstico de Conectividad: diagnose_connectivity.sh**
```bash
#!/bin/bash

echo "=============================================="
echo "      DIAGNÓSTICO DE CONECTIVIDAD"
echo "=============================================="

# Función para testing de conectividad
test_connection() {
    local host=$1
    local port=$2
    local service=$3
    local timeout=5
    
    echo -n "Testing $service ($host:$port)... "
    
    if timeout $timeout bash -c "</dev/tcp/$host/$port" 2>/dev/null; then
        echo -e "${GREEN}OK${NC}"
        return 0
    else
        echo -e "${RED}FAILED${NC}"
        return 1
    fi
}

# Testing conectividad OnPrem
echo "CONECTIVIDAD ONPREM:"
echo "--------------------"
test_connection "192.168.56.10" "3306" "MySQL OnPrem"
test_connection "192.168.56.11" "5432" "PostgreSQL OnPrem"
test_connection "192.168.56.12" "27017" "MongoDB OnPrem"
test_connection "192.168.56.13" "9090" "Prometheus"
test_connection "192.168.56.13" "3000" "Grafana"

echo ""
echo "CONECTIVIDAD INTERNET:"
echo "----------------------"
test_connection "8.8.8.8" "53" "DNS Google"
test_connection "github.com" "443" "GitHub"
test_connection "registry.hub.docker.com" "443" "Docker Hub"

echo ""
echo "CONECTIVIDAD AWS:"
echo "-----------------"
test_connection "ec2.us-east-1.amazonaws.com" "443" "AWS EC2"
test_connection "rds.us-east-1.amazonaws.com" "443" "AWS RDS"

# Testing específico de bases de datos
echo ""
echo "TESTING DE AUTENTICACIÓN:"
echo "-------------------------"

# MySQL OnPrem
echo -n "MySQL OnPrem auth... "
if mysql -h 192.168.56.10 -u dbadmin -pDBAAdmin2024! -e "SELECT 1;" >/dev/null 2>&1; then
    echo -e "${GREEN}OK${NC}"
else
    echo -e "${RED}FAILED${NC}"
fi

# PostgreSQL OnPrem
echo -n "PostgreSQL OnPrem auth... "
if PGPASSWORD=DBAAdmin2024! psql -h 192.168.56.11 -U dbadmin -d postgres -c "SELECT 1;" >/dev/null 2>&1; then
    echo -e "${GREEN}OK${NC}"
else
    echo -e "${RED}FAILED${NC}"
fi

# MongoDB OnPrem
echo -n "MongoDB OnPrem auth... "
if mongo --host 192.168.56.12:27017 -u dbadmin -p DBAAdmin2024! --authenticationDatabase admin --eval "db.version()" >/dev/null 2>&1; then
    echo -e "${GREEN}OK${NC}"
else
    echo -e "${RED}FAILED${NC}"
fi
```

### **Script de Verificación de Performance: check_performance.sh**
```bash
#!/bin/bash

echo "=============================================="
echo "      VERIFICACIÓN DE PERFORMANCE"
echo "=============================================="

# Función para medir latencia
measure_latency() {
    local host=$1
    local port=$2
    local service=$3
    
    echo -n "Latencia $service ($host:$port): "
    
    # Usar nc para medir tiempo de conexión
    start_time=$(date +%s%N)
    if nc -z $host $port 2>/dev/null; then
        end_time=$(date +%s%N)
        latency=$(( (end_time - start_time) / 1000000 ))
        
        if [ $latency -lt 10 ]; then
            echo -e "${GREEN}${latency}ms (Excelente)${NC}"
        elif [ $latency -lt 50 ]; then
            echo -e "${YELLOW}${latency}ms (Bueno)${NC}"
        else
            echo -e "${RED}${latency}ms (Lento)${NC}"
        fi
    else
        echo -e "${RED}No conecta${NC}"
    fi
}

# Medir latencias OnPrem
echo "LATENCIAS ONPREM:"
echo "-----------------"
measure_latency "192.168.56.10" "3306" "MySQL"
measure_latency "192.168.56.11" "5432" "PostgreSQL"
measure_latency "192.168.56.12" "27017" "MongoDB"

# Testing de queries simples
echo ""
echo "PERFORMANCE DE QUERIES:"
echo "-----------------------"

# MySQL query performance
echo -n "MySQL simple query: "
start_time=$(date +%s%N)
if mysql -h 192.168.56.10 -u dbadmin -pDBAAdmin2024! -e "SELECT COUNT(*) FROM information_schema.tables;" >/dev/null 2>&1; then
    end_time=$(date +%s%N)
    query_time=$(( (end_time - start_time) / 1000000 ))
    echo -e "${GREEN}${query_time}ms${NC}"
else
    echo -e "${RED}FAILED${NC}"
fi

# PostgreSQL query performance
echo -n "PostgreSQL simple query: "
start_time=$(date +%s%N)
if PGPASSWORD=DBAAdmin2024! psql -h 192.168.56.11 -U dbadmin -d postgres -c "SELECT COUNT(*) FROM information_schema.tables;" >/dev/null 2>&1; then
    end_time=$(date +%s%N)
    query_time=$(( (end_time - start_time) / 1000000 ))
    echo -e "${GREEN}${query_time}ms${NC}"
else
    echo -e "${RED}FAILED${NC}"
fi
```

---

## 📊 **SCRIPT DE REPORTE COMPLETO**

### **Script de Reporte: generate_progress_report.sh**
```bash
#!/bin/bash

echo "=============================================="
echo "    REPORTE COMPLETO DE PROGRESO"
echo "=============================================="

# Crear archivo de reporte
REPORT_FILE="progress_report_$(date +%Y%m%d_%H%M%S).txt"

{
    echo "DBA CLOUD ONPREM JUNIOR - REPORTE DE PROGRESO"
    echo "Fecha: $(date)"
    echo "Usuario: $(whoami)"
    echo "Host: $(hostname)"
    echo ""
    
    echo "VERIFICACIÓN GENERAL:"
    echo "===================="
    ./check_overall_progress.sh
    
    echo ""
    echo "VERIFICACIÓN SEMANA 0:"
    echo "====================="
    ./check_week0_progress.sh
    
    echo ""
    echo "VERIFICACIÓN SEMANA 1:"
    echo "====================="
    ./check_week1_progress.sh
    
    echo ""
    echo "DIAGNÓSTICO DE CONECTIVIDAD:"
    echo "============================"
    ./diagnose_connectivity.sh
    
    echo ""
    echo "VERIFICACIÓN DE PERFORMANCE:"
    echo "============================"
    ./check_performance.sh
    
} > $REPORT_FILE

echo "Reporte generado: $REPORT_FILE"
echo "Para ver el reporte: cat $REPORT_FILE"
```

---

## 🎯 **INSTRUCCIONES DE USO**

### **Instalación de Scripts**
```bash
# 1. Crear directorio para scripts
mkdir -p ~/dba-scripts
cd ~/dba-scripts

# 2. Descargar todos los scripts
# (Los scripts están incluidos en el material del estudiante)

# 3. Hacer ejecutables
chmod +x *.sh

# 4. Ejecutar verificación inicial
./check_overall_progress.sh
```

### **Uso Semanal**
```bash
# Al final de cada semana, ejecutar:
./check_week0_progress.sh  # Después de Semana 0
./check_week1_progress.sh  # Después de Semana 1
# ... etc

# Para diagnóstico de problemas:
./diagnose_connectivity.sh
./check_performance.sh

# Para reporte completo:
./generate_progress_report.sh
```

### **Interpretación de Resultados**
```
✅ Verde: Configuración correcta
⚠️  Amarillo: Configuración parcial - necesita atención
❌ Rojo: Configuración incorrecta - requiere corrección

Porcentajes:
- 90-100%: Excelente - Continúa a la siguiente semana
- 70-89%: Bueno - Revisa elementos faltantes
- <70%: Insuficiente - Completa configuraciones antes de continuar
```

---

**🔍 Estos scripts te permiten verificar automáticamente tu progreso y identificar problemas antes de que afecten tu aprendizaje. ¡Úsalos regularmente para mantener tu entorno en perfecto estado!**
