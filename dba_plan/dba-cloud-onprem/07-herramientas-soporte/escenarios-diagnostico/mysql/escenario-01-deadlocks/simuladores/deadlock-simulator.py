#!/usr/bin/env python3
"""
Simulador de Deadlocks para Escenario MySQL
Genera patrones realistas de deadlocks en e-commerce
"""

import mysql.connector
import threading
import time
import random
import logging
import os
from datetime import datetime

# Configuración de logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(threadName)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler('/app/logs/deadlock_simulator.log'),
        logging.StreamHandler()
    ]
)

class DeadlockSimulator:
    def __init__(self):
        self.db_config = {
            'host': os.getenv('DB_HOST', 'mysql-deadlock'),
            'user': os.getenv('DB_USER', 'app_user'),
            'password': os.getenv('DB_PASS', 'app_pass'),
            'database': os.getenv('DB_NAME', 'techstore_db'),
            'autocommit': False
        }
        
        # Configuración del problema
        self.concurrent_buyers = int(os.getenv('CONCURRENT_BUYERS', 20))
        self.concurrent_restockers = int(os.getenv('CONCURRENT_RESTOCKERS', 5))
        self.deadlock_probability = float(os.getenv('DEADLOCK_PROBABILITY', 0.3))
        
        # Productos para simular
        self.products = list(range(1, 101))  # 100 productos
        self.customers = list(range(1, 1001))  # 1000 clientes
        
        self.running = True
        
    def get_connection(self):
        """Obtiene conexión a la base de datos"""
        return mysql.connector.connect(**self.db_config)
    
    def buyer_process(self, buyer_id):
        """Simula proceso de compra que puede causar deadlocks"""
        while self.running:
            try:
                conn = self.get_connection()
                cursor = conn.cursor()
                
                # Seleccionar productos y cliente aleatoriamente
                customer_id = random.choice(self.customers)
                product1 = random.choice(self.products)
                product2 = random.choice(self.products)
                
                # Asegurar que sean productos diferentes
                while product2 == product1:
                    product2 = random.choice(self.products)
                
                # PATRÓN QUE CAUSA DEADLOCK:
                # Ordenar productos de forma inconsistente
                if random.random() < self.deadlock_probability:
                    # Orden que favorece deadlock
                    first_product, second_product = max(product1, product2), min(product1, product2)
                else:
                    # Orden consistente
                    first_product, second_product = min(product1, product2), max(product1, product2)
                
                logging.info(f"Buyer {buyer_id}: Iniciando compra - Cliente {customer_id}, Productos {first_product}, {second_product}")
                
                # Transacción de compra
                cursor.execute("START TRANSACTION")
                
                # 1. Verificar y reservar inventario del primer producto
                cursor.execute("""
                    SELECT stock FROM inventory 
                    WHERE product_id = %s FOR UPDATE
                """, (first_product,))
                
                stock1 = cursor.fetchone()
                if stock1 and stock1[0] > 0:
                    # Simular tiempo de procesamiento
                    time.sleep(random.uniform(0.1, 0.3))
                    
                    # 2. Verificar y reservar inventario del segundo producto
                    cursor.execute("""
                        SELECT stock FROM inventory 
                        WHERE product_id = %s FOR UPDATE
                    """, (second_product,))
                    
                    stock2 = cursor.fetchone()
                    if stock2 and stock2[0] > 0:
                        # 3. Crear orden
                        cursor.execute("""
                            INSERT INTO orders (customer_id, total_amount, status, created_at)
                            VALUES (%s, %s, 'processing', NOW())
                        """, (customer_id, random.uniform(50, 500)))
                        
                        order_id = cursor.lastrowid
                        
                        # 4. Actualizar inventario
                        cursor.execute("""
                            UPDATE inventory 
                            SET stock = stock - 1, last_updated = NOW()
                            WHERE product_id = %s
                        """, (first_product,))
                        
                        cursor.execute("""
                            UPDATE inventory 
                            SET stock = stock - 1, last_updated = NOW()
                            WHERE product_id = %s
                        """, (second_product,))
                        
                        # 5. Crear items de orden
                        cursor.execute("""
                            INSERT INTO order_items (order_id, product_id, quantity, price)
                            VALUES (%s, %s, 1, %s), (%s, %s, 1, %s)
                        """, (order_id, first_product, random.uniform(20, 100),
                              order_id, second_product, random.uniform(20, 100)))
                        
                        # 6. Procesar pago (simular delay)
                        time.sleep(random.uniform(0.2, 0.5))
                        
                        cursor.execute("""
                            INSERT INTO payments (order_id, amount, status, processed_at)
                            VALUES (%s, %s, 'completed', NOW())
                        """, (order_id, random.uniform(50, 500)))
                        
                        conn.commit()
                        logging.info(f"Buyer {buyer_id}: Compra exitosa - Orden {order_id}")
                    else:
                        conn.rollback()
                        logging.warning(f"Buyer {buyer_id}: Sin stock producto {second_product}")
                else:
                    conn.rollback()
                    logging.warning(f"Buyer {buyer_id}: Sin stock producto {first_product}")
                
                cursor.close()
                conn.close()
                
            except mysql.connector.Error as e:
                if "Deadlock found" in str(e):
                    logging.error(f"Buyer {buyer_id}: DEADLOCK detectado - {e}")
                else:
                    logging.error(f"Buyer {buyer_id}: Error DB - {e}")
                try:
                    conn.rollback()
                    cursor.close()
                    conn.close()
                except:
                    pass
            
            # Pausa entre transacciones
            time.sleep(random.uniform(0.5, 2.0))
    
    def restock_process(self, restock_id):
        """Simula proceso de restock que puede causar deadlocks"""
        while self.running:
            try:
                conn = self.get_connection()
                cursor = conn.cursor()
                
                # Seleccionar múltiples productos para restock
                products_to_restock = random.sample(self.products, random.randint(3, 8))
                
                logging.info(f"Restock {restock_id}: Iniciando restock - Productos {products_to_restock}")
                
                cursor.execute("START TRANSACTION")
                
                # Actualizar inventario en orden aleatorio (causa deadlocks)
                random.shuffle(products_to_restock)
                
                for product_id in products_to_restock:
                    # Bloquear producto para actualización
                    cursor.execute("""
                        SELECT stock FROM inventory 
                        WHERE product_id = %s FOR UPDATE
                    """, (product_id,))
                    
                    current_stock = cursor.fetchone()[0]
                    new_stock = current_stock + random.randint(10, 50)
                    
                    # Simular tiempo de procesamiento
                    time.sleep(random.uniform(0.1, 0.2))
                    
                    cursor.execute("""
                        UPDATE inventory 
                        SET stock = %s, last_updated = NOW()
                        WHERE product_id = %s
                    """, (new_stock, product_id))
                    
                    # Log de restock
                    cursor.execute("""
                        INSERT INTO inventory_logs (product_id, old_stock, new_stock, operation, created_at)
                        VALUES (%s, %s, %s, 'restock', NOW())
                    """, (product_id, current_stock, new_stock))
                
                conn.commit()
                logging.info(f"Restock {restock_id}: Restock exitoso")
                
                cursor.close()
                conn.close()
                
            except mysql.connector.Error as e:
                if "Deadlock found" in str(e):
                    logging.error(f"Restock {restock_id}: DEADLOCK detectado - {e}")
                else:
                    logging.error(f"Restock {restock_id}: Error DB - {e}")
                try:
                    conn.rollback()
                    cursor.close()
                    conn.close()
                except:
                    pass
            
            # Pausa entre restocks
            time.sleep(random.uniform(5, 15))
    
    def start_simulation(self):
        """Inicia la simulación de deadlocks"""
        logging.info("Iniciando simulación de deadlocks...")
        
        threads = []
        
        # Crear threads de compradores
        for i in range(self.concurrent_buyers):
            thread = threading.Thread(
                target=self.buyer_process,
                args=(i,),
                name=f"Buyer-{i}"
            )
            thread.daemon = True
            threads.append(thread)
            thread.start()
        
        # Crear threads de restock
        for i in range(self.concurrent_restockers):
            thread = threading.Thread(
                target=self.restock_process,
                args=(i,),
                name=f"Restock-{i}"
            )
            thread.daemon = True
            threads.append(thread)
            thread.start()
        
        logging.info(f"Simulación iniciada: {self.concurrent_buyers} compradores, {self.concurrent_restockers} restockers")
        
        try:
            # Mantener simulación corriendo
            while True:
                time.sleep(10)
                logging.info("Simulación activa...")
        except KeyboardInterrupt:
            logging.info("Deteniendo simulación...")
            self.running = False
            
            # Esperar que terminen los threads
            for thread in threads:
                thread.join(timeout=5)

if __name__ == "__main__":
    simulator = DeadlockSimulator()
    simulator.start_simulation()
