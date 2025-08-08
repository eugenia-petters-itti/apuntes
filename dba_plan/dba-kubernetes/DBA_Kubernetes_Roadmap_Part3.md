# Roadmap DBA Kubernetes - Parte 3: Automatización y GitOps
## Labs de Automatización, Performance y Producción

### Fase 6: GitOps y Automatización (4-6 semanas)

#### Semana 19-20: ArgoCD y GitOps

##### Lab 6.1: Implementación de GitOps con ArgoCD
**Objetivo**: Automatizar deployments de bases de datos con GitOps

**Instalación de ArgoCD**:
```bash
# Crear namespace
kubectl create namespace argocd

# Instalar ArgoCD
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Exponer ArgoCD UI
kubectl patch svc argocd-server -n argocd -p '{"spec": {"type": "LoadBalancer"}}'

# Obtener password inicial
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
```

**Estructura de Repositorio GitOps**:
```
database-gitops/
├── environments/
│   ├── dev/
│   │   ├── postgres/
│   │   │   ├── kustomization.yaml
│   │   │   └── postgres-cluster.yaml
│   │   └── mysql/
│   │       ├── kustomization.yaml
│   │       └── mysql-cluster.yaml
│   ├── staging/
│   └── production/
├── base/
│   ├── postgres/
│   │   ├── kustomization.yaml
│   │   ├── cluster.yaml
│   │   └── monitoring.yaml
│   └── mysql/
│       ├── kustomization.yaml
│       ├── cluster.yaml
│       └── monitoring.yaml
└── applications/
    ├── postgres-dev.yaml
    ├── postgres-staging.yaml
    └── postgres-production.yaml
```

**Application Definition**:
```yaml
# applications/postgres-production.yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: postgres-production
  namespace: argocd
spec:
  project: database-platform
  source:
    repoURL: https://github.com/company/database-gitops
    targetRevision: main
    path: environments/production/postgres
  destination:
    server: https://kubernetes.default.svc
    namespace: database-production
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
    - CreateNamespace=true
```

**Tareas**:
- [ ] Instalar y configurar ArgoCD
- [ ] Crear repositorio GitOps
- [ ] Configurar applications para cada entorno
- [ ] Implementar sync policies
- [ ] Probar rollback automático

##### Lab 6.2: Kustomize para Configuración
**Objetivo**: Gestionar configuraciones multi-entorno

**Base Configuration**:
```yaml
# base/postgres/kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

resources:
- cluster.yaml
- monitoring.yaml
- backup.yaml

commonLabels:
  app.kubernetes.io/name: postgres
  app.kubernetes.io/component: database
```

**Environment Overlay**:
```yaml
# environments/production/postgres/kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

namespace: database-production

resources:
- ../../../base/postgres

patchesStrategicMerge:
- postgres-cluster.yaml

images:
- name: postgres
  newTag: "15.4"

replicas:
- name: postgres-cluster
  count: 3
```

**Tareas**:
- [ ] Crear base configurations
- [ ] Implementar overlays por entorno
- [ ] Configurar patches específicos
- [ ] Validar con kustomize build
- [ ] Integrar con ArgoCD

#### Semana 21-22: Terraform y Infrastructure as Code

##### Lab 6.3: Terraform para AWS Resources
**Objetivo**: Automatizar infraestructura AWS para bases de datos

**Terraform Configuration**:
```hcl
# main.tf
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0"
    }
  }
}

# EKS Cluster
module "eks" {
  source = "terraform-aws-modules/eks/aws"
  
  cluster_name    = var.cluster_name
  cluster_version = "1.28"
  
  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets
  
  node_groups = {
    database_nodes = {
      desired_capacity = 3
      max_capacity     = 6
      min_capacity     = 3
      
      instance_types = ["m5.xlarge"]
      
      k8s_labels = {
        workload = "database"
      }
      
      taints = [
        {
          key    = "database"
          value  = "true"
          effect = "NO_SCHEDULE"
        }
      ]
    }
  }
}

# Storage Classes
resource "kubernetes_storage_class" "gp3_encrypted" {
  metadata {
    name = "gp3-encrypted"
  }
  
  storage_provisioner    = "ebs.csi.aws.com"
  reclaim_policy        = "Retain"
  volume_binding_mode   = "WaitForFirstConsumer"
  allow_volume_expansion = true
  
  parameters = {
    type       = "gp3"
    iops       = "3000"
    throughput = "125"
    encrypted  = "true"
  }
}

# S3 Buckets for Backups
resource "aws_s3_bucket" "database_backups" {
  bucket = "${var.cluster_name}-database-backups"
}

resource "aws_s3_bucket_versioning" "database_backups" {
  bucket = aws_s3_bucket.database_backups.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_encryption" "database_backups" {
  bucket = aws_s3_bucket.database_backups.id
  
  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }
}
```

**Tareas**:
- [ ] Crear módulos Terraform para EKS
- [ ] Configurar storage classes optimizadas
- [ ] Crear buckets S3 para backups
- [ ] Implementar IAM roles y policies
- [ ] Configurar remote state

##### Lab 6.4: Ansible para Configuración
**Objetivo**: Automatizar configuración post-deployment

**Ansible Playbook**:
```yaml
# playbooks/database-setup.yml
---
- name: Configure Database Platform
  hosts: localhost
  connection: local
  vars:
    kubeconfig: "{{ ansible_env.HOME }}/.kube/config"
    
  tasks:
  - name: Install database operators
    kubernetes.core.k8s:
      state: present
      definition:
        apiVersion: v1
        kind: Namespace
        metadata:
          name: "{{ item }}"
    loop:
      - cnpg-system
      - pxc-operator
      - mysql-operator
  
  - name: Deploy CloudNativePG operator
    kubernetes.core.k8s:
      state: present
      src: "{{ playbook_dir }}/manifests/cnpg-operator.yaml"
  
  - name: Deploy Percona operator
    kubernetes.core.k8s:
      state: present
      src: "{{ playbook_dir }}/manifests/pxc-operator.yaml"
  
  - name: Configure monitoring stack
    kubernetes.core.helm:
      name: prometheus
      chart_ref: prometheus-community/kube-prometheus-stack
      release_namespace: monitoring
      create_namespace: true
      values:
        grafana:
          adminPassword: "{{ grafana_admin_password }}"
        prometheus:
          prometheusSpec:
            serviceMonitorSelectorNilUsesHelmValues: false
```

**Tareas**:
- [ ] Crear playbooks para setup inicial
- [ ] Automatizar instalación de operadores
- [ ] Configurar monitoring stack
- [ ] Implementar health checks
- [ ] Integrar con CI/CD pipeline

### Fase 7: Performance Tuning y Optimización (4-6 semanas)

#### Semana 23-24: Performance Monitoring Avanzado

##### Lab 7.1: Custom Metrics y Dashboards
**Objetivo**: Implementar monitoreo avanzado de performance

**Custom ServiceMonitor**:
```yaml
# postgres-servicemonitor.yaml
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: postgres-metrics
  labels:
    app: postgres
spec:
  selector:
    matchLabels:
      cnpg.io/cluster: postgres-cluster
  endpoints:
  - port: metrics
    interval: 30s
    path: /metrics
```

**Grafana Dashboard JSON**:
```json
{
  "dashboard": {
    "title": "PostgreSQL Performance Dashboard",
    "panels": [
      {
        "title": "Connection Count",
        "type": "stat",
        "targets": [
          {
            "expr": "pg_stat_database_numbackends{datname!=\"template0\",datname!=\"template1\",datname!=\"postgres\"}"
          }
        ]
      },
      {
        "title": "Query Performance",
        "type": "graph",
        "targets": [
          {
            "expr": "rate(pg_stat_database_tup_returned[5m])"
          }
        ]
      },
      {
        "title": "Buffer Hit Ratio",
        "type": "stat",
        "targets": [
          {
            "expr": "pg_stat_database_blks_hit / (pg_stat_database_blks_hit + pg_stat_database_blks_read) * 100"
          }
        ]
      }
    ]
  }
}
```

**PrometheusRule para Alertas**:
```yaml
# postgres-alerts.yaml
apiVersion: monitoring.coreos.com/v1
kind: PrometheusRule
metadata:
  name: postgres-alerts
spec:
  groups:
  - name: postgres.rules
    rules:
    - alert: PostgreSQLDown
      expr: pg_up == 0
      for: 5m
      labels:
        severity: critical
      annotations:
        summary: "PostgreSQL instance is down"
        
    - alert: PostgreSQLHighConnections
      expr: pg_stat_database_numbackends / pg_settings_max_connections * 100 > 80
      for: 5m
      labels:
        severity: warning
      annotations:
        summary: "PostgreSQL connection usage is high"
        
    - alert: PostgreSQLSlowQueries
      expr: rate(pg_stat_database_tup_returned[5m]) < 100
      for: 10m
      labels:
        severity: warning
      annotations:
        summary: "PostgreSQL queries are running slowly"
```

**Tareas**:
- [ ] Crear ServiceMonitors personalizados
- [ ] Desarrollar dashboards específicos
- [ ] Configurar alertas avanzadas
- [ ] Implementar SLI/SLO monitoring
- [ ] Crear reportes automatizados

##### Lab 7.2: APM Integration
**Objetivo**: Integrar Application Performance Monitoring

**Jaeger Tracing**:
```yaml
# jaeger-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: jaeger
spec:
  replicas: 1
  selector:
    matchLabels:
      app: jaeger
  template:
    metadata:
      labels:
        app: jaeger
    spec:
      containers:
      - name: jaeger
        image: jaegertracing/all-in-one:1.47
        ports:
        - containerPort: 16686
        - containerPort: 14268
        env:
        - name: COLLECTOR_OTLP_ENABLED
          value: "true"
```

**Database Connection Tracing**:
```python
# app-tracing-example.py
import psycopg2
from opentelemetry import trace
from opentelemetry.instrumentation.psycopg2 import Psycopg2Instrumentor

# Initialize tracing
Psycopg2Instrumentor().instrument()

tracer = trace.get_tracer(__name__)

def database_operation():
    with tracer.start_as_current_span("database_query") as span:
        conn = psycopg2.connect(
            host="postgres-cluster-rw",
            database="myapp",
            user="myuser",
            password="mypassword"
        )
        
        span.set_attribute("db.system", "postgresql")
        span.set_attribute("db.name", "myapp")
        
        cursor = conn.cursor()
        cursor.execute("SELECT COUNT(*) FROM users")
        result = cursor.fetchone()
        
        span.set_attribute("db.rows_affected", result[0])
        
        cursor.close()
        conn.close()
        
        return result
```

**Tareas**:
- [ ] Instalar Jaeger para tracing
- [ ] Instrumentar aplicaciones
- [ ] Configurar database tracing
- [ ] Analizar query performance
- [ ] Crear alertas basadas en traces

#### Semana 25-26: Capacity Planning y Auto-scaling

##### Lab 7.3: Vertical Pod Autoscaler (VPA)
**Objetivo**: Implementar auto-scaling vertical

**VPA Configuration**:
```yaml
# postgres-vpa.yaml
apiVersion: autoscaling.k8s.io/v1
kind: VerticalPodAutoscaler
metadata:
  name: postgres-vpa
spec:
  targetRef:
    apiVersion: postgresql.cnpg.io/v1
    kind: Cluster
    name: postgres-cluster
  updatePolicy:
    updateMode: "Auto"
  resourcePolicy:
    containerPolicies:
    - containerName: postgres
      minAllowed:
        cpu: 500m
        memory: 1Gi
      maxAllowed:
        cpu: 4
        memory: 8Gi
      controlledResources: ["cpu", "memory"]
```

**HPA para Read Replicas**:
```yaml
# postgres-hpa.yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: postgres-read-replicas-hpa
spec:
  scaleTargetRef:
    apiVersion: postgresql.cnpg.io/v1
    kind: Cluster
    name: postgres-cluster
  minReplicas: 1
  maxReplicas: 5
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70
  - type: Pods
    pods:
      metric:
        name: postgres_connections_active
      target:
        type: AverageValue
        averageValue: "50"
```

**Tareas**:
- [ ] Configurar VPA para databases
- [ ] Implementar HPA para read replicas
- [ ] Crear métricas custom para scaling
- [ ] Probar scaling bajo carga
- [ ] Documentar scaling policies

##### Lab 7.4: Cluster Autoscaler
**Objetivo**: Auto-scaling de nodos del cluster

**Cluster Autoscaler Deployment**:
```yaml
# cluster-autoscaler.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: cluster-autoscaler
  namespace: kube-system
spec:
  replicas: 1
  selector:
    matchLabels:
      app: cluster-autoscaler
  template:
    metadata:
      labels:
        app: cluster-autoscaler
    spec:
      serviceAccountName: cluster-autoscaler
      containers:
      - image: k8s.gcr.io/autoscaling/cluster-autoscaler:v1.28.0
        name: cluster-autoscaler
        resources:
          limits:
            cpu: 100m
            memory: 300Mi
          requests:
            cpu: 100m
            memory: 300Mi
        command:
        - ./cluster-autoscaler
        - --v=4
        - --stderrthreshold=info
        - --cloud-provider=aws
        - --skip-nodes-with-local-storage=false
        - --expander=least-waste
        - --node-group-auto-discovery=asg:tag=k8s.io/cluster-autoscaler/enabled,k8s.io/cluster-autoscaler/database-cluster
        - --balance-similar-node-groups
        - --skip-nodes-with-system-pods=false
```

**Node Group Configuration**:
```hcl
# terraform/node-groups.tf
resource "aws_eks_node_group" "database_nodes" {
  cluster_name    = aws_eks_cluster.database_cluster.name
  node_group_name = "database-nodes"
  node_role_arn   = aws_iam_role.node_group.arn
  subnet_ids      = var.private_subnet_ids
  
  instance_types = ["m5.xlarge", "m5.2xlarge"]
  
  scaling_config {
    desired_size = 3
    max_size     = 10
    min_size     = 3
  }
  
  tags = {
    "k8s.io/cluster-autoscaler/enabled" = "true"
    "k8s.io/cluster-autoscaler/database-cluster" = "owned"
  }
  
  taint {
    key    = "database"
    value  = "true"
    effect = "NO_SCHEDULE"
  }
}
```

**Tareas**:
- [ ] Configurar Cluster Autoscaler
- [ ] Crear node groups específicos para DB
- [ ] Configurar taints y tolerations
- [ ] Probar scaling de nodos
- [ ] Optimizar costos con Spot instances

### Fase 8: Seguridad y Compliance (4-6 semanas)

#### Semana 27-28: Seguridad Avanzada

##### Lab 8.1: Network Policies y Segmentación
**Objetivo**: Implementar seguridad de red granular

**Network Policy para PostgreSQL**:
```yaml
# postgres-network-policy.yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: postgres-network-policy
  namespace: database-production
spec:
  podSelector:
    matchLabels:
      cnpg.io/cluster: postgres-cluster
  policyTypes:
  - Ingress
  - Egress
  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          name: application-production
    - podSelector:
        matchLabels:
          app: web-app
    ports:
    - protocol: TCP
      port: 5432
  egress:
  - to: []
    ports:
    - protocol: TCP
      port: 53
    - protocol: UDP
      port: 53
  - to:
    - namespaceSelector:
        matchLabels:
          name: monitoring
    ports:
    - protocol: TCP
      port: 9090
```

**Pod Security Standards**:
```yaml
# pod-security-policy.yaml
apiVersion: v1
kind: Namespace
metadata:
  name: database-production
  labels:
    pod-security.kubernetes.io/enforce: restricted
    pod-security.kubernetes.io/audit: restricted
    pod-security.kubernetes.io/warn: restricted
```

**Tareas**:
- [ ] Implementar Network Policies
- [ ] Configurar Pod Security Standards
- [ ] Crear security contexts restrictivos
- [ ] Implementar service mesh (Istio)
- [ ] Configurar mTLS entre servicios

##### Lab 8.2: Secrets Management
**Objetivo**: Gestión segura de credenciales

**External Secrets Operator**:
```yaml
# external-secrets-operator.yaml
apiVersion: external-secrets.io/v1beta1
kind: SecretStore
metadata:
  name: aws-secrets-manager
  namespace: database-production
spec:
  provider:
    aws:
      service: SecretsManager
      region: us-east-1
      auth:
        jwt:
          serviceAccountRef:
            name: external-secrets-sa
---
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: postgres-credentials
  namespace: database-production
spec:
  refreshInterval: 1h
  secretStoreRef:
    name: aws-secrets-manager
    kind: SecretStore
  target:
    name: postgres-secret
    creationPolicy: Owner
  data:
  - secretKey: username
    remoteRef:
      key: postgres-credentials
      property: username
  - secretKey: password
    remoteRef:
      key: postgres-credentials
      property: password
```

**Sealed Secrets**:
```yaml
# sealed-secret.yaml
apiVersion: bitnami.com/v1alpha1
kind: SealedSecret
metadata:
  name: postgres-sealed-secret
  namespace: database-production
spec:
  encryptedData:
    username: AgBy3i4OJSWK+PiTySYZZA9rO43cGDEQAx...
    password: AgBy3i4OJSWK+PiTySYZZA9rO43cGDEQAx...
  template:
    metadata:
      name: postgres-secret
      namespace: database-production
    type: Opaque
```

**Tareas**:
- [ ] Instalar External Secrets Operator
- [ ] Configurar AWS Secrets Manager
- [ ] Implementar Sealed Secrets
- [ ] Configurar automatic secret rotation
- [ ] Integrar con HashiCorp Vault

#### Semana 29-30: Compliance y Auditing

##### Lab 8.3: Compliance Scanning
**Objetivo**: Implementar scanning de seguridad

**Falco Rules**:
```yaml
# falco-rules.yaml
- rule: Database Unauthorized Access
  desc: Detect unauthorized access to database
  condition: >
    spawned_process and
    proc.name in (psql, mysql) and
    not user.name in (postgres, mysql, root)
  output: >
    Unauthorized database access
    (user=%user.name command=%proc.cmdline container=%container.name)
  priority: WARNING

- rule: Database Configuration Change
  desc: Detect changes to database configuration
  condition: >
    open_write and
    fd.name in (/var/lib/postgresql/data/postgresql.conf,
                 /etc/mysql/my.cnf) and
    not proc.name in (postgres, mysqld)
  output: >
    Database configuration file modified
    (file=%fd.name process=%proc.name container=%container.name)
  priority: WARNING
```

**OPA Gatekeeper Policies**:
```yaml
# database-security-policy.yaml
apiVersion: templates.gatekeeper.sh/v1beta1
kind: ConstraintTemplate
metadata:
  name: databasesecurityrequirements
spec:
  crd:
    spec:
      names:
        kind: DatabaseSecurityRequirements
      validation:
        properties:
          requiredLabels:
            type: array
            items:
              type: string
  targets:
    - target: admission.k8s.gatekeeper.sh
      rego: |
        package databasesecurity
        
        violation[{"msg": msg}] {
          required := input.parameters.requiredLabels
          provided := input.review.object.metadata.labels
          missing := required[_]
          not provided[missing]
          msg := sprintf("Missing required label: %v", [missing])
        }
---
apiVersion: constraints.gatekeeper.sh/v1beta1
kind: DatabaseSecurityRequirements
metadata:
  name: database-must-have-security-labels
spec:
  match:
    kinds:
      - apiGroups: ["postgresql.cnpg.io"]
        kinds: ["Cluster"]
      - apiGroups: ["pxc.percona.com"]
        kinds: ["PerconaXtraDBCluster"]
  parameters:
    requiredLabels: ["security.compliance/level", "security.compliance/owner"]
```

**Tareas**:
- [ ] Instalar Falco para runtime security
- [ ] Configurar OPA Gatekeeper
- [ ] Implementar compliance scanning
- [ ] Crear audit logs centralizados
- [ ] Configurar SIEM integration

### Evaluación Final

#### Proyecto Capstone: "Enterprise Database Platform"
**Objetivo**: Crear plataforma completa enterprise-ready

**Componentes Requeridos**:

1. **Multi-tenant Database Platform**
2. **GitOps Workflow Completo**
3. **Monitoring y Alerting Avanzado**
4. **Backup y DR Automatizado**
5. **Security y Compliance**
6. **Performance Optimization**
7. **Cost Optimization**
8. **Documentation y Training**

**Tiempo Estimado**: 6-8 semanas

**Criterios de Evaluación**:
- Arquitectura escalable y resiliente
- Automatización completa
- Seguridad enterprise-grade
- Monitoreo y observabilidad
- Documentación profesional
- Presentación técnica

### Recursos Finales

#### Certificaciones Recomendadas
- [ ] Certified Kubernetes Administrator (CKA)
- [ ] Certified Kubernetes Application Developer (CKAD)
- [ ] AWS Certified Solutions Architect
- [ ] GitOps Fundamentals (CNCF)

#### Comunidades y Eventos
- KubeCon + CloudNativeCon
- PostgreSQL Conference
- MySQL Community Events
- Local Kubernetes Meetups

**Tiempo Total del Roadmap**: 30-40 semanas (7-10 meses)
**Nivel Final**: Expert DBA en Kubernetes y Cloud Native
