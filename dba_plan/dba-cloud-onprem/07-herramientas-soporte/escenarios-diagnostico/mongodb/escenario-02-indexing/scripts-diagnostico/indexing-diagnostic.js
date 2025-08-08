// MongoDB Indexing Diagnostic Script
// Escenario 02: Problemas de Performance por Indexación

print("=== MONGODB INDEXING DIAGNOSTIC REPORT ===");
print("Timestamp: " + new Date());
print("");

// 1. Verificar índices por colección
print("1. INDEX ANALYSIS BY COLLECTION");
print("================================");
db.runCommand("listCollections").cursor.firstBatch.forEach(function(collection) {
    if (collection.type === "collection") {
        var collName = collection.name;
        print("Collection: " + collName);
        
        // Obtener estadísticas de la colección
        var stats = db[collName].stats();
        print("  Documents: " + stats.count);
        print("  Size: " + (stats.size / 1024 / 1024).toFixed(2) + " MB");
        
        // Listar índices
        var indexes = db[collName].getIndexes();
        print("  Indexes (" + indexes.length + "):");
        
        indexes.forEach(function(index) {
            print("    - " + index.name);
            print("      Keys: " + JSON.stringify(index.key));
            print("      Size: " + ((index.indexSizes && index.indexSizes[index.name]) ? 
                  (index.indexSizes[index.name] / 1024 / 1024).toFixed(2) + " MB" : "N/A"));
            
            if (index.sparse) print("      Sparse: true");
            if (index.unique) print("      Unique: true");
            if (index.partialFilterExpression) {
                print("      Partial: " + JSON.stringify(index.partialFilterExpression));
            }
            if (index.expireAfterSeconds) {
                print("      TTL: " + index.expireAfterSeconds + " seconds");
            }
        });
        print("");
    }
});

// 2. Verificar operaciones lentas
print("2. SLOW OPERATIONS ANALYSIS");
print("============================");
var currentOps = db.currentOp({"secs_running": {$gte: 1}});
if (currentOps.inprog.length > 0) {
    print("Currently running slow operations:");
    currentOps.inprog.forEach(function(op) {
        print("  Operation: " + op.op);
        print("  Namespace: " + op.ns);
        print("  Running time: " + op.secs_running + " seconds");
        if (op.planSummary) {
            print("  Plan: " + op.planSummary);
        }
        print("");
    });
} else {
    print("No slow operations currently running");
}
print("");

// 3. Analizar profiler (si está habilitado)
print("3. PROFILER ANALYSIS");
print("====================");
var profilerStatus = db.runCommand({profile: -1});
print("Profiler level: " + profilerStatus.was);
print("Slow operation threshold: " + profilerStatus.slowms + "ms");

if (profilerStatus.was > 0) {
    print("\nRecent slow operations from profiler:");
    var slowOps = db.system.profile.find().sort({ts: -1}).limit(10);
    
    slowOps.forEach(function(op) {
        print("  " + op.ts + " - " + op.op + " (" + op.ns + ")");
        print("    Duration: " + op.millis + "ms");
        if (op.planSummary) {
            print("    Plan: " + op.planSummary);
        }
        if (op.keysExamined !== undefined && op.docsExamined !== undefined) {
            print("    Keys examined: " + op.keysExamined);
            print("    Docs examined: " + op.docsExamined);
            print("    Docs returned: " + (op.nreturned || 0));
            
            // Calcular eficiencia
            if (op.nreturned > 0 && op.docsExamined > 0) {
                var efficiency = (op.nreturned / op.docsExamined * 100).toFixed(2);
                print("    Efficiency: " + efficiency + "%");
            }
        }
        print("");
    });
} else {
    print("Profiler is disabled. Enable with: db.setProfilingLevel(1, {slowms: 100})");
}
print("");

// 4. Verificar estadísticas de índices
print("4. INDEX USAGE STATISTICS");
print("=========================");
db.runCommand("listCollections").cursor.firstBatch.forEach(function(collection) {
    if (collection.type === "collection") {
        var collName = collection.name;
        try {
            var indexStats = db[collName].aggregate([{$indexStats: {}}]).toArray();
            
            if (indexStats.length > 0) {
                print("Collection: " + collName);
                indexStats.forEach(function(stat) {
                    print("  Index: " + stat.name);
                    print("    Accesses: " + stat.accesses.ops);
                    print("    Since: " + stat.accesses.since);
                    
                    // Detectar índices no utilizados
                    if (stat.accesses.ops === 0) {
                        print("    ⚠️  UNUSED INDEX - Consider dropping");
                    }
                });
                print("");
            }
        } catch (e) {
            // $indexStats no disponible en versiones antiguas
            print("Collection: " + collName + " - Index stats not available");
        }
    }
});

// 5. Detectar consultas sin índices
print("5. COLLECTION SCAN DETECTION");
print("=============================");
print("Checking for collections that might need indexes...");

db.runCommand("listCollections").cursor.firstBatch.forEach(function(collection) {
    if (collection.type === "collection") {
        var collName = collection.name;
        var stats = db[collName].stats();
        
        if (stats.count > 1000) { // Solo para colecciones grandes
            print("Collection: " + collName + " (" + stats.count + " docs)");
            
            // Verificar si solo tiene el índice _id
            var indexes = db[collName].getIndexes();
            if (indexes.length === 1 && indexes[0].name === "_id_") {
                print("  ⚠️  Only has _id index - may need additional indexes");
            }
            
            // Sugerir análisis de queries comunes
            print("  💡 Run explain() on common queries to check index usage");
        }
    }
});
print("");

// 6. Verificar fragmentación de índices
print("6. INDEX FRAGMENTATION ANALYSIS");
print("================================");
db.runCommand("listCollections").cursor.firstBatch.forEach(function(collection) {
    if (collection.type === "collection") {
        var collName = collection.name;
        try {
            var stats = db[collName].stats({indexDetails: true});
            
            if (stats.indexSizes) {
                print("Collection: " + collName);
                Object.keys(stats.indexSizes).forEach(function(indexName) {
                    var indexSize = stats.indexSizes[indexName];
                    print("  " + indexName + ": " + (indexSize / 1024 / 1024).toFixed(2) + " MB");
                });
                print("");
            }
        } catch (e) {
            // Continuar con la siguiente colección
        }
    }
});

// 7. Recomendaciones de optimización
print("7. OPTIMIZATION RECOMMENDATIONS");
print("================================");
print("Index Optimization Tips:");
print("• Drop unused indexes to improve write performance");
print("• Create compound indexes for multi-field queries");
print("• Use partial indexes for queries with common filters");
print("• Consider text indexes for search functionality");
print("• Monitor index hit ratios and query patterns");
print("• Use hint() to force specific index usage during testing");
print("");

print("Query Optimization Tips:");
print("• Use explain('executionStats') to analyze query performance");
print("• Ensure queries use indexes effectively (low docsExamined/nreturned ratio)");
print("• Consider query restructuring for better index utilization");
print("• Use projection to limit returned fields");
print("• Implement proper sorting strategies with indexes");
print("");

// 8. Comandos útiles para diagnóstico adicional
print("8. USEFUL DIAGNOSTIC COMMANDS");
print("==============================");
print("Enable profiler: db.setProfilingLevel(1, {slowms: 100})");
print("Analyze query: db.collection.find({query}).explain('executionStats')");
print("Index usage: db.collection.aggregate([{$indexStats: {}}])");
print("Current operations: db.currentOp({'secs_running': {$gte: 1}})");
print("Collection stats: db.collection.stats({indexDetails: true})");
print("");

print("=== END OF DIAGNOSTIC REPORT ===");
