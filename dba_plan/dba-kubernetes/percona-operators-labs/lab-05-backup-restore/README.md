# Lab 05: Backup y Restore

## Objetivo
Aprender a configurar y ejecutar backups y restores para todos los operadores de Percona.

## Duración Estimada
60 minutos

## Conceptos Clave
- **Backup programado**: Backups automáticos con cron
- **Backup bajo demanda**: Backups manuales
- **Point-in-Time Recovery (PITR)**: Restauración a un momento específico
- **Almacenamiento S3**: Backup remoto en object storage

## Estructura del Laboratorio

```
lab-05-backup-restore/
├── mysql-pxc/          # Backups para MySQL PXC
├── mongodb-psmdb/      # Backups para MongoDB
├── postgresql-pg/      # Backups para PostgreSQL
└── s3-setup/          # Configuración de S3 (MinIO)
```

## Parte 1: Configurar MinIO como S3 Compatible

### 1. Desplegar MinIO

```bash
kubectl apply -f s3-setup/minio-deployment.yaml
```

### 2. Crear buckets necesarios

```bash
# Port-forward a MinIO
kubectl port-forward svc/minio 9000:9000

# Acceder a MinIO Console en http://localhost:9000
# Usuario: minioadmin, Password: minioadmin

# Crear buckets:
# - mysql-backups
# - mongodb-backups  
# - postgresql-backups
```

## Parte 2: MySQL PXC Backups

### 1. Configurar credenciales S3

```bash
kubectl apply -f mysql-pxc/s3-credentials.yaml
```

### 2. Crear backup bajo demanda

```bash
kubectl apply -f mysql-pxc/backup-ondemand.yaml
```

### 3. Monitorear el backup

```bash
kubectl get pxc-backup
kubectl describe pxc-backup backup-ondemand-$(date +%Y%m%d)
```

### 4. Programar backups automáticos

```bash
kubectl apply -f mysql-pxc/backup-scheduled.yaml
```

### 5. Restaurar desde backup

```bash
kubectl apply -f mysql-pxc/restore-cluster.yaml
```

## Parte 3: MongoDB PSMDB Backups

### 1. Configurar credenciales S3

```bash
kubectl apply -f mongodb-psmdb/s3-credentials.yaml
```

### 2. Crear backup bajo demanda

```bash
kubectl apply -f mongodb-psmdb/backup-ondemand.yaml
```

### 3. Monitorear el backup

```bash
kubectl get psmdb-backup
kubectl describe psmdb-backup backup-ondemand-$(date +%Y%m%d)
```

### 4. Restaurar desde backup

```bash
kubectl apply -f mongodb-psmdb/restore-cluster.yaml
```

## Parte 4: PostgreSQL Backups

### 1. Ejecutar backup manual

```bash
kubectl annotate postgrescluster pg-cluster \
  postgres-operator.crunchydata.com/pgbackrest-backup="$(date)"
```

### 2. Ver backups disponibles

```bash
kubectl exec -it pg-cluster-repo-host-0 -- pgbackrest info
```

### 3. Restaurar desde backup

```bash
kubectl apply -f postgresql-pg/restore-cluster.yaml
```

## Verificación de Backups

### MySQL PXC
```bash
# Ver lista de backups
kubectl get pxc-backup

# Ver detalles del backup
kubectl describe pxc-backup <backup-name>

# Ver logs del backup
kubectl logs job/<backup-job-name>
```

### MongoDB PSMDB
```bash
# Ver lista de backups
kubectl get psmdb-backup

# Ver detalles del backup
kubectl describe psmdb-backup <backup-name>

# Ver logs del backup
kubectl logs job/<backup-job-name>
```

### PostgreSQL
```bash
# Ver información de backups
kubectl exec -it pg-cluster-repo-host-0 -- pgbackrest info

# Ver logs de backup
kubectl logs pg-cluster-repo-host-0
```

## Pruebas de Disaster Recovery

### 1. Simular pérdida de datos

```bash
# MySQL: Eliminar datos de prueba
kubectl exec -it pxc-cluster-pxc-0 -- mysql -uroot -p<password> -e "DROP DATABASE lab_test;"

# MongoDB: Eliminar colección
kubectl exec -it psmdb-cluster-rs0-0 -- mongosh --eval "use lab_test; db.users.drop();"

# PostgreSQL: Eliminar tabla
kubectl exec -it pg-cluster-instance1-xxxx-0 -- psql -U postgres -c "DROP TABLE users;"
```

### 2. Restaurar desde backup

```bash
# Aplicar manifiestos de restore correspondientes
kubectl apply -f mysql-pxc/restore-cluster.yaml
kubectl apply -f mongodb-psmdb/restore-cluster.yaml
kubectl apply -f postgresql-pg/restore-cluster.yaml
```

### 3. Verificar restauración

```bash
# Verificar que los datos están restaurados
# Conectarse a cada base de datos y verificar contenido
```

## Mejores Prácticas

1. **Frecuencia de Backups**
   - Backups completos: Semanales
   - Backups incrementales: Diarios
   - Logs de transacciones: Continuos

2. **Retención de Backups**
   - Backups diarios: 30 días
   - Backups semanales: 12 semanas
   - Backups mensuales: 12 meses

3. **Monitoreo**
   - Alertas por fallos de backup
   - Verificación de integridad
   - Pruebas de restore regulares

4. **Seguridad**
   - Encriptación en tránsito y reposo
   - Credenciales seguras
   - Acceso restringido a backups

## Troubleshooting

### Backup falla por permisos
```bash
# Verificar RBAC
kubectl get rolebinding -n <namespace>
kubectl describe rolebinding <binding-name>
```

### Backup falla por espacio
```bash
# Verificar espacio en PVCs
kubectl get pvc
kubectl describe pvc <pvc-name>
```

### Restore falla
```bash
# Verificar logs del job de restore
kubectl logs job/<restore-job-name>
kubectl describe job <restore-job-name>
```

## Siguiente Paso
Continuar con `lab-06-monitoring` para configurar monitoreo con PMM.
