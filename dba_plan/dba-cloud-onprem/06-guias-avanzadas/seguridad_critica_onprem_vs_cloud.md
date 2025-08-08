# Seguridad Crítica: OnPrem vs Cloud RDS
## Aspectos de seguridad que muchos DBAs pasan por alto

### 🔒 Introducción
La seguridad en bases de datos tiene matices completamente diferentes entre OnPrem y Cloud. Muchos DBAs cometen errores críticos al no comprender estas diferencias, especialmente en aspectos como encriptación, auditoría, acceso a datos y compliance.

---

## 🛡️ **ENCRIPTACIÓN: DIFERENCIAS CRÍTICAS**

### **OnPrem - Control Total pero Responsabilidad Total**

#### **Encriptación en Reposo:**
```bash
# MySQL OnPrem - Configuración manual completa
[mysqld]
# Encriptación de tablespace
innodb_encrypt_tables = ON
innodb_encrypt_log = ON
innodb_encrypt_online_alter_logs = ON

# Gestión manual de claves
# Debes configurar keyring plugin
plugin-load-add = keyring_file.so
keyring_file_data = /var/lib/mysql-keyring/keyring

# PROBLEMA: Si pierdes el keyring, pierdes TODOS los datos
# RESPONSABILIDAD: Backup seguro del keyring
```

#### **PostgreSQL OnPrem - Encriptación de Cluster:**
```bash
# Encriptación a nivel de filesystem (más común)
# Usando LUKS o similar
cryptsetup luksFormat /dev/sdb
cryptsetup luksOpen /dev/sdb postgres_encrypted

# O encriptación a nivel de columna
CREATE TABLE sensitive_data (
    id SERIAL PRIMARY KEY,
    ssn TEXT,
    encrypted_ssn BYTEA DEFAULT pgp_sym_encrypt(ssn, 'secret_key')
);

# PROBLEMA: Gestión manual de claves
# RESPONSABILIDAD: Rotación de claves manual
```

### **RDS - Encriptación Automática pero Limitada**

#### **MySQL RDS - Encriptación Transparente:**
```bash
# Encriptación habilitada en creación
aws rds create-db-instance \
    --storage-encrypted \
    --kms-key-id arn:aws:kms:region:account:key/key-id

# VENTAJA: AWS gestiona las claves automáticamente
# LIMITACIÓN: No puedes usar tus propias claves para tablespace encryption
# LIMITACIÓN: No puedes deshabilitar encriptación después de creación
```

#### **PostgreSQL RDS - Limitaciones Importantes:**
```sql
-- RDS PostgreSQL NO soporta Transparent Data Encryption (TDE)
-- Solo encriptación a nivel de storage (EBS)
-- Para encriptación granular, debes usar extensiones:

CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- Pero tienes limitaciones en gestión de claves
-- No puedes integrar con HSM externos fácilmente
```

#### **⚠️ Problema Crítico - Migración de Datos Encriptados:**
```bash
# OnPrem → RDS: Si tienes datos encriptados con claves personalizadas
# NO puedes migrar directamente
# Debes desencriptar → migrar → re-encriptar con claves RDS

# Esto puede violar políticas de compliance que requieren
# que los datos nunca estén desencriptados en tránsito
```

---

## 🔐 **GESTIÓN DE ACCESO Y AUTENTICACIÓN**

### **OnPrem - Flexibilidad Total**

#### **MySQL OnPrem - Autenticación Avanzada:**
```sql
-- Múltiples plugins de autenticación
INSTALL PLUGIN authentication_ldap_sasl SONAME 'authentication_ldap_sasl.so';

-- Usuarios con autenticación LDAP
CREATE USER 'ldap_user'@'%' IDENTIFIED WITH authentication_ldap_sasl;

-- Autenticación por certificado SSL
CREATE USER 'cert_user'@'%' IDENTIFIED WITH authentication_ldap_sasl 
REQUIRE SSL AND SUBJECT '/CN=cert_user/O=Company/C=US';

-- Roles personalizados complejos
CREATE ROLE 'app_read_role';
GRANT SELECT ON app_db.* TO 'app_read_role';
GRANT 'app_read_role' TO 'app_user'@'%';
```

#### **PostgreSQL OnPrem - Control Granular:**
```sql
-- pg_hba.conf personalizado completo
# TYPE  DATABASE        USER            ADDRESS                 METHOD
local   all             postgres                                peer
host    all             all             127.0.0.1/32            md5
hostssl sensitive_db    +secure_users   0.0.0.0/0               cert clientcert=1
host    app_db          app_users       10.0.0.0/8              ldap ldapserver=ldap.company.com

-- Row Level Security (RLS) avanzado
CREATE POLICY user_data_policy ON user_table
    FOR ALL TO app_role
    USING (user_id = current_setting('app.current_user_id')::int);
```

### **RDS - IAM Integration pero Limitaciones**

#### **MySQL RDS - IAM Database Authentication:**
```bash
# Habilitar IAM authentication
aws rds modify-db-instance \
    --db-instance-identifier mydb \
    --enable-iam-database-authentication

# Crear usuario IAM
CREATE USER 'iam_user'@'%' IDENTIFIED WITH AWSAuthenticationPlugin AS 'RDS';

# LIMITACIÓN: Solo funciona con usuarios específicos
# LIMITACIÓN: No puedes usar con todos los tipos de aplicaciones
# LIMITACIÓN: Latencia adicional por validación IAM
```

#### **PostgreSQL RDS - Limitaciones de pg_hba.conf:**
```sql
-- NO puedes modificar pg_hba.conf directamente
-- Solo a través de Parameter Groups limitados
-- NO puedes configurar autenticación por certificado personalizada
-- NO puedes integrar con LDAP externo fácilmente

-- PROBLEMA: Aplicaciones enterprise con autenticación compleja
-- pueden no ser compatibles con RDS
```

---

## 📊 **AUDITORÍA Y COMPLIANCE**

### **OnPrem - Auditoría Granular**

#### **MySQL OnPrem - MySQL Enterprise Audit:**
```sql
-- Instalación del plugin de auditoría
INSTALL PLUGIN audit_log SONAME 'audit_log.so';

-- Configuración granular
SET GLOBAL audit_log_policy = 'ALL';
SET GLOBAL audit_log_include_accounts = 'admin@%,app_user@%';
SET GLOBAL audit_log_exclude_accounts = 'monitoring@localhost';

-- Auditoría de comandos específicos
SET GLOBAL audit_log_statement_policy = 'ALL';

-- Logs de auditoría en formato personalizado
SET GLOBAL audit_log_format = 'JSON';
SET GLOBAL audit_log_file = '/var/log/mysql/audit.log';
```

#### **PostgreSQL OnPrem - pgAudit:**
```sql
-- Configuración en postgresql.conf
shared_preload_libraries = 'pgaudit'
pgaudit.log = 'all'
pgaudit.log_catalog = off
pgaudit.log_parameter = on
pgaudit.log_relation = on
pgaudit.log_statement_once = off

-- Auditoría por rol
ALTER ROLE sensitive_user SET pgaudit.log = 'read,write';

-- Auditoría por base de datos
ALTER DATABASE sensitive_db SET pgaudit.log = 'ddl,write';
```

### **RDS - Auditoría Limitada pero Integrada**

#### **MySQL RDS - Server Audit Plugin:**
```sql
-- Habilitar en Parameter Group
-- server_audit_logging = 1
-- server_audit_events = 'CONNECT,QUERY,TABLE'

-- LIMITACIÓN: No puedes configurar exclusiones granulares
-- LIMITACIÓN: Logs van a CloudWatch, no puedes personalizar formato
-- LIMITACIÓN: No puedes enviar logs a SIEM externo directamente
```

#### **PostgreSQL RDS - Logging Básico:**
```sql
-- Configuración limitada en Parameter Group
-- log_statement = 'all'  -- PELIGROSO: puede llenar storage rápidamente
-- log_connections = 1
-- log_disconnections = 1

-- PROBLEMA: No hay pgAudit disponible en RDS estándar
-- PROBLEMA: Logs básicos no cumplen muchos requisitos de compliance
```

#### **⚠️ Problema de Compliance:**
```bash
# Muchas regulaciones requieren:
# 1. Auditoría granular por usuario/tabla
# 2. Logs inmutables
# 3. Retención específica de logs
# 4. Alertas en tiempo real

# RDS puede NO cumplir estos requisitos sin configuración adicional
```

---

## 🌐 **SEGURIDAD DE RED Y ACCESO**

### **OnPrem - Control Total de Red**

#### **Configuración de Red Segura:**
```bash
# Firewall granular
iptables -A INPUT -p tcp --dport 3306 -s 10.0.0.0/8 -j ACCEPT
iptables -A INPUT -p tcp --dport 3306 -j DROP

# SSL/TLS personalizado
# Certificados propios
openssl req -newkey rsa:2048 -days 3600 -nodes -keyout server-key.pem -out server-req.pem
openssl rsa -in server-key.pem -out server-key.pem
openssl x509 -req -in server-req.pem -days 3600 -CA ca-cert.pem -CAkey ca-key.pem -set_serial 01 -out server-cert.pem

# MySQL con SSL obligatorio
[mysqld]
ssl-ca=/etc/mysql/ssl/ca-cert.pem
ssl-cert=/etc/mysql/ssl/server-cert.pem
ssl-key=/etc/mysql/ssl/server-key.pem
require_secure_transport=ON
```

#### **PostgreSQL OnPrem - SSL Avanzado:**
```bash
# postgresql.conf
ssl = on
ssl_cert_file = '/etc/ssl/certs/server.crt'
ssl_key_file = '/etc/ssl/private/server.key'
ssl_ca_file = '/etc/ssl/certs/ca.crt'
ssl_crl_file = '/etc/ssl/certs/ca.crl'

# pg_hba.conf con certificados
hostssl all all 0.0.0.0/0 cert clientcert=1
```

### **RDS - VPC Security pero Limitaciones**

#### **Security Groups y NACLs:**
```bash
# Security Group restrictivo
aws ec2 create-security-group \
    --group-name db-sg \
    --description "Database security group"

aws ec2 authorize-security-group-ingress \
    --group-id sg-12345678 \
    --protocol tcp \
    --port 3306 \
    --source-group sg-87654321  # Solo desde app servers

# LIMITACIÓN: No puedes configurar firewall a nivel de SO
# LIMITACIÓN: Dependes de AWS para troubleshooting de red
```

#### **SSL/TLS en RDS:**
```sql
-- SSL habilitado por defecto, pero configuración limitada
-- No puedes usar certificados personalizados
-- Debes usar certificados de AWS

-- Forzar SSL en MySQL RDS
-- En Parameter Group: require_secure_transport = 1

-- PROBLEMA: Algunas aplicaciones legacy no soportan
-- los certificados de AWS
```

---

## 🚨 **VULNERABILIDADES ESPECÍFICAS POR PLATAFORMA**

### **OnPrem - Vulnerabilidades Comunes**

#### **1. Configuración Insegura por Defecto:**
```sql
-- MySQL OnPrem - Configuraciones peligrosas comunes
-- Usuarios sin password
SELECT user, host FROM mysql.user WHERE authentication_string = '';

-- Root accesible remotamente
SELECT user, host FROM mysql.user WHERE user = 'root' AND host != 'localhost';

-- Bases de datos de prueba
SHOW DATABASES LIKE 'test%';
```

#### **2. Archivos de Configuración Expuestos:**
```bash
# Permisos incorrectos en archivos sensibles
ls -la /etc/mysql/mysql.conf.d/mysqld.cnf
# Debería ser 644, no 666

# Passwords en archivos de configuración
grep -r "password" /etc/mysql/
# NUNCA debería haber passwords en texto plano
```

#### **3. Logs con Información Sensible:**
```bash
# Logs que pueden contener passwords
tail /var/log/mysql/mysql.log | grep -i password
# Configurar log_raw = OFF para evitar esto
```

### **RDS - Vulnerabilidades Específicas**

#### **1. Configuración de Security Groups:**
```bash
# Security Group demasiado permisivo
aws ec2 describe-security-groups --group-ids sg-12345678
# Si ves 0.0.0.0/0 en puerto 3306/5432 = PROBLEMA CRÍTICO
```

#### **2. Snapshots Públicos Accidentales:**
```bash
# Verificar snapshots públicos
aws rds describe-db-snapshots --snapshot-type public
# Si aparecen tus snapshots = PROBLEMA CRÍTICO

# Hacer snapshot privado
aws rds modify-db-snapshot-attribute \
    --db-snapshot-identifier mydb-snapshot \
    --attribute-name restore \
    --values-to-remove all
```

#### **3. Parameter Groups Inseguros:**
```bash
# Verificar configuraciones inseguras
aws rds describe-db-parameters --db-parameter-group-name mydb-params
# Buscar: log_bin_trust_function_creators = 1 sin justificación
# Buscar: general_log = 1 (puede exponer datos sensibles)
```

---

## 🔍 **CASOS DE ESTUDIO: BRECHAS DE SEGURIDAD REALES**

### **Caso 1: Migración OnPrem → RDS con Datos Sensibles**

#### **Problema:**
```bash
# Empresa migró base de datos con PII sin considerar:
# 1. Datos en snapshots automáticos
# 2. Logs de CloudWatch con queries sensibles
# 3. Performance Insights mostrando datos reales
```

#### **Solución:**
```bash
# 1. Configurar retention mínimo para snapshots
# 2. Deshabilitar general_log
# 3. Configurar Performance Insights con filtros
# 4. Implementar data masking antes de migración
```

### **Caso 2: Acceso No Autorizado por Configuración de Red**

#### **Problema OnPrem:**
```bash
# DBA configuró MySQL para escuchar en todas las interfaces
bind-address = 0.0.0.0
# Sin firewall apropiado
# Resultado: Base de datos accesible desde internet
```

#### **Problema RDS:**
```bash
# Security Group mal configurado
# Permitía acceso desde 0.0.0.0/0
# RDS marcado como publicly_accessible = true
# Resultado: Base de datos accesible desde internet
```

### **Caso 3: Fuga de Datos por Logs**

#### **OnPrem:**
```sql
-- General log habilitado con queries sensibles
SET GLOBAL general_log = 'ON';
-- Logs contenían:
-- SELECT * FROM users WHERE ssn = '123-45-6789';
-- UPDATE credit_cards SET number = '4111111111111111' WHERE id = 1;
```

#### **RDS:**
```bash
# CloudWatch logs con datos sensibles
# Performance Insights mostrando queries completas
# Logs accesibles por roles IAM demasiado amplios
```

---

## 📋 **CHECKLIST DE SEGURIDAD CRÍTICA**

### **OnPrem Security Checklist:**

#### **Configuración Básica:**
- [ ] ✅ Usuarios por defecto eliminados o asegurados
- [ ] ✅ Passwords fuertes para todos los usuarios
- [ ] ✅ Root/postgres solo accesible localmente
- [ ] ✅ Bases de datos de prueba eliminadas
- [ ] ✅ Permisos de archivos configurados correctamente

#### **Red y Acceso:**
- [ ] ✅ Firewall configurado restrictivamente
- [ ] ✅ SSL/TLS habilitado y configurado
- [ ] ✅ Bind address configurado apropiadamente
- [ ] ✅ Certificados válidos y actualizados

#### **Auditoría y Monitoreo:**
- [ ] ✅ Logging de auditoría habilitado
- [ ] ✅ Logs protegidos contra modificación
- [ ] ✅ Monitoreo de accesos anómalos
- [ ] ✅ Alertas configuradas para eventos críticos

#### **Encriptación:**
- [ ] ✅ Encriptación en reposo configurada
- [ ] ✅ Encriptación en tránsito obligatoria
- [ ] ✅ Gestión segura de claves
- [ ] ✅ Backup de claves en ubicación segura

### **RDS Security Checklist:**

#### **Configuración de Red:**
- [ ] ✅ VPC privada configurada
- [ ] ✅ Security Groups restrictivos
- [ ] ✅ No publicly accessible (salvo casos específicos)
- [ ] ✅ Subnets privadas para bases de datos

#### **Acceso y Autenticación:**
- [ ] ✅ IAM database authentication habilitado
- [ ] ✅ Usuarios con privilegios mínimos
- [ ] ✅ SSL/TLS obligatorio
- [ ] ✅ Parameter Groups seguros

#### **Auditoría y Compliance:**
- [ ] ✅ CloudTrail habilitado para API calls
- [ ] ✅ CloudWatch logs configurados
- [ ] ✅ Performance Insights con filtros apropiados
- [ ] ✅ Snapshots privados

#### **Backup y Recovery:**
- [ ] ✅ Encriptación de snapshots habilitada
- [ ] ✅ Cross-region backup si es necesario
- [ ] ✅ Retention period apropiado
- [ ] ✅ Testing regular de recovery

---

## 🛠️ **HERRAMIENTAS DE SEGURIDAD RECOMENDADAS**

### **OnPrem Security Tools:**

#### **Auditoría y Monitoreo:**
```bash
# MySQL
- MySQL Enterprise Audit
- Percona Audit Log Plugin
- mysql-audit (open source)

# PostgreSQL
- pgAudit
- pg_stat_statements
- log_statement configuration

# Monitoreo de Seguridad
- OSSEC/Wazuh para file integrity
- Fail2ban para brute force protection
- Tripwire para change detection
```

#### **Encriptación:**
```bash
# Filesystem level
- LUKS for disk encryption
- eCryptfs for file-level encryption

# Database level
- MySQL: keyring plugins
- PostgreSQL: pgcrypto extension
```

### **RDS Security Tools:**

#### **AWS Native:**
```bash
# Monitoreo
- CloudWatch
- CloudTrail
- Config Rules
- GuardDuty

# Seguridad
- IAM policies
- KMS for key management
- Secrets Manager
- Parameter Store
```

#### **Third-party:**
```bash
# Security scanning
- Prowler
- Scout Suite
- CloudSploit

# Database security
- Imperva
- IBM Guardium
- Oracle Database Vault (for Oracle RDS)
```

---

## ⚠️ **ERRORES CRÍTICOS DE SEGURIDAD**

### **Error 1: Asumir que Cloud = Seguro por Defecto**
```bash
# FALSO: RDS requiere configuración de seguridad activa
# AWS proporciona herramientas, pero TÚ debes configurarlas
# Shared responsibility model: AWS asegura la infraestructura,
# TÚ aseguras los datos y accesos
```

### **Error 2: No Considerar Compliance en Migración**
```bash
# Diferentes regulaciones tienen diferentes requisitos:
# GDPR: Right to be forgotten, data residency
# HIPAA: Audit trails, encryption requirements
# PCI-DSS: Network segmentation, access controls
# SOX: Data integrity, audit trails

# RDS puede NO cumplir todos los requisitos sin configuración adicional
```

### **Error 3: Ignorar Logs y Auditoría**
```bash
# OnPrem: Logs pueden crecer sin control y llenar disco
# RDS: Logs van a CloudWatch, pueden generar costos altos
# Ambos: Logs pueden contener información sensible
```

### **Error 4: Gestión Inadecuada de Credenciales**
```bash
# OnPrem: Passwords en archivos de configuración
# RDS: Passwords en scripts de Terraform/CloudFormation
# Solución: Usar AWS Secrets Manager, HashiCorp Vault, etc.
```

---

## 🎯 **MEJORES PRÁCTICAS DE SEGURIDAD HÍBRIDA**

### **1. Principio de Menor Privilegio**
```sql
-- OnPrem y RDS: Crear roles específicos
CREATE ROLE app_read_role;
GRANT SELECT ON specific_tables TO app_read_role;
GRANT app_read_role TO app_user;

-- NO hacer esto:
-- GRANT ALL PRIVILEGES ON *.* TO app_user;
```

### **2. Defense in Depth**
```bash
# Múltiples capas de seguridad:
# 1. Network (VPC, Security Groups, Firewall)
# 2. Authentication (IAM, strong passwords, MFA)
# 3. Authorization (roles, least privilege)
# 4. Encryption (in transit, at rest)
# 5. Auditing (comprehensive logging)
# 6. Monitoring (anomaly detection)
```

### **3. Gestión de Secretos**
```bash
# OnPrem: HashiCorp Vault, CyberArk
# RDS: AWS Secrets Manager, Parameter Store
# Híbrido: Integración entre ambos sistemas
```

### **4. Disaster Recovery Seguro**
```bash
# Backups encriptados
# Procedimientos de recovery documentados y probados
# Segregación de ambientes (dev/staging/prod)
# Testing regular de security controls
```

---

## 🚀 **CONCLUSIÓN: SEGURIDAD COMO PROCESO CONTINUO**

### **Puntos Clave:**

1. **La seguridad no es un destino, es un viaje continuo**
2. **OnPrem requiere más expertise pero ofrece más control**
3. **RDS simplifica muchos aspectos pero introduce nuevas consideraciones**
4. **Compliance debe considerarse desde el diseño, no como afterthought**
5. **Monitoreo y auditoría son críticos en ambos entornos**

### **Recomendación Final:**
**Un DBA de seguridad exitoso debe comprender profundamente tanto las capacidades como las limitaciones de cada plataforma, y diseñar arquitecturas de seguridad que aprovechen las fortalezas de cada una mientras mitigan sus debilidades.**
