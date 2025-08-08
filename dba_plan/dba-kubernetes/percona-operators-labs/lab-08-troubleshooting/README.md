# Lab 08: Troubleshooting y Resolución de Problemas

## Objetivo
Aprender a diagnosticar y resolver problemas comunes con los operadores de Percona.

## Duración Estimada
60 minutos

## Problemas Comunes y Soluciones

### 1. Problemas de Inicialización

#### MySQL PXC - Cluster no forma
```bash
# Síntomas
kubectl get pxc pxc-cluster
# STATUS: initializing (por mucho tiempo)

# Diagnóstico
kubectl describe pxc pxc-cluster
kubectl logs pxc-cluster-pxc-0 -c pxc

# Posibles causas y soluciones
# 1. Recursos insuficientes
kubectl describe node
kubectl top node

# 2. Problemas de red
kubectl exec pxc-cluster-pxc-0 -- nc -zv pxc-cluster-pxc-1.pxc-cluster-pxc 3306

# 3. Secretos incorrectos
kubectl get secret pxc-cluster-secrets -o yaml
```

#### MongoDB PSMDB - Replica Set no se forma
```bash
# Síntomas
kubectl get psmdb psmdb-cluster
# STATUS: initializing

# Diagnóstico
kubectl logs psmdb-cluster-rs0-0 -c mongod

# Soluciones
# 1. Verificar DNS
kubectl exec psmdb-cluster-rs0-0 -- nslookup psmdb-cluster-rs0-1.psmdb-cluster-rs0

# 2. Reiniciar pods en orden
kubectl delete pod psmdb-cluster-rs0-0
# Esperar que inicie, luego continuar con el siguiente
```

#### PostgreSQL - Patroni no inicia
```bash
# Síntomas
kubectl get pods -l postgres-operator.crunchydata.com/cluster=pg-cluster
# Pods en CrashLoopBackOff

# Diagnóstico
kubectl logs pg-cluster-instance1-xxxx-0 -c database

# Soluciones
# 1. Verificar permisos de PVC
kubectl exec pg-cluster-instance1-xxxx-0 -- ls -la /pgdata

# 2. Verificar configuración de Patroni
kubectl exec pg-cluster-instance1-xxxx-0 -- cat /etc/patroni/patroni.yaml
```

### 2. Problemas de Performance

#### Consultas Lentas en MySQL
```bash
# Habilitar slow query log
kubectl exec pxc-cluster-pxc-0 -- mysql -uroot -p<password> -e "SET GLOBAL slow_query_log = 'ON';"

# Ver consultas lentas
kubectl exec pxc-cluster-pxc-0 -- mysql -uroot -p<password> -e "SELECT * FROM mysql.slow_log LIMIT 10;"

# Analizar con PMM
# Acceder a PMM UI -> Query Analytics
```

#### MongoDB Performance Issues
```bash
# Habilitar profiling
kubectl exec psmdb-cluster-rs0-0 -- mongosh --eval "db.setProfilingLevel(2, {slowms: 100})"

# Ver operaciones lentas
kubectl exec psmdb-cluster-rs0-0 -- mongosh --eval "db.system.profile.find().limit(5).sort({ts:-1}).pretty()"

# Verificar índices
kubectl exec psmdb-cluster-rs0-0 -- mongosh --eval "db.users.getIndexes()"
```

#### PostgreSQL Performance
```bash
# Habilitar pg_stat_statements
kubectl exec pg-cluster-instance1-xxxx-0 -- psql -U postgres -c "CREATE EXTENSION IF NOT EXISTS pg_stat_statements;"

# Ver consultas más costosas
kubectl exec pg-cluster-instance1-xxxx-0 -- psql -U postgres -c "SELECT query, calls, total_time, mean_time FROM pg_stat_statements ORDER BY total_time DESC LIMIT 10;"
```

### 3. Problemas de Almacenamiento

#### PVC lleno
```bash
# Verificar uso de espacio
kubectl exec pxc-cluster-pxc-0 -- df -h

# Expandir PVC (si el StorageClass lo permite)
kubectl patch pvc datadir-pxc-cluster-pxc-0 -p '{"spec":{"resources":{"requests":{"storage":"10Gi"}}}}'

# Limpiar logs antiguos
kubectl exec pxc-cluster-pxc-0 -- mysql -uroot -p<password> -e "PURGE BINARY LOGS BEFORE DATE(NOW() - INTERVAL 7 DAY);"
```

#### PVC corrupto
```bash
# Síntomas: Pod no puede montar volumen
kubectl describe pod pxc-cluster-pxc-0

# Solución: Restaurar desde backup
kubectl apply -f ../lab-05-backup-restore/mysql-pxc/restore-cluster.yaml
```

### 4. Problemas de Red

#### Pods no pueden comunicarse
```bash
# Verificar NetworkPolicy
kubectl get networkpolicy

# Probar conectividad
kubectl exec pxc-cluster-pxc-0 -- nc -zv pxc-cluster-pxc-1.pxc-cluster-pxc 3306

# Verificar DNS
kubectl exec pxc-cluster-pxc-0 -- nslookup pxc-cluster-pxc-1.pxc-cluster-pxc
```

#### LoadBalancer no funciona
```bash
# Verificar servicio
kubectl get svc pxc-cluster-haproxy
kubectl describe svc pxc-cluster-haproxy

# Verificar endpoints
kubectl get endpoints pxc-cluster-haproxy
```

### 5. Problemas de Backup

#### Backup falla
```bash
# Ver logs del job de backup
kubectl get jobs
kubectl logs job/backup-pxc-cluster-xxxx

# Verificar credenciales S3
kubectl get secret my-cluster-s3-credentials -o yaml

# Probar conectividad a S3
kubectl run test-s3 --image=amazon/aws-cli --rm -it -- s3 ls s3://my-backup-bucket
```

#### Restore falla
```bash
# Ver logs del restore
kubectl logs job/restore-pxc-cluster-xxxx

# Verificar que el backup existe
kubectl exec -it <backup-pod> -- ls -la /backup/

# Verificar permisos
kubectl describe pvc datadir-pxc-cluster-pxc-0
```

### 6. Problemas del Operador

#### Operador no responde
```bash
# Verificar estado del operador
kubectl get pods -n percona-operators
kubectl logs -n percona-operators deployment/percona-xtradb-cluster-operator

# Reiniciar operador
kubectl rollout restart deployment/percona-xtradb-cluster-operator -n percona-operators
```

#### CRD desactualizado
```bash
# Verificar versión de CRD
kubectl get crd perconaxtradbclusters.pxc.percona.com -o yaml | grep version

# Actualizar CRD
kubectl apply -f https://raw.githubusercontent.com/percona/percona-xtradb-cluster-operator/v1.14.0/deploy/crd.yaml
```

## Herramientas de Diagnóstico

### 1. Script de diagnóstico general
```bash
#!/bin/bash
# diagnose.sh

echo "=== Cluster Status ==="
kubectl get nodes
kubectl get pods --all-namespaces | grep -E "(Error|CrashLoop|Pending)"

echo "=== Percona Operators ==="
kubectl get pods -n percona-operators
kubectl get pxc,psmdb,postgrescluster

echo "=== Storage ==="
kubectl get pvc
kubectl get pv

echo "=== Events ==="
kubectl get events --sort-by='.lastTimestamp' | tail -20
```

### 2. Logs centralizados
```bash
# Ver logs de todos los pods de un cluster
kubectl logs -l app.kubernetes.io/name=percona-xtradb-cluster --tail=100

# Seguir logs en tiempo real
kubectl logs -f pxc-cluster-pxc-0 -c pxc
```

### 3. Métricas de recursos
```bash
# Uso de recursos por pod
kubectl top pods

# Uso de recursos por nodo
kubectl top nodes

# Detalles de recursos
kubectl describe node <node-name>
```

## Procedimientos de Emergencia

### 1. Cluster MySQL completamente caído
```bash
# 1. Identificar el nodo con datos más recientes
kubectl exec pxc-cluster-pxc-0 -- cat /var/lib/mysql/grastate.dat
kubectl exec pxc-cluster-pxc-1 -- cat /var/lib/mysql/grastate.dat
kubectl exec pxc-cluster-pxc-2 -- cat /var/lib/mysql/grastate.dat

# 2. Bootstrap desde el nodo con seqno más alto
kubectl patch pxc pxc-cluster --type='merge' -p='{"spec":{"pxc":{"autoRecovery":false}}}'
kubectl annotate pxc pxc-cluster pxc.percona.com/unsafe-bootstrap=pxc-cluster-pxc-0

# 3. Esperar que el cluster se recupere
kubectl get pxc pxc-cluster -w
```

### 2. Split-brain en MongoDB
```bash
# 1. Identificar el primary
kubectl exec psmdb-cluster-rs0-0 -- mongosh --eval "rs.status()"

# 2. Reconfigurar replica set si es necesario
kubectl exec psmdb-cluster-rs0-0 -- mongosh --eval "rs.reconfig({...}, {force: true})"
```

### 3. PostgreSQL Patroni split-brain
```bash
# 1. Verificar estado de Patroni
kubectl exec pg-cluster-instance1-xxxx-0 -- patronictl list

# 2. Reinicializar réplica si es necesario
kubectl exec pg-cluster-instance1-xxxx-1 -- patronictl reinit pg-cluster instance1-xxxx-1
```

## Monitoreo Proactivo

### 1. Alertas críticas
- Cluster down
- Replicación rota
- Espacio en disco < 10%
- CPU > 80% por 5 minutos
- Memoria > 90%

### 2. Checks de salud automatizados
```bash
# Script de health check
#!/bin/bash
# health-check.sh

# MySQL
kubectl exec pxc-cluster-pxc-0 -- mysql -uroot -p<password> -e "SELECT 1" > /dev/null 2>&1
if [ $? -eq 0 ]; then echo "MySQL: OK"; else echo "MySQL: FAIL"; fi

# MongoDB
kubectl exec psmdb-cluster-rs0-0 -- mongosh --eval "db.runCommand('ping')" > /dev/null 2>&1
if [ $? -eq 0 ]; then echo "MongoDB: OK"; else echo "MongoDB: FAIL"; fi

# PostgreSQL
kubectl exec pg-cluster-instance1-xxxx-0 -- psql -U postgres -c "SELECT 1" > /dev/null 2>&1
if [ $? -eq 0 ]; then echo "PostgreSQL: OK"; else echo "PostgreSQL: FAIL"; fi
```

## Verificación Final

Al completar este laboratorio deberías poder:
- ✅ Diagnosticar problemas comunes de inicialización
- ✅ Resolver problemas de performance
- ✅ Manejar problemas de almacenamiento
- ✅ Solucionar problemas de red
- ✅ Recuperar clusters en situaciones de emergencia
- ✅ Implementar monitoreo proactivo

¡Felicitaciones! Has completado todos los laboratorios de operadores Percona.
