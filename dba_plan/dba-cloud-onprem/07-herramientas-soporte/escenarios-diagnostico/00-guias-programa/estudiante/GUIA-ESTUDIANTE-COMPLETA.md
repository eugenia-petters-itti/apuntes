# 🎓 Guía Completa del Estudiante
## Programa DBA Cloud OnPrem Junior

### 🎯 Bienvenido al Programa

¡Felicidades por unirte al programa más completo de capacitación DBA! Este programa te transformará de principiante a experto en administración de bases de datos híbridas (OnPrem + Cloud).

### 📋 Estructura del Programa

**Duración Total:** 5 semanas (200 horas)
**Modalidad:** 70% práctica, 30% teoría
**Motores de BD:** MySQL, PostgreSQL, MongoDB

#### Semana por Semana:
- **Semana 1:** Fundamentos OnPrem + Escenarios Básicos
- **Semana 2:** Performance y Optimización
- **Semana 3:** Alta Disponibilidad y Replicación
- **Semana 4:** Troubleshooting Avanzado
- **Semana 5:** Migración a Cloud y Casos Reales

### 🚀 Cómo Usar Este Sistema

#### 1. Preparación del Entorno
```bash
# Verificar que Docker esté instalado
docker --version
docker-compose --version

# Clonar o descargar el material completo
cd 07-escenarios-diagnostico

# Verificar que todo esté correcto
./validador-sistema.sh
```

#### 2. Comenzar con un Escenario
```bash
# Ver escenarios disponibles
./gestor-escenarios.sh list

# Iniciar tu primer escenario (recomendado)
./gestor-escenarios.sh start mysql/escenario-02-performance

# Ver logs en tiempo real
./gestor-escenarios.sh logs mysql/escenario-02-performance
```

#### 3. Proceso de Resolución
1. **Lee el problema** en `problema-descripcion.md`
2. **Analiza los síntomas** con las herramientas disponibles
3. **Ejecuta diagnósticos** usando los scripts proporcionados
4. **Implementa la solución** paso a paso
5. **Verifica los resultados** con métricas
6. **Documenta lo aprendido**

#### 4. Interfaces Disponibles
- **Grafana:** http://localhost:3000 (admin/admin) - Métricas en tiempo real
- **Prometheus:** http://localhost:9090 - Datos históricos
- **phpMyAdmin:** http://localhost:8080 (MySQL)
- **pgAdmin:** http://localhost:8081 (PostgreSQL)
- **Mongo Express:** http://localhost:8082 (MongoDB)

### 📊 Sistema de Evaluación

#### Puntuación por Escenario:
- **Identificación de causa raíz:** 30 puntos
- **Implementación de quick fix:** 25 puntos
- **Solución definitiva:** 25 puntos
- **Verificación de resultados:** 10 puntos
- **Documentación:** 10 puntos

#### Niveles de Competencia:
- **90-100 puntos:** 🥇 Experto
- **80-89 puntos:** 🥈 Avanzado
- **70-79 puntos:** 🥉 Competente
- **60-69 puntos:** ✅ Básico
- **<60 puntos:** 📚 Necesita refuerzo

### 🎯 Escenarios por Nivel

#### 🟢 Nivel Básico (Empezar aquí):
1. `mysql/escenario-02-performance` - Optimización de queries
2. `postgresql/escenario-02-connections` - Gestión de conexiones
3. `mongodb/escenario-02-indexing` - Creación de índices

#### 🟡 Nivel Intermedio:
1. `mysql/escenario-01-deadlocks` - Resolución de deadlocks
2. `postgresql/escenario-01-vacuum` - Problemas de VACUUM
3. `mongodb/escenario-03-replica-set` - Configuración de replica sets

#### 🔴 Nivel Avanzado:
1. `mysql/escenario-03-replication` - Replicación compleja
2. `postgresql/escenario-05-wal` - Problemas de WAL
3. `mongodb/escenario-01-sharding` - Balanceo de shards

### 💡 Consejos para el Éxito

#### Metodología Recomendada:
1. **Lee todo el contexto** antes de empezar
2. **No te apresures** - la comprensión es más importante que la velocidad
3. **Usa las pistas sabiamente** - solo cuando realmente las necesites
4. **Documenta todo** - será útil para futuros escenarios
5. **Practica regularmente** - la consistencia es clave

#### Recursos de Apoyo:
- **Documentación oficial** de cada motor de BD
- **Scripts de diagnóstico** incluidos en cada escenario
- **Comunidad de estudiantes** (si está disponible)
- **Sesiones de mentoría** con instructores

### 🔧 Troubleshooting Común

#### Problemas Frecuentes:
```bash
# Puerto ocupado
./gestor-escenarios.sh clean all
sudo lsof -i :3306  # Verificar puertos

# Contenedor no inicia
docker-compose logs [servicio]
docker system prune -f

# Sin espacio en disco
docker system df
docker system prune -a

# Memoria insuficiente
docker stats
# Cerrar otros escenarios si es necesario
```

### 📈 Progreso y Certificación

#### Tracking de Progreso:
- Completa todos los escenarios básicos (3)
- Avanza a escenarios intermedios (3)
- Desafíate con escenarios avanzados (3)
- Completa el proyecto final integrador

#### Certificación:
- **Promedio mínimo:** 70 puntos
- **Escenarios completados:** Mínimo 9 de 15
- **Proyecto final:** Aprobado
- **Evaluación práctica:** Aprobada

### 🎓 Próximos Pasos

Una vez completado el programa:
1. **Portfolio profesional** con casos resueltos
2. **Certificación oficial** del programa
3. **Recomendaciones laborales** 
4. **Acceso a comunidad** de egresados
5. **Actualizaciones continuas** del material

---

**¡Éxito en tu journey como DBA!** 🚀
