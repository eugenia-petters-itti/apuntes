# Material Adicional y Complementario - DBA Cloud OnPrem Junior

## 📚 Índice Completo del Material Adicional

### 🎯 Objetivo
Este material adicional complementa los laboratorios principales con herramientas de automatización, datasets realistas, guías de instalación detalladas y recursos de soporte para facilitar la implementación y ejecución del programa de capacitación.

---

## 🛠️ Scripts de Instalación Automatizada

### 1. **MySQL OnPrem - Instalación Completa**
📄 **Archivo:** `scripts/install_mysql_onprem.sh`

#### Características:
- **Instalación automatizada** de MySQL 8.0 en Ubuntu
- **Configuración de seguridad** inicial completa
- **Creación de usuarios** de laboratorio predefinidos
- **Configuración de firewall** automática
- **Verificación de integridad** post-instalación
- **Script de información** del sistema generado

#### Usuarios creados automáticamente:
```bash
dbadmin / Admin123!        # Administrador completo
readonly / Read123!        # Solo lectura
readwrite / Write123!      # CRUD básico
backup_user / BackupPass123!  # Para backups
repl_user / ReplPass123!   # Para replicación
exporter / ExporterPass123!   # Para monitoreo
```

#### Uso:
```bash
chmod +x install_mysql_onprem.sh
./install_mysql_onprem.sh
```

### 2. **PostgreSQL OnPrem - Instalación Completa**
📄 **Archivo:** `scripts/install_postgresql_onprem.sh`

#### Características:
- **Instalación automatizada** de PostgreSQL 14 en Ubuntu
- **Configuración avanzada** con parámetros optimizados
- **Roles y usuarios** de laboratorio predefinidos
- **Configuración de SSL** y autenticación
- **WAL archiving** configurado
- **Extensiones útiles** instaladas (pg_stat_statements, uuid-ossp)

#### Usuarios creados automáticamente:
```bash
dbadmin / Admin123!           # Administrador completo
readonly / Read123!           # Solo lectura
readwrite / Write123!         # CRUD básico
app_user / AppPass123!        # Usuario de aplicación
backup_user / BackupPass123!  # Para backups
repl_user / ReplPass123!      # Para replicación
postgres_exporter / ExporterPass123!  # Para monitoreo
```

#### Uso:
```bash
chmod +x install_postgresql_onprem.sh
./install_postgresql_onprem.sh
```

### 3. **MongoDB OnPrem - Instalación Completa**
📄 **Archivo:** `scripts/install_mongodb_onprem.sh`

#### Características:
- **Instalación automatizada** de MongoDB 6.0 en Ubuntu
- **Configuración SSL/TLS** con certificados auto-firmados
- **Replica Set** configurado automáticamente
- **Autenticación** habilitada con usuarios predefinidos
- **Configuración de seguridad** avanzada
- **Herramientas adicionales** (mongosh, database tools)

#### Usuarios creados automáticamente:
```bash
admin / AdminPass123!         # Administrador completo
developer / DevPass123!       # Desarrollo
analyst / AnalystPass123!     # Solo lectura
app_user / AppPass123!        # Usuario de aplicación
backup_user / BackupPass123! # Para backups
```

#### Uso:
```bash
chmod +x install_mongodb_onprem.sh
./install_mongodb_onprem.sh
```

---

## 📊 Datasets Realistas para Laboratorios

### 1. **MySQL E-commerce Dataset**
📄 **Archivo:** `datasets/mysql_ecommerce_dataset.sql`

#### Características:
- **Tamaño:** ~50MB de datos
- **Tablas:** 12 tablas relacionales complejas
- **Registros:** 
  - 5,000 clientes
  - 1,000 productos
  - 8 proveedores
  - 15 categorías
  - Datos transaccionales realistas

#### Estructura de datos:
```sql
-- Tablas principales
categories (15 registros)
suppliers (8 registros)  
products (1,000 registros)
customers (5,000 registros)
customer_addresses (6,500 registros)
orders (datos generados dinámicamente)
order_items (datos relacionados)
inventory_movements (historial completo)
product_reviews (reseñas realistas)
discount_coupons (5 cupones activos)
coupon_usage (historial de uso)
```

#### Características avanzadas:
- **Procedimientos almacenados** para transacciones
- **Triggers** para actualización de inventario
- **Vistas** para reportes de ventas
- **Funciones** para cálculos de negocio
- **Índices optimizados** para performance

### 2. **PostgreSQL Analytics Dataset**
📄 **Archivo:** `datasets/postgresql_analytics_dataset.sql`

#### Características:
- **Tamaño:** ~30MB de datos
- **Enfoque:** Análisis de ventas retail
- **Registros:**
  - 100 tiendas
  - 2,000 productos
  - 500 empleados
  - 10,000 clientes
  - Inventario por tienda

#### Estructura de datos:
```sql
-- Tablas principales
regions (8 regiones)
stores (100 tiendas)
product_categories (15 categorías)
products (2,000 productos)
employees (500 empleados)
customers (10,000 clientes)
store_inventory (140,000 registros)
promotions (promociones activas)
```

#### Características avanzadas:
- **Datos JSONB** para atributos de productos
- **Índices GIN** para búsquedas complejas
- **Funciones PL/pgSQL** para análisis
- **Vistas materializadas** para reportes
- **Extensiones** (uuid-ossp, pg_stat_statements)

### 3. **MongoDB Social Media Dataset**
📄 **Archivo:** `datasets/mongodb_social_dataset.js`

#### Características:
- **Tamaño:** ~25MB de datos
- **Enfoque:** Red social con interacciones
- **Documentos:**
  - 1,000 usuarios
  - 5,000 posts
  - 15,000 comentarios
  - 25,000 likes
  - 8,000 relaciones de seguimiento

#### Estructura de colecciones:
```javascript
// Colecciones principales
users (1,000 documentos)
posts (5,000 documentos)
comments (15,000 documentos)
likes (25,000 documentos)
follows (8,000 documentos)
groups (grupos de interés)
```

#### Características avanzadas:
- **Documentos anidados** complejos
- **Arrays** de datos relacionados
- **Índices geoespaciales** para ubicaciones
- **Índices de texto** para búsquedas
- **Agregaciones** complejas para análisis
- **Vistas** para consultas frecuentes

---

## 🏗️ Infraestructura como Código (Terraform)

### 1. **Configuración Completa de Laboratorio**
📄 **Archivo:** `terraform/lab_infrastructure.tf`

#### Recursos creados:
```hcl
# Bases de datos
- RDS MySQL 8.0 (db.t3.micro)
- RDS PostgreSQL 14 (db.t3.micro)
- DocumentDB Cluster (db.t3.medium)

# Networking
- Security Groups específicos por servicio
- DB Subnet Groups
- VPC configuration

# Monitoreo
- CloudWatch Log Groups
- CloudWatch Alarms (CPU, conexiones)
- SNS Topics para alertas

# Compute
- EC2 Bastion Host
- Key Pairs para acceso SSH

# Configuración
- Parameter Groups optimizados
- IAM Roles para monitoreo
- Enhanced Monitoring habilitado
```

#### Variables configurables:
```hcl
variable "aws_region" {
  default = "us-east-1"
}

variable "student_count" {
  default = 20
}

variable "lab_duration_days" {
  default = 35
}

variable "db_password" {
  sensitive = true
  default = "LabPassword123!"
}
```

#### Outputs útiles:
```hcl
# Endpoints de conexión
mysql_endpoint
postgres_endpoint  
docdb_endpoint
bastion_public_ip

# Comandos de conexión
connection_commands

# Credenciales (sensibles)
database_passwords
```

### 2. **Script de Configuración Bastion**
📄 **Archivo:** `terraform/bastion_userdata.sh`

#### Herramientas instaladas:
- **MongoDB Shell (mongosh)** para DocumentDB
- **MySQL Client** para RDS MySQL
- **PostgreSQL Client** para RDS PostgreSQL
- **AWS CLI v2** para gestión de recursos
- **Certificados SSL** para DocumentDB

#### Scripts de conexión:
```bash
# Script automático para DocumentDB
~/connect_docdb.sh

# Aliases útiles
alias docdb='~/connect_docdb.sh'
alias ll='ls -la'
alias logs='sudo tail -f /var/log/messages'
```

---

## 📋 Guías de Implementación

### 1. **Checklist de Preparación**

#### Pre-requisitos del sistema:
- [ ] **Ubuntu 20.04 LTS** o superior
- [ ] **Mínimo 4GB RAM** por VM
- [ ] **50GB espacio libre** por VM
- [ ] **Acceso a internet** para descargas
- [ ] **Usuario con privilegios sudo**

#### Preparación AWS:
- [ ] **Cuenta AWS** con permisos administrativos
- [ ] **AWS CLI** configurado localmente
- [ ] **Terraform** instalado (v1.0+)
- [ ] **Claves SSH** generadas (`~/.ssh/id_rsa.pub`)

#### Preparación de red:
- [ ] **Puertos abiertos:** 3306 (MySQL), 5432 (PostgreSQL), 27017 (MongoDB)
- [ ] **Firewall configurado** apropiadamente
- [ ] **DNS resolution** funcionando

### 2. **Orden de Instalación Recomendado**

#### Paso 1: Preparar infraestructura OnPrem
```bash
# VM1 - MySQL
./scripts/install_mysql_onprem.sh

# VM2 - PostgreSQL  
./scripts/install_postgresql_onprem.sh

# VM3 - MongoDB
./scripts/install_mongodb_onprem.sh
```

#### Paso 2: Desplegar infraestructura Cloud
```bash
cd terraform/
terraform init
terraform plan
terraform apply
```

#### Paso 3: Cargar datasets
```bash
# MySQL
mysql -u root -p < datasets/mysql_ecommerce_dataset.sql

# PostgreSQL
psql -U postgres < datasets/postgresql_analytics_dataset.sql

# MongoDB
mongosh < datasets/mongodb_social_dataset.js
```

#### Paso 4: Verificar conectividad
```bash
# Probar conexiones OnPrem
mysql -u dbadmin -p -e "SELECT VERSION();"
psql -U dbadmin -d lab_test -c "SELECT version();"
mongosh --eval "db.version()"

# Probar conexiones Cloud (desde bastion)
ssh -i ~/.ssh/id_rsa ec2-user@<bastion-ip>
```

### 3. **Scripts de Verificación**

#### Verificación automática OnPrem:
```bash
# Cada script de instalación genera un script de info
~/mysql_lab_info.sh
~/postgresql_lab_info.sh  
~/mongodb_lab_info.sh
```

#### Verificación Terraform:
```bash
# Verificar outputs
terraform output

# Probar conexiones
terraform output connection_commands
```

---

## 🔧 Herramientas de Soporte

### 1. **Scripts de Mantenimiento**

#### Limpieza de recursos AWS:
```bash
# Limpiar todo el laboratorio
terraform destroy

# Limpiar solo bases de datos
terraform destroy -target=aws_db_instance.mysql_lab
```

#### Backup automático OnPrem:
```bash
# Scripts incluidos en cada instalación
~/backup_mysql.sh
~/backup_postgresql.sh
~/backup_mongodb.sh
```

### 2. **Monitoreo y Alertas**

#### CloudWatch Alarms configuradas:
- **CPU > 80%** en todas las instancias
- **Conexiones altas** en RDS
- **Storage casi lleno** en todas las DBs

#### Logs centralizados:
- **MySQL:** Error log, Slow query log
- **PostgreSQL:** Main log, Query log  
- **DocumentDB:** Audit log, Profiler log

### 3. **Troubleshooting**

#### Problemas comunes y soluciones:

**MySQL no inicia:**
```bash
sudo systemctl status mysql
sudo tail -f /var/log/mysql/error.log
sudo systemctl restart mysql
```

**PostgreSQL conexión rechazada:**
```bash
sudo -u postgres psql -c "SHOW listen_addresses;"
sudo vim /etc/postgresql/14/main/pg_hba.conf
sudo systemctl restart postgresql
```

**MongoDB SSL issues:**
```bash
mongosh --tls --tlsAllowInvalidCertificates
sudo tail -f /var/log/mongodb/mongod.log
```

---

## 📊 Métricas y Estadísticas

### Tamaños de Datasets:
| Dataset | Tamaño | Registros | Tablas/Colecciones |
|---------|--------|-----------|-------------------|
| MySQL E-commerce | ~50MB | 15,000+ | 12 tablas |
| PostgreSQL Analytics | ~30MB | 22,000+ | 10 tablas |
| MongoDB Social | ~25MB | 50,000+ | 6 colecciones |

### Tiempo de Instalación Estimado:
| Componente | Tiempo | Dependencias |
|------------|--------|--------------|
| MySQL OnPrem | 15-20 min | Internet, sudo |
| PostgreSQL OnPrem | 20-25 min | Internet, sudo |
| MongoDB OnPrem | 25-30 min | Internet, sudo |
| Terraform Deploy | 10-15 min | AWS CLI, credenciales |
| Dataset Loading | 5-10 min | Conexiones DB |

### Recursos de Sistema:
| Servicio | RAM | CPU | Disk | Network |
|----------|-----|-----|------|---------|
| MySQL | 2GB | 1 core | 20GB | 3306 |
| PostgreSQL | 2GB | 1 core | 20GB | 5432 |
| MongoDB | 2GB | 1 core | 20GB | 27017 |
| Monitoring | 4GB | 2 cores | 50GB | 9090,3000 |

---

## ✅ Checklist de Implementación Completa

### Pre-implementación:
- [ ] Infraestructura preparada (VMs + AWS)
- [ ] Scripts de instalación probados
- [ ] Datasets validados
- [ ] Terraform configurado
- [ ] Accesos y permisos verificados

### Durante implementación:
- [ ] Instalaciones OnPrem completadas
- [ ] Infraestructura Cloud desplegada
- [ ] Datasets cargados correctamente
- [ ] Conectividad híbrida verificada
- [ ] Monitoreo funcionando

### Post-implementación:
- [ ] Scripts de verificación ejecutados
- [ ] Documentación actualizada
- [ ] Credenciales distribuidas
- [ ] Backup inicial realizado
- [ ] Alertas configuradas

---

## 🎯 Beneficios del Material Adicional

### Para Instructores:
- ✅ **Instalación automatizada** reduce tiempo de setup
- ✅ **Datasets realistas** proporcionan experiencia práctica
- ✅ **Infraestructura como código** garantiza consistencia
- ✅ **Scripts de verificación** facilitan troubleshooting

### Para Estudiantes:
- ✅ **Entorno consistente** en todas las máquinas
- ✅ **Datos realistas** para práctica significativa
- ✅ **Herramientas preconfiguradas** listas para usar
- ✅ **Documentación completa** para referencia

### Para la Organización:
- ✅ **Reducción de costos** de setup manual
- ✅ **Escalabilidad** para múltiples cohortes
- ✅ **Calidad consistente** del entrenamiento
- ✅ **Mantenimiento simplificado** de la infraestructura

---

**Este material adicional transforma la implementación del programa de DBA Cloud OnPrem Junior de un proceso manual complejo a una experiencia automatizada, escalable y consistente, garantizando el éxito del programa de capacitación.**
