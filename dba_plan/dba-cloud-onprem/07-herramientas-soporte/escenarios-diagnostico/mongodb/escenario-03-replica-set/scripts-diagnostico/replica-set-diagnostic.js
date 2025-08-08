// MongoDB Replica Set Diagnostic Script
// Escenario 03: Problemas de Replicación y Alta Disponibilidad

print("=== MONGODB REPLICA SET DIAGNOSTIC REPORT ===");
print("Timestamp: " + new Date());
print("");

// 1. Verificar estado del replica set
print("1. REPLICA SET STATUS");
print("=====================");
try {
    var rsStatus = rs.status();
    print("Replica Set: " + rsStatus.set);
    print("Date: " + rsStatus.date);
    print("My State: " + rsStatus.myState);
    
    // Mapear estados
    var stateMap = {
        0: "STARTUP",
        1: "PRIMARY", 
        2: "SECONDARY",
        3: "RECOVERING",
        5: "STARTUP2",
        6: "UNKNOWN",
        7: "ARBITER",
        8: "DOWN",
        9: "ROLLBACK",
        10: "REMOVED"
    };
    
    print("\nMembers:");
    rsStatus.members.forEach(function(member) {
        var state = stateMap[member.state] || "UNKNOWN";
        print("  " + member.name + " - " + state + " (State: " + member.state + ")");
        print("    Health: " + member.health);
        print("    Uptime: " + member.uptime + " seconds");
        
        if (member.optimeDate) {
            print("    Last OpTime: " + member.optimeDate);
        }
        
        if (member.lastHeartbeat) {
            print("    Last Heartbeat: " + member.lastHeartbeat);
            print("    Ping: " + (member.pingMs || "N/A") + "ms");
        }
        
        if (member.syncingTo) {
            print("    Syncing from: " + member.syncingTo);
        }
        
        if (member.errmsg) {
            print("    ⚠️  Error: " + member.errmsg);
        }
        print("");
    });
    
} catch (e) {
    print("✗ Error getting replica set status: " + e);
    print("This might not be a replica set member");
}
print("");

// 2. Verificar configuración del replica set
print("2. REPLICA SET CONFIGURATION");
print("=============================");
try {
    var rsConfig = rs.conf();
    print("Configuration Version: " + rsConfig.version);
    print("Protocol Version: " + rsConfig.protocolVersion);
    
    if (rsConfig.settings) {
        print("\nSettings:");
        if (rsConfig.settings.heartbeatIntervalMillis) {
            print("  Heartbeat Interval: " + rsConfig.settings.heartbeatIntervalMillis + "ms");
        }
        if (rsConfig.settings.heartbeatTimeoutSecs) {
            print("  Heartbeat Timeout: " + rsConfig.settings.heartbeatTimeoutSecs + "s");
        }
        if (rsConfig.settings.electionTimeoutMillis) {
            print("  Election Timeout: " + rsConfig.settings.electionTimeoutMillis + "ms");
        }
        if (rsConfig.settings.chainingAllowed !== undefined) {
            print("  Chaining Allowed: " + rsConfig.settings.chainingAllowed);
        }
    }
    
    print("\nMembers Configuration:");
    rsConfig.members.forEach(function(member) {
        print("  " + member.host + " (ID: " + member._id + ")");
        print("    Priority: " + member.priority);
        print("    Votes: " + member.votes);
        
        if (member.arbiterOnly) {
            print("    Role: ARBITER");
        }
        if (member.hidden) {
            print("    Hidden: true");
        }
        if (member.secondaryDelaySecs) {
            print("    Delay: " + member.secondaryDelaySecs + "s");
        }
        if (member.tags) {
            print("    Tags: " + JSON.stringify(member.tags));
        }
        print("");
    });
    
} catch (e) {
    print("✗ Error getting replica set configuration: " + e);
}
print("");

// 3. Verificar lag de replicación
print("3. REPLICATION LAG ANALYSIS");
print("============================");
try {
    var rsStatus = rs.status();
    var primary = null;
    var secondaries = [];
    
    // Identificar primary y secondaries
    rsStatus.members.forEach(function(member) {
        if (member.state === 1) { // PRIMARY
            primary = member;
        } else if (member.state === 2) { // SECONDARY
            secondaries.push(member);
        }
    });
    
    if (primary && secondaries.length > 0) {
        print("Primary: " + primary.name);
        print("Primary OpTime: " + primary.optimeDate);
        print("");
        
        secondaries.forEach(function(secondary) {
            var lagMs = primary.optimeDate - secondary.optimeDate;
            var lagSeconds = Math.round(lagMs / 1000);
            
            print("Secondary: " + secondary.name);
            print("  OpTime: " + secondary.optimeDate);
            print("  Lag: " + lagSeconds + " seconds");
            
            if (lagSeconds > 10) {
                print("  ⚠️  HIGH LAG - Investigation needed");
            } else if (lagSeconds > 5) {
                print("  ⚠️  Moderate lag");
            } else {
                print("  ✓ Low lag");
            }
            print("");
        });
    } else {
        print("Unable to calculate lag - no primary or secondaries found");
    }
    
} catch (e) {
    print("✗ Error calculating replication lag: " + e);
}
print("");

// 4. Verificar oplog
print("4. OPLOG ANALYSIS");
print("=================");
try {
    var oplogStats = db.getSiblingDB("local").oplog.rs.stats();
    print("Oplog Size: " + (oplogStats.size / 1024 / 1024 / 1024).toFixed(2) + " GB");
    print("Oplog Count: " + oplogStats.count);
    
    // Obtener primera y última entrada del oplog
    var firstOp = db.getSiblingDB("local").oplog.rs.find().sort({$natural: 1}).limit(1).next();
    var lastOp = db.getSiblingDB("local").oplog.rs.find().sort({$natural: -1}).limit(1).next();
    
    if (firstOp && lastOp) {
        var oplogSpan = (lastOp.ts.getTime() - firstOp.ts.getTime()) / 1000 / 3600; // horas
        print("Oplog Time Span: " + oplogSpan.toFixed(2) + " hours");
        print("First Operation: " + firstOp.ts);
        print("Last Operation: " + lastOp.ts);
        
        if (oplogSpan < 24) {
            print("⚠️  Oplog covers less than 24 hours - consider increasing size");
        }
    }
    
} catch (e) {
    print("✗ Error analyzing oplog: " + e);
}
print("");

// 5. Verificar read preference y write concern
print("5. READ/WRITE PREFERENCES");
print("=========================");
try {
    // Verificar read preference actual
    var readPref = db.getMongo().getReadPref();
    print("Current Read Preference: " + (readPref || "primary"));
    
    // Verificar write concern por defecto
    var writeResult = db.runCommand({getDefaultRWConcern: 1});
    if (writeResult.defaultWriteConcern) {
        print("Default Write Concern: " + JSON.stringify(writeResult.defaultWriteConcern));
    } else {
        print("Default Write Concern: Not set (using implicit default)");
    }
    
} catch (e) {
    print("✗ Error checking read/write preferences: " + e);
}
print("");

// 6. Verificar conexiones y carga
print("6. CONNECTION AND LOAD ANALYSIS");
print("================================");
try {
    var serverStatus = db.serverStatus();
    
    print("Connections:");
    print("  Current: " + serverStatus.connections.current);
    print("  Available: " + serverStatus.connections.available);
    print("  Total Created: " + serverStatus.connections.totalCreated);
    
    print("\nOperations per second (approximate):");
    print("  Inserts: " + serverStatus.opcounters.insert);
    print("  Queries: " + serverStatus.opcounters.query);
    print("  Updates: " + serverStatus.opcounters.update);
    print("  Deletes: " + serverStatus.opcounters.delete);
    print("  Commands: " + serverStatus.opcounters.command);
    
    if (serverStatus.repl) {
        print("\nReplication Metrics:");
        print("  Apply Batches Total: " + (serverStatus.repl.apply.batches.totalMillis || "N/A"));
        print("  Apply Ops: " + (serverStatus.repl.apply.ops || "N/A"));
        print("  Buffer Count: " + (serverStatus.repl.buffer.count || "N/A"));
        print("  Buffer Size: " + (serverStatus.repl.buffer.sizeBytes || "N/A"));
    }
    
} catch (e) {
    print("✗ Error getting server status: " + e);
}
print("");

// 7. Verificar elecciones recientes
print("7. RECENT ELECTIONS");
print("===================");
try {
    // Buscar en logs de elecciones (si están disponibles)
    var elections = db.getSiblingDB("local").replset.election.find().sort({_id: -1}).limit(5);
    
    if (elections.hasNext()) {
        print("Recent elections:");
        elections.forEach(function(election) {
            print("  " + election._id + " - " + election.when);
        });
    } else {
        print("No recent election data found");
    }
    
} catch (e) {
    print("Election history not available: " + e.message);
}
print("");

// 8. Recomendaciones de diagnóstico
print("8. DIAGNOSTIC RECOMMENDATIONS");
print("==============================");
print("Replication Health:");
print("• Monitor replication lag regularly");
print("• Ensure oplog size is adequate (24-72 hours of operations)");
print("• Check network connectivity between replica set members");
print("• Verify proper read/write concern settings");
print("• Monitor election frequency (frequent elections indicate issues)");
print("");

print("Performance Optimization:");
print("• Use appropriate read preferences for your use case");
print("• Consider using secondary reads for analytics workloads");
print("• Monitor connection pool usage");
print("• Implement proper indexing strategy across all members");
print("• Use write concern 'majority' for critical operations");
print("");

print("Troubleshooting Commands:");
print("• rs.status() - Check replica set status");
print("• rs.printReplicationInfo() - Oplog information");
print("• rs.printSlaveReplicationInfo() - Secondary lag info");
print("• db.serverStatus().repl - Replication metrics");
print("• rs.conf() - Replica set configuration");
print("");

print("=== END OF DIAGNOSTIC REPORT ===");
