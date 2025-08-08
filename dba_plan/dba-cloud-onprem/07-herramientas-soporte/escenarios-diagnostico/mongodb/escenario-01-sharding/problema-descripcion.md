# Escenario MongoDB 01: Crisis de Sharding Imbalance
## 🔴 Nivel: Avanzado | Tiempo estimado: 50 minutos

### 📋 Contexto del Problema

**Empresa:** IoT Platform "SensorNet"
**Sistema:** Plataforma de recolección de datos de sensores IoT
**Horario:** Miércoles 14:00 - Pico de actividad diurna
**Urgencia:** CRÍTICA - Algunos shards sobrecargados, otros vacíos

### 🚨 Síntomas Reportados

**Reporte del equipo de infraestructura:**
```
"El cluster MongoDB está completamente desbalanceado.
Shard-01 tiene 85% de los datos y está al 95% de CPU.
Shard-02 y Shard-03 están prácticamente vacíos (<5% CPU).
Las consultas de agregación tardan más de 5 minutos.
Los inserts están fallando por timeout en shard-01."
```

**Métricas observadas:**
- ⚠️ Shard-01: 850GB de datos, CPU 95%, RAM 90%
- ⚠️ Shard-02: 45GB de datos, CPU 15%, RAM 25%
- ⚠️ Shard-03: 38GB de datos, CPU 12%, RAM 22%
- ⚠️ Balancer: Deshabilitado hace 2 semanas
- ⚠️ Chunk size: 1GB (muy grande)
- ⚠️ Queries cross-shard: 85% del total

### 📊 Datos Disponibles

**Colecciones principales:**
- `sensor_readings` - Lecturas de sensores (sharded por sensor_id)
- `device_metadata` - Metadatos de dispositivos (sharded por device_id)
- `aggregated_metrics` - Métricas agregadas por hora (sharded por timestamp)
- `user_sessions` - Sesiones de usuarios (no sharded)

**Patrones de datos identificados:**
1. **Hotspot en sensor_id**: 80% de datos en rango 1000-2000
2. **Timestamp skew**: Datos históricos vs tiempo real
3. **Geolocalización**: Concentración en ciertas regiones
4. **Device types**: Algunos tipos generan 10x más datos

### 🎯 Tu Misión

Como DBA Senior MongoDB, debes:

1. **Analizar el desbalance actual** de chunks y datos
2. **Identificar la causa raíz** del mal sharding
3. **Rebalancear el cluster** de forma segura
4. **Optimizar la shard key** para distribución futura
5. **Configurar monitoreo** para prevenir recurrencia

### 📈 Criterios de Éxito

**Resolución exitosa cuando:**
- ✅ Distribución de datos: <40% diferencia entre shards
- ✅ CPU balanceado: <30% diferencia entre shards
- ✅ Queries cross-shard: <50% del total
- ✅ Tiempo de agregación: <30 segundos
- ✅ Balancer funcionando automáticamente

### 🔧 Herramientas Disponibles

**En el cluster MongoDB:**
- MongoDB Compass conectado
- Profiler habilitado en todas las DBs
- Scripts de análisis de sharding
- Herramientas de migración de chunks

**Scripts de diagnóstico:**
- `shard-analyzer.js`
- `chunk-distribution.js`
- `balancer-status.js`
- `query-pattern-analyzer.js`

### ⏰ Cronómetro

**Tiempo límite:** 50 minutos
**Pistas disponibles:** 3 (penalización: -15 puntos cada una)
**Puntuación máxima:** 100 puntos

---

**¿Listo para comenzar?** 
Ejecuta: `docker-compose up -d` en el directorio del escenario.
