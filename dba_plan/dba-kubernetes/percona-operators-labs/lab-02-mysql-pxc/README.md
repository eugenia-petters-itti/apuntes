# Lab 02: Percona XtraDB Cluster (MySQL)

## Objetivo
Instalar y configurar el operador de Percona XtraDB Cluster para MySQL.

## Duración Estimada
45 minutos

## Conceptos Clave
- **PXC**: Percona XtraDB Cluster - Solución de MySQL con alta disponibilidad
- **Galera**: Tecnología de replicación síncrona multi-master
- **ProxySQL**: Proxy inteligente para balanceo de carga

## Pasos

### 1. Instalar el Operador PXC

```bash
# Método 1: Usando kubectl
kubectl apply -f https://raw.githubusercontent.com/percona/percona-xtradb-cluster-operator/v1.14.0/deploy/bundle.yaml

# Método 2: Usando Helm (recomendado)
helm install pxc-operator percona/pxc-operator --namespace percona-operators
```

### 2. Verificar la instalación del operador

```bash
kubectl get pods -n percona-operators
kubectl logs -n percona-operators deployment/percona-xtradb-cluster-operator
```

### 3. Crear secretos para las credenciales

```bash
kubectl apply -f pxc-secrets.yaml
```

### 4. Desplegar el cluster PXC

```bash
kubectl apply -f pxc-cluster.yaml
```

### 5. Monitorear el despliegue

```bash
# Ver el estado del cluster
kubectl get pxc

# Ver pods del cluster
kubectl get pods -l app.kubernetes.io/name=percona-xtradb-cluster

# Ver logs de inicialización
kubectl logs pxc-cluster-pxc-0
```

### 6. Conectarse al cluster

```bash
# Obtener la contraseña root
kubectl get secret pxc-cluster-secrets -o jsonpath='{.data.root}' | base64 --decode

# Conectarse usando port-forward
kubectl port-forward svc/pxc-cluster-proxysql 6033:6033

# En otra terminal
mysql -h127.0.0.1 -P6033 -uroot -p
```

### 7. Probar la funcionalidad del cluster

```sql
-- Crear base de datos de prueba
CREATE DATABASE lab_test;
USE lab_test;

-- Crear tabla de prueba
CREATE TABLE users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100),
    email VARCHAR(100),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Insertar datos de prueba
INSERT INTO users (name, email) VALUES 
('Juan Pérez', 'juan@example.com'),
('María García', 'maria@example.com'),
('Carlos López', 'carlos@example.com');

-- Verificar datos
SELECT * FROM users;

-- Verificar estado del cluster
SHOW STATUS LIKE 'wsrep%';
```

## Verificación

Al finalizar este laboratorio deberías tener:
- ✅ Operador PXC instalado y funcionando
- ✅ Cluster PXC de 3 nodos desplegado
- ✅ ProxySQL funcionando como proxy
- ✅ Capacidad de conectarse y ejecutar consultas
- ✅ Datos replicados en todos los nodos

## Comandos Útiles

```bash
# Ver estado detallado del cluster
kubectl describe pxc pxc-cluster

# Ver configuración del cluster
kubectl get pxc pxc-cluster -o yaml

# Escalar el cluster
kubectl patch pxc pxc-cluster --type='merge' -p='{"spec":{"pxc":{"size":5}}}'

# Ver métricas del cluster
kubectl port-forward svc/pxc-cluster-pxc 33062:33062
# Acceder a http://localhost:33062/metrics
```

## Troubleshooting

### Problema: Pods no inician
```bash
# Verificar recursos
kubectl describe pod pxc-cluster-pxc-0

# Verificar logs
kubectl logs pxc-cluster-pxc-0 -c pxc

# Verificar PVCs
kubectl get pvc
```

### Problema: Cluster no forma quorum
```bash
# Verificar estado de Galera
kubectl exec pxc-cluster-pxc-0 -- mysql -uroot -p<password> -e "SHOW STATUS LIKE 'wsrep_cluster_size'"

# Reiniciar cluster si es necesario
kubectl delete pod pxc-cluster-pxc-0 pxc-cluster-pxc-1 pxc-cluster-pxc-2
```

## Siguiente Paso
Continuar con `lab-03-mongodb-psmdb` para el operador de MongoDB.
