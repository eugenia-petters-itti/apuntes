// MongoDB Aggregation Diagnostic Script
// Escenario 04: Problemas de Performance en Aggregation Pipeline

print("=== MONGODB AGGREGATION DIAGNOSTIC REPORT ===");
print("Timestamp: " + new Date());
print("");

// 1. Verificar operaciones de agregación activas
print("1. ACTIVE AGGREGATION OPERATIONS");
print("=================================");
var currentOps = db.currentOp({
    "command.aggregate": {$exists: true},
    "secs_running": {$gte: 1}
});

if (currentOps.inprog.length > 0) {
    print("Currently running aggregation operations:");
    currentOps.inprog.forEach(function(op) {
        print("  Operation ID: " + op.opid);
        print("  Collection: " + op.ns);
        print("  Running time: " + op.secs_running + " seconds");
        print("  Client: " + op.client);
        
        if (op.command && op.command.pipeline) {
            print("  Pipeline stages: " + op.command.pipeline.length);
            print("  First stage: " + JSON.stringify(op.command.pipeline[0]));
        }
        
        if (op.planSummary) {
            print("  Plan: " + op.planSummary);
        }
        print("");
    });
} else {
    print("No long-running aggregation operations found");
}
print("");

// 2. Analizar aggregations desde el profiler
print("2. AGGREGATION PROFILER ANALYSIS");
print("=================================");
var profilerStatus = db.runCommand({profile: -1});
print("Profiler level: " + profilerStatus.was);

if (profilerStatus.was > 0) {
    var slowAggregations = db.system.profile.find({
        "command.aggregate": {$exists: true},
        "millis": {$gte: 100}
    }).sort({ts: -1}).limit(10);
    
    if (slowAggregations.hasNext()) {
        print("\nRecent slow aggregations:");
        slowAggregations.forEach(function(op) {
            print("  " + op.ts + " - " + op.ns);
            print("    Duration: " + op.millis + "ms");
            print("    Stages: " + (op.command.pipeline ? op.command.pipeline.length : "N/A"));
            
            if (op.keysExamined !== undefined) {
                print("    Keys examined: " + op.keysExamined);
            }
            if (op.docsExamined !== undefined) {
                print("    Docs examined: " + op.docsExamined);
            }
            if (op.nreturned !== undefined) {
                print("    Docs returned: " + op.nreturned);
            }
            
            // Mostrar pipeline si está disponible
            if (op.command.pipeline && op.command.pipeline.length > 0) {
                print("    Pipeline:");
                op.command.pipeline.forEach(function(stage, index) {
                    var stageKey = Object.keys(stage)[0];
                    print("      " + (index + 1) + ". " + stageKey);
                });
            }
            
            if (op.planSummary) {
                print("    Plan: " + op.planSummary);
            }
            print("");
        });
    } else {
        print("No slow aggregations found in profiler");
    }
} else {
    print("Profiler is disabled. Enable with: db.setProfilingLevel(1, {slowms: 100})");
}
print("");

// 3. Verificar uso de memoria en agregaciones
print("3. AGGREGATION MEMORY USAGE");
print("============================");
var serverStatus = db.serverStatus();

if (serverStatus.mem) {
    print("Server Memory Status:");
    print("  Resident: " + serverStatus.mem.resident + " MB");
    print("  Virtual: " + serverStatus.mem.virtual + " MB");
    print("  Mapped: " + (serverStatus.mem.mapped || "N/A") + " MB");
}

// Verificar configuración de memoria para agregaciones
try {
    var aggMemLimit = db.adminCommand({getParameter: 1, internalDocumentSourceGroupMaxMemoryBytes: 1});
    if (aggMemLimit.internalDocumentSourceGroupMaxMemoryBytes) {
        var limitMB = aggMemLimit.internalDocumentSourceGroupMaxMemoryBytes / 1024 / 1024;
        print("  Aggregation memory limit: " + limitMB + " MB");
    }
} catch (e) {
    print("  Aggregation memory limit: Default (100MB per stage)");
}
print("");

// 4. Analizar colecciones para optimización de agregaciones
print("4. COLLECTION ANALYSIS FOR AGGREGATION");
print("=======================================");
db.runCommand("listCollections").cursor.firstBatch.forEach(function(collection) {
    if (collection.type === "collection") {
        var collName = collection.name;
        var stats = db[collName].stats();
        
        if (stats.count > 1000) { // Solo colecciones grandes
            print("Collection: " + collName);
            print("  Documents: " + stats.count);
            print("  Avg doc size: " + (stats.avgObjSize / 1024).toFixed(2) + " KB");
            print("  Total size: " + (stats.size / 1024 / 1024).toFixed(2) + " MB");
            
            // Verificar índices útiles para agregaciones
            var indexes = db[collName].getIndexes();
            print("  Indexes: " + indexes.length);
            
            var hasCompoundIndex = false;
            indexes.forEach(function(index) {
                var keyCount = Object.keys(index.key).length;
                if (keyCount > 1) {
                    hasCompoundIndex = true;
                }
            });
            
            if (!hasCompoundIndex && indexes.length === 1) {
                print("    ⚠️  Only _id index - consider compound indexes for aggregations");
            }
            print("");
        }
    }
});

// 5. Verificar patrones comunes de agregación problemáticos
print("5. COMMON AGGREGATION ANTI-PATTERNS");
print("=====================================");
print("Checking for potential performance issues...");
print("");

// Simular algunos patrones comunes problemáticos
print("Common issues to check in your aggregations:");
print("• $lookup without proper indexing on foreign collection");
print("• $group operations on large datasets without initial $match");
print("• $sort operations without supporting indexes");
print("• $unwind on large arrays without $limit");
print("• Multiple $lookup stages in sequence");
print("• $facet with memory-intensive sub-pipelines");
print("");

// 6. Verificar configuración de agregación
print("6. AGGREGATION CONFIGURATION");
print("=============================");
try {
    // Verificar parámetros relacionados con agregación
    var params = db.adminCommand({
        getParameter: 1,
        internalDocumentSourceGroupMaxMemoryBytes: 1,
        internalQueryExecMaxBlockingSortMemoryUsageBytes: 1,
        maxIndexBuildMemoryUsageMegabytes: 1
    });
    
    Object.keys(params).forEach(function(param) {
        if (param !== "ok") {
            var value = params[param];
            if (typeof value === "number" && value > 1024 * 1024) {
                value = (value / 1024 / 1024).toFixed(0) + " MB";
            }
            print("  " + param + ": " + value);
        }
    });
    
} catch (e) {
    print("Unable to retrieve aggregation parameters: " + e.message);
}
print("");

// 7. Herramientas de diagnóstico para agregaciones
print("7. AGGREGATION DIAGNOSTIC TOOLS");
print("================================");
print("Performance Analysis:");
print("• Use explain('executionStats') with aggregate()");
print("• Monitor aggregation stages with $explain");
print("• Check index usage in $match and $sort stages");
print("• Profile slow aggregations with db.setProfilingLevel()");
print("");

print("Memory Optimization:");
print("• Use $match early in pipeline to reduce document count");
print("• Implement $limit after $sort when possible");
print("• Consider $sample for large dataset analysis");
print("• Use $project to reduce document size early");
print("");

print("Index Optimization:");
print("• Create indexes supporting $match conditions");
print("• Index fields used in $sort operations");
print("• Index foreign keys for $lookup operations");
print("• Consider partial indexes for filtered aggregations");
print("");

// 8. Comandos útiles para diagnóstico
print("8. USEFUL DIAGNOSTIC COMMANDS");
print("==============================");
print("Explain aggregation: db.collection.aggregate(pipeline, {explain: true})");
print("Current operations: db.currentOp({'command.aggregate': {$exists: true}})");
print("Memory stats: db.serverStatus().mem");
print("Profiler query: db.system.profile.find({'command.aggregate': {$exists: true}})");
print("Kill operation: db.killOp(opid)");
print("");

// 9. Ejemplo de agregación optimizada
print("9. OPTIMIZATION EXAMPLE");
print("=======================");
print("Instead of:");
print("  db.collection.aggregate([");
print("    {$group: {_id: '$category', total: {$sum: '$amount'}}},");
print("    {$match: {total: {$gte: 1000}}}");
print("  ])");
print("");
print("Use:");
print("  db.collection.aggregate([");
print("    {$match: {amount: {$gte: 100}}}, // Filter early");
print("    {$group: {_id: '$category', total: {$sum: '$amount'}}},");
print("    {$match: {total: {$gte: 1000}}}");
print("  ])");
print("");

print("=== END OF DIAGNOSTIC REPORT ===");
