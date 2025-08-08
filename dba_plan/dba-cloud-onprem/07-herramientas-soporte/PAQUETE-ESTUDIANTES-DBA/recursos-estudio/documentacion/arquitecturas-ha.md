# 🏗️ Arquitecturas de Alta Disponibilidad
## Guía de Diseño para DBAs

### 🎯 **PRINCIPIOS FUNDAMENTALES**

#### **RTO vs RPO:**
- **RTO (Recovery Time Objective):** Tiempo máximo de downtime aceptable
- **RPO (Recovery Point Objective):** Cantidad máxima de datos que se pueden perder

#### **Niveles de Disponibilidad:**
- **99.9%:** 8.77 horas downtime/año
- **99.95%:** 4.38 horas downtime/año
- **99.99%:** 52.6 minutos downtime/año
- **99.999%:** 5.26 minutos downtime/año

### 🐬 **MYSQL HA PATTERNS**

#### **Master-Slave Replication:**
```sql
-- En Master
SHOW MASTER STATUS;

-- En Slave
CHANGE MASTER TO
  MASTER_HOST='master-ip',
  MASTER_USER='repl_user',
  MASTER_PASSWORD='password',
  MASTER_LOG_FILE='mysql-bin.000001',
  MASTER_LOG_POS=154;

START SLAVE;
```

#### **MySQL Cluster (NDB):**
- **Ventajas:** Shared-nothing, auto-failover
- **Desventajas:** Limitaciones de storage engine
- **Uso:** Aplicaciones que requieren 99.999% uptime

### 🐘 **POSTGRESQL HA PATTERNS**

#### **Streaming Replication:**
```bash
# En Master (postgresql.conf)
wal_level = replica
max_wal_senders = 3
wal_keep_segments = 64

# En Standby
standby_mode = 'on'
primary_conninfo = 'host=master port=5432 user=replicator'
```

#### **Patroni + etcd:**
- **Ventajas:** Automatic failover, split-brain protection
- **Componentes:** Patroni, etcd/consul, HAProxy
- **Uso:** Entornos cloud-native

### 🍃 **MONGODB HA PATTERNS**

#### **Replica Set:**
```javascript
// Inicializar replica set
rs.initiate({
  _id: "myReplicaSet",
  members: [
    {_id: 0, host: "mongo1:27017"},
    {_id: 1, host: "mongo2:27017"},
    {_id: 2, host: "mongo3:27017"}
  ]
})
```

#### **Sharded Cluster:**
- **Config Servers:** Metadatos del cluster
- **Shard Servers:** Datos distribuidos
- **Mongos Routers:** Query routing
