# 🌱 Roadmap DBA Junior - Cloud OnPrem AWS

## 🎯 Perfil del DBA Junior

**Experiencia:** 0-2 años  
**Objetivo:** Dominar fundamentos y operaciones básicas  
**Timeline:** 12-18 meses para avanzar a Semi-Senior  

---

## 📚 Fase 1: Fundamentos (Meses 1-3)

### 🐍 Python y Bash para DBAs

#### Python Básico para Automatización
**Semanas 1-2:**
- [ ] **Fundamentos Python**
  ```python
  # Conexión básica a MySQL
  import mysql.connector
  from datetime import datetime
  
  def connect_to_mysql():
      try:
          connection = mysql.connector.connect(
              host='localhost',
              database='testdb',
              user='admin',
              password='password'
          )
          
          if connection.is_connected():
              print("✅ Conexión exitosa a MySQL")
              return connection
              
      except Exception as e:
          print(f"❌ Error conectando: {e}")
          return None
  
  # Script básico de backup
  def backup_database(db_name):
      timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
      backup_file = f"{db_name}_backup_{timestamp}.sql"
      
      command = f"mysqldump -u admin -p {db_name} > {backup_file}"
      print(f"Ejecutando backup: {command}")
      
      return backup_file
  ```

- [ ] **Librerías Esenciales para DBAs**
  ```python
  # requirements.txt para DBAs
  mysql-connector-python==8.0.33
  psycopg2-binary==2.9.6
  pymongo==4.3.3
  boto3==1.26.137
  pandas==2.0.2
  sqlalchemy==2.0.15
  ```

#### Bash Scripting para Operaciones
**Semanas 3-4:**
- [ ] **Scripts Básicos de Administración**
  ```bash
  #!/bin/bash
  # backup_mysql.sh - Script básico de backup
  
  # Variables
  DB_HOST="localhost"
  DB_USER="admin"
  DB_PASS="password"
  BACKUP_DIR="/backups"
  DATE=$(date +%Y%m%d_%H%M%S)
  
  # Función de logging
  log_message() {
      echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a /var/log/db_backup.log
  }
  
  # Crear directorio de backup
  mkdir -p $BACKUP_DIR
  
  # Backup de todas las bases de datos
  log_message "Iniciando backup de MySQL"
  
  mysqldump -h $DB_HOST -u $DB_USER -p$DB_PASS \
            --all-databases \
            --single-transaction \
            --routines \
            --triggers > $BACKUP_DIR/mysql_backup_$DATE.sql
  
  if [ $? -eq 0 ]; then
      log_message "✅ Backup completado: mysql_backup_$DATE.sql"
      
      # Comprimir backup
      gzip $BACKUP_DIR/mysql_backup_$DATE.sql
      log_message "✅ Backup comprimido"
      
      # Subir a S3 (opcional)
      aws s3 cp $BACKUP_DIR/mysql_backup_$DATE.sql.gz \
                s3://my-db-backups/mysql/
      
  else
      log_message "❌ Error en backup"
      exit 1
  fi
  ```

- [ ] **Monitoreo con Bash**
  ```bash
  #!/bin/bash
  # monitor_mysql.sh - Monitoreo básico
  
  # Colores para output
  RED='\033[0;31m'
  GREEN='\033[0;32m'
  YELLOW='\033[1;33m'
  NC='\033[0m'
  
  # Función para verificar conexión
  check_mysql_connection() {
      mysql -h localhost -u admin -ppassword -e "SELECT 1;" > /dev/null 2>&1
      
      if [ $? -eq 0 ]; then
          echo -e "${GREEN}✅ MySQL está corriendo${NC}"
          return 0
      else
          echo -e "${RED}❌ MySQL no responde${NC}"
          return 1
      fi
  }
  
  # Verificar espacio en disco
  check_disk_space() {
      USAGE=$(df /var/lib/mysql | awk 'NR==2 {print $5}' | sed 's/%//')
      
      if [ $USAGE -gt 80 ]; then
          echo -e "${RED}⚠️  Espacio en disco: ${USAGE}%${NC}"
      elif [ $USAGE -gt 60 ]; then
          echo -e "${YELLOW}⚠️  Espacio en disco: ${USAGE}%${NC}"
      else
          echo -e "${GREEN}✅ Espacio en disco: ${USAGE}%${NC}"
      fi
  }
  
  # Verificar procesos activos
  check_active_processes() {
      PROCESSES=$(mysql -h localhost -u admin -ppassword \
                  -e "SHOW PROCESSLIST;" | wc -l)
      
      echo -e "${GREEN}📊 Procesos activos: $PROCESSES${NC}"
  }
  
  # Ejecutar verificaciones
  echo "🔍 Monitoreo MySQL - $(date)"
  echo "================================"
  check_mysql_connection
  check_disk_space  
  check_active_processes
  ```

### 🗄️ Bases de Datos Relacionales

#### MySQL/MariaDB Básico
**Semanas 5-6:**
- [ ] Instalación en Linux/Windows
- [ ] Configuración básica (my.cnf)
- [ ] Comandos básicos de conexión
- [ ] Crear/eliminar bases de datos y tablas

**Semanas 3-4:**
- [ ] Tipos de datos (INT, VARCHAR, DATE, etc.)
- [ ] Constraints (PRIMARY KEY, FOREIGN KEY, UNIQUE)
- [ ] Índices básicos (CREATE INDEX)
- [ ] Comandos DML (INSERT, UPDATE, DELETE, SELECT)

**Semanas 5-6:**
- [ ] JOINs básicos (INNER, LEFT, RIGHT)
- [ ] Funciones básicas (COUNT, SUM, AVG, MAX, MIN)
- [ ] GROUP BY y HAVING
- [ ] ORDER BY y LIMIT

**Proyecto Práctico:**
```sql
-- Crear base de datos de una tienda online
CREATE DATABASE tienda_online;
USE tienda_online;

CREATE TABLE productos (
    id INT PRIMARY KEY AUTO_INCREMENT,
    nombre VARCHAR(100) NOT NULL,
    precio DECIMAL(10,2),
    stock INT DEFAULT 0,
    categoria_id INT,
    fecha_creacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE categorias (
    id INT PRIMARY KEY AUTO_INCREMENT,
    nombre VARCHAR(50) NOT NULL,
    descripcion TEXT
);

-- Insertar datos de prueba
-- Crear consultas básicas
-- Implementar backup básico
```

#### PostgreSQL Básico
**Semanas 7-8:**
- [ ] Instalación y configuración
- [ ] Arquitectura básica (postmaster, backends)
- [ ] Comandos psql esenciales
- [ ] Diferencias con MySQL

**Semanas 9-10:**
- [ ] Tipos de datos específicos de PostgreSQL
- [ ] Arrays y JSON básico
- [ ] Vacuum y Analyze conceptos
- [ ] Roles y permisos

**Proyecto Práctico:**
```sql
-- Migrar la tienda online a PostgreSQL
-- Explorar tipos de datos únicos
-- Implementar backup con pg_dump
```

### ☁️ AWS Fundamentos

#### Conceptos Básicos AWS
**Semanas 11-12:**
- [ ] Crear cuenta AWS (Free Tier)
- [ ] Regiones y Availability Zones
- [ ] VPC básico (conceptos)
- [ ] Security Groups vs NACLs
- [ ] IAM Users, Groups, Roles

**Laboratorio Práctico:**
```bash
# Configurar AWS CLI
aws configure

# Crear usuario IAM para bases de datos
aws iam create-user --user-name dba-junior
aws iam create-group --group-name dba-group
aws iam add-user-to-group --user-name dba-junior --group-name dba-group
```

---

## 🔧 Fase 2: AWS RDS Básico (Meses 4-6)

### 🗄️ Amazon RDS

#### Creación y Configuración
**Mes 4:**
- [ ] Crear primera instancia RDS MySQL
- [ ] Entender tipos de instancia (db.t3.micro, etc.)
- [ ] Configurar Security Groups
- [ ] Conectar desde cliente local

**Laboratorio:**
```bash
# Crear instancia RDS MySQL
aws rds create-db-instance \
    --db-instance-identifier mi-primera-rds \
    --db-instance-class db.t3.micro \
    --engine mysql \
    --master-username admin \
    --master-user-password MiPassword123! \
    --allocated-storage 20 \
    --vpc-security-group-ids sg-12345678

# Conectar desde local
mysql -h mi-primera-rds.123456789012.us-east-1.rds.amazonaws.com \
      -u admin -p
```

#### Parameter Groups y Backups
**Mes 5:**
- [ ] Crear Parameter Groups personalizados
- [ ] Configurar automated backups
- [ ] Realizar manual snapshots
- [ ] Restore desde snapshot

**Configuraciones Básicas:**
```sql
-- Parameter Group para MySQL
[mysqld]
innodb_buffer_pool_size = {DBInstanceClassMemory*3/4}
max_connections = 100
slow_query_log = 1
long_query_time = 2
```

#### Multi-AZ y Read Replicas
**Mes 6:**
- [ ] Entender Multi-AZ (conceptos)
- [ ] Crear Read Replica
- [ ] Monitorear replication lag
- [ ] Failover testing básico

---

## 📊 Fase 3: Monitoreo y Operaciones (Meses 7-9)

### 📈 CloudWatch Básico

#### Métricas Esenciales
**Mes 7:**
- [ ] CPU Utilization
- [ ] Database Connections
- [ ] Free Storage Space
- [ ] Read/Write IOPS
- [ ] Read/Write Latency

**Dashboard Básico:**
```json
{
  "widgets": [
    {
      "type": "metric",
      "properties": {
        "metrics": [
          ["AWS/RDS", "CPUUtilization", "DBInstanceIdentifier", "mi-rds"]
        ],
        "period": 300,
        "stat": "Average",
        "region": "us-east-1",
        "title": "CPU Utilization"
      }
    }
  ]
}
```

#### Alertas Básicas
**Mes 8:**
- [ ] Crear alarmas para CPU > 80%
- [ ] Alertas para espacio en disco < 20%
- [ ] Notificaciones por SNS
- [ ] Logs de error básicos

#### Performance Insights
**Mes 9:**
- [ ] Habilitar Performance Insights
- [ ] Interpretar top SQL statements
- [ ] Identificar wait events básicos
- [ ] Correlacionar con métricas CloudWatch

---

## 🛠️ Fase 4: Herramientas y Automatización (Meses 10-12)

### 🔧 Herramientas de Administración

#### Clientes y Conectividad
**Mes 10:**
- [ ] MySQL Workbench avanzado
- [ ] pgAdmin para PostgreSQL
- [ ] SSH Tunneling para conexiones seguras
- [ ] Bastion hosts básicos

#### Infrastructure as Code (Terraform Básico)
**Mes 11:**
- [ ] **Conceptos de IaC**
  - ¿Por qué Infrastructure as Code?
  - Terraform vs CloudFormation vs CDK
  - Estado (state) y versionado
  - Beneficios para DBAs

- [ ] **Terraform Fundamentos**
  ```hcl
  # Primer archivo main.tf
  terraform {
    required_providers {
      aws = {
        source  = "hashicorp/aws"
        version = "~> 5.0"
      }
    }
  }
  
  provider "aws" {
    region = "us-east-1"
  }
  
  # Crear instancia RDS básica
  resource "aws_db_instance" "mysql_basic" {
    identifier = "mi-primera-rds-tf"
    
    engine         = "mysql"
    engine_version = "8.0"
    instance_class = "db.t3.micro"
    
    allocated_storage = 20
    storage_type     = "gp2"
    
    db_name  = "testdb"
    username = "admin"
    password = "password123!"
    
    skip_final_snapshot = true
    
    tags = {
      Name        = "Mi Primera RDS"
      Environment = "learning"
      CreatedBy   = "terraform"
    }
  }
  ```

- [ ] **Comandos Básicos Terraform**
  ```bash
  # Inicializar proyecto
  terraform init
  
  # Planificar cambios
  terraform plan
  
  # Aplicar cambios
  terraform apply
  
  # Ver estado actual
  terraform show
  
  # Destruir recursos
  terraform destroy
  ```

- [ ] **Variables y Outputs**
  ```hcl
  # variables.tf
  variable "db_password" {
    description = "Password for RDS instance"
    type        = string
    sensitive   = true
  }
  
  variable "environment" {
    description = "Environment name"
    type        = string
    default     = "dev"
  }
  
  # outputs.tf
  output "rds_endpoint" {
    description = "RDS instance endpoint"
    value       = aws_db_instance.mysql_basic.endpoint
  }
  
  output "rds_port" {
    description = "RDS instance port"
    value       = aws_db_instance.mysql_basic.port
  }
  ```

#### Scripts de Automatización
**Mes 12:**
```bash
#!/bin/bash
# Script básico de backup
DB_HOST="mi-rds.amazonaws.com"
DB_USER="admin"
DB_PASS="password"
BACKUP_DIR="/backups"
DATE=$(date +%Y%m%d_%H%M%S)

# Backup MySQL
mysqldump -h $DB_HOST -u $DB_USER -p$DB_PASS \
          --all-databases > $BACKUP_DIR/backup_$DATE.sql

# Comprimir
gzip $BACKUP_DIR/backup_$DATE.sql

# Subir a S3
aws s3 cp $BACKUP_DIR/backup_$DATE.sql.gz \
          s3://mi-bucket-backups/mysql/
```

#### Documentación y Procedimientos
**Mes 12:**
- [ ] Crear runbooks básicos
- [ ] Documentar procedimientos de backup/restore
- [ ] Crear checklist de tareas diarias
- [ ] Establecer proceso de change management

---

## 🎯 Proyectos Prácticos Integrales

### Proyecto 1: Automatización con Python y Bash
**Objetivo:** Crear suite de herramientas de automatización para DBA

**Componentes Python:**
```python
# db_manager.py - Gestor de bases de datos
import mysql.connector
import boto3
import json
from datetime import datetime

class DatabaseManager:
    def __init__(self, config_file):
        with open(config_file, 'r') as f:
            self.config = json.load(f)
    
    def health_check(self):
        """Verificar salud de todas las bases de datos"""
        results = {}
        
        for db_name, db_config in self.config['databases'].items():
            try:
                conn = mysql.connector.connect(**db_config)
                cursor = conn.cursor()
                
                # Verificar conexión
                cursor.execute("SELECT 1")
                
                # Obtener métricas básicas
                cursor.execute("SHOW GLOBAL STATUS LIKE 'Threads_connected'")
                connections = cursor.fetchone()[1]
                
                cursor.execute("SHOW GLOBAL STATUS LIKE 'Uptime'")
                uptime = cursor.fetchone()[1]
                
                results[db_name] = {
                    'status': 'healthy',
                    'connections': connections,
                    'uptime_hours': int(uptime) // 3600
                }
                
                conn.close()
                
            except Exception as e:
                results[db_name] = {
                    'status': 'error',
                    'error': str(e)
                }
        
        return results
    
    def backup_database(self, db_name):
        """Realizar backup de base de datos específica"""
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        backup_file = f"{db_name}_backup_{timestamp}.sql"
        
        # Ejecutar mysqldump
        import subprocess
        
        db_config = self.config['databases'][db_name]
        cmd = [
            'mysqldump',
            f"-h{db_config['host']}",
            f"-u{db_config['user']}",
            f"-p{db_config['password']}",
            db_config['database']
        ]
        
        with open(backup_file, 'w') as f:
            result = subprocess.run(cmd, stdout=f, stderr=subprocess.PIPE)
        
        if result.returncode == 0:
            # Subir a S3
            s3 = boto3.client('s3')
            s3.upload_file(backup_file, 'my-db-backups', f"mysql/{backup_file}")
            
            return {'status': 'success', 'file': backup_file}
        else:
            return {'status': 'error', 'error': result.stderr.decode()}

# config.json
{
    "databases": {
        "production": {
            "host": "prod-mysql.amazonaws.com",
            "user": "admin",
            "password": "secure_password",
            "database": "production_db"
        },
        "staging": {
            "host": "staging-mysql.amazonaws.com", 
            "user": "admin",
            "password": "staging_password",
            "database": "staging_db"
        }
    }
}
```

**Componentes Bash:**
```bash
#!/bin/bash
# dba_toolkit.sh - Toolkit completo para DBA

# Configuración
CONFIG_FILE="config.json"
LOG_FILE="/var/log/dba_toolkit.log"

# Funciones de utilidad
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a $LOG_FILE
}

# Menú principal
show_menu() {
    echo "================================"
    echo "🛠️  DBA Toolkit"
    echo "================================"
    echo "1. Health Check de todas las BDs"
    echo "2. Backup de BD específica"
    echo "3. Monitoreo en tiempo real"
    echo "4. Limpiar logs antiguos"
    echo "5. Verificar espacio en disco"
    echo "6. Salir"
    echo "================================"
}

# Función principal
main() {
    while true; do
        show_menu
        read -p "Selecciona una opción: " choice
        
        case $choice in
            1)
                log "Ejecutando health check"
                python3 -c "
from db_manager import DatabaseManager
import json
dm = DatabaseManager('$CONFIG_FILE')
results = dm.health_check()
print(json.dumps(results, indent=2))
"
                ;;
            2)
                read -p "Nombre de la BD: " db_name
                log "Iniciando backup de $db_name"
                python3 -c "
from db_manager import DatabaseManager
dm = DatabaseManager('$CONFIG_FILE')
result = dm.backup_database('$db_name')
print(result)
"
                ;;
            3)
                log "Iniciando monitoreo"
                ./monitor_mysql.sh
                ;;
            4)
                log "Limpiando logs antiguos"
                find /var/log -name "*.log" -mtime +7 -delete
                echo "✅ Logs antiguos eliminados"
                ;;
            5)
                df -h | grep -E "(Filesystem|/dev/)"
                ;;
            6)
                log "Saliendo del toolkit"
                exit 0
                ;;
            *)
                echo "❌ Opción inválida"
                ;;
        esac
        
        echo ""
        read -p "Presiona Enter para continuar..."
    done
}

main
```

**Entregables:**
- Suite completa de herramientas Python/Bash
- Configuración centralizada
- Logging y monitoreo
- Documentación de uso

### Proyecto 2: E-commerce Database
**Objetivo:** Crear sistema completo de BD para e-commerce

**Componentes:**
- Base de datos MySQL en RDS
- Tablas: usuarios, productos, pedidos, pagos
- Índices optimizados
- Backup automatizado
- Monitoreo básico

**Entregables:**
- Esquema de BD documentado
- Scripts de creación
- Procedimientos de backup
- Dashboard de monitoreo

### Proyecto 2: Migración OnPrem a Cloud
**Objetivo:** Migrar BD local a RDS

**Pasos:**
1. Análisis de BD existente
2. Sizing de instancia RDS
3. Migración con mysqldump
4. Validación de datos
5. Configuración de monitoreo

### Proyecto 3: Infrastructure as Code con Terraform
**Objetivo:** Crear infraestructura de BD usando Terraform

**Pasos:**
1. Crear proyecto Terraform para RDS
2. Implementar variables y outputs
3. Crear múltiples entornos (dev, staging)
4. Versionado con Git
5. Documentar el proceso

**Entregables:**
- Código Terraform versionado
- Documentación de deployment
- Comparación manual vs IaC
- Plan de rollback

### Proyecto 4: Disaster Recovery Básico
**Objetivo:** Implementar estrategia básica de DR

**Componentes:**
- Multi-AZ configuration
- Cross-region snapshots
- Procedimientos de restore
- Testing de failover

---

## 📋 Checklist de Competencias Junior

### Conocimientos Técnicos
- [ ] **Python básico para automatización de DBAs**
- [ ] **Bash scripting para operaciones de BD**
- [ ] SQL básico a intermedio
- [ ] Administración básica MySQL/PostgreSQL
- [ ] Conceptos de AWS (VPC, IAM, EC2 básico)
- [ ] RDS creation y management
- [ ] CloudWatch monitoring básico
- [ ] Backup y restore procedures
- [ ] **Terraform básico para infraestructura de BD**
- [ ] **Git para versionado de código IaC**

### Habilidades Prácticas
- [ ] **Escribir scripts Python para automatización de BD**
- [ ] **Crear scripts Bash para operaciones diarias**
- [ ] Crear y configurar instancias RDS
- [ ] Conectar aplicaciones a RDS
- [ ] Realizar backups manuales y automatizados
- [ ] Interpretar métricas básicas
- [ ] Resolver problemas de conectividad
- [ ] Documentar procedimientos
- [ ] **Crear infraestructura de BD con Terraform**
- [ ] **Versionar y gestionar código IaC**

### Soft Skills
- [ ] Comunicación técnica clara
- [ ] Documentación detallada
- [ ] Seguimiento de procedimientos
- [ ] Escalación apropiada de problemas
- [ ] Trabajo en equipo
- [ ] Aprendizaje continuo

---

## 📚 Recursos de Estudio Específicos

### Cursos Online
1. **AWS Training: Cloud Practitioner** (40 horas)
2. **MySQL for Developers** - PlanetScale (20 horas)
3. **PostgreSQL Administration** - Udemy (30 horas)
4. **AWS RDS Deep Dive** - A Cloud Guru (15 horas)

### Libros
1. **"Automate the Boring Stuff with Python"** - Al Sweigart (Gratis online)
2. **"Learning the Bash Shell"** - Cameron Newham
3. **"Learning MySQL"** - Seyed Tahaghoghi
4. **"PostgreSQL: Up and Running"** - Regina Obe
5. **"AWS Certified Cloud Practitioner Study Guide"**
6. **"Terraform: Up & Running"** - Yevgeniy Brikman (Capítulos básicos)

### Práctica Hands-on
1. **AWS Free Tier** - 12 meses gratis
2. **MySQL/PostgreSQL local** - Docker containers
3. **GitHub** - Portfolio de proyectos
4. **AWS Labs** - Guided tutorials

### Certificaciones Objetivo
1. **AWS Cloud Practitioner** (Mes 6)
2. **AWS Solutions Architect Associate** (Mes 12)
3. **MySQL 8.0 Database Administrator** (Mes 9)

---

## 📅 Timeline Detallado

### Mes 1: Python y Bash Fundamentos
- Semana 1-2: Python básico para DBAs
- Semana 3-4: Bash scripting para operaciones

### Mes 2: MySQL Fundamentos
- Semana 1-2: Instalación y configuración
- Semana 3-4: SQL básico y DDL

### Mes 3: MySQL Intermedio + PostgreSQL
- Semana 1-2: DML avanzado y JOINs
- Semana 3-4: PostgreSQL básico y AWS intro

### Mes 4: RDS Básico
- Semana 1-2: Crear primera instancia
- Semana 3-4: Conectividad y security

### Mes 5: RDS Intermedio
- Semana 1-2: Parameter groups
- Semana 3-4: Backups y snapshots

### Mes 6: Alta Disponibilidad
- Semana 1-2: Multi-AZ concepts
- Semana 3-4: Read replicas

### Mes 7-8: Monitoreo
- CloudWatch setup
- Performance Insights
- Alerting básico

### Mes 9-10: Herramientas
- Clientes avanzados
- Terraform básico para DBAs

### Mes 11-12: Proyectos
- Proyecto integral
- Preparación certificación

---

## 🎯 Métricas de Éxito

### Técnicas
- [ ] 95% uptime en proyectos personales
- [ ] Tiempo de restore < 30 minutos
- [ ] Documentación completa de procedimientos
- [ ] 0 incidentes de seguridad

### Profesionales
- [ ] Certificación AWS Cloud Practitioner
- [ ] Portfolio con 3 proyectos completos
- [ ] Contribuciones a documentación del equipo
- [ ] Feedback positivo de mentores

### Preparación para Semi-Senior
- [ ] Puede trabajar independientemente en tareas básicas
- [ ] Entiende arquitecturas simples
- [ ] Puede explicar decisiones técnicas
- [ ] Listo para liderar proyectos pequeños

---

**¡Tu journey como DBA Junior comienza aquí!** 🚀

*Roadmap Junior - Actualizado Agosto 2025*
