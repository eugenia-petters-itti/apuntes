# 🚀 DBA Training System - Guía de Despliegue Terraform

## 📋 Índice
- [Prerrequisitos](#prerrequisitos)
- [Configuración Inicial](#configuración-inicial)
- [Despliegue Paso a Paso](#despliegue-paso-a-paso)
- [Verificación del Sistema](#verificación-del-sistema)
- [Acceso y Uso](#acceso-y-uso)
- [Mantenimiento](#mantenimiento)
- [Troubleshooting](#troubleshooting)
- [Limpieza y Destrucción](#limpieza-y-destrucción)

## 🔧 Prerrequisitos

### Software Requerido
```bash
# Terraform (versión >= 1.0)
terraform --version

# AWS CLI configurado
aws configure list

# Git (para clonar repositorio)
git --version
```

### Permisos AWS Requeridos
El usuario/rol AWS debe tener permisos para:
- **VPC**: Crear VPC, subnets, security groups, NAT gateways
- **EC2**: Crear instancias, EIPs, key pairs
- **RDS**: Crear instancias MySQL y PostgreSQL
- **DocumentDB**: Crear clusters y instancias
- **IAM**: Crear roles y políticas
- **CloudWatch**: Crear log groups y alarmas
- **Lambda**: Crear funciones (para automatización)
- **EventBridge**: Crear reglas de programación

### Recursos AWS Existentes
- **Key Pair**: Debe existir en la región de despliegue
- **Límites de Servicio**: Verificar límites de EC2, RDS, DocumentDB

## ⚙️ Configuración Inicial

### 1. Preparar Archivos de Configuración

```bash
# Clonar o descargar el código
cd 05-terraform/

# Copiar archivo de variables de ejemplo
cp terraform.tfvars.example terraform.tfvars

# Editar variables según tu entorno
vim terraform.tfvars
```

### 2. Variables Críticas a Configurar

```hcl
# terraform.tfvars
key_name = "tu-key-pair-existente"  # OBLIGATORIO
aws_region = "us-east-1"            # Tu región preferida

# Seguridad - IMPORTANTE: Restringir en producción
allowed_cidr_blocks = ["tu.ip.publica/32"]

# Configuración de instancias
bastion_instance_type = "t3.medium"
db_instance_class = "db.t3.micro"
max_students = 10  # Ajustar según necesidades
```

### 3. Verificar Configuración AWS

```bash
# Verificar credenciales
aws sts get-caller-identity

# Verificar región
aws configure get region

# Verificar key pair existe
aws ec2 describe-key-pairs --key-names tu-key-pair-existente
```

## 🚀 Despliegue Paso a Paso

### Paso 1: Inicializar Terraform

```bash
# Inicializar Terraform
terraform init

# Verificar configuración
terraform validate

# Ver plan de despliegue
terraform plan
```

### Paso 2: Revisar Plan de Despliegue

El plan debe mostrar aproximadamente:
- **1 VPC** con subnets públicas, privadas y de base de datos
- **1 Bastion Host** con herramientas DBA
- **2 RDS instances** (MySQL y PostgreSQL)
- **1 DocumentDB cluster**
- **Security Groups** y reglas de red
- **IAM roles** y políticas
- **CloudWatch** logs y alarmas

### Paso 3: Aplicar Configuración

```bash
# Aplicar configuración (toma 15-20 minutos)
terraform apply

# Confirmar con 'yes' cuando se solicite
```

### Paso 4: Guardar Outputs Importantes

```bash
# Ver todos los outputs
terraform output

# Guardar información de conexión
terraform output -json > infrastructure-info.json

# Ver credenciales de base de datos (sensible)
terraform output database_credentials
```

## ✅ Verificación del Sistema

### 1. Verificar Infraestructura Base

```bash
# Verificar VPC creada
aws ec2 describe-vpcs --filters "Name=tag:Project,Values=dba-training-system"

# Verificar instancias EC2
aws ec2 describe-instances --filters "Name=tag:Project,Values=dba-training-system"

# Verificar bases de datos
aws rds describe-db-instances
aws docdb describe-db-clusters
```

### 2. Verificar Conectividad

```bash
# Obtener IP pública del bastion
BASTION_IP=$(terraform output -raw bastion_public_ip)

# Probar conexión SSH
ssh -i tu-key.pem ec2-user@$BASTION_IP

# Verificar servicios en bastion
ssh -i tu-key.pem ec2-user@$BASTION_IP "sudo systemctl status prometheus grafana-server"
```

### 3. Verificar Servicios Web

```bash
# URLs a verificar (reemplazar con IP real)
echo "Grafana: http://$BASTION_IP:3000"
echo "Prometheus: http://$BASTION_IP:9090"
echo "Training Portal: http://$BASTION_IP"
echo "Jupyter: http://$BASTION_IP:8888"
```

## 🎯 Acceso y Uso

### Para Instructores

```bash
# Conectar al bastion
ssh -i tu-key.pem ec2-user@$BASTION_IP

# Verificar estado de servicios
dba-status

# Conectar a bases de datos
/opt/dba-training/scripts/connect-mysql.sh
/opt/dba-training/scripts/connect-postgres.sh
/opt/dba-training/scripts/connect-mongodb.sh
```

### Para Estudiantes

1. **Acceso Web**: `http://BASTION_IP`
2. **Grafana**: `http://BASTION_IP:3000` (admin/dba-training-2024)
3. **Jupyter**: `http://BASTION_IP:8888` (token: dba-training-2024)

### Credenciales de Base de Datos

```bash
# Ver credenciales (desde directorio terraform)
terraform output database_credentials
```

## 🔧 Mantenimiento

### Actualizaciones de Configuración

```bash
# Modificar terraform.tfvars según necesidades
vim terraform.tfvars

# Aplicar cambios
terraform plan
terraform apply
```

### Monitoreo del Sistema

```bash
# Ver logs de CloudWatch
aws logs describe-log-groups --log-group-name-prefix "/aws/ec2/dba-training"

# Ver métricas en Grafana
# http://BASTION_IP:3000
```

### Backup Manual

```bash
# Crear snapshot de RDS
aws rds create-db-snapshot --db-instance-identifier dba-training-mysql --db-snapshot-identifier manual-backup-$(date +%Y%m%d)

# Crear snapshot de DocumentDB
aws docdb create-db-cluster-snapshot --db-cluster-identifier dba-training-docdb --db-cluster-snapshot-identifier manual-backup-$(date +%Y%m%d)
```

## 🔍 Troubleshooting

### Problemas Comunes

#### 1. Error de Key Pair
```
Error: InvalidKeyPair.NotFound
```
**Solución**: Verificar que el key pair existe en la región correcta
```bash
aws ec2 describe-key-pairs --region tu-region
```

#### 2. Límites de Servicio
```
Error: LimitExceeded
```
**Solución**: Solicitar aumento de límites en AWS Service Quotas

#### 3. Problemas de Conectividad
```bash
# Verificar security groups
aws ec2 describe-security-groups --filters "Name=tag:Project,Values=dba-training-system"

# Verificar rutas de red
aws ec2 describe-route-tables
```

#### 4. Servicios No Iniciados en Bastion

```bash
# Conectar al bastion y verificar logs
ssh -i tu-key.pem ec2-user@$BASTION_IP
sudo journalctl -u prometheus -f
sudo journalctl -u grafana-server -f

# Reiniciar servicios si es necesario
sudo systemctl restart prometheus grafana-server
```

### Logs Importantes

```bash
# Logs de user-data (configuración inicial)
sudo cat /var/log/user-data.log

# Logs de aplicaciones
sudo tail -f /opt/dba-training/logs/*.log

# Logs del sistema
sudo journalctl -f
```

## 🧹 Limpieza y Destrucción

### Destrucción Completa

```bash
# ADVERTENCIA: Esto eliminará TODA la infraestructura
terraform destroy

# Confirmar con 'yes'
```

### Destrucción Selectiva

```bash
# Eliminar solo recursos específicos
terraform destroy -target=module.rds_mysql
terraform destroy -target=module.documentdb
```

### Limpieza Manual (si es necesario)

```bash
# Eliminar snapshots manuales
aws rds describe-db-snapshots --snapshot-type manual
aws rds delete-db-snapshot --db-snapshot-identifier snapshot-id

# Eliminar log groups huérfanos
aws logs describe-log-groups --log-group-name-prefix "/aws/ec2/dba-training"
aws logs delete-log-group --log-group-name log-group-name
```

## 📊 Costos Estimados

### Configuración Básica (por mes)
- **Bastion t3.medium**: ~$30
- **RDS MySQL db.t3.micro**: ~$15
- **RDS PostgreSQL db.t3.micro**: ~$15
- **DocumentDB db.t3.medium**: ~$50
- **NAT Gateway**: ~$45
- **EBS Storage**: ~$10
- **Data Transfer**: ~$5

**Total Estimado**: ~$170/mes

### Optimizaciones de Costo
- Usar instancias spot para entornos de desarrollo
- Programar apagado automático fuera de horarios de clase
- Usar instancias más pequeñas para pruebas

## 📞 Soporte

### Información del Sistema
```bash
# Generar reporte de estado
terraform output > system-status.txt
aws ec2 describe-instances --filters "Name=tag:Project,Values=dba-training-system" >> system-status.txt
```

### Contacto
- **Documentación**: Ver archivos en `01-documentacion-programa/`
- **Issues**: Reportar problemas con logs completos
- **Mejoras**: Sugerir optimizaciones basadas en uso real

---

**¡El sistema DBA Training está listo para transformar la educación en administración de bases de datos!** 🎓
