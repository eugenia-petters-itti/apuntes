# Lab 06: Monitoreo con PMM (Percona Monitoring and Management)

## Objetivo
Configurar monitoreo completo para todos los operadores de Percona usando PMM.

## Duración Estimada
45 minutos

## Conceptos Clave
- **PMM Server**: Servidor central de monitoreo
- **PMM Client**: Agente que recolecta métricas
- **Grafana**: Dashboards de visualización
- **Prometheus**: Sistema de métricas
- **QAN**: Query Analytics para análisis de consultas

## Pasos

### 1. Desplegar PMM Server

```bash
kubectl apply -f pmm-server.yaml
```

### 2. Configurar acceso a PMM

```bash
# Port-forward para acceder a PMM
kubectl port-forward svc/pmm-server 8080:80

# Acceder a http://localhost:8080
# Usuario: admin, Password: admin (cambiar en primer acceso)
```

### 3. Habilitar PMM en MySQL PXC

```bash
# Actualizar cluster PXC para habilitar PMM
kubectl patch pxc pxc-cluster --type='merge' -p='{"spec":{"pmm":{"enabled":true,"serverHost":"pmm-server"}}}'
```

### 4. Habilitar PMM en MongoDB

```bash
# Actualizar cluster PSMDB para habilitar PMM
kubectl patch psmdb psmdb-cluster --type='merge' -p='{"spec":{"pmm":{"enabled":true,"serverHost":"pmm-server"}}}'
```

### 5. Configurar PMM para PostgreSQL

```bash
kubectl apply -f pmm-postgresql.yaml
```

### 6. Verificar métricas

```bash
# Ver pods de PMM client
kubectl get pods -l app.kubernetes.io/name=pmm-client

# Ver logs de PMM client
kubectl logs -l app.kubernetes.io/name=pmm-client
```

## Dashboards Disponibles

### MySQL Dashboards
- MySQL Overview
- MySQL InnoDB Details
- MySQL Query Response Time Details
- MySQL Replication Summary
- PXC/Galera Cluster Summary

### MongoDB Dashboards
- MongoDB Overview
- MongoDB Cluster Summary
- MongoDB ReplSet Summary
- MongoDB InMemory Details
- MongoDB WiredTiger Details

### PostgreSQL Dashboards
- PostgreSQL Overview
- PostgreSQL Instance Summary
- PostgreSQL Instance Compare
- PostgreSQL Vacuum Monitoring

### System Dashboards
- Node Summary
- Disk Details
- Network Details
- Memory Details
- CPU Utilization Details

## Configuración de Alertas

### 1. Crear reglas de alerta

```bash
kubectl apply -f alert-rules.yaml
```

### 2. Configurar notificaciones

```bash
# Acceder a PMM UI -> Alerting -> Notification channels
# Configurar Slack, email, webhook, etc.
```

## Análisis de Consultas (QAN)

### MySQL QAN
1. Acceder a PMM UI -> Query Analytics
2. Seleccionar servicio MySQL
3. Analizar consultas lentas y frecuentes
4. Optimizar consultas problemáticas

### MongoDB QAN
1. Habilitar profiling en MongoDB:
```javascript
db.setProfilingLevel(2, { slowms: 100 })
```
2. Ver análisis en PMM UI -> Query Analytics

### PostgreSQL QAN
1. Configurar pg_stat_statements
2. Ver análisis en PMM UI -> Query Analytics

## Métricas Personalizadas

### 1. Crear ServiceMonitor para métricas custom

```bash
kubectl apply -f custom-metrics.yaml
```

### 2. Crear dashboard personalizado

```bash
# Importar dashboard desde pmm-dashboards/custom-dashboard.json
```

## Troubleshooting

### PMM Client no se conecta
```bash
# Verificar conectividad
kubectl exec -it <pmm-client-pod> -- pmm-admin list

# Verificar configuración
kubectl exec -it <pmm-client-pod> -- pmm-admin status
```

### Métricas no aparecen
```bash
# Verificar targets en Prometheus
# PMM UI -> Settings -> Prometheus Targets

# Verificar logs
kubectl logs <pmm-client-pod>
```

### Dashboard no carga datos
```bash
# Verificar data source en Grafana
# PMM UI -> Settings -> Data Sources

# Verificar queries en dashboard
```

## Mejores Prácticas

1. **Retención de Datos**
   - Métricas: 30 días por defecto
   - QAN: 8 días por defecto
   - Ajustar según necesidades

2. **Recursos**
   - PMM Server: Mínimo 2GB RAM, 4GB recomendado
   - PMM Client: 100-200MB RAM por servicio

3. **Seguridad**
   - Cambiar contraseña por defecto
   - Configurar HTTPS
   - Restringir acceso de red

4. **Alertas**
   - Configurar alertas críticas
   - Evitar alert fatigue
   - Documentar runbooks

## Verificación

Al finalizar este laboratorio deberías tener:
- ✅ PMM Server desplegado y accesible
- ✅ PMM Client configurado en todos los clusters
- ✅ Dashboards mostrando métricas
- ✅ QAN funcionando para análisis de consultas
- ✅ Alertas configuradas

## Siguiente Paso
Continuar con `lab-07-scaling` para aprender sobre escalado.
