# Lab 01: Configuración del Entorno

## Objetivo
Preparar el entorno de Kubernetes para ejecutar los operadores de Percona.

## Duración Estimada
30 minutos

## Prerrequisitos
- Docker instalado
- kubectl instalado
- Helm 3.x instalado

## Pasos

### 1. Crear cluster de Kubernetes (usando kind)

```bash
# Instalar kind si no está instalado
# macOS: brew install kind
# Linux: curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.20.0/kind-linux-amd64

# Crear cluster con configuración personalizada
kind create cluster --config=kind-config.yaml --name=percona-lab
```

### 2. Verificar el cluster

```bash
kubectl cluster-info
kubectl get nodes
```

### 3. Instalar cert-manager (requerido por los operadores)

```bash
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.13.0/cert-manager.yaml
```

### 4. Crear namespace para los operadores

```bash
kubectl create namespace percona-operators
```

### 5. Verificar que cert-manager está funcionando

```bash
kubectl get pods -n cert-manager
```

### 6. Instalar herramientas adicionales

```bash
# Instalar Helm si no está instalado
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# Agregar repositorio de Percona
helm repo add percona https://percona.github.io/percona-helm-charts/
helm repo update
```

## Verificación

Al finalizar este laboratorio deberías tener:
- ✅ Cluster de Kubernetes funcionando
- ✅ cert-manager instalado y funcionando
- ✅ Namespace percona-operators creado
- ✅ Repositorio Helm de Percona agregado

## Troubleshooting

### Problema: cert-manager pods no inician
```bash
# Verificar recursos
kubectl describe pods -n cert-manager

# Verificar logs
kubectl logs -n cert-manager deployment/cert-manager
```

### Problema: kind cluster no inicia
```bash
# Limpiar y recrear
kind delete cluster --name=percona-lab
kind create cluster --config=kind-config.yaml --name=percona-lab
```

## Siguiente Paso
Continuar con `lab-02-mysql-pxc` para instalar el operador de MySQL.
