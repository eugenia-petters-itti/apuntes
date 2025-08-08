# Lab 03: Percona Server for MongoDB (PSMDB)

## Objetivo
Instalar y configurar el operador de Percona Server for MongoDB.

## Duración Estimada
45 minutos

## Conceptos Clave
- **PSMDB**: Percona Server for MongoDB - Versión mejorada de MongoDB
- **Replica Set**: Conjunto de réplicas para alta disponibilidad
- **Sharding**: Distribución horizontal de datos
- **mongos**: Router para clusters con sharding

## Pasos

### 1. Instalar el Operador PSMDB

```bash
# Usando Helm
helm install psmdb-operator percona/psmdb-operator --namespace percona-operators

# O usando kubectl
kubectl apply -f https://raw.githubusercontent.com/percona/percona-server-mongodb-operator/v1.15.0/deploy/bundle.yaml
```

### 2. Verificar la instalación

```bash
kubectl get pods -n percona-operators
kubectl logs -n percona-operators deployment/percona-server-mongodb-operator
```

### 3. Crear secretos para MongoDB

```bash
kubectl apply -f psmdb-secrets.yaml
```

### 4. Desplegar el cluster PSMDB

```bash
kubectl apply -f psmdb-cluster.yaml
```

### 5. Monitorear el despliegue

```bash
# Ver estado del cluster
kubectl get psmdb

# Ver pods del cluster
kubectl get pods -l app.kubernetes.io/name=percona-server-mongodb

# Ver logs
kubectl logs psmdb-cluster-rs0-0
```

### 6. Conectarse al cluster

```bash
# Port-forward al servicio
kubectl port-forward svc/psmdb-cluster-mongos 27017:27017

# En otra terminal, conectarse con mongo shell
mongosh mongodb://databaseAdmin:databaseAdminPassword@localhost:27017/admin
```

### 7. Probar funcionalidad

```javascript
// Verificar estado del replica set
rs.status()

// Crear base de datos de prueba
use lab_test

// Crear colección e insertar documentos
db.users.insertMany([
  { name: "Juan Pérez", email: "juan@example.com", age: 30 },
  { name: "María García", email: "maria@example.com", age: 25 },
  { name: "Carlos López", email: "carlos@example.com", age: 35 }
])

// Consultar documentos
db.users.find().pretty()

// Crear índice
db.users.createIndex({ email: 1 }, { unique: true })

// Verificar réplicas
db.runCommand({ isMaster: 1 })
```

## Verificación

Al finalizar este laboratorio deberías tener:
- ✅ Operador PSMDB instalado y funcionando
- ✅ Cluster MongoDB de 3 nodos desplegado
- ✅ Replica Set configurado correctamente
- ✅ Capacidad de conectarse y ejecutar operaciones
- ✅ Datos replicados en todos los nodos

## Siguiente Paso
Continuar con `lab-04-postgresql-pg` para el operador de PostgreSQL.
