# Roadmap DBA Kubernetes - Parte 1: Fundamentos
## Labs Prácticos para Alta Disponibilidad de Bases de Datos

### Fase 1: Fundamentos de Kubernetes (4-6 semanas)

#### Semana 1-2: Setup del Entorno

##### Lab 1.1: Instalación de Kubernetes Local
**Objetivo**: Configurar entorno de desarrollo local

**Herramientas necesarias**:
- Docker Desktop
- kubectl
- Helm
- k3d o minikube

**Pasos del Lab**:
```bash
# Instalar k3d
curl -s https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash

# Crear cluster local
k3d cluster create db-lab --agents 3 --port "8080:80@loadbalancer"

# Verificar instalación
kubectl cluster-info
kubectl get nodes
```

**Entregables**:
- [ ] Cluster Kubernetes funcionando
- [ ] kubectl configurado
- [ ] Helm instalado
- [ ] Dashboard de Kubernetes accesible

##### Lab 1.2: Setup de EKS en AWS
**Objetivo**: Crear cluster EKS para labs avanzados

**Prerequisitos**:
- AWS CLI configurado
- eksctl instalado
- Terraform (opcional)

**Pasos del Lab**:
```bash
# Crear cluster EKS
eksctl create cluster \
  --name dba-lab-cluster \
  --region us-east-1 \
  --nodegroup-name workers \
  --node-type t3.medium \
  --nodes 3 \
  --nodes-min 1 \
  --nodes-max 4 \
  --managed

# Configurar kubectl
aws eks update-kubeconfig --region us-east-1 --name dba-lab-cluster
```

**Entregables**:
- [ ] Cluster EKS funcionando
- [ ] Node groups configurados
- [ ] Acceso desde kubectl
- [ ] IAM roles configurados

#### Semana 3-4: Conceptos Básicos de Kubernetes

##### Lab 1.3: Pods, Services y ConfigMaps
**Objetivo**: Entender objetos básicos de Kubernetes

**Ejercicio Práctico**:
```yaml
# pod-mysql-basic.yaml
apiVersion: v1
kind: Pod
metadata:
  name: mysql-basic
  labels:
    app: mysql
spec:
  containers:
  - name: mysql
    image: mysql:8.0
    env:
    - name: MYSQL_ROOT_PASSWORD
      value: "rootpassword"
    - name: MYSQL_DATABASE
      value: "testdb"
    ports:
    - containerPort: 3306
    volumeMounts:
    - name: mysql-storage
      mountPath: /var/lib/mysql
  volumes:
  - name: mysql-storage
    emptyDir: {}
```

**Tareas**:
- [ ] Crear pod MySQL básico
- [ ] Exponer con Service
- [ ] Crear ConfigMap para configuración
- [ ] Conectarse desde otro pod
- [ ] Verificar logs y métricas

##### Lab 1.4: Persistent Volumes y Storage Classes
**Objetivo**: Gestión de almacenamiento persistente

**Ejercicio Práctico**:
```yaml
# storageclass-gp3.yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: gp3-encrypted
provisioner: ebs.csi.aws.com
parameters:
  type: gp3
  iops: "3000"
  throughput: "125"
  encrypted: "true"
volumeBindingMode: WaitForFirstConsumer
allowVolumeExpansion: true
```

**Tareas**:
- [ ] Crear StorageClass optimizada
- [ ] Crear PersistentVolumeClaim
- [ ] Montar volumen en pod MySQL
- [ ] Verificar persistencia de datos
- [ ] Probar expansión de volumen

### Fase 2: Bases de Datos Básicas en Kubernetes (4-6 semanas)

#### Semana 5-6: MySQL Standalone

##### Lab 2.1: MySQL con Helm Chart
**Objetivo**: Desplegar MySQL usando Helm

**Pasos del Lab**:
```bash
# Agregar repositorio Bitnami
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update

# Crear values personalizados
cat > mysql-values.yaml << EOF
auth:
  rootPassword: "supersecret"
  database: "myapp"
  username: "myuser"
  password: "mypassword"

primary:
  persistence:
    enabled: true
    storageClass: "gp3-encrypted"
    size: 20Gi
  
  resources:
    requests:
      memory: 1Gi
      cpu: 500m
    limits:
      memory: 2Gi
      cpu: 1

metrics:
  enabled: true
  serviceMonitor:
    enabled: true
EOF

# Instalar MySQL
helm install mysql bitnami/mysql -f mysql-values.yaml
```

**Tareas**:
- [ ] Desplegar MySQL con Helm
- [ ] Configurar recursos y límites
- [ ] Habilitar métricas
- [ ] Crear base de datos de prueba
- [ ] Configurar backup básico

##### Lab 2.2: PostgreSQL con Helm Chart
**Objetivo**: Desplegar PostgreSQL usando Helm

**Pasos del Lab**:
```bash
# Crear values para PostgreSQL
cat > postgres-values.yaml << EOF
auth:
  postgresPassword: "supersecret"
  database: "myapp"
  username: "myuser"
  password: "mypassword"

primary:
  persistence:
    enabled: true
    storageClass: "gp3-encrypted"
    size: 20Gi
  
  resources:
    requests:
      memory: 1Gi
      cpu: 500m

metrics:
  enabled: true
  serviceMonitor:
    enabled: true

postgresql:
  maxConnections: 200
  sharedBuffers: 256MB
EOF

# Instalar PostgreSQL
helm install postgres bitnami/postgresql -f postgres-values.yaml
```

**Tareas**:
- [ ] Desplegar PostgreSQL con Helm
- [ ] Configurar parámetros de PostgreSQL
- [ ] Habilitar métricas con Prometheus
- [ ] Crear esquemas de prueba
- [ ] Configurar conexión externa

#### Semana 7-8: Monitoreo y Observabilidad

##### Lab 2.3: Prometheus y Grafana
**Objetivo**: Implementar stack de monitoreo

**Pasos del Lab**:
```bash
# Instalar Prometheus Operator
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm install prometheus prometheus-community/kube-prometheus-stack \
  --set grafana.adminPassword=admin123 \
  --set prometheus.prometheusSpec.serviceMonitorSelectorNilUsesHelmValues=false
```

**Tareas**:
- [ ] Instalar Prometheus y Grafana
- [ ] Configurar ServiceMonitors para MySQL/PostgreSQL
- [ ] Crear dashboards personalizados
- [ ] Configurar alertas básicas
- [ ] Monitorear métricas de base de datos

##### Lab 2.4: Logging con ELK Stack
**Objetivo**: Centralizar logs de bases de datos

**Pasos del Lab**:
```bash
# Instalar Elastic Stack
helm repo add elastic https://helm.elastic.co
helm install elasticsearch elastic/elasticsearch
helm install kibana elastic/kibana
helm install filebeat elastic/filebeat
```

**Tareas**:
- [ ] Desplegar Elasticsearch y Kibana
- [ ] Configurar Filebeat para logs de MySQL/PostgreSQL
- [ ] Crear índices y patrones
- [ ] Configurar dashboards en Kibana
- [ ] Alertas basadas en logs

### Evaluación Fase 1-2

#### Proyecto Integrador: "Database Monitoring Stack"
**Objetivo**: Crear stack completo de monitoreo para bases de datos

**Requisitos**:
1. MySQL y PostgreSQL desplegados con Helm
2. Prometheus y Grafana configurados
3. Dashboards personalizados para cada DB
4. Alertas configuradas para:
   - CPU/Memory usage > 80%
   - Disk space < 20%
   - Connection count > threshold
   - Slow queries detected
5. Logs centralizados en Elasticsearch
6. Documentación completa del setup

**Criterios de Evaluación**:
- [ ] Todas las bases de datos funcionando
- [ ] Métricas visibles en Grafana
- [ ] Alertas funcionando correctamente
- [ ] Logs centralizados y consultables
- [ ] Documentación clara y completa
- [ ] Código versionado en Git

**Tiempo Estimado**: 2 semanas

### Recursos Adicionales

#### Documentación Recomendada
- [Kubernetes Official Documentation](https://kubernetes.io/docs/)
- [Helm Documentation](https://helm.sh/docs/)
- [Bitnami Charts](https://github.com/bitnami/charts)
- [Prometheus Operator](https://prometheus-operator.dev/)

#### Herramientas Útiles
- **k9s**: Terminal UI para Kubernetes
- **kubectx/kubens**: Cambio rápido de contextos
- **stern**: Logs agregados de múltiples pods
- **kubectl-tree**: Visualizar recursos relacionados

#### Comandos Útiles
```bash
# Ver recursos de base de datos
kubectl get pods -l app=mysql
kubectl describe pod mysql-0

# Logs en tiempo real
kubectl logs -f mysql-0

# Port forwarding para acceso local
kubectl port-forward svc/mysql 3306:3306

# Ejecutar comandos en pod
kubectl exec -it mysql-0 -- mysql -u root -p

# Ver métricas de recursos
kubectl top pods
kubectl top nodes
```

### Próximos Pasos
Una vez completada esta fase, estarás listo para:
- Alta disponibilidad con operadores especializados
- Clustering avanzado de MySQL y PostgreSQL
- Backup y disaster recovery
- Automatización con GitOps
- Performance tuning avanzado

**Tiempo Total Estimado Fase 1-2**: 8-12 semanas
**Prerequisitos**: Conocimientos básicos de Docker y bases de datos
**Nivel de Dificultad**: Intermedio
