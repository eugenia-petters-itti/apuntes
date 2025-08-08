# 🔧 PREREQUISITOS TÉCNICOS
## DBA Cloud OnPrem Junior - Todo lo que necesitas saber ANTES de empezar

### 🎯 **INTRODUCCIÓN**
Este documento detalla todos los conocimientos técnicos, hardware, software y configuraciones que necesitas ANTES de comenzar el programa. Completar estos prerequisitos es OBLIGATORIO para el éxito en el curso.

---

## 💻 **REQUISITOS DE HARDWARE**

### **Configuración Mínima (Funcional pero limitada)**
- **Procesador:** Intel i5 4ta gen / AMD Ryzen 5 (4 cores, 2.5GHz+)
- **RAM:** 16GB DDR4 (mínimo absoluto)
- **Almacenamiento:** 100GB libres en SSD
- **Red:** 10 Mbps estable, latencia <50ms a AWS us-east-1

### **Configuración Recomendada (Experiencia óptima)**
- **Procesador:** Intel i7 8va gen+ / AMD Ryzen 7 (8 cores, 3.0GHz+)
- **RAM:** 32GB DDR4 (recomendado fuertemente)
- **Almacenamiento:** 200GB libres en NVMe SSD
- **Red:** 25+ Mbps estable, latencia <30ms a AWS us-east-1

### **Configuración Profesional (Para instructores/avanzados)**
- **Procesador:** Intel i9 / AMD Ryzen 9 (12+ cores, 3.5GHz+)
- **RAM:** 64GB DDR4
- **Almacenamiento:** 500GB libres en NVMe SSD
- **Red:** 50+ Mbps dedicado, latencia <20ms a AWS us-east-1

### **Verificación de Hardware**
```bash
# Verificar CPU
lscpu | grep -E '^CPU\(s\)|^Thread|^Core|^Model name'

# Verificar RAM
free -h
cat /proc/meminfo | grep MemTotal

# Verificar almacenamiento
df -h
lsblk

# Verificar conectividad a AWS
ping -c 5 ec2.us-east-1.amazonaws.com
curl -w "@curl-format.txt" -o /dev/null -s "https://ec2.us-east-1.amazonaws.com"
```

**Checklist Hardware:**
- [ ] ✅ CPU: 4+ cores verificados
- [ ] ✅ RAM: 16GB+ verificados
- [ ] ✅ Disco: 100GB+ libres verificados
- [ ] ✅ Red: <50ms latencia a AWS verificada

---

## 🖥️ **REQUISITOS DE SOFTWARE**

### **Sistema Operativo Soportado**
```bash
# Opción 1: Ubuntu 20.04+ LTS (RECOMENDADO)
lsb_release -a

# Opción 2: CentOS 8+ / RHEL 8+
cat /etc/redhat-release

# Opción 3: macOS 10.15+ (Catalina o superior)
sw_vers

# Opción 4: Windows 10/11 Pro (con WSL2)
wsl --version
```

### **Herramientas de Virtualización**
```bash
# Opción 1: VirtualBox (GRATUITO - Recomendado para estudiantes)
virtualbox --help

# Opción 2: VMware Workstation Pro (PAGADO - Mejor performance)
vmware --version

# Opción 3: Hyper-V (Windows Pro/Enterprise)
Get-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V

# Opción 4: KVM/QEMU (Linux avanzado)
kvm-ok
```

### **Herramientas de Desarrollo**
```bash
# Git (OBLIGATORIO)
git --version

# Curl/Wget (OBLIGATORIO)
curl --version
wget --version

# Text Editor avanzado (OBLIGATORIO - elegir uno)
vim --version
nano --version
code --version  # VS Code

# Terminal avanzado (RECOMENDADO)
tmux -V
screen --version
```

### **AWS CLI y Herramientas Cloud**
```bash
# AWS CLI v2 (OBLIGATORIO)
aws --version

# Terraform (OBLIGATORIO para Semana 4)
terraform --version

# Docker (OPCIONAL pero recomendado)
docker --version

# kubectl (OPCIONAL para contenedores)
kubectl version --client
```

**Checklist Software Base:**
- [ ] ✅ SO soportado instalado
- [ ] ✅ Virtualización funcionando
- [ ] ✅ Git instalado y configurado
- [ ] ✅ Editor de texto avanzado
- [ ] ✅ AWS CLI v2 instalado
- [ ] ✅ Terraform instalado

---

## 🗄️ **CONOCIMIENTOS TÉCNICOS PREVIOS**

### **Linux/Unix Básico (OBLIGATORIO)**
```bash
# Navegación de archivos
ls -la
cd /path/to/directory
pwd
find /path -name "*.conf"

# Gestión de archivos
cp source destination
mv old_name new_name
rm -rf directory
chmod 755 script.sh
chown user:group file

# Procesos y servicios
ps aux | grep mysql
top
htop
systemctl status mysql
systemctl start/stop/restart service

# Red y conectividad
netstat -tulpn
ss -tulpn
iptables -L
ufw status
ping host
telnet host port
```

**Test de Conocimientos Linux:**
```bash
# Ejecuta estos comandos y explica qué hacen:
sudo find /var/log -name "*.log" -mtime +7 -exec rm {} \;
ps aux | grep -v grep | grep mysql | awk '{print $2}' | xargs kill -9
netstat -tulpn | grep :3306 | awk '{print $7}' | cut -d'/' -f1
```

### **SQL Básico (OBLIGATORIO)**
```sql
-- Consultas básicas
SELECT column1, column2 FROM table WHERE condition;
INSERT INTO table (col1, col2) VALUES (val1, val2);
UPDATE table SET column = value WHERE condition;
DELETE FROM table WHERE condition;

-- Joins básicos
SELECT t1.col, t2.col 
FROM table1 t1 
JOIN table2 t2 ON t1.id = t2.foreign_id;

-- Funciones agregadas
SELECT COUNT(*), AVG(price), MAX(date) 
FROM orders 
GROUP BY customer_id 
HAVING COUNT(*) > 5;

-- Subconsultas
SELECT * FROM products 
WHERE price > (SELECT AVG(price) FROM products);
```

**Test de Conocimientos SQL:**
```sql
-- Crea una consulta que muestre:
-- 1. Clientes que han hecho más de 3 pedidos
-- 2. El total gastado por cada cliente
-- 3. Ordenado por total gastado descendente
-- 4. Solo clientes con gasto > $1000

-- Tu respuesta aquí:
```

### **Conceptos de Red (OBLIGATORIO)**
```bash
# Direccionamiento IP
# ¿Qué significa 192.168.1.0/24?
# ¿Cuántas IPs disponibles tiene?
# ¿Cuál es la IP de broadcast?

# Puertos y servicios
# MySQL: 3306
# PostgreSQL: 5432
# MongoDB: 27017
# SSH: 22
# HTTP: 80
# HTTPS: 443

# Firewall básico
sudo ufw allow from 192.168.1.0/24 to any port 3306
sudo ufw deny 3306
sudo ufw status numbered
```

**Test de Conocimientos Red:**
- ¿Qué puerto usa PostgreSQL por defecto?
- ¿Cómo permites acceso SSH solo desde tu red local?
- ¿Qué significa una IP 10.0.0.0/8?
- ¿Cómo verificas qué proceso usa el puerto 3306?

### **Inglés Técnico (OBLIGATORIO)**
```
# Debes poder entender:
- Documentación oficial de MySQL, PostgreSQL, MongoDB
- Mensajes de error en inglés
- Logs de sistema en inglés
- Tutoriales y foros técnicos

# Vocabulario esencial:
- Database, Table, Index, Query, Schema
- Backup, Restore, Recovery, Replication
- Performance, Optimization, Tuning
- Security, Authentication, Authorization
- Monitoring, Alerting, Troubleshooting
```

**Test de Inglés Técnico:**
```
Traduce y explica estos mensajes de error:
1. "Access denied for user 'root'@'localhost'"
2. "Table 'database.table' doesn't exist"
3. "Disk full (/tmp); waiting for someone to free some space"
4. "Connection refused on port 3306"
```

**Checklist Conocimientos Previos:**
- [ ] ✅ Linux básico: Navegación, archivos, procesos
- [ ] ✅ SQL básico: SELECT, INSERT, UPDATE, DELETE, JOINs
- [ ] ✅ Red básica: IP, puertos, firewall
- [ ] ✅ Inglés técnico: Documentación y errores

---

## ☁️ **CONFIGURACIÓN AWS**

### **Cuenta AWS (OBLIGATORIO)**
```bash
# 1. Crear cuenta AWS
# - Ir a https://aws.amazon.com
# - Crear cuenta (requiere tarjeta de crédito)
# - Verificar email y teléfono

# 2. Configurar billing alerts
# - CloudWatch > Billing > Create Alarm
# - Alert cuando gasto > $50/mes

# 3. Crear IAM user para laboratorio
aws iam create-user --user-name dba-lab-user
aws iam create-access-key --user-name dba-lab-user
```

### **Permisos AWS Necesarios**
```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "rds:*",
                "docdb:*",
                "ec2:*",
                "vpc:*",
                "s3:*",
                "cloudwatch:*",
                "logs:*"
            ],
            "Resource": "*"
        }
    ]
}
```

### **Configuración AWS CLI**
```bash
# Instalar AWS CLI v2
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install

# Configurar credenciales
aws configure
# AWS Access Key ID: [Tu Access Key]
# AWS Secret Access Key: [Tu Secret Key]  
# Default region name: us-east-1
# Default output format: json

# Verificar configuración
aws sts get-caller-identity
aws ec2 describe-regions
```

### **Estimación de Costos AWS**
```
Recursos que usaremos durante el programa:

RDS MySQL (db.t3.micro):     ~$15/mes
RDS PostgreSQL (db.t3.micro): ~$15/mes  
DocumentDB (db.t3.medium):   ~$45/mes
EC2 Bastion (t3.micro):      ~$8/mes
VPC, Subnets, Security Groups: $0
CloudWatch Logs:             ~$5/mes
S3 Storage (backups):        ~$2/mes

TOTAL ESTIMADO: $90/mes durante 5 semanas = ~$110 total
```

**Checklist AWS:**
- [ ] ✅ Cuenta AWS creada y verificada
- [ ] ✅ Billing alerts configuradas (<$50/mes)
- [ ] ✅ IAM user creado con permisos necesarios
- [ ] ✅ AWS CLI instalado y configurado
- [ ] ✅ Conectividad a AWS verificada

---

## 🔧 **CONFIGURACIÓN DE LABORATORIO**

### **Estructura de VMs Requerida**
```
VM1: DBA-Lab-MySQL
- OS: Ubuntu 20.04 LTS
- RAM: 4GB
- Disco: 25GB
- IP: 192.168.56.10
- Servicios: MySQL 8.0, MySQL Exporter

VM2: DBA-Lab-PostgreSQL  
- OS: Ubuntu 20.04 LTS
- RAM: 4GB
- Disco: 25GB
- IP: 192.168.56.11
- Servicios: PostgreSQL 14, PostgreSQL Exporter

VM3: DBA-Lab-MongoDB
- OS: Ubuntu 20.04 LTS
- RAM: 4GB  
- Disco: 25GB
- IP: 192.168.56.12
- Servicios: MongoDB 6.0, MongoDB Exporter

VM4: DBA-Lab-Tools
- OS: Ubuntu 20.04 LTS
- RAM: 4GB
- Disco: 25GB  
- IP: 192.168.56.13
- Servicios: Prometheus, Grafana, Scripts
```

### **Red de Laboratorio**
```
Host-Only Network: 192.168.56.0/24
Gateway: 192.168.56.1 (tu máquina host)
DNS: 8.8.8.8, 8.8.4.4

Conectividad requerida:
- VM ↔ VM: Todas las VMs se comunican entre sí
- VM ↔ Host: Acceso desde tu máquina a todas las VMs
- VM ↔ Internet: Acceso a internet para descargas
- VM ↔ AWS: Acceso a servicios AWS desde VMs
```

### **Scripts de Verificación**
```bash
# Crear script de verificación completa
cat > verify_prerequisites.sh << 'EOF'
#!/bin/bash

echo "=== VERIFICACIÓN DE PREREQUISITOS DBA CLOUD ONPREM JUNIOR ==="

# Verificar hardware
echo "1. Verificando hardware..."
CORES=$(nproc)
RAM_GB=$(free -g | awk '/^Mem:/{print $2}')
DISK_GB=$(df -BG / | awk 'NR==2{print $4}' | sed 's/G//')

echo "   CPU Cores: $CORES (mínimo 4)"
echo "   RAM: ${RAM_GB}GB (mínimo 16GB)"
echo "   Disco libre: ${DISK_GB}GB (mínimo 100GB)"

# Verificar software
echo "2. Verificando software..."
command -v git >/dev/null 2>&1 && echo "   ✅ Git instalado" || echo "   ❌ Git NO instalado"
command -v aws >/dev/null 2>&1 && echo "   ✅ AWS CLI instalado" || echo "   ❌ AWS CLI NO instalado"
command -v terraform >/dev/null 2>&1 && echo "   ✅ Terraform instalado" || echo "   ❌ Terraform NO instalado"
command -v virtualbox >/dev/null 2>&1 && echo "   ✅ VirtualBox instalado" || echo "   ❌ VirtualBox NO instalado"

# Verificar AWS
echo "3. Verificando AWS..."
aws sts get-caller-identity >/dev/null 2>&1 && echo "   ✅ AWS configurado" || echo "   ❌ AWS NO configurado"

# Verificar conectividad
echo "4. Verificando conectividad..."
ping -c 1 8.8.8.8 >/dev/null 2>&1 && echo "   ✅ Internet OK" || echo "   ❌ Sin internet"
ping -c 1 ec2.us-east-1.amazonaws.com >/dev/null 2>&1 && echo "   ✅ AWS alcanzable" || echo "   ❌ AWS no alcanzable"

echo "=== VERIFICACIÓN COMPLETADA ==="
EOF

chmod +x verify_prerequisites.sh
./verify_prerequisites.sh
```

**Checklist Configuración:**
- [ ] ✅ 4 VMs creadas con especificaciones correctas
- [ ] ✅ Red host-only configurada (192.168.56.0/24)
- [ ] ✅ Conectividad VM ↔ VM verificada
- [ ] ✅ Conectividad VM ↔ Internet verificada
- [ ] ✅ Conectividad VM ↔ AWS verificada

---

## 📚 **RECURSOS DE PREPARACIÓN**

### **Cursos Preparatorios Recomendados**
```
Linux Básico:
- "Linux Command Line Basics" (Udacity - GRATUITO)
- "Introduction to Linux" (edX - GRATUITO)

SQL Básico:
- "SQL for Everybody" (Coursera - Universidad de Michigan)
- "W3Schools SQL Tutorial" (GRATUITO online)

AWS Básico:
- "AWS Cloud Practitioner Essentials" (AWS Training - GRATUITO)
- "Introduction to AWS" (Coursera - GRATUITO)
```

### **Documentación Oficial**
```
MySQL: https://dev.mysql.com/doc/
PostgreSQL: https://www.postgresql.org/docs/
MongoDB: https://docs.mongodb.com/
AWS RDS: https://docs.aws.amazon.com/rds/
AWS DocumentDB: https://docs.aws.amazon.com/documentdb/
```

### **Herramientas de Práctica**
```
SQL Online:
- SQLiteOnline.com
- DB Fiddle
- W3Schools SQL Tryit Editor

Linux Online:
- JSLinux
- Katacoda Linux Scenarios
- OverTheWire Bandit (wargames)

AWS Free Tier:
- AWS Free Tier Account
- AWS Educate (si eres estudiante)
```

---

## ✅ **CHECKLIST FINAL DE PREREQUISITOS**

### **Hardware y Software**
- [ ] ✅ Hardware cumple requisitos mínimos
- [ ] ✅ Sistema operativo soportado instalado
- [ ] ✅ VirtualBox/VMware instalado y funcionando
- [ ] ✅ 4 VMs Ubuntu 20.04 creadas y configuradas
- [ ] ✅ Red host-only configurada correctamente

### **Herramientas de Desarrollo**
- [ ] ✅ Git instalado y configurado
- [ ] ✅ Editor de texto avanzado (vim/nano/vscode)
- [ ] ✅ Terminal avanzado (tmux/screen opcional)
- [ ] ✅ AWS CLI v2 instalado y configurado
- [ ] ✅ Terraform instalado

### **Conocimientos Técnicos**
- [ ] ✅ Linux básico: Navegación, archivos, procesos, servicios
- [ ] ✅ SQL básico: SELECT, INSERT, UPDATE, DELETE, JOINs
- [ ] ✅ Red básica: IP, puertos, firewall, conectividad
- [ ] ✅ Inglés técnico: Documentación y mensajes de error

### **AWS y Cloud**
- [ ] ✅ Cuenta AWS creada y verificada
- [ ] ✅ Billing alerts configuradas
- [ ] ✅ IAM user con permisos necesarios
- [ ] ✅ Conectividad a AWS verificada
- [ ] ✅ Presupuesto de $110 para 5 semanas aprobado

### **Verificación Final**
- [ ] ✅ Script verify_prerequisites.sh ejecutado exitosamente
- [ ] ✅ Todas las VMs pueden comunicarse entre sí
- [ ] ✅ Todas las VMs tienen acceso a internet
- [ ] ✅ Todas las VMs pueden conectarse a AWS
- [ ] ✅ Todos los comandos básicos funcionan correctamente

---

## 🆘 **SOPORTE PARA PREREQUISITOS**

### **Si tienes problemas con los prerequisitos:**

1. **Revisa la documentación oficial** de cada herramienta
2. **Ejecuta el script de verificación** para identificar problemas específicos
3. **Consulta los foros de la comunidad** (Stack Overflow, Reddit)
4. **Contacta al soporte del programa** ANTES de que inicie el curso

### **Contacto de Soporte:**
- **Email:** prerequisitos@dba-program.com
- **Horarios:** Lunes a Viernes, 9:00-17:00
- **Tiempo de respuesta:** 24-48 horas

---

**⚠️ IMPORTANTE: Completar TODOS estos prerequisitos es OBLIGATORIO antes del primer día de clase. Los estudiantes que no cumplan con los prerequisitos no podrán participar efectivamente en el programa.**

**✅ Una vez completado todo, estarás listo para comenzar tu transformación hacia DBA Cloud OnPrem Junior!**
