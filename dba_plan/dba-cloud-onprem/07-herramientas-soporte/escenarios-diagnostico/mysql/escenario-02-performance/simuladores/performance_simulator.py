#!/usr/bin/env python3
"""MySQL Performance Issues Simulator"""
import os, sys, time, threading, random, mysql.connector
from datetime import datetime

class PerformanceSimulator:
    def __init__(self):
        self.db_config = {
            'host': os.getenv('DB_HOST', 'localhost'),
            'user': os.getenv('DB_USER', 'app_user'),
            'password': os.getenv('DB_PASS', 'app_pass'),
            'database': os.getenv('DB_NAME', 'training_db'),
            'port': int(os.getenv('DB_PORT', '3306'))
        }
        self.running = True
    
    def get_connection(self):
        return mysql.connector.connect(**self.db_config)
    
    def slow_query_generator(self):
        """Generate intentionally slow queries"""
        while self.running:
            try:
                conn = self.get_connection()
                cursor = conn.cursor()
                
                # Slow query without proper indexing
                cursor.execute("""
                    SELECT p1.*, p2.*, COUNT(*)
                    FROM products p1
                    CROSS JOIN products p2
                    WHERE p1.price > p2.price * 0.8
                    GROUP BY p1.id, p2.id
                    HAVING COUNT(*) > 0
                    ORDER BY RAND()
                    LIMIT 10
                """)
                cursor.fetchall()
                conn.close()
                
                time.sleep(random.uniform(2, 5))
            except Exception as e:
                print(f"Slow query error: {e}")
                time.sleep(5)
    
    def run(self):
        threads = []
        for i in range(3):
            thread = threading.Thread(target=self.slow_query_generator)
            thread.daemon = True
            thread.start()
            threads.append(thread)
        
        try:
            while True:
                time.sleep(60)
        except KeyboardInterrupt:
            self.running = False

if __name__ == "__main__":
    simulator = PerformanceSimulator()
    simulator.run()
