# Laboratorios de Operadores Percona para Kubernetes

Este repositorio contiene laboratorios prácticos para aprender y probar los operadores de Percona en Kubernetes.

## Operadores Incluidos

1. **Percona Operator for MySQL (PXC)** - Percona XtraDB Cluster
2. **Percona Operator for MongoDB (PSMDB)** - Percona Server for MongoDB
3. **Percona Operator for PostgreSQL (PG)** - Percona Distribution for PostgreSQL

## Estructura de Laboratorios

```
percona-operators-labs/
├── lab-01-setup/              # Configuración inicial del entorno
├── lab-02-mysql-pxc/          # Percona XtraDB Cluster
├── lab-03-mongodb-psmdb/      # Percona Server for MongoDB
├── lab-04-postgresql-pg/      # Percona Distribution for PostgreSQL
├── lab-05-backup-restore/     # Backup y restore
├── lab-06-monitoring/         # Monitoreo con PMM
├── lab-07-scaling/            # Escalado y alta disponibilidad
└── lab-08-troubleshooting/    # Resolución de problemas
```

## Prerrequisitos

- Kubernetes cluster (minikube, kind, o cluster real)
- kubectl configurado
- Helm 3.x
- Al menos 8GB RAM disponible
- 20GB de espacio en disco

## Orden de Ejecución

1. Comenzar con `lab-01-setup` para preparar el entorno
2. Continuar con los laboratorios específicos de cada operador
3. Finalizar con los laboratorios avanzados de backup, monitoreo y troubleshooting

## Recursos Adicionales

- [Documentación oficial de Percona](https://docs.percona.com/)
- [Percona Operators GitHub](https://github.com/percona)
