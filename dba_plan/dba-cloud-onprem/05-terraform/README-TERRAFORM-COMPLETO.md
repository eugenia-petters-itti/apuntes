# 🏗️ DBA Training System - Infraestructura Terraform Completa

## 📋 Descripción General

Esta carpeta contiene la infraestructura completa como código (IaC) para el **Sistema de Entrenamiento DBA**, diseñada para soportar 15 escenarios de diagnóstico across MySQL, PostgreSQL, y MongoDB con un enfoque híbrido OnPrem + Cloud.

## 🎯 Características Principales

- **Infraestructura Modular**: Módulos Terraform reutilizables y mantenibles
- **Seguridad Integrada**: Security groups, IAM roles, y encriptación por defecto
- **Monitoreo Completo**: Grafana, Prometheus, CloudWatch integrados
- **Automatización**: Scripts de configuración y validación automatizados
- **Escalabilidad**: Soporte para hasta 100 estudiantes concurrentes
- **Optimización de Costos**: Configuraciones optimizadas para entrenamiento

## 📁 Estructura de Archivos

```
05-terraform/
├── main.tf                     # Configuración principal y módulos
├── variables.tf                # Variables de configuración
├── outputs.tf                  # Outputs de infraestructura
├── security-groups.tf          # Grupos de seguridad
├── iam.tf                      # Roles y políticas IAM
├── modules.tf                  # Definición de módulos
├── terraform.tfvars.example    # Ejemplo de variables
├── DEPLOYMENT-GUIDE.md         # Guía completa de despliegue
├── validate-deployment.sh      # Script de validación
├── modules/
│   ├── bastion/               # Módulo del host bastion
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── userdata.sh        # Script de configuración avanzado
│   ├── documentdb/            # Módulo DocumentDB
│   │   ├── main.tf
│   │   └── variables.tf
│   ├── student-environments/   # Módulo entornos estudiantes
│   ├── monitoring/            # Módulo monitoreo
│   └── automation/            # Módulo automatización
└── lab_infrastructure.tf      # Configuración legacy (mantener)
```

## 🚀 Recursos Desplegados

### **Infraestructura de Red**
- **VPC**: Red privada virtual con subnets públicas, privadas y de base de datos
- **Security Groups**: Configuración granular de acceso por servicio
- **NAT Gateway**: Acceso a internet para subnets privadas
- **VPC Endpoints**: Acceso seguro a servicios AWS

### **Bases de Datos**
```hcl
# MySQL RDS
- Engine: MySQL 8.0
- Instance: db.t3.micro (configurable)
- Storage: 20GB con auto-scaling hasta 100GB
- Backup: 7 días (configurable)
- Performance Insights: Habilitado
- Enhanced Monitoring: Habilitado

# PostgreSQL RDS  
- Engine: PostgreSQL 15.4
- Instance: db.t3.micro (configurable)
- Storage: 20GB con auto-scaling hasta 100GB
- Backup: 7 días (configurable)
- Performance Insights: Habilitado
- Enhanced Monitoring: Habilitado

# DocumentDB Cluster
- Engine: DocumentDB 5.0
- Instance: db.t3.medium (configurable)
- Cluster Size: 1-16 instancias
- Backup: 5 días (configurable)
- Audit Logs: Habilitado
- Profiler: Habilitado
```

### **Compute y Aplicaciones**
```hcl
# Bastion Host
- Instance: t3.medium
- OS: Amazon Linux 2
- Tools: Grafana, Prometheus, Jupyter, Database clients
- Storage: 50GB EBS encriptado
- Public IP: Elastic IP asignada

# Student Environments (Opcional)
- Auto Scaling Group
- Instance: t3.small
- Max Students: 20 (configurable hasta 100)
- Private Subnets: Acceso vía bastion
```

### **Monitoreo y Observabilidad**
```hcl
# Grafana Dashboard
- Port: 3000
- Credentials: admin/dba-training-2024
- Dashboards: Pre-configurados para DBA scenarios

# Prometheus Metrics
- Port: 9090  
- Exporters: Node, MySQL, PostgreSQL, MongoDB
- Retention: 15 días

# CloudWatch Integration
- Log Groups: Centralizados por servicio
- Alarms: CPU, Memory, Connections, Storage
- Retention: 14 días (configurable)

# Jupyter Notebooks
- Port: 8888
- Token: dba-training-2024
- Environment: Python 3 con librerías DBA
```

## ⚙️ Configuración y Despliegue

### **1. Prerrequisitos**
```bash
# Software requerido
terraform --version  # >= 1.0
aws --version        # >= 2.0
git --version

# Configuración AWS
aws configure
aws sts get-caller-identity

# Key Pair (debe existir en AWS)
aws ec2 describe-key-pairs --key-names your-key-name
```

### **2. Configuración de Variables**
```bash
# Copiar archivo de ejemplo
cp terraform.tfvars.example terraform.tfvars

# Editar variables críticas
vim terraform.tfvars
```

**Variables Críticas:**
```hcl
# terraform.tfvars
key_name = "your-existing-key-pair"  # OBLIGATORIO
aws_region = "us-east-1"
environment = "training"
max_students = 20

# Seguridad - IMPORTANTE: Restringir en producción
allowed_cidr_blocks = ["your.ip.address/32"]

# Configuración de instancias
bastion_instance_type = "t3.medium"
db_instance_class = "db.t3.micro"
```

### **3. Despliegue Paso a Paso**
```bash
# 1. Inicializar Terraform
terraform init

# 2. Validar configuración
terraform validate

# 3. Revisar plan de despliegue
terraform plan

# 4. Aplicar configuración (15-20 minutos)
terraform apply

# 5. Validar despliegue
./validate-deployment.sh
```

## 📊 Información de Acceso

### **Outputs Principales**
```bash
# Ver todos los outputs
terraform output

# Información específica
terraform output bastion_public_ip
terraform output web_access_urls
terraform output database_credentials  # Sensible
```

### **URLs de Acceso**
```bash
# Obtener IP del bastion
BASTION_IP=$(terraform output -raw bastion_public_ip)

# URLs principales
echo "Training Portal: http://$BASTION_IP"
echo "Grafana: http://$BASTION_IP:3000"
echo "Prometheus: http://$BASTION_IP:9090"  
echo "Jupyter: http://$BASTION_IP:8888"
```

### **Conexión SSH**
```bash
# Conectar al bastion
ssh -i your-key.pem ec2-user@$BASTION_IP

# Scripts de conexión a bases de datos (desde bastion)
/opt/dba-training/scripts/connect-mysql.sh
/opt/dba-training/scripts/connect-postgres.sh
/opt/dba-training/scripts/connect-mongodb.sh
```

## 🔧 Herramientas y Utilidades

### **Bastion Host - Herramientas Preinstaladas**
```bash
# Clientes de base de datos
- mysql (MySQL 8.0 client)
- psql (PostgreSQL 15 client)  
- mongosh (MongoDB Shell 7.0)

# Herramientas de monitoreo
- Grafana 10.x
- Prometheus 2.45
- Node Exporter
- Database Exporters (MySQL, PostgreSQL, MongoDB)

# Herramientas de desarrollo
- Python 3 + pip
- Jupyter Notebook
- Docker + Docker Compose
- Git, vim, htop, curl, wget

# Librerías Python para DBA
- pymysql, psycopg2-binary, pymongo
- pandas, numpy, matplotlib
- sqlalchemy, boto3, awscli
```

### **Scripts de Automatización**
```bash
# En el bastion host
dba-status          # Verificar estado de servicios
dba-start           # Iniciar todos los servicios
monitoring-dashboard.py  # Dashboard web personalizado

# Directorios importantes
/opt/dba-training/scripts/    # Scripts de conexión
/opt/dba-training/scenarios/  # 15 escenarios de diagnóstico
/opt/dba-training/datasets/   # Datasets de entrenamiento
/opt/dba-training/logs/       # Logs del sistema
```

## 🎓 Escenarios de Entrenamiento

### **MySQL Scenarios (5)**
1. **mysql-deadlock**: Detección y resolución de deadlocks
2. **mysql-performance**: Optimización de queries lentas
3. **mysql-replication**: Configuración y troubleshooting de replicación
4. **mysql-backup-recovery**: Estrategias de backup y recovery
5. **mysql-connection-exhaustion**: Gestión de conexiones

### **PostgreSQL Scenarios (5)**
1. **postgres-vacuum**: Optimización de VACUUM y ANALYZE
2. **postgres-index-bloat**: Detección y corrección de index bloat
3. **postgres-connection-pooling**: Configuración de connection pooling
4. **postgres-query-optimization**: Análisis y optimización de queries
5. **postgres-partition-management**: Gestión de particiones

### **MongoDB Scenarios (5)**
1. **mongodb-sharding**: Configuración y balanceo de sharding
2. **mongodb-replica-set**: Gestión de replica sets
3. **mongodb-performance**: Optimización de performance
4. **mongodb-aggregation**: Pipelines de agregación complejos
5. **mongodb-index-optimization**: Estrategias de indexación

## 💰 Estimación de Costos

### **Configuración Estándar (Mensual)**
```bash
# Compute
Bastion t3.medium (24/7):        ~$30
Student environments (variable): ~$0-50

# Databases  
MySQL db.t3.micro:              ~$15
PostgreSQL db.t3.micro:         ~$15
DocumentDB db.t3.medium:        ~$50

# Network
NAT Gateway:                    ~$45
Data Transfer:                  ~$5

# Storage
EBS (100GB total):              ~$10
Backup storage:                 ~$5

# Monitoring
CloudWatch logs/metrics:        ~$5

Total Estimado:                 ~$180/mes
```

### **Optimizaciones de Costo**
```hcl
# Para entornos de desarrollo
enable_spot_instances = true      # -30% en compute
auto_shutdown_schedule = "0 22 * * *"  # Apagar por las noches

# Para laboratorios cortos
db_backup_retention_period = 1   # Mínimo backup
enable_deletion_protection = false

# Para grupos pequeños
max_students = 10                # Reduce auto-scaling
db_instance_class = "db.t3.micro"  # Instancias más pequeñas
```

## 🔍 Monitoreo y Alertas

### **CloudWatch Alarms Configuradas**
```bash
# Database Performance
- CPU Utilization > 80%
- Database Connections > 80% of max
- Free Storage Space < 20%
- Read/Write Latency > 200ms

# System Performance  
- Bastion CPU > 80%
- Memory Usage > 85%
- Disk Usage > 90%

# Application Health
- Service Down alerts
- Failed Login attempts
- Error Rate > 5%
```

### **Grafana Dashboards**
```bash
# Pre-configurados
1. DBA System Overview
2. MySQL Performance Dashboard  
3. PostgreSQL Performance Dashboard
4. MongoDB Performance Dashboard
5. Infrastructure Monitoring
6. Student Activity Dashboard
```

## 🛠️ Mantenimiento y Troubleshooting

### **Comandos de Diagnóstico**
```bash
# Validar despliegue completo
./validate-deployment.sh

# Verificar estado de servicios
ssh -i key.pem ec2-user@$BASTION_IP "dba-status"

# Ver logs del sistema
ssh -i key.pem ec2-user@$BASTION_IP "sudo journalctl -f"

# Verificar conectividad de bases de datos
terraform output troubleshooting_commands
```

### **Problemas Comunes y Soluciones**

#### **1. Error de Key Pair**
```bash
Error: InvalidKeyPair.NotFound

# Solución
aws ec2 describe-key-pairs --region your-region
# Crear key pair si no existe o actualizar variable
```

#### **2. Servicios no iniciados en Bastion**
```bash
# Conectar y verificar
ssh -i key.pem ec2-user@$BASTION_IP
sudo systemctl status prometheus grafana-server

# Reiniciar si es necesario
sudo systemctl restart prometheus grafana-server
dba-start
```

#### **3. Problemas de conectividad de base de datos**
```bash
# Verificar security groups
aws ec2 describe-security-groups --filters "Name=tag:Project,Values=dba-training-system"

# Test de conectividad
telnet $MYSQL_ENDPOINT 3306
telnet $POSTGRES_ENDPOINT 5432
telnet $DOCUMENTDB_ENDPOINT 27017
```

### **Logs Importantes**
```bash
# Configuración inicial del bastion
/var/log/user-data.log

# Logs de aplicaciones DBA
/opt/dba-training/logs/*.log

# Logs de servicios
sudo journalctl -u prometheus
sudo journalctl -u grafana-server
```

## 🔄 Actualizaciones y Cleanup

### **Actualizar Configuración**
```bash
# Modificar variables
vim terraform.tfvars

# Aplicar cambios
terraform plan
terraform apply
```

### **Cleanup Completo**
```bash
# ADVERTENCIA: Elimina toda la infraestructura
terraform destroy

# Confirmar con 'yes'
# Tiempo estimado: 10-15 minutos
```

### **Cleanup Selectivo**
```bash
# Eliminar solo bases de datos
terraform destroy -target=module.rds_mysql
terraform destroy -target=module.rds_postgres  
terraform destroy -target=module.documentdb
```

## 📞 Soporte y Documentación

### **Documentación Adicional**
- **DEPLOYMENT-GUIDE.md**: Guía detallada de despliegue
- **validate-deployment.sh**: Script de validación automatizada
- **terraform.tfvars.example**: Configuración de ejemplo completa

### **Estructura de Soporte**
```bash
# Generar reporte de estado
terraform output > system-status.txt
./validate-deployment.sh > validation-report.txt

# Información para soporte
- Terraform version
- AWS CLI version  
- Region y account ID
- Logs de error específicos
```

---

## 🎯 Próximos Pasos

1. **Revisar DEPLOYMENT-GUIDE.md** para instrucciones detalladas
2. **Configurar terraform.tfvars** con tus valores específicos
3. **Ejecutar despliegue** siguiendo los pasos documentados
4. **Validar sistema** con el script de validación
5. **Configurar acceso de estudiantes** y comenzar entrenamiento

**¡Tu sistema de entrenamiento DBA está listo para transformar la educación en administración de bases de datos!** 🚀
