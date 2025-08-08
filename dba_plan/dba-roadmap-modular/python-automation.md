# Python Automation for DBAs

## 🎯 Why Python is Essential for Modern DBAs

Python has become the standard for database automation, monitoring, and operations. Manual database administration is obsolete in 2025 - automation through scripting is mandatory for career viability.

## 🚀 Getting Started

### Environment Setup
```bash
# Install Python (macOS)
brew install python3

# Create virtual environment
python3 -m venv dba-automation
source dba-automation/bin/activate

# Install essential packages
pip install boto3 psycopg2-binary pymysql sqlalchemy pandas
pip install requests schedule logging-config
```

### Project Structure
```
dba-automation/
├── config/
│   ├── database.yaml
│   └── monitoring.yaml
├── scripts/
│   ├── monitoring/
│   ├── backup/
│   └── maintenance/
├── utils/
│   ├── __init__.py
│   ├── database.py
│   └── aws_helper.py
└── requirements.txt
```

## 📚 Core Python Skills for DBAs

### 1. Database Connectivity and Operations
```python
import psycopg2
import pymysql
from sqlalchemy import create_engine, text
import pandas as pd
from contextlib import contextmanager
import logging

class DatabaseManager:
    def __init__(self, config):
        self.config = config
        self.logger = logging.getLogger(__name__)
    
    @contextmanager
    def get_connection(self, db_type='postgresql'):
        """Context manager for database connections"""
        conn = None
        try:
            if db_type == 'postgresql':
                conn = psycopg2.connect(
                    host=self.config['host'],
                    port=self.config['port'],
                    database=self.config['database'],
                    user=self.config['username'],
                    password=self.config['password']
                )
            elif db_type == 'mysql':
                conn = pymysql.connect(
                    host=self.config['host'],
                    port=self.config['port'],
                    database=self.config['database'],
                    user=self.config['username'],
                    password=self.config['password']
                )
            yield conn
        except Exception as e:
            self.logger.error(f"Database connection error: {e}")
            if conn:
                conn.rollback()
            raise
        finally:
            if conn:
                conn.close()
    
    def execute_query(self, query, params=None):
        """Execute query and return results"""
        with self.get_connection() as conn:
            cursor = conn.cursor()
            cursor.execute(query, params or ())
            
            if query.strip().upper().startswith('SELECT'):
                return cursor.fetchall()
            else:
                conn.commit()
                return cursor.rowcount
    
    def get_table_sizes(self):
        """Get table sizes for PostgreSQL"""
        query = """
        SELECT 
            schemaname,
            tablename,
            pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) as size,
            pg_total_relation_size(schemaname||'.'||tablename) as size_bytes
        FROM pg_tables 
        WHERE schemaname NOT IN ('information_schema', 'pg_catalog')
        ORDER BY size_bytes DESC;
        """
        return self.execute_query(query)
```

### 2. AWS RDS Monitoring and Management
```python
import boto3
from datetime import datetime, timedelta
import json
import asyncio
import aiohttp

class RDSMonitor:
    def __init__(self, region='us-east-1'):
        self.rds = boto3.client('rds', region_name=region)
        self.cloudwatch = boto3.client('cloudwatch', region_name=region)
        self.sns = boto3.client('sns', region_name=region)
        self.logger = logging.getLogger(__name__)
    
    def get_db_instances(self):
        """Get all RDS instances"""
        try:
            response = self.rds.describe_db_instances()
            return response['DBInstances']
        except Exception as e:
            self.logger.error(f"Error fetching DB instances: {e}")
            return []
    
    def get_metric_statistics(self, db_identifier, metric_name, start_time, end_time):
        """Get CloudWatch metrics for RDS instance"""
        try:
            response = self.cloudwatch.get_metric_statistics(
                Namespace='AWS/RDS',
                MetricName=metric_name,
                Dimensions=[
                    {'Name': 'DBInstanceIdentifier', 'Value': db_identifier}
                ],
                StartTime=start_time,
                EndTime=end_time,
                Period=300,  # 5 minutes
                Statistics=['Average', 'Maximum']
            )
            return response['Datapoints']
        except Exception as e:
            self.logger.error(f"Error fetching metrics: {e}")
            return []
    
    async def monitor_database_health(self, db_identifier):
        """Comprehensive database health monitoring"""
        end_time = datetime.utcnow()
        start_time = end_time - timedelta(minutes=15)
        
        metrics_to_check = [
            'CPUUtilization',
            'DatabaseConnections',
            'FreeableMemory',
            'FreeStorageSpace',
            'ReadLatency',
            'WriteLatency'
        ]
        
        health_report = {
            'instance': db_identifier,
            'timestamp': end_time.isoformat(),
            'metrics': {},
            'alerts': []
        }
        
        for metric in metrics_to_check:
            datapoints = self.get_metric_statistics(
                db_identifier, metric, start_time, end_time
            )
            
            if datapoints:
                latest = max(datapoints, key=lambda x: x['Timestamp'])
                health_report['metrics'][metric] = {
                    'value': latest['Average'],
                    'max': latest['Maximum'],
                    'timestamp': latest['Timestamp'].isoformat()
                }
                
                # Check thresholds and generate alerts
                await self.check_thresholds(db_identifier, metric, latest, health_report)
        
        return health_report
    
    async def check_thresholds(self, db_identifier, metric, datapoint, health_report):
        """Check metric thresholds and generate alerts"""
        thresholds = {
            'CPUUtilization': {'warning': 70, 'critical': 85},
            'DatabaseConnections': {'warning': 80, 'critical': 95},
            'FreeableMemory': {'warning': 1000000000, 'critical': 500000000},  # bytes
            'ReadLatency': {'warning': 0.2, 'critical': 0.5},  # seconds
            'WriteLatency': {'warning': 0.2, 'critical': 0.5}
        }
        
        if metric in thresholds:
            threshold = thresholds[metric]
            value = datapoint['Average']
            
            if metric == 'FreeableMemory':
                # For memory, lower values are worse
                if value < threshold['critical']:
                    await self.send_alert(db_identifier, metric, value, 'CRITICAL')
                    health_report['alerts'].append({
                        'level': 'CRITICAL',
                        'metric': metric,
                        'value': value,
                        'threshold': threshold['critical']
                    })
                elif value < threshold['warning']:
                    await self.send_alert(db_identifier, metric, value, 'WARNING')
                    health_report['alerts'].append({
                        'level': 'WARNING',
                        'metric': metric,
                        'value': value,
                        'threshold': threshold['warning']
                    })
            else:
                # For other metrics, higher values are worse
                if value > threshold['critical']:
                    await self.send_alert(db_identifier, metric, value, 'CRITICAL')
                    health_report['alerts'].append({
                        'level': 'CRITICAL',
                        'metric': metric,
                        'value': value,
                        'threshold': threshold['critical']
                    })
                elif value > threshold['warning']:
                    await self.send_alert(db_identifier, metric, value, 'WARNING')
                    health_report['alerts'].append({
                        'level': 'WARNING',
                        'metric': metric,
                        'value': value,
                        'threshold': threshold['warning']
                    })
    
    async def send_alert(self, db_identifier, metric, value, level):
        """Send alert via SNS"""
        message = {
            'instance': db_identifier,
            'metric': metric,
            'value': value,
            'level': level,
            'timestamp': datetime.utcnow().isoformat()
        }
        
        try:
            self.sns.publish(
                TopicArn='arn:aws:sns:us-east-1:123456789012:database-alerts',
                Message=json.dumps(message),
                Subject=f'Database Alert: {level} - {db_identifier}'
            )
            self.logger.info(f"Alert sent for {db_identifier}: {metric} = {value}")
        except Exception as e:
            self.logger.error(f"Failed to send alert: {e}")
```

### 3. Automated Backup Management
```python
import boto3
from datetime import datetime, timedelta
import schedule
import time

class BackupManager:
    def __init__(self, region='us-east-1'):
        self.rds = boto3.client('rds', region_name=region)
        self.s3 = boto3.client('s3', region_name=region)
        self.logger = logging.getLogger(__name__)
    
    def create_snapshot(self, db_identifier, snapshot_type='manual'):
        """Create RDS snapshot"""
        timestamp = datetime.now().strftime('%Y%m%d-%H%M%S')
        snapshot_id = f"{db_identifier}-{snapshot_type}-{timestamp}"
        
        try:
            response = self.rds.create_db_snapshot(
                DBSnapshotIdentifier=snapshot_id,
                DBInstanceIdentifier=db_identifier,
                Tags=[
                    {'Key': 'Type', 'Value': snapshot_type},
                    {'Key': 'CreatedBy', 'Value': 'automated-backup'},
                    {'Key': 'CreatedAt', 'Value': timestamp}
                ]
            )
            
            self.logger.info(f"Snapshot created: {snapshot_id}")
            return snapshot_id
            
        except Exception as e:
            self.logger.error(f"Failed to create snapshot: {e}")
            return None
    
    def cleanup_old_snapshots(self, db_identifier, retention_days=7):
        """Clean up snapshots older than retention period"""
        cutoff_date = datetime.now() - timedelta(days=retention_days)
        
        try:
            response = self.rds.describe_db_snapshots(
                DBInstanceIdentifier=db_identifier,
                SnapshotType='manual'
            )
            
            for snapshot in response['DBSnapshots']:
                if snapshot['SnapshotCreateTime'].replace(tzinfo=None) < cutoff_date:
                    self.rds.delete_db_snapshot(
                        DBSnapshotIdentifier=snapshot['DBSnapshotIdentifier']
                    )
                    self.logger.info(f"Deleted old snapshot: {snapshot['DBSnapshotIdentifier']}")
                    
        except Exception as e:
            self.logger.error(f"Failed to cleanup snapshots: {e}")
    
    def export_snapshot_to_s3(self, snapshot_id, s3_bucket, kms_key_id):
        """Export snapshot to S3 for long-term storage"""
        export_task_id = f"export-{snapshot_id}-{int(time.time())}"
        
        try:
            response = self.rds.start_export_task(
                ExportTaskIdentifier=export_task_id,
                SourceArn=f"arn:aws:rds:us-east-1:123456789012:snapshot:{snapshot_id}",
                S3BucketName=s3_bucket,
                S3Prefix=f"database-exports/{datetime.now().strftime('%Y/%m/%d')}/",
                KmsKeyId=kms_key_id,
                ExportOnly=['schema', 'data']
            )
            
            self.logger.info(f"Export task started: {export_task_id}")
            return export_task_id
            
        except Exception as e:
            self.logger.error(f"Failed to start export task: {e}")
            return None
```

### 4. Performance Analysis and Reporting
```python
import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns
from sqlalchemy import create_engine

class PerformanceAnalyzer:
    def __init__(self, db_config):
        self.engine = create_engine(
            f"postgresql://{db_config['username']}:{db_config['password']}"
            f"@{db_config['host']}:{db_config['port']}/{db_config['database']}"
        )
        self.logger = logging.getLogger(__name__)
    
    def analyze_slow_queries(self, hours=24):
        """Analyze slow queries from pg_stat_statements"""
        query = """
        SELECT 
            query,
            calls,
            total_time,
            mean_time,
            rows,
            100.0 * shared_blks_hit / nullif(shared_blks_hit + shared_blks_read, 0) AS hit_percent
        FROM pg_stat_statements 
        WHERE total_time > 1000  -- queries taking more than 1 second total
        ORDER BY total_time DESC 
        LIMIT 20;
        """
        
        try:
            df = pd.read_sql(query, self.engine)
            return df
        except Exception as e:
            self.logger.error(f"Error analyzing slow queries: {e}")
            return pd.DataFrame()
    
    def generate_performance_report(self):
        """Generate comprehensive performance report"""
        report = {
            'timestamp': datetime.now().isoformat(),
            'slow_queries': self.analyze_slow_queries(),
            'table_stats': self.get_table_statistics(),
            'index_usage': self.analyze_index_usage(),
            'connection_stats': self.get_connection_statistics()
        }
        
        # Generate visualizations
        self.create_performance_charts(report)
        
        return report
    
    def create_performance_charts(self, report):
        """Create performance visualization charts"""
        fig, axes = plt.subplots(2, 2, figsize=(15, 10))
        
        # Slow queries chart
        if not report['slow_queries'].empty:
            top_queries = report['slow_queries'].head(10)
            axes[0, 0].barh(range(len(top_queries)), top_queries['total_time'])
            axes[0, 0].set_title('Top Slow Queries by Total Time')
            axes[0, 0].set_xlabel('Total Time (ms)')
        
        # Table sizes chart
        if not report['table_stats'].empty:
            top_tables = report['table_stats'].head(10)
            axes[0, 1].pie(top_tables['size_bytes'], labels=top_tables['tablename'])
            axes[0, 1].set_title('Largest Tables by Size')
        
        plt.tight_layout()
        plt.savefig(f"performance_report_{datetime.now().strftime('%Y%m%d_%H%M%S')}.png")
        plt.close()
```

## 🔧 Automation Scripts for Daily Operations

### 1. Scheduled Monitoring Script
```python
import schedule
import time
import asyncio

def setup_monitoring_schedule():
    """Setup automated monitoring schedule"""
    monitor = RDSMonitor()
    
    # Monitor every 5 minutes
    schedule.every(5).minutes.do(lambda: asyncio.run(run_health_checks(monitor)))
    
    # Daily backup at 2 AM
    schedule.every().day.at("02:00").do(run_daily_backup)
    
    # Weekly performance report on Sundays
    schedule.every().sunday.at("06:00").do(generate_weekly_report)
    
    while True:
        schedule.run_pending()
        time.sleep(60)

async def run_health_checks(monitor):
    """Run health checks for all databases"""
    instances = monitor.get_db_instances()
    
    for instance in instances:
        db_id = instance['DBInstanceIdentifier']
        health_report = await monitor.monitor_database_health(db_id)
        
        # Log or store health report
        print(f"Health check completed for {db_id}")
        if health_report['alerts']:
            print(f"Alerts generated: {len(health_report['alerts'])}")
```

## 📊 Learning Path for DBAs

### Week 1-2: Python Basics
- Python syntax and data structures
- Working with databases (psycopg2, pymysql)
- Error handling and logging

### Week 3-4: AWS Integration
- boto3 SDK fundamentals
- RDS and CloudWatch APIs
- SNS for alerting

### Week 5-6: Automation
- Scheduled tasks with schedule library
- Async programming for performance
- Configuration management

### Week 7-8: Advanced Topics
- Performance monitoring and analysis
- Data visualization with matplotlib
- CI/CD integration for scripts

## 💰 ROI for Python Skills

- **Efficiency**: 90% reduction in manual monitoring tasks
- **Reliability**: 95% fewer human errors in operations
- **Career Impact**: Essential skill for modern DBA roles
- **Salary Boost**: 25-30% increase with automation skills

---

*Next: [Bash Scripting Guide](./bash-scripting.md)*
