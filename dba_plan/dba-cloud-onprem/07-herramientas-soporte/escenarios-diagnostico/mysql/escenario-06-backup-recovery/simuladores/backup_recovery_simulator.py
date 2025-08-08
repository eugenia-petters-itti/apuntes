#!/usr/bin/env python3
"""
MySQL Backup & Recovery Simulator
Simulates data corruption and recovery scenarios
"""

import os
import sys
import time
import logging
import mysql.connector
from mysql.connector import Error
import subprocess
import random
from datetime import datetime, timedelta

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

class BackupRecoverySimulator:
    def __init__(self):
        self.db_config = {
            'host': os.getenv('DB_HOST', 'localhost'),
            'user': os.getenv('DB_USER', 'app_user'),
            'password': os.getenv('DB_PASS', 'app_pass'),
            'database': os.getenv('DB_NAME', 'training_db'),
            'port': int(os.getenv('DB_PORT', '3306'))
        }
        
    def create_test_data(self):
        """Create test data for backup scenario"""
        try:
            connection = mysql.connector.connect(**self.db_config)
            cursor = connection.cursor()
            
            # Create tables
            cursor.execute("""
                CREATE TABLE IF NOT EXISTS transactions (
                    id INT AUTO_INCREMENT PRIMARY KEY,
                    account_id INT NOT NULL,
                    amount DECIMAL(10,2) NOT NULL,
                    transaction_type ENUM('DEBIT', 'CREDIT') NOT NULL,
                    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                    INDEX idx_account_id (account_id),
                    INDEX idx_created_at (created_at)
                )
            """)
            
            cursor.execute("""
                CREATE TABLE IF NOT EXISTS accounts (
                    id INT AUTO_INCREMENT PRIMARY KEY,
                    account_number VARCHAR(20) UNIQUE NOT NULL,
                    balance DECIMAL(12,2) DEFAULT 0.00,
                    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
                )
            """)
            
            # Insert test accounts
            for i in range(1000):
                account_number = f"ACC{i:06d}"
                initial_balance = random.uniform(1000, 50000)
                cursor.execute(
                    "INSERT IGNORE INTO accounts (account_number, balance) VALUES (%s, %s)",
                    (account_number, initial_balance)
                )
            
            # Insert test transactions
            for i in range(10000):
                account_id = random.randint(1, 1000)
                amount = random.uniform(10, 1000)
                transaction_type = random.choice(['DEBIT', 'CREDIT'])
                
                cursor.execute(
                    "INSERT INTO transactions (account_id, amount, transaction_type) VALUES (%s, %s, %s)",
                    (account_id, amount, transaction_type)
                )
            
            connection.commit()
            logger.info("Test data created successfully")
            
        except Error as e:
            logger.error(f"Error creating test data: {e}")
        finally:
            if connection.is_connected():
                cursor.close()
                connection.close()
    
    def simulate_corruption(self):
        """Simulate data corruption"""
        logger.info("Simulating data corruption...")
        
        try:
            connection = mysql.connector.connect(**self.db_config)
            cursor = connection.cursor()
            
            # Simulate corruption by dropping some data
            cursor.execute("DELETE FROM transactions WHERE id % 7 = 0")
            cursor.execute("UPDATE accounts SET balance = -999999 WHERE id % 13 = 0")
            
            connection.commit()
            logger.info("Data corruption simulated")
            
        except Error as e:
            logger.error(f"Error simulating corruption: {e}")
        finally:
            if connection.is_connected():
                cursor.close()
                connection.close()
    
    def create_backup(self):
        """Create a backup"""
        logger.info("Creating backup...")
        
        backup_file = f"/backup/backup_{datetime.now().strftime('%Y%m%d_%H%M%S')}.sql"
        
        cmd = [
            'mysqldump',
            f'--host={self.db_config["host"]}',
            f'--user={self.db_config["user"]}',
            f'--password={self.db_config["password"]}',
            '--single-transaction',
            '--routines',
            '--triggers',
            '--flush-logs',
            '--master-data=2',
            self.db_config['database']
        ]
        
        try:
            with open(backup_file, 'w') as f:
                subprocess.run(cmd, stdout=f, check=True)
            logger.info(f"Backup created: {backup_file}")
            return backup_file
        except subprocess.CalledProcessError as e:
            logger.error(f"Backup failed: {e}")
            return None
    
    def run_scenario(self):
        """Run the complete backup/recovery scenario"""
        logger.info("Starting Backup & Recovery scenario")
        
        # Step 1: Create initial data
        self.create_test_data()
        time.sleep(2)
        
        # Step 2: Create a "good" backup
        backup_file = self.create_backup()
        time.sleep(2)
        
        # Step 3: Add more data (this will be "lost")
        logger.info("Adding additional data that will be lost...")
        try:
            connection = mysql.connector.connect(**self.db_config)
            cursor = connection.cursor()
            
            for i in range(1000):
                account_id = random.randint(1, 1000)
                amount = random.uniform(10, 1000)
                transaction_type = random.choice(['DEBIT', 'CREDIT'])
                
                cursor.execute(
                    "INSERT INTO transactions (account_id, amount, transaction_type) VALUES (%s, %s, %s)",
                    (account_id, amount, transaction_type)
                )
            
            connection.commit()
            logger.info("Additional data added")
            
        except Error as e:
            logger.error(f"Error adding additional data: {e}")
        finally:
            if connection.is_connected():
                cursor.close()
                connection.close()
        
        time.sleep(2)
        
        # Step 4: Simulate corruption
        self.simulate_corruption()
        
        logger.info("Scenario setup complete. Database is now 'corrupted'.")
        logger.info("Your mission: Restore from backup and recover all data.")
        logger.info(f"Available backup: {backup_file}")

if __name__ == "__main__":
    simulator = BackupRecoverySimulator()
    simulator.run_scenario()
    
    # Keep running to maintain the scenario
    while True:
        time.sleep(60)
        logger.info("Scenario running... Waiting for recovery actions.")
