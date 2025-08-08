# Laboratorio Semana 0 - Fundamentos OnPrem
## DBA Cloud OnPrem Junior

### 🎯 Objetivos del Laboratorio
Al finalizar este laboratorio, el estudiante será capaz de:
- Instalar MySQL y PostgreSQL desde cero en Linux
- Configurar servicios del sistema con systemd
- Configurar firewall básico para bases de datos
- Crear usuarios del sistema operativo y de base de datos
- Documentar procedimientos de instalación

### 🖥️ Infraestructura Requerida
```yaml
# Especificaciones mínimas por VM
VM1 - MySQL Server:
  OS: Ubuntu 20.04 LTS
  RAM: 4GB
  CPU: 2 cores
  Disk: 50GB
  Network: Acceso a internet

VM2 - PostgreSQL Server:
  OS: Ubuntu 20.04 LTS  
  RAM: 4GB
  CPU: 2 cores
  Disk: 50GB
  Network: Acceso a internet

# Accesos requeridos
- Usuario con privilegios sudo
- Conexión SSH configurada
- Acceso a repositorios oficiales
```

---

## 📋 Laboratorio 1: Instalación de MySQL OnPrem

### Paso 1: Preparación del Sistema
```bash
# Conectar a VM1 (MySQL Server)
ssh student@mysql-vm-ip

# Actualizar sistema
sudo apt update && sudo apt upgrade -y

# Instalar herramientas básicas
sudo apt install -y curl wget vim htop net-tools tree

# Verificar espacio en disco
df -h
free -h
```

### Paso 2: Instalación de MySQL
```bash
# Instalar MySQL Server
sudo apt install -y mysql-server mysql-client

# Verificar instalación
mysql --version
sudo systemctl status mysql

# Ejecutar configuración de seguridad
sudo mysql_secure_installation
```

**Configuración de mysql_secure_installation:**
```
- Set root password: YES (usar: MyS3cur3P@ss!)
- Remove anonymous users: YES
- Disallow root login remotely: NO (para laboratorio)
- Remove test database: YES
- Reload privilege tables: YES
```

### Paso 3: Configuración Básica
```bash
# Editar configuración principal
sudo vim /etc/mysql/mysql.conf.d/mysqld.cnf

# Modificar las siguientes líneas:
bind-address = 0.0.0.0
max_connections = 200
innodb_buffer_pool_size = 1G
slow_query_log = 1
slow_query_log_file = /var/log/mysql/slow.log
long_query_time = 2

# Reiniciar servicio
sudo systemctl restart mysql
sudo systemctl enable mysql
```

### Paso 4: Configuración de Firewall
```bash
# Habilitar firewall
sudo ufw enable

# Permitir SSH (importante!)
sudo ufw allow ssh

# Permitir MySQL
sudo ufw allow 3306/tcp

# Verificar reglas
sudo ufw status verbose
```

### Paso 5: Crear Usuarios de Base de Datos
```sql
-- Conectar como root
sudo mysql -u root -p

-- Crear usuario administrador
CREATE USER 'dbadmin'@'%' IDENTIFIED BY 'Admin123!';
GRANT ALL PRIVILEGES ON *.* TO 'dbadmin'@'%' WITH GRANT OPTION;

-- Crear usuario readonly
CREATE USER 'readonly'@'%' IDENTIFIED BY 'Read123!';
GRANT SELECT ON *.* TO 'readonly'@'%';

-- Crear usuario readwrite
CREATE USER 'readwrite'@'%' IDENTIFIED BY 'Write123!';
GRANT SELECT, INSERT, UPDATE, DELETE ON *.* TO 'readwrite'@'%';

-- Aplicar cambios
FLUSH PRIVILEGES;

-- Verificar usuarios
SELECT user, host FROM mysql.user;
```

### Paso 6: Pruebas de Conectividad
```bash
# Probar conexión local
mysql -u dbadmin -p -e "SELECT VERSION();"

# Probar desde otra máquina (usar IP de la VM)
mysql -h MYSQL_VM_IP -u readonly -p -e "SHOW DATABASES;"
```

---

## 📋 Laboratorio 2: Instalación de PostgreSQL OnPrem

### Paso 1: Preparación del Sistema
```bash
# Conectar a VM2 (PostgreSQL Server)
ssh student@postgres-vm-ip

# Actualizar sistema
sudo apt update && sudo apt upgrade -y

# Instalar herramientas básicas
sudo apt install -y curl wget vim htop net-tools tree
```

### Paso 2: Instalación de PostgreSQL
```bash
# Instalar PostgreSQL
sudo apt install -y postgresql postgresql-client postgresql-contrib

# Verificar instalación
psql --version
sudo systemctl status postgresql

# Habilitar servicio
sudo systemctl enable postgresql
```

### Paso 3: Configuración Inicial
```bash
# Cambiar a usuario postgres
sudo -i -u postgres

# Configurar password para usuario postgres
psql -c "ALTER USER postgres PASSWORD 'Postgres123!';"

# Salir del usuario postgres
exit
```

### Paso 4: Configuración de Acceso Remoto
```bash
# Editar postgresql.conf
sudo vim /etc/postgresql/12/main/postgresql.conf

# Modificar:
listen_addresses = '*'
port = 5432
max_connections = 200
shared_buffers = 1GB
work_mem = 4MB

# Editar pg_hba.conf para permitir conexiones
sudo vim /etc/postgresql/12/main/pg_hba.conf

# Agregar al final:
host    all             all             0.0.0.0/0               md5
```

### Paso 5: Configuración de Firewall
```bash
# Permitir PostgreSQL
sudo ufw allow 5432/tcp

# Verificar reglas
sudo ufw status verbose

# Reiniciar PostgreSQL
sudo systemctl restart postgresql
```

### Paso 6: Crear Usuarios y Bases de Datos
```sql
-- Conectar como postgres
sudo -u postgres psql

-- Crear usuario administrador
CREATE USER dbadmin WITH PASSWORD 'Admin123!' CREATEDB CREATEROLE;

-- Crear usuario readonly
CREATE USER readonly WITH PASSWORD 'Read123!';

-- Crear usuario readwrite  
CREATE USER readwrite WITH PASSWORD 'Write123!';

-- Crear base de datos de prueba
CREATE DATABASE testdb OWNER dbadmin;

-- Conectar a testdb
\c testdb

-- Otorgar permisos
GRANT CONNECT ON DATABASE testdb TO readonly, readwrite;
GRANT USAGE ON SCHEMA public TO readonly, readwrite;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO readonly;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO readwrite;

-- Verificar usuarios
\du

-- Salir
\q
```

### Paso 7: Pruebas de Conectividad
```bash
# Probar conexión local
psql -U dbadmin -d testdb -c "SELECT version();"

# Probar desde otra máquina
psql -h POSTGRES_VM_IP -U readonly -d testdb -c "SELECT current_database();"
```

---

## 📋 Laboratorio 3: Creación de Datos de Prueba

### Para MySQL
```sql
-- Conectar como dbadmin
mysql -u dbadmin -p

-- Crear base de datos de prueba
CREATE DATABASE ecommerce_lab;
USE ecommerce_lab;

-- Crear tablas
CREATE TABLE customers (
    id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    phone VARCHAR(20),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE products (
    id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(200) NOT NULL,
    price DECIMAL(10,2) NOT NULL,
    category VARCHAR(50),
    stock INT DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE orders (
    id INT PRIMARY KEY AUTO_INCREMENT,
    customer_id INT,
    total DECIMAL(10,2),
    status VARCHAR(20) DEFAULT 'pending',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (customer_id) REFERENCES customers(id)
);

-- Insertar datos de prueba
INSERT INTO customers (name, email, phone) VALUES
('Juan Pérez', 'juan@email.com', '555-0001'),
('María García', 'maria@email.com', '555-0002'),
('Carlos López', 'carlos@email.com', '555-0003'),
('Ana Martínez', 'ana@email.com', '555-0004'),
('Luis Rodríguez', 'luis@email.com', '555-0005');

INSERT INTO products (name, price, category, stock) VALUES
('Laptop Dell', 899.99, 'Electronics', 10),
('Mouse Logitech', 29.99, 'Electronics', 50),
('Desk Chair', 199.99, 'Furniture', 15),
('Monitor 24"', 299.99, 'Electronics', 8),
('Keyboard', 79.99, 'Electronics', 25);

INSERT INTO orders (customer_id, total, status) VALUES
(1, 929.98, 'completed'),
(2, 199.99, 'pending'),
(3, 379.98, 'completed'),
(1, 79.99, 'shipped'),
(4, 899.99, 'pending');
```

### Para PostgreSQL
```sql
-- Conectar como dbadmin
psql -U dbadmin -d testdb

-- Crear tablas similares
CREATE TABLE customers (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    phone VARCHAR(20),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE products (
    id SERIAL PRIMARY KEY,
    name VARCHAR(200) NOT NULL,
    price DECIMAL(10,2) NOT NULL,
    category VARCHAR(50),
    stock INTEGER DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE orders (
    id SERIAL PRIMARY KEY,
    customer_id INTEGER REFERENCES customers(id),
    total DECIMAL(10,2),
    status VARCHAR(20) DEFAULT 'pending',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Insertar los mismos datos de prueba
-- (usar los mismos INSERT statements adaptados)
```

---

## 🧪 Ejercicios de Evaluación

### Ejercicio 1: Verificación de Instalación (25 puntos)
**Tiempo límite: 30 minutos**

```bash
# El estudiante debe ejecutar y documentar:

# 1. Verificar versiones instaladas
mysql --version
psql --version

# 2. Verificar servicios activos
sudo systemctl status mysql
sudo systemctl status postgresql

# 3. Verificar puertos en escucha
sudo netstat -tlnp | grep :3306
sudo netstat -tlnp | grep :5432

# 4. Verificar logs de arranque
sudo journalctl -u mysql --since "1 hour ago"
sudo journalctl -u postgresql --since "1 hour ago"
```

**Criterios de evaluación:**
- Servicios funcionando correctamente (10 pts)
- Puertos configurados y escuchando (10 pts)
- Sin errores en logs (5 pts)

### Ejercicio 2: Gestión de Usuarios (25 puntos)
**Tiempo límite: 45 minutos**

```sql
-- MySQL: Crear usuario específico para aplicación
CREATE USER 'app_user'@'localhost' IDENTIFIED BY 'AppPass123!';
GRANT SELECT, INSERT, UPDATE ON ecommerce_lab.* TO 'app_user'@'localhost';

-- PostgreSQL: Crear usuario específico para reportes
CREATE USER report_user WITH PASSWORD 'ReportPass123!';
GRANT CONNECT ON DATABASE testdb TO report_user;
GRANT USAGE ON SCHEMA public TO report_user;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO report_user;
```

**Criterios de evaluación:**
- Usuarios creados correctamente (10 pts)
- Permisos asignados apropiadamente (10 pts)
- Puede conectar y ejecutar operaciones permitidas (5 pts)

### Ejercicio 3: Configuración de Seguridad (25 puntos)
**Tiempo límite: 30 minutos**

```bash
# Configurar firewall más restrictivo
sudo ufw delete allow 3306/tcp
sudo ufw delete allow 5432/tcp

# Permitir solo desde red específica (ejemplo: 192.168.1.0/24)
sudo ufw allow from 192.168.1.0/24 to any port 3306
sudo ufw allow from 192.168.1.0/24 to any port 5432

# Verificar configuración SSL en PostgreSQL
sudo -u postgres psql -c "SHOW ssl;"

# Verificar configuración SSL en MySQL
mysql -u root -p -e "SHOW VARIABLES LIKE '%ssl%';"
```

**Criterios de evaluación:**
- Firewall configurado restrictivamente (10 pts)
- SSL verificado y documentado (10 pts)
- Acceso remoto funcional desde red permitida (5 pts)

### Ejercicio 4: Troubleshooting Básico (25 puntos)
**Tiempo límite: 45 minutos**

**Escenario:** Se han introducido los siguientes problemas intencionalmente:
1. Servicio MySQL detenido
2. Puerto PostgreSQL bloqueado en firewall
3. Usuario con password expirado

```bash
# El estudiante debe:
# 1. Identificar los problemas
# 2. Documentar el diagnóstico
# 3. Resolver cada problema
# 4. Verificar la solución

# Comandos de diagnóstico esperados:
sudo systemctl status mysql postgresql
sudo ufw status
sudo netstat -tlnp | grep -E "(3306|5432)"
mysql -u problema_user -p
```

**Criterios de evaluación:**
- Identifica todos los problemas (10 pts)
- Documenta el proceso de diagnóstico (5 pts)
- Resuelve todos los problemas (10 pts)

---

## 📊 Rúbrica de Evaluación Final

### Escala de Calificación
- **Excelente (90-100):** Ejecuta todas las tareas de forma autónoma, documenta correctamente, resuelve problemas sin ayuda
- **Bueno (80-89):** Ejecuta la mayoría de tareas correctamente, requiere ayuda mínima
- **Regular (70-79):** Ejecuta tareas básicas, requiere ayuda frecuente
- **Insuficiente (<70):** No logra completar tareas básicas de forma funcional

### Criterios Específicos

| Criterio | Peso | Excelente | Bueno | Regular | Insuficiente |
|----------|------|-----------|-------|---------|--------------|
| **Instalación** | 25% | Instala sin ayuda, configura parámetros avanzados | Instala correctamente, configuración básica | Instala con ayuda, configuración mínima | No logra instalación funcional |
| **Configuración** | 25% | Configura servicios, firewall, usuarios correctamente | Configuración básica correcta | Configuración parcial funcional | Configuración incorrecta |
| **Seguridad** | 25% | Implementa todas las medidas de seguridad | Implementa medidas básicas | Seguridad mínima | Sin medidas de seguridad |
| **Troubleshooting** | 25% | Identifica y resuelve problemas autónomamente | Resuelve con guía mínima | Requiere ayuda para resolver | No puede resolver problemas |

---

## 📝 Entregables del Laboratorio

### 1. Documento de Instalación
```markdown
# Reporte de Instalación - Semana 0
## Estudiante: [Nombre]
## Fecha: [Fecha]

### MySQL Installation Log
- Versión instalada: 
- Configuración aplicada:
- Usuarios creados:
- Problemas encontrados:
- Soluciones aplicadas:

### PostgreSQL Installation Log
- Versión instalada:
- Configuración aplicada:
- Usuarios creados:
- Problemas encontrados:
- Soluciones aplicadas:

### Verificaciones Finales
- [ ] MySQL responde en puerto 3306
- [ ] PostgreSQL responde en puerto 5432
- [ ] Usuarios pueden conectar remotamente
- [ ] Firewall configurado correctamente
- [ ] Servicios configurados para inicio automático
```

### 2. Scripts de Configuración
```bash
#!/bin/bash
# mysql_setup.sh - Script de configuración MySQL
# Creado por: [Estudiante]
# Fecha: [Fecha]

echo "Configurando MySQL..."
# Incluir todos los comandos utilizados
```

### 3. Capturas de Pantalla
- Servicios activos (systemctl status)
- Conexiones exitosas desde cliente remoto
- Configuración de firewall (ufw status)
- Verificación de usuarios creados

---

## 🔧 Herramientas de Soporte

### Script de Verificación Automática
```bash
#!/bin/bash
# verify_lab0.sh - Verificación automática del laboratorio

echo "=== Verificación Laboratorio Semana 0 ==="

# Verificar MySQL
if systemctl is-active --quiet mysql; then
    echo "✅ MySQL service is running"
    mysql -u root -p -e "SELECT VERSION();" 2>/dev/null && echo "✅ MySQL connection OK"
else
    echo "❌ MySQL service is not running"
fi

# Verificar PostgreSQL
if systemctl is-active --quiet postgresql; then
    echo "✅ PostgreSQL service is running"
    sudo -u postgres psql -c "SELECT version();" 2>/dev/null && echo "✅ PostgreSQL connection OK"
else
    echo "❌ PostgreSQL service is not running"
fi

# Verificar puertos
netstat -tlnp | grep :3306 >/dev/null && echo "✅ MySQL port 3306 listening" || echo "❌ MySQL port not listening"
netstat -tlnp | grep :5432 >/dev/null && echo "✅ PostgreSQL port 5432 listening" || echo "❌ PostgreSQL port not listening"

echo "=== Verificación completada ==="
```

### Datasets de Respaldo
En caso de problemas con la creación de datos, proporcionar archivos SQL pre-generados:
- `mysql_sample_data.sql`
- `postgres_sample_data.sql`

Este laboratorio proporciona una base sólida para evaluar las competencias fundamentales OnPrem antes de avanzar a temas más complejos.
