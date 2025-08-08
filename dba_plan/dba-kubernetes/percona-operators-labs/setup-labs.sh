#!/bin/bash

# Script para configurar todos los laboratorios de operadores Percona
# Autor: Amazon Q
# Fecha: $(date)

set -e

echo "🚀 Configurando laboratorios de operadores Percona..."

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Función para imprimir mensajes
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Verificar prerrequisitos
check_prerequisites() {
    print_status "Verificando prerrequisitos..."
    
    # Verificar kubectl
    if ! command -v kubectl &> /dev/null; then
        print_error "kubectl no está instalado"
        exit 1
    fi
    
    # Verificar helm
    if ! command -v helm &> /dev/null; then
        print_error "helm no está instalado"
        exit 1
    fi
    
    # Verificar kind
    if ! command -v kind &> /dev/null; then
        print_error "kind no está instalado"
        exit 1
    fi
    
    print_success "Todos los prerrequisitos están instalados"
}

# Crear cluster de Kubernetes
create_cluster() {
    print_status "Creando cluster de Kubernetes..."
    
    if kind get clusters | grep -q "percona-lab"; then
        print_warning "El cluster percona-lab ya existe"
        read -p "¿Deseas recrearlo? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            kind delete cluster --name=percona-lab
        else
            print_status "Usando cluster existente"
            return
        fi
    fi
    
    cd lab-01-setup
    kind create cluster --config=kind-config.yaml --name=percona-lab
    cd ..
    
    print_success "Cluster creado exitosamente"
}

# Instalar cert-manager
install_cert_manager() {
    print_status "Instalando cert-manager..."
    
    kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.13.0/cert-manager.yaml
    
    print_status "Esperando a que cert-manager esté listo..."
    kubectl wait --for=condition=ready pod -l app=cert-manager -n cert-manager --timeout=300s
    kubectl wait --for=condition=ready pod -l app=cainjector -n cert-manager --timeout=300s
    kubectl wait --for=condition=ready pod -l app=webhook -n cert-manager --timeout=300s
    
    print_success "cert-manager instalado exitosamente"
}

# Crear namespace
create_namespace() {
    print_status "Creando namespace percona-operators..."
    kubectl create namespace percona-operators --dry-run=client -o yaml | kubectl apply -f -
    print_success "Namespace creado"
}

# Agregar repositorio Helm
add_helm_repo() {
    print_status "Agregando repositorio Helm de Percona..."
    helm repo add percona https://percona.github.io/percona-helm-charts/
    helm repo update
    print_success "Repositorio Helm agregado"
}

# Función principal
main() {
    echo "======================================"
    echo "  Laboratorios Operadores Percona"
    echo "======================================"
    echo
    
    check_prerequisites
    create_cluster
    install_cert_manager
    create_namespace
    add_helm_repo
    
    echo
    print_success "¡Configuración inicial completada!"
    echo
    echo "Próximos pasos:"
    echo "1. cd lab-02-mysql-pxc && kubectl apply -f ."
    echo "2. cd lab-03-mongodb-psmdb && kubectl apply -f ."
    echo "3. cd lab-04-postgresql-pg && kubectl apply -f ."
    echo
    echo "Para monitorear el progreso:"
    echo "kubectl get pods -n percona-operators -w"
    echo
}

# Ejecutar función principal
main "$@"
