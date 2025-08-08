#!/usr/bin/env python3
"""
Simulador de Problemas de VACUUM para PostgreSQL
Genera patrones de carga que causan bloat y problemas de performance
"""

import psycopg2
import threading
import time
import random
import logging
import os
from datetime import datetime, timedelta

# Configuración de logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(threadName)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler('/app/logs/vacuum_problem_simulator.log'),
        logging.StreamHandler()
    ]
)

class VacuumProblemSimulator:
    def __init__(self):
        self.db_config = {
            'host': os.getenv('DB_HOST', 'postgres-vacuum'),
            'user': os.getenv('DB_USER', 'postgres'),
            'password': os.getenv('DB_PASS', 'dba2024!'),
            'database': os.getenv('DB_NAME', 'dataflow_db'),
            'port': 5432
        }
        
        # Configuración del problema
        self.etl_batch_size = int(os.getenv('ETL_BATCH_SIZE', 100000))
        self.update_frequency = int(os.getenv('UPDATE_FREQUENCY', 30))
        self.delete_frequency = int(os.getenv('DELETE_FREQUENCY', 3600))
        self.concurrent_sessions = int(os.getenv('CONCURRENT_SESSIONS', 50))
        
        self.running = True
        
    def get_connection(self):
        """Obtiene conexión a PostgreSQL"""
        return psycopg2.connect(**self.db_config)
    
    def etl_process(self, worker_id):
        """Simula proceso ETL que causa bloat masivo"""
        while self.running:
            try:
                conn = self.get_connection()
                conn.autocommit = False
                cursor = conn.cursor()
                
                logging.info(f"ETL {worker_id}: Iniciando batch de {self.etl_batch_size} registros")
                
                # PATRÓN PROBLEMÁTICO: INSERT masivo seguido de UPDATE masivo
                # Esto causa que las páginas se llenen y luego se fragmenten
                
                # 1. INSERT masivo de eventos
                events_data = []
                for i in range(self.etl_batch_size):
                    events_data.append((
                        random.randint(1, 10000),  # user_id
                        f'event_type_{random.randint(1, 20)}',
                        f'{{"data": "value_{random.randint(1, 1000)}"}}',
                        datetime.now() - timedelta(minutes=random.randint(0, 1440))
                    ))
                
                cursor.executemany("""
                    INSERT INTO events (user_id, event_type, event_data, created_at)
                    VALUES (%s, %s, %s, %s)
                """, events_data)
                
                conn.commit()
                logging.info(f"ETL {worker_id}: Insertados {self.etl_batch_size} eventos")
                
                # 2. UPDATE masivo que causa fragmentación
                # Simular enriquecimiento de datos
                time.sleep(random.uniform(1, 3))  # Simular procesamiento
                
                cursor.execute("""
                    UPDATE events 
                    SET event_data = event_data || '{"processed": true, "timestamp": "' || NOW() || '"}'
                    WHERE created_at >= %s
                    AND event_data::text NOT LIKE '%processed%'
                """, (datetime.now() - timedelta(minutes=30),))
                
                updated_rows = cursor.rowcount
                conn.commit()
                logging.info(f"ETL {worker_id}: Actualizados {updated_rows} eventos")
                
                # 3. DELETE de datos antiguos (causa más fragmentación)
                cursor.execute("""
                    DELETE FROM events 
                    WHERE created_at < %s
                    AND event_type LIKE 'temp_%'
                """, (datetime.now() - timedelta(days=1),))
                
                deleted_rows = cursor.rowcount
                conn.commit()
                logging.info(f"ETL {worker_id}: Eliminados {deleted_rows} eventos temporales")
                
                cursor.close()
                conn.close()
                
            except psycopg2.Error as e:
                logging.error(f"ETL {worker_id}: Error DB - {e}")
                try:
                    conn.rollback()
                    cursor.close()
                    conn.close()
                except:
                    pass
            
            # Pausa entre batches ETL
            time.sleep(random.uniform(300, 600))  # 5-10 minutos
    
    def session_updater_process(self, worker_id):
        """Simula actualizaciones frecuentes de sesiones (causa bloat)"""
        while self.running:
            try:
                conn = self.get_connection()
                conn.autocommit = False
                cursor = conn.cursor()
                
                # PATRÓN PROBLEMÁTICO: UPDATEs muy frecuentes en las mismas filas
                # Esto causa que PostgreSQL mantenga múltiples versiones (bloat)
                
                # Seleccionar sesiones activas para actualizar
                active_sessions = random.sample(range(1, 10001), 
                                               min(100, self.concurrent_sessions))
                
                for session_id in active_sessions:
                    # UPDATE que cambia datos frecuentemente
                    cursor.execute("""
                        UPDATE user_sessions 
                        SET 
                            last_activity = NOW(),
                            page_views = page_views + %s,
                            session_data = session_data || %s
                        WHERE session_id = %s
                    """, (
                        random.randint(1, 5),
                        f'{{"last_page": "page_{random.randint(1, 100)}", "timestamp": "{datetime.now()}"}}',
                        session_id
                    ))
                
                conn.commit()
                logging.info(f"SessionUpdater {worker_id}: Actualizadas {len(active_sessions)} sesiones")
                
                cursor.close()
                conn.close()
                
            except psycopg2.Error as e:
                logging.error(f"SessionUpdater {worker_id}: Error DB - {e}")
                try:
                    conn.rollback()
                    cursor.close()
                    conn.close()
                except:
                    pass
            
            # Actualizar cada 30 segundos (muy frecuente)
            time.sleep(self.update_frequency)
    
    def cache_manager_process(self, worker_id):
        """Simula gestión de cache que causa bloat extremo"""
        while self.running:
            try:
                conn = self.get_connection()
                conn.autocommit = False
                cursor = conn.cursor()
                
                logging.info(f"CacheManager {worker_id}: Iniciando limpieza de cache")
                
                # PATRÓN MUY PROBLEMÁTICO: DELETE + INSERT masivo
                # Esto causa fragmentación extrema
                
                # 1. DELETE masivo de cache antiguo
                cursor.execute("""
                    DELETE FROM analytics_cache 
                    WHERE created_at < %s
                """, (datetime.now() - timedelta(hours=6),))
                
                deleted_rows = cursor.rowcount
                logging.info(f"CacheManager {worker_id}: Eliminadas {deleted_rows} entradas de cache")
                
                # 2. INSERT masivo de nuevo cache
                cache_data = []
                for i in range(random.randint(10000, 50000)):
                    cache_data.append((
                        f'metric_{random.randint(1, 1000)}',
                        f'dimension_{random.randint(1, 100)}',
                        random.uniform(0, 10000),
                        f'{{"calculation": "complex_aggregation_{i}", "metadata": "data_{random.randint(1, 1000)}"}}',
                        datetime.now()
                    ))
                
                cursor.executemany("""
                    INSERT INTO analytics_cache (metric_name, dimension, value, metadata, created_at)
                    VALUES (%s, %s, %s, %s, %s)
                """, cache_data)
                
                conn.commit()
                logging.info(f"CacheManager {worker_id}: Insertadas {len(cache_data)} nuevas entradas de cache")
                
                cursor.close()
                conn.close()
                
            except psycopg2.Error as e:
                logging.error(f"CacheManager {worker_id}: Error DB - {e}")
                try:
                    conn.rollback()
                    cursor.close()
                    conn.close()
                except:
                    pass
            
            # Limpieza cada 2 horas
            time.sleep(7200)
    
    def audit_log_process(self, worker_id):
        """Simula logs de auditoría (solo INSERT, pero volumen alto)"""
        while self.running:
            try:
                conn = self.get_connection()
                conn.autocommit = True  # Autocommit para logs
                cursor = conn.cursor()
                
                # INSERT continuo de logs (causa crecimiento constante)
                for _ in range(random.randint(100, 500)):
                    cursor.execute("""
                        INSERT INTO audit_logs (user_id, action, table_name, record_id, changes, created_at)
                        VALUES (%s, %s, %s, %s, %s, NOW())
                    """, (
                        random.randint(1, 10000),
                        random.choice(['SELECT', 'INSERT', 'UPDATE', 'DELETE']),
                        random.choice(['events', 'user_sessions', 'analytics_cache']),
                        random.randint(1, 1000000),
                        f'{{"old": "value_{random.randint(1, 1000)}", "new": "value_{random.randint(1, 1000)}"}}'
                    ))
                
                logging.info(f"AuditLog {worker_id}: Insertados logs de auditoría")
                
                cursor.close()
                conn.close()
                
            except psycopg2.Error as e:
                logging.error(f"AuditLog {worker_id}: Error DB - {e}")
                try:
                    cursor.close()
                    conn.close()
                except:
                    pass
            
            # Logs cada 10 segundos
            time.sleep(10)
    
    def start_simulation(self):
        """Inicia la simulación de problemas de VACUUM"""
        logging.info("Iniciando simulación de problemas de VACUUM...")
        
        threads = []
        
        # Crear threads ETL (causan bloat masivo)
        for i in range(2):
            thread = threading.Thread(
                target=self.etl_process,
                args=(i,),
                name=f"ETL-{i}"
            )
            thread.daemon = True
            threads.append(thread)
            thread.start()
        
        # Crear threads de actualización de sesiones (bloat por UPDATEs frecuentes)
        for i in range(3):
            thread = threading.Thread(
                target=self.session_updater_process,
                args=(i,),
                name=f"SessionUpdater-{i}"
            )
            thread.daemon = True
            threads.append(thread)
            thread.start()
        
        # Crear thread de gestión de cache (bloat extremo)
        thread = threading.Thread(
            target=self.cache_manager_process,
            args=(0,),
            name="CacheManager-0"
        )
        thread.daemon = True
        threads.append(thread)
        thread.start()
        
        # Crear threads de logs de auditoría (crecimiento constante)
        for i in range(2):
            thread = threading.Thread(
                target=self.audit_log_process,
                args=(i,),
                name=f"AuditLog-{i}"
            )
            thread.daemon = True
            threads.append(thread)
            thread.start()
        
        logging.info("Simulación de problemas de VACUUM iniciada")
        
        try:
            # Mantener simulación corriendo
            while True:
                time.sleep(30)
                logging.info("Simulación activa - generando bloat...")
        except KeyboardInterrupt:
            logging.info("Deteniendo simulación...")
            self.running = False
            
            # Esperar que terminen los threads
            for thread in threads:
                thread.join(timeout=10)

if __name__ == "__main__":
    simulator = VacuumProblemSimulator()
    simulator.start_simulation()
