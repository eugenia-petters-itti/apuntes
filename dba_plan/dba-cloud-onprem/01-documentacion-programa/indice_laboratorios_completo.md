# Índice Completo de Laboratorios - DBA Cloud OnPrem Junior

## 📚 Estructura General del Programa

### Duración Total: 5 Semanas (200 horas)
- **40 horas por semana** (8 horas/día x 5 días)
- **Teoría:** 30% (60 horas)
- **Práctica:** 70% (140 horas)
- **Evaluaciones:** 25 horas distribuidas

---

## 🗂️ Laboratorios por Semana

### **Semana 0: Fundamentos OnPrem** 
📄 **Archivo:** `laboratorio_semana0_fundamentos_onprem.md`

#### 🎯 Objetivos
- Instalar MySQL y PostgreSQL desde cero en Linux
- Configurar servicios del sistema con systemd
- Configurar firewall básico para bases de datos
- Crear usuarios del sistema operativo y de base de datos

#### 🖥️ Infraestructura
- **VM1:** MySQL OnPrem (4GB RAM, 2 CPU, 50GB)
- **VM2:** PostgreSQL OnPrem (4GB RAM, 2 CPU, 50GB)

#### 📋 Laboratorios Incluidos
1. **Instalación de MySQL OnPrem**
   - Preparación del sistema
   - Instalación y configuración básica
   - Configuración de firewall
   - Creación de usuarios de BD

2. **Instalación de PostgreSQL OnPrem**
   - Preparación del sistema
   - Instalación y configuración inicial
   - Configuración de acceso remoto
   - Creación de usuarios y bases de datos

3. **Creación de Datos de Prueba**
   - Datasets para MySQL
   - Datasets para PostgreSQL
   - Estructura de tablas relacionales

#### 🧪 Evaluaciones (100 puntos)
- **Ejercicio 1:** Verificación de instalación (25 pts)
- **Ejercicio 2:** Gestión de usuarios (25 pts)
- **Ejercicio 3:** Configuración de seguridad (25 pts)
- **Ejercicio 4:** Troubleshooting básico (25 pts)

---

### **Semana 1: Fundamentos Híbridos**
📄 **Archivo:** `laboratorio_semana1_hibrido.md`

#### 🎯 Objetivos
- Crear instancias RDS y DocumentDB en AWS
- Configurar conectividad OnPrem ↔ Cloud
- Comparar arquitecturas OnPrem vs Cloud
- Implementar backups automáticos y manuales

#### 🖥️ Infraestructura
- **OnPrem:** VM1 y VM2 (de Semana 0)
- **AWS Cloud:** RDS MySQL, RDS PostgreSQL, DocumentDB
- **Herramientas:** AWS CLI, mongosh, bastion EC2

#### 📋 Laboratorios Incluidos
1. **Creación de RDS MySQL**
   - Configuración de VPC y seguridad
   - Creación de subnet groups
   - Despliegue de instancia RDS

2. **Creación de RDS PostgreSQL**
   - Security groups específicos
   - Configuración de instancia
   - Pruebas de conectividad

3. **Creación de DocumentDB**
   - Configuración de cluster
   - Creación de instancias
   - Configuración SSL

4. **Configuración de Conectividad Híbrida**
   - Instancia EC2 bastion
   - Configuración de acceso a DocumentDB
   - Pruebas de conectividad

5. **Comparación OnPrem vs Cloud**
   - Datos de prueba idénticos
   - Comparación de performance
   - Análisis de configuraciones

#### 🧪 Evaluaciones (100 puntos)
- **Ejercicio 1:** Creación de recursos Cloud (30 pts)
- **Ejercicio 2:** Configuración de conectividad (25 pts)
- **Ejercicio 3:** Comparación de arquitecturas (25 pts)
- **Ejercicio 4:** Troubleshooting híbrido (20 pts)

---

### **Semana 2: MySQL y PostgreSQL Avanzado**
📄 **Archivo:** `laboratorio_semana2_mysql_postgres.md`

#### 🎯 Objetivos
- Crear y gestionar usuarios con diferentes niveles de permisos
- Realizar backups lógicos y físicos en ambos entornos
- Configurar y analizar herramientas de monitoreo OnPrem
- Optimizar parámetros de configuración para hardware específico

#### 🖥️ Infraestructura
- **OnPrem:** VM1 (MySQL) y VM2 (PostgreSQL) con datos de prueba
- **Cloud:** RDS MySQL y PostgreSQL (de Semana 1)
- **Herramientas:** XtraBackup, MySQLTuner, pgBadger, pt-query-digest

#### 📋 Laboratorios Incluidos
1. **Gestión Avanzada de Usuarios MySQL**
   - Instalación de herramientas OnPrem
   - Estructura de usuarios empresarial
   - Pruebas de permisos

2. **Backups Avanzados MySQL**
   - Backup lógico con mysqldump
   - Backup físico con XtraBackup
   - Pruebas de restauración

3. **Gestión Avanzada de Usuarios PostgreSQL**
   - Instalación de herramientas OnPrem
   - Configuración de logging
   - Estructura de roles y usuarios

4. **Backups Avanzados PostgreSQL**
   - Backup lógico con pg_dump
   - Backup físico con pg_basebackup
   - Configuración de WAL archiving

5. **Monitoreo y Tuning**
   - Análisis con MySQLTuner
   - Análisis de queries con pt-query-digest
   - Análisis con pgBadger
   - Monitoreo en tiempo real

#### 🧪 Evaluaciones (100 puntos)
- **Ejercicio 1:** Gestión de usuarios (25 pts)
- **Ejercicio 2:** Backup y restore (30 pts)
- **Ejercicio 3:** Análisis de performance (25 pts)
- **Ejercicio 4:** Troubleshooting de conectividad (20 pts)

---

### **Semana 3: DocumentDB/MongoDB y Seguridad Híbrida**
📄 **Archivo:** `laboratorio_semana3_mongodb_seguridad.md`

#### 🎯 Objetivos
- Instalar y configurar MongoDB OnPrem con SSL/TLS
- Conectar y operar con DocumentDB en AWS
- Configurar autenticación y autorización en MongoDB
- Implementar migración de datos OnPrem ↔ Cloud

#### 🖥️ Infraestructura
- **Nueva VM3:** MongoDB OnPrem (4GB RAM, 2 CPU, 50GB)
- **AWS Cloud:** DocumentDB cluster y EC2 bastion
- **Herramientas:** mongosh, MongoDB Database Tools, OpenSSL

#### 📋 Laboratorios Incluidos
1. **Instalación MongoDB OnPrem**
   - Instalación de MongoDB Community
   - Configuración inicial
   - Configuración de replica set

2. **Configuración de Seguridad OnPrem**
   - Creación de certificados SSL/TLS
   - Configuración SSL en MongoDB
   - Creación de usuarios de administración

3. **Gestión de Usuarios MongoDB**
   - Creación de roles personalizados
   - Creación de usuarios con roles
   - Pruebas de permisos

4. **Operaciones CRUD y Datos de Prueba**
   - Creación de colecciones y datos
   - Creación de índices
   - Operaciones avanzadas

5. **Conectividad con DocumentDB**
   - Configuración de conexión
   - Creación de usuarios en DocumentDB
   - Migración de datos OnPrem → DocumentDB

#### 🧪 Evaluaciones (100 puntos)
- **Ejercicio 1:** Instalación y configuración SSL (25 pts)
- **Ejercicio 2:** Gestión de usuarios y roles (25 pts)
- **Ejercicio 3:** Migración de datos (30 pts)
- **Ejercicio 4:** Troubleshooting de conectividad (20 pts)

---

### **Semana 4: Automatización y Monitoreo Híbrido**
📄 **Archivo:** `laboratorio_semana4_automatizacion.md`

#### 🎯 Objetivos
- Desplegar recursos de base de datos usando Terraform
- Configurar Prometheus + Grafana para monitoreo OnPrem
- Crear playbooks de Ansible para automatización
- Integrar monitoreo híbrido OnPrem + Cloud

#### 🖥️ Infraestructura
- **Nueva VM4:** Monitoring Server (8GB RAM, 4 CPU, 100GB)
- **VMs existentes:** VM1, VM2, VM3 funcionando
- **AWS Cloud:** RDS y DocumentDB existentes
- **Herramientas:** Terraform, Ansible, Prometheus, Grafana, Exporters

#### 📋 Laboratorios Incluidos
1. **Configuración de Terraform**
   - Instalación de Terraform
   - Creación de proyecto para RDS
   - Configuración principal
   - Creación de outputs

2. **Despliegue con Terraform**
   - Configuración de variables
   - Ejecución de Terraform
   - Verificación de despliegue

3. **Instalación de Prometheus y Grafana**
   - Instalación de Prometheus
   - Configuración de Prometheus
   - Creación de servicio systemd
   - Instalación de Grafana

4. **Configuración de Exporters**
   - Node Exporter en todas las VMs
   - MySQL Exporter
   - PostgreSQL Exporter
   - MongoDB Exporter

#### 🧪 Evaluaciones (100 puntos)
- **Ejercicio 1:** Despliegue con Terraform (30 pts)
- **Ejercicio 2:** Configuración de monitoreo (35 pts)
- **Ejercicio 3:** Automatización con scripts (20 pts)
- **Ejercicio 4:** Integración híbrida (15 pts)

---

### **Semana 5: Troubleshooting y Disaster Recovery**
📄 **Archivo:** `laboratorio_semana5_troubleshooting_dr.md`

#### 🎯 Objetivos
- Diagnosticar y resolver problemas complejos OnPrem
- Ejecutar procedimientos completos de disaster recovery
- Configurar alta disponibilidad híbrida
- Simular y recuperarse de fallos críticos

#### 🖥️ Infraestructura
- **Todas las VMs:** VM1-VM4 con datos críticos
- **AWS Cloud:** RDS y DocumentDB como backup secundario
- **Herramientas:** Scripts de simulación, herramientas de recovery

#### 📋 Laboratorios Incluidos
1. **Preparación de Escenarios de Fallo**
   - Creación de datos críticos de prueba
   - Configuración de replicación MySQL
   - Configuración de streaming replication PostgreSQL

2. **Simulación de Fallos Críticos**
   - Scripts de simulación de fallos
   - Scripts de diagnóstico
   - Escenarios de fallo múltiple

3. **Procedimientos de Recovery**
   - Recovery MySQL desde backup físico
   - Recovery PostgreSQL con PITR
   - Recovery MongoDB con replica set

4. **Configuración de Alta Disponibilidad**
   - MySQL Master-Slave
   - PostgreSQL Standby
   - Configuración híbrida OnPrem-Cloud

#### 🧪 Evaluaciones Finales (100 puntos)
- **Ejercicio 1:** Diagnóstico completo (25 pts)
- **Ejercicio 2:** Disaster recovery completo (35 pts)
- **Ejercicio 3:** Configuración de alta disponibilidad (25 pts)
- **Ejercicio 4:** Automatización de recovery (15 pts)

---

## 📊 Resumen de Evaluaciones

### Distribución Total de Puntos
| Semana | Laboratorio | Puntos | Peso |
|--------|-------------|--------|------|
| 0 | Fundamentos OnPrem | 100 | 16.7% |
| 1 | Fundamentos Híbridos | 100 | 16.7% |
| 2 | MySQL/PostgreSQL Avanzado | 100 | 16.7% |
| 3 | MongoDB/Seguridad | 100 | 16.7% |
| 4 | Automatización/Monitoreo | 100 | 16.7% |
| 5 | Troubleshooting/DR | 100 | 16.7% |
| **Total** | **6 Laboratorios** | **600** | **100%** |

### Criterios de Aprobación General
- **Excelente (540-600 pts / 90-100%):** Domina todos los aspectos OnPrem y Cloud
- **Bueno (480-539 pts / 80-89%):** Maneja conceptos básicos, requiere ayuda mínima
- **Regular (420-479 pts / 70-79%):** Ejecuta tareas básicas, dificultades avanzadas
- **Insuficiente (<420 pts / <70%):** No logra competencias básicas requeridas

---

## 🛠️ Herramientas y Tecnologías Cubiertas

### Motores de Base de Datos
- **MySQL 8.0:** OnPrem + RDS
- **PostgreSQL 14:** OnPrem + RDS  
- **MongoDB 6.0:** OnPrem + DocumentDB

### Herramientas OnPrem
- **Backup:** XtraBackup, pg_basebackup, mongodump
- **Monitoreo:** MySQLTuner, pgBadger, pt-query-digest
- **Sistema:** systemd, firewall (ufw), SSL/TLS

### Herramientas Cloud
- **AWS:** RDS, DocumentDB, EC2, VPC, Security Groups
- **Monitoreo:** CloudWatch, Enhanced Monitoring

### Automatización
- **IaC:** Terraform
- **Configuración:** Ansible (básico)
- **Monitoreo:** Prometheus, Grafana, Exporters
- **Scripts:** Bash, Python (básico)

### Herramientas de Desarrollo
- **Control de versiones:** Git
- **CLI:** AWS CLI, mongosh, mysql, psql
- **Editores:** vim, nano

---

## 📁 Estructura de Archivos Entregables

```
laboratorios_dba_cloud_onprem/
├── README.md
├── indice_laboratorios_completo.md
├── semana0/
│   ├── laboratorio_semana0_fundamentos_onprem.md
│   ├── scripts/
│   │   ├── install_mysql.sh
│   │   ├── install_postgresql.sh
│   │   └── verify_lab0.sh
│   └── datasets/
│       ├── mysql_sample_data.sql
│       └── postgres_sample_data.sql
├── semana1/
│   ├── laboratorio_semana1_hibrido.md
│   ├── terraform/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   └── scripts/
│       └── cleanup_lab1.sh
├── semana2/
│   ├── laboratorio_semana2_mysql_postgres.md
│   ├── scripts/
│   │   ├── mysql_backup_script.sh
│   │   └── postgres_backup_script.sh
│   └── configs/
│       ├── my.cnf.example
│       └── postgresql.conf.example
├── semana3/
│   ├── laboratorio_semana3_mongodb_seguridad.md
│   ├── scripts/
│   │   ├── install_mongodb.sh
│   │   └── setup_ssl.sh
│   └── configs/
│       └── mongod.conf.example
├── semana4/
│   ├── laboratorio_semana4_automatizacion.md
│   ├── terraform/
│   │   ├── rds-lab/
│   │   └── monitoring/
│   ├── ansible/
│   │   └── playbooks/
│   └── monitoring/
│       ├── prometheus.yml
│       └── grafana_dashboards/
└── semana5/
    ├── laboratorio_semana5_troubleshooting_dr.md
    ├── disaster_recovery/
    │   ├── mysql_disaster_recovery.sh
    │   ├── postgres_pitr_recovery.sh
    │   └── mongodb_recovery.sh
    ├── simulation/
    │   ├── simulate_failures.sh
    │   └── diagnose_system.sh
    └── runbooks/
        ├── mysql_dr_runbook.md
        ├── postgres_dr_runbook.md
        └── mongodb_dr_runbook.md
```

---

## 🎯 Competencias Desarrolladas

### Técnicas OnPrem (40% del programa)
- ✅ Instalación y configuración de motores DB desde cero
- ✅ Administración de Linux para DBAs
- ✅ Gestión de usuarios y permisos del SO
- ✅ Configuración de servicios systemd
- ✅ Configuración de firewall y red
- ✅ Backups físicos y lógicos
- ✅ Troubleshooting de hardware y SO
- ✅ Disaster recovery OnPrem
- ✅ Alta disponibilidad sin servicios cloud

### Técnicas Cloud (30% del programa)
- ✅ Despliegue de RDS y DocumentDB
- ✅ Configuración de VPC y Security Groups
- ✅ Automatización con Terraform
- ✅ Monitoreo con CloudWatch
- ✅ Gestión de backups automáticos
- ✅ Escalado vertical y horizontal
- ✅ Configuración de parámetros cloud

### Híbridas (30% del programa)
- ✅ Conectividad OnPrem ↔ Cloud
- ✅ Migración de datos bidireccional
- ✅ Monitoreo unificado multi-entorno
- ✅ Seguridad híbrida end-to-end
- ✅ Disaster recovery híbrido
- ✅ Replicación cross-environment
- ✅ Automatización híbrida

---

## 🚀 Próximos Pasos

### Para Instructores
1. **Revisar** todos los laboratorios 2 semanas antes del inicio
2. **Preparar** infraestructura según especificaciones
3. **Probar** todos los ejercicios en entorno similar
4. **Adaptar** contenido según nivel del grupo

### Para Estudiantes
1. **Prerequisitos:** Linux básico, SQL básico, conceptos de red
2. **Preparación:** Revisar documentación de herramientas
3. **Práctica:** Dedicar tiempo adicional a ejercicios
4. **Documentación:** Mantener lab notebook personal

### Para la Organización
1. **Infraestructura:** Provisionar VMs y accesos AWS
2. **Licencias:** Verificar licencias de herramientas
3. **Soporte:** Tener equipo de soporte técnico disponible
4. **Seguimiento:** Plan de mentoring post-graduación

---

## ✅ Checklist de Implementación

### Pre-lanzamiento
- [ ] Infraestructura preparada (4 VMs + AWS)
- [ ] Todos los laboratorios probados
- [ ] Instructores capacitados
- [ ] Material didáctico completo
- [ ] Evaluaciones validadas

### Durante el programa
- [ ] Monitoreo semanal de progreso
- [ ] Feedback continuo de estudiantes
- [ ] Soporte técnico 24/7
- [ ] Ajustes de contenido según necesidad

### Post-programa
- [ ] Evaluación de satisfacción
- [ ] Seguimiento de empleabilidad
- [ ] Recolección de feedback
- [ ] Actualización de material
- [ ] Planificación de próxima cohorte

---

**Este índice completo proporciona una guía exhaustiva para implementar el programa completo de DBA Cloud OnPrem Junior, con 5 semanas de laboratorios prácticos intensivos que preparan a los estudiantes para entornos de producción reales híbridos.**
