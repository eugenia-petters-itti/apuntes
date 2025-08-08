#!/usr/bin/env python3
"""
MySQL Deadlock Simulator - Main Entry Point
Simulates realistic deadlock scenarios for DBA training
"""

import os
import sys
import time
import logging
import threading
import random
from datetime import datetime
from typing import List, Dict, Any
import mysql.connector
from mysql.connector import Error
import yaml
from prometheus_client import Counter, Histogram, Gauge, start_http_server

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler('/app/logs/deadlock_simulator.log'),
        logging.StreamHandler(sys.stdout)
    ]
)
logger = logging.getLogger(__name__)

# Prometheus metrics
deadlock_counter = Counter('mysql_deadlocks_total', 'Total number of deadlocks detected')
transaction_counter = Counter('mysql_transactions_total', 'Total number of transactions', ['status'])
connection_gauge = Gauge('mysql_active_connections', 'Number of active connections')
response_time = Histogram('mysql_transaction_duration_seconds', 'Transaction duration')

class DeadlockSimulator:
    def __init__(self):
        self.config = self.load_config()
        self.db_config = {
            'host': os.getenv('DB_HOST', 'localhost'),
            'user': os.getenv('DB_USER', 'app_user'),
            'password': os.getenv('DB_PASS', 'app_pass'),
            'database': os.getenv('DB_NAME', 'training_db'),
            'port': int(os.getenv('DB_PORT', '3306')),
            'autocommit': False,
            'charset': 'utf8mb4'
        }
        self.running = True
        self.connections = []
        
    def load_config(self) -> Dict[str, Any]:
        """Load configuration from environment or defaults"""
        return {
            'concurrent_buyers': int(os.getenv('CONCURRENT_BUYERS', '10')),
            'concurrent_restockers': int(os.getenv('CONCURRENT_RESTOCKERS', '3')),
            'concurrent_reporters': int(os.getenv('CONCURRENT_REPORTERS', '2')),
            'deadlock_probability': float(os.getenv('DEADLOCK_PROBABILITY', '0.2')),
            'transaction_delay': float(os.getenv('TRANSACTION_DELAY', '0.1')),
            'simulation_duration': int(os.getenv('SIMULATION_DURATION', '3600')),  # 1 hour
            'metrics_port': int(os.getenv('METRICS_PORT', '8080'))
        }
    
    def get_connection(self):
        """Get database connection with retry logic"""
        max_retries = 5
        for attempt in range(max_retries):
            try:
                conn = mysql.connector.connect(**self.db_config)
                connection_gauge.inc()
                return conn
            except Error as e:
                logger.error(f"Connection attempt {attempt + 1} failed: {e}")
                if attempt < max_retries - 1:
                    time.sleep(2 ** attempt)  # Exponential backoff
                else:
                    raise
    
    def close_connection(self, conn):
        """Close database connection"""
        if conn and conn.is_connected():
            conn.close()
            connection_gauge.dec()
    
    def buyer_transaction(self, buyer_id: int):
        """Simulate a buyer purchasing products (prone to deadlocks)"""
        conn = None
        try:
            conn = self.get_connection()
            cursor = conn.cursor()
            
            with response_time.time():
                # Start transaction
                conn.start_transaction()
                
                # Select random products to buy
                product_ids = random.sample(range(1, 11), random.randint(1, 3))
                
                for product_id in product_ids:
                    # Check stock (SELECT FOR UPDATE - acquires lock)
                    cursor.execute("""
                        SELECT stock_quantity, price 
                        FROM products 
                        WHERE id = %s 
                        FOR UPDATE
                    """, (product_id,))
                    
                    result = cursor.fetchone()
                    if not result:
                        continue
                        
                    stock, price = result
                    quantity_to_buy = random.randint(1, min(3, stock))
                    
                    if stock >= quantity_to_buy:
                        # Add artificial delay to increase deadlock probability
                        time.sleep(random.uniform(0.01, self.config['transaction_delay']))
                        
                        # Update stock
                        cursor.execute("""
                            UPDATE products 
                            SET stock_quantity = stock_quantity - %s 
                            WHERE id = %s
                        """, (quantity_to_buy, product_id))
                        
                        # Create order
                        cursor.execute("""
                            INSERT INTO orders (user_id, total_amount, status) 
                            VALUES (%s, %s, 'pending')
                        """, (buyer_id, price * quantity_to_buy))
                        
                        order_id = cursor.lastrowid
                        
                        # Add order item
                        cursor.execute("""
                            INSERT INTO order_items (order_id, product_id, quantity, price) 
                            VALUES (%s, %s, %s, %s)
                        """, (order_id, product_id, quantity_to_buy, price))
                        
                        # Record inventory movement
                        cursor.execute("""
                            INSERT INTO inventory_movements (product_id, movement_type, quantity, reference_id) 
                            VALUES (%s, 'out', %s, %s)
                        """, (product_id, quantity_to_buy, order_id))
                
                # Commit transaction
                conn.commit()
                transaction_counter.labels(status='success').inc()
                logger.info(f"Buyer {buyer_id} completed purchase successfully")
                
        except mysql.connector.Error as e:
            if conn:
                conn.rollback()
            
            if e.errno == 1213:  # Deadlock error
                deadlock_counter.inc()
                transaction_counter.labels(status='deadlock').inc()
                logger.warning(f"Buyer {buyer_id} encountered deadlock: {e}")
            else:
                transaction_counter.labels(status='error').inc()
                logger.error(f"Buyer {buyer_id} transaction failed: {e}")
                
        except Exception as e:
            if conn:
                conn.rollback()
            transaction_counter.labels(status='error').inc()
            logger.error(f"Buyer {buyer_id} unexpected error: {e}")
            
        finally:
            if conn:
                self.close_connection(conn)
    
    def restocking_transaction(self, restocker_id: int):
        """Simulate restocking products (prone to deadlocks with buyers)"""
        conn = None
        try:
            conn = self.get_connection()
            cursor = conn.cursor()
            
            with response_time.time():
                conn.start_transaction()
                
                # Select random products to restock
                product_ids = random.sample(range(1, 11), random.randint(1, 2))
                
                for product_id in product_ids:
                    # Lock product for update
                    cursor.execute("""
                        SELECT stock_quantity 
                        FROM products 
                        WHERE id = %s 
                        FOR UPDATE
                    """, (product_id,))
                    
                    result = cursor.fetchone()
                    if not result:
                        continue
                    
                    current_stock = result[0]
                    restock_quantity = random.randint(10, 50)
                    
                    # Add delay to increase deadlock probability
                    time.sleep(random.uniform(0.02, self.config['transaction_delay'] * 2))
                    
                    # Update stock
                    cursor.execute("""
                        UPDATE products 
                        SET stock_quantity = stock_quantity + %s 
                        WHERE id = %s
                    """, (restock_quantity, product_id))
                    
                    # Record inventory movement
                    cursor.execute("""
                        INSERT INTO inventory_movements (product_id, movement_type, quantity) 
                        VALUES (%s, 'in', %s)
                    """, (product_id, restock_quantity))
                
                conn.commit()
                transaction_counter.labels(status='success').inc()
                logger.info(f"Restocker {restocker_id} completed restocking successfully")
                
        except mysql.connector.Error as e:
            if conn:
                conn.rollback()
                
            if e.errno == 1213:  # Deadlock error
                deadlock_counter.inc()
                transaction_counter.labels(status='deadlock').inc()
                logger.warning(f"Restocker {restocker_id} encountered deadlock: {e}")
            else:
                transaction_counter.labels(status='error').inc()
                logger.error(f"Restocker {restocker_id} transaction failed: {e}")
                
        except Exception as e:
            if conn:
                conn.rollback()
            transaction_counter.labels(status='error').inc()
            logger.error(f"Restocker {restocker_id} unexpected error: {e}")
            
        finally:
            if conn:
                self.close_connection(conn)
    
    def reporting_transaction(self, reporter_id: int):
        """Simulate reporting queries (can cause deadlocks with long-running reads)"""
        conn = None
        try:
            conn = self.get_connection()
            cursor = conn.cursor()
            
            with response_time.time():
                conn.start_transaction()
                
                # Long-running report query that locks multiple tables
                cursor.execute("""
                    SELECT 
                        p.id,
                        p.name,
                        p.stock_quantity,
                        COALESCE(SUM(oi.quantity), 0) as total_sold,
                        COALESCE(SUM(im.quantity), 0) as total_restocked
                    FROM products p
                    LEFT JOIN order_items oi ON p.id = oi.product_id
                    LEFT JOIN inventory_movements im ON p.id = im.product_id AND im.movement_type = 'in'
                    WHERE p.id BETWEEN %s AND %s
                    GROUP BY p.id, p.name, p.stock_quantity
                    FOR UPDATE
                """, (random.randint(1, 5), random.randint(6, 10)))
                
                results = cursor.fetchall()
                
                # Simulate processing time
                time.sleep(random.uniform(0.1, 0.5))
                
                conn.commit()
                transaction_counter.labels(status='success').inc()
                logger.info(f"Reporter {reporter_id} completed report successfully")
                
        except mysql.connector.Error as e:
            if conn:
                conn.rollback()
                
            if e.errno == 1213:  # Deadlock error
                deadlock_counter.inc()
                transaction_counter.labels(status='deadlock').inc()
                logger.warning(f"Reporter {reporter_id} encountered deadlock: {e}")
            else:
                transaction_counter.labels(status='error').inc()
                logger.error(f"Reporter {reporter_id} transaction failed: {e}")
                
        except Exception as e:
            if conn:
                conn.rollback()
            transaction_counter.labels(status='error').inc()
            logger.error(f"Reporter {reporter_id} unexpected error: {e}")
            
        finally:
            if conn:
                self.close_connection(conn)
    
    def worker_thread(self, worker_type: str, worker_id: int):
        """Worker thread that continuously executes transactions"""
        logger.info(f"Starting {worker_type} worker {worker_id}")
        
        while self.running:
            try:
                if worker_type == 'buyer':
                    self.buyer_transaction(worker_id)
                elif worker_type == 'restocker':
                    self.restocking_transaction(worker_id)
                elif worker_type == 'reporter':
                    self.reporting_transaction(worker_id)
                
                # Random delay between transactions
                time.sleep(random.uniform(0.5, 2.0))
                
            except Exception as e:
                logger.error(f"{worker_type} {worker_id} thread error: {e}")
                time.sleep(5)  # Wait before retrying
    
    def wait_for_database(self):
        """Wait for database to be ready"""
        max_attempts = 30
        for attempt in range(max_attempts):
            try:
                conn = self.get_connection()
                cursor = conn.cursor()
                cursor.execute("SELECT 1")
                cursor.fetchone()
                self.close_connection(conn)
                logger.info("Database is ready")
                return True
            except Exception as e:
                logger.info(f"Waiting for database... attempt {attempt + 1}/{max_attempts}")
                time.sleep(2)
        
        logger.error("Database not ready after maximum attempts")
        return False
    
    def run(self):
        """Main simulation loop"""
        logger.info("Starting MySQL Deadlock Simulator")
        logger.info(f"Configuration: {self.config}")
        
        # Start Prometheus metrics server
        start_http_server(self.config['metrics_port'])
        logger.info(f"Metrics server started on port {self.config['metrics_port']}")
        
        # Wait for database
        if not self.wait_for_database():
            logger.error("Cannot connect to database. Exiting.")
            return
        
        # Start worker threads
        threads = []
        
        # Buyer threads
        for i in range(self.config['concurrent_buyers']):
            thread = threading.Thread(target=self.worker_thread, args=('buyer', i + 1))
            thread.daemon = True
            thread.start()
            threads.append(thread)
        
        # Restocker threads
        for i in range(self.config['concurrent_restockers']):
            thread = threading.Thread(target=self.worker_thread, args=('restocker', i + 1))
            thread.daemon = True
            thread.start()
            threads.append(thread)
        
        # Reporter threads
        for i in range(self.config['concurrent_reporters']):
            thread = threading.Thread(target=self.worker_thread, args=('reporter', i + 1))
            thread.daemon = True
            thread.start()
            threads.append(thread)
        
        logger.info(f"Started {len(threads)} worker threads")
        
        # Run simulation
        try:
            if self.config['simulation_duration'] > 0:
                logger.info(f"Running simulation for {self.config['simulation_duration']} seconds")
                time.sleep(self.config['simulation_duration'])
            else:
                logger.info("Running simulation indefinitely (Ctrl+C to stop)")
                while True:
                    time.sleep(60)
                    logger.info("Simulation still running...")
        except KeyboardInterrupt:
            logger.info("Received interrupt signal")
        finally:
            logger.info("Stopping simulation...")
            self.running = False
            
            # Wait for threads to finish
            for thread in threads:
                thread.join(timeout=5)
            
            logger.info("Simulation stopped")

def main():
    """Main entry point"""
    simulator = DeadlockSimulator()
    simulator.run()

if __name__ == "__main__":
    main()
