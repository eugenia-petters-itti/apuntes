# 🔧 GUÍA DE TROUBLESHOOTING
## DBA Cloud OnPrem Junior - Soluciones a Problemas Comunes

### 🎯 **INTRODUCCIÓN**
Esta guía contiene soluciones a los problemas más comunes que enfrentan los estudiantes durante el programa. Está organizada por categorías y incluye comandos específicos para diagnosticar y resolver cada problema.

---

## 🚨 **PROBLEMAS DE CONECTIVIDAD**

### **Problema: No puedo conectar a las VMs desde mi máquina host**

#### **Síntomas:**
```bash
ssh dbastudent@192.168.56.10
# ssh: connect to host 192.168.56.10 port 22: Connection refused
```

#### **Diagnóstico:**
```bash
# 1. Verificar que las VMs están ejecutándose
VBoxManage list runningvms

# 2. Verificar configuración de red
VBoxManage showvminfo "DBA-Lab-MySQL" | grep -i network

# 3. Verificar IP de la VM desde dentro de la VM
ip addr show
```

#### **Soluciones:**
```bash
# Solución 1: Reiniciar servicio de red en la VM
sudo systemctl restart networking
sudo netplan apply

# Solución 2: Reconfigurar red host-only
# En VirtualBox: File > Host Network Manager
# Verificar que existe vboxnet0 con rango 192.168.56.0/24

# Solución 3: Verificar firewall
sudo ufw status
sudo ufw allow ssh
sudo ufw allow from 192.168.56.0/24

# Solución 4: Reiniciar SSH
sudo systemctl restart ssh
sudo systemctl enable ssh
```

### **Problema: Las VMs no pueden acceder a internet**

#### **Síntomas:**
```bash
ping google.com
# ping: google.com: Temporary failure in name resolution

apt update
# Could not resolve 'archive.ubuntu.com'
```

#### **Diagnóstico:**
```bash
# 1. Verificar configuración de DNS
cat /etc/resolv.conf

# 2. Verificar gateway
ip route show

# 3. Verificar adaptador NAT
ip addr show enp0s3
```

#### **Soluciones:**
```bash
# Solución 1: Configurar DNS manualmente
sudo nano /etc/resolv.conf
# Agregar:
# nameserver 8.8.8.8
# nameserver 8.8.4.4

# Solución 2: Reconfigurar netplan
sudo nano /etc/netplan/00-installer-config.yaml
# Agregar nameservers:
network:
  ethernets:
    enp0s3:
      dhcp4: true
      nameservers:
        addresses: [8.8.8.8, 8.8.4.4]
    enp0s8:
      addresses: [192.168.56.10/24]
  version: 2

sudo netplan apply

# Solución 3: Verificar adaptador NAT en VirtualBox
# VM Settings > Network > Adapter 1 > NAT
```

---

## 🗄️ **PROBLEMAS DE BASES DE DATOS**

### **Problema: MySQL no inicia después de la instalación**

#### **Síntomas:**
```bash
sudo systemctl status mysql
# ● mysql.service - MySQL Community Server
#    Active: failed (Result: exit-code)
```

#### **Diagnóstico:**
```bash
# 1. Verificar logs de error
sudo tail -f /var/log/mysql/error.log

# 2. Verificar configuración
sudo mysql --help --verbose | grep -A 1 'Default options'

# 3. Verificar permisos de archivos
ls -la /var/lib/mysql/
```

#### **Soluciones:**
```bash
# Solución 1: Reinicializar MySQL
sudo systemctl stop mysql
sudo rm -rf /var/lib/mysql/*
sudo mysqld --initialize --user=mysql
sudo systemctl start mysql

# Solución 2: Verificar configuración my.cnf
sudo nano /etc/mysql/mysql.conf.d/mysqld.cnf
# Comentar líneas problemáticas temporalmente

# Solución 3: Verificar permisos
sudo chown -R mysql:mysql /var/lib/mysql
sudo chmod 750 /var/lib/mysql

# Solución 4: Reinstalar completamente
sudo apt remove --purge mysql-server mysql-client mysql-common
sudo apt autoremove
sudo apt autoclean
sudo rm -rf /var/lib/mysql
sudo rm -rf /etc/mysql
# Luego ejecutar script de instalación nuevamente
```

### **Problema: PostgreSQL no acepta conexiones remotas**

#### **Síntomas:**
```bash
psql -h 192.168.56.11 -U dbadmin -d postgres
# psql: error: could not connect to server: Connection refused
```

#### **Diagnóstico:**
```bash
# 1. Verificar que PostgreSQL está ejecutándose
sudo systemctl status postgresql

# 2. Verificar configuración de listen_addresses
sudo grep listen_addresses /etc/postgresql/14/main/postgresql.conf

# 3. Verificar pg_hba.conf
sudo cat /etc/postgresql/14/main/pg_hba.conf
```

#### **Soluciones:**
```bash
# Solución 1: Configurar listen_addresses
sudo nano /etc/postgresql/14/main/postgresql.conf
# Cambiar:
# listen_addresses = '*'

# Solución 2: Configurar pg_hba.conf
sudo nano /etc/postgresql/14/main/pg_hba.conf
# Agregar al final:
# host all all 192.168.56.0/24 md5

# Solución 3: Reiniciar PostgreSQL
sudo systemctl restart postgresql

# Solución 4: Verificar firewall
sudo ufw allow 5432
sudo ufw allow from 192.168.56.0/24 to any port 5432
```

### **Problema: MongoDB no inicia con autenticación**

#### **Síntomas:**
```bash
sudo systemctl status mongod
# Active: failed (Result: exit-code)

mongo
# MongoDB shell version v6.0.0
# Error: couldn't connect to server 127.0.0.1:27017
```

#### **Diagnóstico:**
```bash
# 1. Verificar logs de MongoDB
sudo tail -f /var/log/mongodb/mongod.log

# 2. Verificar configuración
sudo cat /etc/mongod.conf

# 3. Verificar permisos
ls -la /var/lib/mongodb/
```

#### **Soluciones:**
```bash
# Solución 1: Iniciar sin autenticación temporalmente
sudo nano /etc/mongod.conf
# Comentar sección security:
# security:
#   authorization: enabled

sudo systemctl restart mongod

# Solución 2: Recrear usuario admin
mongo
use admin
db.createUser({
  user: "dbadmin",
  pwd: "DBAAdmin2024!",
  roles: ["root"]
})

# Solución 3: Verificar permisos de archivos
sudo chown -R mongodb:mongodb /var/lib/mongodb
sudo chown -R mongodb:mongodb /var/log/mongodb

# Solución 4: Limpiar locks corruptos
sudo rm /var/lib/mongodb/mongod.lock
sudo systemctl restart mongod
```

---

## ☁️ **PROBLEMAS DE AWS**

### **Problema: AWS CLI no está configurado correctamente**

#### **Síntomas:**
```bash
aws sts get-caller-identity
# Unable to locate credentials. You can configure credentials by running "aws configure".
```

#### **Diagnóstico:**
```bash
# 1. Verificar archivos de configuración
ls -la ~/.aws/
cat ~/.aws/credentials
cat ~/.aws/config

# 2. Verificar variables de entorno
env | grep AWS
```

#### **Soluciones:**
```bash
# Solución 1: Reconfigurar AWS CLI
aws configure
# AWS Access Key ID: [Tu Access Key]
# AWS Secret Access Key: [Tu Secret Key]
# Default region name: us-east-1
# Default output format: json

# Solución 2: Verificar permisos de archivos
chmod 600 ~/.aws/credentials
chmod 600 ~/.aws/config

# Solución 3: Configurar manualmente
mkdir -p ~/.aws
cat > ~/.aws/credentials << EOF
[default]
aws_access_key_id = YOUR_ACCESS_KEY
aws_secret_access_key = YOUR_SECRET_KEY
EOF

cat > ~/.aws/config << EOF
[default]
region = us-east-1
output = json
EOF
```

### **Problema: No puedo crear recursos en AWS (permisos)**

#### **Síntomas:**
```bash
aws rds create-db-instance --db-instance-identifier test
# An error occurred (AccessDenied) when calling the CreateDBInstance operation
```

#### **Diagnóstico:**
```bash
# 1. Verificar identidad actual
aws sts get-caller-identity

# 2. Verificar permisos específicos
aws iam simulate-principal-policy \
    --policy-source-arn $(aws sts get-caller-identity --query Arn --output text) \
    --action-names rds:CreateDBInstance \
    --resource-arns "*"
```

#### **Soluciones:**
```bash
# Solución 1: Verificar políticas IAM
# En AWS Console: IAM > Users > [tu usuario] > Permissions

# Solución 2: Usar usuario con permisos administrativos
# Crear nuevo IAM user con política AdministratorAccess

# Solución 3: Verificar límites de servicio
aws service-quotas get-service-quota \
    --service-code rds \
    --quota-code L-7B6409FD
```

### **Problema: Instancias RDS no son accesibles desde OnPrem**

#### **Síntomas:**
```bash
mysql -h myinstance.xxxxxxxx.us-east-1.rds.amazonaws.com -u dbadmin -p
# ERROR 2003 (HY000): Can't connect to MySQL server
```

#### **Diagnóstico:**
```bash
# 1. Verificar security groups
aws ec2 describe-security-groups --group-ids sg-xxxxxxxx

# 2. Verificar estado de la instancia
aws rds describe-db-instances --db-instance-identifier myinstance

# 3. Testing de conectividad
telnet myinstance.xxxxxxxx.us-east-1.rds.amazonaws.com 3306
```

#### **Soluciones:**
```bash
# Solución 1: Configurar security group
aws ec2 authorize-security-group-ingress \
    --group-id sg-xxxxxxxx \
    --protocol tcp \
    --port 3306 \
    --cidr 0.0.0.0/0

# Solución 2: Verificar subnet group
aws rds describe-db-subnet-groups

# Solución 3: Verificar publicly accessible
aws rds modify-db-instance \
    --db-instance-identifier myinstance \
    --publicly-accessible
```

---

## 🔧 **PROBLEMAS DE HERRAMIENTAS**

### **Problema: Prometheus no puede scrape targets**

#### **Síntomas:**
```bash
# En Prometheus UI: Status > Targets
# Todos los targets aparecen como "DOWN"
```

#### **Diagnóstico:**
```bash
# 1. Verificar configuración de Prometheus
cat /etc/prometheus/prometheus.yml

# 2. Verificar logs de Prometheus
sudo journalctl -u prometheus -f

# 3. Testing manual de endpoints
curl http://192.168.56.10:9104/metrics  # MySQL exporter
```

#### **Soluciones:**
```bash
# Solución 1: Verificar exporters están ejecutándose
sudo systemctl status node_exporter
sudo systemctl status mysqld_exporter
sudo systemctl status postgres_exporter

# Solución 2: Configurar firewall
sudo ufw allow 9100  # node_exporter
sudo ufw allow 9104  # mysqld_exporter
sudo ufw allow 9187  # postgres_exporter

# Solución 3: Verificar configuración de exporters
# MySQL exporter
cat /etc/default/mysqld_exporter

# PostgreSQL exporter
cat /etc/default/postgres_exporter

# Solución 4: Reiniciar Prometheus
sudo systemctl restart prometheus
```

### **Problema: Grafana no puede conectar a Prometheus**

#### **Síntomas:**
```bash
# En Grafana UI: Configuration > Data Sources
# "HTTP Error Bad Gateway"
```

#### **Diagnóstico:**
```bash
# 1. Verificar Prometheus está ejecutándose
curl http://192.168.56.13:9090/api/v1/status/config

# 2. Verificar logs de Grafana
sudo journalctl -u grafana-server -f

# 3. Verificar configuración de data source
# En Grafana UI verificar URL: http://localhost:9090
```

#### **Soluciones:**
```bash
# Solución 1: Usar IP correcta en data source
# Cambiar URL a: http://192.168.56.13:9090

# Solución 2: Verificar firewall
sudo ufw allow 9090

# Solución 3: Reiniciar servicios
sudo systemctl restart prometheus
sudo systemctl restart grafana-server

# Solución 4: Verificar configuración de Grafana
sudo nano /etc/grafana/grafana.ini
# Verificar sección [server]
```

---

## 📊 **PROBLEMAS DE PERFORMANCE**

### **Problema: Queries muy lentas en MySQL**

#### **Síntomas:**
```sql
SELECT * FROM products WHERE category = 'electronics';
-- Query takes 30+ seconds
```

#### **Diagnóstico:**
```sql
-- 1. Verificar slow query log
SHOW VARIABLES LIKE 'slow_query_log';
SHOW VARIABLES LIKE 'long_query_time';

-- 2. Analizar query plan
EXPLAIN SELECT * FROM products WHERE category = 'electronics';

-- 3. Verificar índices
SHOW INDEX FROM products;

-- 4. Verificar estadísticas de tabla
ANALYZE TABLE products;
```

#### **Soluciones:**
```sql
-- Solución 1: Crear índices apropiados
CREATE INDEX idx_category ON products(category);

-- Solución 2: Optimizar configuración MySQL
-- En /etc/mysql/mysql.conf.d/mysqld.cnf:
-- innodb_buffer_pool_size = 1G
-- query_cache_size = 256M

-- Solución 3: Actualizar estadísticas
ANALYZE TABLE products;
OPTIMIZE TABLE products;

-- Solución 4: Reescribir query
SELECT id, name, price FROM products 
WHERE category = 'electronics' 
LIMIT 100;
```

### **Problema: PostgreSQL consume mucha memoria**

#### **Síntomas:**
```bash
free -h
# Available memory very low
# PostgreSQL processes using 3GB+ RAM
```

#### **Diagnóstico:**
```sql
-- 1. Verificar configuración de memoria
SHOW shared_buffers;
SHOW work_mem;
SHOW maintenance_work_mem;

-- 2. Verificar conexiones activas
SELECT count(*) FROM pg_stat_activity;

-- 3. Verificar queries largas
SELECT query, state, query_start 
FROM pg_stat_activity 
WHERE state = 'active';
```

#### **Soluciones:**
```bash
# Solución 1: Optimizar configuración PostgreSQL
sudo nano /etc/postgresql/14/main/postgresql.conf

# Para VM con 4GB RAM:
# shared_buffers = 1GB
# work_mem = 4MB
# maintenance_work_mem = 256MB
# effective_cache_size = 3GB

# Solución 2: Configurar connection pooling
sudo apt install pgbouncer
sudo nano /etc/pgbouncer/pgbouncer.ini

# Solución 3: Terminar conexiones idle
SELECT pg_terminate_backend(pid) 
FROM pg_stat_activity 
WHERE state = 'idle' 
AND query_start < now() - interval '1 hour';

# Solución 4: Reiniciar PostgreSQL
sudo systemctl restart postgresql
```

---

## 🆘 **PROCEDIMIENTOS DE EMERGENCIA**

### **Procedimiento: Reset completo del entorno**

#### **Cuándo usar:**
- Múltiples servicios no funcionan
- Configuraciones corruptas
- Después de cambios experimentales fallidos

#### **Pasos:**
```bash
# 1. Hacer backup de datos importantes
mkdir -p ~/backup/$(date +%Y%m%d)
mysqldump -h 192.168.56.10 -u dbadmin -pDBAAdmin2024! --all-databases > ~/backup/$(date +%Y%m%d)/mysql_backup.sql
pg_dumpall -h 192.168.56.11 -U dbadmin > ~/backup/$(date +%Y%m%d)/postgresql_backup.sql
mongodump --host 192.168.56.12:27017 -u dbadmin -p DBAAdmin2024! --authenticationDatabase admin --out ~/backup/$(date +%Y%m%d)/mongodb_backup

# 2. Parar todos los servicios
sudo systemctl stop mysql postgresql mongod prometheus grafana-server

# 3. Limpiar configuraciones
sudo rm -rf /var/lib/mysql/*
sudo rm -rf /var/lib/postgresql/14/main/*
sudo rm -rf /var/lib/mongodb/*

# 4. Re-ejecutar scripts de instalación
cd ~/scripts
./install_mysql_onprem.sh
./install_postgresql_onprem.sh
./install_mongodb_onprem.sh

# 5. Restaurar datos
mysql -u root -p < ~/backup/$(date +%Y%m%d)/mysql_backup.sql
sudo -u postgres psql < ~/backup/$(date +%Y%m%d)/postgresql_backup.sql
mongorestore --host 192.168.56.12:27017 -u dbadmin -p DBAAdmin2024! --authenticationDatabase admin ~/backup/$(date +%Y%m%d)/mongodb_backup
```

### **Procedimiento: Recuperación de VM corrupta**

#### **Cuándo usar:**
- VM no inicia
- Sistema de archivos corrupto
- Kernel panic

#### **Pasos:**
```bash
# 1. Crear snapshot antes de cualquier cambio
VBoxManage snapshot "DBA-Lab-MySQL" take "before_recovery"

# 2. Intentar boot en modo recovery
# En GRUB, seleccionar "Advanced options" > "recovery mode"

# 3. Si no funciona, restaurar desde snapshot anterior
VBoxManage snapshot "DBA-Lab-MySQL" restore "working_snapshot"

# 4. Si no hay snapshots, recrear VM
# Clonar VM funcional
VBoxManage clonevm "DBA-Lab-PostgreSQL" --name "DBA-Lab-MySQL-New" --register

# 5. Reconfigurar IP y servicios
sudo nano /etc/netplan/00-installer-config.yaml
# Cambiar IP a 192.168.56.10
sudo netplan apply
```

---

## 📞 **CONTACTO Y ESCALACIÓN**

### **Niveles de Soporte**

#### **Nivel 1: Auto-diagnóstico (Tú mismo)**
1. Consultar esta guía de troubleshooting
2. Ejecutar scripts de diagnóstico
3. Buscar en logs de error
4. Consultar documentación oficial

#### **Nivel 2: Comunidad (Compañeros de clase)**
1. Preguntar en el foro del programa
2. Consultar con compañeros en Slack/Discord
3. Participar en sesiones de peer mentoring
4. Revisar soluciones compartidas en GitHub

#### **Nivel 3: Instructor (Soporte oficial)**
1. Contactar durante office hours
2. Enviar email con detalles del problema
3. Solicitar sesión 1-on-1
4. Escalar a soporte técnico si es necesario

### **Información a incluir al reportar problemas**

#### **Template de reporte:**
```
PROBLEMA: [Descripción breve del problema]

SÍNTOMAS:
- [Qué está pasando exactamente]
- [Mensajes de error específicos]
- [Cuándo ocurre el problema]

ENTORNO:
- SO: [Ubuntu 20.04, etc.]
- VM: [DBA-Lab-MySQL, etc.]
- Semana del programa: [Semana 0, 1, etc.]

PASOS PARA REPRODUCIR:
1. [Paso 1]
2. [Paso 2]
3. [Paso 3]

DIAGNÓSTICO REALIZADO:
- [Scripts ejecutados]
- [Logs revisados]
- [Soluciones intentadas]

ARCHIVOS ADJUNTOS:
- [Logs relevantes]
- [Screenshots si aplica]
- [Archivos de configuración]
```

### **Contactos de Emergencia**
```
Instructor Principal: instructor@dba-program.com
Soporte Técnico: soporte@dba-program.com
Foro del Programa: https://forum.dba-program.com
Slack/Discord: [Enlaces proporcionados por el instructor]

Horarios de Soporte:
- Lunes a Viernes: 9:00-17:00
- Sábados: 10:00-14:00 (solo emergencias)
- Domingos: No disponible

Tiempo de Respuesta:
- Problemas críticos: 2-4 horas
- Problemas normales: 24-48 horas
- Consultas generales: 48-72 horas
```

---

**🔧 Esta guía cubre los problemas más comunes que encontrarás durante el programa. Manténla a mano y consulta siempre los logs de error para obtener información específica sobre cada problema. ¡La mayoría de los problemas tienen solución rápida si sigues los procedimientos correctos!**
