# 🔥 Roadmap DBA Semi-Senior - Cloud OnPrem AWS

## 🎯 Perfil del DBA Semi-Senior

**Experiencia:** 2-5 años  
**Objetivo:** Arquitectura, optimización y liderazgo técnico  
**Timeline:** 24-36 meses para avanzar a Senior  

---

## 🏗️ Fase 1: Arquitectura Avanzada (Meses 1-6)

### 🗄️ Bases de Datos Avanzadas

#### MySQL/MariaDB Avanzado
**Meses 1-2:**
- [ ] **Replicación Master-Slave**
  ```sql
  -- Configurar Master
  [mysqld]
  server-id = 1
  log-bin = mysql-bin
  binlog-format = ROW
  
  -- Crear usuario de replicación
  CREATE USER 'repl'@'%' IDENTIFIED BY 'password';
  GRANT REPLICATION SLAVE ON *.* TO 'repl'@'%';
  ```

- [ ] **InnoDB Engine Optimization**
  ```sql
  -- Configuraciones críticas
  innodb_buffer_pool_size = 70% of RAM
  innodb_log_file_size = 256M
  innodb_flush_log_at_trx_commit = 2
  innodb_file_per_table = ON
  ```

- [ ] **Query Optimization Avanzada**
  ```sql
  -- Análisis de queries
  EXPLAIN FORMAT=JSON SELECT ...;
  
  -- Performance Schema
  SELECT * FROM performance_schema.events_statements_summary_by_digest
  ORDER BY sum_timer_wait DESC LIMIT 10;
  ```

#### PostgreSQL Avanzado
**Meses 3-4:**
- [ ] **Streaming Replication**
  ```bash
  # postgresql.conf (Master)
  wal_level = replica
  max_wal_senders = 3
  wal_keep_segments = 64
  
  # recovery.conf (Slave)
  standby_mode = 'on'
  primary_conninfo = 'host=master port=5432 user=replicator'
  ```

- [ ] **Query Planner Optimization**
  ```sql
  -- Análisis detallado
  EXPLAIN (ANALYZE, BUFFERS, FORMAT JSON) 
  SELECT ...;
  
  -- Estadísticas
  ANALYZE table_name;
  SELECT * FROM pg_stat_user_tables;
  ```

- [ ] **Partitioning Strategies**
  ```sql
  -- Range Partitioning
  CREATE TABLE sales (
      id SERIAL,
      sale_date DATE,
      amount DECIMAL
  ) PARTITION BY RANGE (sale_date);
  
  CREATE TABLE sales_2024 PARTITION OF sales
  FOR VALUES FROM ('2024-01-01') TO ('2025-01-01');
  ```

### ☁️ AWS Servicios Avanzados

#### Aurora Deep Dive
**Mes 5:**
- [ ] **Aurora MySQL/PostgreSQL**
  ```bash
  # Crear cluster Aurora
  aws rds create-db-cluster \
      --db-cluster-identifier aurora-cluster \
      --engine aurora-mysql \
      --engine-version 8.0.mysql_aurora.3.02.0 \
      --master-username admin \
      --master-user-password password \
      --database-name production
  ```

- [ ] **Aurora Serverless**
  - Auto-scaling configuration
  - Data API usage
  - Cost optimization

- [ ] **Global Database**
  - Cross-region replication
  - Disaster recovery
  - Read replica management

#### ElastiCache Integration
**Mes 6:**
- [ ] **Redis Cluster Mode**
  ```python
  import redis
  
  # Conexión a cluster Redis
  redis_client = redis.RedisCluster(
      host='my-cluster.cache.amazonaws.com',
      port=6379,
      decode_responses=True
  )
  
  # Caching strategy
  def get_user_data(user_id):
      cache_key = f"user:{user_id}"
      cached_data = redis_client.get(cache_key)
      
      if cached_data:
          return json.loads(cached_data)
      
      # Fetch from database
      data = fetch_from_db(user_id)
      redis_client.setex(cache_key, 3600, json.dumps(data))
      return data
  ```

---

## 🔄 Fase 2: Migración y Sincronización (Meses 7-12)

### 🚀 Database Migration Service (DMS)

#### Configuración Avanzada DMS
**Meses 7-8:**
- [ ] **Replication Instances**
  ```json
  {
    "ReplicationInstanceClass": "dms.t3.medium",
    "AllocatedStorage": 100,
    "VpcSecurityGroupIds": ["sg-12345678"],
    "MultiAZ": true,
    "PubliclyAccessible": false
  }
  ```

- [ ] **Source/Target Endpoints**
  ```bash
  # Crear endpoint source (OnPrem MySQL)
  aws dms create-endpoint \
      --endpoint-identifier mysql-source \
      --endpoint-type source \
      --engine-name mysql \
      --server-name onprem-mysql.company.com \
      --port 3306 \
      --username dms_user \
      --password password
  ```

- [ ] **Task Configuration**
  ```json
  {
    "rules": [
      {
        "rule-type": "selection",
        "rule-id": "1",
        "rule-name": "1",
        "object-locator": {
          "schema-name": "production",
          "table-name": "%"
        },
        "rule-action": "include"
      },
      {
        "rule-type": "transformation",
        "rule-id": "2",
        "rule-name": "2",
        "rule-action": "rename",
        "rule-target": "table",
        "object-locator": {
          "schema-name": "production",
          "table-name": "old_table"
        },
        "value": "new_table"
      }
    ]
  }
  ```

#### Migración Zero-Downtime
**Meses 9-10:**
- [ ] **Full Load + CDC**
  - Initial data migration
  - Change data capture
  - Cutover strategies

- [ ] **Data Validation**
  ```python
  # Script de validación
  def validate_migration():
      source_count = get_table_count(source_db, 'users')
      target_count = get_table_count(target_db, 'users')
      
      if source_count != target_count:
          raise Exception(f"Count mismatch: {source_count} vs {target_count}")
      
      # Checksum validation
      source_checksum = calculate_checksum(source_db, 'users')
      target_checksum = calculate_checksum(target_db, 'users')
      
      assert source_checksum == target_checksum
  ```

### 🔄 Arquitectura Híbrida

#### VPN y Direct Connect
**Meses 11-12:**
- [ ] **Site-to-Site VPN**
  ```bash
  # Crear Customer Gateway
  aws ec2 create-customer-gateway \
      --type ipsec.1 \
      --public-ip 203.0.113.12 \
      --bgp-asn 65000
  
  # Crear VPN Connection
  aws ec2 create-vpn-connection \
      --type ipsec.1 \
      --customer-gateway-id cgw-12345678 \
      --vpn-gateway-id vgw-12345678
  ```

- [ ] **Direct Connect Gateway**
  - Virtual interfaces
  - BGP routing
  - Redundancy planning

#### Infrastructure as Code Avanzado
**Meses 11-12 (continuación):**
- [ ] **Terraform Modules para DBAs**
  ```hcl
  # modules/rds-aurora/main.tf
  resource "aws_rds_cluster" "aurora" {
    cluster_identifier = var.cluster_identifier
    engine            = var.engine
    engine_version    = var.engine_version
    
    database_name   = var.database_name
    master_username = var.master_username
    master_password = var.master_password
    
    vpc_security_group_ids = var.security_group_ids
    db_subnet_group_name   = aws_db_subnet_group.aurora.name
    
    backup_retention_period = var.backup_retention_period
    preferred_backup_window = var.backup_window
    
    skip_final_snapshot = var.skip_final_snapshot
    
    tags = var.tags
  }
  
  resource "aws_rds_cluster_instance" "aurora_instances" {
    count              = var.instance_count
    identifier         = "${var.cluster_identifier}-${count.index}"
    cluster_identifier = aws_rds_cluster.aurora.id
    instance_class     = var.instance_class
    engine             = aws_rds_cluster.aurora.engine
    engine_version     = aws_rds_cluster.aurora.engine_version
    
    performance_insights_enabled = var.performance_insights_enabled
    monitoring_interval          = var.monitoring_interval
    
    tags = var.tags
  }
  ```

- [ ] **Terraform State Management**
  ```hcl
  # Remote state backend
  terraform {
    backend "s3" {
      bucket         = "company-terraform-state"
      key            = "database/prod/terraform.tfstate"
      region         = "us-east-1"
      encrypt        = true
      dynamodb_table = "terraform-state-locks"
    }
  }
  
  # Data sources para compartir información
  data "terraform_remote_state" "vpc" {
    backend = "s3"
    config = {
      bucket = "company-terraform-state"
      key    = "vpc/prod/terraform.tfstate"
      region = "us-east-1"
    }
  }
  ```

- [ ] **Multi-Environment Management**
  ```hcl
  # environments/prod/main.tf
  module "production_aurora" {
    source = "../../modules/rds-aurora"
    
    cluster_identifier = "prod-aurora-cluster"
    engine            = "aurora-mysql"
    engine_version    = "8.0.mysql_aurora.3.02.0"
    
    instance_class = "db.r6g.xlarge"
    instance_count = 3
    
    database_name   = "production"
    master_username = "admin"
    master_password = var.db_password
    
    vpc_id     = data.terraform_remote_state.vpc.outputs.vpc_id
    subnet_ids = data.terraform_remote_state.vpc.outputs.database_subnet_ids
    
    backup_retention_period = 30
    backup_window          = "03:00-04:00"
    
    performance_insights_enabled = true
    monitoring_interval          = 60
    
    tags = {
      Environment = "production"
      Team        = "database"
      Project     = "main-app"
    }
  }
  ```

---

## 📊 Fase 3: Monitoreo y Observabilidad (Meses 13-18)

### 🐍 Python Avanzado para DBAs

#### Automatización y Orquestación
**Meses 13-14:**
- [ ] **Framework de Automatización Personalizado**
  ```python
  # dba_framework.py - Framework avanzado para DBAs
  import asyncio
  import aiohttp
  import aiomysql
  import asyncpg
  from dataclasses import dataclass
  from typing import List, Dict, Any
  import logging
  from datetime import datetime, timedelta
  
  @dataclass
  class DatabaseConfig:
      name: str
      type: str  # mysql, postgresql, mongodb
      host: str
      port: int
      username: str
      password: str
      database: str
      
  class DatabaseMonitor:
      def __init__(self, configs: List[DatabaseConfig]):
          self.configs = configs
          self.logger = self._setup_logging()
      
      def _setup_logging(self):
          logging.basicConfig(
              level=logging.INFO,
              format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
              handlers=[
                  logging.FileHandler('dba_monitor.log'),
                  logging.StreamHandler()
              ]
          )
          return logging.getLogger(__name__)
      
      async def check_mysql_health(self, config: DatabaseConfig):
          """Verificación asíncrona de salud MySQL"""
          try:
              pool = await aiomysql.create_pool(
                  host=config.host,
                  port=config.port,
                  user=config.username,
                  password=config.password,
                  db=config.database,
                  minsize=1,
                  maxsize=5
              )
              
              async with pool.acquire() as conn:
                  async with conn.cursor() as cursor:
                      # Verificar conexiones activas
                      await cursor.execute("SHOW GLOBAL STATUS LIKE 'Threads_connected'")
                      connections = await cursor.fetchone()
                      
                      # Verificar replication lag
                      await cursor.execute("SHOW SLAVE STATUS")
                      slave_status = await cursor.fetchone()
                      
                      # Verificar espacio en disco
                      await cursor.execute("""
                          SELECT 
                              table_schema,
                              ROUND(SUM(data_length + index_length) / 1024 / 1024, 2) AS 'DB Size in MB'
                          FROM information_schema.tables 
                          GROUP BY table_schema
                      """)
                      db_sizes = await cursor.fetchall()
                      
                      pool.close()
                      await pool.wait_closed()
                      
                      return {
                          'status': 'healthy',
                          'connections': connections[1] if connections else 0,
                          'replication_lag': slave_status[32] if slave_status else None,
                          'database_sizes': dict(db_sizes) if db_sizes else {}
                      }
                      
          except Exception as e:
              self.logger.error(f"MySQL health check failed for {config.name}: {e}")
              return {'status': 'error', 'error': str(e)}
      
      async def check_postgresql_health(self, config: DatabaseConfig):
          """Verificación asíncrona de salud PostgreSQL"""
          try:
              conn = await asyncpg.connect(
                  host=config.host,
                  port=config.port,
                  user=config.username,
                  password=config.password,
                  database=config.database
              )
              
              # Verificar conexiones activas
              active_connections = await conn.fetchval(
                  "SELECT count(*) FROM pg_stat_activity WHERE state = 'active'"
              )
              
              # Verificar dead tuples
              dead_tuples = await conn.fetch("""
                  SELECT schemaname, tablename, n_dead_tup, n_live_tup,
                         ROUND(n_dead_tup::numeric / NULLIF(n_live_tup + n_dead_tup, 0) * 100, 2) as dead_tuple_percent
                  FROM pg_stat_user_tables 
                  WHERE n_dead_tup > 0
                  ORDER BY dead_tuple_percent DESC
                  LIMIT 10
              """)
              
              # Verificar tamaño de bases de datos
              db_sizes = await conn.fetch("""
                  SELECT datname, pg_size_pretty(pg_database_size(datname)) as size
                  FROM pg_database 
                  WHERE datistemplate = false
              """)
              
              await conn.close()
              
              return {
                  'status': 'healthy',
                  'active_connections': active_connections,
                  'dead_tuples': [dict(row) for row in dead_tuples],
                  'database_sizes': [dict(row) for row in db_sizes]
              }
              
          except Exception as e:
              self.logger.error(f"PostgreSQL health check failed for {config.name}: {e}")
              return {'status': 'error', 'error': str(e)}
      
      async def monitor_all_databases(self):
          """Monitorear todas las bases de datos concurrentemente"""
          tasks = []
          
          for config in self.configs:
              if config.type == 'mysql':
                  task = self.check_mysql_health(config)
              elif config.type == 'postgresql':
                  task = self.check_postgresql_health(config)
              else:
                  continue
                  
              tasks.append((config.name, task))
          
          results = {}
          for name, task in tasks:
              try:
                  result = await task
                  results[name] = result
                  
                  # Enviar métricas a CloudWatch
                  await self.send_metrics_to_cloudwatch(name, result)
                  
              except Exception as e:
                  results[name] = {'status': 'error', 'error': str(e)}
          
          return results
      
      async def send_metrics_to_cloudwatch(self, db_name: str, metrics: Dict[str, Any]):
          """Enviar métricas personalizadas a CloudWatch"""
          import boto3
          
          cloudwatch = boto3.client('cloudwatch')
          
          metric_data = []
          
          if 'connections' in metrics:
              metric_data.append({
                  'MetricName': 'ActiveConnections',
                  'Value': float(metrics['connections']),
                  'Unit': 'Count',
                  'Dimensions': [
                      {'Name': 'DatabaseName', 'Value': db_name}
                  ]
              })
          
          if 'replication_lag' in metrics and metrics['replication_lag'] is not None:
              metric_data.append({
                  'MetricName': 'ReplicationLag',
                  'Value': float(metrics['replication_lag']),
                  'Unit': 'Seconds',
                  'Dimensions': [
                      {'Name': 'DatabaseName', 'Value': db_name}
                  ]
              })
          
          if metric_data:
              cloudwatch.put_metric_data(
                  Namespace='Database/Custom',
                  MetricData=metric_data
              )
  
  # Uso del framework
  async def main():
      configs = [
          DatabaseConfig(
              name='production-mysql',
              type='mysql',
              host='prod-mysql.amazonaws.com',
              port=3306,
              username='monitor_user',
              password='secure_password',
              database='production'
          ),
          DatabaseConfig(
              name='analytics-postgres',
              type='postgresql',
              host='analytics-pg.amazonaws.com',
              port=5432,
              username='monitor_user',
              password='secure_password',
              database='analytics'
          )
      ]
      
      monitor = DatabaseMonitor(configs)
      results = await monitor.monitor_all_databases()
      
      print("🔍 Resultados del monitoreo:")
      for db_name, result in results.items():
          print(f"\n📊 {db_name}:")
          print(f"   Estado: {result['status']}")
          if result['status'] == 'healthy':
              if 'connections' in result:
                  print(f"   Conexiones: {result['connections']}")
              if 'replication_lag' in result and result['replication_lag']:
                  print(f"   Replication Lag: {result['replication_lag']}s")
  
  if __name__ == "__main__":
      asyncio.run(main())
  ```

#### Bash Avanzado para Operaciones
**Meses 15-16:**
- [ ] **Scripts de Orquestación Compleja**
  ```bash
  #!/bin/bash
  # advanced_dba_operations.sh - Operaciones avanzadas para DBA
  
  # Configuración avanzada
  set -euo pipefail  # Strict mode
  IFS=$'\n\t'
  
  # Variables globales
  readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  readonly CONFIG_FILE="${SCRIPT_DIR}/config.yaml"
  readonly LOG_DIR="/var/log/dba-operations"
  readonly BACKUP_DIR="/backups"
  readonly TEMP_DIR="/tmp/dba-ops"
  
  # Colores y formato
  readonly RED='\033[0;31m'
  readonly GREEN='\033[0;32m'
  readonly YELLOW='\033[1;33m'
  readonly BLUE='\033[0;34m'
  readonly BOLD='\033[1m'
  readonly NC='\033[0m'
  
  # Funciones de utilidad
  log() {
      local level="$1"
      shift
      local message="$*"
      local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
      
      case "$level" in
          ERROR)   echo -e "${RED}[ERROR]${NC} ${timestamp} - $message" | tee -a "${LOG_DIR}/error.log" ;;
          WARN)    echo -e "${YELLOW}[WARN]${NC} ${timestamp} - $message" | tee -a "${LOG_DIR}/operations.log" ;;
          INFO)    echo -e "${GREEN}[INFO]${NC} ${timestamp} - $message" | tee -a "${LOG_DIR}/operations.log" ;;
          DEBUG)   echo -e "${BLUE}[DEBUG]${NC} ${timestamp} - $message" | tee -a "${LOG_DIR}/debug.log" ;;
      esac
  }
  
  # Función para verificar prerrequisitos
  check_prerequisites() {
      log INFO "Verificando prerrequisitos..."
      
      local missing_tools=()
      
      # Verificar herramientas necesarias
      for tool in mysql mysqldump aws python3 docker jq yq; do
          if ! command -v "$tool" &> /dev/null; then
              missing_tools+=("$tool")
          fi
      done
      
      if [[ ${#missing_tools[@]} -gt 0 ]]; then
          log ERROR "Herramientas faltantes: ${missing_tools[*]}"
          exit 1
      fi
      
      # Crear directorios necesarios
      mkdir -p "$LOG_DIR" "$BACKUP_DIR" "$TEMP_DIR"
      
      # Verificar configuración
      if [[ ! -f "$CONFIG_FILE" ]]; then
          log ERROR "Archivo de configuración no encontrado: $CONFIG_FILE"
          exit 1
      fi
      
      log INFO "✅ Prerrequisitos verificados"
  }
  
  # Función de backup inteligente con retry y validación
  intelligent_backup() {
      local db_name="$1"
      local max_retries=3
      local retry_count=0
      
      log INFO "Iniciando backup inteligente de $db_name"
      
      # Obtener configuración de la BD
      local db_config=$(yq eval ".databases.${db_name}" "$CONFIG_FILE")
      local host=$(echo "$db_config" | yq eval '.host' -)
      local user=$(echo "$db_config" | yq eval '.user' -)
      local password=$(echo "$db_config" | yq eval '.password' -)
      
      while [[ $retry_count -lt $max_retries ]]; do
          local timestamp=$(date +%Y%m%d_%H%M%S)
          local backup_file="${BACKUP_DIR}/${db_name}_backup_${timestamp}.sql"
          local compressed_file="${backup_file}.gz"
          
          log INFO "Intento $((retry_count + 1)) de backup para $db_name"
          
          # Verificar espacio disponible
          local available_space=$(df "$BACKUP_DIR" | awk 'NR==2 {print $4}')
          local estimated_size=$(mysql -h "$host" -u "$user" -p"$password" \
                                -e "SELECT ROUND(SUM(data_length + index_length) / 1024 / 1024, 1) AS 'DB Size in MB' 
                                    FROM information_schema.tables 
                                    WHERE table_schema = '$db_name';" | tail -n 1)
          
          if [[ $available_space -lt $((estimated_size * 1024 * 2)) ]]; then
              log ERROR "Espacio insuficiente para backup. Disponible: ${available_space}KB, Necesario: $((estimated_size * 1024 * 2))KB"
              return 1
          fi
          
          # Realizar backup con opciones optimizadas
          if mysqldump \
              --host="$host" \
              --user="$user" \
              --password="$password" \
              --single-transaction \
              --routines \
              --triggers \
              --events \
              --hex-blob \
              --quick \
              --lock-tables=false \
              --databases "$db_name" > "$backup_file"; then
              
              log INFO "✅ Backup completado: $backup_file"
              
              # Validar integridad del backup
              if validate_backup "$backup_file"; then
                  # Comprimir backup
                  gzip "$backup_file"
                  log INFO "✅ Backup comprimido: $compressed_file"
                  
                  # Subir a S3 con metadata
                  upload_to_s3 "$compressed_file" "$db_name"
                  
                  # Limpiar backups antiguos
                  cleanup_old_backups "$db_name"
                  
                  return 0
              else
                  log ERROR "Backup inválido, reintentando..."
                  rm -f "$backup_file"
              fi
          else
              log ERROR "Error en mysqldump, reintentando..."
          fi
          
          ((retry_count++))
          sleep $((retry_count * 10))  # Backoff exponencial
      done
      
      log ERROR "Backup falló después de $max_retries intentos"
      return 1
  }
  
  # Función para validar backup
  validate_backup() {
      local backup_file="$1"
      
      log INFO "Validando integridad del backup: $backup_file"
      
      # Verificar que el archivo no esté vacío
      if [[ ! -s "$backup_file" ]]; then
          log ERROR "Backup está vacío"
          return 1
      fi
      
      # Verificar sintaxis SQL básica
      if ! grep -q "CREATE DATABASE" "$backup_file"; then
          log ERROR "Backup no contiene estructura de BD válida"
          return 1
      fi
      
      # Verificar que termine correctamente
      if ! tail -n 5 "$backup_file" | grep -q "Dump completed"; then
          log ERROR "Backup parece incompleto"
          return 1
      fi
      
      log INFO "✅ Backup validado correctamente"
      return 0
  }
  
  # Función para subir a S3 con metadata
  upload_to_s3() {
      local file="$1"
      local db_name="$2"
      local s3_bucket=$(yq eval '.aws.backup_bucket' "$CONFIG_FILE")
      local s3_key="mysql/${db_name}/$(basename "$file")"
      
      log INFO "Subiendo backup a S3: s3://${s3_bucket}/${s3_key}"
      
      # Calcular checksum
      local checksum=$(sha256sum "$file" | cut -d' ' -f1)
      
      # Subir con metadata
      if aws s3 cp "$file" "s3://${s3_bucket}/${s3_key}" \
          --metadata "database=${db_name},checksum=${checksum},backup-type=full" \
          --storage-class STANDARD_IA; then
          
          log INFO "✅ Backup subido exitosamente a S3"
          
          # Crear entrada en DynamoDB para tracking
          aws dynamodb put-item \
              --table-name backup-tracking \
              --item "{
                  \"database_name\": {\"S\": \"$db_name\"},
                  \"backup_date\": {\"S\": \"$(date -u +%Y-%m-%dT%H:%M:%SZ)\"},
                  \"s3_location\": {\"S\": \"s3://${s3_bucket}/${s3_key}\"},
                  \"checksum\": {\"S\": \"$checksum\"},
                  \"size_bytes\": {\"N\": \"$(stat -c%s "$file")\"}
              }"
          
          return 0
      else
          log ERROR "Error subiendo backup a S3"
          return 1
      fi
  }
  
  # Función para limpiar backups antiguos
  cleanup_old_backups() {
      local db_name="$1"
      local retention_days=$(yq eval '.backup.retention_days' "$CONFIG_FILE")
      
      log INFO "Limpiando backups antiguos de $db_name (>$retention_days días)"
      
      # Limpiar archivos locales
      find "$BACKUP_DIR" -name "${db_name}_backup_*.sql.gz" -mtime +$retention_days -delete
      
      # Limpiar archivos en S3
      local s3_bucket=$(yq eval '.aws.backup_bucket' "$CONFIG_FILE")
      local cutoff_date=$(date -d "$retention_days days ago" +%Y-%m-%d)
      
      aws s3api list-objects-v2 \
          --bucket "$s3_bucket" \
          --prefix "mysql/${db_name}/" \
          --query "Contents[?LastModified<='${cutoff_date}'].Key" \
          --output text | \
      while read -r key; do
          if [[ -n "$key" ]]; then
              aws s3 rm "s3://${s3_bucket}/${key}"
              log INFO "Eliminado backup antiguo: s3://${s3_bucket}/${key}"
          fi
      done
  }
  
  # Función principal
  main() {
      log INFO "🚀 Iniciando operaciones avanzadas de DBA"
      
      check_prerequisites
      
      case "${1:-}" in
          backup)
              if [[ -z "${2:-}" ]]; then
                  log ERROR "Uso: $0 backup <database_name>"
                  exit 1
              fi
              intelligent_backup "$2"
              ;;
          monitor)
              log INFO "Iniciando monitoreo continuo..."
              python3 "${SCRIPT_DIR}/dba_framework.py"
              ;;
          health-check)
              log INFO "Ejecutando health check completo..."
              # Implementar health check
              ;;
          *)
              echo "Uso: $0 {backup|monitor|health-check} [opciones]"
              exit 1
              ;;
      esac
      
      log INFO "✅ Operaciones completadas exitosamente"
  }
  
  # Manejo de señales
  trap 'log ERROR "Script interrumpido"; exit 130' INT TERM
  
  # Ejecutar función principal
  main "$@"
  ```

### 📈 Monitoreo y Observabilidad

#### Custom Metrics y Dashboards
**Meses 13-14:**
- [ ] **CloudWatch Custom Metrics**
  ```python
  import boto3
  
  cloudwatch = boto3.client('cloudwatch')
  
  # Enviar métrica personalizada
  cloudwatch.put_metric_data(
      Namespace='Database/Custom',
      MetricData=[
          {
              'MetricName': 'ActiveConnections',
              'Value': get_active_connections(),
              'Unit': 'Count',
              'Dimensions': [
                  {
                      'Name': 'DatabaseName',
                      'Value': 'production'
                  }
              ]
          }
      ]
  )
  ```

- [ ] **Grafana + Prometheus**
  ```yaml
  # prometheus.yml
  global:
    scrape_interval: 15s
  
  scrape_configs:
    - job_name: 'mysql-exporter'
      static_configs:
        - targets: ['mysql-exporter:9104']
    
    - job_name: 'postgres-exporter'
      static_configs:
        - targets: ['postgres-exporter:9187']
  ```

#### Alerting Avanzado
**Meses 15-16:**
- [ ] **Multi-dimensional Alerts**
  ```json
  {
    "AlarmName": "DatabaseHighCPU",
    "ComparisonOperator": "GreaterThanThreshold",
    "EvaluationPeriods": 2,
    "MetricName": "CPUUtilization",
    "Namespace": "AWS/RDS",
    "Period": 300,
    "Statistic": "Average",
    "Threshold": 80.0,
    "ActionsEnabled": true,
    "AlarmActions": [
      "arn:aws:sns:us-east-1:123456789012:database-alerts"
    ],
    "Dimensions": [
      {
        "Name": "DBInstanceIdentifier",
        "Value": "production-db"
      }
    ]
  }
  ```

### 🔍 Performance Analysis

#### Query Performance Tuning
**Meses 17-18:**
- [ ] **MySQL Performance Schema**
  ```sql
  -- Top queries por tiempo de ejecución
  SELECT 
      DIGEST_TEXT,
      COUNT_STAR,
      AVG_TIMER_WAIT/1000000000 as avg_time_sec,
      SUM_TIMER_WAIT/1000000000 as total_time_sec
  FROM performance_schema.events_statements_summary_by_digest
  ORDER BY SUM_TIMER_WAIT DESC
  LIMIT 10;
  ```

- [ ] **PostgreSQL pg_stat_statements**
  ```sql
  -- Queries más costosas
  SELECT 
      query,
      calls,
      total_time,
      mean_time,
      rows
  FROM pg_stat_statements
  ORDER BY total_time DESC
  LIMIT 10;
  ```

---

## 🛡️ Fase 4: Seguridad y Compliance (Meses 19-24)

### 🔐 Seguridad Avanzada

#### Encryption y Key Management
**Meses 19-20:**
- [ ] **RDS Encryption**
  ```bash
  # Crear instancia con encryption
  aws rds create-db-instance \
      --db-instance-identifier encrypted-db \
      --storage-encrypted \
      --kms-key-id arn:aws:kms:us-east-1:123456789012:key/12345678-1234-1234-1234-123456789012
  ```

- [ ] **Application-level Encryption**
  ```python
  from cryptography.fernet import Fernet
  
  # Generar key
  key = Fernet.generate_key()
  cipher_suite = Fernet(key)
  
  # Encriptar datos sensibles
  def encrypt_pii(data):
      return cipher_suite.encrypt(data.encode())
  
  def decrypt_pii(encrypted_data):
      return cipher_suite.decrypt(encrypted_data).decode()
  ```

#### Access Control y Auditing
**Meses 21-22:**
- [ ] **IAM Database Authentication**
  ```python
  import boto3
  
  # Generar token de autenticación
  rds_client = boto3.client('rds')
  token = rds_client.generate_db_auth_token(
      DBHostname='mydb.cluster-123456789012.us-east-1.rds.amazonaws.com',
      Port=3306,
      DBUsername='db_user'
  )
  ```

- [ ] **Database Activity Streams**
  ```bash
  # Habilitar activity streams
  aws rds start-activity-stream \
      --resource-arn arn:aws:rds:us-east-1:123456789012:cluster:aurora-cluster \
      --mode async \
      --kms-key-id arn:aws:kms:us-east-1:123456789012:key/12345678-1234-1234-1234-123456789012
  ```

### 📋 Compliance Framework

#### GDPR/HIPAA Compliance
**Meses 23-24:**
- [ ] **Data Classification**
  ```sql
  -- Identificar datos sensibles
  CREATE TABLE data_classification (
      table_name VARCHAR(100),
      column_name VARCHAR(100),
      classification ENUM('PUBLIC', 'INTERNAL', 'CONFIDENTIAL', 'RESTRICTED'),
      retention_period INT,
      encryption_required BOOLEAN
  );
  ```

- [ ] **Audit Logging**
  ```python
  # Audit log processor
  def process_audit_log(log_entry):
      if log_entry['event_type'] in ['SELECT', 'INSERT', 'UPDATE', 'DELETE']:
          if contains_pii(log_entry['query']):
              alert_security_team(log_entry)
              
      store_audit_record(log_entry)
  ```

---

## 🎯 Proyectos Integrales Semi-Senior

### Proyecto 1: Migración Empresarial
**Duración:** 3-4 meses  
**Objetivo:** Migrar aplicación crítica de OnPrem a AWS

**Componentes:**
- Análisis de workload actual
- Diseño de arquitectura target
- Plan de migración por fases
- Implementación con DMS
- Validación y testing
- Go-live y post-migration support

**Entregables:**
- Architecture design document
- Migration runbook
- Rollback procedures
- Performance benchmarks
- Cost analysis

### Proyecto 2: Multi-Region DR
**Duración:** 2-3 meses  
**Objetivo:** Implementar disaster recovery cross-region

**Componentes:**
- RTO/RPO requirements analysis
- Aurora Global Database setup
- Automated failover procedures
- Data validation frameworks
- DR testing automation

### Proyecto 3: Performance Optimization
**Duración:** 2 meses  
**Objetivo:** Optimizar aplicación con problemas de performance

**Componentes:**
- Performance baseline establishment
- Query optimization
- Index strategy redesign
- Caching implementation
- Load testing validation

---

## 📋 Checklist de Competencias Semi-Senior

### Conocimientos Técnicos Avanzados
- [ ] Replicación y alta disponibilidad
- [ ] Query optimization avanzada
- [ ] AWS servicios especializados (Aurora, DMS, ElastiCache)
- [ ] Arquitecturas híbridas
- [ ] Seguridad y compliance
- [ ] Monitoreo y observabilidad avanzada

### Habilidades de Liderazgo
- [ ] Liderar proyectos medianos (3-6 meses)
- [ ] Mentorear DBAs junior
- [ ] Comunicar con stakeholders técnicos
- [ ] Tomar decisiones arquitecturales
- [ ] Evaluar y recomendar tecnologías

### Competencias de Negocio
- [ ] Entender impacto de decisiones técnicas en negocio
- [ ] Calcular TCO y ROI
- [ ] Gestionar vendors y proveedores
- [ ] Participar en planning estratégico

---

## 📚 Recursos de Estudio Semi-Senior

### Certificaciones Objetivo
1. **AWS Database Specialty** (Mes 12)
2. **AWS Solutions Architect Professional** (Mes 18)
3. **MySQL 8.0 Database Administrator** (Mes 6)
4. **PostgreSQL 13 Associate** (Mes 9)

### Cursos Especializados
1. **AWS Database Migration Workshop**
2. **High Performance MySQL** - Percona
3. **PostgreSQL Performance Tuning** - 2ndQuadrant
4. **Aurora Deep Dive** - AWS Training

### Libros Avanzados
1. **"High Performance MySQL"** - Baron Schwartz
2. **"PostgreSQL High Performance"** - Gregory Smith
3. **"Designing Data-Intensive Applications"** - Martin Kleppmann
4. **"Database Reliability Engineering"** - Campbell & Majors

---

## 📅 Timeline Detallado Semi-Senior

### Año 1: Fundamentos Avanzados
- **Q1:** MySQL/PostgreSQL avanzado
- **Q2:** Aurora y servicios AWS especializados
- **Q3:** DMS y migraciones
- **Q4:** Arquitecturas híbridas

### Año 2: Especialización
- **Q1:** Monitoreo y observabilidad
- **Q2:** Seguridad y compliance
- **Q3:** Performance optimization
- **Q4:** Liderazgo de proyectos

### Año 3: Preparación Senior
- **Q1:** Arquitectura empresarial
- **Q2:** Estrategia de datos
- **Q3:** Mentoring y team building
- **Q4:** Innovation y R&D

---

## 🎯 Métricas de Éxito Semi-Senior

### Técnicas
- [ ] Liderar migración exitosa (>99.9% uptime)
- [ ] Mejorar performance >50% en proyecto crítico
- [ ] Implementar DR con RTO <15 minutos
- [ ] Reducir costos operativos >20%

### Liderazgo
- [ ] Mentorear 2+ DBAs junior exitosamente
- [ ] Liderar equipo de 3-5 personas
- [ ] Presentar a stakeholders C-level
- [ ] Contribuir a estrategia técnica organizacional

### Reconocimiento
- [ ] AWS Database Specialty certification
- [ ] Contribuciones a comunidad (blogs, talks)
- [ ] Reconocimiento interno como SME
- [ ] Preparado para roles de arquitecto/lead

---

**¡Tu evolución hacia DBA Senior está en marcha!** 🚀

*Roadmap Semi-Senior - Actualizado Agosto 2025*
