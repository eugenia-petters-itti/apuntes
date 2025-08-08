// MongoDB Shard Analyzer Tool
// Herramienta para análisis detallado de sharding

function analyzeShardDistribution(namespace) {
    print("=== SHARD DISTRIBUTION ANALYZER ===");
    print("Analyzing: " + namespace);
    print("Timestamp: " + new Date());
    print("");
    
    try {
        // Obtener información de chunks
        var chunks = db.getSiblingDB("config").chunks.find({ns: namespace}).toArray();
        
        if (chunks.length === 0) {
            print("❌ Collection not found or not sharded: " + namespace);
            return;
        }
        
        // Agrupar chunks por shard
        var chunksByShard = {};
        chunks.forEach(function(chunk) {
            if (!chunksByShard[chunk.shard]) {
                chunksByShard[chunk.shard] = [];
            }
            chunksByShard[chunk.shard].push(chunk);
        });
        
        print("📊 CHUNK DISTRIBUTION");
        print("=====================");
        Object.keys(chunksByShard).forEach(function(shard) {
            print("Shard: " + shard + " - " + chunksByShard[shard].length + " chunks");
        });
        
        // Calcular distribución ideal
        var totalChunks = chunks.length;
        var totalShards = Object.keys(chunksByShard).length;
        var idealChunksPerShard = Math.ceil(totalChunks / totalShards);
        
        print("\n📈 BALANCE ANALYSIS");
        print("===================");
        print("Total chunks: " + totalChunks);
        print("Total shards: " + totalShards);
        print("Ideal chunks per shard: " + idealChunksPerShard);
        
        var imbalanced = false;
        Object.keys(chunksByShard).forEach(function(shard) {
            var chunkCount = chunksByShard[shard].length;
            var deviation = Math.abs(chunkCount - idealChunksPerShard);
            var status = deviation > 2 ? "⚠️  IMBALANCED" : "✅ BALANCED";
            
            print("Shard " + shard + ": " + chunkCount + " chunks " + status);
            
            if (deviation > 2) {
                imbalanced = true;
            }
        });
        
        if (imbalanced) {
            print("\n🔧 RECOMMENDATIONS");
            print("==================");
            print("• Enable balancer: sh.enableBalancing('" + namespace + "')");
            print("• Check balancer status: sh.isBalancerRunning()");
            print("• Monitor migration progress: sh.status()");
        }
        
    } catch (e) {
        print("❌ Error analyzing distribution: " + e);
    }
}

function analyzeShardKey(namespace) {
    print("\n=== SHARD KEY ANALYZER ===");
    
    try {
        var collection = db.getSiblingDB("config").collections.findOne({_id: namespace});
        
        if (!collection) {
            print("❌ Collection not found: " + namespace);
            return;
        }
        
        print("🔑 SHARD KEY ANALYSIS");
        print("=====================");
        print("Shard key: " + JSON.stringify(collection.key));
        print("Unique: " + (collection.unique || false));
        
        // Analizar cardinalidad del shard key
        var dbName = namespace.split('.')[0];
        var collName = namespace.split('.')[1];
        var targetDb = db.getSiblingDB(dbName);
        
        var shardKeyFields = Object.keys(collection.key);
        
        print("\n📊 CARDINALITY ANALYSIS");
        print("=======================");
        
        shardKeyFields.forEach(function(field) {
            try {
                var distinctCount = targetDb[collName].distinct(field).length;
                var totalDocs = targetDb[collName].countDocuments();
                var cardinality = totalDocs > 0 ? (distinctCount / totalDocs * 100).toFixed(2) : 0;
                
                print("Field '" + field + "':");
                print("  Distinct values: " + distinctCount);
                print("  Total documents: " + totalDocs);
                print("  Cardinality: " + cardinality + "%");
                
                if (cardinality < 10) {
                    print("  ⚠️  LOW CARDINALITY - May cause hotspots");
                } else if (cardinality > 80) {
                    print("  ✅ HIGH CARDINALITY - Good distribution potential");
                } else {
                    print("  ⚡ MODERATE CARDINALITY - Acceptable");
                }
                
            } catch (e) {
                print("  ❌ Could not analyze field '" + field + "': " + e);
            }
        });
        
    } catch (e) {
        print("❌ Error analyzing shard key: " + e);
    }
}

function checkBalancerStatus() {
    print("\n=== BALANCER STATUS CHECKER ===");
    
    try {
        var balancerEnabled = sh.getBalancerState();
        var balancerRunning = sh.isBalancerRunning();
        
        print("⚖️  BALANCER STATUS");
        print("==================");
        print("Enabled: " + balancerEnabled);
        print("Running: " + balancerRunning);
        
        if (!balancerEnabled) {
            print("⚠️  Balancer is disabled globally");
            print("   Enable with: sh.enableBalancing()");
        }
        
        if (!balancerRunning && balancerEnabled) {
            print("⚠️  Balancer is enabled but not running");
            print("   This may be normal if no balancing is needed");
        }
        
        // Verificar ventana de balanceo
        var balancerSettings = db.getSiblingDB("config").settings.findOne({_id: "balancer"});
        if (balancerSettings && balancerSettings.activeWindow) {
            print("\n⏰ BALANCER WINDOW");
            print("==================");
            print("Start: " + balancerSettings.activeWindow.start);
            print("Stop: " + balancerSettings.activeWindow.stop);
        } else {
            print("\n⏰ Balancer runs 24/7 (no window restrictions)");
        }
        
        // Verificar migraciones recientes
        var recentMigrations = db.getSiblingDB("config").changelog.find({
            "time": {$gte: new Date(Date.now() - 60*60*1000)} // Última hora
        }).count();
        
        print("\n📈 RECENT ACTIVITY");
        print("==================");
        print("Migrations in last hour: " + recentMigrations);
        
    } catch (e) {
        print("❌ Error checking balancer: " + e);
    }
}

function generateShardingReport(namespace) {
    print("=== COMPREHENSIVE SHARDING REPORT ===");
    print("Collection: " + namespace);
    print("Generated: " + new Date());
    print("");
    
    analyzeShardDistribution(namespace);
    analyzeShardKey(namespace);
    checkBalancerStatus();
    
    print("\n=== END OF REPORT ===");
}

// Funciones de utilidad
function enableBalancerForCollection(namespace) {
    try {
        sh.enableBalancing(namespace);
        print("✅ Balancer enabled for " + namespace);
    } catch (e) {
        print("❌ Failed to enable balancer: " + e);
    }
}

function disableBalancerForCollection(namespace) {
    try {
        sh.disableBalancing(namespace);
        print("✅ Balancer disabled for " + namespace);
    } catch (e) {
        print("❌ Failed to disable balancer: " + e);
    }
}

// Ejemplo de uso
print("=== MONGODB SHARD ANALYZER TOOL ===");
print("Available functions:");
print("• analyzeShardDistribution('db.collection')");
print("• analyzeShardKey('db.collection')");
print("• checkBalancerStatus()");
print("• generateShardingReport('db.collection')");
print("• enableBalancerForCollection('db.collection')");
print("• disableBalancerForCollection('db.collection')");
print("");
print("Example usage:");
print("  generateShardingReport('testSharding.unevenData')");
print("");
