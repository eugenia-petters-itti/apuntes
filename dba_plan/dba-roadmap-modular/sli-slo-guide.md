# SLIs y SLOs: Guía Completa para DBAs y DBREs

## 🎯 ¿Qué son SLIs y SLOs?

### Definiciones Simples
- **SLI (Service Level Indicator)**: Una métrica específica que mide el rendimiento de tu servicio
- **SLO (Service Level Objective)**: El objetivo o meta que quieres alcanzar para esa métrica

### Analogía del Mundo Real
Imagina que manejas un restaurante:
- **SLI**: "Tiempo promedio para servir una orden" (métrica medible)
- **SLO**: "95% de las órdenes deben servirse en menos de 15 minutos" (objetivo)

## 🔍 SLIs (Service Level Indicators)

### ¿Qué es un SLI?
Un SLI es una **medición cuantitativa** de algún aspecto del nivel de servicio que proporcionas. Debe ser:
- **Medible**: Puedes obtener datos reales
- **Relevante**: Importa a los usuarios finales
- **Específico**: No ambiguo en su definición

### Tipos de SLIs para Bases de Datos

#### 1. **Availability (Disponibilidad)**
```python
# Ejemplo: SLI de disponibilidad de base de datos
def calculate_availability_sli(successful_connections, total_connection_attempts):
    """
    SLI: Porcentaje de conexiones exitosas a la base de datos
    """
    if total_connection_attempts == 0:
        return 100.0
    
    availability = (successful_connections / total_connection_attempts) * 100
    return availability

# Ejemplo de uso
successful = 9950  # conexiones exitosas
total = 10000      # total de intentos de conexión
availability_sli = calculate_availability_sli(successful, total)
print(f"Availability SLI: {availability_sli}%")  # Output: 99.5%
```

#### 2. **Latency (Latencia)**
```python
# Ejemplo: SLI de latencia de queries
def calculate_latency_sli(query_times, threshold_ms=100):
    """
    SLI: Porcentaje de queries que responden bajo el umbral
    """
    fast_queries = sum(1 for time in query_times if time < threshold_ms)
    total_queries = len(query_times)
    
    latency_sli = (fast_queries / total_queries) * 100
    return latency_sli

# Ejemplo de uso
query_times = [45, 67, 89, 120, 34, 156, 78, 91, 43, 234]  # en milisegundos
latency_sli = calculate_latency_sli(query_times, 100)
print(f"Latency SLI: {latency_sli}%")  # Output: 70.0%
```

#### 3. **Throughput (Rendimiento)**
```python
# Ejemplo: SLI de throughput
def calculate_throughput_sli(current_qps, target_qps):
    """
    SLI: Porcentaje de capacidad de throughput utilizada
    """
    throughput_sli = (current_qps / target_qps) * 100
    return min(throughput_sli, 100)  # Cap at 100%

# Ejemplo de uso
current_qps = 850   # queries por segundo actuales
target_qps = 1000   # queries por segundo objetivo
throughput_sli = calculate_throughput_sli(current_qps, target_qps)
print(f"Throughput SLI: {throughput_sli}%")  # Output: 85.0%
```

#### 4. **Data Freshness (Frescura de Datos)**
```python
from datetime import datetime, timedelta

def calculate_data_freshness_sli(last_update_time, max_age_minutes=30):
    """
    SLI: Si los datos están dentro del tiempo máximo permitido
    """
    now = datetime.now()
    age_minutes = (now - last_update_time).total_seconds() / 60
    
    is_fresh = age_minutes <= max_age_minutes
    return 100.0 if is_fresh else 0.0

# Ejemplo de uso
last_update = datetime.now() - timedelta(minutes=25)
freshness_sli = calculate_data_freshness_sli(last_update, 30)
print(f"Data Freshness SLI: {freshness_sli}%")  # Output: 100.0%
```

## 🎯 SLOs (Service Level Objectives)

### ¿Qué es un SLO?
Un SLO es el **objetivo o meta** que estableces para tu SLI. Define qué nivel de servicio prometes proporcionar.

### Características de un Buen SLO
- **Específico**: "99.9% de disponibilidad" no "alta disponibilidad"
- **Medible**: Basado en SLIs que puedes medir
- **Alcanzable**: Realista pero desafiante
- **Relevante**: Importa a los usuarios
- **Temporal**: Tiene un período de medición definido

### Ejemplos de SLOs para Bases de Datos

#### SLO de Disponibilidad
```python
# Definición de SLO de disponibilidad
AVAILABILITY_SLO = {
    'name': 'Database Availability',
    'description': 'Percentage of successful database connections',
    'target': 99.95,  # 99.95% de conexiones exitosas
    'measurement_window': '30d',  # Medido en ventana de 30 días
    'sli_definition': 'successful_connections / total_connection_attempts * 100'
}

def evaluate_availability_slo(current_sli, slo_config):
    """
    Evalúa si el SLI actual cumple con el SLO
    """
    target = slo_config['target']
    
    if current_sli >= target:
        status = 'MEETING'
        buffer = current_sli - target
    else:
        status = 'BREACHING'
        buffer = current_sli - target  # Será negativo
    
    return {
        'status': status,
        'current_sli': current_sli,
        'target_slo': target,
        'buffer': buffer,
        'measurement_window': slo_config['measurement_window']
    }

# Ejemplo de uso
current_availability = 99.97
result = evaluate_availability_slo(current_availability, AVAILABILITY_SLO)
print(f"SLO Status: {result['status']}")  # Output: MEETING
print(f"Buffer: +{result['buffer']:.2f}%")  # Output: +0.02%
```

#### SLO de Latencia
```python
# Definición de SLO de latencia
LATENCY_SLO = {
    'name': 'Query Response Time',
    'description': 'Percentage of queries completing under 100ms',
    'target': 95.0,  # 95% de queries bajo 100ms
    'measurement_window': '7d',
    'threshold_ms': 100
}

def evaluate_latency_slo(query_times, slo_config):
    """
    Evalúa SLO de latencia basado en tiempos de query
    """
    threshold = slo_config['threshold_ms']
    target = slo_config['target']
    
    # Calcular SLI
    fast_queries = sum(1 for time in query_times if time < threshold)
    total_queries = len(query_times)
    current_sli = (fast_queries / total_queries) * 100
    
    # Evaluar contra SLO
    if current_sli >= target:
        status = 'MEETING'
    else:
        status = 'BREACHING'
    
    return {
        'status': status,
        'current_sli': current_sli,
        'target_slo': target,
        'fast_queries': fast_queries,
        'total_queries': total_queries,
        'threshold_ms': threshold
    }

# Ejemplo de uso
query_times = [45, 67, 89, 120, 34, 156, 78, 91, 43, 234]
result = evaluate_latency_slo(query_times, LATENCY_SLO)
print(f"Latency SLO Status: {result['status']}")  # Output: BREACHING
print(f"Current SLI: {result['current_sli']:.1f}%")  # Output: 70.0%
```

## 💰 Error Budgets (Presupuesto de Errores)

### ¿Qué es un Error Budget?
El **Error Budget** es la cantidad de "fallas" que puedes permitirte sin violar tu SLO.

```python
def calculate_error_budget(slo_target, measurement_window_days=30):
    """
    Calcula el error budget basado en el SLO
    """
    # Convertir SLO a decimal (99.9% = 0.999)
    slo_decimal = slo_target / 100
    
    # Error budget = 1 - SLO
    error_budget_percentage = (1 - slo_decimal) * 100
    
    # Calcular en minutos para el período
    total_minutes = measurement_window_days * 24 * 60
    error_budget_minutes = total_minutes * (1 - slo_decimal)
    
    return {
        'error_budget_percentage': error_budget_percentage,
        'error_budget_minutes': error_budget_minutes,
        'measurement_window_days': measurement_window_days,
        'slo_target': slo_target
    }

# Ejemplo: SLO de 99.9% en 30 días
budget = calculate_error_budget(99.9, 30)
print(f"Error Budget: {budget['error_budget_percentage']:.1f}%")  # 0.1%
print(f"Error Budget: {budget['error_budget_minutes']:.1f} minutes")  # 43.2 minutes
```

### Tracking del Error Budget
```python
class ErrorBudgetTracker:
    def __init__(self, slo_config):
        self.slo_config = slo_config
        self.incidents = []
    
    def add_incident(self, duration_minutes, impact_percentage=100):
        """
        Añade un incidente que consume error budget
        """
        incident = {
            'timestamp': datetime.now(),
            'duration_minutes': duration_minutes,
            'impact_percentage': impact_percentage,
            'budget_consumed': duration_minutes * (impact_percentage / 100)
        }
        self.incidents.append(incident)
        return incident
    
    def get_budget_status(self):
        """
        Calcula el estado actual del error budget
        """
        # Calcular budget total
        total_budget = calculate_error_budget(
            self.slo_config['target'], 
            30  # 30 días
        )['error_budget_minutes']
        
        # Calcular budget consumido
        consumed_budget = sum(incident['budget_consumed'] for incident in self.incidents)
        
        # Calcular budget restante
        remaining_budget = total_budget - consumed_budget
        remaining_percentage = (remaining_budget / total_budget) * 100
        
        return {
            'total_budget_minutes': total_budget,
            'consumed_budget_minutes': consumed_budget,
            'remaining_budget_minutes': remaining_budget,
            'remaining_percentage': remaining_percentage,
            'status': 'HEALTHY' if remaining_percentage > 0 else 'EXHAUSTED'
        }

# Ejemplo de uso
tracker = ErrorBudgetTracker({'target': 99.9})

# Simular algunos incidentes
tracker.add_incident(15, 100)  # 15 minutos de downtime completo
tracker.add_incident(30, 50)   # 30 minutos con 50% de impacto

status = tracker.get_budget_status()
print(f"Budget Status: {status['status']}")
print(f"Remaining: {status['remaining_budget_minutes']:.1f} minutes")
```

## 🚨 Alerting Basado en SLOs

### Alertas Inteligentes
En lugar de alertar por métricas técnicas, alerta cuando los SLOs están en riesgo:

```python
class SLOAlerting:
    def __init__(self, slo_config):
        self.slo_config = slo_config
        self.alert_thresholds = {
            'fast_burn': 10,    # 10x burn rate normal
            'medium_burn': 5,   # 5x burn rate normal
            'slow_burn': 2      # 2x burn rate normal
        }
    
    def calculate_burn_rate(self, current_sli, window_hours=1):
        """
        Calcula la tasa de consumo del error budget
        """
        slo_target = self.slo_config['target']
        
        # Error rate actual
        current_error_rate = 100 - current_sli
        
        # Error rate permitido por el SLO
        allowed_error_rate = 100 - slo_target
        
        # Burn rate = error_rate_actual / error_rate_permitido
        if allowed_error_rate == 0:
            return 0
        
        burn_rate = current_error_rate / allowed_error_rate
        return burn_rate
    
    def should_alert(self, current_sli, window_hours=1):
        """
        Determina si debe generar una alerta
        """
        burn_rate = self.calculate_burn_rate(current_sli, window_hours)
        
        alerts = []
        
        if burn_rate >= self.alert_thresholds['fast_burn']:
            alerts.append({
                'severity': 'CRITICAL',
                'message': f'Fast burn rate detected: {burn_rate:.1f}x',
                'action': 'Immediate response required'
            })
        elif burn_rate >= self.alert_thresholds['medium_burn']:
            alerts.append({
                'severity': 'HIGH',
                'message': f'Medium burn rate detected: {burn_rate:.1f}x',
                'action': 'Investigation needed within 1 hour'
            })
        elif burn_rate >= self.alert_thresholds['slow_burn']:
            alerts.append({
                'severity': 'MEDIUM',
                'message': f'Slow burn rate detected: {burn_rate:.1f}x',
                'action': 'Monitor closely'
            })
        
        return alerts

# Ejemplo de uso
alerting = SLOAlerting({'target': 99.9})

# Simular SLI bajo (muchos errores)
current_sli = 95.0  # Solo 95% de éxito
alerts = alerting.should_alert(current_sli)

for alert in alerts:
    print(f"🚨 {alert['severity']}: {alert['message']}")
    print(f"   Action: {alert['action']}")
```

## 📊 Implementación Práctica con Prometheus

### Métricas en Prometheus
```yaml
# prometheus.yml - Configuración para métricas de base de datos
global:
  scrape_interval: 15s

scrape_configs:
  - job_name: 'database-sli'
    static_configs:
      - targets: ['localhost:9090']
    metrics_path: /metrics
    scrape_interval: 30s
```

### Queries PromQL para SLIs
```promql
# SLI de Disponibilidad
# Porcentaje de conexiones exitosas en los últimos 5 minutos
(
  sum(rate(database_connections_successful_total[5m])) /
  sum(rate(database_connections_total[5m]))
) * 100

# SLI de Latencia
# Porcentaje de queries bajo 100ms en los últimos 5 minutos
(
  sum(rate(database_query_duration_bucket{le="0.1"}[5m])) /
  sum(rate(database_query_duration_count[5m]))
) * 100

# Error Budget Burn Rate
# Tasa de consumo del error budget
(
  (100 - sli_availability) / (100 - 99.9)
)
```

### Alertas en Prometheus
```yaml
# alerts.yml - Reglas de alerta basadas en SLOs
groups:
  - name: database_slo_alerts
    rules:
      - alert: DatabaseAvailabilitySLOBreach
        expr: |
          (
            sum(rate(database_connections_successful_total[5m])) /
            sum(rate(database_connections_total[5m]))
          ) * 100 < 99.9
        for: 2m
        labels:
          severity: critical
          slo: availability
        annotations:
          summary: "Database availability SLO breach"
          description: "Database availability is {{ $value }}%, below SLO of 99.9%"
      
      - alert: DatabaseLatencySLOBreach
        expr: |
          (
            sum(rate(database_query_duration_bucket{le="0.1"}[5m])) /
            sum(rate(database_query_duration_count[5m]))
          ) * 100 < 95
        for: 5m
        labels:
          severity: warning
          slo: latency
        annotations:
          summary: "Database latency SLO breach"
          description: "Only {{ $value }}% of queries complete under 100ms, below SLO of 95%"
```

## 🎯 Mejores Prácticas para SLIs/SLOs

### 1. **Empieza Simple**
```python
# ❌ No hagas esto al principio
complex_sli = {
    'availability': 99.99,
    'latency_p50': 50,
    'latency_p95': 100,
    'latency_p99': 200,
    'throughput_min': 1000,
    'error_rate_max': 0.01
}

# ✅ Empieza con esto
simple_sli = {
    'availability': 99.9,  # Una métrica simple y clara
}
```

### 2. **Mide lo que Importa al Usuario**
```python
# ❌ Métricas técnicas que no importan al usuario
technical_metrics = {
    'cpu_usage': 80,
    'memory_usage': 70,
    'disk_io': 1000
}

# ✅ Métricas centradas en el usuario
user_centric_metrics = {
    'query_success_rate': 99.9,    # ¿Las queries funcionan?
    'query_response_time': 100,    # ¿Son rápidas?
    'data_freshness': 300          # ¿Los datos están actualizados?
}
```

### 3. **SLOs Realistas**
```python
def validate_slo_target(historical_performance, proposed_slo):
    """
    Valida que el SLO propuesto sea realista
    """
    # El SLO debe ser alcanzable pero desafiante
    # Regla general: SLO = historical_performance - buffer
    
    buffer = 0.1  # 0.1% de buffer
    realistic_slo = historical_performance - buffer
    
    if proposed_slo > realistic_slo:
        return {
            'valid': False,
            'message': f'SLO too aggressive. Historical: {historical_performance}%, Proposed: {proposed_slo}%',
            'suggested': realistic_slo
        }
    
    return {'valid': True, 'message': 'SLO is realistic'}

# Ejemplo
historical = 99.95  # Performance histórico
proposed = 99.99    # SLO propuesto
validation = validate_slo_target(historical, proposed)
print(validation['message'])
```

## 🚀 Implementación Paso a Paso

### Semana 1: Identificar SLIs
1. Lista todas las métricas que mides actualmente
2. Identifica cuáles importan a los usuarios
3. Define 1-2 SLIs simples

### Semana 2: Establecer SLOs
1. Analiza performance histórico
2. Define SLOs realistas
3. Calcula error budgets

### Semana 3: Implementar Medición
1. Configura métricas en Prometheus
2. Crea dashboards en Grafana
3. Implementa cálculo de SLIs

### Semana 4: Alerting
1. Configura alertas basadas en SLOs
2. Define runbooks para respuesta
3. Prueba el sistema de alertas

## 📈 Ejemplo Completo: E-commerce Database

```python
class EcommerceDatabaseSLOs:
    def __init__(self):
        self.slos = {
            'user_queries': {
                'availability': 99.95,  # 99.95% de queries exitosas
                'latency': 95.0,        # 95% bajo 100ms
                'description': 'User-facing product queries'
            },
            'order_processing': {
                'availability': 99.99,  # 99.99% de órdenes procesadas
                'latency': 99.0,        # 99% bajo 500ms
                'description': 'Order creation and updates'
            },
            'reporting': {
                'availability': 99.0,   # 99% de reportes exitosos
                'latency': 90.0,        # 90% bajo 2 segundos
                'description': 'Business intelligence queries'
            }
        }
    
    def get_slo_for_query_type(self, query_type):
        """
        Retorna el SLO apropiado basado en el tipo de query
        """
        if 'SELECT' in query_type.upper() and 'product' in query_type.lower():
            return self.slos['user_queries']
        elif 'INSERT' in query_type.upper() and 'order' in query_type.lower():
            return self.slos['order_processing']
        elif 'report' in query_type.lower():
            return self.slos['reporting']
        else:
            return self.slos['user_queries']  # Default
```

---

## 🎯 Resumen Clave

### SLIs (Service Level Indicators)
- **Qué medir**: Métricas específicas y medibles
- **Centrado en usuario**: Lo que importa a quien usa el servicio
- **Ejemplos**: % de conexiones exitosas, % de queries bajo 100ms

### SLOs (Service Level Objectives)
- **Qué lograr**: Objetivos específicos para tus SLIs
- **Realistas**: Basados en performance histórico
- **Ejemplos**: 99.9% disponibilidad, 95% de queries bajo 100ms

### Error Budgets
- **Cuánto puedes fallar**: Sin violar tus SLOs
- **Herramienta de balance**: Entre confiabilidad y velocidad de desarrollo
- **Ejemplo**: SLO 99.9% = 43.2 minutos de downtime permitido por mes

**La clave está en empezar simple, medir lo que importa al usuario, y iterar basándose en datos reales.**

¿Te gustaría que profundice en algún aspecto específico o que creemos ejemplos para tu caso de uso particular?
