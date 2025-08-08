# Laboratorio Semana 4 - Automatización y Monitoreo Híbrido
## DBA Cloud OnPrem Junior

### 🎯 Objetivos del Laboratorio
Al finalizar este laboratorio, el estudiante será capaz de:
- Desplegar recursos de base de datos usando Terraform
- Configurar Prometheus + Grafana para monitoreo OnPrem
- Crear playbooks de Ansible para automatización
- Integrar monitoreo híbrido OnPrem + Cloud
- Configurar alertas automatizadas

### 🖥️ Infraestructura Requerida
```yaml
# Nueva VM para herramientas de monitoreo
VM4 - Monitoring Server:
  OS: Ubuntu 20.04 LTS
  RAM: 8GB
  CPU: 4 cores
  Disk: 100GB
  Network: Acceso a todas las VMs y AWS

# VMs existentes (de laboratorios anteriores)
VM1 - MySQL OnPrem: Funcionando
VM2 - PostgreSQL OnPrem: Funcionando  
VM3 - MongoDB OnPrem: Funcionando

# AWS Cloud
- Cuenta AWS con permisos para Terraform
- RDS y DocumentDB existentes

# Herramientas
- Terraform
- Ansible
- Prometheus
- Grafana
- Node Exporter
- Database Exporters
```

---

## 📋 Laboratorio 1: Configuración de Terraform

### Paso 1: Instalación de Terraform
```bash
# Conectar a VM4 (Monitoring Server)
ssh student@monitoring-vm-ip

# Instalar Terraform
wget -O- https://apt.releases.hashicorp.com/gpg | gpg --dearmor | sudo tee /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update && sudo apt install terraform

# Verificar instalación
terraform version

# Configurar AWS CLI
aws configure
# Usar las credenciales proporcionadas
```

### Paso 2: Crear Proyecto Terraform para RDS
```bash
# Crear directorio de proyecto
mkdir -p ~/terraform/rds-lab
cd ~/terraform/rds-lab

# Crear archivo de variables
cat > variables.tf << 'EOF'
variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "db_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t3.micro"
}

variable "db_name" {
  description = "Database name"
  type        = string
  default     = "terraformdb"
}

variable "db_username" {
  description = "Database username"
  type        = string
  default     = "admin"
}

variable "db_password" {
  description = "Database password"
  type        = string
  sensitive   = true
  default     = "TerraformPass123!"
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
  # Obtener con: aws ec2 describe-vpcs --query 'Vpcs[0].VpcId' --output text
}

variable "subnet_ids" {
  description = "Subnet IDs for DB subnet group"
  type        = list(string)
  # Obtener con: aws ec2 describe-subnets --query 'Subnets[*].SubnetId' --output text
}
EOF
```

### Paso 3: Crear Configuración Principal de Terraform
```bash
# Crear archivo principal
cat > main.tf << 'EOF'
terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# Security Group para RDS
resource "aws_security_group" "rds_sg" {
  name_prefix = "terraform-rds-sg"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # En producción, usar CIDR específico
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "terraform-rds-sg"
    Environment = "lab"
    ManagedBy   = "terraform"
  }
}

# DB Subnet Group
resource "aws_db_subnet_group" "rds_subnet_group" {
  name       = "terraform-rds-subnet-group"
  subnet_ids = var.subnet_ids

  tags = {
    Name        = "terraform-rds-subnet-group"
    Environment = "lab"
    ManagedBy   = "terraform"
  }
}

# Parameter Group
resource "aws_db_parameter_group" "rds_params" {
  family = "mysql8.0"
  name   = "terraform-mysql-params"

  parameter {
    name  = "innodb_buffer_pool_size"
    value = "{DBInstanceClassMemory*3/4}"
  }

  parameter {
    name  = "max_connections"
    value = "200"
  }

  parameter {
    name  = "slow_query_log"
    value = "1"
  }

  parameter {
    name  = "long_query_time"
    value = "2"
  }

  tags = {
    Name        = "terraform-mysql-params"
    Environment = "lab"
    ManagedBy   = "terraform"
  }
}

# RDS Instance
resource "aws_db_instance" "mysql_instance" {
  identifier = "terraform-mysql-lab"

  # Engine configuration
  engine         = "mysql"
  engine_version = "8.0.35"
  instance_class = var.db_instance_class

  # Database configuration
  db_name  = var.db_name
  username = var.db_username
  password = var.db_password

  # Storage configuration
  allocated_storage     = 20
  max_allocated_storage = 100
  storage_type          = "gp2"
  storage_encrypted     = true

  # Network configuration
  vpc_security_group_ids = [aws_security_group.rds_sg.id]
  db_subnet_group_name   = aws_db_subnet_group.rds_subnet_group.name
  publicly_accessible    = true

  # Backup configuration
  backup_retention_period = 7
  backup_window          = "03:00-04:00"
  maintenance_window     = "sun:04:00-sun:05:00"

  # Parameter group
  parameter_group_name = aws_db_parameter_group.rds_params.name

  # Monitoring
  monitoring_interval = 60
  monitoring_role_arn = aws_iam_role.rds_monitoring_role.arn

  # Other settings
  auto_minor_version_upgrade = true
  deletion_protection       = false
  skip_final_snapshot      = true

  tags = {
    Name        = "terraform-mysql-lab"
    Environment = "lab"
    ManagedBy   = "terraform"
  }
}

# IAM Role for Enhanced Monitoring
resource "aws_iam_role" "rds_monitoring_role" {
  name = "rds-monitoring-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "monitoring.rds.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "rds_monitoring_policy" {
  role       = aws_iam_role.rds_monitoring_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}
EOF
```

### Paso 4: Crear Outputs
```bash
# Crear archivo de outputs
cat > outputs.tf << 'EOF'
output "rds_endpoint" {
  description = "RDS instance endpoint"
  value       = aws_db_instance.mysql_instance.endpoint
}

output "rds_port" {
  description = "RDS instance port"
  value       = aws_db_instance.mysql_instance.port
}

output "security_group_id" {
  description = "Security group ID"
  value       = aws_security_group.rds_sg.id
}

output "db_instance_id" {
  description = "RDS instance ID"
  value       = aws_db_instance.mysql_instance.id
}
EOF
```

---

## 📋 Laboratorio 2: Despliegue con Terraform

### Paso 1: Configurar Variables
```bash
# Obtener VPC ID y Subnet IDs
VPC_ID=$(aws ec2 describe-vpcs --query 'Vpcs[0].VpcId' --output text)
SUBNET_IDS=$(aws ec2 describe-subnets --query 'Subnets[*].SubnetId' --output json)

echo "VPC ID: $VPC_ID"
echo "Subnet IDs: $SUBNET_IDS"

# Crear archivo terraform.tfvars
cat > terraform.tfvars << EOF
aws_region = "us-east-1"
vpc_id = "$VPC_ID"
subnet_ids = $(echo $SUBNET_IDS | jq -c .)
db_instance_class = "db.t3.micro"
db_name = "terraformlab"
db_username = "admin"
db_password = "TerraformPass123!"
EOF
```

### Paso 2: Ejecutar Terraform
```bash
# Inicializar Terraform
terraform init

# Validar configuración
terraform validate

# Planificar despliegue
terraform plan

# Aplicar configuración
terraform apply

# Guardar outputs
terraform output > terraform_outputs.txt
cat terraform_outputs.txt
```

### Paso 3: Verificar Despliegue
```bash
# Obtener endpoint de RDS
RDS_ENDPOINT=$(terraform output -raw rds_endpoint)
echo "RDS Endpoint: $RDS_ENDPOINT"

# Probar conexión
mysql -h $RDS_ENDPOINT -u admin -p -e "SELECT VERSION(), @@hostname;"

# Verificar parámetros configurados
mysql -h $RDS_ENDPOINT -u admin -p -e "SHOW VARIABLES LIKE 'innodb_buffer_pool_size';"
mysql -h $RDS_ENDPOINT -u admin -p -e "SHOW VARIABLES LIKE 'max_connections';"
```

---

## 📋 Laboratorio 3: Instalación de Prometheus y Grafana

### Paso 1: Instalación de Prometheus
```bash
# Crear usuario para Prometheus
sudo useradd --no-create-home --shell /bin/false prometheus

# Crear directorios
sudo mkdir /etc/prometheus
sudo mkdir /var/lib/prometheus
sudo chown prometheus:prometheus /etc/prometheus
sudo chown prometheus:prometheus /var/lib/prometheus

# Descargar Prometheus
cd /tmp
wget https://github.com/prometheus/prometheus/releases/download/v2.40.0/prometheus-2.40.0.linux-amd64.tar.gz
tar xvf prometheus-2.40.0.linux-amd64.tar.gz

# Instalar binarios
sudo cp prometheus-2.40.0.linux-amd64/prometheus /usr/local/bin/
sudo cp prometheus-2.40.0.linux-amd64/promtool /usr/local/bin/
sudo chown prometheus:prometheus /usr/local/bin/prometheus
sudo chown prometheus:prometheus /usr/local/bin/promtool

# Copiar archivos de configuración
sudo cp -r prometheus-2.40.0.linux-amd64/consoles /etc/prometheus
sudo cp -r prometheus-2.40.0.linux-amd64/console_libraries /etc/prometheus
sudo chown -R prometheus:prometheus /etc/prometheus/consoles
sudo chown -R prometheus:prometheus /etc/prometheus/console_libraries
```

### Paso 2: Configurar Prometheus
```bash
# Crear archivo de configuración
sudo tee /etc/prometheus/prometheus.yml > /dev/null << 'EOF'
global:
  scrape_interval: 15s
  evaluation_interval: 15s

rule_files:
  # - "first_rules.yml"
  # - "second_rules.yml"

scrape_configs:
  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']

  - job_name: 'node-exporter'
    static_configs:
      - targets: 
        - 'localhost:9100'
        - 'MYSQL_VM_IP:9100'
        - 'POSTGRES_VM_IP:9100'
        - 'MONGODB_VM_IP:9100'

  - job_name: 'mysql-exporter'
    static_configs:
      - targets: ['MYSQL_VM_IP:9104']

  - job_name: 'postgres-exporter'
    static_configs:
      - targets: ['POSTGRES_VM_IP:9187']

  - job_name: 'mongodb-exporter'
    static_configs:
      - targets: ['MONGODB_VM_IP:9216']
EOF

# Reemplazar IPs reales
sudo sed -i "s/MYSQL_VM_IP/$(echo $MYSQL_VM_IP)/g" /etc/prometheus/prometheus.yml
sudo sed -i "s/POSTGRES_VM_IP/$(echo $POSTGRES_VM_IP)/g" /etc/prometheus/prometheus.yml
sudo sed -i "s/MONGODB_VM_IP/$(echo $MONGODB_VM_IP)/g" /etc/prometheus/prometheus.yml

sudo chown prometheus:prometheus /etc/prometheus/prometheus.yml
```

### Paso 3: Crear Servicio Systemd para Prometheus
```bash
# Crear archivo de servicio
sudo tee /etc/systemd/system/prometheus.service > /dev/null << 'EOF'
[Unit]
Description=Prometheus
Wants=network-online.target
After=network-online.target

[Service]
User=prometheus
Group=prometheus
Type=simple
ExecStart=/usr/local/bin/prometheus \
    --config.file /etc/prometheus/prometheus.yml \
    --storage.tsdb.path /var/lib/prometheus/ \
    --web.console.templates=/etc/prometheus/consoles \
    --web.console.libraries=/etc/prometheus/console_libraries \
    --web.listen-address=0.0.0.0:9090 \
    --web.enable-lifecycle

[Install]
WantedBy=multi-user.target
EOF

# Iniciar Prometheus
sudo systemctl daemon-reload
sudo systemctl start prometheus
sudo systemctl enable prometheus
sudo systemctl status prometheus
```

### Paso 4: Instalación de Grafana
```bash
# Agregar repositorio de Grafana
wget -q -O - https://packages.grafana.com/gpg.key | sudo apt-key add -
echo "deb https://packages.grafana.com/oss/deb stable main" | sudo tee -a /etc/apt/sources.list.d/grafana.list

# Instalar Grafana
sudo apt update
sudo apt install grafana

# Iniciar Grafana
sudo systemctl start grafana-server
sudo systemctl enable grafana-server
sudo systemctl status grafana-server

# Configurar firewall
sudo ufw allow 3000/tcp
sudo ufw allow 9090/tcp
```

---

## 📋 Laboratorio 4: Configuración de Exporters

### Paso 1: Instalar Node Exporter en todas las VMs
```bash
# Script para instalar en cada VM (ejecutar en VM1, VM2, VM3, VM4)
# Crear usuario
sudo useradd --no-create-home --shell /bin/false node_exporter

# Descargar Node Exporter
cd /tmp
wget https://github.com/prometheus/node_exporter/releases/download/v1.5.0/node_exporter-1.5.0.linux-amd64.tar.gz
tar xvf node_exporter-1.5.0.linux-amd64.tar.gz

# Instalar binario
sudo cp node_exporter-1.5.0.linux-amd64/node_exporter /usr/local/bin
sudo chown node_exporter:node_exporter /usr/local/bin/node_exporter

# Crear servicio systemd
sudo tee /etc/systemd/system/node_exporter.service > /dev/null << 'EOF'
[Unit]
Description=Node Exporter
Wants=network-online.target
After=network-online.target

[Service]
User=node_exporter
Group=node_exporter
Type=simple
ExecStart=/usr/local/bin/node_exporter

[Install]
WantedBy=multi-user.target
EOF

# Iniciar servicio
sudo systemctl daemon-reload
sudo systemctl start node_exporter
sudo systemctl enable node_exporter

# Configurar firewall
sudo ufw allow 9100/tcp
```

### Paso 2: Instalar MySQL Exporter (en VM1)
```bash
# En VM1 (MySQL OnPrem)
# Crear usuario para monitoreo en MySQL
mysql -u root -p << 'EOF'
CREATE USER 'exporter'@'localhost' IDENTIFIED BY 'ExporterPass123!';
GRANT PROCESS, REPLICATION CLIENT, SELECT ON *.* TO 'exporter'@'localhost';
FLUSH PRIVILEGES;
EOF

# Crear usuario del sistema
sudo useradd --no-create-home --shell /bin/false mysqld_exporter

# Descargar MySQL Exporter
cd /tmp
wget https://github.com/prometheus/mysqld_exporter/releases/download/v0.14.0/mysqld_exporter-0.14.0.linux-amd64.tar.gz
tar xvf mysqld_exporter-0.14.0.linux-amd64.tar.gz

# Instalar binario
sudo cp mysqld_exporter-0.14.0.linux-amd64/mysqld_exporter /usr/local/bin
sudo chown mysqld_exporter:mysqld_exporter /usr/local/bin/mysqld_exporter

# Crear archivo de configuración
sudo tee /etc/mysql/mysqld_exporter.cnf > /dev/null << 'EOF'
[client]
user=exporter
password=ExporterPass123!
host=localhost
port=3306
EOF

sudo chown mysqld_exporter:mysqld_exporter /etc/mysql/mysqld_exporter.cnf
sudo chmod 600 /etc/mysql/mysqld_exporter.cnf

# Crear servicio systemd
sudo tee /etc/systemd/system/mysqld_exporter.service > /dev/null << 'EOF'
[Unit]
Description=MySQL Exporter
Wants=network-online.target
After=network-online.target

[Service]
User=mysqld_exporter
Group=mysqld_exporter
Type=simple
ExecStart=/usr/local/bin/mysqld_exporter --config.my-cnf=/etc/mysql/mysqld_exporter.cnf
Restart=always

[Install]
WantedBy=multi-user.target
EOF

# Iniciar servicio
sudo systemctl daemon-reload
sudo systemctl start mysqld_exporter
sudo systemctl enable mysqld_exporter

# Configurar firewall
sudo ufw allow 9104/tcp
```

### Paso 3: Instalar PostgreSQL Exporter (en VM2)
```bash
# En VM2 (PostgreSQL OnPrem)
# Crear usuario para monitoreo en PostgreSQL
sudo -u postgres psql << 'EOF'
CREATE USER postgres_exporter WITH PASSWORD 'ExporterPass123!';
GRANT CONNECT ON DATABASE postgres TO postgres_exporter;
GRANT pg_monitor TO postgres_exporter;
EOF

# Crear usuario del sistema
sudo useradd --no-create-home --shell /bin/false postgres_exporter

# Descargar PostgreSQL Exporter
cd /tmp
wget https://github.com/prometheus-community/postgres_exporter/releases/download/v0.11.1/postgres_exporter-0.11.1.linux-amd64.tar.gz
tar xvf postgres_exporter-0.11.1.linux-amd64.tar.gz

# Instalar binario
sudo cp postgres_exporter-0.11.1.linux-amd64/postgres_exporter /usr/local/bin
sudo chown postgres_exporter:postgres_exporter /usr/local/bin/postgres_exporter

# Crear archivo de configuración
sudo tee /etc/postgres_exporter/postgres_exporter.env > /dev/null << 'EOF'
DATA_SOURCE_NAME="postgresql://postgres_exporter:ExporterPass123!@localhost:5432/postgres?sslmode=disable"
EOF

sudo mkdir -p /etc/postgres_exporter
sudo chown postgres_exporter:postgres_exporter /etc/postgres_exporter/postgres_exporter.env
sudo chmod 600 /etc/postgres_exporter/postgres_exporter.env

# Crear servicio systemd
sudo tee /etc/systemd/system/postgres_exporter.service > /dev/null << 'EOF'
[Unit]
Description=PostgreSQL Exporter
Wants=network-online.target
After=network-online.target

[Service]
User=postgres_exporter
Group=postgres_exporter
Type=simple
EnvironmentFile=/etc/postgres_exporter/postgres_exporter.env
ExecStart=/usr/local/bin/postgres_exporter
Restart=always

[Install]
WantedBy=multi-user.target
EOF

# Iniciar servicio
sudo systemctl daemon-reload
sudo systemctl start postgres_exporter
sudo systemctl enable postgres_exporter

# Configurar firewall
sudo ufw allow 9187/tcp
```

---

## 🧪 Ejercicios de Evaluación

### Ejercicio 1: Despliegue con Terraform (30 puntos)
**Tiempo límite: 60 minutos**

**Tarea:** Crear y desplegar una instancia RDS PostgreSQL usando Terraform con:
- Instance class: db.t3.micro
- Engine: PostgreSQL 14.x
- Storage: 20GB encrypted
- Parameter group personalizado
- Security group con acceso desde OnPrem

**Criterios de evaluación:**
- Configuración Terraform correcta (15 pts)
- Despliegue exitoso (10 pts)
- Puede conectar desde OnPrem (5 pts)

### Ejercicio 2: Configuración de Monitoreo (35 puntos)
**Tiempo límite: 75 minutos**

**Tarea:** 
1. Configurar Prometheus para monitorear todas las VMs
2. Instalar exporters en al menos 2 motores de DB
3. Crear dashboard básico en Grafana
4. Configurar alerta para CPU > 80%

**Criterios de evaluación:**
- Prometheus recolecta métricas (15 pts)
- Exporters funcionando (10 pts)
- Dashboard creado (5 pts)
- Alerta configurada (5 pts)

### Ejercicio 3: Automatización con Scripts (20 puntos)
**Tiempo límite: 40 minutos**

**Tarea:** Crear script bash que:
1. Verifique estado de todos los servicios DB
2. Genere reporte de uso de recursos
3. Envíe alerta si algún servicio está caído

**Criterios de evaluación:**
- Script funciona correctamente (10 pts)
- Genera reporte útil (5 pts)
- Maneja errores apropiadamente (5 pts)

### Ejercicio 4: Integración Híbrida (15 puntos)
**Tiempo límite: 30 minutos**

**Tarea:** Configurar CloudWatch para recibir métricas custom desde Prometheus OnPrem

**Criterios de evaluación:**
- Configuración CloudWatch correcta (10 pts)
- Métricas aparecen en CloudWatch (5 pts)

Este laboratorio proporciona experiencia práctica completa en automatización y monitoreo híbrido, preparando a los estudiantes para entornos de producción reales.
