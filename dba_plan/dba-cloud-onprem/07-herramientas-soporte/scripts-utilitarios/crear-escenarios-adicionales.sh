#!/bin/bash

# Script para crear escenarios adicionales de diagnóstico
# Autor: DBA Training Platform

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ESCENARIOS_DIR="$(dirname "$SCRIPT_DIR")/escenarios-diagnostico"

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${BLUE}ℹ️ $1${NC}"
}

log_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

log_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Función para crear escenario de backup y recovery
create_backup_recovery_scenario() {
    local scenario_dir="$ESCENARIOS_DIR/mysql/escenario-06-backup-recovery"
    
    log_info "Creando escenario de Backup y Recovery"
    
    mkdir -p "$scenario_dir"/{simuladores,init-scripts,prometheus,grafana/{datasources,dashboards},scripts-diagnostico,config}
    
    # Docker Compose
    cat > "$scenario_dir/docker-compose.yml" << 'EOF'
version: '3.8'

services:
  mysql-db:
    image: mysql:8.0
    container_name: escenario-mysql
    environment:
      MYSQL_ROOT_PASSWORD: dba2024!
      MYSQL_DATABASE: training_db
      MYSQL_USER: app_user
      MYSQL_PASSWORD: app_pass
    ports:
      - "3306:3306"
    volumes:
      - ./init-scripts:/docker-entrypoint-initdb.d
      - ./config/my.cnf:/etc/mysql/conf.d/my.cnf
      - mysql_data:/var/lib/mysql
      - backup_volume:/backup
    networks:
      - db-network

  simulator:
    build: ./simuladores
    container_name: escenario-simulator
    depends_on:
      - mysql-db
    environment:
      DB_HOST: mysql-db
      DB_USER: app_user
      DB_PASS: app_pass
      DB_NAME: training_db
    volumes:
      - backup_volume:/backup
    networks:
      - db-network

  prometheus:
    image: prom/prometheus:latest
    container_name: prometheus
    ports:
      - "9090:9090"
    volumes:
      - ./prometheus:/etc/prometheus
    command:
      - '--config.file=/etc/prometheus/prometheus.yml'
      - '--storage.tsdb.path=/prometheus'
      - '--web.console.libraries=/etc/prometheus/console_libraries'
      - '--web.console.templates=/etc/prometheus/consoles'
      - '--web.enable-lifecycle'
    networks:
      - db-network

  grafana:
    image: grafana/grafana:latest
    container_name: grafana
    ports:
      - "3000:3000"
    volumes:
      - ./grafana/datasources:/etc/grafana/provisioning/datasources
      - ./grafana/dashboards:/etc/grafana/provisioning/dashboards
    environment:
      - GF_SECURITY_ADMIN_PASSWORD=admin123
    networks:
      - db-network

  mysql-exporter:
    image: prom/mysqld-exporter:latest
    container_name: mysql-exporter
    ports:
      - "9104:9104"
    environment:
      - DATA_SOURCE_NAME=app_user:app_pass@(mysql-db:3306)/training_db
    depends_on:
      - mysql-db
    networks:
      - db-network

volumes:
  mysql_data:
  backup_volume:

networks:
  db-network:
    driver: bridge
EOF

    # Problema descripción
    cat > "$scenario_dir/problema-descripcion.md" << 'EOF'
# Escenario MySQL 06: Disaster Recovery Crítico
## 🔴 Nivel: Avanzado | Tiempo estimado: 60 minutos

### 📋 Contexto del Problema

**Empresa:** FinTech "SecureBank"
**Sistema:** Base de datos transaccional crítica
**Horario:** Domingo 03:00 AM - Mantenimiento programado FALLÓ
**Urgencia:** CRÍTICA - Pérdida de datos detectada

### 🚨 Síntomas Reportados

**Reporte del equipo de infraestructura:**
```
"El proceso de mantenimiento programado falló a las 03:15 AM.
Se detectó corrupción en varios archivos de datos.
Los backups automáticos de las últimas 48 horas están corruptos.
El último backup válido es de hace 72 horas.
Necesitamos recuperar las transacciones de los últimos 3 días."
```

**Estado actual:**
- ⚠️ Base de datos no inicia correctamente
- ⚠️ Archivos de datos corruptos detectados
- ⚠️ Binary logs disponibles desde el último backup válido
- ⚠️ Pérdida potencial: 72 horas de transacciones

### 📊 Datos Disponibles

**Recursos para recovery:**
- Backup completo válido (72 horas atrás)
- Binary logs completos desde el backup
- Archivos de configuración
- Scripts de recovery personalizados

**Tablas críticas afectadas:**
- `transactions` - Transacciones financieras
- `accounts` - Cuentas de usuarios
- `audit_log` - Log de auditoría
- `balances` - Saldos actuales

### 🎯 Tu Misión

Como DBA Senior de Disaster Recovery, debes:

1. **Evaluar el daño** y determinar estrategia de recovery
2. **Restaurar desde backup** el último punto válido
3. **Aplicar binary logs** para recuperar transacciones perdidas
4. **Verificar integridad** de datos recuperados
5. **Documentar el proceso** para auditoría

### 📈 Criterios de Éxito

**Recovery exitoso cuando:**
- ✅ Base de datos operativa al 100%
- ✅ Todas las transacciones recuperadas
- ✅ Integridad de datos verificada
- ✅ RTO < 4 horas (objetivo: 2 horas)
- ✅ RPO = 0 (sin pérdida de datos)

### 🔧 Herramientas Disponibles

**Scripts de recovery:**
- `backup-restore.sh` - Restauración automatizada
- `binlog-recovery.sh` - Aplicación de binary logs
- `integrity-check.sh` - Verificación de integridad
- `performance-test.sh` - Pruebas de rendimiento post-recovery

### ⏰ Cronómetro

**Tiempo límite:** 60 minutos
**RTO objetivo:** 2 horas
**Puntuación máxima:** 150 puntos

---

**¿Listo para el recovery?** 
Ejecuta: `docker-compose up -d` y comienza el proceso de recuperación.
EOF

    # Simulador de corrupción
    cat > "$scenario_dir/simuladores/backup_recovery_simulator.py" << 'EOF'
#!/usr/bin/env python3
"""
MySQL Backup & Recovery Simulator
Simulates data corruption and recovery scenarios
"""

import os
import sys
import time
import logging
import mysql.connector
from mysql.connector import Error
import subprocess
import random
from datetime import datetime, timedelta

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

class BackupRecoverySimulator:
    def __init__(self):
        self.db_config = {
            'host': os.getenv('DB_HOST', 'localhost'),
            'user': os.getenv('DB_USER', 'app_user'),
            'password': os.getenv('DB_PASS', 'app_pass'),
            'database': os.getenv('DB_NAME', 'training_db'),
            'port': int(os.getenv('DB_PORT', '3306'))
        }
        
    def create_test_data(self):
        """Create test data for backup scenario"""
        try:
            connection = mysql.connector.connect(**self.db_config)
            cursor = connection.cursor()
            
            # Create tables
            cursor.execute("""
                CREATE TABLE IF NOT EXISTS transactions (
                    id INT AUTO_INCREMENT PRIMARY KEY,
                    account_id INT NOT NULL,
                    amount DECIMAL(10,2) NOT NULL,
                    transaction_type ENUM('DEBIT', 'CREDIT') NOT NULL,
                    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                    INDEX idx_account_id (account_id),
                    INDEX idx_created_at (created_at)
                )
            """)
            
            cursor.execute("""
                CREATE TABLE IF NOT EXISTS accounts (
                    id INT AUTO_INCREMENT PRIMARY KEY,
                    account_number VARCHAR(20) UNIQUE NOT NULL,
                    balance DECIMAL(12,2) DEFAULT 0.00,
                    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
                )
            """)
            
            # Insert test accounts
            for i in range(1000):
                account_number = f"ACC{i:06d}"
                initial_balance = random.uniform(1000, 50000)
                cursor.execute(
                    "INSERT IGNORE INTO accounts (account_number, balance) VALUES (%s, %s)",
                    (account_number, initial_balance)
                )
            
            # Insert test transactions
            for i in range(10000):
                account_id = random.randint(1, 1000)
                amount = random.uniform(10, 1000)
                transaction_type = random.choice(['DEBIT', 'CREDIT'])
                
                cursor.execute(
                    "INSERT INTO transactions (account_id, amount, transaction_type) VALUES (%s, %s, %s)",
                    (account_id, amount, transaction_type)
                )
            
            connection.commit()
            logger.info("Test data created successfully")
            
        except Error as e:
            logger.error(f"Error creating test data: {e}")
        finally:
            if connection.is_connected():
                cursor.close()
                connection.close()
    
    def simulate_corruption(self):
        """Simulate data corruption"""
        logger.info("Simulating data corruption...")
        
        try:
            connection = mysql.connector.connect(**self.db_config)
            cursor = connection.cursor()
            
            # Simulate corruption by dropping some data
            cursor.execute("DELETE FROM transactions WHERE id % 7 = 0")
            cursor.execute("UPDATE accounts SET balance = -999999 WHERE id % 13 = 0")
            
            connection.commit()
            logger.info("Data corruption simulated")
            
        except Error as e:
            logger.error(f"Error simulating corruption: {e}")
        finally:
            if connection.is_connected():
                cursor.close()
                connection.close()
    
    def create_backup(self):
        """Create a backup"""
        logger.info("Creating backup...")
        
        backup_file = f"/backup/backup_{datetime.now().strftime('%Y%m%d_%H%M%S')}.sql"
        
        cmd = [
            'mysqldump',
            f'--host={self.db_config["host"]}',
            f'--user={self.db_config["user"]}',
            f'--password={self.db_config["password"]}',
            '--single-transaction',
            '--routines',
            '--triggers',
            '--flush-logs',
            '--master-data=2',
            self.db_config['database']
        ]
        
        try:
            with open(backup_file, 'w') as f:
                subprocess.run(cmd, stdout=f, check=True)
            logger.info(f"Backup created: {backup_file}")
            return backup_file
        except subprocess.CalledProcessError as e:
            logger.error(f"Backup failed: {e}")
            return None
    
    def run_scenario(self):
        """Run the complete backup/recovery scenario"""
        logger.info("Starting Backup & Recovery scenario")
        
        # Step 1: Create initial data
        self.create_test_data()
        time.sleep(2)
        
        # Step 2: Create a "good" backup
        backup_file = self.create_backup()
        time.sleep(2)
        
        # Step 3: Add more data (this will be "lost")
        logger.info("Adding additional data that will be lost...")
        try:
            connection = mysql.connector.connect(**self.db_config)
            cursor = connection.cursor()
            
            for i in range(1000):
                account_id = random.randint(1, 1000)
                amount = random.uniform(10, 1000)
                transaction_type = random.choice(['DEBIT', 'CREDIT'])
                
                cursor.execute(
                    "INSERT INTO transactions (account_id, amount, transaction_type) VALUES (%s, %s, %s)",
                    (account_id, amount, transaction_type)
                )
            
            connection.commit()
            logger.info("Additional data added")
            
        except Error as e:
            logger.error(f"Error adding additional data: {e}")
        finally:
            if connection.is_connected():
                cursor.close()
                connection.close()
        
        time.sleep(2)
        
        # Step 4: Simulate corruption
        self.simulate_corruption()
        
        logger.info("Scenario setup complete. Database is now 'corrupted'.")
        logger.info("Your mission: Restore from backup and recover all data.")
        logger.info(f"Available backup: {backup_file}")

if __name__ == "__main__":
    simulator = BackupRecoverySimulator()
    simulator.run_scenario()
    
    # Keep running to maintain the scenario
    while True:
        time.sleep(60)
        logger.info("Scenario running... Waiting for recovery actions.")
EOF

    # Dockerfile
    cat > "$scenario_dir/simuladores/Dockerfile" << 'EOF'
FROM python:3.9-slim

WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y \
    default-mysql-client \
    && rm -rf /var/lib/apt/lists/*

# Copy requirements
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy code
COPY . .

# Command
CMD ["python", "backup_recovery_simulator.py"]
EOF

    # Requirements
    cat > "$scenario_dir/simuladores/requirements.txt" << 'EOF'
mysql-connector-python==8.0.33
prometheus-client==0.17.1
psutil==5.9.5
EOF

    # Configuración MySQL
    cat > "$scenario_dir/config/my.cnf" << 'EOF'
[mysqld]
# Binary logging for point-in-time recovery
log-bin=mysql-bin
binlog-format=ROW
expire_logs_days=7
max_binlog_size=100M

# General settings
innodb_buffer_pool_size=256M
innodb_log_file_size=64M
innodb_flush_log_at_trx_commit=1
sync_binlog=1

# Backup-friendly settings
innodb_fast_shutdown=0
EOF

    # Scripts de diagnóstico
    cat > "$scenario_dir/scripts-diagnostico/backup-restore.sh" << 'EOF'
#!/bin/bash

# Backup and Restore Script for MySQL
# Usage: ./backup-restore.sh [backup|restore] [file]

set -e

DB_HOST=${DB_HOST:-mysql-db}
DB_USER=${DB_USER:-app_user}
DB_PASS=${DB_PASS:-app_pass}
DB_NAME=${DB_NAME:-training_db}

backup() {
    local backup_file="/backup/manual_backup_$(date +%Y%m%d_%H%M%S).sql"
    echo "Creating backup: $backup_file"
    
    mysqldump \
        --host="$DB_HOST" \
        --user="$DB_USER" \
        --password="$DB_PASS" \
        --single-transaction \
        --routines \
        --triggers \
        --flush-logs \
        --master-data=2 \
        "$DB_NAME" > "$backup_file"
    
    echo "Backup completed: $backup_file"
}

restore() {
    local backup_file="$1"
    
    if [[ ! -f "$backup_file" ]]; then
        echo "Error: Backup file not found: $backup_file"
        exit 1
    fi
    
    echo "Restoring from: $backup_file"
    
    mysql \
        --host="$DB_HOST" \
        --user="$DB_USER" \
        --password="$DB_PASS" \
        "$DB_NAME" < "$backup_file"
    
    echo "Restore completed"
}

case "$1" in
    backup)
        backup
        ;;
    restore)
        restore "$2"
        ;;
    *)
        echo "Usage: $0 [backup|restore] [file]"
        exit 1
        ;;
esac
EOF

    chmod +x "$scenario_dir/scripts-diagnostico/backup-restore.sh"

    # Configuración de evaluación
    cat > "$scenario_dir/evaluacion-config.yml" << 'EOF'
scenario: "backup-recovery"
max_score: 150
time_limit: 3600  # 60 minutes

evaluation_criteria:
  - name: "Database Restoration"
    weight: 30
    description: "Successfully restore database from backup"
    
  - name: "Data Integrity"
    weight: 25
    description: "Verify all data is intact after recovery"
    
  - name: "Binary Log Recovery"
    weight: 25
    description: "Apply binary logs to recover lost transactions"
    
  - name: "Performance Verification"
    weight: 10
    description: "Ensure database performance is restored"
    
  - name: "Documentation"
    weight: 10
    description: "Document recovery process and lessons learned"

hints:
  - "Check available backups in /backup directory"
  - "Use binary logs for point-in-time recovery"
  - "Verify data integrity after restoration"
EOF

    log_success "Escenario Backup & Recovery creado"
}

# Función para crear escenario de alta disponibilidad
create_high_availability_scenario() {
    local scenario_dir="$ESCENARIOS_DIR/mysql/escenario-07-high-availability"
    
    log_info "Creando escenario de Alta Disponibilidad"
    
    mkdir -p "$scenario_dir"/{simuladores,init-scripts,prometheus,grafana/{datasources,dashboards},scripts-diagnostico,config}
    
    # Docker Compose con replicación
    cat > "$scenario_dir/docker-compose.yml" << 'EOF'
version: '3.8'

services:
  mysql-master:
    image: mysql:8.0
    container_name: mysql-master
    environment:
      MYSQL_ROOT_PASSWORD: dba2024!
      MYSQL_DATABASE: training_db
      MYSQL_USER: app_user
      MYSQL_PASSWORD: app_pass
      MYSQL_REPLICATION_USER: repl_user
      MYSQL_REPLICATION_PASSWORD: repl_pass
    ports:
      - "3306:3306"
    volumes:
      - ./init-scripts:/docker-entrypoint-initdb.d
      - ./config/master.cnf:/etc/mysql/conf.d/mysql.cnf
    networks:
      - db-network

  mysql-slave1:
    image: mysql:8.0
    container_name: mysql-slave1
    environment:
      MYSQL_ROOT_PASSWORD: dba2024!
      MYSQL_DATABASE: training_db
      MYSQL_USER: app_user
      MYSQL_PASSWORD: app_pass
    ports:
      - "3307:3306"
    volumes:
      - ./config/slave.cnf:/etc/mysql/conf.d/mysql.cnf
    depends_on:
      - mysql-master
    networks:
      - db-network

  mysql-slave2:
    image: mysql:8.0
    container_name: mysql-slave2
    environment:
      MYSQL_ROOT_PASSWORD: dba2024!
      MYSQL_DATABASE: training_db
      MYSQL_USER: app_user
      MYSQL_PASSWORD: app_pass
    ports:
      - "3308:3306"
    volumes:
      - ./config/slave.cnf:/etc/mysql/conf.d/mysql.cnf
    depends_on:
      - mysql-master
    networks:
      - db-network

  haproxy:
    image: haproxy:2.4
    container_name: haproxy
    ports:
      - "3309:3306"
      - "8080:8080"
    volumes:
      - ./config/haproxy.cfg:/usr/local/etc/haproxy/haproxy.cfg
    depends_on:
      - mysql-master
      - mysql-slave1
      - mysql-slave2
    networks:
      - db-network

  simulator:
    build: ./simuladores
    container_name: escenario-simulator
    depends_on:
      - mysql-master
      - mysql-slave1
      - mysql-slave2
    environment:
      DB_HOST: haproxy
      DB_USER: app_user
      DB_PASS: app_pass
      DB_NAME: training_db
    networks:
      - db-network

networks:
  db-network:
    driver: bridge
EOF

    # Configuración HAProxy
    cat > "$scenario_dir/config/haproxy.cfg" << 'EOF'
global
    daemon
    maxconn 256

defaults
    mode tcp
    timeout connect 5000ms
    timeout client 50000ms
    timeout server 50000ms

frontend mysql_frontend
    bind *:3306
    default_backend mysql_backend

backend mysql_backend
    balance roundrobin
    option mysql-check user haproxy_check
    server mysql-master mysql-master:3306 check
    server mysql-slave1 mysql-slave1:3306 check backup
    server mysql-slave2 mysql-slave2:3306 check backup

listen stats
    bind *:8080
    stats enable
    stats uri /stats
    stats refresh 30s
EOF

    # Configuración Master
    cat > "$scenario_dir/config/master.cnf" << 'EOF'
[mysqld]
server-id=1
log-bin=mysql-bin
binlog-format=ROW
gtid-mode=ON
enforce-gtid-consistency=ON
log-slave-updates=ON
binlog-do-db=training_db
EOF

    # Configuración Slave
    cat > "$scenario_dir/config/slave.cnf" << 'EOF'
[mysqld]
server-id=2
relay-log=mysql-relay-bin
log-bin=mysql-bin
binlog-format=ROW
gtid-mode=ON
enforce-gtid-consistency=ON
log-slave-updates=ON
read-only=ON
EOF

    log_success "Escenario Alta Disponibilidad creado"
}

# Función para crear escenario de seguridad
create_security_scenario() {
    local scenario_dir="$ESCENARIOS_DIR/mysql/escenario-08-security-breach"
    
    log_info "Creando escenario de Seguridad"
    
    mkdir -p "$scenario_dir"/{simuladores,init-scripts,prometheus,grafana/{datasources,dashboards},scripts-diagnostico,config}
    
    # Problema descripción
    cat > "$scenario_dir/problema-descripcion.md" << 'EOF'
# Escenario MySQL 08: Brecha de Seguridad
## 🔴 Nivel: Avanzado | Tiempo estimado: 45 minutos

### 📋 Contexto del Problema

**Empresa:** E-commerce "ShopSecure"
**Sistema:** Base de datos de usuarios y transacciones
**Horario:** Martes 14:30 - Horario comercial pico
**Urgencia:** CRÍTICA - Posible brecha de seguridad detectada

### 🚨 Síntomas Reportados

**Reporte del equipo de seguridad:**
```
"Se detectaron patrones de acceso anómalos en la base de datos.
Múltiples intentos de login fallidos desde IPs sospechosas.
Consultas SQL inusuales en logs de auditoría.
Posible inyección SQL detectada en aplicación web.
Datos sensibles potencialmente comprometidos."
```

**Indicadores de compromiso:**
- ⚠️ 500+ intentos de login fallidos en 1 hora
- ⚠️ Consultas SELECT masivas en tabla de usuarios
- ⚠️ Accesos desde IPs geográficamente dispersas
- ⚠️ Patrones de SQL injection en logs de aplicación

### 🎯 Tu Misión

Como DBA de Seguridad, debes:

1. **Investigar la brecha** y determinar el alcance
2. **Asegurar la base de datos** inmediatamente
3. **Identificar datos comprometidos**
4. **Implementar medidas de seguridad** adicionales
5. **Documentar el incidente** para auditoría

### 📈 Criterios de Éxito

**Respuesta exitosa cuando:**
- ✅ Brecha contenida y accesos bloqueados
- ✅ Alcance del compromiso determinado
- ✅ Medidas de seguridad implementadas
- ✅ Datos sensibles protegidos
- ✅ Plan de remediación documentado

### 🔧 Herramientas Disponibles

**Scripts de seguridad:**
- `security-audit.sh` - Auditoría de seguridad
- `access-analyzer.py` - Análisis de patrones de acceso
- `sql-injection-detector.py` - Detector de inyecciones SQL
- `user-privilege-audit.sh` - Auditoría de privilegios

### ⏰ Cronómetro

**Tiempo límite:** 45 minutos
**Puntuación máxima:** 120 puntos

---

**¿Listo para la investigación?** 
Ejecuta: `docker-compose up -d` y comienza la investigación de seguridad.
EOF

    log_success "Escenario Seguridad creado"
}

# Función principal
main() {
    echo "============================================================================"
    echo "🚀 CREACIÓN DE ESCENARIOS ADICIONALES"
    echo "============================================================================"
    
    # Crear escenarios adicionales
    create_backup_recovery_scenario
    create_high_availability_scenario
    create_security_scenario
    
    echo "============================================================================"
    echo "📊 RESUMEN"
    echo "============================================================================"
    log_success "3 escenarios adicionales creados:"
    echo "  - escenario-06-backup-recovery (Disaster Recovery)"
    echo "  - escenario-07-high-availability (Alta Disponibilidad)"
    echo "  - escenario-08-security-breach (Seguridad)"
    echo ""
    log_info "Los escenarios están listos para usar"
    log_info "Ejecuta la validación para verificar: ./validar-funcionalidad-escenarios.sh"
}

# Ejecutar función principal
main "$@"
