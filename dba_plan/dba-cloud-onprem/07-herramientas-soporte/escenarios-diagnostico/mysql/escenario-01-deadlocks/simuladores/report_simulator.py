#!/usr/bin/env python3
"""
Report Generator Simulator for MySQL Deadlock Scenario
Generates heavy reporting queries that contribute to deadlock conditions
"""

import os
import sys
import time
import logging
import random
from datetime import datetime, timedelta
import mysql.connector
from mysql.connector import Error

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler('/app/logs/report_simulator.log'),
        logging.StreamHandler(sys.stdout)
    ]
)
logger = logging.getLogger(__name__)

class ReportSimulator:
    def __init__(self):
        self.db_config = {
            'host': os.getenv('DB_HOST', 'localhost'),
            'user': os.getenv('DB_USER', 'app_user'),
            'password': os.getenv('DB_PASS', 'app_pass'),
            'database': os.getenv('DB_NAME', 'training_db'),
            'port': int(os.getenv('DB_PORT', '3306')),
            'autocommit': False,
            'charset': 'utf8mb4'
        }
        self.report_interval = int(os.getenv('REPORT_INTERVAL', '30'))
        self.running = True
        
    def get_connection(self):
        """Get database connection with retry logic"""
        max_retries = 5
        for attempt in range(max_retries):
            try:
                return mysql.connector.connect(**self.db_config)
            except Error as e:
                logger.error(f"Connection attempt {attempt + 1} failed: {e}")
                if attempt < max_retries - 1:
                    time.sleep(2 ** attempt)
                else:
                    raise
    
    def generate_sales_report(self):
        """Generate sales report that locks multiple tables"""
        conn = None
        try:
            conn = self.get_connection()
            cursor = conn.cursor(dictionary=True)
            
            logger.info("Generating sales report...")
            
            # Complex query that joins multiple tables and uses FOR UPDATE
            query = """
            SELECT 
                p.id as product_id,
                p.name as product_name,
                p.price as current_price,
                p.stock_quantity as current_stock,
                COUNT(DISTINCT o.id) as total_orders,
                COALESCE(SUM(oi.quantity), 0) as total_quantity_sold,
                COALESCE(SUM(oi.quantity * oi.price), 0) as total_revenue,
                AVG(oi.price) as average_selling_price,
                MIN(o.created_at) as first_sale_date,
                MAX(o.created_at) as last_sale_date
            FROM products p
            LEFT JOIN order_items oi ON p.id = oi.product_id
            LEFT JOIN orders o ON oi.order_id = o.id
            WHERE o.status IN ('completed', 'processing')
            GROUP BY p.id, p.name, p.price, p.stock_quantity
            ORDER BY total_revenue DESC
            FOR UPDATE
            """
            
            start_time = time.time()
            cursor.execute(query)
            results = cursor.fetchall()
            execution_time = time.time() - start_time
            
            logger.info(f"Sales report completed in {execution_time:.2f} seconds")
            logger.info(f"Found {len(results)} products with sales data")
            
            # Log top 3 products
            for i, product in enumerate(results[:3]):
                logger.info(f"Top {i+1}: {product['product_name']} - Revenue: ${product['total_revenue']:.2f}")
            
            conn.commit()
            
        except mysql.connector.Error as e:
            if conn:
                conn.rollback()
            if e.errno == 1213:
                logger.warning(f"Sales report encountered deadlock: {e}")
            else:
                logger.error(f"Sales report failed: {e}")
        except Exception as e:
            if conn:
                conn.rollback()
            logger.error(f"Sales report unexpected error: {e}")
        finally:
            if conn and conn.is_connected():
                conn.close()
    
    def generate_inventory_report(self):
        """Generate inventory report with movement analysis"""
        conn = None
        try:
            conn = self.get_connection()
            cursor = conn.cursor(dictionary=True)
            
            logger.info("Generating inventory report...")
            
            query = """
            SELECT 
                p.id as product_id,
                p.name as product_name,
                p.stock_quantity as current_stock,
                COALESCE(SUM(CASE WHEN im.movement_type = 'in' THEN im.quantity ELSE 0 END), 0) as total_restocked,
                COALESCE(SUM(CASE WHEN im.movement_type = 'out' THEN im.quantity ELSE 0 END), 0) as total_sold,
                COUNT(CASE WHEN im.movement_type = 'in' THEN 1 END) as restock_transactions,
                COUNT(CASE WHEN im.movement_type = 'out' THEN 1 END) as sale_transactions,
                MIN(im.created_at) as first_movement,
                MAX(im.created_at) as last_movement
            FROM products p
            LEFT JOIN inventory_movements im ON p.id = im.product_id
            GROUP BY p.id, p.name, p.stock_quantity
            HAVING total_restocked > 0 OR total_sold > 0
            ORDER BY (total_restocked - total_sold) ASC
            FOR UPDATE
            """
            
            start_time = time.time()
            cursor.execute(query)
            results = cursor.fetchall()
            execution_time = time.time() - start_time
            
            logger.info(f"Inventory report completed in {execution_time:.2f} seconds")
            logger.info(f"Found {len(results)} products with inventory movements")
            
            # Log products with low stock
            low_stock_products = [p for p in results if p['current_stock'] < 10]
            if low_stock_products:
                logger.warning(f"Found {len(low_stock_products)} products with low stock:")
                for product in low_stock_products[:3]:
                    logger.warning(f"  {product['product_name']}: {product['current_stock']} units")
            
            conn.commit()
            
        except mysql.connector.Error as e:
            if conn:
                conn.rollback()
            if e.errno == 1213:
                logger.warning(f"Inventory report encountered deadlock: {e}")
            else:
                logger.error(f"Inventory report failed: {e}")
        except Exception as e:
            if conn:
                conn.rollback()
            logger.error(f"Inventory report unexpected error: {e}")
        finally:
            if conn and conn.is_connected():
                conn.close()
    
    def generate_customer_report(self):
        """Generate customer analysis report"""
        conn = None
        try:
            conn = self.get_connection()
            cursor = conn.cursor(dictionary=True)
            
            logger.info("Generating customer report...")
            
            query = """
            SELECT 
                u.id as customer_id,
                u.username as customer_name,
                u.email as customer_email,
                COUNT(DISTINCT o.id) as total_orders,
                COALESCE(SUM(o.total_amount), 0) as total_spent,
                AVG(o.total_amount) as average_order_value,
                MIN(o.created_at) as first_order_date,
                MAX(o.created_at) as last_order_date,
                COUNT(CASE WHEN o.status = 'completed' THEN 1 END) as completed_orders,
                COUNT(CASE WHEN o.status = 'cancelled' THEN 1 END) as cancelled_orders
            FROM users u
            LEFT JOIN orders o ON u.id = o.user_id
            GROUP BY u.id, u.username, u.email
            HAVING total_orders > 0
            ORDER BY total_spent DESC
            FOR UPDATE
            """
            
            start_time = time.time()
            cursor.execute(query)
            results = cursor.fetchall()
            execution_time = time.time() - start_time
            
            logger.info(f"Customer report completed in {execution_time:.2f} seconds")
            logger.info(f"Found {len(results)} customers with orders")
            
            # Log top customers
            for i, customer in enumerate(results[:3]):
                logger.info(f"Top customer {i+1}: {customer['customer_name']} - Spent: ${customer['total_spent']:.2f}")
            
            conn.commit()
            
        except mysql.connector.Error as e:
            if conn:
                conn.rollback()
            if e.errno == 1213:
                logger.warning(f"Customer report encountered deadlock: {e}")
            else:
                logger.error(f"Customer report failed: {e}")
        except Exception as e:
            if conn:
                conn.rollback()
            logger.error(f"Customer report unexpected error: {e}")
        finally:
            if conn and conn.is_connected():
                conn.close()
    
    def generate_performance_report(self):
        """Generate database performance analysis"""
        conn = None
        try:
            conn = self.get_connection()
            cursor = conn.cursor(dictionary=True)
            
            logger.info("Generating performance report...")
            
            # Get InnoDB status information
            cursor.execute("SHOW ENGINE INNODB STATUS")
            innodb_status = cursor.fetchone()
            
            # Get process list
            cursor.execute("SHOW PROCESSLIST")
            processes = cursor.fetchall()
            
            # Get deadlock information
            cursor.execute("""
                SELECT 
                    VARIABLE_NAME,
                    VARIABLE_VALUE
                FROM performance_schema.global_status 
                WHERE VARIABLE_NAME LIKE '%deadlock%'
                   OR VARIABLE_NAME LIKE '%lock_wait%'
                   OR VARIABLE_NAME LIKE '%innodb_row_lock%'
            """)
            lock_stats = cursor.fetchall()
            
            logger.info(f"Performance report: {len(processes)} active processes")
            
            # Log lock statistics
            for stat in lock_stats:
                if int(stat['VARIABLE_VALUE']) > 0:
                    logger.info(f"  {stat['VARIABLE_NAME']}: {stat['VARIABLE_VALUE']}")
            
            conn.commit()
            
        except mysql.connector.Error as e:
            if conn:
                conn.rollback()
            logger.error(f"Performance report failed: {e}")
        except Exception as e:
            if conn:
                conn.rollback()
            logger.error(f"Performance report unexpected error: {e}")
        finally:
            if conn and conn.is_connected():
                conn.close()
    
    def wait_for_database(self):
        """Wait for database to be ready"""
        max_attempts = 30
        for attempt in range(max_attempts):
            try:
                conn = self.get_connection()
                cursor = conn.cursor()
                cursor.execute("SELECT 1")
                cursor.fetchone()
                conn.close()
                logger.info("Database is ready for reporting")
                return True
            except Exception as e:
                logger.info(f"Waiting for database... attempt {attempt + 1}/{max_attempts}")
                time.sleep(2)
        
        logger.error("Database not ready after maximum attempts")
        return False
    
    def run(self):
        """Main reporting loop"""
        logger.info("Starting Report Generator Simulator")
        logger.info(f"Report interval: {self.report_interval} seconds")
        
        # Wait for database
        if not self.wait_for_database():
            logger.error("Cannot connect to database. Exiting.")
            return
        
        report_functions = [
            self.generate_sales_report,
            self.generate_inventory_report,
            self.generate_customer_report,
            self.generate_performance_report
        ]
        
        try:
            while self.running:
                # Select random report to generate
                report_func = random.choice(report_functions)
                
                try:
                    report_func()
                except Exception as e:
                    logger.error(f"Report generation failed: {e}")
                
                # Wait before next report
                time.sleep(self.report_interval + random.uniform(-5, 5))
                
        except KeyboardInterrupt:
            logger.info("Received interrupt signal")
        finally:
            logger.info("Report generator stopped")
            self.running = False

def main():
    """Main entry point"""
    simulator = ReportSimulator()
    simulator.run()

if __name__ == "__main__":
    main()
