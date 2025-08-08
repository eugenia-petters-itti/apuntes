# Laboratorio Semana 1 - Fundamentos Híbridos
## DBA Cloud OnPrem Junior

### 🎯 Objetivos del Laboratorio
Al finalizar este laboratorio, el estudiante será capaz de:
- Crear instancias RDS y DocumentDB en AWS
- Configurar conectividad OnPrem ↔ Cloud
- Comparar arquitecturas OnPrem vs Cloud
- Configurar endpoints y tipos de conexión
- Implementar backups automáticos y manuales

### 🖥️ Infraestructura Requerida
```yaml
# OnPrem (de Semana 0)
VM1 - MySQL OnPrem: Funcionando
VM2 - PostgreSQL OnPrem: Funcionando

# AWS Cloud
- Cuenta AWS con permisos para:
  - RDS (create, modify, delete)
  - DocumentDB (create, modify, delete)
  - VPC (create subnets, security groups)
  - EC2 (create instances para bastion)

# Herramientas
- AWS CLI configurado
- Cliente MySQL/PostgreSQL
- mongosh para DocumentDB
```

---

## 📋 Laboratorio 1: Creación de RDS MySQL

### Paso 1: Configuración de VPC y Seguridad
```bash
# Configurar AWS CLI (si no está configurado)
aws configure
# AWS Access Key ID: [Tu Access Key]
# AWS Secret Access Key: [Tu Secret Key]
# Default region: us-east-1
# Default output format: json

# Crear Security Group para RDS
aws ec2 create-security-group \
    --group-name rds-mysql-sg \
    --description "Security group for RDS MySQL" \
    --vpc-id vpc-xxxxxxxxx

# Obtener el Security Group ID
SG_ID=$(aws ec2 describe-security-groups \
    --group-names rds-mysql-sg \
    --query 'SecurityGroups[0].GroupId' \
    --output text)

# Permitir acceso MySQL desde OnPrem (ajustar IP según tu red)
aws ec2 authorize-security-group-ingress \
    --group-id $SG_ID \
    --protocol tcp \
    --port 3306 \
    --cidr 0.0.0.0/0  # En producción usar IP específica

echo "Security Group ID: $SG_ID"
```

### Paso 2: Crear Subnet Group para RDS
```bash
# Crear DB Subnet Group
aws rds create-db-subnet-group \
    --db-subnet-group-name mysql-subnet-group \
    --db-subnet-group-description "Subnet group for MySQL RDS" \
    --subnet-ids subnet-xxxxxxxxx subnet-yyyyyyyyy

# Verificar creación
aws rds describe-db-subnet-groups \
    --db-subnet-group-name mysql-subnet-group
```

### Paso 3: Crear Instancia RDS MySQL
```bash
# Crear instancia RDS MySQL
aws rds create-db-instance \
    --db-instance-identifier mysql-lab-instance \
    --db-instance-class db.t3.micro \
    --engine mysql \
    --engine-version 8.0.35 \
    --master-username admin \
    --master-user-password 'MyRDS123!' \
    --allocated-storage 20 \
    --storage-type gp2 \
    --vpc-security-group-ids $SG_ID \
    --db-subnet-group-name mysql-subnet-group \
    --backup-retention-period 7 \
    --storage-encrypted \
    --multi-az false \
    --publicly-accessible true \
    --auto-minor-version-upgrade true \
    --deletion-protection false

# Monitorear creación (toma ~10-15 minutos)
aws rds describe-db-instances \
    --db-instance-identifier mysql-lab-instance \
    --query 'DBInstances[0].DBInstanceStatus'
```

### Paso 4: Obtener Endpoint y Probar Conexión
```bash
# Obtener endpoint cuando esté disponible
RDS_ENDPOINT=$(aws rds describe-db-instances \
    --db-instance-identifier mysql-lab-instance \
    --query 'DBInstances[0].Endpoint.Address' \
    --output text)

echo "RDS MySQL Endpoint: $RDS_ENDPOINT"

# Probar conexión desde OnPrem
mysql -h $RDS_ENDPOINT -u admin -p -e "SELECT VERSION(), @@hostname;"
```

---

## 📋 Laboratorio 2: Creación de RDS PostgreSQL

### Paso 1: Crear Security Group para PostgreSQL
```bash
# Crear Security Group para PostgreSQL
aws ec2 create-security-group \
    --group-name rds-postgres-sg \
    --description "Security group for RDS PostgreSQL" \
    --vpc-id vpc-xxxxxxxxx

# Obtener Security Group ID
PG_SG_ID=$(aws ec2 describe-security-groups \
    --group-names rds-postgres-sg \
    --query 'SecurityGroups[0].GroupId' \
    --output text)

# Permitir acceso PostgreSQL
aws ec2 authorize-security-group-ingress \
    --group-id $PG_SG_ID \
    --protocol tcp \
    --port 5432 \
    --cidr 0.0.0.0/0
```

### Paso 2: Crear Instancia RDS PostgreSQL
```bash
# Crear instancia RDS PostgreSQL
aws rds create-db-instance \
    --db-instance-identifier postgres-lab-instance \
    --db-instance-class db.t3.micro \
    --engine postgres \
    --engine-version 14.9 \
    --master-username postgres \
    --master-user-password 'MyRDS123!' \
    --allocated-storage 20 \
    --storage-type gp2 \
    --vpc-security-group-ids $PG_SG_ID \
    --db-subnet-group-name mysql-subnet-group \
    --backup-retention-period 7 \
    --storage-encrypted \
    --multi-az false \
    --publicly-accessible true \
    --auto-minor-version-upgrade true \
    --deletion-protection false

# Obtener endpoint
PG_RDS_ENDPOINT=$(aws rds describe-db-instances \
    --db-instance-identifier postgres-lab-instance \
    --query 'DBInstances[0].Endpoint.Address' \
    --output text)

echo "RDS PostgreSQL Endpoint: $PG_RDS_ENDPOINT"
```

---

## 📋 Laboratorio 3: Creación de DocumentDB

### Paso 1: Crear Security Group para DocumentDB
```bash
# Crear Security Group para DocumentDB
aws ec2 create-security-group \
    --group-name docdb-sg \
    --description "Security group for DocumentDB" \
    --vpc-id vpc-xxxxxxxxx

# Obtener Security Group ID
DOCDB_SG_ID=$(aws ec2 describe-security-groups \
    --group-names docdb-sg \
    --query 'SecurityGroups[0].GroupId' \
    --output text)

# Permitir acceso MongoDB (puerto 27017)
aws ec2 authorize-security-group-ingress \
    --group-id $DOCDB_SG_ID \
    --protocol tcp \
    --port 27017 \
    --cidr 0.0.0.0/0
```

### Paso 2: Crear DocumentDB Cluster
```bash
# Crear DocumentDB Subnet Group
aws docdb create-db-subnet-group \
    --db-subnet-group-name docdb-subnet-group \
    --db-subnet-group-description "Subnet group for DocumentDB" \
    --subnet-ids subnet-xxxxxxxxx subnet-yyyyyyyyy

# Crear DocumentDB Cluster
aws docdb create-db-cluster \
    --db-cluster-identifier docdb-lab-cluster \
    --engine docdb \
    --master-username docdbadmin \
    --master-user-password 'DocDB123!' \
    --vpc-security-group-ids $DOCDB_SG_ID \
    --db-subnet-group-name docdb-subnet-group \
    --storage-encrypted \
    --backup-retention-period 7

# Crear instancia en el cluster
aws docdb create-db-instance \
    --db-instance-identifier docdb-lab-instance \
    --db-instance-class db.t3.medium \
    --engine docdb \
    --db-cluster-identifier docdb-lab-cluster

# Obtener endpoint
DOCDB_ENDPOINT=$(aws docdb describe-db-clusters \
    --db-cluster-identifier docdb-lab-cluster \
    --query 'DBClusters[0].Endpoint' \
    --output text)

echo "DocumentDB Endpoint: $DOCDB_ENDPOINT"
```

---

## 📋 Laboratorio 4: Configuración de Conectividad Híbrida

### Paso 1: Crear Instancia EC2 Bastion
```bash
# Crear Key Pair para EC2
aws ec2 create-key-pair \
    --key-name lab-bastion-key \
    --query 'KeyMaterial' \
    --output text > lab-bastion-key.pem

chmod 400 lab-bastion-key.pem

# Crear Security Group para Bastion
aws ec2 create-security-group \
    --group-name bastion-sg \
    --description "Security group for Bastion host" \
    --vpc-id vpc-xxxxxxxxx

BASTION_SG_ID=$(aws ec2 describe-security-groups \
    --group-names bastion-sg \
    --query 'SecurityGroups[0].GroupId' \
    --output text)

# Permitir SSH
aws ec2 authorize-security-group-ingress \
    --group-id $BASTION_SG_ID \
    --protocol tcp \
    --port 22 \
    --cidr 0.0.0.0/0

# Crear instancia EC2
aws ec2 run-instances \
    --image-id ami-0c02fb55956c7d316 \
    --count 1 \
    --instance-type t2.micro \
    --key-name lab-bastion-key \
    --security-group-ids $BASTION_SG_ID \
    --subnet-id subnet-xxxxxxxxx \
    --associate-public-ip-address \
    --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=lab-bastion}]'
```

### Paso 2: Configurar Bastion para Acceso a DocumentDB
```bash
# Obtener IP pública del bastion
BASTION_IP=$(aws ec2 describe-instances \
    --filters "Name=tag:Name,Values=lab-bastion" "Name=instance-state-name,Values=running" \
    --query 'Reservations[0].Instances[0].PublicIpAddress' \
    --output text)

echo "Bastion IP: $BASTION_IP"

# Conectar al bastion
ssh -i lab-bastion-key.pem ec2-user@$BASTION_IP

# En el bastion, instalar mongosh
wget -qO - https://www.mongodb.org/static/pgp/server-6.0.asc | sudo apt-key add -
echo "deb [ arch=amd64,arm64 ] https://repo.mongodb.org/apt/ubuntu focal/mongodb-org/6.0 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-6.0.list
sudo apt update
sudo apt install -y mongodb-mongosh

# Descargar certificado SSL para DocumentDB
wget https://s3.amazonaws.com/rds-downloads/rds-combined-ca-bundle.pem
```

### Paso 3: Probar Conectividad a DocumentDB
```bash
# Desde el bastion, conectar a DocumentDB
mongosh --host $DOCDB_ENDPOINT:27017 \
    --username docdbadmin \
    --password 'DocDB123!' \
    --ssl \
    --sslCAFile rds-combined-ca-bundle.pem \
    --retryWrites=false

# Dentro de mongosh
db.adminCommand('ismaster')
show dbs
```

---

## 📋 Laboratorio 5: Comparación OnPrem vs Cloud

### Paso 1: Crear Datos de Prueba Idénticos
```sql
-- En MySQL OnPrem
mysql -u dbadmin -p ecommerce_lab

-- En RDS MySQL
mysql -h $RDS_ENDPOINT -u admin -p

-- Ejecutar en ambos:
CREATE DATABASE IF NOT EXISTS performance_test;
USE performance_test;

CREATE TABLE test_table (
    id INT PRIMARY KEY AUTO_INCREMENT,
    data VARCHAR(1000),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_created (created_at)
);

-- Insertar 10,000 registros
DELIMITER //
CREATE PROCEDURE InsertTestData()
BEGIN
    DECLARE i INT DEFAULT 1;
    WHILE i <= 10000 DO
        INSERT INTO test_table (data) VALUES (CONCAT('Test data row ', i, ' - ', REPEAT('x', 100)));
        SET i = i + 1;
    END WHILE;
END //
DELIMITER ;

CALL InsertTestData();
```

### Paso 2: Comparar Performance
```sql
-- Ejecutar en ambos entornos y comparar tiempos
-- Query 1: SELECT simple
SELECT COUNT(*) FROM test_table;

-- Query 2: SELECT con WHERE
SELECT COUNT(*) FROM test_table WHERE created_at > DATE_SUB(NOW(), INTERVAL 1 HOUR);

-- Query 3: SELECT con JOIN (crear tabla relacionada primero)
CREATE TABLE categories (
    id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(50)
);

INSERT INTO categories (name) VALUES ('Category 1'), ('Category 2'), ('Category 3');

ALTER TABLE test_table ADD COLUMN category_id INT;
UPDATE test_table SET category_id = (id % 3) + 1;

SELECT c.name, COUNT(t.id) 
FROM test_table t 
JOIN categories c ON t.category_id = c.id 
GROUP BY c.name;
```

### Paso 3: Comparar Configuraciones
```sql
-- MySQL OnPrem vs RDS - Comparar variables
SHOW VARIABLES LIKE 'innodb_buffer_pool_size';
SHOW VARIABLES LIKE 'max_connections';
SHOW VARIABLES LIKE 'query_cache_size';

-- PostgreSQL OnPrem vs RDS
SELECT name, setting, unit FROM pg_settings WHERE name IN (
    'shared_buffers',
    'work_mem',
    'max_connections',
    'effective_cache_size'
);
```

---

## 🧪 Ejercicios de Evaluación

### Ejercicio 1: Creación de Recursos Cloud (30 puntos)
**Tiempo límite: 60 minutos**

**Tarea:** Crear una instancia RDS PostgreSQL con las siguientes especificaciones:
- Instancia: db.t3.micro
- Engine: PostgreSQL 14.x
- Storage: 20GB, encrypted
- Backup retention: 7 días
- Multi-AZ: No
- Publicly accessible: Yes

```bash
# Comandos esperados (ejemplo de solución):
aws rds create-db-instance \
    --db-instance-identifier student-postgres-eval \
    --db-instance-class db.t3.micro \
    --engine postgres \
    --engine-version 14.9 \
    --master-username evaluser \
    --master-user-password 'EvalPass123!' \
    --allocated-storage 20 \
    --storage-encrypted \
    --backup-retention-period 7 \
    --publicly-accessible true
```

**Criterios de evaluación:**
- Instancia creada correctamente (15 pts)
- Configuración según especificaciones (10 pts)
- Puede conectar exitosamente (5 pts)

### Ejercicio 2: Configuración de Conectividad (25 puntos)
**Tiempo límite: 45 minutos**

**Tarea:** Configurar conectividad desde OnPrem a RDS creado en Ejercicio 1

```bash
# Pasos esperados:
# 1. Crear/modificar Security Group
# 2. Probar conectividad
# 3. Crear usuario de aplicación
# 4. Verificar permisos
```

**Criterios de evaluación:**
- Security Group configurado correctamente (10 pts)
- Conectividad funcional desde OnPrem (10 pts)
- Usuario de aplicación creado con permisos apropiados (5 pts)

### Ejercicio 3: Comparación de Arquitecturas (25 puntos)
**Tiempo límite: 30 minutos**

**Tarea:** Completar tabla comparativa OnPrem vs Cloud

| Aspecto | OnPrem | RDS/Cloud | Ventajas OnPrem | Ventajas Cloud |
|---------|--------|-----------|-----------------|----------------|
| Costo inicial | | | | |
| Mantenimiento | | | | |
| Escalabilidad | | | | |
| Backup/Recovery | | | | |
| Seguridad | | | | |
| Performance | | | | |

**Criterios de evaluación:**
- Análisis técnico correcto (15 pts)
- Identificación de ventajas/desventajas (10 pts)

### Ejercicio 4: Troubleshooting Híbrido (20 puntos)
**Tiempo límite: 30 minutos**

**Escenario:** No se puede conectar desde OnPrem a RDS

Posibles problemas introducidos:
1. Security Group bloqueando puerto
2. Credenciales incorrectas
3. Endpoint incorrecto

```bash
# Comandos de diagnóstico esperados:
aws rds describe-db-instances --db-instance-identifier [instance-id]
aws ec2 describe-security-groups --group-ids [sg-id]
telnet [rds-endpoint] 5432
psql -h [rds-endpoint] -U [username] -d postgres
```

**Criterios de evaluación:**
- Identifica el problema correctamente (10 pts)
- Aplica solución apropiada (10 pts)

---

## 📊 Rúbrica de Evaluación Final

### Distribución de Puntos
- **Ejercicio 1 - Creación de recursos:** 30 puntos
- **Ejercicio 2 - Conectividad:** 25 puntos  
- **Ejercicio 3 - Comparación:** 25 puntos
- **Ejercicio 4 - Troubleshooting:** 20 puntos
- **Total:** 100 puntos

### Criterios de Aprobación
- **Excelente (90-100):** Completa todos los ejercicios correctamente, demuestra comprensión profunda de diferencias OnPrem vs Cloud
- **Bueno (80-89):** Completa la mayoría de ejercicios, comprende conceptos básicos híbridos
- **Regular (70-79):** Completa ejercicios básicos, requiere ayuda para troubleshooting
- **Insuficiente (<70):** No logra crear recursos cloud o establecer conectividad

---

## 📝 Entregables del Laboratorio

### 1. Reporte de Configuración
```markdown
# Reporte Laboratorio Semana 1 - Arquitecturas Híbridas
## Estudiante: [Nombre]
## Fecha: [Fecha]

### Recursos AWS Creados
- RDS MySQL: [endpoint]
- RDS PostgreSQL: [endpoint]  
- DocumentDB: [endpoint]
- Security Groups: [IDs]

### Pruebas de Conectividad
- [ ] OnPrem MySQL → RDS MySQL
- [ ] OnPrem PostgreSQL → RDS PostgreSQL
- [ ] Bastion → DocumentDB
- [ ] Aplicación puede conectar a ambos entornos

### Comparación de Performance
| Query | OnPrem Time | Cloud Time | Diferencia |
|-------|-------------|------------|------------|
| SELECT COUNT(*) | | | |
| SELECT con WHERE | | | |
| SELECT con JOIN | | | |

### Lecciones Aprendidas
- Ventajas observadas del Cloud:
- Ventajas observadas del OnPrem:
- Desafíos de conectividad híbrida:
```

### 2. Scripts de Automatización
```bash
#!/bin/bash
# create_hybrid_lab.sh
# Script para recrear el laboratorio híbrido

echo "Creando recursos AWS para laboratorio híbrido..."
# Incluir todos los comandos AWS CLI utilizados
```

### 3. Configuraciones de Conexión
```ini
# mysql_connections.conf
[onprem]
host=localhost
port=3306
user=dbadmin
password=Admin123!

[rds]
host=mysql-lab-instance.xxxxx.us-east-1.rds.amazonaws.com
port=3306
user=admin
password=MyRDS123!
```

---

## 🔧 Herramientas de Soporte

### Script de Limpieza
```bash
#!/bin/bash
# cleanup_lab1.sh - Limpiar recursos AWS para evitar costos

echo "Eliminando recursos del laboratorio..."

# Eliminar instancias RDS
aws rds delete-db-instance \
    --db-instance-identifier mysql-lab-instance \
    --skip-final-snapshot

aws rds delete-db-instance \
    --db-instance-identifier postgres-lab-instance \
    --skip-final-snapshot

# Eliminar DocumentDB
aws docdb delete-db-instance \
    --db-instance-identifier docdb-lab-instance

aws docdb delete-db-cluster \
    --db-cluster-identifier docdb-lab-cluster \
    --skip-final-snapshot

# Eliminar EC2 bastion
aws ec2 terminate-instances \
    --instance-ids $(aws ec2 describe-instances \
        --filters "Name=tag:Name,Values=lab-bastion" \
        --query 'Reservations[0].Instances[0].InstanceId' \
        --output text)

echo "Recursos eliminados. Verificar en consola AWS."
```

### Monitoreo de Costos
```bash
#!/bin/bash
# check_costs.sh - Verificar costos del laboratorio

aws ce get-cost-and-usage \
    --time-period Start=2024-01-01,End=2024-01-31 \
    --granularity MONTHLY \
    --metrics BlendedCost \
    --group-by Type=DIMENSION,Key=SERVICE
```

Este laboratorio proporciona una experiencia práctica completa en arquitecturas híbridas, preparando a los estudiantes para entornos reales donde deben manejar tanto recursos OnPrem como Cloud.
