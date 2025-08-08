# Lab 04: Percona Distribution for PostgreSQL

## Objetivo
Instalar y configurar el operador de Percona Distribution for PostgreSQL.

## Duración Estimada
45 minutos

## Conceptos Clave
- **PG**: Percona Distribution for PostgreSQL
- **Patroni**: Herramienta para alta disponibilidad de PostgreSQL
- **pgBouncer**: Connection pooler para PostgreSQL
- **WAL-G**: Herramienta para backup y restore

## Pasos

### 1. Instalar el Operador PostgreSQL

```bash
# Usando Helm
helm install pg-operator percona/pg-operator --namespace percona-operators

# O usando kubectl
kubectl apply -f https://raw.githubusercontent.com/percona/percona-postgresql-operator/v2.3.1/deploy/bundle.yaml
```

### 2. Verificar la instalación

```bash
kubectl get pods -n percona-operators
kubectl logs -n percona-operators deployment/percona-postgresql-operator
```

### 3. Crear secretos para PostgreSQL

```bash
kubectl apply -f pg-secrets.yaml
```

### 4. Desplegar el cluster PostgreSQL

```bash
kubectl apply -f pg-cluster.yaml
```

### 5. Monitorear el despliegue

```bash
# Ver estado del cluster
kubectl get pg

# Ver pods del cluster
kubectl get pods -l postgres-operator.crunchydata.com/cluster=pg-cluster

# Ver logs
kubectl logs pg-cluster-instance1-xxxx-0
```

### 6. Conectarse al cluster

```bash
# Obtener la contraseña
kubectl get secret pg-cluster-pguser-postgres -o jsonpath='{.data.password}' | base64 --decode

# Port-forward al servicio
kubectl port-forward svc/pg-cluster-primary 5432:5432

# Conectarse con psql
psql -h localhost -p 5432 -U postgres -d postgres
```

### 7. Probar funcionalidad

```sql
-- Crear base de datos de prueba
CREATE DATABASE lab_test;
\c lab_test;

-- Crear tabla de prueba
CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Insertar datos de prueba
INSERT INTO users (name, email) VALUES 
('Juan Pérez', 'juan@example.com'),
('María García', 'maria@example.com'),
('Carlos López', 'carlos@example.com');

-- Consultar datos
SELECT * FROM users;

-- Verificar replicación
SELECT * FROM pg_stat_replication;

-- Ver configuración del cluster
SELECT name, setting FROM pg_settings WHERE name LIKE '%wal%';
```

## Verificación

Al finalizar este laboratorio deberías tener:
- ✅ Operador PostgreSQL instalado y funcionando
- ✅ Cluster PostgreSQL con alta disponibilidad
- ✅ Patroni configurado para failover automático
- ✅ Capacidad de conectarse y ejecutar consultas
- ✅ Replicación funcionando correctamente

## Comandos Útiles

```bash
# Ver estado detallado del cluster
kubectl describe pg pg-cluster

# Ver réplicas
kubectl get pods -l postgres-operator.crunchydata.com/role=replica

# Forzar failover (para pruebas)
kubectl annotate pg pg-cluster postgres-operator.crunchydata.com/trigger-failover=true

# Ver backups
kubectl get pgbackup
```

## Siguiente Paso
Continuar con `lab-05-backup-restore` para aprender sobre backup y restore.
