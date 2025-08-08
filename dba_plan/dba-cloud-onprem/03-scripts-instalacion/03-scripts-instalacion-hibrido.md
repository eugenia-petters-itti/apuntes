# Guía de Instalación Híbrida - Docker + VMs
## Programa DBA Cloud OnPrem Junior

### 🚀 Quick Decision Guide

| Escenario | Recomendación | Tiempo Setup |
|-----------|---------------|--------------|
| **Primeros laboratorios (Semana 1-3)** | 🐳 Docker | 2-3 min |
| **Práctica con datasets** | 🐳 Docker | 2-3 min |
| **Comparación OnPrem vs RDS** | 🐳 Docker | 2-3 min |
| **Administración avanzada (Semana 4-5)** | 🖥️ VM | 15-20 min |
| **Clustering y HA** | 🖥️ VM | 20-30 min |
| **Troubleshooting nivel sistema** | 🖥️ VM | 15-20 min |

### 🐳 Opción Docker (Recomendada - 80% casos)

#### Cuándo usar Docker:
- ✅ Aprendizaje de SQL y administración básica
- ✅ Carga y manipulación de datasets
- ✅ Comparación de rendimiento básico
- ✅ Desarrollo rápido y testing
- ✅ Recursos de hardware limitados
- ✅ Necesitas setup/teardown rápido

#### Ventajas Docker:
- **Velocidad**: Entorno listo en 2-3 minutos
- **Recursos**: Consume 70% menos RAM que VMs
- **Portabilidad**: Funciona igual en Windows/Mac/Linux
- **Limpieza**: `docker-compose down` elimina todo
- **Versionado**: Imágenes específicas por laboratorio

#### Quick Start Docker:
```bash
# Levantar MySQL para laboratorios básicos
cd docker/mysql
docker-compose up -d

# Verificar funcionamiento
docker-compose ps
docker exec -it dba-mysql-lab mysql -u root -p

# Limpiar cuando termines
docker-compose down -v
```

### 🖥️ Opción VMs (Avanzada - 20% casos específicos)

#### Cuándo usar VMs:
- ✅ Administración completa del sistema operativo
- ✅ Configuración de clustering (MySQL Cluster, PostgreSQL Streaming)
- ✅ Gestión de servicios del sistema (systemd, init.d)
- ✅ Configuración de red avanzada
- ✅ Simulación de entornos de producción reales
- ✅ Troubleshooting a nivel de SO

#### Ventajas VMs:
- **Realismo**: Experiencia idéntica a producción
- **Control total**: Acceso completo al sistema operativo
- **Networking**: Configuración de red compleja
- **Servicios**: Gestión completa de daemons y servicios
- **Clustering**: Setup real de alta disponibilidad

#### Opciones de VMs disponibles:

**A) Vagrant (Desarrollo local):**
```bash
cd vms/vagrant
vagrant up mysql-vm
vagrant ssh mysql-vm
```

**B) Scripts bare-metal (Servidor dedicado):**
```bash
cd vms/scripts-bare-metal
chmod +x install_mysql_onprem.sh
./install_mysql_onprem.sh
```

**C) AWS EC2 (Cloud VMs):**
```bash
cd vms/cloud-vms/terraform
terraform init && terraform apply
```

### 📊 Comparación Detallada

| Aspecto | Docker | VMs |
|---------|--------|-----|
| **Tiempo de setup** | 2-3 min | 15-30 min |
| **Uso de RAM** | 512MB-1GB | 2-4GB |
| **Uso de disco** | 1-2GB | 10-20GB |
| **Portabilidad** | Excelente | Limitada |
| **Realismo** | Bueno | Excelente |
| **Administración SO** | Limitada | Completa |
| **Networking avanzado** | Básico | Completo |
| **Clustering** | Simulado | Real |

### 🎯 Recomendación por Semana

**Semana 1-2 (Fundamentos):** 
- 🐳 Docker exclusivamente
- Focus en SQL y administración básica

**Semana 3 (Datasets y Performance):**
- 🐳 Docker para carga de datos
- 🐳 Docker para comparación con RDS

**Semana 4 (Administración Avanzada):**
- 🖥️ VMs para clustering
- 🖥️ VMs para configuración de servicios

**Semana 5 (Troubleshooting y Producción):**
- 🖥️ VMs para simulación real
- 🐳 Docker para testing rápido

### 🔧 Herramientas Comunes

Independiente de la opción elegida:
- `verificacion-entorno.sh` - Verifica que todo funcione
- `carga-datasets.sh` - Carga datasets automáticamente  
- `comparacion-performance.sh` - Compara Docker vs VM vs RDS

### 💡 Consejos Prácticos

1. **Empieza siempre con Docker** para familiarizarte
2. **Usa VMs solo cuando Docker no sea suficiente**
3. **Combina ambos**: Docker para desarrollo, VM para validación final
4. **Documenta diferencias** que encuentres entre ambos entornos

---

**Siguiente paso:** Elige tu opción y ve a la carpeta correspondiente (`docker/` o `vms/`) para instrucciones específicas.
