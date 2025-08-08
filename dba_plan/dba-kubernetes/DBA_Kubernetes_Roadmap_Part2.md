# Roadmap DBA Kubernetes - Parte 2: Alta Disponibilidad
## Labs Avanzados de Clustering y HA

### Fase 3: PostgreSQL Alta Disponibilidad (6-8 semanas)

#### Semana 9-10: CloudNativePG Operator

##### Lab 3.1: Instalación y Configuración de CNPG
**Objetivo**: Implementar PostgreSQL HA con CloudNativePG

**Prerequisitos**:
- Cluster Kubernetes funcionando
- Cert-manager instalado

**Pasos del Lab**:
```bash
# Instalar cert-manager
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.13.0/cert-manager.yaml

# Instalar CloudNativePG operator
kubectl apply -f https://raw.githubusercontent.com/cloudnative-pg/cloudnative-pg/release-1.21/releases/cnpg-1.21.0.yaml

# Verificar instalación
kubectl get pods -n cnpg-system
```

**Configuración del Cluster**:
```yaml
# postgres-cluster.yaml
apiVersion: postgresql.cnpg.io/v1
kind: Cluster
metadata:
  name: postgres-cluster
spec:
  instances: 3
  
  # Configuración de PostgreSQL
  postgresql:
    parameters:
      max_connections: "200"
      shared_buffers: "256MB"
      effective_cache_size: "1GB"
      maintenance_work_mem: "64MB"
      checkpoint_completion_target: "0.9"
      wal_buffers: "16MB"
      default_statistics_target: "100"
      random_page_cost: "1.1"
      effective_io_concurrency: "200"
  
  # Bootstrap inicial
  bootstrap:
    initdb:
      database: myapp
      owner: myuser
      secret:
        name: postgres-credentials
  
  # Storage configuration
  storage:
    size: 100Gi
    storageClass: gp3-encrypted
  
  # Monitoring
  monitoring:
    enabled: true
    podMonitorEnabled: true
  
  # Anti-affinity para distribución en nodos
  affinity:
    podAntiAffinity:
      requiredDuringSchedulingIgnoredDuringExecution:
      - labelSelector:
          matchLabels:
            cnpg.io/cluster: postgres-cluster
        topologyKey: kubernetes.io/hostname
```

**Tareas**:
- [ ] Instalar CNPG operator
- [ ] Crear cluster PostgreSQL de 3 nodos
- [ ] Verificar replicación streaming
- [ ] Probar failover automático
- [ ] Configurar monitoreo

##### Lab 3.2: Backup y Recovery con CNPG
**Objetivo**: Implementar estrategia de backup completa

**Configuración de Backup**:
```yaml
# postgres-cluster-backup.yaml
apiVersion: postgresql.cnpg.io/v1
kind: Cluster
metadata:
  name: postgres-cluster-backup
spec:
  instances: 3
  
  # Configuración de backup
  backup:
    retentionPolicy: "30d"
    barmanObjectStore:
      destinationPath: "s3://my-postgres-backups/postgres-cluster"
      s3Credentials:
        accessKeyId:
          name: backup-credentials
          key: ACCESS_KEY_ID
        secretAccessKey:
          name: backup-credentials
          key: SECRET_ACCESS_KEY
      wal:
        retention: "7d"
      data:
        retention: "30d"
        jobs: 2
  
  # Configuración de recovery
  externalClusters:
  - name: postgres-backup-source
    barmanObjectStore:
      destinationPath: "s3://my-postgres-backups/postgres-cluster"
      s3Credentials:
        accessKeyId:
          name: backup-credentials
          key: ACCESS_KEY_ID
        secretAccessKey:
          name: backup-credentials
          key: SECRET_ACCESS_KEY
```

**ScheduledBackup**:
```yaml
# scheduled-backup.yaml
apiVersion: postgresql.cnpg.io/v1
kind: ScheduledBackup
metadata:
  name: postgres-backup-schedule
spec:
  schedule: "0 2 * * *"  # Daily at 2 AM
  backupOwnerReference: self
  cluster:
    name: postgres-cluster-backup
```

**Tareas**:
- [ ] Configurar backup automático a S3
- [ ] Crear ScheduledBackup
- [ ] Probar restore desde backup
- [ ] Implementar Point-in-Time Recovery
- [ ] Documentar procedimientos de recovery

#### Semana 11-12: Zalando Postgres Operator

##### Lab 3.3: Comparación con Zalando Operator
**Objetivo**: Evaluar diferentes operadores PostgreSQL

**Instalación**:
```bash
# Instalar Zalando Postgres Operator
kubectl apply -k github.com/zalando/postgres-operator/manifests
```

**Configuración del Cluster**:
```yaml
# postgres-zalando.yaml
apiVersion: "acid.zalan.do/v1"
kind: postgresql
metadata:
  name: postgres-zalando-cluster
spec:
  teamId: "dba-team"
  volume:
    size: 100Gi
    storageClass: gp3-encrypted
  numberOfInstances: 3
  users:
    myuser:
    - superuser
    - createdb
  databases:
    myapp: myuser
  postgresql:
    version: "15"
    parameters:
      shared_buffers: "256MB"
      max_connections: "200"
  resources:
    requests:
      cpu: 500m
      memory: 1Gi
    limits:
      cpu: 1
      memory: 2Gi
```

**Tareas**:
- [ ] Instalar Zalando operator
- [ ] Crear cluster PostgreSQL
- [ ] Comparar features con CNPG
- [ ] Evaluar facilidad de uso
- [ ] Documentar pros y contras

### Fase 4: MySQL Alta Disponibilidad (6-8 semanas)

#### Semana 13-14: MySQL InnoDB Cluster

##### Lab 4.1: MySQL Operator (Oracle)
**Objetivo**: Implementar MySQL HA con operador oficial

**Instalación**:
```bash
# Instalar MySQL Operator
kubectl apply -f https://raw.githubusercontent.com/mysql/mysql-operator/trunk/deploy/deploy-crds.yaml
kubectl apply -f https://raw.githubusercontent.com/mysql/mysql-operator/trunk/deploy/deploy-operator.yaml
```

**Configuración del Cluster**:
```yaml
# mysql-innodb-cluster.yaml
apiVersion: mysql.oracle.com/v2
kind: InnoDBCluster
metadata:
  name: mysql-cluster
spec:
  secretName: mysql-secret
  tlsUseSelfSigned: true
  instances: 3
  
  # Router configuration
  router:
    instances: 2
    
  # Storage configuration
  datadirVolumeClaimTemplate:
    spec:
      accessModes: 
        - ReadWriteOnce
      resources:
        requests:
          storage: 100Gi
      storageClassName: gp3-encrypted
  
  # MySQL configuration
  mycnf: |
    [mysqld]
    max_connections=200
    innodb_buffer_pool_size=1G
    innodb_log_file_size=256M
    innodb_flush_log_at_trx_commit=1
    sync_binlog=1
    
  # Resources
  resources:
    requests:
      cpu: 500m
      memory: 1Gi
    limits:
      cpu: 1
      memory: 2Gi
```

**Secret para credenciales**:
```yaml
# mysql-secret.yaml
apiVersion: v1
kind: Secret
metadata:
  name: mysql-secret
type: Opaque
data:
  rootUser: cm9vdA==  # root
  rootHost: JQ==      # %
  rootPassword: c3VwZXJzZWNyZXQ=  # supersecret
```

**Tareas**:
- [ ] Instalar MySQL Operator
- [ ] Crear InnoDB Cluster de 3 nodos
- [ ] Configurar MySQL Router
- [ ] Probar failover automático
- [ ] Verificar split-brain protection

##### Lab 4.2: Percona XtraDB Cluster
**Objetivo**: Implementar MySQL HA con Percona

**Instalación**:
```bash
# Instalar Percona Operator
kubectl apply -f https://raw.githubusercontent.com/percona/percona-xtradb-cluster-operator/v1.13.0/deploy/bundle.yaml
```

**Configuración del Cluster**:
```yaml
# pxc-cluster.yaml
apiVersion: pxc.percona.com/v1
kind: PerconaXtraDBCluster
metadata:
  name: pxc-cluster
spec:
  crVersion: 1.13.0
  secretsName: pxc-secrets
  
  # PXC nodes configuration
  pxc:
    size: 3
    image: percona/percona-xtradb-cluster:8.0.32-24.2
    
    # Resources
    resources:
      requests:
        memory: 1Gi
        cpu: 500m
      limits:
        memory: 2Gi
        cpu: 1
    
    # Storage
    volumeSpec:
      persistentVolumeClaim:
        storageClassName: gp3-encrypted
        accessModes: ["ReadWriteOnce"]
        resources:
          requests:
            storage: 100Gi
    
    # MySQL configuration
    configuration: |
      [mysqld]
      wsrep_provider_options="gcache.size=1G; gcache.recover=yes"
      wsrep_cluster_address=gcomm://
      binlog_format=ROW
      default_storage_engine=InnoDB
      innodb_autoinc_lock_mode=2
      max_connections=200
      innodb_buffer_pool_size=1G
  
  # ProxySQL configuration
  proxysql:
    enabled: true
    size: 2
    image: percona/percona-xtradb-cluster-operator:1.13.0-proxysql
    
    resources:
      requests:
        memory: 500Mi
        cpu: 200m
      limits:
        memory: 1Gi
        cpu: 500m
  
  # Backup configuration
  backup:
    image: percona/percona-xtradb-cluster-operator:1.13.0-pxc8.0-backup
    storages:
      s3-backup:
        type: s3
        s3:
          bucket: my-mysql-backups
          credentialsSecret: s3-credentials
          region: us-east-1
```

**Tareas**:
- [ ] Instalar Percona Operator
- [ ] Crear PXC cluster de 3 nodos
- [ ] Configurar ProxySQL
- [ ] Implementar backup a S3
- [ ] Probar recovery procedures

#### Semana 15-16: Vitess para Sharding

##### Lab 4.3: Vitess Deployment
**Objetivo**: Implementar sharding horizontal con Vitess

**Instalación con Helm**:
```bash
# Agregar repositorio Vitess
helm repo add vitess https://vitess.io/helm-charts
helm repo update

# Instalar Vitess
helm install vitess vitess/vitess \
  --set topology.cells[0].name=zone1 \
  --set topology.cells[0].keyspaces[0].name=commerce \
  --set topology.cells[0].keyspaces[0].shards[0].name="-" \
  --set topology.cells[0].keyspaces[0].shards[0].tablets[0].type=primary \
  --set topology.cells[0].keyspaces[0].shards[0].tablets[1].type=replica
```

**Configuración de Sharding**:
```yaml
# vitess-sharding.yaml
apiVersion: planetscale.com/v2
kind: VitessCluster
metadata:
  name: commerce-cluster
spec:
  images:
    vtctld: vitess/lite:v17.0.0
    vtgate: vitess/lite:v17.0.0
    vttablet: vitess/lite:v17.0.0
    vtbackup: vitess/lite:v17.0.0
    mysqld: mysql:8.0.30
    mysqldExporter: prom/mysqld-exporter:v0.14.0
  
  cells:
  - name: zone1
    gateway:
      replicas: 2
      resources:
        requests:
          cpu: 100m
          memory: 256Mi
    
  keyspaces:
  - name: commerce
    turndownPolicy: Immediate
    vitessOrchestrator:
      resources:
        limits:
          memory: 128Mi
        requests:
          cpu: 100m
          memory: 128Mi
    
    partitionings:
    - equal:
        parts: 2
        shardTemplate:
          databaseInitScriptSecret:
            name: commerce-db-init-script
            key: init_db.sql
          tabletPools:
          - cell: zone1
            type: replica
            replicas: 2
            vttablet:
              extraFlags:
                db_charset: utf8mb4
              resources:
                limits:
                  memory: 512Mi
                requests:
                  cpu: 100m
                  memory: 256Mi
            mysqld:
              resources:
                limits:
                  memory: 512Mi
                requests:
                  cpu: 100m
                  memory: 256Mi
            dataVolumeClaimTemplate:
              accessModes: ["ReadWriteOnce"]
              resources:
                requests:
                  storage: 10Gi
              storageClassName: gp3-encrypted
```

**Tareas**:
- [ ] Instalar Vitess operator
- [ ] Crear cluster con sharding
- [ ] Configurar VTGate para routing
- [ ] Implementar resharding
- [ ] Probar queries cross-shard

### Fase 5: Backup, Recovery y Disaster Recovery (4-6 semanas)

#### Semana 17-18: Estrategias de Backup Avanzadas

##### Lab 5.1: Velero para Backup de Kubernetes
**Objetivo**: Implementar backup completo del cluster

**Instalación**:
```bash
# Instalar Velero CLI
curl -fsSL -o velero-v1.11.1-linux-amd64.tar.gz https://github.com/vmware-tanzu/velero/releases/download/v1.11.1/velero-v1.11.1-linux-amd64.tar.gz
tar -xvf velero-v1.11.1-linux-amd64.tar.gz
sudo mv velero-v1.11.1-linux-amd64/velero /usr/local/bin/

# Instalar Velero en cluster
velero install \
    --provider aws \
    --plugins velero/velero-plugin-for-aws:v1.7.1 \
    --bucket velero-backups \
    --backup-location-config region=us-east-1 \
    --snapshot-location-config region=us-east-1 \
    --secret-file ./credentials-velero
```

**Configuración de Backup**:
```yaml
# backup-schedule.yaml
apiVersion: velero.io/v1
kind: Schedule
metadata:
  name: database-backup
spec:
  schedule: "0 2 * * *"  # Daily at 2 AM
  template:
    includedNamespaces:
    - database-production
    - database-staging
    storageLocation: default
    volumeSnapshotLocations:
    - default
    ttl: 720h0m0s  # 30 days
```

**Tareas**:
- [ ] Instalar y configurar Velero
- [ ] Crear backup schedules
- [ ] Probar restore completo
- [ ] Implementar cross-region backup
- [ ] Documentar procedures

##### Lab 5.2: Stash para Database Backup
**Objetivo**: Backup específico de bases de datos

**Instalación**:
```bash
# Instalar Stash operator
kubectl apply -f https://github.com/stashed/installer/raw/v2023.05.31/deploy/stash.yaml
```

**Configuración para PostgreSQL**:
```yaml
# postgres-backup-config.yaml
apiVersion: stash.appscode.com/v1beta1
kind: BackupConfiguration
metadata:
  name: postgres-backup-config
spec:
  repository:
    name: postgres-repo
  schedule: "*/30 * * * *"  # Every 30 minutes
  target:
    ref:
      apiVersion: apps/v1
      kind: StatefulSet
      name: postgres-cluster
    volumeMounts:
    - name: data
      mountPath: /var/lib/postgresql/data
  retentionPolicy:
    name: postgres-retention-policy
    keepLast: 10
    prune: true
```

**Tareas**:
- [ ] Configurar Stash para PostgreSQL y MySQL
- [ ] Implementar backup incremental
- [ ] Probar point-in-time recovery
- [ ] Configurar alertas de backup
- [ ] Automatizar testing de backups

### Evaluación Fase 3-5

#### Proyecto Final: "Production-Ready Database Platform"
**Objetivo**: Crear plataforma completa de bases de datos HA

**Requisitos del Proyecto**:

1. **PostgreSQL HA Cluster**:
   - 3 nodos con CNPG
   - Backup automático a S3
   - Monitoreo completo
   - Disaster recovery cross-region

2. **MySQL HA Cluster**:
   - PXC cluster de 3 nodos
   - ProxySQL para load balancing
   - Backup y recovery automatizado
   - Performance monitoring

3. **Vitess Sharded MySQL**:
   - 2 shards iniciales
   - VTGate configurado
   - Resharding procedure documentado
   - Query routing verification

4. **Monitoring Stack**:
   - Prometheus y Grafana
   - Alertmanager configurado
   - Custom dashboards para cada DB
   - SLI/SLO definitions

5. **Backup Strategy**:
   - Velero para cluster backup
   - Database-specific backups
   - Cross-region replication
   - Recovery testing automation

6. **Documentation**:
   - Architecture diagrams
   - Runbooks para operaciones
   - Disaster recovery procedures
   - Performance tuning guides

**Criterios de Evaluación**:
- [ ] Todos los clusters funcionando en HA
- [ ] Failover automático verificado
- [ ] Backups y recovery probados
- [ ] Monitoreo y alertas funcionando
- [ ] Documentación completa
- [ ] Código en GitOps repository
- [ ] Performance benchmarks realizados

**Tiempo Estimado**: 4 semanas

### Recursos y Herramientas

#### Herramientas Esenciales
- **kubectl**: CLI de Kubernetes
- **helm**: Package manager
- **k9s**: Terminal UI
- **kubectx/kubens**: Context switching
- **stern**: Multi-pod logs
- **velero**: Backup tool

#### Repositorios Importantes
- [CloudNativePG](https://github.com/cloudnative-pg/cloudnative-pg)
- [MySQL Operator](https://github.com/mysql/mysql-operator)
- [Percona Operator](https://github.com/percona/percona-xtradb-cluster-operator)
- [Vitess](https://github.com/vitessio/vitess)

#### Documentación Clave
- [Kubernetes Database Patterns](https://kubernetes.io/docs/concepts/workloads/controllers/statefulset/)
- [PostgreSQL on Kubernetes](https://postgres-operator.readthedocs.io/)
- [MySQL InnoDB Cluster](https://dev.mysql.com/doc/mysql-operator/en/)

**Tiempo Total Estimado Fase 3-5**: 16-22 semanas
**Nivel de Dificultad**: Avanzado
**Prerequisitos**: Completar Fase 1-2 exitosamente
