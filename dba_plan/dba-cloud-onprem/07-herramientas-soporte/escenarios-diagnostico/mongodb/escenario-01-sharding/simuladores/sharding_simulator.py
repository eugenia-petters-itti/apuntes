#!/usr/bin/env python3
"""MongoDB Sharding Issues Simulator"""
import os, sys, time, threading, random
from pymongo import MongoClient
from datetime import datetime

class ShardingSimulator:
    def __init__(self):
        self.client = MongoClient(
            host=os.getenv('DB_HOST', 'localhost'),
            port=int(os.getenv('DB_PORT', '27017')),
            username=os.getenv('DB_USER', 'app_user'),
            password=os.getenv('DB_PASS', 'app_pass')
        )
        self.db = self.client[os.getenv('DB_NAME', 'training_db')]
        self.running = True
    
    def create_imbalanced_data(self):
        """Create data that causes shard imbalance"""
        while self.running:
            try:
                # Insert data with skewed shard key distribution
                docs = []
                for i in range(100):
                    docs.append({
                        'shard_key': random.choice(['hot_shard_1', 'hot_shard_1', 'hot_shard_1', 'cold_shard_2']),
                        'data': f'Document {i}',
                        'timestamp': datetime.now(),
                        'value': random.randint(1, 1000)
                    })
                
                self.db.sharded_collection.insert_many(docs)
                time.sleep(2)
            except Exception as e:
                print(f"Sharding simulation error: {e}")
                time.sleep(5)
    
    def run(self):
        threads = []
        for i in range(2):
            thread = threading.Thread(target=self.create_imbalanced_data)
            thread.daemon = True
            thread.start()
            threads.append(thread)
        
        try:
            while True:
                time.sleep(60)
        except KeyboardInterrupt:
            self.running = False

if __name__ == "__main__":
    simulator = ShardingSimulator()
    simulator.run()
