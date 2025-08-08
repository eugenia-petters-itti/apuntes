# Escenario MySQL 01: Deadlocks Críticos
## 🔴 Nivel: Intermedio | Tiempo estimado: 45 minutos

### 📋 Contexto del Problema

**Empresa:** E-commerce "TechStore"
**Sistema:** Plataforma de ventas online
**Horario:** Viernes 18:00 - Black Friday
**Urgencia:** CRÍTICA - Ventas detenidas

### 🚨 Síntomas Reportados

**Reporte del equipo de desarrollo:**
```
"Las transacciones de compra están fallando intermitentemente.
Los usuarios reportan errores de 'timeout' al finalizar compras.
El sistema se vuelve muy lento cada 2-3 minutos.
Los logs muestran errores de 'Deadlock found when trying to get lock'."
```

**Métricas observadas:**
- ⚠️ Tiempo de respuesta: 15-30 segundos (normal: 2-3 seg)
- ⚠️ Transacciones fallidas: 25% (normal: <1%)
- ⚠️ Conexiones activas: 180/200 (límite casi alcanzado)
- ⚠️ CPU del servidor: 85% (normal: 40-50%)

### 📊 Datos Disponibles

**Tablas principales afectadas:**
- `orders` - Órdenes de compra
- `inventory` - Inventario de productos
- `payments` - Pagos procesados
- `customers` - Información de clientes

**Procesos concurrentes identificados:**
1. **Proceso de compra** - Inserta orden, actualiza inventario, procesa pago
2. **Proceso de restock** - Actualiza inventario masivamente
3. **Proceso de reportes** - Lee datos para dashboard en tiempo real

### 🎯 Tu Misión

Como DBA Senior, debes:

1. **Identificar la causa raíz** de los deadlocks
2. **Analizar los patrones** de bloqueo
3. **Proponer solución inmediata** (quick fix)
4. **Diseñar solución definitiva** (arquitectural)
5. **Implementar monitoreo** para prevenir recurrencia

### 📈 Criterios de Éxito

**Resolución exitosa cuando:**
- ✅ Deadlocks reducidos a <1 por minuto
- ✅ Tiempo de respuesta <5 segundos
- ✅ Transacciones exitosas >98%
- ✅ Identificación correcta de causa raíz
- ✅ Plan de prevención documentado

### 🔧 Herramientas Disponibles

**En el contenedor MySQL:**
- Logs de error y slow query
- `SHOW ENGINE INNODB STATUS`
- `SHOW PROCESSLIST`
- Performance Schema habilitado
- Monitoring con Prometheus/Grafana

**Scripts de diagnóstico:**
- `deadlock-analyzer.sh`
- `transaction-tracer.sql`
- `lock-monitor.sql`

### ⏰ Cronómetro

**Tiempo límite:** 45 minutos
**Pistas disponibles:** 3 (penalización: -10 puntos cada una)
**Puntuación máxima:** 100 puntos

---

**¿Listo para comenzar?** 
Ejecuta: `docker-compose up -d` en el directorio del escenario.
