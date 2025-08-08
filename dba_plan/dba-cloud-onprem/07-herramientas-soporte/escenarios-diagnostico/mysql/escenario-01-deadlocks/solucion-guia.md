# Guía de Solución: Deadlocks MySQL
## Escenario TechStore E-commerce

### 🎯 Proceso de Diagnóstico Paso a Paso

#### **PASO 1: Identificación Inicial (5 minutos)**

**Comandos de diagnóstico inmediato:**
```sql
-- Ver estado general de deadlocks
SHOW ENGINE INNODB STATUS\G

-- Estadísticas de deadlocks
SELECT VARIABLE_VALUE as 'Total_Deadlocks' 
FROM performance_schema.global_status 
WHERE VARIABLE_NAME = 'Innodb_deadlocks';

-- Procesos activos sospechosos
SHOW PROCESSLIST;
```

**🔍 Qué buscar:**
- Sección "LATEST DETECTED DEADLOCK" en INNODB STATUS
- Número creciente de deadlocks en estadísticas
- Múltiples procesos en estado "Waiting for table level lock"

#### **PASO 2: Análisis de Patrones (10 minutos)**

**Ejecutar script de diagnóstico:**
```bash
# Dentro del contenedor MySQL
mysql -u root -p techstore_db < /scripts/deadlock-diagnostic.sql > /reports/diagnostico.txt
```

**🔍 Análisis de resultados:**
1. **Tablas más afectadas**: `inventory`, `orders`, `order_items`
2. **Patrón temporal**: Deadlocks cada 2-3 minutos
3. **Procesos involucrados**: Compradores vs Restockers
4. **Hotspots**: Productos con ID bajos (1-20)

#### **PASO 3: Identificación de Causa Raíz (15 minutos)**

**Causa raíz identificada:**
```
PROBLEMA: Orden inconsistente de acceso a recursos
- Proceso de compra: Accede productos en orden aleatorio
- Proceso de restock: Accede productos en orden aleatorio
- Resultado: Deadlock clásico A→B vs B→A
```

**Evidencia en logs:**
```
Transaction 1: Lock product_id=15, then product_id=7
Transaction 2: Lock product_id=7, then product_id=15
→ DEADLOCK
```

#### **PASO 4: Solución Inmediata - Quick Fix (10 minutos)**

**Opción A: Reducir timeout de locks**
```sql
-- Reducir tiempo de espera (menos bloqueos prolongados)
SET GLOBAL innodb_lock_wait_timeout = 5;
```

**Opción B: Forzar orden consistente en aplicación**
```python
# En el simulador, cambiar línea 67:
# ANTES (causa deadlocks):
first_product, second_product = max(product1, product2), min(product1, product2)

# DESPUÉS (orden consistente):
first_product, second_product = min(product1, product2), max(product1, product2)
```

**Opción C: Implementar retry logic**
```python
def execute_with_retry(transaction_func, max_retries=3):
    for attempt in range(max_retries):
        try:
            return transaction_func()
        except mysql.connector.Error as e:
            if "Deadlock found" in str(e) and attempt < max_retries - 1:
                time.sleep(random.uniform(0.1, 0.5))  # Backoff aleatorio
                continue
            raise
```

#### **PASO 5: Solución Definitiva - Arquitectural (15 minutos)**

**1. Rediseño de transacciones:**
```sql
-- ANTES: Transacción monolítica
START TRANSACTION;
SELECT ... FROM inventory WHERE product_id = ? FOR UPDATE;
SELECT ... FROM inventory WHERE product_id = ? FOR UPDATE;
INSERT INTO orders ...;
UPDATE inventory ...;
UPDATE inventory ...;
INSERT INTO order_items ...;
INSERT INTO payments ...;
COMMIT;

-- DESPUÉS: Transacciones más pequeñas y ordenadas
-- Transacción 1: Reservar inventario (orden consistente)
START TRANSACTION;
SELECT ... FROM inventory WHERE product_id IN (?, ?) ORDER BY product_id FOR UPDATE;
UPDATE inventory SET reserved = reserved + 1 WHERE product_id IN (?, ?) ORDER BY product_id;
COMMIT;

-- Transacción 2: Crear orden
START TRANSACTION;
INSERT INTO orders ...;
INSERT INTO order_items ...;
COMMIT;

-- Transacción 3: Procesar pago
START TRANSACTION;
INSERT INTO payments ...;
UPDATE inventory SET stock = stock - reserved, reserved = 0 WHERE ...;
COMMIT;
```

**2. Índices optimizados:**
```sql
-- Índice compuesto para evitar table locks
CREATE INDEX idx_inventory_product_stock ON inventory(product_id, stock);

-- Índice para órdenes por timestamp
CREATE INDEX idx_orders_created ON orders(created_at);

-- Índice para items por orden
CREATE INDEX idx_order_items_order_product ON order_items(order_id, product_id);
```

**3. Configuración MySQL optimizada:**
```ini
# En my.cnf
[mysqld]
# Reducir probabilidad de deadlocks
innodb_lock_wait_timeout = 10
innodb_deadlock_detect = ON
innodb_print_all_deadlocks = ON

# Mejorar concurrencia
innodb_thread_concurrency = 0
innodb_concurrency_tickets = 5000

# Optimizar buffer pool
innodb_buffer_pool_size = 1G
innodb_buffer_pool_instances = 8
```

### 🚀 Implementación de la Solución

#### **Quick Fix (Implementar inmediatamente):**
```bash
# 1. Aplicar configuración temporal
docker exec mysql-deadlock-scenario mysql -u root -pdba2024! -e "SET GLOBAL innodb_lock_wait_timeout = 5;"

# 2. Reiniciar simulador con orden consistente
docker restart deadlock-generator

# 3. Verificar mejora
docker exec mysql-deadlock-scenario mysql -u root -pdba2024! -e "
SELECT VARIABLE_VALUE FROM performance_schema.global_status 
WHERE VARIABLE_NAME = 'Innodb_deadlocks';"
```

#### **Solución Definitiva (Para producción):**
```bash
# 1. Aplicar nuevos índices
docker exec mysql-deadlock-scenario mysql -u root -pdba2024! techstore_db < /scripts/optimized-indexes.sql

# 2. Actualizar configuración MySQL
# (Requiere reinicio del contenedor con nueva configuración)

# 3. Desplegar código de aplicación optimizado
# (Con transacciones rediseñadas y retry logic)
```

### 📊 Verificación de Resultados

**Métricas de éxito:**
```sql
-- Antes de la solución
SELECT 'ANTES' as Momento, VARIABLE_VALUE as Deadlocks 
FROM performance_schema.global_status 
WHERE VARIABLE_NAME = 'Innodb_deadlocks';

-- Después de la solución (esperar 10 minutos)
SELECT 'DESPUÉS' as Momento, VARIABLE_VALUE as Deadlocks 
FROM performance_schema.global_status 
WHERE VARIABLE_NAME = 'Innodb_deadlocks';

-- Tiempo promedio de transacciones
SELECT 
    AVG(query_time) as Tiempo_Promedio_Segundos,
    COUNT(*) as Total_Queries
FROM mysql.slow_log 
WHERE start_time >= DATE_SUB(NOW(), INTERVAL 10 MINUTE);
```

**Resultados esperados:**
- ✅ Deadlocks: De 15-20/min a <1/min
- ✅ Tiempo de respuesta: De 15-30s a <5s
- ✅ Transacciones exitosas: De 75% a >98%
- ✅ CPU del servidor: De 85% a <60%

### 🎓 Lecciones Aprendidas

**Conceptos clave demostrados:**
1. **Orden de acceso a recursos** es crítico para evitar deadlocks
2. **Granularidad de transacciones** afecta la concurrencia
3. **Índices apropiados** reducen tiempo de locks
4. **Retry logic** es esencial en aplicaciones concurrentes
5. **Monitoreo proactivo** previene problemas en producción

**Mejores prácticas aplicadas:**
- Acceso ordenado a múltiples recursos
- Transacciones más pequeñas y específicas
- Timeouts apropiados para el contexto
- Logging detallado para diagnóstico
- Testing de carga para validar soluciones

### 🏆 Puntuación del Escenario

**Criterios de evaluación:**
- **Identificación correcta de causa raíz**: 30 puntos
- **Implementación de quick fix**: 25 puntos
- **Diseño de solución definitiva**: 25 puntos
- **Verificación de resultados**: 10 puntos
- **Documentación de lecciones**: 10 puntos

**Tiempo total utilizado**: _____ minutos (máximo 45)
**Pistas utilizadas**: _____ (penalización: -10 puntos cada una)
**Puntuación final**: _____ / 100 puntos
