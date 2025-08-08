# Escenario PostgreSQL 02: Crisis de Conexiones
## 🟢 Nivel: Básico | Tiempo estimado: 25 minutos

### 📋 Contexto del Problema

**Empresa:** FinTech "PayFlow Solutions"
**Sistema:** API de procesamiento de pagos
**Horario:** Viernes 16:00 - Pico de transacciones de fin de semana
**Urgencia:** CRÍTICA - API rechazando conexiones

### 🚨 Síntomas Reportados

**Reporte del equipo de DevOps:**
```
"La API de pagos está rechazando nuevas conexiones desde hace 30 minutos.
Los logs muestran errores de 'too many connections'.
Las aplicaciones cliente están fallando al conectarse a la base de datos.
El monitoreo muestra que estamos en el límite de conexiones."
```

**Métricas observadas:**
- ⚠️ Conexiones activas: 100/100 (límite alcanzado)
- ⚠️ Conexiones en estado IDLE: 85
- ⚠️ Conexiones en estado ACTIVE: 15
- ⚠️ Tiempo promedio de conexión: 45 minutos
- ⚠️ Pool de conexiones de aplicación: Agotado
- ⚠️ Errores de conexión: 500+ en la última hora

### 📊 Datos Disponibles

**Aplicaciones conectadas:**
- `payment-api` - API principal (20 conexiones esperadas)
- `notification-service` - Servicio de notificaciones (10 conexiones)
- `reporting-service` - Servicio de reportes (15 conexiones)
- `batch-processor` - Procesador de lotes (5 conexiones)
- `monitoring-tools` - Herramientas de monitoreo (5 conexiones)

**Patrones identificados:**
1. **Conexiones IDLE prolongadas** - No se liberan correctamente
2. **Connection pooling deficiente** - Configuración subóptima
3. **Queries de larga duración** - Bloquean conexiones
4. **Falta de timeout** en conexiones inactivas

### 🎯 Tu Misión

Como DBA Junior PostgreSQL, debes:

1. **Identificar conexiones problemáticas** y su origen
2. **Analizar configuración de conexiones** actual
3. **Liberar conexiones innecesarias** de forma segura
4. **Optimizar configuración** de max_connections y timeouts
5. **Implementar monitoreo** para prevenir recurrencia

### 📈 Criterios de Éxito

**Resolución exitosa cuando:**
- ✅ Conexiones activas <80% del límite
- ✅ Conexiones IDLE <20% del total
- ✅ API acepta nuevas conexiones
- ✅ Tiempo promedio de conexión <10 minutos
- ✅ Configuración optimizada implementada

### 🔧 Herramientas Disponibles

**En el contenedor PostgreSQL:**
- Vista `pg_stat_activity` para análisis de conexiones
- Configuración de timeouts disponible
- Herramientas de monitoreo de conexiones
- Scripts de análisis de pool de conexiones

**Scripts de diagnóstico:**
- `connection-analyzer.sql`
- `idle-connection-killer.sql`
- `connection-config-optimizer.sql`
- `pool-monitor.sql`

### ⏰ Cronómetro

**Tiempo límite:** 25 minutos
**Pistas disponibles:** 3 (penalización: -10 puntos cada una)
**Puntuación máxima:** 100 puntos

---

**¿Listo para comenzar?** 
Ejecuta: `docker-compose up -d` en el directorio del escenario.
