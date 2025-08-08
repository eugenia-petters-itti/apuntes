// MongoDB Diagnostic Queries

// Sharding status
sh.status()

// Collection sharding info
db.runCommand({collStats: "sharded_collection", indexDetails: true})

// Balancer status
sh.getBalancerState()
sh.isBalancerRunning()

// Chunk distribution
db.chunks.aggregate([
  {$group: {_id: "$shard", count: {$sum: 1}}},
  {$sort: {count: -1}}
])

// Index usage statistics
db.sharded_collection.aggregate([
  {$indexStats: {}}
])
