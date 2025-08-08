# ⚙️ INSTALACIÓN Y REQUISITOS
## Setup Completo para el Programa DBA

### 🎯 **REQUISITOS DEL SISTEMA**

#### **Requisitos Mínimos:**
- **RAM:** 8GB (16GB recomendado)
- **Disco:** 50GB libres (100GB recomendado)
- **CPU:** 4 cores (8 cores recomendado)
- **OS:** Windows 10+, macOS 10.14+, Linux (Ubuntu 18.04+)
- **Internet:** Conexión estable para descargar imágenes Docker

#### **Requisitos Obligatorios:**
- ✅ **Docker Desktop** (versión 20.0+)
- ✅ **Docker Compose** (versión 1.29+)
- ✅ **Navegador web** moderno (Chrome, Firefox, Safari, Edge)
- ✅ **Editor de texto** (VS Code recomendado)

---

## 🐳 **INSTALACIÓN DE DOCKER**

### **Windows:**

#### **Paso 1: Descargar Docker Desktop**
1. Ir a https://docker.com/products/docker-desktop
2. Descargar "Docker Desktop for Windows"
3. Ejecutar el instalador como administrador

#### **Paso 2: Configurar Docker Desktop**
1. Abrir Docker Desktop
2. Ir a Settings → Resources → Advanced
3. Configurar:
   - **Memory:** Mínimo 4GB (8GB recomendado)
   - **CPUs:** Mínimo 2 (4 recomendado)
   - **Disk image size:** Mínimo 60GB

#### **Paso 3: Verificar Instalación**
```cmd
# Abrir PowerShell o CMD
docker --version
docker-compose --version

# Debe mostrar:
# Docker version 20.10.x
# docker-compose version 1.29.x
```

### **macOS:**

#### **Paso 1: Descargar Docker Desktop**
1. Ir a https://docker.com/products/docker-desktop
2. Descargar "Docker Desktop for Mac"
3. Arrastrar Docker.app a Applications

#### **Paso 2: Configurar Docker Desktop**
1. Abrir Docker Desktop
2. Ir a Preferences → Resources → Advanced
3. Configurar memoria y CPU como en Windows

#### **Paso 3: Verificar Instalación**
```bash
# Abrir Terminal
docker --version
docker-compose --version
```

### **Linux (Ubuntu/Debian):**

#### **Paso 1: Instalar Docker**
```bash
# Actualizar sistema
sudo apt update

# Instalar dependencias
sudo apt install apt-transport-https ca-certificates curl gnupg lsb-release

# Agregar clave GPG de Docker
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

# Agregar repositorio
echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Instalar Docker
sudo apt update
sudo apt install docker-ce docker-ce-cli containerd.io

# Agregar usuario al grupo docker
sudo usermod -aG docker $USER
```

#### **Paso 2: Instalar Docker Compose**
```bash
# Descargar Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose

# Dar permisos de ejecución
sudo chmod +x /usr/local/bin/docker-compose

# Verificar instalación
docker --version
docker-compose --version
```

---

## ✅ **VERIFICACIÓN DEL ENTORNO**

### **Test Básico de Docker:**
```bash
# Test 1: Verificar que Docker funciona
docker run hello-world

# Test 2: Verificar Docker Compose
docker-compose --version

# Test 3: Verificar recursos disponibles
docker system df
docker system info
```

### **Test del Paquete DBA:**
```bash
# Navegar al directorio del paquete
cd PAQUETE-ESTUDIANTES-DBA

# Ejecutar validador del sistema
./herramientas/validador-sistema.sh

# Debe mostrar: "✅ Sistema listo para usar"
```

---

## 🔧 **CONFIGURACIÓN ADICIONAL**

### **Configurar Memoria para Docker:**

#### **Windows/macOS:**
1. Abrir Docker Desktop
2. Settings → Resources → Advanced
3. Configurar:
   - **Memory:** 8GB (para múltiples escenarios)
   - **Swap:** 2GB
   - **CPUs:** 4-6 cores

#### **Linux:**
```bash
# Docker en Linux usa recursos del sistema directamente
# Verificar memoria disponible
free -h

# Verificar espacio en disco
df -h
```

### **Configurar Puertos:**
Los escenarios usan estos puertos. Asegúrate de que estén libres:
- **3000-3010:** Grafana y dashboards
- **8080-8090:** Interfaces de administración de BD
- **9090-9100:** Prometheus y exporters
- **3306, 5432, 27017:** Bases de datos

```bash
# Verificar puertos en uso (Linux/macOS)
sudo lsof -i :3000
sudo lsof -i :3306

# Verificar puertos en uso (Windows)
netstat -an | findstr :3000
netstat -an | findstr :3306
```

---

## 📁 **ESTRUCTURA DE ARCHIVOS**

### **Organización Recomendada:**
```
~/Documents/
└── DBA-Training/
    └── PAQUETE-ESTUDIANTES-DBA/
        ├── README.md
        ├── herramientas/
        ├── escenarios-practica/
        └── dashboard/
```

### **Permisos de Archivos:**
```bash
# En Linux/macOS, dar permisos de ejecución
chmod +x herramientas/*.sh
chmod +x herramientas/*.py

# Verificar permisos
ls -la herramientas/
```

---

## 🌐 **CONFIGURACIÓN DE RED**

### **Firewall (Windows):**
1. Abrir "Windows Defender Firewall"
2. Permitir Docker Desktop a través del firewall
3. Permitir puertos 3000-3010, 8080-8090, 9090-9100

### **Firewall (Linux):**
```bash
# UFW (Ubuntu)
sudo ufw allow 3000:3010/tcp
sudo ufw allow 8080:8090/tcp
sudo ufw allow 9090:9100/tcp

# Firewalld (CentOS/RHEL)
sudo firewall-cmd --permanent --add-port=3000-3010/tcp
sudo firewall-cmd --permanent --add-port=8080-8090/tcp
sudo firewall-cmd --reload
```

---

## 🛠️ **HERRAMIENTAS ADICIONALES RECOMENDADAS**

### **Editor de Código:**
- **VS Code** (recomendado): https://code.visualstudio.com
- **Sublime Text**: https://sublimetext.com
- **Atom**: https://atom.io

### **Extensiones VS Code Útiles:**
- Docker
- MySQL
- PostgreSQL
- MongoDB for VS Code
- YAML
- Markdown Preview Enhanced

### **Clientes de Base de Datos (Opcionales):**
- **MySQL Workbench**: https://dev.mysql.com/downloads/workbench/
- **pgAdmin**: https://pgadmin.org
- **MongoDB Compass**: https://mongodb.com/products/compass
- **DBeaver** (universal): https://dbeaver.io

---

## 🚨 **TROUBLESHOOTING COMÚN**

### **Problema: Docker no inicia**
```bash
# Windows: Reiniciar Docker Desktop
# Linux: Reiniciar servicio
sudo systemctl restart docker

# Verificar logs
docker system events
```

### **Problema: Puerto ocupado**
```bash
# Ver qué proceso usa el puerto
sudo lsof -i :3000  # Linux/macOS
netstat -ano | findstr :3000  # Windows

# Matar proceso si es necesario
kill -9 PID  # Linux/macOS
taskkill /PID PID /F  # Windows
```

### **Problema: Sin espacio en disco**
```bash
# Limpiar Docker
docker system prune -a
docker volume prune

# Ver uso de espacio
docker system df
```

### **Problema: Memoria insuficiente**
```bash
# Ver uso de memoria
docker stats

# Detener contenedores innecesarios
docker stop $(docker ps -q)
```

### **Problema: Permisos en Linux**
```bash
# Agregar usuario al grupo docker
sudo usermod -aG docker $USER

# Cerrar sesión y volver a entrar
# O ejecutar:
newgrp docker
```

---

## ✅ **CHECKLIST FINAL**

Antes de empezar el programa, verifica que tienes:

- [ ] Docker Desktop instalado y funcionando
- [ ] Docker Compose disponible
- [ ] Mínimo 8GB RAM asignados a Docker
- [ ] Mínimo 50GB espacio libre en disco
- [ ] Puertos 3000-3010, 8080-8090, 9090-9100 libres
- [ ] Navegador web moderno instalado
- [ ] Editor de texto instalado
- [ ] Paquete DBA descargado y descomprimido
- [ ] Permisos de ejecución en herramientas
- [ ] Validador del sistema ejecutado exitosamente

### **Comando Final de Verificación:**
```bash
cd PAQUETE-ESTUDIANTES-DBA
./herramientas/validador-sistema.sh

# Debe mostrar:
# ✅ Docker: Funcionando
# ✅ Docker Compose: Disponible
# ✅ Memoria: Suficiente
# ✅ Espacio: Suficiente
# ✅ Puertos: Disponibles
# ✅ Sistema listo para usar
```

---

## 🎓 **¡LISTO PARA EMPEZAR!**

Una vez que tengas todo configurado:

1. **Lee** el `README.md` principal
2. **Sigue** la `INICIO-RAPIDO.md` para tu primer escenario
3. **Consulta** el `PLAN-ESTUDIO-5-SEMANAS.md` para el cronograma completo

**🚀 ¡Tu journey hacia convertirte en DBA experto comienza ahora!**

---

### **Soporte Técnico:**
Si tienes problemas con la instalación:
1. Revisa la sección de troubleshooting
2. Consulta la documentación oficial de Docker
3. Busca en los foros de la comunidad
4. Contacta al instructor si estás en un programa formal
