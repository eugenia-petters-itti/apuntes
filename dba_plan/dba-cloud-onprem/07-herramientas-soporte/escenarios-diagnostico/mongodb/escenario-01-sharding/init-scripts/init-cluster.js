// Script de inicialización del cluster MongoDB con problemas de sharding
// Archivo: init-scripts/init-cluster.js

print("=== Iniciando configuración del cluster MongoDB ===");

// 1. Inicializar Config Server Replica Set
print("1. Configurando Config Server Replica Set...");
try {
    rs.initiate({
        _id: "configReplSet",
        configsvr: true,
        members: [
            { _id: 0, host: "config-server-1:27017" },
            { _id: 1, host: "config-server-2:27017" },
            { _id: 2, host: "config-server-3:27017" }
        ]
    });
    print("✅ Config Server Replica Set inicializado");
} catch (e) {
    print("⚠️ Config Server ya inicializado o error: " + e);
}

// Esperar a que el config server esté listo
sleep(10000);

// 2. Conectar a mongos y configurar shards
print("2. Conectando a mongos router...");
db = connect("mongos-router:27017/admin");

// 3. Inicializar Shard Replica Sets
print("3. Inicializando Shard Replica Sets...");

// Shard 1
print("3.1. Configurando Shard 1...");
try {
    db.runCommand({
        addShard: "shard1ReplSet/shard1-primary:27017,shard1-secondary:27017"
    });
    print("✅ Shard 1 agregado");
} catch (e) {
    print("⚠️ Shard 1 ya existe o error: " + e);
}

// Shard 2
print("3.2. Configurando Shard 2...");
try {
    db.runCommand({
        addShard: "shard2ReplSet/shard2-primary:27017,shard2-secondary:27017"
    });
    print("✅ Shard 2 agregado");
} catch (e) {
    print("⚠️ Shard 2 ya existe o error: " + e);
}

// Shard 3
print("3.3. Configurando Shard 3...");
try {
    db.runCommand({
        addShard: "shard3ReplSet/shard3-primary:27017,shard3-secondary:27017"
    });
    print("✅ Shard 3 agregado");
} catch (e) {
    print("⚠️ Shard 3 ya existe o error: " + e);
}

sleep(5000);

// 4. Habilitar sharding en la base de datos
print("4. Habilitando sharding en sensornet_db...");
try {
    db.runCommand({ enableSharding: "sensornet_db" });
    print("✅ Sharding habilitado en sensornet_db");
} catch (e) {
    print("⚠️ Sharding ya habilitado o error: " + e);
}

// 5. Configurar sharding problemático en las colecciones
print("5. Configurando shard keys problemáticas...");

// 5.1. Sensor readings con shard key problemática (causa hotspots)
print("5.1. Configurando sensor_readings con shard key problemática...");
try {
    db.runCommand({
        shardCollection: "sensornet_db.sensor_readings",
        key: { sensor_id: 1 }  // PROBLEMÁTICO: Causa hotspots
    });
    print("✅ sensor_readings sharded con sensor_id");
} catch (e) {
    print("⚠️ sensor_readings ya sharded o error: " + e);
}

// 5.2. Device metadata con shard key subóptima
print("5.2. Configurando device_metadata...");
try {
    db.runCommand({
        shardCollection: "sensornet_db.device_metadata",
        key: { device_id: 1 }  // PROBLEMÁTICO: Similar distribución
    });
    print("✅ device_metadata sharded con device_id");
} catch (e) {
    print("⚠️ device_metadata ya sharded o error: " + e);
}

// 5.3. Aggregated metrics con timestamp (mejor, pero no perfecto)
print("5.3. Configurando aggregated_metrics...");
try {
    db.runCommand({
        shardCollection: "sensornet_db.aggregated_metrics",
        key: { timestamp: 1 }  // PROBLEMÁTICO: Monotónico
    });
    print("✅ aggregated_metrics sharded con timestamp");
} catch (e) {
    print("⚠️ aggregated_metrics ya sharded o error: " + e);
}

// 6. CONFIGURACIÓN PROBLEMÁTICA: Chunk size muy grande
print("6. Configurando chunk size problemático...");
try {
    db.settings.save({ _id: "chunksize", value: 1024 }); // 1GB chunks (MUY GRANDE)
    print("✅ Chunk size configurado a 1GB (problemático)");
} catch (e) {
    print("⚠️ Error configurando chunk size: " + e);
}

// 7. PROBLEMA CRÍTICO: Deshabilitar el balancer
print("7. DESHABILITANDO el balancer (causa principal del problema)...");
try {
    sh.stopBalancer();
    print("🚨 BALANCER DESHABILITADO - Esto causará desbalance");
} catch (e) {
    print("⚠️ Error deshabilitando balancer: " + e);
}

// 8. Verificar estado del cluster
print("8. Verificando estado del cluster...");
try {
    printjson(sh.status());
} catch (e) {
    print("⚠️ Error obteniendo status: " + e);
}

// 9. Crear índices adicionales para performance
print("9. Creando índices...");
db = db.getSiblingDB("sensornet_db");

try {
    db.sensor_readings.createIndex({ sensor_id: 1, timestamp: -1 });
    db.sensor_readings.createIndex({ device_type: 1, timestamp: -1 });
    db.device_metadata.createIndex({ device_type: 1, location: 1 });
    db.aggregated_metrics.createIndex({ metric_type: 1, timestamp: -1 });
    print("✅ Índices creados");
} catch (e) {
    print("⚠️ Error creando índices: " + e);
}

print("=== Configuración del cluster completada ===");
print("🚨 CLUSTER CONFIGURADO CON PROBLEMAS INTENCIONADOS:");
print("   - Balancer deshabilitado");
print("   - Chunk size muy grande (1GB)");
print("   - Shard keys que causan hotspots");
print("   - Distribución desigual esperada");
print("=== Listo para diagnóstico ===");
