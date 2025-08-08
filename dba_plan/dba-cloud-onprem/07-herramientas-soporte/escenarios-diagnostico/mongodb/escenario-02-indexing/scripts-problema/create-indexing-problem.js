// MongoDB Indexing Problem Creation Script
// Este script crea problemas de performance relacionados con índices

print("=== CREATING INDEXING PROBLEM SCENARIO ===");
print("Timestamp: " + new Date());
print("");

use testIndexing;

// 1. Crear colección grande sin índices apropiados
print("1. Creating large collection with poor indexing...");
db.slowQueries.drop();

// Insertar muchos documentos
print("Inserting 50,000 documents...");
var bulk = db.slowQueries.initializeUnorderedBulkOp();
for (let i = 0; i < 50000; i++) {
    bulk.insert({
        _id: i,
        userId: Math.floor(Math.random() * 1000), // Baja cardinalidad
        category: ["electronics", "books", "clothing", "home", "sports"][Math.floor(Math.random() * 5)],
        status: Math.random() > 0.8 ? "inactive" : "active", // 80% active, 20% inactive
        price: Math.random() * 1000,
        createdAt: new Date(Date.now() - Math.random() * 365 * 24 * 60 * 60 * 1000),
        description: "Product description ".repeat(10), // Texto largo
        tags: ["tag" + Math.floor(Math.random() * 100), "tag" + Math.floor(Math.random() * 100)],
        metadata: {
            views: Math.floor(Math.random() * 10000),
            likes: Math.floor(Math.random() * 1000),
            nested: {
                level1: Math.random(),
                level2: "deep value " + i
            }
        }
    });
    
    if (i % 10000 === 0) {
        print("  Inserted " + i + " documents...");
    }
}
bulk.execute();
print("✓ Created collection with 50,000 documents");

// 2. Crear índices problemáticos
print("\n2. Creating problematic indexes...");

// Índice en campo de baja cardinalidad
db.slowQueries.createIndex({status: 1}, {name: "poor_cardinality_index"});
print("✓ Created index on low-cardinality field (status)");

// Índice compuesto en orden incorrecto
db.slowQueries.createIndex({category: 1, userId: 1, createdAt: 1}, {name: "wrong_order_compound"});
print("✓ Created compound index with suboptimal field order");

// Índice parcial innecesario
db.slowQueries.createIndex(
    {price: 1}, 
    {
        name: "unnecessary_partial",
        partialFilterExpression: {price: {$exists: true}} // Redundante
    }
);
print("✓ Created unnecessary partial index");

// Índice duplicado (similar funcionalidad)
db.slowQueries.createIndex({userId: 1}, {name: "duplicate_functionality_1"});
db.slowQueries.createIndex({userId: 1, status: 1}, {name: "duplicate_functionality_2"});
print("✓ Created redundant indexes");

// 3. Crear consultas problemáticas
print("\n3. Creating problematic query patterns...");
db.problematicQueries.drop();
db.problematicQueries.insertMany([
    {
        type: "no_index_support",
        query: "db.slowQueries.find({price: {$gte: 100, $lte: 500}, 'metadata.views': {$gt: 1000}})",
        problem: "Query on unindexed nested field",
        expectedScan: "COLLSCAN"
    },
    {
        type: "wrong_sort_order",
        query: "db.slowQueries.find({category: 'electronics'}).sort({createdAt: -1, userId: 1})",
        problem: "Sort order doesn't match compound index",
        expectedScan: "IXSCAN + SORT"
    },
    {
        type: "regex_without_anchor",
        query: "db.slowQueries.find({description: /Product/})",
        problem: "Regex without leading anchor",
        expectedScan: "COLLSCAN"
    },
    {
        type: "or_query_inefficient",
        query: "db.slowQueries.find({$or: [{userId: 123}, {category: 'books'}, {price: {$gt: 800}}]})",
        problem: "OR query with mixed indexed/unindexed fields",
        expectedScan: "Multiple scans"
    },
    {
        type: "large_skip",
        query: "db.slowQueries.find().skip(40000).limit(10)",
        problem: "Large skip value causes performance issues",
        expectedScan: "IXSCAN with large skip"
    }
]);
print("✓ Created problematic query examples");

// 4. Simular consultas lentas ejecutándose
print("\n4. Simulating slow queries...");

// Habilitar profiler para capturar consultas lentas
db.setProfilingLevel(1, {slowms: 50});
print("✓ Enabled profiler (slowms: 50)");

// Ejecutar algunas consultas problemáticas
print("Executing slow queries...");

// Query sin índice apropiado
db.slowQueries.find({"metadata.views": {$gt: 5000}}).limit(10).toArray();

// Query con sort costoso
db.slowQueries.find({category: "electronics"}).sort({createdAt: -1, userId: 1}).limit(5).toArray();

// Query con regex
db.slowQueries.find({description: /Product description/}).limit(3).toArray();

// Query con skip grande
db.slowQueries.find().skip(30000).limit(5).toArray();

print("✓ Executed problematic queries");

// 5. Crear estadísticas de uso de índices problemáticas
print("\n5. Creating index usage statistics...");
try {
    // Ejecutar más consultas para generar estadísticas
    for (let i = 0; i < 100; i++) {
        // Usar solo algunos índices, dejando otros sin usar
        db.slowQueries.find({userId: Math.floor(Math.random() * 1000)}).limit(1).toArray();
        
        if (i % 2 === 0) {
            db.slowQueries.find({status: "active"}).limit(1).toArray();
        }
        
        // El índice parcial y algunos compuestos quedarán sin usar
    }
    print("✓ Generated index usage patterns");
} catch (e) {
    print("⚠️  Could not generate usage statistics: " + e);
}

// 6. Información del problema creado
print("\n6. PROBLEM SCENARIO SUMMARY");
print("============================");
print("Created the following indexing issues:");
print("• Large collection (50,000 docs) with suboptimal indexes");
print("• Index on low-cardinality field (status)");
print("• Compound index with wrong field order");
print("• Unnecessary partial index");
print("• Redundant indexes with overlapping functionality");
print("• Queries that don't use indexes effectively");
print("• Some indexes that are never used");
print("");

print("To diagnose these issues, run:");
print("• db.slowQueries.getIndexes() - List all indexes");
print("• db.slowQueries.aggregate([{$indexStats: {}}]) - Index usage stats");
print("• db.system.profile.find().sort({ts: -1}).limit(10) - Recent slow queries");
print("• db.slowQueries.find({query}).explain('executionStats') - Analyze specific queries");
print("");

print("Expected symptoms:");
print("• Slow query performance");
print("• High docsExamined/nreturned ratios");
print("• COLLSCAN execution plans");
print("• Unused indexes consuming space");
print("• Inefficient compound index usage");
print("");

print("=== INDEXING PROBLEM SCENARIO CREATED ===");
