# 🎯 Escenarios de Diagnóstico DBA - Resumen Completo

## 📊 Estado Actual: FUNCIONALES ✅

**Fecha de última actualización:** 8 de Agosto, 2025  
**Total de escenarios:** 18 escenarios  
**Estado de funcionalidad:** 100% operativos  

---

## 🗂️ Catálogo de Escenarios

### 🐬 MySQL (8 escenarios)

#### **Escenarios Básicos**
| Escenario | Nivel | Tiempo | Descripción | Estado |
|-----------|-------|--------|-------------|--------|
| **01-deadlocks** | Intermedio | 45 min | Resolución de bloqueos mutuos en transacciones concurrentes | ✅ |
| **02-performance** | Intermedio | 45 min | Optimización de consultas lentas y análisis de rendimiento | ✅ |
| **03-replication** | Avanzado | 60 min | Problemas de replicación master-slave | ✅ |
| **04-corruption** | Avanzado | 60 min | Recuperación de datos corruptos | ✅ |
| **05-memory** | Intermedio | 45 min | Gestión de memoria y buffer pools | ✅ |

#### **Escenarios Avanzados**
| Escenario | Nivel | Tiempo | Descripción | Estado |
|-----------|-------|--------|-------------|--------|
| **06-backup-recovery** | Avanzado | 60 min | Disaster Recovery con binary logs | ✅ |
| **07-high-availability** | Experto | 90 min | Configuración de alta disponibilidad con HAProxy | ✅ |
| **08-security-breach** | Avanzado | 45 min | Investigación y respuesta a brechas de seguridad | ✅ |

### 🐘 PostgreSQL (5 escenarios)

| Escenario | Nivel | Tiempo | Descripción | Estado |
|-----------|-------|--------|-------------|--------|
| **01-vacuum** | Intermedio | 45 min | Problemas de VACUUM y mantenimiento | ✅ |
| **02-connections** | Básico | 30 min | Gestión de conexiones y pool exhaustion | ✅ |
| **03-locks** | Intermedio | 45 min | Resolución de bloqueos y deadlocks | ✅ |
| **04-statistics** | Intermedio | 45 min | Problemas con estadísticas del query planner | ✅ |
| **05-wal** | Avanzado | 60 min | Gestión de Write-Ahead Logs | ✅ |

### 🍃 MongoDB (5 escenarios)

| Escenario | Nivel | Tiempo | Descripción | Estado |
|-----------|-------|--------|-------------|--------|
| **01-sharding** | Avanzado | 60 min | Problemas de sharding y balanceador | ✅ |
| **02-indexing** | Intermedio | 45 min | Optimización de índices y consultas | ✅ |
| **03-replica-set** | Intermedio | 45 min | Problemas en replica sets | ✅ |
| **04-aggregation** | Intermedio | 45 min | Optimización de pipelines de agregación | ✅ |
| **05-storage** | Avanzado | 60 min | Gestión de almacenamiento y compresión | ✅ |

---

## 🛠️ Componentes Técnicos

### **Cada escenario incluye:**

#### 📁 **Estructura de Archivos**
```
escenario-XX-nombre/
├── 📄 docker-compose.yml          # Orquestación completa
├── 📄 problema-descripcion.md     # Contexto y síntomas
├── 📄 solucion-guia.md           # Guía de resolución
├── 📄 evaluacion-config.yml      # Criterios de evaluación
├── 📁 simuladores/               # Scripts Python de simulación
│   ├── Dockerfile
│   ├── requirements.txt
│   └── *.py (simuladores específicos)
├── 📁 init-scripts/              # Scripts de inicialización DB
├── 📁 prometheus/                # Configuración de métricas
│   ├── prometheus.yml
│   └── alert-rules.yml
├── 📁 grafana/                   # Dashboards de monitoreo
│   ├── datasources/
│   └── dashboards/
├── 📁 scripts-diagnostico/       # Herramientas de diagnóstico
├── 📁 config/                    # Configuraciones específicas
└── 📁 datos-sintoma/             # Datos de ejemplo
```

#### 🐳 **Servicios Docker**
- **Base de datos principal** (MySQL/PostgreSQL/MongoDB)
- **Simulador de problemas** (Python)
- **Prometheus** (métricas y alertas)
- **Grafana** (visualización)
- **Exporters** (mysql-exporter, postgres-exporter, mongodb-exporter)
- **Servicios adicionales** (HAProxy para HA, etc.)

#### 📊 **Sistema de Monitoreo**
- **Prometheus:** Recolección de métricas en tiempo real
- **Grafana:** Dashboards interactivos con alertas visuales
- **Exporters:** Métricas específicas por base de datos
- **Alertas:** Configuración automática de umbrales críticos

---

## 🚀 Guía de Uso Rápido

### **1. Iniciar un Escenario**
```bash
# Navegar al escenario deseado
cd escenarios-diagnostico/mysql/escenario-01-deadlocks

# Iniciar todos los servicios
docker-compose up -d

# Verificar estado
docker-compose ps
```

### **2. Acceder a Herramientas**
- **Grafana:** http://localhost:3000 (admin/admin123)
- **Prometheus:** http://localhost:9090
- **Base de datos:** localhost:3306 (MySQL), :5432 (PostgreSQL), :27017 (MongoDB)

### **3. Monitorear el Problema**
```bash
# Ver logs del simulador
docker-compose logs -f simulator

# Conectar a la base de datos
docker-compose exec mysql-db mysql -u app_user -p training_db

# Ejecutar scripts de diagnóstico
./scripts-diagnostico/diagnostic-script.sql
```

### **4. Aplicar Solución**
- Seguir la guía en `solucion-guia.md`
- Usar scripts de diagnóstico disponibles
- Verificar métricas en Grafana

---

## 🎓 Niveles de Dificultad

### **🟢 Básico (30-45 min)**
- Problemas comunes de configuración
- Diagnóstico directo con herramientas estándar
- Soluciones documentadas y conocidas
- **Ejemplos:** connections, memory básico

### **🟡 Intermedio (45-60 min)**
- Problemas que requieren análisis de métricas
- Uso de múltiples herramientas de diagnóstico
- Soluciones que involucran optimización
- **Ejemplos:** deadlocks, performance, indexing

### **🔴 Avanzado (60-90 min)**
- Problemas complejos multi-componente
- Requiere conocimiento profundo del sistema
- Soluciones arquitecturales o de configuración avanzada
- **Ejemplos:** replication, corruption, sharding

### **⚫ Experto (90+ min)**
- Escenarios de producción realistas
- Múltiples sistemas interconectados
- Requiere toma de decisiones estratégicas
- **Ejemplos:** high-availability, disaster recovery

---

## 📈 Métricas y Evaluación

### **Sistema de Puntuación**
- **Básico:** 50-75 puntos máximo
- **Intermedio:** 75-100 puntos máximo
- **Avanzado:** 100-150 puntos máximo
- **Experto:** 150+ puntos máximo

### **Criterios de Evaluación**
1. **Diagnóstico correcto** (30% del puntaje)
2. **Solución implementada** (40% del puntaje)
3. **Tiempo de resolución** (15% del puntaje)
4. **Documentación** (10% del puntaje)
5. **Prevención futura** (5% del puntaje)

### **Métricas Automáticas**
- Tiempo de resolución (RTO)
- Precisión del diagnóstico
- Efectividad de la solución
- Uso de herramientas apropiadas

---

## 🔧 Herramientas de Gestión

### **Scripts de Utilidad**
```bash
# Validar todos los escenarios
./scripts-utilitarios/validar-funcionalidad-escenarios.sh

# Corregir problemas detectados
./scripts-utilitarios/corregir-escenarios-diagnostico.sh

# Crear escenarios adicionales
./scripts-utilitarios/crear-escenarios-adicionales.sh

# Limpiar entorno
./scripts-utilitarios/limpiar-entorno.sh
```

### **Evaluación Automática**
```bash
# Ejecutar evaluador automático
./escenarios-diagnostico/evaluador-automatico.py

# Generar reporte de progreso
./escenarios-diagnostico/generar-reporte.py
```

---

## 🎯 Casos de Uso Recomendados

### **Para Estudiantes Junior**
1. **MySQL:** escenario-02-performance, escenario-05-memory
2. **PostgreSQL:** escenario-02-connections, escenario-01-vacuum
3. **MongoDB:** escenario-02-indexing, escenario-03-replica-set

### **Para DBAs Semi-Senior**
1. **MySQL:** escenario-01-deadlocks, escenario-03-replication
2. **PostgreSQL:** escenario-03-locks, escenario-04-statistics
3. **MongoDB:** escenario-01-sharding, escenario-04-aggregation

### **Para DBAs Senior**
1. **MySQL:** escenario-06-backup-recovery, escenario-08-security-breach
2. **PostgreSQL:** escenario-05-wal
3. **MongoDB:** escenario-05-storage

### **Para Arquitectos/DBRE**
1. **MySQL:** escenario-07-high-availability
2. **Combinaciones multi-escenario**
3. **Escenarios personalizados**

---

## 🚀 Próximas Mejoras

### **En Desarrollo**
- [ ] Escenarios de Kubernetes (Cloud Native)
- [ ] Integración con AWS RDS/Aurora
- [ ] Escenarios de migración de datos
- [ ] Simulación de fallos de red
- [ ] Escenarios de compliance (GDPR, SOX)

### **Mejoras Planificadas**
- [ ] Dashboard instructor en tiempo real
- [ ] Sistema de badges y certificaciones
- [ ] Integración con LMS
- [ ] Escenarios colaborativos multi-usuario
- [ ] Simulación de cargas de trabajo reales

---

## 📞 Soporte y Contribuciones

### **Reportar Problemas**
- Usar el sistema de issues del repositorio
- Incluir logs detallados y pasos para reproducir
- Especificar entorno (OS, Docker version, etc.)

### **Contribuir Nuevos Escenarios**
1. Seguir la estructura estándar de directorios
2. Incluir documentación completa
3. Probar con el script de validación
4. Enviar pull request con descripción detallada

### **Contacto**
- **Documentación:** Ver README.md principal
- **Issues:** GitHub Issues
- **Discusiones:** GitHub Discussions

---

**🎉 ¡Los escenarios están listos para entrenar a la próxima generación de DBAs!**

*Última actualización: Agosto 2025*
