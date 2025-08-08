# Escenario PostgreSQL 01: Crisis de VACUUM
## 🔴 Nivel: Intermedio | Tiempo estimado: 40 minutos

### 📋 Contexto del Problema

**Empresa:** SaaS Analytics "DataFlow"
**Sistema:** Plataforma de análisis de datos en tiempo real
**Horario:** Lunes 09:00 - Inicio de semana laboral
**Urgencia:** ALTA - Dashboards extremadamente lentos

### 🚨 Síntomas Reportados

**Reporte del equipo de operaciones:**
```
"Los dashboards que antes cargaban en 2-3 segundos ahora toman 2-3 minutos.
Las consultas de reportes están fallando por timeout.
El tamaño de la base de datos creció de 50GB a 180GB en una semana.
Los usuarios reportan que la aplicación está 'congelada'."
```

**Métricas observadas:**
- ⚠️ Tiempo de consulta promedio: 45-120 segundos (normal: 2-5 seg)
- ⚠️ Tamaño de BD: 180GB (esperado: ~60GB)
- ⚠️ Conexiones activas: 95/100 (todas en estado 'active')
- ⚠️ CPU del servidor: 95% (normal: 30-40%)
- ⚠️ I/O Wait: 80% (normal: 10-15%)

### 📊 Datos Disponibles

**Tablas principales afectadas:**
- `events` - Eventos de usuario (alta frecuencia de INSERT/UPDATE/DELETE)
- `user_sessions` - Sesiones de usuario (actualizaciones constantes)
- `analytics_cache` - Cache de métricas (limpieza diaria)
- `audit_logs` - Logs de auditoría (solo INSERT, retención 90 días)

**Patrones de uso identificados:**
1. **Carga masiva nocturna** - ETL que procesa 10M+ registros
2. **Updates frecuentes** - Sesiones actualizadas cada 30 segundos
3. **Limpieza diaria** - DELETE de registros antiguos a las 02:00
4. **Consultas analíticas** - Agregaciones complejas durante el día

### 🎯 Tu Misión

Como DBA Senior PostgreSQL, debes:

1. **Identificar por qué VACUUM no está funcionando** correctamente
2. **Analizar el bloat de tablas** y su impacto en performance
3. **Implementar solución inmediata** para recuperar performance
4. **Configurar VACUUM automático** optimizado
5. **Establecer monitoreo** para prevenir recurrencia

### 📈 Criterios de Éxito

**Resolución exitosa cuando:**
- ✅ Consultas de dashboard <10 segundos
- ✅ Tamaño de BD reducido a <80GB
- ✅ CPU del servidor <50%
- ✅ I/O Wait <25%
- ✅ VACUUM automático funcionando correctamente

### 🔧 Herramientas Disponibles

**En el contenedor PostgreSQL:**
- Extensión `pg_stat_statements` habilitada
- Extensión `pgstattuple` para análisis de bloat
- Logs de VACUUM detallados
- Scripts de monitoreo personalizados

**Scripts de diagnóstico:**
- `vacuum-analyzer.sql`
- `bloat-detector.sql`
- `table-stats.sql`
- `autovacuum-tuner.sh`

### ⏰ Cronómetro

**Tiempo límite:** 40 minutos
**Pistas disponibles:** 3 (penalización: -10 puntos cada una)
**Puntuación máxima:** 100 puntos

---

**¿Listo para comenzar?** 
Ejecuta: `docker-compose up -d` en el directorio del escenario.
