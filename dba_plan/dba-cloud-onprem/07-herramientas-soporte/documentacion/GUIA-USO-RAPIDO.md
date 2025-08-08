# 🚀 Guía de Uso Rápido - Escenarios de Diagnóstico
## Programa DBA Cloud OnPrem Junior

### ⚡ Quick Start (5 minutos)

#### 1. Seleccionar escenario
```bash
cd 07-escenarios-diagnostico/

# Ver escenarios disponibles
ls -la mysql/        # 5 escenarios MySQL
ls -la postgresql/   # 5 escenarios PostgreSQL  
ls -la mongodb/      # 5 escenarios MongoDB
```

#### 2. Levantar escenario específico
```bash
# Ejemplo: Escenario MySQL Deadlocks
cd mysql/escenario-01-deadlocks/

# Levantar entorno completo
docker-compose up -d

# Verificar que esté funcionando
docker-compose ps
```

#### 3. Acceder a herramientas
```bash
# Logs del problema en tiempo real
docker-compose logs -f deadlock-generator

# Acceder a herramientas de diagnóstico
docker exec -it diagnostic-tools bash

# Interfaces web disponibles:
# - Grafana: http://localhost:3000 (admin/admin)
# - Prometheus: http://localhost:9090
# - phpMyAdmin: http://localhost:8080 (root/dba2024!)
```

#### 4. Ejecutar diagnóstico
```bash
# Dentro del contenedor diagnostic-tools
./scripts/deadlock-analyzer.sql

# O directamente desde host
docker exec -it mysql-deadlock-scenario mysql -u root -pdba2024! < scripts-diagnostico/deadlock-diagnostic.sql
```

#### 5. Limpiar escenario
```bash
# Detener y limpiar completamente
docker-compose down -v

# Verificar limpieza
docker system prune -f
```

### 📋 Escenarios Disponibles

#### 🐬 MySQL (5 escenarios)
| Escenario | Nivel | Tiempo | Problema Principal |
|-----------|-------|--------|-------------------|
| **01-deadlocks** | 🟡 Intermedio | 45 min | Deadlocks en transacciones concurrentes |
| **02-performance** | 🟢 Básico | 30 min | Queries lentas y falta de índices |
| **03-replication** | 🔴 Avanzado | 60 min | Replicación rota y lag |
| **04-corruption** | 🔴 Avanzado | 50 min | Corrupción de datos InnoDB |
| **05-memory** | 🟡 Intermedio | 40 min | Memory leaks y buffer pool |

#### 🐘 PostgreSQL (5 escenarios)
| Escenario | Nivel | Tiempo | Problema Principal |
|-----------|-------|--------|-------------------|
| **01-vacuum** | 🟡 Intermedio | 40 min | VACUUM problems y bloat |
| **02-connections** | 🟢 Básico | 25 min | Connection exhaustion |
| **03-locks** | 🟡 Intermedio | 35 min | Lock contention |
| **04-statistics** | 🟢 Básico | 30 min | Statistics outdated |
| **05-wal** | 🔴 Avanzado | 55 min | WAL issues y recovery |

#### 🍃 MongoDB (5 escenarios)
| Escenario | Nivel | Tiempo | Problema Principal |
|-----------|-------|--------|-------------------|
| **01-sharding** | 🔴 Avanzado | 50 min | Sharding imbalance |
| **02-indexing** | 🟢 Básico | 30 min | Missing indexes |
| **03-replica-set** | 🟡 Intermedio | 40 min | Replica set lag |
| **04-aggregation** | 🟡 Intermedio | 35 min | Aggregation performance |
| **05-storage** | 🔴 Avanzado | 45 min | Storage engine issues |

### 🎯 Metodología de Resolución

#### Proceso estándar (todos los escenarios):
1. **Leer problema-descripcion.md** (5 min)
2. **Levantar entorno** con docker-compose (2 min)
3. **Analizar síntomas** con herramientas (15-20 min)
4. **Identificar causa raíz** (10-15 min)
5. **Implementar solución** (10-15 min)
6. **Verificar resultados** (5 min)
7. **Documentar lecciones** (5 min)

#### Herramientas disponibles en cada escenario:
- **Scripts de diagnóstico** específicos por problema
- **Grafana dashboards** con métricas en tiempo real
- **Prometheus** para métricas históricas
- **Logs estructurados** del problema
- **Interfaces de administración** (phpMyAdmin, pgAdmin, Mongo Express)

### 🏆 Sistema de Puntuación

#### Puntuación base: 100 puntos
- **Identificación correcta de causa raíz**: 30 puntos
- **Implementación de quick fix**: 25 puntos
- **Diseño de solución definitiva**: 25 puntos
- **Verificación de resultados**: 10 puntos
- **Documentación de lecciones**: 10 puntos

#### Penalizaciones:
- **Pista utilizada**: -10 puntos cada una (máximo 3)
- **Tiempo excedido**: -5 puntos por cada 5 minutos extra
- **Solución incorrecta**: -20 puntos

#### Bonificaciones:
- **Resolución en tiempo récord**: +10 puntos (<70% del tiempo límite)
- **Solución innovadora**: +5 puntos
- **Documentación excepcional**: +5 puntos

### 🔧 Troubleshooting Común

#### Problemas frecuentes:
```bash
# Error: Puerto ya en uso
docker-compose down -v
sudo lsof -i :3306  # Verificar puertos ocupados

# Error: Contenedor no inicia
docker-compose logs [servicio]
docker system prune -f

# Error: Sin espacio en disco
docker system df
docker system prune -a

# Error: Memoria insuficiente
docker stats
# Cerrar otros escenarios: docker-compose down -v
```

#### Comandos útiles:
```bash
# Ver todos los contenedores activos
docker ps -a

# Logs de un servicio específico
docker-compose logs -f [servicio]

# Ejecutar comando en contenedor
docker exec -it [contenedor] [comando]

# Reiniciar servicio específico
docker-compose restart [servicio]

# Ver uso de recursos
docker stats
```

### 📚 Recursos Adicionales

#### Documentación por escenario:
- **README.md** - Instrucciones específicas
- **problema-descripcion.md** - Contexto detallado
- **solucion-guia.md** - Guía paso a paso
- **datos-sintoma/** - Logs y evidencias

#### Herramientas comunes:
- **herramientas-diagnostico/** - Scripts reutilizables
- **plantillas-escenarios/** - Para crear nuevos escenarios

#### Soporte:
- Documentación completa en cada carpeta
- Scripts de verificación incluidos
- Casos de estudio reales para referencia

---

**¡Listo para comenzar!** Selecciona tu primer escenario y comienza el diagnóstico. 🚀
