# 🐍 Python y Bash para DBAs - Guía Esencial

## 🎯 ¿Por qué Python y Bash son Esenciales para DBAs?

### 📈 **Realidad del Mercado 2025**

En el mundo actual, **un DBA sin habilidades de scripting es como un piloto sin licencia**:

- **98% de las ofertas de trabajo DBA** requieren Python o Bash
- **Automatización es obligatoria** - tareas manuales son cosa del pasado
- **DevOps culture** exige que DBAs escriban código
- **Cloud-first companies** esperan Infrastructure as Code

### 🔄 **Evolución del DBA**

#### DBA Tradicional (2015)
```
❌ Tareas manuales repetitivas
❌ Documentación en Excel
❌ Backups manuales
❌ Monitoreo reactivo
❌ "Funciona en mi máquina"
```

#### DBA Moderno (2025)
```python
✅ Todo automatizado con código
✅ Monitoreo proactivo
✅ Infrastructure as Code
✅ CI/CD para bases de datos
✅ Observabilidad avanzada
```

---

## 🐍 Python para DBAs - Roadmap Completo

### 🌱 **Nivel Junior (Mes 1 del roadmap)**

#### Semana 1-2: Python Básico
```python
# Conexión básica a MySQL
import mysql.connector
from datetime import datetime
import os

def connect_to_database():
    """Conexión básica con manejo de errores"""
    try:
        connection = mysql.connector.connect(
            host=os.getenv('DB_HOST', 'localhost'),
            database=os.getenv('DB_NAME', 'testdb'),
            user=os.getenv('DB_USER', 'admin'),
            password=os.getenv('DB_PASS', 'password')
        )
        
        if connection.is_connected():
            print("✅ Conexión exitosa a MySQL")
            return connection
            
    except mysql.connector.Error as e:
        print(f"❌ Error conectando a MySQL: {e}")
        return None

# Script básico de health check
def database_health_check():
    """Verificar salud básica de la base de datos"""
    conn = connect_to_database()
    if not conn:
        return False
    
    try:
        cursor = conn.cursor()
        
        # Verificar conexión
        cursor.execute("SELECT 1")
        result = cursor.fetchone()
        
        if result[0] == 1:
            print("✅ Base de datos responde correctamente")
            
            # Obtener información básica
            cursor.execute("SELECT VERSION()")
            version = cursor.fetchone()[0]
            print(f"📊 Versión MySQL: {version}")
            
            # Verificar conexiones activas
            cursor.execute("SHOW GLOBAL STATUS LIKE 'Threads_connected'")
            connections = cursor.fetchone()[1]
            print(f"📊 Conexiones activas: {connections}")
            
            return True
            
    except Exception as e:
        print(f"❌ Error en health check: {e}")
        return False
    finally:
        if conn.is_connected():
            cursor.close()
            conn.close()

# Ejecutar health check
if __name__ == "__main__":
    database_health_check()
```

#### Semana 3-4: Automatización Básica
```python
# backup_manager.py - Gestor básico de backups
import subprocess
import os
import gzip
import shutil
from datetime import datetime
import logging

# Configurar logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler('backup.log'),
        logging.StreamHandler()
    ]
)

class BackupManager:
    def __init__(self, config):
        self.config = config
        self.backup_dir = config.get('backup_dir', '/backups')
        self.ensure_backup_directory()
    
    def ensure_backup_directory(self):
        """Crear directorio de backup si no existe"""
        os.makedirs(self.backup_dir, exist_ok=True)
        logging.info(f"Directorio de backup: {self.backup_dir}")
    
    def create_backup(self, database_name):
        """Crear backup de una base de datos específica"""
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        backup_filename = f"{database_name}_backup_{timestamp}.sql"
        backup_path = os.path.join(self.backup_dir, backup_filename)
        
        logging.info(f"Iniciando backup de {database_name}")
        
        # Comando mysqldump
        cmd = [
            'mysqldump',
            f"--host={self.config['host']}",
            f"--user={self.config['user']}",
            f"--password={self.config['password']}",
            '--single-transaction',
            '--routines',
            '--triggers',
            database_name
        ]
        
        try:
            # Ejecutar mysqldump
            with open(backup_path, 'w') as backup_file:
                result = subprocess.run(
                    cmd, 
                    stdout=backup_file, 
                    stderr=subprocess.PIPE,
                    text=True
                )
            
            if result.returncode == 0:
                logging.info(f"✅ Backup creado: {backup_path}")
                
                # Comprimir backup
                compressed_path = self.compress_backup(backup_path)
                
                # Validar backup
                if self.validate_backup(backup_path):
                    logging.info("✅ Backup validado correctamente")
                    return compressed_path
                else:
                    logging.error("❌ Backup inválido")
                    return None
            else:
                logging.error(f"❌ Error en mysqldump: {result.stderr}")
                return None
                
        except Exception as e:
            logging.error(f"❌ Error creando backup: {e}")
            return None
    
    def compress_backup(self, backup_path):
        """Comprimir archivo de backup"""
        compressed_path = f"{backup_path}.gz"
        
        try:
            with open(backup_path, 'rb') as f_in:
                with gzip.open(compressed_path, 'wb') as f_out:
                    shutil.copyfileobj(f_in, f_out)
            
            # Eliminar archivo original
            os.remove(backup_path)
            logging.info(f"✅ Backup comprimido: {compressed_path}")
            return compressed_path
            
        except Exception as e:
            logging.error(f"❌ Error comprimiendo backup: {e}")
            return backup_path
    
    def validate_backup(self, backup_path):
        """Validar que el backup sea válido"""
        try:
            with open(backup_path, 'r') as f:
                content = f.read(1000)  # Leer primeros 1000 caracteres
                
                # Verificaciones básicas
                if 'CREATE DATABASE' in content or 'CREATE TABLE' in content:
                    return True
                else:
                    return False
                    
        except Exception as e:
            logging.error(f"❌ Error validando backup: {e}")
            return False

# Configuración
config = {
    'host': 'localhost',
    'user': 'admin',
    'password': 'password',
    'backup_dir': '/backups'
}

# Uso
if __name__ == "__main__":
    backup_manager = BackupManager(config)
    result = backup_manager.create_backup('production_db')
    
    if result:
        print(f"🎉 Backup completado: {result}")
    else:
        print("❌ Backup falló")
```

### 🔥 **Nivel Semi-Senior (Meses 13-14)**

#### Framework Avanzado de Monitoreo
```python
# advanced_monitor.py - Monitoreo avanzado asíncrono
import asyncio
import aiohttp
import aiomysql
import asyncpg
import boto3
from dataclasses import dataclass
from typing import List, Dict, Any, Optional
import json
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
    ssl_enabled: bool = False
    connection_timeout: int = 30

@dataclass
class MetricThreshold:
    metric_name: str
    warning_threshold: float
    critical_threshold: float
    unit: str = 'Count'

class AdvancedDatabaseMonitor:
    def __init__(self, configs: List[DatabaseConfig]):
        self.configs = configs
        self.logger = self._setup_logging()
        self.cloudwatch = boto3.client('cloudwatch')
        self.sns = boto3.client('sns')
        
        # Umbrales por defecto
        self.thresholds = {
            'connections': MetricThreshold('ActiveConnections', 80, 95),
            'cpu_usage': MetricThreshold('CPUUtilization', 70, 90, 'Percent'),
            'replication_lag': MetricThreshold('ReplicationLag', 30, 60, 'Seconds'),
            'dead_tuples_percent': MetricThreshold('DeadTuplesPercent', 20, 40, 'Percent')
        }
    
    def _setup_logging(self):
        """Configurar logging avanzado"""
        logger = logging.getLogger(__name__)
        logger.setLevel(logging.INFO)
        
        # Handler para archivo
        file_handler = logging.FileHandler('advanced_monitor.log')
        file_handler.setLevel(logging.INFO)
        
        # Handler para consola
        console_handler = logging.StreamHandler()
        console_handler.setLevel(logging.INFO)
        
        # Formato
        formatter = logging.Formatter(
            '%(asctime)s - %(name)s - %(levelname)s - %(message)s'
        )
        file_handler.setFormatter(formatter)
        console_handler.setFormatter(formatter)
        
        logger.addHandler(file_handler)
        logger.addHandler(console_handler)
        
        return logger
    
    async def check_mysql_advanced(self, config: DatabaseConfig) -> Dict[str, Any]:
        """Verificación avanzada de MySQL con métricas detalladas"""
        try:
            # Crear pool de conexiones
            pool = await aiomysql.create_pool(
                host=config.host,
                port=config.port,
                user=config.username,
                password=config.password,
                db=config.database,
                minsize=1,
                maxsize=5,
                connect_timeout=config.connection_timeout
            )
            
            metrics = {}
            
            async with pool.acquire() as conn:
                async with conn.cursor() as cursor:
                    # Métricas de conexiones
                    await cursor.execute("SHOW GLOBAL STATUS LIKE 'Threads_connected'")
                    connections = await cursor.fetchone()
                    metrics['active_connections'] = int(connections[1]) if connections else 0
                    
                    await cursor.execute("SHOW GLOBAL STATUS LIKE 'Max_used_connections'")
                    max_connections = await cursor.fetchone()
                    metrics['max_used_connections'] = int(max_connections[1]) if max_connections else 0
                    
                    # Métricas de replicación
                    await cursor.execute("SHOW SLAVE STATUS")
                    slave_status = await cursor.fetchone()
                    if slave_status:
                        metrics['replication_lag'] = slave_status[32] or 0
                        metrics['slave_io_running'] = slave_status[10] == 'Yes'
                        metrics['slave_sql_running'] = slave_status[11] == 'Yes'
                    
                    # Métricas de performance
                    await cursor.execute("SHOW GLOBAL STATUS LIKE 'Slow_queries'")
                    slow_queries = await cursor.fetchone()
                    metrics['slow_queries'] = int(slow_queries[1]) if slow_queries else 0
                    
                    # Métricas de InnoDB
                    await cursor.execute("SHOW GLOBAL STATUS LIKE 'Innodb_buffer_pool_read_requests'")
                    read_requests = await cursor.fetchone()
                    await cursor.execute("SHOW GLOBAL STATUS LIKE 'Innodb_buffer_pool_reads'")
                    disk_reads = await cursor.fetchone()
                    
                    if read_requests and disk_reads:
                        total_reads = int(read_requests[1])
                        physical_reads = int(disk_reads[1])
                        if total_reads > 0:
                            metrics['buffer_pool_hit_ratio'] = ((total_reads - physical_reads) / total_reads) * 100
                    
                    # Tamaños de bases de datos
                    await cursor.execute("""
                        SELECT 
                            table_schema,
                            ROUND(SUM(data_length + index_length) / 1024 / 1024, 2) AS size_mb
                        FROM information_schema.tables 
                        WHERE table_schema NOT IN ('information_schema', 'performance_schema', 'mysql', 'sys')
                        GROUP BY table_schema
                    """)
                    db_sizes = await cursor.fetchall()
                    metrics['database_sizes'] = {db[0]: db[1] for db in db_sizes} if db_sizes else {}
            
            pool.close()
            await pool.wait_closed()
            
            # Evaluar umbrales y generar alertas
            alerts = self._evaluate_thresholds(config.name, metrics)
            
            return {
                'status': 'healthy',
                'timestamp': datetime.utcnow().isoformat(),
                'metrics': metrics,
                'alerts': alerts
            }
            
        except Exception as e:
            self.logger.error(f"MySQL check failed for {config.name}: {e}")
            return {
                'status': 'error',
                'timestamp': datetime.utcnow().isoformat(),
                'error': str(e)
            }
    
    def _evaluate_thresholds(self, db_name: str, metrics: Dict[str, Any]) -> List[Dict[str, Any]]:
        """Evaluar métricas contra umbrales y generar alertas"""
        alerts = []
        
        for metric_key, threshold in self.thresholds.items():
            if metric_key in metrics:
                value = metrics[metric_key]
                
                if value >= threshold.critical_threshold:
                    alerts.append({
                        'severity': 'CRITICAL',
                        'metric': threshold.metric_name,
                        'value': value,
                        'threshold': threshold.critical_threshold,
                        'message': f"{threshold.metric_name} is critically high: {value} >= {threshold.critical_threshold}"
                    })
                elif value >= threshold.warning_threshold:
                    alerts.append({
                        'severity': 'WARNING',
                        'metric': threshold.metric_name,
                        'value': value,
                        'threshold': threshold.warning_threshold,
                        'message': f"{threshold.metric_name} is above warning threshold: {value} >= {threshold.warning_threshold}"
                    })
        
        return alerts
    
    async def send_metrics_to_cloudwatch(self, db_name: str, metrics: Dict[str, Any]):
        """Enviar métricas personalizadas a CloudWatch"""
        try:
            metric_data = []
            
            # Mapear métricas a CloudWatch
            metric_mappings = {
                'active_connections': ('ActiveConnections', 'Count'),
                'replication_lag': ('ReplicationLag', 'Seconds'),
                'slow_queries': ('SlowQueries', 'Count'),
                'buffer_pool_hit_ratio': ('BufferPoolHitRatio', 'Percent')
            }
            
            for metric_key, (metric_name, unit) in metric_mappings.items():
                if metric_key in metrics:
                    metric_data.append({
                        'MetricName': metric_name,
                        'Value': float(metrics[metric_key]),
                        'Unit': unit,
                        'Dimensions': [
                            {'Name': 'DatabaseName', 'Value': db_name}
                        ],
                        'Timestamp': datetime.utcnow()
                    })
            
            if metric_data:
                self.cloudwatch.put_metric_data(
                    Namespace='Database/Advanced',
                    MetricData=metric_data
                )
                self.logger.info(f"✅ Métricas enviadas a CloudWatch para {db_name}")
                
        except Exception as e:
            self.logger.error(f"Error enviando métricas a CloudWatch: {e}")
    
    async def send_alerts(self, db_name: str, alerts: List[Dict[str, Any]]):
        """Enviar alertas críticas por SNS"""
        if not alerts:
            return
        
        critical_alerts = [alert for alert in alerts if alert['severity'] == 'CRITICAL']
        
        if critical_alerts:
            try:
                message = f"🚨 ALERTA CRÍTICA - Base de datos: {db_name}\n\n"
                for alert in critical_alerts:
                    message += f"• {alert['message']}\n"
                
                message += f"\nTimestamp: {datetime.utcnow().isoformat()}"
                
                # Enviar a SNS (configurar ARN del topic)
                sns_topic_arn = os.getenv('SNS_TOPIC_ARN')
                if sns_topic_arn:
                    self.sns.publish(
                        TopicArn=sns_topic_arn,
                        Message=message,
                        Subject=f"Database Alert - {db_name}"
                    )
                    self.logger.info(f"🚨 Alerta crítica enviada para {db_name}")
                
            except Exception as e:
                self.logger.error(f"Error enviando alerta: {e}")
    
    async def monitor_all_databases(self) -> Dict[str, Any]:
        """Monitorear todas las bases de datos concurrentemente"""
        tasks = []
        
        for config in self.configs:
            if config.type == 'mysql':
                task = self.check_mysql_advanced(config)
                tasks.append((config.name, task))
        
        results = {}
        
        # Ejecutar todas las verificaciones concurrentemente
        for name, task in tasks:
            try:
                result = await task
                results[name] = result
                
                # Enviar métricas a CloudWatch
                if result['status'] == 'healthy':
                    await self.send_metrics_to_cloudwatch(name, result['metrics'])
                    await self.send_alerts(name, result.get('alerts', []))
                
            except Exception as e:
                results[name] = {
                    'status': 'error',
                    'timestamp': datetime.utcnow().isoformat(),
                    'error': str(e)
                }
                self.logger.error(f"Error monitoring {name}: {e}")
        
        return results

# Uso del monitor avanzado
async def main():
    configs = [
        DatabaseConfig(
            name='production-mysql',
            type='mysql',
            host='prod-mysql.amazonaws.com',
            port=3306,
            username='monitor_user',
            password='secure_password',
            database='production',
            ssl_enabled=True
        )
    ]
    
    monitor = AdvancedDatabaseMonitor(configs)
    
    # Monitoreo continuo cada 60 segundos
    while True:
        try:
            results = await monitor.monitor_all_databases()
            
            print(f"\n🔍 Monitoreo completado - {datetime.now()}")
            for db_name, result in results.items():
                status_emoji = "✅" if result['status'] == 'healthy' else "❌"
                print(f"{status_emoji} {db_name}: {result['status']}")
                
                if result['status'] == 'healthy' and 'alerts' in result:
                    for alert in result['alerts']:
                        severity_emoji = "🚨" if alert['severity'] == 'CRITICAL' else "⚠️"
                        print(f"  {severity_emoji} {alert['message']}")
            
            await asyncio.sleep(60)  # Esperar 60 segundos
            
        except KeyboardInterrupt:
            print("\n👋 Monitoreo detenido por el usuario")
            break
        except Exception as e:
            print(f"❌ Error en monitoreo: {e}")
            await asyncio.sleep(30)  # Esperar 30 segundos antes de reintentar

if __name__ == "__main__":
    asyncio.run(main())
```

---

## 📊 **Casos de Uso Prácticos**

### 1. **Automatización de Backups Inteligentes**
- Backup con retry automático
- Validación de integridad
- Compresión y upload a S3
- Limpieza automática de backups antiguos
- Notificaciones de estado

### 2. **Monitoreo Proactivo**
- Health checks asíncronos
- Métricas personalizadas a CloudWatch
- Alertas automáticas por SNS
- Dashboards en tiempo real
- Análisis de tendencias

### 3. **Gestión de Configuraciones**
- Deployment automatizado de cambios
- Rollback automático en caso de errores
- Validación de configuraciones
- Auditoría de cambios
- Compliance automático

---

*Continúa en la siguiente parte...*
