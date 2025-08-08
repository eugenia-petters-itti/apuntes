// MongoDB Sharding Problem Creation Script
// Este script crea condiciones problemáticas para diagnóstico

print("=== CREATING SHARDING PROBLEM SCENARIO ===");
print("Timestamp: " + new Date());
print("");

// 1. Crear una colección con distribución desigual
print("1. Creating uneven data distribution...");
use testSharding;

// Crear colección con shard key problemático
db.unevenData.drop();
sh.shardCollection("testSharding.unevenData", {status: 1});

// Insertar datos que se concentrarán en un solo shard
print("Inserting data that will concentrate on one shard...");
for (let i = 0; i < 10000; i++) {
    db.unevenData.insertOne({
        _id: i,
        status: "active", // Todos los documentos tendrán el mismo valor
        data: "x".repeat(100),
        timestamp: new Date(),
        value: Math.random() * 1000
    });
}

// Insertar pocos documentos con otros estados
for (let i = 10000; i < 10100; i++) {
    db.unevenData.insertOne({
        _id: i,
        status: "inactive",
        data: "y".repeat(100),
        timestamp: new Date(),
        value: Math.random() * 1000
    });
}

print("✓ Created collection with uneven distribution");

// 2. Deshabilitar el balanceador temporalmente
print("\n2. Disabling balancer to create imbalance...");
try {
    sh.disableBalancing("testSharding.unevenData");
    print("✓ Balancer disabled for collection");
} catch (e) {
    print("⚠️  Could not disable balancer: " + e);
}

// 3. Crear chunks manualmente para forzar distribución problemática
print("\n3. Creating problematic chunk distribution...");
try {
    // Dividir en chunks pequeños
    sh.splitAt("testSharding.unevenData", {status: "active"});
    sh.splitAt("testSharding.unevenData", {status: "inactive"});
    print("✓ Created manual splits");
} catch (e) {
    print("⚠️  Could not create splits: " + e);
}

// 4. Crear consultas que causarán scatter-gather
print("\n4. Creating queries that will cause scatter-gather operations...");
db.problematicQueries.drop();
db.problematicQueries.insertMany([
    {
        query: "db.unevenData.find({value: {$gte: 500}})",
        description: "Query without shard key - will hit all shards"
    },
    {
        query: "db.unevenData.aggregate([{$group: {_id: null, total: {$sum: '$value'}}}])",
        description: "Aggregation without $match on shard key"
    },
    {
        query: "db.unevenData.find().sort({timestamp: -1}).limit(10)",
        description: "Sort without shard key - expensive operation"
    }
]);

print("✓ Created problematic query examples");

// 5. Simular conexiones múltiples que pueden causar problemas
print("\n5. Simulating connection issues...");
try {
    // Crear múltiples conexiones simuladas
    for (let i = 0; i < 50; i++) {
        db.connectionTest.insertOne({
            connectionId: i,
            timestamp: new Date(),
            status: "connected"
        });
    }
    print("✓ Simulated multiple connections");
} catch (e) {
    print("⚠️  Connection simulation failed: " + e);
}

// 6. Crear datos de configuración problemáticos
print("\n6. Creating configuration issues...");
db.configIssues.drop();
db.configIssues.insertMany([
    {
        issue: "uneven_chunks",
        description: "Chunks are not evenly distributed across shards",
        severity: "high",
        impact: "Performance degradation on specific shards"
    },
    {
        issue: "poor_shard_key",
        description: "Shard key has low cardinality causing hotspots",
        severity: "critical",
        impact: "Most data concentrated on single shard"
    },
    {
        issue: "balancer_disabled",
        description: "Balancer is disabled preventing automatic rebalancing",
        severity: "medium",
        impact: "Manual intervention required for balancing"
    }
]);

print("✓ Created configuration issue documentation");

// 7. Información para el diagnóstico
print("\n7. PROBLEM SCENARIO SUMMARY");
print("============================");
print("Created the following issues:");
print("• Uneven data distribution (10,000 'active' vs 100 'inactive')");
print("• Poor shard key choice (low cardinality)");
print("• Balancer disabled for the collection");
print("• Queries that will cause scatter-gather operations");
print("• Simulated connection pressure");
print("");

print("To diagnose these issues, run:");
print("• sh.status() - Check cluster status");
print("• db.unevenData.getShardDistribution() - Check data distribution");
print("• sh.isBalancerRunning() - Check balancer status");
print("• db.currentOp() - Check for long-running operations");
print("");

print("Expected symptoms:");
print("• Uneven chunk distribution across shards");
print("• High load on one shard");
print("• Slow query performance");
print("• Balancer not running for this collection");
print("");

print("=== PROBLEM SCENARIO CREATED ===");
