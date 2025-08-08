# Guía de Implementación - DBA Cloud OnPrem Junior

## 🎯 Plan de Implementación por Fases

### Fase 1: Preparación del Entorno (Semana -1)
#### Infraestructura necesaria
```bash
# Servidores/VMs requeridos:
- 3x VMs Linux (Ubuntu 20.04+ o CentOS 8+)
  - VM1: MySQL OnPrem (4GB RAM, 2 CPU, 50GB disk)
  - VM2: PostgreSQL OnPrem (4GB RAM, 2 CPU, 50GB disk)  
  - VM3: MongoDB OnPrem (4GB RAM, 2 CPU, 50GB disk)
- 1x VM para herramientas de monitoreo (8GB RAM, 4 CPU, 100GB disk)
- Acceso a cuenta AWS (sandbox/dev)
```

#### Software base a instalar
```bash
# En todas las VMs:
sudo apt update && sudo apt upgrade -y
sudo apt install -y curl wget git vim htop net-tools

# Herramientas de monitoreo (VM4):
# Prometheus, Grafana, Zabbix (scripts de instalación incluidos)
```

#### Accesos y permisos
- Usuarios sudo para estudiantes en todas las VMs
- Claves SSH configuradas
- Acceso a AWS con permisos limitados (RDS, DocumentDB, CloudWatch)

### Fase 2: Implementación Gradual (5 semanas)

#### Semana 0: Fundamentos OnPrem
**Día 1-2: Linux básico**
```bash
# Checklist de competencias:
□ Navegación básica (ls, cd, pwd, find)
□ Gestión de archivos (cp, mv, rm, chmod, chown)
□ Procesos (ps, top, htop, kill)
□ Red (ping, netstat, ss, telnet)
□ Logs (tail, grep, journalctl)
```

**Día 3-4: Instalación de motores**
```bash
# MySQL OnPrem
sudo apt install mysql-server mysql-client
sudo mysql_secure_installation

# PostgreSQL OnPrem  
sudo apt install postgresql postgresql-client
sudo -u postgres createuser --interactive
```

**Día 5: Configuración de servicios**
```bash
# Systemd services
sudo systemctl enable mysql postgresql
sudo systemctl start mysql postgresql
sudo systemctl status mysql postgresql

# Firewall básico
sudo ufw enable
sudo ufw allow 3306  # MySQL
sudo ufw allow 5432  # PostgreSQL
```

#### Semana 1: Fundamentos híbridos
**Ejercicio clave:** Conectar VM OnPrem con RDS AWS
```bash
# Configurar VPN o conexión directa
# Probar conectividad bidireccional
mysql -h rds-endpoint.region.rds.amazonaws.com -u admin -p
```

#### Semana 2: Administración avanzada
**Ejercicio clave:** Backup y restore completo
```bash
# Backup lógico
mysqldump --all-databases > full_backup.sql
pg_dumpall > postgres_full_backup.sql

# Backup físico
xtrabackup --backup --target-dir=/backup/mysql/
pg_basebackup -D /backup/postgres/
```

#### Semana 3: NoSQL y seguridad
**Ejercicio clave:** MongoDB OnPrem con SSL
```bash
# Instalar MongoDB
wget -qO - https://www.mongodb.org/static/pgp/server-5.0.asc | sudo apt-key add -
sudo apt install mongodb-org

# Configurar SSL
openssl req -newkey rsa:2048 -new -x509 -days 3653 -nodes -out mongodb-cert.crt -keyout mongodb-cert.key
cat mongodb-cert.key mongodb-cert.crt > mongodb.pem
```

#### Semana 4: Monitoreo híbrido
**Ejercicio clave:** Dashboard unificado
```bash
# Instalar Prometheus
wget https://github.com/prometheus/prometheus/releases/download/v2.40.0/prometheus-2.40.0.linux-amd64.tar.gz
tar xvfz prometheus-*.tar.gz

# Configurar exporters
# - node_exporter para métricas del sistema
# - mysqld_exporter para MySQL
# - postgres_exporter para PostgreSQL
```

#### Semana 5: Troubleshooting y DR
**Ejercicio clave:** Simulación de fallo completo
```bash
# Simular fallo de disco
sudo umount /var/lib/mysql
# Procedimiento de recovery desde backup
# Validar integridad de datos
```

## 🛠️ Recursos y Herramientas Necesarias

### Scripts de Instalación Automatizada
```bash
#!/bin/bash
# install_mysql_onprem.sh
echo "Instalando MySQL OnPrem..."
sudo apt update
sudo apt install -y mysql-server mysql-client
sudo mysql_secure_installation
sudo systemctl enable mysql
sudo systemctl start mysql
echo "MySQL instalado correctamente"
```

### Configuraciones Base
```ini
# my.cnf para entorno de aprendizaje
[mysqld]
bind-address = 0.0.0.0
max_connections = 200
innodb_buffer_pool_size = 1G
slow_query_log = 1
slow_query_log_file = /var/log/mysql/slow.log
long_query_time = 2
```

### Datasets de Prueba
```sql
-- Crear base de datos de ejemplo
CREATE DATABASE ecommerce_demo;
USE ecommerce_demo;

-- Tablas con datos realistas para práctica
CREATE TABLE customers (
    id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(100),
    email VARCHAR(100),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Insertar 10,000 registros para pruebas de performance
```

## 📚 Material de Apoyo

### Documentación Técnica
1. **Guías de instalación paso a paso** (PDF)
2. **Cheatsheets de comandos** por motor de DB
3. **Troubleshooting guides** con casos comunes
4. **Scripts de automatización** comentados

### Videos de Apoyo (Recomendados)
- Instalación de MySQL OnPrem (15 min)
- Configuración de PostgreSQL desde cero (20 min)
- Backup y restore con XtraBackup (25 min)
- Configuración de Prometheus + Grafana (30 min)

### Laboratorios Virtuales
```yaml
# docker-compose.yml para entorno de práctica
version: '3.8'
services:
  mysql-onprem:
    image: mysql:8.0
    environment:
      MYSQL_ROOT_PASSWORD: rootpass
    ports:
      - "3306:3306"
    volumes:
      - mysql_data:/var/lib/mysql
      
  postgres-onprem:
    image: postgres:14
    environment:
      POSTGRES_PASSWORD: postgrespass
    ports:
      - "5432:5432"
    volumes:
      - postgres_data:/var/lib/postgresql/data
```

## 🎓 Evaluación y Certificación

### Rúbricas Detalladas
```markdown
## Evaluación Semana 0 - Fundamentos OnPrem
### Criterios (100 puntos total):

**Instalación (25 puntos)**
- Excelente (23-25): Instala sin ayuda, configura servicios correctamente
- Bueno (18-22): Instala con mínima ayuda, configuración básica correcta
- Regular (13-17): Requiere ayuda, configuración parcial
- Insuficiente (0-12): No logra instalación funcional

**Configuración (25 puntos)**
- Excelente (23-25): Configura parámetros, firewall, usuarios correctamente
- Bueno (18-22): Configuración básica correcta, algunos parámetros
- Regular (13-17): Configuración mínima funcional
- Insuficiente (0-12): Configuración incorrecta o no funcional

**Troubleshooting (25 puntos)**
- Excelente (23-25): Identifica y resuelve problemas de forma autónoma
- Bueno (18-22): Resuelve problemas con guía mínima
- Regular (13-17): Requiere ayuda para resolver problemas
- Insuficiente (0-12): No puede resolver problemas básicos

**Documentación (25 puntos)**
- Excelente (23-25): Documenta procedimientos completos y claros
- Bueno (18-22): Documentación básica pero útil
- Regular (13-17): Documentación mínima
- Insuficiente (0-12): No documenta o documentación inútil
```

### Proyecto Final Integrador
```markdown
## Proyecto: "Migración y Monitoreo Híbrido"

**Objetivo:** Migrar una aplicación de e-commerce de OnPrem a Cloud manteniendo alta disponibilidad

**Entregables:**
1. Documentación de arquitectura actual (OnPrem)
2. Plan de migración detallado
3. Implementación de monitoreo híbrido
4. Ejecución de migración con rollback plan
5. Validación de integridad de datos
6. Configuración de disaster recovery

**Tiempo:** 2 semanas
**Evaluación:** 40% del puntaje final
```

## 📊 Métricas de Éxito

### KPIs del Programa
- **Tasa de aprobación:** >85%
- **Tiempo promedio de resolución de ejercicios:** <tiempo objetivo
- **Satisfacción del estudiante:** >4.5/5
- **Empleabilidad post-curso:** >90% en 6 meses

### Métricas por Competencia
```markdown
## Competencias OnPrem (Peso: 40%)
- Instalación y configuración: 90% de estudiantes logran instalación autónoma
- Troubleshooting: 85% resuelven problemas comunes sin ayuda
- Backup/Recovery: 95% ejecutan procedimientos correctamente

## Competencias Cloud (Peso: 30%)
- Despliegue RDS: 95% crean instancias correctamente
- Automatización: 80% escriben Terraform básico
- Monitoreo: 90% configuran alarmas básicas

## Competencias Híbridas (Peso: 30%)
- Conectividad: 85% configuran conexión OnPrem-Cloud
- Migración: 75% ejecutan migración básica
- Monitoreo unificado: 80% crean dashboards híbridos
```

## 🚀 Plan de Mejora Continua

### Feedback Loop
1. **Evaluación semanal** de estudiantes sobre contenido y dificultad
2. **Revisión mensual** de material con instructores
3. **Actualización trimestral** de herramientas y versiones
4. **Revisión anual** completa del programa

### Actualizaciones Tecnológicas
```markdown
## Roadmap de Actualizaciones 2024-2025

**Q1 2024:**
- Agregar contenido de PostgreSQL 15
- Actualizar Terraform a v1.6+
- Incluir MongoDB 7.0

**Q2 2024:**
- Agregar módulo de Kubernetes para DBs
- Incluir contenido de Aurora Serverless v2
- Expandir contenido de DocumentDB

**Q3 2024:**
- Agregar módulo de observabilidad avanzada
- Incluir contenido de RDS Proxy
- Expandir automatización con Python

**Q4 2024:**
- Revisión completa del programa
- Actualización de todas las herramientas
- Incorporar feedback del año
```

## 💡 Consejos de Implementación

### Para Instructores
1. **Preparación:** Revisar todo el material 2 semanas antes
2. **Flexibilidad:** Adaptar ritmo según el grupo
3. **Práctica:** Enfatizar ejercicios hands-on sobre teoría
4. **Mentoring:** Sesiones 1:1 para estudiantes con dificultades

### Para Estudiantes
1. **Prerequisitos:** Conocimientos básicos de Linux y SQL
2. **Tiempo:** Dedicar 2-3 horas diarias de práctica adicional
3. **Documentación:** Mantener un lab notebook personal
4. **Networking:** Conectar con otros DBAs y comunidades

### Para la Organización
1. **Inversión inicial:** Budget para infraestructura y licencias
2. **Soporte técnico:** Tener backup de instructores expertos
3. **Seguimiento:** Programa de mentoring post-graduación
4. **Actualización:** Plan de actualización continua del contenido

---

## ✅ Checklist de Implementación

### Pre-lanzamiento
- [ ] Infraestructura preparada y probada
- [ ] Material didáctico completo y revisado
- [ ] Instructores capacitados en nuevo contenido
- [ ] Evaluaciones diseñadas y validadas
- [ ] Proceso de certificación definido

### Durante el programa
- [ ] Monitoreo semanal de progreso
- [ ] Feedback continuo de estudiantes
- [ ] Ajustes de contenido según necesidad
- [ ] Soporte técnico disponible 24/7
- [ ] Documentación de incidentes y resoluciones

### Post-programa
- [ ] Evaluación de satisfacción completa
- [ ] Seguimiento de empleabilidad
- [ ] Recolección de feedback para mejoras
- [ ] Actualización de material basado en experiencia
- [ ] Planificación de próxima cohorte

Este plan de implementación asegura una transición exitosa del programa original al mejorado, con enfoque en la experiencia práctica y la preparación real para el mercado laboral híbrido actual.
