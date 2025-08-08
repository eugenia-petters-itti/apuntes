// MongoDB Sharding Diagnostic Script
// Escenario 01: Problemas de Sharding y Distribución de Datos

print("=== MONGODB SHARDING DIAGNOSTIC REPORT ===");
print("Timestamp: " + new Date());
print("");

// 1. Verificar estado del cluster
print("1. CLUSTER STATUS");
print("==================");
try {
    var shardStatus = sh.status();
    print("✓ Cluster status retrieved successfully");
} catch (e) {
    print("✗ Error getting cluster status: " + e);
}
print("");

// 2. Verificar configuración de shards
print("2. SHARD CONFIGURATION");
print("======================");
db.adminCommand("listShards").shards.forEach(function(shard) {
    print("Shard: " + shard._id);
    print("  Host: " + shard.host);
    print("  State: " + shard.state);
    print("  Tags: " + JSON.stringify(shard.tags || {}));
    print("");
});

// 3. Verificar balanceador
print("3. BALANCER STATUS");
print("==================");
var balancerStatus = sh.getBalancerState();
print("Balancer enabled: " + balancerStatus);

if (balancerStatus) {
    var balancerRunning = sh.isBalancerRunning();
    print("Balancer running: " + balancerRunning);
    
    // Verificar ventana de balanceo
    var balancerWindow = db.settings.findOne({_id: "balancer"});
    if (balancerWindow && balancerWindow.activeWindow) {
        print("Active window: " + JSON.stringify(balancerWindow.activeWindow));
    }
}
print("");

// 4. Verificar distribución de chunks
print("4. CHUNK DISTRIBUTION");
print("=====================");
db.runCommand("listCollections").cursor.firstBatch.forEach(function(collection) {
    if (collection.type === "collection") {
        var collName = collection.name;
        var shardKey = db[collName].getShardDistribution;
        
        if (typeof shardKey === "function") {
            print("Collection: " + collName);
            try {
                db[collName].getShardDistribution();
            } catch (e) {
                print("  Not sharded or error: " + e.message);
            }
            print("");
        }
    }
});

// 5. Verificar operaciones de chunk en progreso
print("5. CHUNK OPERATIONS");
print("===================");
var chunkOps = db.getSiblingDB("config").locks.find({
    "state": {$ne: 0},
    "_id": /^.*chunk.*$/
});

if (chunkOps.hasNext()) {
    print("Active chunk operations:");
    chunkOps.forEach(function(op) {
        print("  " + op._id + " - State: " + op.state);
    });
} else {
    print("No active chunk operations");
}
print("");

// 6. Verificar historial de migraciones
print("6. RECENT MIGRATIONS");
print("====================");
var recentMigrations = db.getSiblingDB("config").changelog.find({
    "time": {$gte: new Date(Date.now() - 24*60*60*1000)} // Últimas 24 horas
}).sort({"time": -1}).limit(10);

if (recentMigrations.hasNext()) {
    print("Recent migrations (last 24h):");
    recentMigrations.forEach(function(migration) {
        print("  " + migration.time + " - " + migration.what + 
              " (" + migration.ns + ")");
    });
} else {
    print("No recent migrations found");
}
print("");

// 7. Verificar sharded collections
print("7. SHARDED COLLECTIONS");
print("======================");
db.getSiblingDB("config").collections.find().forEach(function(coll) {
    print("Collection: " + coll._id);
    print("  Shard key: " + JSON.stringify(coll.key));
    print("  Unique: " + (coll.unique || false));
    print("  Dropped: " + (coll.dropped || false));
    print("");
});

// 8. Verificar estadísticas de conexiones por shard
print("8. CONNECTION STATISTICS");
print("========================");
db.adminCommand("listShards").shards.forEach(function(shard) {
    print("Shard: " + shard._id);
    try {
        var conn = new Mongo(shard.host);
        var stats = conn.getDB("admin").runCommand("serverStatus");
        print("  Connections current: " + stats.connections.current);
        print("  Connections available: " + stats.connections.available);
        print("  Operations/sec: " + (stats.opcounters.query + stats.opcounters.insert + 
                                    stats.opcounters.update + stats.opcounters.delete));
    } catch (e) {
        print("  Error connecting to shard: " + e);
    }
    print("");
});

// 9. Verificar configuración de zonas (si aplica)
print("9. ZONE CONFIGURATION");
print("=====================");
var zones = db.getSiblingDB("config").tags.find();
if (zones.hasNext()) {
    zones.forEach(function(zone) {
        print("Zone: " + zone.tag);
        print("  Shard: " + zone.shard);
        print("  Namespace: " + zone.ns);
        print("  Range: " + JSON.stringify(zone.min) + " -> " + JSON.stringify(zone.max));
        print("");
    });
} else {
    print("No zones configured");
}
print("");

// 10. Recomendaciones de diagnóstico
print("10. DIAGNOSTIC RECOMMENDATIONS");
print("===============================");
print("• Check for uneven chunk distribution");
print("• Monitor balancer activity and performance");
print("• Verify shard key effectiveness");
print("• Review migration patterns and timing");
print("• Monitor connection pool usage per shard");
print("• Check for hot spots in data distribution");
print("");

print("=== END OF DIAGNOSTIC REPORT ===");
