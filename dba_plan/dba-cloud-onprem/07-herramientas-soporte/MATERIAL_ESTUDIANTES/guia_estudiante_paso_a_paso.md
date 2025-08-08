# 🎓 GUÍA PASO A PASO PARA ESTUDIANTES
## DBA Cloud OnPrem Junior - Tu Roadmap Completo

### 🎯 **INTRODUCCIÓN**
Esta guía te llevará paso a paso a través de las 5 semanas del programa DBA Cloud OnPrem Junior. Cada sección incluye objetivos claros, pasos detallados, verificaciones de progreso y recursos de apoyo.

---

## 📅 **CRONOGRAMA DETALLADO - 200 HORAS TOTALES**

### **SEMANA -1: PREPARACIÓN (10 horas)**
**Objetivo:** Preparar tu entorno de aprendizaje

#### **Día 1-2: Configuración de Hardware (4 horas)**
```bash
# 1. Verificar requisitos de hardware
echo "Verificando RAM disponible..."
free -h

# 2. Verificar espacio en disco
df -h

# 3. Verificar procesador
lscpu | grep -E '^Thread|^Core|^Socket|^CPU\('
```

**Checklist Día 1-2:**
- [ ] ✅ Verificado: 16GB+ RAM disponible
- [ ] ✅ Verificado: 100GB+ espacio libre
- [ ] ✅ Verificado: Procesador 4+ cores
- [ ] ✅ Conexión a internet estable (>10 Mbps)

#### **Día 3-4: Instalación de Software Base (4 horas)**
```bash
# 1. Instalar VirtualBox (Ubuntu/Debian)
sudo apt update
sudo apt install virtualbox virtualbox-ext-pack

# 2. Descargar Ubuntu 20.04 LTS
wget https://releases.ubuntu.com/20.04/ubuntu-20.04.6-live-server-amd64.iso

# 3. Crear primera VM
# - Nombre: DBA-Lab-MySQL
# - RAM: 4GB
# - Disco: 25GB
# - Red: NAT + Host-Only
```

**Checklist Día 3-4:**
- [ ] ✅ VirtualBox instalado y funcionando
- [ ] ✅ Ubuntu 20.04 ISO descargado
- [ ] ✅ Primera VM creada y configurada
- [ ] ✅ Red configurada correctamente

#### **Día 5-6: Configuración AWS (2 horas)**
```bash
# 1. Crear cuenta AWS (si no tienes)
# 2. Configurar AWS CLI
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install

# 3. Configurar credenciales
aws configure
# AWS Access Key ID: [Tu Access Key]
# AWS Secret Access Key: [Tu Secret Key]
# Default region: us-east-1
# Default output format: json

# 4. Verificar configuración
aws sts get-caller-identity
```

**Checklist Día 5-6:**
- [ ] ✅ Cuenta AWS creada y verificada
- [ ] ✅ AWS CLI instalado
- [ ] ✅ Credenciales configuradas
- [ ] ✅ Conexión AWS verificada

---

## 📚 **SEMANA 0: FUNDAMENTOS ONPREM (40 horas)**
**Objetivo:** Dominar instalación y configuración OnPrem desde cero

### **Día 1: Preparación del Entorno (8 horas)**

#### **Mañana (4 horas): Configuración de VMs**
```bash
# 1. Crear 4 VMs idénticas
# VM1: DBA-Lab-MySQL (4GB RAM, 25GB disco)
# VM2: DBA-Lab-PostgreSQL (4GB RAM, 25GB disco)  
# VM3: DBA-Lab-MongoDB (4GB RAM, 25GB disco)
# VM4: DBA-Lab-Tools (4GB RAM, 25GB disco)

# 2. Instalar Ubuntu en cada VM
# - Usuario: dbastudent
# - Password: DBA2024!
# - SSH habilitado
# - Actualizaciones automáticas deshabilitadas

# 3. Configurar red en cada VM
sudo nano /etc/netplan/00-installer-config.yaml
```

**Configuración de red para cada VM:**
```yaml
network:
  ethernets:
    enp0s3:
      dhcp4: true
    enp0s8:
      addresses:
        - 192.168.56.10/24  # MySQL VM
        # - 192.168.56.11/24  # PostgreSQL VM
        # - 192.168.56.12/24  # MongoDB VM
        # - 192.168.56.13/24  # Tools VM
  version: 2
```

#### **Tarde (4 horas): Configuración Base**
```bash
# En cada VM, ejecutar:
# 1. Actualizar sistema
sudo apt update && sudo apt upgrade -y

# 2. Instalar herramientas básicas
sudo apt install -y curl wget git vim htop tree net-tools

# 3. Configurar SSH keys
ssh-keygen -t rsa -b 4096 -C "dbastudent@lab"

# 4. Configurar firewall básico
sudo ufw enable
sudo ufw allow ssh
sudo ufw allow from 192.168.56.0/24
```

**Checklist Día 1:**
- [ ] ✅ 4 VMs creadas y configuradas
- [ ] ✅ Ubuntu instalado en todas las VMs
- [ ] ✅ Red configurada correctamente
- [ ] ✅ SSH funcionando entre VMs
- [ ] ✅ Herramientas básicas instaladas

### **Día 2: Instalación MySQL OnPrem (8 horas)**

#### **Mañana (4 horas): Instalación desde Cero**
```bash
# En VM1 (DBA-Lab-MySQL):
# 1. Descargar script de instalación
cd /home/dbastudent
wget [URL_del_script]/install_mysql_onprem.sh
chmod +x install_mysql_onprem.sh

# 2. Ejecutar instalación automatizada
./install_mysql_onprem.sh

# 3. Verificar instalación
sudo systemctl status mysql
mysql --version
```

#### **Tarde (4 horas): Configuración Avanzada**
```bash
# 1. Configurar MySQL para acceso remoto
sudo nano /etc/mysql/mysql.conf.d/mysqld.cnf
# Cambiar bind-address = 0.0.0.0

# 2. Crear usuarios administrativos
mysql -u root -p
CREATE USER 'dbadmin'@'%' IDENTIFIED BY 'DBAAdmin2024!';
GRANT ALL PRIVILEGES ON *.* TO 'dbadmin'@'%' WITH GRANT OPTION;
FLUSH PRIVILEGES;

# 3. Configurar firewall
sudo ufw allow 3306

# 4. Cargar dataset de prueba
mysql -u dbadmin -p < mysql_ecommerce_dataset.sql
```

**Checklist Día 2:**
- [ ] ✅ MySQL instalado correctamente
- [ ] ✅ Servicio MySQL ejecutándose
- [ ] ✅ Acceso remoto configurado
- [ ] ✅ Usuario administrativo creado
- [ ] ✅ Dataset de prueba cargado

### **Día 3: Instalación PostgreSQL OnPrem (8 horas)**

#### **Mañana (4 horas): Instalación desde Cero**
```bash
# En VM2 (DBA-Lab-PostgreSQL):
# 1. Descargar script de instalación
cd /home/dbastudent
wget [URL_del_script]/install_postgresql_onprem.sh
chmod +x install_postgresql_onprem.sh

# 2. Ejecutar instalación automatizada
./install_postgresql_onprem.sh

# 3. Verificar instalación
sudo systemctl status postgresql
psql --version
```

#### **Tarde (4 horas): Configuración Avanzada**
```bash
# 1. Configurar PostgreSQL para acceso remoto
sudo nano /etc/postgresql/14/main/postgresql.conf
# listen_addresses = '*'

sudo nano /etc/postgresql/14/main/pg_hba.conf
# host all all 192.168.56.0/24 md5

# 2. Crear usuarios administrativos
sudo -u postgres psql
CREATE USER dbadmin WITH PASSWORD 'DBAAdmin2024!' SUPERUSER;
CREATE DATABASE analytics_db OWNER dbadmin;

# 3. Configurar firewall
sudo ufw allow 5432

# 4. Cargar dataset de prueba
psql -U dbadmin -d analytics_db -f postgresql_analytics_dataset.sql
```

**Checklist Día 3:**
- [ ] ✅ PostgreSQL instalado correctamente
- [ ] ✅ Servicio PostgreSQL ejecutándose
- [ ] ✅ Acceso remoto configurado
- [ ] ✅ Usuario administrativo creado
- [ ] ✅ Dataset de prueba cargado

### **Día 4: Instalación MongoDB OnPrem (8 horas)**

#### **Mañana (4 horas): Instalación desde Cero**
```bash
# En VM3 (DBA-Lab-MongoDB):
# 1. Descargar script de instalación
cd /home/dbastudent
wget [URL_del_script]/install_mongodb_onprem.sh
chmod +x install_mongodb_onprem.sh

# 2. Ejecutar instalación automatizada
./install_mongodb_onprem.sh

# 3. Verificar instalación
sudo systemctl status mongod
mongod --version
```

#### **Tarde (4 horas): Configuración Avanzada**
```bash
# 1. Configurar MongoDB para acceso remoto
sudo nano /etc/mongod.conf
# net:
#   port: 27017
#   bindIp: 0.0.0.0

# 2. Habilitar autenticación
# security:
#   authorization: enabled

# 3. Crear usuarios administrativos
mongo
use admin
db.createUser({
  user: "dbadmin",
  pwd: "DBAAdmin2024!",
  roles: ["root"]
})

# 4. Configurar firewall
sudo ufw allow 27017

# 5. Cargar dataset de prueba
mongo -u dbadmin -p --authenticationDatabase admin
load("mongodb_social_dataset.js")
```

**Checklist Día 4:**
- [ ] ✅ MongoDB instalado correctamente
- [ ] ✅ Servicio MongoDB ejecutándose
- [ ] ✅ Autenticación configurada
- [ ] ✅ Usuario administrativo creado
- [ ] ✅ Dataset de prueba cargado

### **Día 5: Herramientas de Monitoreo (8 horas)**

#### **Mañana (4 horas): Instalación de Herramientas**
```bash
# En VM4 (DBA-Lab-Tools):
# 1. Instalar Prometheus
wget https://github.com/prometheus/prometheus/releases/download/v2.40.0/prometheus-2.40.0.linux-amd64.tar.gz
tar xvfz prometheus-*.tar.gz
cd prometheus-*
./prometheus --config.file=prometheus.yml

# 2. Instalar Grafana
sudo apt-get install -y software-properties-common
sudo add-apt-repository "deb https://packages.grafana.com/oss/deb stable main"
wget -q -O - https://packages.grafana.com/gpg.key | sudo apt-key add -
sudo apt-get update
sudo apt-get install grafana
```

#### **Tarde (4 horas): Configuración de Monitoreo**
```bash
# 1. Configurar exporters en cada DB VM
# MySQL Exporter en VM1
# PostgreSQL Exporter en VM2  
# MongoDB Exporter en VM3

# 2. Configurar Prometheus targets
sudo nano /etc/prometheus/prometheus.yml

# 3. Importar dashboards en Grafana
# - MySQL Dashboard
# - PostgreSQL Dashboard
# - MongoDB Dashboard
```

**Checklist Día 5:**
- [ ] ✅ Prometheus instalado y configurado
- [ ] ✅ Grafana instalado y configurado
- [ ] ✅ Exporters configurados en cada DB
- [ ] ✅ Dashboards importados
- [ ] ✅ Monitoreo funcionando correctamente

---

## 🔄 **SEMANA 1: ARQUITECTURAS HÍBRIDAS (40 horas)**
**Objetivo:** Conectar entornos OnPrem con Cloud AWS

### **Día 1: Configuración AWS RDS (8 horas)**

#### **Mañana (4 horas): Creación de Instancias RDS**
```bash
# 1. Crear VPC para laboratorio
aws ec2 create-vpc --cidr-block 10.0.0.0/16 --tag-specifications 'ResourceType=vpc,Tags=[{Key=Name,Value=DBA-Lab-VPC}]'

# 2. Crear subnets
aws ec2 create-subnet --vpc-id vpc-xxxxxxxx --cidr-block 10.0.1.0/24 --availability-zone us-east-1a
aws ec2 create-subnet --vpc-id vpc-xxxxxxxx --cidr-block 10.0.2.0/24 --availability-zone us-east-1b

# 3. Crear DB subnet group
aws rds create-db-subnet-group \
    --db-subnet-group-name dba-lab-subnet-group \
    --db-subnet-group-description "DBA Lab Subnet Group" \
    --subnet-ids subnet-xxxxxxxx subnet-yyyyyyyy

# 4. Crear instancia MySQL RDS
aws rds create-db-instance \
    --db-instance-identifier dba-lab-mysql \
    --db-instance-class db.t3.micro \
    --engine mysql \
    --master-username dbadmin \
    --master-user-password DBAAdmin2024! \
    --allocated-storage 20 \
    --db-subnet-group-name dba-lab-subnet-group
```

#### **Tarde (4 horas): Configuración de Conectividad**
```bash
# 1. Crear security group
aws ec2 create-security-group \
    --group-name dba-lab-sg \
    --description "DBA Lab Security Group" \
    --vpc-id vpc-xxxxxxxx

# 2. Configurar reglas de firewall
aws ec2 authorize-security-group-ingress \
    --group-id sg-xxxxxxxx \
    --protocol tcp \
    --port 3306 \
    --source-group sg-xxxxxxxx

# 3. Probar conectividad desde OnPrem
mysql -h dba-lab-mysql.xxxxxxxx.us-east-1.rds.amazonaws.com -u dbadmin -p
```

**Checklist Día 1:**
- [ ] ✅ VPC y subnets creadas
- [ ] ✅ Instancia MySQL RDS creada
- [ ] ✅ Security groups configurados
- [ ] ✅ Conectividad OnPrem → RDS verificada

### **Día 2: Configuración DocumentDB (8 horas)**

#### **Mañana (4 horas): Creación de Cluster DocumentDB**
```bash
# 1. Crear cluster DocumentDB
aws docdb create-db-cluster \
    --db-cluster-identifier dba-lab-docdb \
    --engine docdb \
    --master-username dbadmin \
    --master-user-password DBAAdmin2024! \
    --db-subnet-group-name dba-lab-subnet-group \
    --vpc-security-group-ids sg-xxxxxxxx

# 2. Crear instancia en el cluster
aws docdb create-db-instance \
    --db-instance-identifier dba-lab-docdb-instance \
    --db-instance-class db.t3.medium \
    --engine docdb \
    --db-cluster-identifier dba-lab-docdb
```

#### **Tarde (4 horas): Configuración de Conectividad**
```bash
# 1. Descargar certificado SSL
wget https://s3.amazonaws.com/rds-downloads/rds-combined-ca-bundle.pem

# 2. Probar conectividad
mongo --ssl --host dba-lab-docdb.cluster-xxxxxxxx.us-east-1.docdb.amazonaws.com:27017 \
    --sslCAFile rds-combined-ca-bundle.pem \
    --username dbadmin \
    --password DBAAdmin2024!

# 3. Migrar datos de MongoDB OnPrem a DocumentDB
mongodump --host 192.168.56.12:27017 --db social_media --out /tmp/backup
mongorestore --ssl --host dba-lab-docdb.cluster-xxxxxxxx.us-east-1.docdb.amazonaws.com:27017 \
    --sslCAFile rds-combined-ca-bundle.pem \
    --username dbadmin --password DBAAdmin2024! \
    --db social_media /tmp/backup/social_media
```

**Checklist Día 2:**
- [ ] ✅ Cluster DocumentDB creado
- [ ] ✅ Instancia DocumentDB creada
- [ ] ✅ Conectividad SSL configurada
- [ ] ✅ Migración de datos completada

### **Día 3-5: Ejercicios Prácticos Híbridos (24 horas)**

#### **Ejercicios de Conectividad (8 horas)**
```bash
# 1. Configurar replicación MySQL OnPrem → RDS
# 2. Sincronizar datos PostgreSQL OnPrem ↔ RDS
# 3. Implementar backup híbrido OnPrem + S3
# 4. Configurar monitoreo híbrido con CloudWatch
```

#### **Ejercicios de Migración (8 horas)**
```bash
# 1. Migrar base de datos completa OnPrem → RDS
# 2. Implementar estrategia de rollback
# 3. Validar integridad de datos post-migración
# 4. Optimizar performance en ambos entornos
```

#### **Ejercicios de Administración (8 horas)**
```bash
# 1. Gestionar usuarios en ambos entornos
# 2. Configurar backups automatizados
# 3. Implementar alertas y monitoreo
# 4. Documentar procedimientos operativos
```

---

## 📊 **SEMANAS 2-5: CONTINUACIÓN DETALLADA**

### **SEMANA 2: ADMINISTRACIÓN AVANZADA (40 horas)**
- Gestión avanzada de usuarios y roles
- Estrategias de backup y recovery
- Optimización de performance
- Herramientas de monitoreo avanzado

### **SEMANA 3: SEGURIDAD Y NOSQL (40 horas)**
- Implementación de SSL/TLS
- Configuración de autenticación avanzada
- Auditoría y compliance
- Migración de datos segura

### **SEMANA 4: AUTOMATIZACIÓN (40 horas)**
- Terraform para infraestructura
- Scripts de automatización
- CI/CD para bases de datos
- Monitoreo con Prometheus/Grafana

### **SEMANA 5: TROUBLESHOOTING Y DR (40 horas)**
- Diagnóstico avanzado de problemas
- Procedimientos de disaster recovery
- Alta disponibilidad
- Proyecto final integrador

---

## 📋 **SISTEMA DE VERIFICACIÓN CONTINUA**

### **Scripts de Auto-Verificación**
```bash
# Verificar progreso semanal
./check_week0_progress.sh
./check_week1_progress.sh
# ... etc
```

### **Checklist de Competencias**
- [ ] ✅ Instalación OnPrem desde cero
- [ ] ✅ Configuración de conectividad híbrida
- [ ] ✅ Migración de datos OnPrem ↔ Cloud
- [ ] ✅ Implementación de seguridad avanzada
- [ ] ✅ Automatización con Terraform
- [ ] ✅ Monitoreo y alertas
- [ ] ✅ Troubleshooting avanzado
- [ ] ✅ Procedimientos de DR

---

## 🎯 **PROYECTO FINAL INTEGRADOR**

### **Objetivo:** Implementar solución híbrida completa
- Infraestructura OnPrem + Cloud
- Migración de datos en vivo
- Monitoreo y alertas
- Documentación completa
- Presentación de resultados

---

**¡Esta guía te llevará paso a paso hacia el dominio completo de las tecnologías DBA híbridas OnPrem + Cloud!**
