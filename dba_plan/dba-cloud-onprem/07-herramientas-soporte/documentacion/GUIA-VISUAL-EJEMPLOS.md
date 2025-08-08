# 📺 GUÍA VISUAL CON EJEMPLOS - Sistema DBA

## 🎯 Qué Verás en Cada Paso

### 1. Validación del Sistema
```bash
$ ./scripts-utilitarios/validacion-final-simple.sh
```

**Lo que deberías ver:**
```
🔍 VALIDACIÓN FINAL SIMPLIFICADA - COMPONENTES CORE
==================================================

📁 ESTRUCTURA BÁSICA:
✅ Directorio de escenarios
✅ Herramientas de diagnóstico
✅ Queries MySQL
✅ Queries PostgreSQL
✅ Monitor MySQL

🐍 SIMULADORES PYTHON:
✅ MySQL Deadlock Simulator
✅ PostgreSQL Vacuum Simulator
✅ MongoDB Sharding Simulator

📊 RESULTADO FINAL:
Componentes verificados: 16/16
Porcentaje de completitud: 100%
🎉 SISTEMA ALTAMENTE FUNCIONAL (100%)
✅ Listo para uso en entrenamiento
```

---

### 2. Levantar Escenario MySQL
```bash
$ cd escenarios-diagnostico/mysql/escenario-01-deadlocks
$ docker-compose up -d
```

**Lo que deberías ver:**
```
Creating network "escenario-01-deadlocks_db-network" ... done
Creating escenario-01-deadlocks-mysql ... done
Creating escenario-01-deadlocks-simulator ... done
Creating escenario-01-deadlocks-prometheus ... done
Creating escenario-01-deadlocks-grafana ... done
```

**Verificar servicios:**
```bash
$ docker-compose ps
```

**Salida esperada:**
```
Name                                    Command               State           Ports
-----------------------------------------------------------------------------------------
escenario-01-deadlocks-grafana         /run.sh                              Up      0.0.0.0:3000->3000/tcp
escenario-01-deadlocks-mysql           docker-entrypoint.sh mysqld         Up      0.0.0.0:3306->3306/tcp
escenario-01-deadlocks-prometheus      /bin/prometheus --config.f...       Up      0.0.0.0:9090->9090/tcp
escenario-01-deadlocks-simulator       python3 main_simulator.py           Up
```

---

### 3. Ejecutar Simulador
```bash
$ docker-compose exec simulator python3 main_simulator.py
```

**Lo que deberías ver:**
```
🔥 MySQL Deadlock Simulator Started
=====================================
[2025-08-08 13:30:15] Connecting to MySQL...
[2025-08-08 13:30:15] ✅ Connected successfully
[2025-08-08 13:30:15] 🎯 Starting deadlock simulation...
[2025-08-08 13:30:16] 💥 Deadlock detected! Transaction rolled back
[2025-08-08 13:30:17] 📊 Deadlock count: 1
[2025-08-08 13:30:18] 💥 Deadlock detected! Transaction rolled back
[2025-08-08 13:30:19] 📊 Deadlock count: 2
```

---

### 4. Conectar a MySQL
```bash
$ docker-compose exec mysql-db mysql -u root -pdba2024! training_db
```

**Lo que deberías ver:**
```
Welcome to the MySQL monitor.  Commands end with ; or \g.
Your MySQL connection id is 42
Server version: 8.0.33 MySQL Community Server - GPL

Copyright (c) 2000, 2023, Oracle and/or its affiliates.

Oracle is a registered trademark of Oracle Corporation and/or its
affiliates. Other names may be trademarks of their respective
owners.

Type 'help;' or '\h' for help. Type '\c' to clear the current input statement.

mysql> 
```

**Ver deadlocks:**
```sql
mysql> SHOW ENGINE INNODB STATUS\G
```

**Salida esperada (fragmento):**
```
------------------------
LATEST DETECTED DEADLOCK
------------------------
2025-08-08 13:30:16 0x7f8b2c001700
*** (1) TRANSACTION:
TRANSACTION 421394, ACTIVE 0 sec starting index read
mysql tables in use 1, locked 1
LOCK WAIT 3 lock struct(s), heap size 1136, 2 row lock(s)
MySQL thread id 15, OS thread id 140239891216128, query id 1234 localhost root updating
UPDATE products SET stock = stock - 1 WHERE id = 1

*** (2) TRANSACTION:
TRANSACTION 421395, ACTIVE 0 sec starting index read
mysql tables in use 1, locked 1
3 lock struct(s), heap size 1136, 2 row lock(s)
MySQL thread id 16, OS thread id 140239890952960, query id 1235 localhost root updating
UPDATE products SET stock = stock - 1 WHERE id = 2

*** WE ROLL BACK TRANSACTION (1)
```

---

### 5. Acceder a Grafana
**URL:** http://localhost:3000

**Pantalla de login:**
```
┌─────────────────────────────────────┐
│             Grafana                 │
│                                     │
│  Username: [admin              ]    │
│  Password: [admin              ]    │
│                                     │
│           [Log in]                  │
└─────────────────────────────────────┘
```

**Dashboard MySQL Deadlocks:**
```
MySQL Deadlock Monitoring Dashboard
====================================

📊 Deadlock Rate (last 5min)    📈 Active Connections
    ▲ 2.3 deadlocks/min             ▲ 15 connections

📊 Transaction Rollbacks         📈 Query Response Time  
    ▲ 12 rollbacks/min               ▲ 45ms avg

🔥 Recent Deadlocks:
[13:30:16] Deadlock between transactions 421394 and 421395
[13:30:18] Deadlock between transactions 421396 and 421397
[13:30:20] Deadlock between transactions 421398 and 421399
```

---

### 6. Usar Herramientas de Diagnóstico
```bash
$ cd ../../../herramientas-diagnostico/scripts-monitoring/mysql/
$ ./deadlock_monitor.sh
```

**Lo que deberías ver:**
```
🔍 MySQL Deadlock Monitor - Real Time
=====================================
Monitoring MySQL deadlocks every 5 seconds...
Press Ctrl+C to stop

[13:30:25] 🔥 DEADLOCK DETECTED!
  - Transaction ID: 421400
  - Affected Tables: products
  - Rollback Count: 15
  - Recommendation: Review transaction order

[13:30:30] 🔥 DEADLOCK DETECTED!
  - Transaction ID: 421402  
  - Affected Tables: products, orders
  - Rollback Count: 16
  - Recommendation: Implement retry logic

[13:30:35] ✅ No deadlocks in last 5 seconds
```

---

### 7. Queries de Diagnóstico
```bash
$ cat ../queries-diagnostico/mysql-diagnostics.sql
```

**Contenido del archivo:**
```sql
-- MySQL Diagnostic Queries for Deadlock Analysis

-- 1. Current deadlock information
SHOW ENGINE INNODB STATUS;

-- 2. Recent deadlock count
SHOW GLOBAL STATUS LIKE 'Innodb_deadlocks';

-- 3. Lock waits
SELECT * FROM performance_schema.data_lock_waits;

-- 4. Current transactions
SELECT * FROM information_schema.innodb_trx;

-- 5. Lock information
SELECT * FROM performance_schema.data_locks;
```

**Ejecutar query específica:**
```bash
$ docker-compose exec mysql-db mysql -u root -pdba2024! -e "SHOW GLOBAL STATUS LIKE 'Innodb_deadlocks';"
```

**Salida esperada:**
```
+------------------+-------+
| Variable_name    | Value |
+------------------+-------+
| Innodb_deadlocks | 23    |
+------------------+-------+
```

---

### 8. Evaluación Automática
```bash
$ cd ../../../
$ python3 evaluador_mejorado.py mysql/escenario-01-deadlocks
```

**Lo que deberías ver:**
```
🎓 Enhanced Automatic Evaluator for DBA Scenarios
=================================================

Evaluating: mysql/escenario-01-deadlocks
Scenario type: mysql

✅ MySQL Deadlock Resolution Test
  Score: 45/50
  Details: Deadlocks: 23, Detection: ON
  
📊 Evaluation Results:
{
  "scenario_path": "mysql/escenario-01-deadlocks",
  "scenario_type": "mysql", 
  "timestamp": "2025-08-08T13:35:00",
  "total_score": 45,
  "max_score": 50,
  "percentage": 90.0,
  "results": [
    {
      "test": "MySQL Deadlock Resolution",
      "score": 45,
      "max_score": 50,
      "details": "Deadlocks: 23, Detection: ON"
    }
  ]
}
```

---

### 9. Limpiar Entorno
```bash
$ docker-compose down
```

**Lo que deberías ver:**
```
Stopping escenario-01-deadlocks-grafana     ... done
Stopping escenario-01-deadlocks-prometheus  ... done
Stopping escenario-01-deadlocks-simulator   ... done
Stopping escenario-01-deadlocks-mysql       ... done
Removing escenario-01-deadlocks-grafana     ... done
Removing escenario-01-deadlocks-prometheus  ... done
Removing escenario-01-deadlocks-simulator   ... done
Removing escenario-01-deadlocks-mysql       ... done
Removing network escenario-01-deadlocks_db-network
```

---

## 🎯 Escenarios Adicionales - Vista Previa

### PostgreSQL Vacuum
```bash
$ cd postgresql/escenario-01-vacuum
$ docker-compose up -d
$ docker-compose exec simulator python3 vacuum_simulator.py
```

**Salida del simulador:**
```
🧹 PostgreSQL Vacuum Simulator Started
======================================
[13:40:15] Creating table bloat...
[13:40:16] 💾 Dead tuples: 1,250 | Live tuples: 8,750
[13:40:17] 💾 Dead tuples: 2,500 | Live tuples: 7,500  
[13:40:18] ⚠️  Dead tuple ratio: 25% - Vacuum needed!
```

### MongoDB Sharding
```bash
$ cd mongodb/escenario-01-sharding  
$ docker-compose up -d
$ docker-compose exec mongodb mongo -u admin -p dba2024!
```

**En MongoDB shell:**
```javascript
> sh.status()

--- Sharding Status ---
  sharding version: {
    "_id" : 1,
    "minCompatibleVersion" : 5,
    "currentVersion" : 6,
    "clusterId" : ObjectId("64d2a1b2c3d4e5f6a7b8c9d0")
  }
  
  shards:
    {  "_id" : "shard0000",  "host" : "shard0000/mongodb-shard1:27018" }
    {  "_id" : "shard0001",  "host" : "shard0001/mongodb-shard2:27019" }
    
  active mongoses:
    "4.4.15" : 1
    
  databases:
    {  "_id" : "training_db",  "primary" : "shard0000",  "partitioned" : true }
```

---

## 🔧 Solución de Problemas Visuales

### Error: Puerto Ocupado
```bash
$ docker-compose up -d
```

**Error que podrías ver:**
```
ERROR: for mysql-db  Cannot start service mysql-db: 
driver failed programming external connectivity on endpoint: 
bind for 0.0.0.0:3306 failed: port is already allocated
```

**Solución:**
```bash
# Ver qué usa el puerto
$ netstat -tulpn | grep :3306
tcp6  0  0  :::3306  :::*  LISTEN  1234/mysqld

# Detener el servicio conflictivo o cambiar puerto en docker-compose.yml
```

### Error: Simulador no Responde
```bash
$ docker-compose logs simulator
```

**Error que podrías ver:**
```
simulator_1  | Traceback (most recent call last):
simulator_1  |   File "main_simulator.py", line 15, in <module>
simulator_1  |     import mysql.connector
simulator_1  | ModuleNotFoundError: No module named 'mysql.connector'
```

**Solución:**
```bash
# Reconstruir imagen
$ docker-compose build --no-cache simulator
$ docker-compose up -d
```

---

## 📱 Accesos Rápidos

### URLs Importantes
- **Grafana:** http://localhost:3000 (admin/admin)
- **Prometheus:** http://localhost:9090
- **MySQL:** localhost:3306 (root/dba2024!)
- **PostgreSQL:** localhost:5432 (app_user/app_pass)
- **MongoDB:** localhost:27017 (admin/dba2024!)

### Comandos Esenciales
```bash
# Estado de servicios
docker-compose ps

# Logs en tiempo real
docker-compose logs -f [servicio]

# Conectar a base de datos
docker-compose exec [servicio] [comando]

# Limpiar todo
docker-compose down -v
```

---

**¡Con esta guía visual ya sabes exactamente qué esperar en cada paso!** 👀✨

*Para más detalles, consulta el tutorial completo en `TUTORIAL-COMPLETO-USO.md`*
