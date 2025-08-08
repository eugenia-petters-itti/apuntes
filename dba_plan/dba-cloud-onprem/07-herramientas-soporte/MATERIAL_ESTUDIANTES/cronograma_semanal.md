# 📅 CRONOGRAMA SEMANAL DETALLADO
## DBA Cloud OnPrem Junior - Planificación Completa 200 Horas

### 🎯 **ESTRUCTURA GENERAL DEL PROGRAMA**

**Duración Total:** 5 semanas + 1 semana preparación = 6 semanas
**Horas Totales:** 200 horas de contenido + 10 horas preparación = 210 horas
**Modalidad:** 70% práctica, 30% teoría
**Horario Sugerido:** 40 horas/semana (8 horas/día, 5 días/semana)

---

## 📊 **DISTRIBUCIÓN DE TIEMPO POR SEMANA**

| Semana | Tema Principal | Horas | OnPrem | Cloud | Práctica |
|--------|---------------|-------|---------|-------|----------|
| -1 | Preparación | 10h | 100% | 0% | 80% |
| 0 | Fundamentos OnPrem | 40h | 100% | 0% | 70% |
| 1 | Arquitecturas Híbridas | 40h | 50% | 50% | 75% |
| 2 | Administración Avanzada | 40h | 60% | 40% | 70% |
| 3 | Seguridad y NoSQL | 40h | 55% | 45% | 75% |
| 4 | Automatización | 40h | 40% | 60% | 80% |
| 5 | Troubleshooting y DR | 40h | 50% | 50% | 70% |

---

## 🗓️ **SEMANA -1: PREPARACIÓN (10 horas)**
**Objetivo:** Configurar entorno completo de laboratorio

### **Lunes: Verificación de Hardware y Software (2 horas)**
```
09:00-10:00 | Verificación de prerequisitos técnicos
            | - Ejecutar script verify_prerequisites.sh
            | - Verificar hardware (CPU, RAM, disco)
            | - Verificar conectividad a internet y AWS

10:00-11:00 | Instalación de software faltante
            | - Instalar VirtualBox/VMware si falta
            | - Instalar AWS CLI v2
            | - Instalar Terraform
            | - Configurar Git
```

### **Martes: Configuración de VMs (2 horas)**
```
09:00-10:00 | Creación de VMs base
            | - Descargar Ubuntu 20.04 LTS ISO
            | - Crear VM1: DBA-Lab-MySQL (4GB RAM, 25GB disco)
            | - Configurar red host-only

10:00-11:00 | Instalación de Ubuntu en VM1
            | - Instalar Ubuntu Server
            | - Configurar usuario dbastudent
            | - Configurar SSH y red
```

### **Miércoles: Configuración de Red (2 horas)**
```
09:00-10:00 | Configuración de red host-only
            | - Crear red 192.168.56.0/24
            | - Configurar VM1 con IP 192.168.56.10
            | - Verificar conectividad VM ↔ Host

10:00-11:00 | Clonación de VMs
            | - Clonar VM1 → VM2 (PostgreSQL)
            | - Clonar VM1 → VM3 (MongoDB)  
            | - Clonar VM1 → VM4 (Tools)
            | - Configurar IPs: .11, .12, .13
```

### **Jueves: Configuración AWS (2 horas)**
```
09:00-10:00 | Configuración de cuenta AWS
            | - Crear/verificar cuenta AWS
            | - Configurar billing alerts
            | - Crear IAM user para laboratorio

10:00-11:00 | Configuración AWS CLI
            | - Instalar AWS CLI en todas las VMs
            | - Configurar credenciales
            | - Verificar conectividad a AWS
```

### **Viernes: Verificación Final (2 horas)**
```
09:00-10:00 | Testing completo del entorno
            | - Verificar conectividad entre todas las VMs
            | - Verificar acceso a internet desde VMs
            | - Verificar acceso a AWS desde VMs

10:00-11:00 | Preparación para Semana 0
            | - Descargar scripts de instalación
            | - Descargar datasets
            | - Revisar material de Semana 0
```

**Checklist Semana -1:**
- [ ] ✅ 4 VMs Ubuntu 20.04 creadas y configuradas
- [ ] ✅ Red host-only funcionando (192.168.56.0/24)
- [ ] ✅ AWS CLI configurado en todas las VMs
- [ ] ✅ Conectividad completa verificada
- [ ] ✅ Material de Semana 0 descargado

---

## 🗓️ **SEMANA 0: FUNDAMENTOS ONPREM (40 horas)**
**Objetivo:** Dominar instalación y configuración OnPrem desde cero

### **Lunes: Instalación MySQL OnPrem (8 horas)**
```
09:00-10:30 | Teoría: Arquitectura MySQL
            | - Componentes de MySQL Server
            | - Archivos de configuración
            | - Estructura de directorios
            | - Procesos y threads

10:30-10:45 | BREAK

10:45-12:00 | Práctica: Instalación manual MySQL
            | - Descargar MySQL 8.0 desde fuente
            | - Compilar e instalar paso a paso
            | - Configurar my.cnf básico
            | - Inicializar base de datos

12:00-13:00 | ALMUERZO

13:00-14:30 | Práctica: Configuración avanzada
            | - Configurar usuarios y permisos
            | - Configurar acceso remoto
            | - Configurar SSL/TLS
            | - Configurar logging

14:30-14:45 | BREAK

14:45-16:00 | Práctica: Carga de datos
            | - Cargar dataset e-commerce (50MB)
            | - Crear índices optimizados
            | - Verificar integridad de datos
            | - Configurar backup inicial

16:00-17:00 | Evaluación: Ejercicios MySQL
            | - 4 ejercicios prácticos
            | - Documentar configuración
            | - Troubleshooting básico
```

### **Martes: Instalación PostgreSQL OnPrem (8 horas)**
```
09:00-10:30 | Teoría: Arquitectura PostgreSQL
            | - Procesos PostgreSQL (postmaster, backend)
            | - Archivos de configuración
            | - Estructura de cluster
            | - WAL y checkpoints

10:30-10:45 | BREAK

10:45-12:00 | Práctica: Instalación manual PostgreSQL
            | - Descargar PostgreSQL 14 desde fuente
            | - Compilar con extensiones
            | - Inicializar cluster
            | - Configurar postgresql.conf

12:00-13:00 | ALMUERZO

13:00-14:30 | Práctica: Configuración avanzada
            | - Configurar pg_hba.conf
            | - Configurar usuarios y roles
            | - Configurar conexiones remotas
            | - Configurar SSL

14:30-14:45 | BREAK

14:45-16:00 | Práctica: Carga de datos
            | - Cargar dataset analytics (30MB)
            | - Crear índices y constraints
            | - Configurar vacuum y analyze
            | - Configurar backup con pg_dump

16:00-17:00 | Evaluación: Ejercicios PostgreSQL
            | - 4 ejercicios prácticos
            | - Comparación con MySQL
            | - Optimización de queries
```

### **Miércoles: Instalación MongoDB OnPrem (8 horas)**
```
09:00-10:30 | Teoría: Arquitectura MongoDB
            | - Documentos y colecciones
            | - Sharding y replica sets
            | - Índices en MongoDB
            | - Agregation pipeline

10:30-10:45 | BREAK

10:45-12:00 | Práctica: Instalación manual MongoDB
            | - Descargar MongoDB 6.0
            | - Configurar mongod.conf
            | - Inicializar replica set
            | - Configurar autenticación

12:00-13:00 | ALMUERZO

13:00-14:30 | Práctica: Configuración avanzada
            | - Configurar SSL/TLS
            | - Configurar usuarios y roles
            | - Configurar sharding básico
            | - Configurar logging y profiling

14:30-14:45 | BREAK

14:45-16:00 | Práctica: Carga de datos
            | - Cargar dataset social media (25MB)
            | - Crear índices compuestos
            | - Configurar TTL collections
            | - Configurar backup con mongodump

16:00-17:00 | Evaluación: Ejercicios MongoDB
            | - 4 ejercicios prácticos
            | - Queries de agregación
            | - Comparación con SQL
```

### **Jueves: Herramientas de Monitoreo (8 horas)**
```
09:00-10:30 | Teoría: Monitoreo de bases de datos
            | - Métricas importantes
            | - Herramientas de monitoreo
            | - Alertas y umbrales
            | - Dashboards y visualización

10:30-10:45 | BREAK

10:45-12:00 | Práctica: Instalación Prometheus
            | - Instalar Prometheus en VM4
            | - Configurar targets
            | - Instalar exporters en cada DB VM
            | - Configurar scraping

12:00-13:00 | ALMUERZO

13:00-14:30 | Práctica: Instalación Grafana
            | - Instalar Grafana
            | - Configurar data source Prometheus
            | - Importar dashboards para MySQL/PostgreSQL/MongoDB
            | - Personalizar dashboards

14:30-14:45 | BREAK

14:45-16:00 | Práctica: Configuración de alertas
            | - Configurar alertas en Prometheus
            | - Configurar notificaciones
            | - Testing de alertas
            | - Documentar procedimientos

16:00-17:00 | Evaluación: Ejercicios Monitoreo
            | - Configurar alertas personalizadas
            | - Crear dashboard personalizado
            | - Simular problemas y verificar alertas
```

### **Viernes: Integración y Testing (8 horas)**
```
09:00-10:30 | Práctica: Conectividad entre DBs
            | - Configurar foreign data wrappers
            | - Configurar replicación MySQL
            | - Configurar streaming replication PostgreSQL
            | - Configurar replica set MongoDB

10:30-10:45 | BREAK

10:45-12:00 | Práctica: Backup y Recovery
            | - Configurar backups automatizados
            | - Testing de recovery procedures
            | - Configurar backup a storage externo
            | - Documentar procedimientos

12:00-13:00 | ALMUERZO

13:00-14:30 | Práctica: Performance tuning
            | - Optimizar configuraciones
            | - Analizar slow queries
            | - Optimizar índices
            | - Testing de performance

14:30-14:45 | BREAK

14:45-16:00 | Evaluación: Proyecto integrador Semana 0
            | - Implementar solución completa OnPrem
            | - 3 DBs funcionando con monitoreo
            | - Backups automatizados
            | - Documentación completa

16:00-17:00 | Review y preparación Semana 1
            | - Review de conceptos aprendidos
            | - Q&A session
            | - Preparación para arquitecturas híbridas
```

**Checklist Semana 0:**
- [ ] ✅ MySQL 8.0 instalado y configurado desde cero
- [ ] ✅ PostgreSQL 14 instalado y configurado desde cero
- [ ] ✅ MongoDB 6.0 instalado y configurado desde cero
- [ ] ✅ Prometheus + Grafana funcionando
- [ ] ✅ Datasets cargados en todas las DBs
- [ ] ✅ Backups automatizados configurados
- [ ] ✅ 12 ejercicios prácticos completados
- [ ] ✅ Documentación completa del entorno

---

## 🗓️ **SEMANA 1: ARQUITECTURAS HÍBRIDAS (40 horas)**
**Objetivo:** Conectar entornos OnPrem con Cloud AWS

### **Lunes: AWS RDS MySQL (8 horas)**
```
09:00-10:30 | Teoría: AWS RDS vs OnPrem
            | - Diferencias arquitecturales
            | - Ventajas y desventajas
            | - Casos de uso híbridos
            | - Estrategias de migración

10:30-10:45 | BREAK

10:45-12:00 | Práctica: Creación RDS MySQL
            | - Crear VPC y subnets
            | - Crear security groups
            | - Crear instancia RDS MySQL
            | - Configurar parameter groups

12:00-13:00 | ALMUERZO

13:00-14:30 | Práctica: Conectividad OnPrem ↔ RDS
            | - Configurar conectividad desde VMs
            | - Testing de latencia y performance
            | - Configurar SSL connections
            | - Migrar datos OnPrem → RDS

14:30-14:45 | BREAK

14:45-16:00 | Práctica: Configuración híbrida
            | - Configurar read replicas
            | - Configurar backup híbrido
            | - Configurar monitoreo CloudWatch
            | - Integrar con Grafana OnPrem

16:00-17:00 | Evaluación: Ejercicios RDS
            | - 4 ejercicios prácticos
            | - Comparación performance OnPrem vs RDS
            | - Configurar alertas híbridas
```

### **Martes: AWS RDS PostgreSQL (8 horas)**
```
09:00-10:30 | Teoría: PostgreSQL en AWS
            | - RDS vs Aurora PostgreSQL
            | - Extensiones disponibles
            | - Limitaciones vs OnPrem
            | - Best practices

10:30-10:45 | BREAK

10:45-12:00 | Práctica: Creación RDS PostgreSQL
            | - Crear instancia RDS PostgreSQL
            | - Configurar parameter groups
            | - Configurar opciones avanzadas
            | - Configurar backup y maintenance

12:00-13:00 | ALMUERZO

13:00-14:30 | Práctica: Migración de datos
            | - Usar pg_dump/pg_restore
            | - Usar AWS DMS
            | - Verificar integridad de datos
            | - Optimizar performance post-migración

14:30-14:45 | BREAK

14:45-16:00 | Práctica: Configuración avanzada
            | - Configurar logical replication
            | - Configurar connection pooling
            | - Configurar monitoring avanzado
            | - Testing de failover

16:00-17:00 | Evaluación: Ejercicios PostgreSQL RDS
            | - Migración completa OnPrem → RDS
            | - Configurar replicación bidireccional
            | - Optimización de queries en RDS
```

### **Miércoles: AWS DocumentDB (8 horas)**
```
09:00-10:30 | Teoría: DocumentDB vs MongoDB
            | - Diferencias de API
            | - Limitaciones de DocumentDB
            | - Casos de uso apropiados
            | - Estrategias de migración

10:30-10:45 | BREAK

10:45-12:00 | Práctica: Creación DocumentDB
            | - Crear cluster DocumentDB
            | - Configurar instancias
            | - Configurar security groups
            | - Configurar SSL/TLS

12:00-13:00 | ALMUERZO

13:00-14:30 | Práctica: Migración MongoDB → DocumentDB
            | - Usar mongodump/mongorestore
            | - Adaptar queries incompatibles
            | - Verificar funcionalidad
            | - Optimizar performance

14:30-14:45 | BREAK

14:45-16:00 | Práctica: Configuración híbrida
            | - Configurar sync OnPrem ↔ DocumentDB
            | - Configurar backup híbrido
            | - Configurar monitoring
            | - Testing de failover

16:00-17:00 | Evaluación: Ejercicios DocumentDB
            | - Migración completa
            | - Configurar aplicación híbrida
            | - Comparación performance
```

### **Jueves: Networking y Seguridad (8 horas)**
```
09:00-10:30 | Teoría: Networking híbrido
            | - VPC y subnets
            | - Security groups vs NACLs
            | - VPN y Direct Connect
            | - Best practices de seguridad

10:30-10:45 | BREAK

10:45-12:00 | Práctica: Configuración de red
            | - Configurar VPC peering
            | - Configurar VPN site-to-site
            | - Configurar routing
            | - Testing de conectividad

12:00-13:00 | ALMUERZO

13:00-14:30 | Práctica: Seguridad avanzada
            | - Configurar IAM roles y policies
            | - Configurar encryption at rest
            | - Configurar encryption in transit
            | - Configurar auditing

14:30-14:45 | BREAK

14:45-16:00 | Práctica: Monitoreo de seguridad
            | - Configurar CloudTrail
            | - Configurar GuardDuty
            | - Configurar alertas de seguridad
            | - Testing de vulnerabilidades

16:00-17:00 | Evaluación: Ejercicios Seguridad
            | - Implementar arquitectura segura
            | - Configurar compliance
            | - Testing de penetración básico
```

### **Viernes: Proyecto Integrador Híbrido (8 horas)**
```
09:00-12:00 | Proyecto: Arquitectura híbrida completa
            | - Diseñar arquitectura OnPrem + AWS
            | - Implementar conectividad
            | - Configurar replicación
            | - Configurar backup híbrido

12:00-13:00 | ALMUERZO

13:00-16:00 | Proyecto: Testing y optimización
            | - Testing de performance
            | - Testing de failover
            | - Optimización de costos
            | - Documentación completa

16:00-17:00 | Presentación y review
            | - Presentar arquitectura implementada
            | - Review de conceptos aprendidos
            | - Q&A session
            | - Preparación Semana 2
```

**Checklist Semana 1:**
- [ ] ✅ RDS MySQL creado y conectado
- [ ] ✅ RDS PostgreSQL creado y conectado  
- [ ] ✅ DocumentDB cluster creado y conectado
- [ ] ✅ Migración de datos OnPrem → Cloud completada
- [ ] ✅ Arquitectura híbrida funcionando
- [ ] ✅ Monitoreo híbrido configurado
- [ ] ✅ 12 ejercicios prácticos completados
- [ ] ✅ Proyecto integrador completado

---

## 📊 **RESUMEN DE SEMANAS 2-5**

### **SEMANA 2: ADMINISTRACIÓN AVANZADA (40 horas)**
- **Lunes:** Gestión avanzada de usuarios y roles
- **Martes:** Estrategias de backup y recovery
- **Miércoles:** Optimización de performance
- **Jueves:** Herramientas de monitoreo avanzado
- **Viernes:** Proyecto integrador administración

### **SEMANA 3: SEGURIDAD Y NOSQL (40 horas)**
- **Lunes:** Implementación de SSL/TLS avanzado
- **Martes:** Configuración de autenticación avanzada
- **Miércoles:** Auditoría y compliance
- **Jueves:** Migración de datos segura
- **Viernes:** Proyecto integrador seguridad

### **SEMANA 4: AUTOMATIZACIÓN (40 horas)**
- **Lunes:** Terraform para infraestructura
- **Martes:** Scripts de automatización
- **Miércoles:** CI/CD para bases de datos
- **Jueves:** Monitoreo con Prometheus/Grafana avanzado
- **Viernes:** Proyecto integrador automatización

### **SEMANA 5: TROUBLESHOOTING Y DR (40 horas)**
- **Lunes:** Diagnóstico avanzado de problemas
- **Martes:** Procedimientos de disaster recovery
- **Miércoles:** Alta disponibilidad
- **Jueves:** Proyecto final integrador
- **Viernes:** Presentaciones finales y certificación

---

## 📋 **SISTEMA DE SEGUIMIENTO SEMANAL**

### **Métricas de Progreso**
```
Cada semana debes completar:
- 40 horas de contenido (8h/día x 5 días)
- 12-16 ejercicios prácticos
- 1 proyecto integrador
- 1 evaluación semanal
- Documentación completa
```

### **Checklist Diario**
```
Al final de cada día:
- [ ] ✅ Objetivos del día completados
- [ ] ✅ Ejercicios prácticos terminados
- [ ] ✅ Notas y documentación actualizadas
- [ ] ✅ Problemas identificados y resueltos
- [ ] ✅ Preparación para el día siguiente
```

### **Review Semanal**
```
Al final de cada semana:
- [ ] ✅ Todos los objetivos semanales completados
- [ ] ✅ Proyecto integrador funcionando
- [ ] ✅ Evaluación semanal aprobada (>70%)
- [ ] ✅ Documentación completa y organizada
- [ ] ✅ Preparación para la siguiente semana
```

---

**🎯 Este cronograma te guiará paso a paso hacia el dominio completo de las tecnologías DBA híbridas OnPrem + Cloud. ¡Síguelo religiosamente y tendrás éxito garantizado!**
