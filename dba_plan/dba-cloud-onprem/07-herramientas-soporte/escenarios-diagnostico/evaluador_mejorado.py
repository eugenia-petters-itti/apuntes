#!/usr/bin/env python3
"""
Enhanced Automatic Evaluator for DBA Scenarios
Provides real database validation and detailed scoring
"""

import os
import sys
import json
import time
import mysql.connector
import psycopg2
import pymongo
from datetime import datetime
from typing import Dict, List, Any

class EnhancedEvaluator:
    def __init__(self, scenario_path: str):
        self.scenario_path = scenario_path
        self.scenario_type = self.detect_scenario_type()
        self.score = 0
        self.max_score = 100
        self.results = []
        
    def detect_scenario_type(self) -> str:
        """Detect scenario type from path"""
        if 'mysql' in self.scenario_path:
            return 'mysql'
        elif 'postgresql' in self.scenario_path:
            return 'postgresql'
        elif 'mongodb' in self.scenario_path:
            return 'mongodb'
        return 'unknown'
    
    def test_mysql_deadlock_resolution(self) -> Dict[str, Any]:
        """Test MySQL deadlock scenario resolution"""
        try:
            conn = mysql.connector.connect(
                host='localhost',
                user='root',
                password='dba2024!',
                database='training_db'
            )
            cursor = conn.cursor()
            
            # Check deadlock statistics
            cursor.execute("SHOW GLOBAL STATUS LIKE 'Innodb_deadlocks'")
            deadlocks = cursor.fetchone()[1]
            
            # Check configuration
            cursor.execute("SHOW VARIABLES LIKE 'innodb_deadlock_detect'")
            deadlock_detect = cursor.fetchone()[1]
            
            score = 0
            if deadlock_detect == 'ON':
                score += 25
            if int(deadlocks) > 0:
                score += 25  # Deadlocks were generated
                
            conn.close()
            
            return {
                'test': 'MySQL Deadlock Resolution',
                'score': score,
                'max_score': 50,
                'details': f'Deadlocks: {deadlocks}, Detection: {deadlock_detect}'
            }
        except Exception as e:
            return {
                'test': 'MySQL Deadlock Resolution',
                'score': 0,
                'max_score': 50,
                'error': str(e)
            }
    
    def test_postgresql_vacuum_optimization(self) -> Dict[str, Any]:
        """Test PostgreSQL vacuum scenario resolution"""
        try:
            conn = psycopg2.connect(
                host='localhost',
                user='app_user',
                password='app_pass',
                database='training_db'
            )
            cursor = conn.cursor()
            
            # Check dead tuples
            cursor.execute("""
                SELECT SUM(n_dead_tup), SUM(n_live_tup)
                FROM pg_stat_user_tables
            """)
            dead_tup, live_tup = cursor.fetchone()
            
            score = 0
            if dead_tup is not None and live_tup is not None:
                dead_ratio = dead_tup / (live_tup + dead_tup) if (live_tup + dead_tup) > 0 else 0
                if dead_ratio < 0.1:  # Less than 10% dead tuples
                    score += 30
                elif dead_ratio < 0.2:
                    score += 20
                else:
                    score += 10
                    
            conn.close()
            
            return {
                'test': 'PostgreSQL Vacuum Optimization',
                'score': score,
                'max_score': 30,
                'details': f'Dead tuples: {dead_tup}, Live tuples: {live_tup}'
            }
        except Exception as e:
            return {
                'test': 'PostgreSQL Vacuum Optimization',
                'score': 0,
                'max_score': 30,
                'error': str(e)
            }
    
    def evaluate_scenario(self) -> Dict[str, Any]:
        """Evaluate the specific scenario"""
        if self.scenario_type == 'mysql':
            if 'deadlock' in self.scenario_path:
                result = self.test_mysql_deadlock_resolution()
            else:
                result = {'test': 'Generic MySQL Test', 'score': 50, 'max_score': 100}
        elif self.scenario_type == 'postgresql':
            if 'vacuum' in self.scenario_path:
                result = self.test_postgresql_vacuum_optimization()
            else:
                result = {'test': 'Generic PostgreSQL Test', 'score': 50, 'max_score': 100}
        else:
            result = {'test': 'Generic Test', 'score': 50, 'max_score': 100}
            
        self.results.append(result)
        self.score += result['score']
        return result
    
    def generate_report(self) -> str:
        """Generate evaluation report"""
        report = {
            'scenario_path': self.scenario_path,
            'scenario_type': self.scenario_type,
            'timestamp': datetime.now().isoformat(),
            'total_score': self.score,
            'max_score': self.max_score,
            'percentage': round((self.score / self.max_score) * 100, 2),
            'results': self.results
        }
        
        return json.dumps(report, indent=2)

if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Usage: python evaluador_mejorado.py <scenario_path>")
        sys.exit(1)
        
    evaluator = EnhancedEvaluator(sys.argv[1])
    result = evaluator.evaluate_scenario()
    print(evaluator.generate_report())
