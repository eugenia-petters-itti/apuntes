#!/usr/bin/env python3
"""
Basic Simulator for escenario-03-replica-set
"""
import os
import sys
import time
import random
from datetime import datetime

class BasicSimulator:
    def __init__(self):
        self.db_host = os.getenv('DB_HOST', 'localhost')
        self.db_user = os.getenv('DB_USER', 'app_user')
        self.db_pass = os.getenv('DB_PASS', 'app_pass')
        self.db_name = os.getenv('DB_NAME', 'training_db')
        self.running = True
        
    def simulate_problem(self):
        """Simulate the specific problem for this scenario"""
        print(f"Starting simulation for escenario-03-replica-set")
        
        while self.running:
            try:
                # Basic simulation logic
                print(f"[{datetime.now()}] Simulating problem...")
                time.sleep(random.uniform(5, 15))
                
            except KeyboardInterrupt:
                print("Simulation stopped by user")
                self.running = False
            except Exception as e:
                print(f"Simulation error: {e}")
                time.sleep(5)
    
    def run(self):
        """Run the simulator"""
        try:
            self.simulate_problem()
        except KeyboardInterrupt:
            print("Shutting down simulator...")
            self.running = False

if __name__ == "__main__":
    simulator = BasicSimulator()
    simulator.run()
