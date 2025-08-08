# 🎓 TUTORIAL COMPLETO - Sistema de Entrenamiento DBA

## 📋 Índice del Tutorial

1. [Introducción y Requisitos](#introducción-y-requisitos)
2. [Primer Uso - Configuración Inicial](#primer-uso---configuración-inicial)
3. [Tutorial Básico - Tu Primer Escenario](#tutorial-básico---tu-primer-escenario)
4. [Tutorial Intermedio - Escenarios Avanzados](#tutorial-intermedio---escenarios-avanzados)
5. [Tutorial Avanzado - Monitoreo y Evaluación](#tutorial-avanzado---monitoreo-y-evaluación)
6. [Guía para Instructores](#guía-para-instructores)
7. [Solución de Problemas](#solución-de-problemas)
8. [Casos de Uso Prácticos](#casos-de-uso-prácticos)

---

## 🚀 Introducción y Requisitos

### ¿Qué es el Sistema DBA?
Un entorno completo de entrenamiento para DBAs que simula problemas reales de bases de datos en un ambiente controlado y seguro.

### 📋 Requisitos Previos
- **Docker:** Versión 20.10 o superior
- **Docker Compose:** Versión 1.29 o superior
- **Python 3:** Versión 3.8 o superior
- **Sistema Operativo:** macOS, Linux, o Windows con WSL2
- **Memoria RAM:** Mínimo 8GB (recomendado 16GB)
- **Espacio en disco:** Mínimo 10GB libres

### ✅ Verificar Requisitos
```bash
# Verificar Docker
docker --version
docker-compose --version

# Verificar Python
python3 --version

# Verificar sistema
./scripts-utilitarios/validacion-final-simple.sh
```

---

## 🔧 Primer Uso - Configuración Inicial

### Paso 1: Navegar al Sistema
```bash
cd /ruta/a/tu/sistema/07-herramientas-soporte
```

### Paso 2: Verificar Estructura
```bash
# Ver estructura principal
ls -la

# Deberías ver:
# - README.md
# - escenarios-diagnostico/
# - scripts-utilitarios/
# - documentacion/
```

### Paso 3: Validar Sistema
```bash
# Ejecutar validación completa
./scripts-utilitarios/validacion-final-simple.sh

# Deberías ver: "🎉 SISTEMA ALTAMENTE FUNCIONAL (100%)"
```

### Paso 4: Explorar Escenarios Disponibles
```bash
cd escenarios-diagnostico

# Ver escenarios por motor de BD
ls mysql/        # 5 escenarios MySQL
ls postgresql/   # 5 escenarios PostgreSQL
ls mongodb/      # 5 escenarios MongoDB
```

---

## 🎯 Tutorial Básico - Tu Primer Escenario

### Escenario Recomendado: MySQL Deadlocks
Este es el escenario más completo y fácil de entender para principiantes.

#### Paso 1: Navegar al Escenario
```bash
cd escenarios-diagnostico/mysql/escenario-01-deadlocks
```

#### Paso 2: Explorar la Estructura
```bash
ls -la

# Verás:
# - docker-compose.yml      # Configuración de servicios
# - simuladores/            # Scripts que generan problemas
# - init-scripts/           # Scripts de inicialización de BD
# - prometheus/             # Configuración de métricas
# - grafana/               # Dashboards de monitoreo
# - problema-descripcion.md # Descripción del problema
# - solucion-guia.md       # Guía de solución
```

#### Paso 3: Leer la Descripción del Problema
```bash
cat problema-descripcion.md
```

#### Paso 4: Levantar el Entorno
```bash
# Levantar todos los servicios
docker-compose up -d

# Verificar que estén corriendo
docker-compose ps

# Deberías ver servicios como:
# - mysql-db (puerto 3306)
# - simulator
# - prometheus (puerto 9090)
# - grafana (puerto 3000)
```

#### Paso 5: Acceder a las Herramientas

**Base de Datos MySQL:**
```bash
# Conectar a MySQL
docker-compose exec mysql-db mysql -u root -p
# Password: dba2024!

# Ver bases de datos
SHOW DATABASES;
USE training_db;
SHOW TABLES;
```

**Grafana (Monitoreo Visual):**
```bash
# Abrir en navegador
open http://localhost:3000

# Credenciales por defecto:
# Usuario: admin
# Password: admin
```

**Prometheus (Métricas):**
```bash
# Abrir en navegador
open http://localhost:9090
```

#### Paso 6: Ejecutar el Simulador
```bash
# En una nueva terminal, ejecutar simulador
docker-compose exec simulator python3 main_simulator.py

# O ejecutar en background
docker-compose exec -d simulator python3 main_simulator.py
```

#### Paso 7: Observar el Problema
```bash
# Ver logs del simulador
docker-compose logs -f simulator

# Ver logs de MySQL
docker-compose logs -f mysql-db

# Conectar a MySQL y ver deadlocks
docker-compose exec mysql-db mysql -u root -pdba2024! -e "SHOW ENGINE INNODB STATUS\G" | grep -A 20 "LATEST DETECTED DEADLOCK"
```

#### Paso 8: Diagnosticar con Herramientas
```bash
# Usar queries de diagnóstico
cd ../../../herramientas-diagnostico/queries-diagnostico/

# Ver queries disponibles
cat mysql-diagnostics.sql

# Ejecutar query específica para deadlocks
docker-compose -f ../../mysql/escenario-01-deadlocks/docker-compose.yml exec mysql-db mysql -u root -pdba2024! training_db < mysql-diagnostics.sql
```

#### Paso 9: Aplicar Solución
```bash
# Leer guía de solución
cd ../../mysql/escenario-01-deadlocks/
cat solucion-guia.md

# Aplicar configuraciones recomendadas
# (Seguir pasos específicos en la guía)
```

#### Paso 10: Limpiar Entorno
```bash
# Detener servicios
docker-compose down

# Limpiar volúmenes (opcional)
docker-compose down -v
```

---

## 🔥 Tutorial Intermedio - Escenarios Avanzados

### Escenario PostgreSQL: Problemas de Vacuum

#### Configuración Rápida
```bash
cd escenarios-diagnostico/postgresql/escenario-01-vacuum

# Levantar entorno
docker-compose up -d

# Ejecutar simulador de problemas
docker-compose exec simulator python3 vacuum_simulator.py
```

#### Diagnóstico Avanzado
```bash
# Conectar a PostgreSQL
docker-compose exec postgres-db psql -U app_user -d training_db

# Ver estadísticas de vacuum
SELECT schemaname, tablename, n_dead_tup, n_live_tup, 
       last_vacuum, last_autovacuum 
FROM pg_stat_user_tables 
WHERE n_dead_tup > 0;

# Ver configuración de autovacuum
SHOW autovacuum;
SHOW autovacuum_vacuum_threshold;
```

### Escenario MongoDB: Problemas de Sharding

#### Configuración y Diagnóstico
```bash
cd escenarios-diagnostico/mongodb/escenario-01-sharding

# Levantar entorno
docker-compose up -d

# Conectar a MongoDB
docker-compose exec mongodb mongo -u admin -p dba2024!

# Ver estado del sharding
sh.status()

# Ver distribución de chunks
db.chunks.aggregate([
  {$group: {_id: "$shard", count: {$sum: 1}}},
  {$sort: {count: -1}}
])
```

---

## 📊 Tutorial Avanzado - Monitoreo y Evaluación

### Configurar Monitoreo Completo

#### Paso 1: Acceder a Grafana
```bash
# URL: http://localhost:3000
# Usuario: admin / Password: admin

# Importar dashboards predefinidos
# Los dashboards están en: grafana/dashboards/
```

#### Paso 2: Configurar Alertas
```bash
# Editar configuración de Prometheus
cd prometheus/
cat prometheus.yml

# Agregar reglas de alerta personalizadas
# (Ver documentación específica de cada escenario)
```

### Usar el Sistema de Evaluación

#### Evaluación Automática
```bash
# Ejecutar evaluador en un escenario
cd escenarios-diagnostico/
python3 evaluador_mejorado.py mysql/escenario-01-deadlocks

# Ver reporte de evaluación
cat evaluation-report.json
```

#### Evaluación Manual
```bash
# Usar criterios de evaluacion-config.yml
cd mysql/escenario-01-deadlocks/
cat evaluacion-config.yml

# Seguir criterios de evaluación paso a paso
```

---

## 👨‍🏫 Guía para Instructores

### Preparar una Sesión de Entrenamiento

#### Antes de la Clase
```bash
# 1. Validar sistema completo
./scripts-utilitarios/validacion-final-simple.sh

# 2. Preparar escenarios específicos
cd escenarios-diagnostico/mysql/escenario-01-deadlocks
docker-compose pull  # Pre-descargar imágenes

# 3. Verificar acceso a herramientas
open http://localhost:3000  # Grafana
open http://localhost:9090  # Prometheus
```

#### Durante la Clase
```bash
# 1. Demostrar problema
docker-compose up -d
docker-compose exec simulator python3 main_simulator.py

# 2. Guiar diagnóstico
# Usar queries en herramientas-diagnostico/

# 3. Mostrar monitoreo en tiempo real
# Grafana dashboards

# 4. Evaluar soluciones
python3 evaluador_mejorado.py [escenario]
```

#### Después de la Clase
```bash
# Limpiar entornos
docker-compose down -v

# Generar reportes de progreso
# (Ver logs de evaluación)
```

### Personalizar Escenarios

#### Modificar Simuladores
```bash
# Editar simuladores Python
cd simuladores/
nano main_simulator.py

# Ajustar parámetros:
# - Frecuencia de problemas
# - Intensidad de carga
# - Tipos de transacciones
```

#### Crear Nuevos Problemas
```bash
# Usar plantillas en:
cd plantillas-escenarios/

# Copiar plantilla base
cp -r plantilla-mysql/ nuevo-escenario/

# Personalizar configuraciones
```

---

## 🔧 Solución de Problemas

### Problemas Comunes

#### Docker no Inicia
```bash
# Verificar Docker daemon
docker info

# Reiniciar Docker
sudo systemctl restart docker  # Linux
# o usar Docker Desktop en macOS/Windows
```

#### Puertos Ocupados
```bash
# Ver puertos en uso
netstat -tulpn | grep :3306
netstat -tulpn | grep :5432
netstat -tulpn | grep :27017

# Cambiar puertos en docker-compose.yml si es necesario
```

#### Simuladores no Funcionan
```bash
# Verificar logs
docker-compose logs simulator

# Verificar sintaxis Python
python3 -m py_compile simuladores/main_simulator.py

# Reinstalar dependencias
docker-compose build --no-cache simulator
```

#### Grafana no Muestra Datos
```bash
# Verificar conexión a Prometheus
curl http://localhost:9090/metrics

# Verificar configuración de datasource
# En Grafana: Configuration > Data Sources
```

### Comandos de Diagnóstico

#### Estado del Sistema
```bash
# Ver todos los contenedores
docker ps -a

# Ver uso de recursos
docker stats

# Ver logs de todos los servicios
docker-compose logs
```

#### Limpiar Sistema
```bash
# Limpiar contenedores parados
docker container prune

# Limpiar imágenes no usadas
docker image prune

# Limpiar volúmenes
docker volume prune

# Limpiar todo (¡CUIDADO!)
docker system prune -a
```

---

## 💼 Casos de Uso Prácticos

### Caso 1: Entrenamiento Individual
```bash
# Estudiante trabajando solo
cd escenarios-diagnostico/mysql/escenario-01-deadlocks
docker-compose up -d
# Seguir tutorial paso a paso
```

### Caso 2: Clase Grupal
```bash
# Instructor prepara múltiples escenarios
for scenario in mysql/escenario-01-deadlocks postgresql/escenario-01-vacuum mongodb/escenario-01-sharding; do
  cd $scenario
  docker-compose up -d
  cd -
done
```

### Caso 3: Evaluación/Examen
```bash
# Configurar escenario sin mostrar solución
cd escenarios-diagnostico/mysql/escenario-01-deadlocks
docker-compose up -d
# Estudiante debe diagnosticar y resolver
# Usar evaluador automático para calificar
python3 evaluador_mejorado.py mysql/escenario-01-deadlocks
```

### Caso 4: Práctica de Certificación
```bash
# Rotar entre diferentes escenarios
scenarios=(
  "mysql/escenario-01-deadlocks"
  "mysql/escenario-02-performance"
  "postgresql/escenario-01-vacuum"
  "mongodb/escenario-01-sharding"
)

for scenario in "${scenarios[@]}"; do
  echo "Practicando: $scenario"
  cd "escenarios-diagnostico/$scenario"
  docker-compose up -d
  # Tiempo limitado para resolver
  sleep 1800  # 30 minutos
  docker-compose down
  cd -
done
```

---

## 📚 Recursos Adicionales

### Documentación Complementaria
- `README.md` - Guía principal del sistema
- `documentacion/INDICE-MAESTRO.md` - Navegación completa
- `documentacion/LOGRO-FINAL-100-FUNCIONAL.md` - Capacidades del sistema

### Scripts Útiles
- `scripts-utilitarios/validacion-final-simple.sh` - Validación rápida
- `scripts-utilitarios/mantenimiento-sistema.sh` - Mantenimiento automatizado

### Material Educativo
- `MATERIAL_ESTUDIANTES/` - Recursos para estudiantes
- `MATERIAL_INSTRUCTOR/` - Recursos para instructores

---

## 🎯 Próximos Pasos

### Para Principiantes
1. Completar tutorial básico con MySQL deadlocks
2. Practicar con PostgreSQL vacuum
3. Explorar MongoDB sharding
4. Usar herramientas de monitoreo

### Para Usuarios Avanzados
1. Personalizar simuladores
2. Crear escenarios propios
3. Configurar alertas avanzadas
4. Integrar con sistemas externos

### Para Instructores
1. Preparar plan de estudios
2. Configurar evaluaciones automáticas
3. Personalizar criterios de evaluación
4. Crear material complementario

---

## 📞 Soporte y Ayuda

### Recursos de Ayuda
- **Documentación:** `documentacion/`
- **Ejemplos:** Cada escenario incluye ejemplos completos
- **Logs:** `docker-compose logs` para diagnóstico
- **Validación:** Scripts de validación incluidos

### Contacto
- **Documentación técnica:** Ver `documentacion/`
- **Problemas técnicos:** Revisar sección "Solución de Problemas"
- **Mejoras:** Documentar en `documentacion/`

---

**¡Feliz aprendizaje con el Sistema de Entrenamiento DBA!** 🎓✨

*Tutorial creado el 8 de Agosto, 2025 - Sistema DBA 100% funcional*
