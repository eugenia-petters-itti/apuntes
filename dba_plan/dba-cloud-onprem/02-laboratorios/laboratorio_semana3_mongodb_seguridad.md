# Laboratorio Semana 3 - DocumentDB/MongoDB y Seguridad Híbrida
## DBA Cloud OnPrem Junior

### 🎯 Objetivos del Laboratorio
Al finalizar este laboratorio, el estudiante será capaz de:
- Instalar y configurar MongoDB OnPrem con SSL/TLS
- Conectar y operar con DocumentDB en AWS
- Configurar autenticación y autorización en MongoDB
- Implementar migración de datos OnPrem ↔ Cloud
- Configurar seguridad híbrida end-to-end

### 🖥️ Infraestructura Requerida
```yaml
# Nueva VM para MongoDB OnPrem
VM3 - MongoDB OnPrem:
  OS: Ubuntu 20.04 LTS
  RAM: 4GB
  CPU: 2 cores
  Disk: 50GB
  Network: Acceso a internet

# AWS Cloud (de laboratorios anteriores)
DocumentDB Cluster: Funcionando
EC2 Bastion: Funcionando

# Herramientas
- mongosh
- MongoDB Database Tools
- OpenSSL para certificados
- AWS CLI
```

---

## 📋 Laboratorio 1: Instalación MongoDB OnPrem

### Paso 1: Instalación de MongoDB Community
```bash
# Conectar a VM3 (MongoDB OnPrem)
ssh student@mongodb-vm-ip

# Importar clave pública de MongoDB
wget -qO - https://www.mongodb.org/static/pgp/server-6.0.asc | sudo apt-key add -

# Crear archivo de lista de fuentes
echo "deb [ arch=amd64,arm64 ] https://repo.mongodb.org/apt/ubuntu focal/mongodb-org/6.0 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-6.0.list

# Actualizar paquetes e instalar MongoDB
sudo apt update
sudo apt install -y mongodb-org

# Instalar herramientas adicionales
sudo apt install -y mongodb-database-tools mongodb-mongosh

# Verificar instalación
mongod --version
mongosh --version
```

### Paso 2: Configuración Inicial
```bash
# Crear directorios necesarios
sudo mkdir -p /var/lib/mongodb
sudo mkdir -p /var/log/mongodb
sudo mkdir -p /etc/ssl/mongodb

# Configurar permisos
sudo chown mongodb:mongodb /var/lib/mongodb
sudo chown mongodb:mongodb /var/log/mongodb
sudo chown mongodb:mongodb /etc/ssl/mongodb

# Crear archivo de configuración
sudo tee /etc/mongod.conf > /dev/null <<EOF
# mongod.conf
storage:
  dbPath: /var/lib/mongodb
  journal:
    enabled: true

systemLog:
  destination: file
  logAppend: true
  path: /var/log/mongodb/mongod.log

net:
  port: 27017
  bindIp: 0.0.0.0

processManagement:
  timeZoneInfo: /usr/share/zoneinfo

security:
  authorization: enabled

replication:
  replSetName: "rs0"
EOF

# Iniciar MongoDB
sudo systemctl start mongod
sudo systemctl enable mongod

# Verificar estado
sudo systemctl status mongod
```

### Paso 3: Configuración de Replica Set
```bash
# Conectar a MongoDB
mongosh

# Inicializar replica set
rs.initiate({
  _id: "rs0",
  members: [
    { _id: 0, host: "localhost:27017" }
  ]
})

# Verificar estado del replica set
rs.status()

# Salir de mongosh
exit
```

---

## 📋 Laboratorio 2: Configuración de Seguridad OnPrem

### Paso 1: Crear Certificados SSL/TLS
```bash
# Crear directorio para certificados
sudo mkdir -p /etc/ssl/mongodb
cd /etc/ssl/mongodb

# Generar clave privada
sudo openssl genrsa -out mongodb-server.key 2048

# Generar certificado auto-firmado
sudo openssl req -new -x509 -key mongodb-server.key -out mongodb-server.crt -days 365 -subj "/C=US/ST=State/L=City/O=Organization/OU=IT/CN=mongodb-server"

# Combinar clave y certificado
sudo cat mongodb-server.key mongodb-server.crt > mongodb-server.pem

# Configurar permisos
sudo chown mongodb:mongodb /etc/ssl/mongodb/*
sudo chmod 600 /etc/ssl/mongodb/mongodb-server.key
sudo chmod 644 /etc/ssl/mongodb/mongodb-server.crt
sudo chmod 600 /etc/ssl/mongodb/mongodb-server.pem
```

### Paso 2: Configurar SSL en MongoDB
```bash
# Actualizar configuración de MongoDB
sudo tee /etc/mongod.conf > /dev/null <<EOF
# mongod.conf with SSL
storage:
  dbPath: /var/lib/mongodb
  journal:
    enabled: true

systemLog:
  destination: file
  logAppend: true
  path: /var/log/mongodb/mongod.log

net:
  port: 27017
  bindIp: 0.0.0.0
  tls:
    mode: requireTLS
    certificateKeyFile: /etc/ssl/mongodb/mongodb-server.pem
    allowConnectionsWithoutCertificates: true

processManagement:
  timeZoneInfo: /usr/share/zoneinfo

security:
  authorization: enabled

replication:
  replSetName: "rs0"
EOF

# Reiniciar MongoDB
sudo systemctl restart mongod

# Verificar que está escuchando con SSL
sudo netstat -tlnp | grep :27017
```

### Paso 3: Crear Usuarios de Administración
```bash
# Conectar con SSL
mongosh --tls --tlsAllowInvalidCertificates

# Crear usuario administrador
use admin
db.createUser({
  user: "admin",
  pwd: "AdminPass123!",
  roles: [
    { role: "userAdminAnyDatabase", db: "admin" },
    { role: "readWriteAnyDatabase", db: "admin" },
    { role: "dbAdminAnyDatabase", db: "admin" },
    { role: "clusterAdmin", db: "admin" }
  ]
})

# Salir y reconectar con autenticación
exit

# Conectar con usuario admin
mongosh --tls --tlsAllowInvalidCertificates -u admin -p AdminPass123! --authenticationDatabase admin
```

---

## 📋 Laboratorio 3: Gestión de Usuarios MongoDB

### Paso 1: Crear Roles Personalizados
```javascript
// Conectar como admin
mongosh --tls --tlsAllowInvalidCertificates -u admin -p AdminPass123! --authenticationDatabase admin

// Crear base de datos de prueba
use ecommerce_mongo

// Crear rol para desarrolladores
db.runCommand({
  createRole: "developerRole",
  privileges: [
    {
      resource: { db: "ecommerce_mongo", collection: "" },
      actions: ["find", "insert", "update", "remove", "createIndex"]
    }
  ],
  roles: []
})

// Crear rol para analistas (solo lectura)
db.runCommand({
  createRole: "analystRole",
  privileges: [
    {
      resource: { db: "ecommerce_mongo", collection: "" },
      actions: ["find"]
    }
  ],
  roles: []
})

// Crear rol para aplicación
db.runCommand({
  createRole: "appRole",
  privileges: [
    {
      resource: { db: "ecommerce_mongo", collection: "customers" },
      actions: ["find", "insert", "update", "remove"]
    },
    {
      resource: { db: "ecommerce_mongo", collection: "orders" },
      actions: ["find", "insert", "update", "remove"]
    },
    {
      resource: { db: "ecommerce_mongo", collection: "products" },
      actions: ["find"]
    }
  ],
  roles: []
})
```

### Paso 2: Crear Usuarios con Roles
```javascript
// Crear usuarios
use admin

// Usuario desarrollador
db.createUser({
  user: "developer",
  pwd: "DevPass123!",
  roles: [
    { role: "developerRole", db: "ecommerce_mongo" }
  ]
})

// Usuario analista
db.createUser({
  user: "analyst",
  pwd: "AnalystPass123!",
  roles: [
    { role: "analystRole", db: "ecommerce_mongo" }
  ]
})

// Usuario aplicación
db.createUser({
  user: "app_user",
  pwd: "AppPass123!",
  roles: [
    { role: "appRole", db: "ecommerce_mongo" }
  ]
})

// Usuario backup
db.createUser({
  user: "backup_user",
  pwd: "BackupPass123!",
  roles: [
    { role: "backup", db: "admin" },
    { role: "readAnyDatabase", db: "admin" }
  ]
})

// Listar usuarios
db.getUsers()
```

---

## 📋 Laboratorio 4: Operaciones CRUD y Datos de Prueba

### Paso 1: Crear Colecciones y Datos
```javascript
// Conectar como developer
mongosh --tls --tlsAllowInvalidCertificates -u developer -p DevPass123! --authenticationDatabase admin

use ecommerce_mongo

// Crear colección de customers
db.customers.insertMany([
  {
    _id: ObjectId(),
    name: "Juan Pérez",
    email: "juan@email.com",
    phone: "555-0001",
    address: {
      street: "123 Main St",
      city: "Madrid",
      country: "Spain",
      zipCode: "28001"
    },
    createdAt: new Date()
  },
  {
    _id: ObjectId(),
    name: "María García",
    email: "maria@email.com",
    phone: "555-0002",
    address: {
      street: "456 Oak Ave",
      city: "Barcelona",
      country: "Spain",
      zipCode: "08001"
    },
    createdAt: new Date()
  },
  {
    _id: ObjectId(),
    name: "Carlos López",
    email: "carlos@email.com",
    phone: "555-0003",
    address: {
      street: "789 Pine Rd",
      city: "Valencia",
      country: "Spain",
      zipCode: "46001"
    },
    createdAt: new Date()
  }
])

// Crear colección de products
db.products.insertMany([
  {
    _id: ObjectId(),
    name: "Laptop Dell XPS 13",
    price: 899.99,
    category: "Electronics",
    stock: 10,
    specifications: {
      processor: "Intel i7",
      ram: "16GB",
      storage: "512GB SSD"
    },
    tags: ["laptop", "dell", "portable"],
    createdAt: new Date()
  },
  {
    _id: ObjectId(),
    name: "Mouse Logitech MX Master",
    price: 79.99,
    category: "Electronics",
    stock: 50,
    specifications: {
      type: "Wireless",
      buttons: 7,
      battery: "Rechargeable"
    },
    tags: ["mouse", "logitech", "wireless"],
    createdAt: new Date()
  }
])

// Crear colección de orders
db.orders.insertMany([
  {
    _id: ObjectId(),
    customerId: db.customers.findOne({email: "juan@email.com"})._id,
    items: [
      {
        productId: db.products.findOne({name: /Laptop/})._id,
        quantity: 1,
        price: 899.99
      }
    ],
    total: 899.99,
    status: "completed",
    orderDate: new Date(),
    shippingAddress: {
      street: "123 Main St",
      city: "Madrid",
      country: "Spain",
      zipCode: "28001"
    }
  }
])
```

### Paso 2: Crear Índices
```javascript
// Crear índices para optimizar consultas
db.customers.createIndex({ email: 1 }, { unique: true })
db.customers.createIndex({ "address.city": 1 })
db.products.createIndex({ category: 1, price: 1 })
db.products.createIndex({ tags: 1 })
db.orders.createIndex({ customerId: 1 })
db.orders.createIndex({ orderDate: -1 })
db.orders.createIndex({ status: 1 })

// Verificar índices
db.customers.getIndexes()
db.products.getIndexes()
db.orders.getIndexes()
```

---

## 📋 Laboratorio 5: Conectividad con DocumentDB

### Paso 1: Configurar Conexión a DocumentDB
```bash
# Desde el bastion EC2 (creado en laboratorio anterior)
ssh -i lab-bastion-key.pem ec2-user@$BASTION_IP

# Verificar que mongosh está instalado
mongosh --version

# Descargar certificado SSL para DocumentDB (si no está)
wget https://s3.amazonaws.com/rds-downloads/rds-combined-ca-bundle.pem

# Obtener endpoint de DocumentDB
DOCDB_ENDPOINT=$(aws docdb describe-db-clusters \
    --db-cluster-identifier docdb-lab-cluster \
    --query 'DBClusters[0].Endpoint' \
    --output text)

echo "DocumentDB Endpoint: $DOCDB_ENDPOINT"
```

### Paso 2: Crear Usuarios en DocumentDB
```javascript
// Conectar a DocumentDB
mongosh --host $DOCDB_ENDPOINT:27017 \
    --username docdbadmin \
    --password 'DocDB123!' \
    --ssl \
    --sslCAFile rds-combined-ca-bundle.pem \
    --retryWrites=false

// Crear usuarios similares a MongoDB OnPrem
use admin

db.createUser({
  user: "developer",
  pwd: "DevPass123!",
  roles: [
    { role: "readWrite", db: "ecommerce_docdb" }
  ]
})

db.createUser({
  user: "analyst",
  pwd: "AnalystPass123!",
  roles: [
    { role: "read", db: "ecommerce_docdb" }
  ]
})

// Verificar usuarios
db.getUsers()
```

### Paso 3: Migrar Datos OnPrem → DocumentDB
```bash
# Desde MongoDB OnPrem, exportar datos
mongodump --host localhost:27017 \
    --ssl --sslAllowInvalidCertificates \
    --username developer \
    --password DevPass123! \
    --authenticationDatabase admin \
    --db ecommerce_mongo \
    --out /backup/mongodb/export_to_docdb

# Copiar backup al bastion (desde máquina local)
scp -i lab-bastion-key.pem -r /backup/mongodb/export_to_docdb ec2-user@$BASTION_IP:/tmp/

# Desde el bastion, importar a DocumentDB
mongorestore --host $DOCDB_ENDPOINT:27017 \
    --username developer \
    --password DevPass123! \
    --ssl \
    --sslCAFile rds-combined-ca-bundle.pem \
    --db ecommerce_docdb \
    /tmp/export_to_docdb/ecommerce_mongo/
```

---

## 🧪 Ejercicios de Evaluación

### Ejercicio 1: Instalación y Configuración SSL (25 puntos)
**Tiempo límite: 45 minutos**

**Tarea:** 
1. Instalar MongoDB OnPrem con SSL habilitado
2. Crear certificado auto-firmado
3. Configurar autenticación
4. Crear usuario administrador

**Verificación esperada:**
```bash
# Debe poder conectar con SSL
mongosh --tls --tlsAllowInvalidCertificates -u admin -p AdminPass123! --authenticationDatabase admin

# Debe mostrar SSL habilitado
db.adminCommand("getCmdLineOpts")
```

**Criterios de evaluación:**
- MongoDB instalado y funcionando (10 pts)
- SSL configurado correctamente (10 pts)
- Usuario admin creado y funcional (5 pts)

### Ejercicio 2: Gestión de Usuarios y Roles (25 puntos)
**Tiempo límite: 40 minutos**

**Tarea:** Crear estructura de usuarios empresarial:
- `dba_user`: Administración completa
- `app_user`: CRUD en colecciones específicas
- `readonly_user`: Solo lectura en toda la base

```javascript
// Solución esperada
use admin

// Crear roles personalizados
db.runCommand({
  createRole: "appRole",
  privileges: [
    {
      resource: { db: "test_db", collection: "users" },
      actions: ["find", "insert", "update", "remove"]
    },
    {
      resource: { db: "test_db", collection: "orders" },
      actions: ["find", "insert", "update", "remove"]
    }
  ],
  roles: []
})

// Crear usuarios
db.createUser({
  user: "app_user",
  pwd: "AppPass123!",
  roles: [{ role: "appRole", db: "test_db" }]
})
```

**Criterios de evaluación:**
- Roles creados correctamente (10 pts)
- Usuarios asignados a roles apropiados (10 pts)
- Permisos funcionan según especificación (5 pts)

### Ejercicio 3: Migración de Datos (30 puntos)
**Tiempo límite: 50 minutos**

**Tarea:** 
1. Exportar datos de MongoDB OnPrem
2. Importar a DocumentDB
3. Verificar integridad de datos
4. Crear índices en DocumentDB

```bash
# Comandos esperados
mongodump --host localhost:27017 --ssl --sslAllowInvalidCertificates \
    --username backup_user --password BackupPass123! \
    --authenticationDatabase admin \
    --db source_db --out /backup/migration/

mongorestore --host $DOCDB_ENDPOINT:27017 \
    --username docdbadmin --password DocDB123! \
    --ssl --sslCAFile rds-combined-ca-bundle.pem \
    --db target_db /backup/migration/source_db/
```

**Criterios de evaluación:**
- Exportación exitosa (10 pts)
- Importación exitosa (10 pts)
- Verificación de integridad (5 pts)
- Índices creados (5 pts)

### Ejercicio 4: Troubleshooting de Conectividad (20 puntos)
**Tiempo límite: 30 minutos**

**Escenario:** Se han introducido problemas:
1. SSL mal configurado en MongoDB OnPrem
2. Usuario sin permisos suficientes
3. Firewall bloqueando conexión a DocumentDB

```bash
# Comandos de diagnóstico esperados
sudo systemctl status mongod
sudo tail -f /var/log/mongodb/mongod.log
mongosh --tls --tlsAllowInvalidCertificates
telnet $DOCDB_ENDPOINT 27017
```

**Criterios de evaluación:**
- Identifica problemas SSL (7 pts)
- Resuelve problemas de permisos (7 pts)
- Soluciona conectividad DocumentDB (6 pts)

---

## 📊 Rúbrica de Evaluación Final

### Distribución de Puntos
- **Ejercicio 1 - Instalación SSL:** 25 puntos
- **Ejercicio 2 - Usuarios y roles:** 25 puntos
- **Ejercicio 3 - Migración:** 30 puntos
- **Ejercicio 4 - Troubleshooting:** 20 puntos
- **Total:** 100 puntos

### Criterios de Aprobación
- **Excelente (90-100):** Domina instalación, seguridad, y migración MongoDB/DocumentDB
- **Bueno (80-89):** Maneja conceptos básicos, requiere ayuda en tareas avanzadas
- **Regular (70-79):** Instala y configura básicamente, dificultades con SSL y migración
- **Insuficiente (<70):** No logra instalación funcional o configuración de seguridad

Este laboratorio proporciona experiencia completa en MongoDB OnPrem y DocumentDB, incluyendo aspectos críticos de seguridad y migración híbrida.
