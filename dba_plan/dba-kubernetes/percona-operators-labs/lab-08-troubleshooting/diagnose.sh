#!/bin/bash

# Script de diagnóstico para operadores Percona
# Uso: ./diagnose.sh [mysql|mongodb|postgresql|all]

set -e

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_header() {
    echo -e "\n${BLUE}=== $1 ===${NC}"
}

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

# Función para verificar cluster general
check_cluster() {
    print_header "Cluster Status"
    
    echo "Nodes:"
    kubectl get nodes
    
    echo -e "\nPods con problemas:"
    kubectl get pods --all-namespaces | grep -E "(Error|CrashLoop|Pending|Failed)" || echo "No hay pods con problemas"
    
    echo -e "\nEventos recientes:"
    kubectl get events --sort-by='.lastTimestamp' | tail -10
}

# Función para verificar operadores
check_operators() {
    print_header "Percona Operators"
    
    echo "Pods de operadores:"
    kubectl get pods -n percona-operators
    
    echo -e "\nRecursos Percona:"
    kubectl get pxc,psmdb,postgrescluster 2>/dev/null || echo "No hay recursos Percona desplegados"
}

# Función para verificar MySQL PXC
check_mysql() {
    print_header "MySQL PXC Diagnostics"
    
    # Verificar si existe el cluster
    if ! kubectl get pxc pxc-cluster &>/dev/null; then
        print_warning "Cluster PXC no encontrado"
        return
    fi
    
    echo "Estado del cluster PXC:"
    kubectl get pxc pxc-cluster
    
    echo -e "\nPods PXC:"
    kubectl get pods -l app.kubernetes.io/name=percona-xtradb-cluster
    
    # Verificar conectividad si los pods están corriendo
    if kubectl get pod pxc-cluster-pxc-0 &>/dev/null; then
        echo -e "\nVerificando conectividad MySQL:"
        if kubectl exec pxc-cluster-pxc-0 -- mysql -uroot -p$(kubectl get secret pxc-cluster-secrets -o jsonpath='{.data.root}' | base64 --decode) -e "SELECT 1" &>/dev/null; then
            print_success "MySQL conectividad OK"
            
            echo -e "\nEstado del cluster Galera:"
            kubectl exec pxc-cluster-pxc-0 -- mysql -uroot -p$(kubectl get secret pxc-cluster-secrets -o jsonpath='{.data.root}' | base64 --decode) -e "SHOW STATUS LIKE 'wsrep_cluster_size'"
        else
            print_error "No se puede conectar a MySQL"
        fi
    fi
    
    echo -e "\nPVCs MySQL:"
    kubectl get pvc | grep pxc-cluster || echo "No hay PVCs de PXC"
}

# Función para verificar MongoDB
check_mongodb() {
    print_header "MongoDB PSMDB Diagnostics"
    
    if ! kubectl get psmdb psmdb-cluster &>/dev/null; then
        print_warning "Cluster PSMDB no encontrado"
        return
    fi
    
    echo "Estado del cluster PSMDB:"
    kubectl get psmdb psmdb-cluster
    
    echo -e "\nPods PSMDB:"
    kubectl get pods -l app.kubernetes.io/name=percona-server-mongodb
    
    if kubectl get pod psmdb-cluster-rs0-0 &>/dev/null; then
        echo -e "\nVerificando conectividad MongoDB:"
        if kubectl exec psmdb-cluster-rs0-0 -- mongosh --eval "db.runCommand('ping')" &>/dev/null; then
            print_success "MongoDB conectividad OK"
            
            echo -e "\nEstado del replica set:"
            kubectl exec psmdb-cluster-rs0-0 -- mongosh --eval "rs.status().members.forEach(m => print(m.name + ': ' + m.stateStr))"
        else
            print_error "No se puede conectar a MongoDB"
        fi
    fi
    
    echo -e "\nPVCs MongoDB:"
    kubectl get pvc | grep psmdb-cluster || echo "No hay PVCs de PSMDB"
}

# Función para verificar PostgreSQL
check_postgresql() {
    print_header "PostgreSQL Diagnostics"
    
    if ! kubectl get postgrescluster pg-cluster &>/dev/null; then
        print_warning "Cluster PostgreSQL no encontrado"
        return
    fi
    
    echo "Estado del cluster PostgreSQL:"
    kubectl get postgrescluster pg-cluster
    
    echo -e "\nPods PostgreSQL:"
    kubectl get pods -l postgres-operator.crunchydata.com/cluster=pg-cluster
    
    # Buscar el pod primary
    PRIMARY_POD=$(kubectl get pods -l postgres-operator.crunchydata.com/cluster=pg-cluster,postgres-operator.crunchydata.com/role=master -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
    
    if [ -n "$PRIMARY_POD" ]; then
        echo -e "\nVerificando conectividad PostgreSQL:"
        if kubectl exec $PRIMARY_POD -- psql -U postgres -c "SELECT 1" &>/dev/null; then
            print_success "PostgreSQL conectividad OK"
            
            echo -e "\nEstado de replicación:"
            kubectl exec $PRIMARY_POD -- psql -U postgres -c "SELECT client_addr, state, sync_state FROM pg_stat_replication;"
        else
            print_error "No se puede conectar a PostgreSQL"
        fi
    fi
    
    echo -e "\nPVCs PostgreSQL:"
    kubectl get pvc | grep pg-cluster || echo "No hay PVCs de PostgreSQL"
}

# Función para verificar recursos
check_resources() {
    print_header "Resource Usage"
    
    echo "Uso de recursos por nodo:"
    kubectl top nodes 2>/dev/null || echo "Metrics server no disponible"
    
    echo -e "\nUso de recursos por pod:"
    kubectl top pods 2>/dev/null || echo "Metrics server no disponible"
    
    echo -e "\nPVCs y su uso:"
    kubectl get pvc
}

# Función para verificar PMM
check_pmm() {
    print_header "PMM Status"
    
    if kubectl get pod -l app=pmm-server &>/dev/null; then
        echo "PMM Server:"
        kubectl get pods -l app=pmm-server
        
        echo -e "\nPMM Clients:"
        kubectl get pods -l app.kubernetes.io/name=pmm-client
        
        print_success "PMM está desplegado"
    else
        print_warning "PMM no está desplegado"
    fi
}

# Función principal
main() {
    local component=${1:-all}
    
    echo "======================================"
    echo "  Diagnóstico Operadores Percona"
    echo "======================================"
    echo "Fecha: $(date)"
    echo "Cluster: $(kubectl config current-context)"
    
    case $component in
        mysql)
            check_mysql
            ;;
        mongodb)
            check_mongodb
            ;;
        postgresql)
            check_postgresql
            ;;
        all)
            check_cluster
            check_operators
            check_mysql
            check_mongodb
            check_postgresql
            check_resources
            check_pmm
            ;;
        *)
            echo "Uso: $0 [mysql|mongodb|postgresql|all]"
            exit 1
            ;;
    esac
    
    echo -e "\n${GREEN}Diagnóstico completado${NC}"
}

main "$@"
