// MongoDB Index Analyzer Tool
// Herramienta para análisis detallado de índices y performance

function analyzeIndexUsage(collectionName) {
    print("=== INDEX USAGE ANALYZER ===");
    print("Collection: " + collectionName);
    print("Timestamp: " + new Date());
    print("");
    
    try {
        var collection = db.getCollection(collectionName);
        
        // Obtener estadísticas de uso de índices
        var indexStats = collection.aggregate([{$indexStats: {}}]).toArray();
        
        if (indexStats.length === 0) {
            print("❌ No index statistics available");
            return;
        }
        
        print("📊 INDEX USAGE STATISTICS");
        print("=========================");
        
        var unusedIndexes = [];
        var lowUsageIndexes = [];
        
        indexStats.forEach(function(stat) {
            var usage = stat.accesses.ops;
            var indexName = stat.name;
            
            print("Index: " + indexName);
            print("  Operations: " + usage);
            print("  Since: " + stat.accesses.since);
            
            if (usage === 0 && indexName !== "_id_") {
                print("  ⚠️  UNUSED - Consider dropping");
                unusedIndexes.push(indexName);
            } else if (usage < 10 && indexName !== "_id_") {
                print("  ⚡ LOW USAGE - Review necessity");
                lowUsageIndexes.push(indexName);
            } else {
                print("  ✅ ACTIVE");
            }
            print("");
        });
        
        // Resumen de recomendaciones
        if (unusedIndexes.length > 0 || lowUsageIndexes.length > 0) {
            print("🔧 RECOMMENDATIONS");
            print("==================");
            
            if (unusedIndexes.length > 0) {
                print("Unused indexes to consider dropping:");
                unusedIndexes.forEach(function(idx) {
                    print("  db." + collectionName + ".dropIndex('" + idx + "')");
                });
                print("");
            }
            
            if (lowUsageIndexes.length > 0) {
                print("Low usage indexes to review:");
                lowUsageIndexes.forEach(function(idx) {
                    print("  " + idx + " - Verify if still needed");
                });
            }
        }
        
    } catch (e) {
        print("❌ Error analyzing index usage: " + e);
    }
}

function analyzeIndexEfficiency(collectionName) {
    print("\n=== INDEX EFFICIENCY ANALYZER ===");
    
    try {
        var collection = db.getCollection(collectionName);
        var indexes = collection.getIndexes();
        var stats = collection.stats();
        
        print("📈 EFFICIENCY METRICS");
        print("=====================");
        print("Total documents: " + stats.count);
        print("Total indexes: " + indexes.length);
        print("Index size: " + (stats.totalIndexSize / 1024 / 1024).toFixed(2) + " MB");
        print("Data size: " + (stats.size / 1024 / 1024).toFixed(2) + " MB");
        
        var indexToDataRatio = (stats.totalIndexSize / stats.size * 100).toFixed(2);
        print("Index/Data ratio: " + indexToDataRatio + "%");
        
        if (indexToDataRatio > 50) {
            print("⚠️  High index overhead - review index necessity");
        } else if (indexToDataRatio > 25) {
            print("⚡ Moderate index overhead - acceptable");
        } else {
            print("✅ Low index overhead - efficient");
        }
        
        print("\n📋 INDEX DETAILS");
        print("================");
        
        indexes.forEach(function(index) {
            print("Index: " + index.name);
            print("  Keys: " + JSON.stringify(index.key));
            
            var keyCount = Object.keys(index.key).length;
            if (keyCount > 3) {
                print("  ⚠️  Complex compound index (" + keyCount + " fields)");
            }
            
            if (index.sparse) {
                print("  📍 Sparse index");
            }
            if (index.unique) {
                print("  🔒 Unique constraint");
            }
            if (index.partialFilterExpression) {
                print("  🎯 Partial index: " + JSON.stringify(index.partialFilterExpression));
            }
            if (index.expireAfterSeconds) {
                print("  ⏰ TTL: " + index.expireAfterSeconds + "s");
            }
            print("");
        });
        
    } catch (e) {
        print("❌ Error analyzing index efficiency: " + e);
    }
}

function findDuplicateIndexes(collectionName) {
    print("\n=== DUPLICATE INDEX DETECTOR ===");
    
    try {
        var collection = db.getCollection(collectionName);
        var indexes = collection.getIndexes();
        
        print("🔍 CHECKING FOR REDUNDANT INDEXES");
        print("==================================");
        
        var duplicates = [];
        var prefixDuplicates = [];
        
        for (let i = 0; i < indexes.length; i++) {
            for (let j = i + 1; j < indexes.length; j++) {
                var idx1 = indexes[i];
                var idx2 = indexes[j];
                
                // Verificar duplicados exactos
                if (JSON.stringify(idx1.key) === JSON.stringify(idx2.key)) {
                    duplicates.push([idx1.name, idx2.name]);
                }
                
                // Verificar prefijos redundantes
                var keys1 = Object.keys(idx1.key);
                var keys2 = Object.keys(idx2.key);
                
                if (keys1.length < keys2.length) {
                    var isPrefix = keys1.every(function(key, index) {
                        return keys2[index] === key && idx1.key[key] === idx2.key[key];
                    });
                    
                    if (isPrefix) {
                        prefixDuplicates.push([idx1.name, idx2.name, "prefix"]);
                    }
                } else if (keys2.length < keys1.length) {
                    var isPrefix = keys2.every(function(key, index) {
                        return keys1[index] === key && idx2.key[key] === idx1.key[key];
                    });
                    
                    if (isPrefix) {
                        prefixDuplicates.push([idx2.name, idx1.name, "prefix"]);
                    }
                }
            }
        }
        
        if (duplicates.length === 0 && prefixDuplicates.length === 0) {
            print("✅ No duplicate indexes found");
        } else {
            if (duplicates.length > 0) {
                print("❌ EXACT DUPLICATES FOUND:");
                duplicates.forEach(function(dup) {
                    print("  " + dup[0] + " ≡ " + dup[1]);
                    print("    Consider dropping one of these indexes");
                });
                print("");
            }
            
            if (prefixDuplicates.length > 0) {
                print("⚠️  PREFIX REDUNDANCY FOUND:");
                prefixDuplicates.forEach(function(dup) {
                    print("  " + dup[0] + " is prefix of " + dup[1]);
                    print("    Consider dropping " + dup[0] + " if " + dup[1] + " serves the same queries");
                });
            }
        }
        
    } catch (e) {
        print("❌ Error checking for duplicates: " + e);
    }
}

function analyzeSlowQueries(collectionName) {
    print("\n=== SLOW QUERY ANALYZER ===");
    
    try {
        // Verificar si el profiler está habilitado
        var profilerStatus = db.getProfilingStatus();
        
        if (profilerStatus.was === 0) {
            print("⚠️  Profiler is disabled. Enable with:");
            print("   db.setProfilingLevel(1, {slowms: 100})");
            return;
        }
        
        print("🐌 SLOW QUERIES ANALYSIS");
        print("========================");
        print("Profiler level: " + profilerStatus.was);
        print("Slow threshold: " + profilerStatus.slowms + "ms");
        print("");
        
        // Buscar consultas lentas para esta colección
        var slowQueries = db.system.profile.find({
            "ns": db.getName() + "." + collectionName,
            "millis": {$gte: profilerStatus.slowms}
        }).sort({ts: -1}).limit(10);
        
        if (!slowQueries.hasNext()) {
            print("✅ No slow queries found for this collection");
            return;
        }
        
        print("Recent slow queries:");
        var queryCount = 0;
        
        slowQueries.forEach(function(query) {
            queryCount++;
            print("\n" + queryCount + ". " + query.ts);
            print("   Duration: " + query.millis + "ms");
            print("   Operation: " + query.op);
            
            if (query.keysExamined !== undefined && query.docsExamined !== undefined) {
                print("   Keys examined: " + query.keysExamined);
                print("   Docs examined: " + query.docsExamined);
                print("   Docs returned: " + (query.nreturned || 0));
                
                // Calcular eficiencia
                if (query.nreturned > 0 && query.docsExamined > 0) {
                    var efficiency = (query.nreturned / query.docsExamined * 100).toFixed(2);
                    print("   Efficiency: " + efficiency + "%");
                    
                    if (efficiency < 10) {
                        print("   ❌ VERY INEFFICIENT - Needs index optimization");
                    } else if (efficiency < 50) {
                        print("   ⚠️  INEFFICIENT - Consider index improvements");
                    }
                }
            }
            
            if (query.planSummary) {
                print("   Plan: " + query.planSummary);
                
                if (query.planSummary.includes("COLLSCAN")) {
                    print("   ❌ COLLECTION SCAN - Needs index");
                } else if (query.planSummary.includes("SORT")) {
                    print("   ⚠️  IN-MEMORY SORT - Consider sort-supporting index");
                }
            }
            
            // Mostrar la consulta si está disponible
            if (query.command) {
                if (query.command.find) {
                    print("   Query: " + JSON.stringify(query.command.filter || {}));
                } else if (query.command.aggregate) {
                    print("   Pipeline stages: " + query.command.pipeline.length);
                }
            }
        });
        
    } catch (e) {
        print("❌ Error analyzing slow queries: " + e);
    }
}

function generateIndexReport(collectionName) {
    print("=== COMPREHENSIVE INDEX REPORT ===");
    print("Collection: " + collectionName);
    print("Generated: " + new Date());
    print("");
    
    analyzeIndexUsage(collectionName);
    analyzeIndexEfficiency(collectionName);
    findDuplicateIndexes(collectionName);
    analyzeSlowQueries(collectionName);
    
    print("\n=== END OF REPORT ===");
}

function suggestIndexOptimizations(collectionName) {
    print("\n=== INDEX OPTIMIZATION SUGGESTIONS ===");
    
    try {
        var collection = db.getCollection(collectionName);
        
        print("🎯 OPTIMIZATION STRATEGIES");
        print("==========================");
        
        print("1. Query Pattern Analysis:");
        print("   • Identify most common query patterns");
        print("   • Create compound indexes for multi-field queries");
        print("   • Ensure sort fields are included in indexes");
        print("");
        
        print("2. Index Maintenance:");
        print("   • Drop unused indexes to improve write performance");
        print("   • Consolidate redundant indexes");
        print("   • Use partial indexes for filtered queries");
        print("");
        
        print("3. Performance Monitoring:");
        print("   • Enable profiler: db.setProfilingLevel(1, {slowms: 100})");
        print("   • Monitor index hit ratios");
        print("   • Use explain() to verify index usage");
        print("");
        
        print("4. Specific Commands:");
        print("   • Analyze query: db." + collectionName + ".find({}).explain('executionStats')");
        print("   • Index stats: db." + collectionName + ".aggregate([{$indexStats: {}}])");
        print("   • Reindex: db." + collectionName + ".reIndex()");
        
    } catch (e) {
        print("❌ Error generating suggestions: " + e);
    }
}

// Funciones de utilidad
print("=== MONGODB INDEX ANALYZER TOOL ===");
print("Available functions:");
print("• analyzeIndexUsage('collectionName')");
print("• analyzeIndexEfficiency('collectionName')");
print("• findDuplicateIndexes('collectionName')");
print("• analyzeSlowQueries('collectionName')");
print("• generateIndexReport('collectionName')");
print("• suggestIndexOptimizations('collectionName')");
print("");
print("Example usage:");
print("  generateIndexReport('slowQueries')");
print("");
