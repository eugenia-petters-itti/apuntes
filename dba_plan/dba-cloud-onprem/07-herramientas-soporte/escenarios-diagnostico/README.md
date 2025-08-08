# 🎯 Escenarios de Diagnóstico DBA

## 📁 Estructura de Escenarios

Cada escenario contiene:
- `docker-compose.yml` - Orquestación de servicios
- `simuladores/` - Scripts Python para generar problemas
- `init-scripts/` - Scripts de inicialización de BD
- `prometheus/` - Configuración de métricas
- `grafana/` - Dashboards de monitoreo
- `problema-descripcion.md` - Descripción del problema
- `solucion-guia.md` - Guía de solución
- `evaluacion-config.yml` - Configuración de evaluación

## 🚀 Uso de Escenarios

1. Navegar al escenario deseado
2. Ejecutar `docker-compose up -d`
3. Iniciar simulador correspondiente
4. Monitorear con Grafana
5. Aplicar soluciones
6. Evaluar con sistema automático

## 📊 Escenarios Disponibles

### MySQL
- `escenario-01-deadlocks` - Bloqueos mutuos
- `escenario-02-performance` - Rendimiento
- `escenario-03-replication` - Replicación
- `escenario-04-corruption` - Corrupción
- `escenario-05-memory` - Memoria

### PostgreSQL
- `escenario-01-vacuum` - Mantenimiento
- `escenario-02-connections` - Conexiones
- `escenario-03-locks` - Bloqueos
- `escenario-04-statistics` - Estadísticas
- `escenario-05-wal` - WAL

### MongoDB
- `escenario-01-sharding` - Sharding
- `escenario-02-indexing` - Índices
- `escenario-03-replica-set` - Réplicas
- `escenario-04-aggregation` - Agregación
- `escenario-05-storage` - Almacenamiento
