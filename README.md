# 🚀 ITTI Platform - Apuntes DBA

Repositorio completo de materiales de capacitación para Database Administrators (DBAs) modernos, enfocado en entornos híbridos Cloud + OnPrem, Kubernetes y evolución hacia Database Reliability Engineering (DBRE).

## 📋 Contenido del Repositorio

### 🎯 Programas de Capacitación Disponibles

| Programa | Duración | Nivel | Enfoque Principal |
|----------|----------|-------|-------------------|
| **DBA Cloud OnPrem** | 5 semanas (200h) | Junior-Senior | Híbrido AWS + OnPrem |
| **DBA Cloud OnPrem Roadmap** | 12-36 meses | Junior-Senior | Carrera progresiva |
| **DBA Roadmap Modular** | Flexible | Todos | Habilidades específicas |
| **DBA Kubernetes** | 7-10 meses | Intermedio-Avanzado | Cloud Native + K8s |

---

## 📁 Estructura del Repositorio

```
apuntes/
├── 📂 dba_plan/                           # Directorio principal de planes DBA
│   ├── 📂 dba-cloud-onprem/              # Programa intensivo 5 semanas
│   ├── 📂 dba-cloud-onprem-roadmap/      # Roadmap de carrera completo
│   ├── 📂 dba-roadmap-modular/           # Guías modulares especializadas
│   ├── 📂 dba-kubernetes/                # Especialización Kubernetes
│   └── 📄 README.md                      # Índice general de planes
└── 📄 README.md                          # Este archivo
```

---

## 🎓 Programas Detallados

### 1. 🏢 DBA Cloud OnPrem (Programa Intensivo)
**📍 Ubicación:** `dba_plan/dba-cloud-onprem/`

**Descripción:** Programa intensivo de 5 semanas diseñado para transformar DBAs junior en expertos híbridos OnPrem + Cloud.

**Características:**
- ⏱️ **Duración:** 5 semanas (200 horas)
- 📊 **Modalidad:** 70% práctica, 30% teoría
- 🎯 **Enfoque:** Híbrido OnPrem + AWS (RDS/DocumentDB)
- 🛠️ **Incluye:** 6 laboratorios, 3 scripts de instalación, datasets realistas

**Estructura:**
```
dba-cloud-onprem/
├── 📁 01-documentacion-programa/    # Documentación del programa
├── 📁 02-laboratorios/             # 6 laboratorios semanales
├── 📁 03-scripts-instalacion/      # Scripts automatizados (MySQL, PostgreSQL, MongoDB)
├── 📁 04-datasets/                 # Datasets realistas (25-50MB c/u)
├── 📁 05-terraform/                # Infraestructura como código AWS
├── 📁 06-guias-avanzadas/          # Guías especializadas avanzadas
├── 📁 07-herramientas-soporte/     # Scripts y herramientas de apoyo
└── 📁 08-evaluaciones/             # Rúbricas y criterios de evaluación
```

**Laboratorios Incluidos:**
- **Semana 0:** Fundamentos OnPrem
- **Semana 1:** Arquitectura Híbrida
- **Semana 2:** MySQL y PostgreSQL Avanzado
- **Semana 3:** MongoDB y Seguridad
- **Semana 4:** Automatización y Monitoreo
- **Semana 5:** Troubleshooting y Disaster Recovery

---

### 2. 🗺️ DBA Cloud OnPrem Roadmap (Carrera Completa)
**📍 Ubicación:** `dba_plan/dba-cloud-onprem-roadmap/`

**Descripción:** Roadmap completo de carrera para DBAs en entornos híbridos con enfoque en AWS.

**Niveles de Progresión:**
- 🌱 **Junior DBA** (0-2 años): Fundamentos y operaciones básicas
- 🔥 **Semi-Senior DBA** (2-5 años): Arquitectura y optimización
- 🚀 **Senior DBA** (5+ años): Estrategia y liderazgo técnico

**Archivos Principales:**
- `README.md` - Índice maestro del roadmap
- `ROADMAP-JUNIOR.md` - Guía completa nivel junior
- `ROADMAP-SEMI-SENIOR.md` - Progresión semi-senior
- `ROADMAP-SENIOR.md` - Liderazgo y arquitectura empresarial
- `CERTIFICACIONES-Y-RECURSOS.md` - Certificaciones recomendadas
- `TERRAFORM-PARA-DBAS.md` - Infrastructure as Code
- `PYTHON-BASH-PARA-DBAS.md` - Automatización y scripting

---

### 3. 🧩 DBA Roadmap Modular (Habilidades Específicas)
**📍 Ubicación:** `dba_plan/dba-roadmap-modular/`

**Descripción:** Guías modulares especializadas para desarrollar habilidades específicas y evolucionar hacia Database Reliability Engineering (DBRE).

**Módulos Disponibles:**
- 📈 `junior-dba-roadmap.md` - Fundamentos para principiantes
- 🔄 `dba-to-dbre-transition.md` - **Transición DBA → DBRE** (12 meses)
- ⚡ `dbre-sre-roadmap.md` - **Roadmap DBRE completo** (El futuro de DBAs)
- 🏗️ `terraform-guide.md` - Infrastructure as Code esencial
- 🐍 `python-automation.md` - Automatización con Python
- 📊 `sli-slo-guide.md` - **SLIs y SLOs explicados** (Métricas centradas en usuario)

**🌟 Destacado: Database Reliability Engineer (DBRE)**
- **Salarios:** 40-60% más altos que DBA tradicional
- **Demanda:** +45% crecimiento anual
- **Futuro:** Los DBAs tradicionales serán obsoletos en 3-5 años
- **Oportunidades:** 5x más posiciones disponibles

---

### 4. ☸️ DBA Kubernetes (Cloud Native)
**📍 Ubicación:** `dba_plan/dba-kubernetes/`

**Descripción:** Especialización completa en bases de datos cloud-native con Kubernetes.

**Programa Estructurado:**
- ⏱️ **Duración:** 7-10 meses (30-40 semanas)
- 🎯 **Nivel Final:** Expert DBA en Kubernetes y Cloud Native
- 🛠️ **Modalidad:** Hands-on labs con proyectos prácticos

**Partes del Roadmap:**
1. **Parte 1** (`DBA_Kubernetes_Roadmap_Part1.md`): Fundamentos (8-12 semanas)
   - Kubernetes básico, k3d, EKS, Helm
   - PostgreSQL y MySQL en contenedores
   - Proyecto: Database Monitoring Stack

2. **Parte 2** (`DBA_Kubernetes_Roadmap_Part2.md`): Alta Disponibilidad (16-22 semanas)
   - CloudNativePG, Percona XtraDB, Vitess
   - Clustering y operadores especializados
   - Proyecto: Production-Ready Database Platform

3. **Parte 3** (`DBA_Kubernetes_Roadmap_Part3.md`): Automatización (6-8 semanas)
   - GitOps con ArgoCD, Terraform
   - Performance tuning, seguridad enterprise
   - Proyecto: Enterprise Database Platform

**Laboratorios Percona:**
- Directorio `percona-operators-labs/` con ejercicios prácticos
- Operadores para MySQL, PostgreSQL y MongoDB
- Configuraciones de alta disponibilidad

---

## 🎯 ¿Cuál Programa Elegir?

### 🚀 Para Transformación Rápida (RECOMENDADO)
**DBA Roadmap Modular → DBRE**
- Enfoque en transición DBA → DBRE (12 meses)
- Salarios 40-60% más altos
- Habilidades a prueba de futuro
- **Archivo clave:** `dba-roadmap-modular/dba-to-dbre-transition.md`

### 🏢 Para Entornos Empresariales
**DBA Cloud OnPrem (Programa Intensivo)**
- 5 semanas de capacitación intensiva
- Enfoque híbrido OnPrem + AWS
- Material completo con laboratorios y datasets
- **Directorio:** `dba-cloud-onprem/`

### 📈 Para Progresión de Carrera Tradicional
**DBA Cloud OnPrem Roadmap**
- Progresión Junior → Semi-Senior → Senior
- 12-36 meses de desarrollo
- Certificaciones AWS incluidas
- **Directorio:** `dba-cloud-onprem-roadmap/`

### ☸️ Para Especialización Cloud Native
**DBA Kubernetes**
- 7-10 meses de especialización
- Enfoque en contenedores y orquestación
- Proyectos enterprise reales
- **Directorio:** `dba-kubernetes/`

---

## 🛠️ Tecnologías Cubiertas

### Bases de Datos
- **Relacionales:** MySQL, PostgreSQL, SQL Server, Oracle
- **NoSQL:** MongoDB, DynamoDB, DocumentDB
- **Cloud Native:** Aurora, CloudNativePG, Vitess
- **Graph:** Neptune
- **Time Series:** Timestream

### Cloud Platforms
- **AWS:** RDS, Aurora, DynamoDB, DocumentDB, ElastiCache
- **Servicios:** DMS, Backup, Systems Manager, CloudWatch
- **Networking:** VPC, Direct Connect, Transit Gateway

### Infrastructure as Code
- **Terraform:** Módulos, state management, multi-environment
- **CloudFormation:** Templates y stacks
- **Helm:** Charts para Kubernetes
- **Docker:** Contenedores y compose

### Automatización y Monitoreo
- **Python:** Scripts de automatización y monitoreo
- **Bash:** Administración de sistemas y operaciones
- **Prometheus + Grafana:** Observabilidad avanzada
- **CloudWatch:** Métricas y alertas AWS

### Kubernetes y Orquestación
- **Kubernetes:** Clusters, pods, services, ingress
- **Operadores:** CloudNativePG, Percona, Vitess
- **GitOps:** ArgoCD, Flux
- **Service Mesh:** Istio básico

---

## 📊 Comparación de Carreras

| Aspecto | DBA Tradicional | DBA Moderno | DBRE |
|---------|----------------|-------------|------|
| **Salario Promedio** | $75K - $95K | $95K - $120K | $120K - $220K+ |
| **Crecimiento Anual** | -5% (declive) | +15% | +45% |
| **Habilidades Clave** | SQL, Backups | SQL + Python + Terraform | SRE + Observabilidad + Chaos Engineering |
| **Enfoque** | Reactivo | Proactivo | Preventivo |
| **Futuro** | Obsolescencia | Estable | Alta demanda |

---

## 🚀 Quick Start

### 1. Evaluación Inicial
```bash
# Autoevaluación rápida
¿Puedes crear una instancia RDS con Terraform? → Junior DBA
¿Implementas monitoring automatizado con Python? → Semi-Senior DBA  
¿Defines SLIs/SLOs para sistemas de datos? → DBRE
¿Lideras estrategia de confiabilidad organizacional? → Senior DBRE
```

### 2. Configuración de Entorno
```bash
# Clonar repositorio
git clone <repository-url>
cd apuntes/dba_plan

# Para programa intensivo
cd dba-cloud-onprem/03-scripts-instalacion/
chmod +x *.sh
./install_mysql_onprem.sh

# Para Terraform
cd ../05-terraform/
terraform init
terraform plan
```

### 3. Comenzar Aprendizaje
- **Principiantes:** `dba-roadmap-modular/junior-dba-roadmap.md`
- **Transición DBRE:** `dba-roadmap-modular/dba-to-dbre-transition.md`
- **Programa Intensivo:** `dba-cloud-onprem/02-laboratorios/`
- **Kubernetes:** `dba-kubernetes/DBA_Kubernetes_Roadmap_Part1.md`

---

## 📚 Recursos Adicionales

### Certificaciones Recomendadas
- **AWS Cloud Practitioner** (Foundational)
- **AWS Solutions Architect Associate**
- **AWS Database Specialty**
- **Certified Kubernetes Administrator (CKA)**

### Libros Esenciales
- "High Performance MySQL" - Baron Schwartz
- "Designing Data-Intensive Applications" - Martin Kleppmann
- "Database Reliability Engineering" - O'Reilly
- "Site Reliability Engineering" - Google

### Comunidades
- AWS User Groups
- CNCF Community
- SREcon Conferences
- Database Reliability Engineering Slack

---

## 🎯 Próximos Pasos

1. **Evalúa tu nivel actual** usando las guías de autoevaluación
2. **Elige tu camino:** DBA tradicional vs DBRE (recomendado)
3. **Configura tu lab personal** con AWS free tier
4. **Comienza con el roadmap** correspondiente a tu nivel
5. **Únete a las comunidades** para networking y soporte

---

## 📞 Soporte y Contribuciones

Este repositorio es un recurso vivo que se actualiza constantemente con las últimas tendencias y mejores prácticas en administración de bases de datos.

### Estructura de Contribución
- Cada directorio incluye su propio README con instrucciones específicas
- Scripts de verificación y troubleshooting incluidos
- Casos de estudio reales para referencia
- Documentación completa para cada tecnología

### Contacto
Para preguntas específicas sobre algún programa o sugerencias de mejora, revisa la documentación específica de cada directorio.

---

**🚀 Tu transformación como DBA moderno comienza aquí. El futuro de la administración de bases de datos está en la intersección de expertise técnico profundo e ingeniería de confiabilidad moderna.**

*Repositorio actualizado - Agosto 2025*
