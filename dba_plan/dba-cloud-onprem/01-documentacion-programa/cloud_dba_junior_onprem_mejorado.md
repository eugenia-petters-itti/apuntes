# Cloud DBA OnPrem Junior - Versión Mejorada

## 0. Fundamentos OnPrem (NUEVO)
### Administración básica de Linux para DBAs
- Comandos esenciales: ls, cd, ps, top, df, du, netstat, ss
- Gestión de usuarios y permisos del SO (useradd, usermod, chmod, chown)
- Servicios del sistema con systemd (systemctl start/stop/enable/status)
- Configuración básica de red (ip, ping, telnet, nc)
- Gestión de logs del sistema (/var/log/, journalctl)

### Instalación y configuración OnPrem
- Instalación de MySQL/PostgreSQL desde repositorios oficiales
- Configuración de archivos de configuración (my.cnf, postgresql.conf)
- Configuración de firewall local (ufw, iptables básico)
- Gestión de almacenamiento (mount, fstab, LVM básico)
- Configuración de servicios de red (SSH, SSL/TLS)

### Backup y almacenamiento OnPrem
- Estrategias de backup local (disk, tape, NAS)
- Herramientas de sincronización (rsync, scp)
- Compresión y encriptación de backups
- Rotación de backups y políticas de retención

## 1. Conceptos básicos de bases de datos (independientes del motor)
### Modelo relacional y NoSQL
- Diferencias entre bases relacionales (MySQL/PostgreSQL) y NoSQL (DocumentDB/MongoDB)
- Concepto de tablas, índices, claves primarias/foráneas, colecciones y documentos
- **NUEVO:** Comparación OnPrem vs Cloud (ventajas/desventajas de cada modelo)

### Operaciones CRUD
- Crear, leer, actualizar y borrar datos
- Uso básico de SELECT, INSERT, UPDATE, DELETE en SQL
- Operaciones básicas en DocumentDB/MongoDB (find, insertOne, updateOne)
- **NUEVO:** Optimización de queries para entornos con recursos limitados

### Índices y rendimiento
- Qué son los índices, tipos comunes (BTREE, Hash, GIN, GIST)
- Impacto en consultas y escritura
- **NUEVO:** Monitoreo de índices en entornos OnPrem (pg_stat_user_indexes, SHOW INDEX)

### Integridad y normalización
- Entender conceptos de normalización y cuándo desnormalizar
- **NUEVO:** Consideraciones de performance OnPrem vs Cloud

## 2. Conocimientos básicos de MySQL
### Instalación y configuración OnPrem
- **NUEVO:** Instalación desde repositorios (apt, yum, dnf)
- **NUEVO:** Configuración inicial de seguridad (mysql_secure_installation)
- Conexión básica (cliente CLI, GUI)
- **NUEVO:** Configuración de my.cnf para entornos OnPrem

### Administración básica
- Diferencias entre motores de almacenamiento (InnoDB vs MyISAM)
- **NUEVO:** Gestión de usuarios del SO vs usuarios de MySQL
- Backups y restauración con mysqldump, MySQL Shell (dumpInstance, loadDump)
- **NUEVO:** Backups físicos con Percona XtraBackup
- Parámetros básicos (max_connections, innodb_buffer_pool_size)
- **NUEVO:** Tuning para hardware específico

### Monitoreo OnPrem
- Monitoreo de estado con SHOW STATUS, SHOW PROCESSLIST
- **NUEVO:** Herramientas OnPrem: MySQLTuner, pt-query-digest
- **NUEVO:** Configuración de logs (error log, slow query log, binary log)

## 3. Conocimientos básicos de PostgreSQL
### Instalación y configuración OnPrem
- **NUEVO:** Instalación desde repositorios oficiales
- **NUEVO:** Configuración inicial (initdb, pg_hba.conf, postgresql.conf)
- Conexión básica con psql (autenticación, SSL)
- **NUEVO:** Configuración de autenticación OnPrem

### Administración básica
- Roles y privilegios: CREATE ROLE, GRANT, REVOKE
- **NUEVO:** Gestión de tablespaces y esquemas
- Backups con pg_dump, restauración con pg_restore
- **NUEVO:** Backups físicos con pg_basebackup
- Uso de esquemas (public, custom schemas)
- Parámetros comunes (work_mem, shared_buffers, effective_cache_size)

### Monitoreo OnPrem
- Monitoreo básico: pg_stat_activity, pg_stat_statements
- **NUEVO:** Herramientas OnPrem: pgBadger, pg_stat_kcache
- **NUEVO:** Configuración de logs y análisis de performance

## 4. Conocimientos básicos de DocumentDB/MongoDB
### MongoDB OnPrem vs DocumentDB Cloud
- **NUEVO:** Instalación de MongoDB Community OnPrem
- **NUEVO:** Configuración básica (mongod.conf)
- Diferencias con MongoDB tradicional (limitaciones de DocumentDB)
- Conexión usando mongosh (OnPrem y Cloud)

### Operaciones básicas
- Operaciones básicas: db.collection.find(), insertOne, updateOne
- Índices en MongoDB/DocumentDB (createIndex)
- **NUEVO:** Sharding y replica sets OnPrem
- **NUEVO:** Backups OnPrem con mongodump/mongorestore

### Migración y sincronización
- **NUEVO:** Herramientas de migración OnPrem ↔ Cloud
- **NUEVO:** MongoDB Atlas vs DocumentDB vs MongoDB OnPrem

## 5. Conocimientos de Cloud y Híbrido (AWS enfocado a bases de datos)
### RDS y DocumentDB en AWS
- Crear instancias, configurarlas (CPU, RAM, almacenamiento)
- Parámetros en grupos de parámetros (DB Parameter Groups)
- Backups automáticos y snapshots manuales
- Escalado vertical (modificar tamaño) y horizontal (read replicas)
- Endpoints de conexión (writer/read replicas)

### Arquitecturas híbridas (NUEVO)
- **NUEVO:** Conectividad OnPrem ↔ Cloud (VPN, Direct Connect)
- **NUEVO:** Database Migration Service (DMS) para migraciones
- **NUEVO:** Estrategias de disaster recovery híbridas
- **NUEVO:** Sincronización de datos bidireccional

### Seguridad híbrida
- Configuración de VPC, subnets y security groups
- **NUEVO:** Configuración de VPN site-to-site
- Uso de Secrets Manager para contraseñas
- **NUEVO:** Gestión de certificados OnPrem y Cloud
- Roles IAM básicos para acceso a RDS/DocumentDB

### Monitoreo híbrido (NUEVO)
- Métricas básicas en CloudWatch: CPU, conexiones, IOPS, almacenamiento
- **NUEVO:** Integración con herramientas OnPrem (Prometheus, Grafana, Zabbix)
- **NUEVO:** Alertas unificadas OnPrem + Cloud
- Configuración de alarmas simples (CPU alta, storage casi lleno)

## 6. Automatización e Infraestructura como Código
### Terraform para entornos híbridos
- Variables y terraform apply/plan/destroy
- Recursos de RDS (aws_db_instance, aws_db_parameter_group)
- **NUEVO:** Providers para VMware, bare metal (vsphere, metal)
- **NUEVO:** Gestión de recursos OnPrem con Terraform
- Concepto de state y outputs

### Herramientas de automatización OnPrem (NUEVO)
- **NUEVO:** Ansible para configuración de servidores DB
- **NUEVO:** Scripts de backup automatizados (bash, Python)
- **NUEVO:** Cron jobs para tareas recurrentes
- **NUEVO:** Configuration management básico

### Uso de Git
- Clonar repos, hacer commits, push/pull
- **NUEVO:** Gestión de configuraciones como código
- **NUEVO:** Branching strategies para cambios de producción

## 7. Operaciones diarias y soporte
### Operaciones básicas
- Crear usuarios y asignar roles (readonly/readwrite)
- Ejecutar queries de diagnóstico para performance y locking
- Identificar problemas básicos de conexión (firewall, credenciales)
- Verificar backups y restauraciones simples
- Documentar cambios y procedimientos

### Troubleshooting OnPrem (NUEVO)
- **NUEVO:** Diagnóstico de problemas de hardware (disk, memory, CPU)
- **NUEVO:** Análisis de logs del sistema operativo
- **NUEVO:** Troubleshooting de red OnPrem
- **NUEVO:** Procedimientos de recovery ante fallos de hardware
- **NUEVO:** Escalamiento de incidentes críticos

### Mantenimiento preventivo (NUEVO)
- **NUEVO:** Actualizaciones de SO y patches de seguridad
- **NUEVO:** Mantenimiento de hardware y limpieza
- **NUEVO:** Verificación de integridad de datos
- **NUEVO:** Pruebas de disaster recovery

## 8. Herramientas de monitoreo OnPrem y Cloud (NUEVO)
### Herramientas OnPrem
- **NUEVO:** Prometheus + Grafana para métricas
- **NUEVO:** Zabbix para monitoreo de infraestructura
- **NUEVO:** Nagios para alertas críticas
- **NUEVO:** ELK Stack para análisis de logs

### Integración híbrida
- **NUEVO:** Exporters para enviar métricas OnPrem a CloudWatch
- **NUEVO:** Configuración de alertas unificadas
- **NUEVO:** Dashboards híbridos

## 9. Buenas prácticas y golden rules
### Seguridad
- No exponer RDS o bases OnPrem a internet sin protección
- Habilitar backups automáticos y encriptación (KMS/TDE)
- Usar roles IAM y autenticación fuerte
- **NUEVO:** Hardening de servidores OnPrem
- **NUEVO:** Gestión de parches y actualizaciones

### Performance y disponibilidad
- Monitorear espacio y conexiones
- Mantener versiones soportadas y planificar upgrades
- **NUEVO:** Dimensionamiento adecuado de hardware OnPrem
- **NUEVO:** Estrategias de alta disponibilidad híbridas

### Operaciones
- **NUEVO:** Documentación de procedimientos OnPrem
- **NUEVO:** Runbooks para incidentes comunes
- **NUEVO:** Políticas de backup y recovery testing

---

# TEMARIO MEJORADO

## Semana 0 – Fundamentos OnPrem (NUEVA)
### Conceptos a enseñar:
- Administración básica de Linux para DBAs
- Instalación de MySQL/PostgreSQL desde cero
- Configuración de servicios del sistema (systemd)
- Gestión básica de almacenamiento y red
- Configuración de firewall local

### Prácticas:
- Instalar MySQL y PostgreSQL en una VM Linux
- Configurar servicios para inicio automático
- Configurar firewall para permitir conexiones DB
- Crear usuarios del SO y configurar permisos

## Semana 1 – Fundamentos de bases de datos y arquitecturas híbridas
### Conceptos a enseñar:
- Diferencia entre bases relacionales y NoSQL (OnPrem vs Cloud)
- Conceptos de tablas, índices, claves primarias/foráneas, esquemas y colecciones
- Arquitectura básica de RDS y DocumentDB en AWS
- **NUEVO:** Arquitecturas híbridas y conectividad OnPrem ↔ Cloud
- Endpoints y tipos de endpoints (writer, reader)
- Backups automáticos vs manuales (Cloud vs OnPrem)

### Prácticas:
- Conectarse vía CLI a instancias OnPrem y Cloud
- Identificar componentes de una instancia RDS en la consola
- **NUEVO:** Configurar conectividad básica OnPrem ↔ Cloud

## Semana 2 – MySQL y PostgreSQL (OnPrem + Cloud)
### Conceptos a enseñar:
- Crear usuarios y roles, asignar permisos (GRANT/REVOKE)
- Comandos CRUD básicos
- Backups con mysqldump, pg_dump y restauraciones
- **NUEVO:** Backups físicos (XtraBackup, pg_basebackup)
- Monitoreo básico: SHOW PROCESSLIST, pg_stat_activity
- **NUEVO:** Herramientas OnPrem: MySQLTuner, pgBadger
- Parámetros básicos y tuning para hardware específico

### Prácticas:
- Crear un usuario readonly y readwrite en PostgreSQL y MySQL (OnPrem)
- Crear y restaurar backups lógicos y físicos
- **NUEVO:** Configurar monitoreo básico con herramientas OnPrem
- Identificar conexiones activas y consultas lentas

## Semana 3 – DocumentDB/MongoDB y Seguridad Híbrida
### Conceptos a enseñar:
- **NUEVO:** Instalación y configuración de MongoDB OnPrem
- Conexión a DocumentDB con mongosh
- Operaciones básicas en colecciones (find, insertOne, updateOne)
- Limitaciones DocumentDB vs MongoDB nativo
- **NUEVO:** Migración OnPrem ↔ Cloud
- Seguridad: Security Groups, VPC, IAM Roles y Secrets Manager
- **NUEVO:** Seguridad OnPrem: firewall, SSL/TLS, autenticación
- Encriptación con KMS y TDE

### Prácticas:
- **NUEVO:** Instalar y configurar MongoDB OnPrem
- Conectar y crear una colección en DocumentDB y MongoDB OnPrem
- Configurar un usuario con acceso limitado
- **NUEVO:** Configurar SSL/TLS en MongoDB OnPrem
- Validar que las instancias estén encriptadas y en red privada

## Semana 4 – Automatización, Monitoreo Híbrido y Operaciones
### Conceptos a enseñar:
- Terraform básico: terraform plan/apply/destroy
- Despliegue de RDS con aws_db_instance y grupos de parámetros
- **NUEVO:** Terraform para recursos OnPrem (VMware, bare metal)
- **NUEVO:** Ansible para configuración de servidores DB
- Métricas clave en CloudWatch (CPU, conexiones, almacenamiento, IOPS)
- **NUEVO:** Herramientas OnPrem: Prometheus, Grafana, Zabbix
- **NUEVO:** Integración de monitoreo híbrido
- Alertas y notificaciones básicas (SNS, Slack, email)
- Golden rules: backups habilitados, no público, encriptación activa

### Prácticas:
- Desplegar un RDS MySQL usando Terraform
- **NUEVO:** Configurar Prometheus + Grafana para monitoreo OnPrem
- **NUEVO:** Crear playbook de Ansible para instalación de PostgreSQL
- Crear alarmas en CloudWatch y herramientas OnPrem
- **NUEVO:** Configurar dashboard híbrido (OnPrem + Cloud)
- Verificar cumplimiento de golden rules en instancias reales

## Semana 5 – Troubleshooting y Disaster Recovery (NUEVA)
### Conceptos a enseñar:
- **NUEVO:** Diagnóstico de problemas OnPrem (hardware, SO, red)
- **NUEVO:** Análisis de logs del sistema y aplicaciones
- **NUEVO:** Procedimientos de disaster recovery OnPrem
- **NUEVO:** Estrategias de alta disponibilidad híbridas
- **NUEVO:** Testing de backups y procedimientos de recovery

### Prácticas:
- **NUEVO:** Simular y resolver fallos comunes OnPrem
- **NUEVO:** Ejecutar procedimiento completo de disaster recovery
- **NUEVO:** Configurar replicación MySQL/PostgreSQL OnPrem
- **NUEVO:** Probar migración de datos OnPrem ↔ Cloud

---

# EVALUACIÓN MEJORADA

## Evaluación semanal

### Semana 0 (NUEVA):
**Preguntas:** Comandos básicos Linux, diferencia entre usuarios SO vs DB, configuración de servicios
**Ejercicio:** Instalar PostgreSQL desde cero y configurar para inicio automático

### Semana 1:
**Preguntas:** Diferencias OnPrem vs Cloud, arquitecturas híbridas, endpoint writer vs reader
**Ejercicio:** Conectarse a instancias OnPrem y Cloud, mostrar bases de datos disponibles

### Semana 2:
**Preguntas:** Diferencias GRANT vs REVOKE, backups lógicos vs físicos, herramientas de tuning
**Ejercicio:** Crear usuario readonly, restaurar backup físico, ejecutar MySQLTuner

### Semana 3:
**Preguntas:** MongoDB vs DocumentDB, configuración SSL/TLS, migración de datos
**Ejercicio:** Instalar MongoDB OnPrem, configurar SSL, migrar datos a DocumentDB

### Semana 4:
**Preguntas:** Terraform para OnPrem, métricas híbridas, integración de herramientas
**Ejercicio:** Deploy con Terraform, configurar Grafana, crear dashboard híbrido

### Semana 5 (NUEVA):
**Preguntas:** Procedimientos DR, troubleshooting OnPrem, alta disponibilidad
**Ejercicio:** Ejecutar DR completo, resolver fallo simulado, configurar replicación

## Evaluación final (práctica mejorada)
1. **NUEVO:** Instalar y configurar PostgreSQL OnPrem con SSL
2. Crear una base de datos en RDS con Terraform
3. Configurar un usuario readonly en ambos entornos
4. **NUEVO:** Configurar replicación OnPrem → Cloud
5. Generar y restaurar backups lógicos y físicos
6. Conectar a DocumentDB y MongoDB OnPrem, hacer operaciones CRUD
7. **NUEVO:** Configurar monitoreo híbrido con Grafana
8. **NUEVO:** Ejecutar procedimiento de disaster recovery
9. Validar métricas y golden rules (backups, encriptación, acceso privado)

## Criterios de aprobación mejorados
- **Teórico:** Responde al menos el 75% de las preguntas de conceptos (OnPrem + Cloud)
- **Práctico OnPrem:** Ejecuta instalación, configuración y troubleshooting básico de manera autónoma
- **Práctico Cloud:** Demuestra manejo de servicios AWS y automatización
- **Híbrido:** Configura conectividad y monitoreo entre entornos OnPrem y Cloud
- **Seguridad:** Demuestra comprensión de seguridad en ambos entornos
- **Operaciones:** Ejecuta procedimientos de backup, recovery y mantenimiento
