// MongoDB Storage Diagnostic Script
// Escenario 05: Problemas de Storage y Espacio en Disco

print("=== MONGODB STORAGE DIAGNOSTIC REPORT ===");
print("Timestamp: " + new Date());
print("");

// 1. Verificar estadísticas generales de storage
print("1. STORAGE OVERVIEW");
print("===================");
try {
    var dbStats = db.stats();
    print("Database: " + db.getName());
    print("Collections: " + dbStats.collections);
    print("Objects: " + dbStats.objects);
    print("Data Size: " + (dbStats.dataSize / 1024 / 1024 / 1024).toFixed(2) + " GB");
    print("Storage Size: " + (dbStats.storageSize / 1024 / 1024 / 1024).toFixed(2) + " GB");
    print("Index Size: " + (dbStats.indexSize / 1024 / 1024 / 1024).toFixed(2) + " GB");
    print("Total Size: " + (dbStats.fsUsedSize / 1024 / 1024 / 1024).toFixed(2) + " GB");
    print("Free Space: " + (dbStats.fsTotalSize - dbStats.fsUsedSize) / 1024 / 1024 / 1024).toFixed(2) + " GB");
    
    // Calcular eficiencia de storage
    var efficiency = ((dbStats.dataSize / dbStats.storageSize) * 100).toFixed(2);
    print("Storage Efficiency: " + efficiency + "%");
    
    if (efficiency < 50) {
        print("⚠️  Low storage efficiency - consider compaction");
    }
    
} catch (e) {
    print("✗ Error getting database stats: " + e);
}
print("");

// 2. Análisis por colección
print("2. COLLECTION STORAGE ANALYSIS");
print("===============================");
var totalDataSize = 0;
var totalStorageSize = 0;
var totalIndexSize = 0;

db.runCommand("listCollections").cursor.firstBatch.forEach(function(collection) {
    if (collection.type === "collection") {
        var collName = collection.name;
        try {
            var stats = db[collName].stats();
            
            print("Collection: " + collName);
            print("  Documents: " + stats.count);
            print("  Data Size: " + (stats.size / 1024 / 1024).toFixed(2) + " MB");
            print("  Storage Size: " + (stats.storageSize / 1024 / 1024).toFixed(2) + " MB");
            print("  Index Size: " + (stats.totalIndexSize / 1024 / 1024).toFixed(2) + " MB");
            print("  Avg Doc Size: " + (stats.avgObjSize / 1024).toFixed(2) + " KB");
            
            // Calcular fragmentación
            if (stats.storageSize > 0) {
                var fragmentation = ((stats.storageSize - stats.size) / stats.storageSize * 100).toFixed(2);
                print("  Fragmentation: " + fragmentation + "%");
                
                if (fragmentation > 25) {
                    print("    ⚠️  High fragmentation - consider compaction");
                }
            }
            
            // Verificar índices grandes
            if (stats.totalIndexSize > stats.size) {
                print("    ⚠️  Index size larger than data size");
            }
            
            totalDataSize += stats.size;
            totalStorageSize += stats.storageSize;
            totalIndexSize += stats.totalIndexSize;
            
        } catch (e) {
            print("  ✗ Error getting stats for " + collName + ": " + e);
        }
        print("");
    }
});

print("TOTALS:");
print("  Total Data: " + (totalDataSize / 1024 / 1024 / 1024).toFixed(2) + " GB");
print("  Total Storage: " + (totalStorageSize / 1024 / 1024 / 1024).toFixed(2) + " GB");
print("  Total Indexes: " + (totalIndexSize / 1024 / 1024 / 1024).toFixed(2) + " GB");
print("");

// 3. Verificar storage engine
print("3. STORAGE ENGINE INFORMATION");
print("==============================");
try {
    var serverStatus = db.serverStatus();
    print("Storage Engine: " + serverStatus.storageEngine.name);
    
    if (serverStatus.storageEngine.name === "wiredTiger") {
        print("\nWiredTiger Statistics:");
        var wt = serverStatus.wiredTiger;
        
        if (wt.cache) {
            print("  Cache Size: " + (wt.cache["maximum bytes configured"] / 1024 / 1024).toFixed(0) + " MB");
            print("  Cache Used: " + (wt.cache["bytes currently in the cache"] / 1024 / 1024).toFixed(0) + " MB");
            print("  Cache Dirty: " + (wt.cache["tracked dirty bytes in the cache"] / 1024 / 1024).toFixed(0) + " MB");
            
            var cacheUtilization = (wt.cache["bytes currently in the cache"] / wt.cache["maximum bytes configured"] * 100).toFixed(2);
            print("  Cache Utilization: " + cacheUtilization + "%");
            
            if (cacheUtilization > 95) {
                print("    ⚠️  Cache nearly full - may impact performance");
            }
        }
        
        if (wt.block_manager) {
            print("  Blocks Read: " + wt.block_manager["blocks read"]);
            print("  Blocks Written: " + wt.block_manager["blocks written"]);
        }
        
        if (wt.transaction) {
            print("  Transactions Begun: " + wt.transaction["transaction begins"]);
            print("  Transactions Committed: " + wt.transaction["transaction commits"]);
            print("  Transactions Rolled Back: " + wt.transaction["transaction rollbacks"]);
        }
    }
    
} catch (e) {
    print("✗ Error getting storage engine info: " + e);
}
print("");

// 4. Verificar espacio en disco del sistema
print("4. DISK SPACE ANALYSIS");
print("======================");
try {
    var diskStats = db.runCommand({dbStats: 1});
    
    if (diskStats.fsUsedSize && diskStats.fsTotalSize) {
        var usedGB = (diskStats.fsUsedSize / 1024 / 1024 / 1024).toFixed(2);
        var totalGB = (diskStats.fsTotalSize / 1024 / 1024 / 1024).toFixed(2);
        var freeGB = ((diskStats.fsTotalSize - diskStats.fsUsedSize) / 1024 / 1024 / 1024).toFixed(2);
        var usagePercent = ((diskStats.fsUsedSize / diskStats.fsTotalSize) * 100).toFixed(2);
        
        print("Filesystem Usage:");
        print("  Total: " + totalGB + " GB");
        print("  Used: " + usedGB + " GB (" + usagePercent + "%)");
        print("  Free: " + freeGB + " GB");
        
        if (usagePercent > 90) {
            print("  🚨 CRITICAL: Disk usage over 90%");
        } else if (usagePercent > 80) {
            print("  ⚠️  WARNING: Disk usage over 80%");
        } else {
            print("  ✓ Disk usage normal");
        }
    }
    
} catch (e) {
    print("Disk space information not available: " + e.message);
}
print("");

// 5. Verificar operaciones de I/O
print("5. I/O OPERATIONS ANALYSIS");
print("===========================");
try {
    var serverStatus = db.serverStatus();
    
    if (serverStatus.opcounters) {
        print("Operation Counters:");
        print("  Inserts: " + serverStatus.opcounters.insert);
        print("  Queries: " + serverStatus.opcounters.query);
        print("  Updates: " + serverStatus.opcounters.update);
        print("  Deletes: " + serverStatus.opcounters.delete);
        print("  Commands: " + serverStatus.opcounters.command);
    }
    
    if (serverStatus.globalLock) {
        print("\nGlobal Lock:");
        print("  Total Time: " + serverStatus.globalLock.totalTime + " μs");
        if (serverStatus.globalLock.currentQueue) {
            print("  Current Queue Total: " + serverStatus.globalLock.currentQueue.total);
            print("  Current Queue Readers: " + serverStatus.globalLock.currentQueue.readers);
            print("  Current Queue Writers: " + serverStatus.globalLock.currentQueue.writers);
        }
    }
    
} catch (e) {
    print("✗ Error getting I/O statistics: " + e);
}
print("");

// 6. Verificar journal y durabilidad
print("6. JOURNAL AND DURABILITY");
print("==========================");
try {
    var serverStatus = db.serverStatus();
    
    if (serverStatus.dur) {
        print("Journal Status:");
        print("  Commits: " + serverStatus.dur.commits);
        print("  Journal MB: " + (serverStatus.dur.journaledMB || 0));
        print("  Write to Data Files MB: " + (serverStatus.dur.writeToDataFilesMB || 0));
        print("  Compression: " + (serverStatus.dur.compression || "N/A"));
        
        if (serverStatus.dur.timeMs) {
            print("  Time in Journal (ms): " + serverStatus.dur.timeMs.dt);
            print("  Time in Write Lock (ms): " + serverStatus.dur.timeMs.writeToJournal);
        }
    } else {
        print("Journal information not available (may be disabled)");
    }
    
} catch (e) {
    print("✗ Error getting journal info: " + e);
}
print("");

// 7. Verificar compactación y mantenimiento
print("7. COMPACTION AND MAINTENANCE");
print("==============================");
print("Collections that may benefit from compaction:");

db.runCommand("listCollections").cursor.firstBatch.forEach(function(collection) {
    if (collection.type === "collection") {
        var collName = collection.name;
        try {
            var stats = db[collName].stats();
            
            if (stats.storageSize > 0) {
                var fragmentation = ((stats.storageSize - stats.size) / stats.storageSize * 100);
                var sizeMB = stats.storageSize / 1024 / 1024;
                
                if (fragmentation > 25 && sizeMB > 100) {
                    print("  " + collName + ": " + fragmentation.toFixed(2) + "% fragmented (" + 
                          sizeMB.toFixed(0) + " MB)");
                }
            }
        } catch (e) {
            // Continuar con la siguiente colección
        }
    }
});
print("");

// 8. Recomendaciones de optimización
print("8. STORAGE OPTIMIZATION RECOMMENDATIONS");
print("========================================");
print("Immediate Actions:");
print("• Monitor disk space regularly (set alerts at 80% usage)");
print("• Consider compaction for highly fragmented collections");
print("• Review and optimize large indexes");
print("• Implement data archiving for old documents");
print("");

print("Performance Optimization:");
print("• Adjust WiredTiger cache size if needed");
print("• Monitor I/O patterns and optimize accordingly");
print("• Consider sharding for very large collections");
print("• Implement proper index maintenance");
print("");

print("Maintenance Commands:");
print("• Compact collection: db.collection.compact()");
print("• Repair database: db.repairDatabase() (use with caution)");
print("• Reindex collection: db.collection.reIndex()");
print("• Check collection: db.collection.validate()");
print("");

print("Monitoring:");
print("• Set up disk space monitoring");
print("• Monitor cache hit ratios");
print("• Track fragmentation levels");
print("• Monitor I/O wait times");
print("");

// 9. Comandos útiles para diagnóstico adicional
print("9. USEFUL DIAGNOSTIC COMMANDS");
print("==============================");
print("Collection stats: db.collection.stats()");
print("Database stats: db.stats()");
print("Server status: db.serverStatus()");
print("Validate collection: db.collection.validate({full: true})");
print("Current operations: db.currentOp()");
print("Profiler status: db.getProfilingStatus()");
print("");

print("=== END OF DIAGNOSTIC REPORT ===");
