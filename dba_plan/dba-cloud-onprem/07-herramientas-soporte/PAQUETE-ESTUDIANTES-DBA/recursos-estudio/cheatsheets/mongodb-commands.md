# 🍃 MongoDB Commands Cheatsheet
## Comandos Esenciales para DBAs

### 🔧 **CONEXIÓN Y BÁSICOS**
```javascript
// Conectar a MongoDB
mongo
mongo --host hostname:port

// Ver bases de datos
show dbs

// Usar base de datos
use database_name

// Ver colecciones
show collections

// Ver estadísticas de colección
db.collection.stats()
```

### 📊 **DIAGNÓSTICO DE PERFORMANCE**
```javascript
// Ver operaciones actuales
db.currentOp()

// Terminar operación
db.killOp(opid)

// Ver estadísticas del servidor
db.serverStatus()

// Profiler de queries
db.setProfilingLevel(2)
db.system.profile.find().pretty()

// Explicar query
db.collection.find().explain("executionStats")
```

### 🔍 **ÍNDICES**
```javascript
// Ver índices
db.collection.getIndexes()

// Crear índice
db.collection.createIndex({field: 1})

// Índice compuesto
db.collection.createIndex({field1: 1, field2: -1})

// Eliminar índice
db.collection.dropIndex({field: 1})

// Ver uso de índices
db.collection.aggregate([{$indexStats: {}}])
```

### 🔄 **REPLICA SETS**
```javascript
// Ver estado del replica set
rs.status()

// Ver configuración
rs.conf()

// Agregar miembro
rs.add("hostname:port")

// Forzar elección
rs.stepDown()
```
