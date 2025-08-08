#!/usr/bin/env python3
"""
Simulador de Datos Desbalanceados para MongoDB Sharding
Genera patrones que causan hotspots y desbalance en el cluster
"""

import pymongo
import threading
import time
import random
import logging
import os
from datetime import datetime, timedelta
import json

# Configuración de logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(threadName)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler('/app/logs/sharding_simulator.log'),
        logging.StreamHandler()
    ]
)

class ShardingImbalanceSimulator:
    def __init__(self):
        self.mongo_host = os.getenv('MONGO_HOST', 'mongos-router')
        self.mongo_port = int(os.getenv('MONGO_PORT', 27017))
        self.db_name = os.getenv('MONGO_DB', 'sensornet_db')
        
        # Configuración del problema
        self.hotspot_start = int(os.getenv('HOTSPOT_SENSOR_RANGE_START', 1000))
        self.hotspot_end = int(os.getenv('HOTSPOT_SENSOR_RANGE_END', 2000))
        self.hotspot_probability = float(os.getenv('HOTSPOT_PROBABILITY', 0.8))
        self.total_sensors = int(os.getenv('TOTAL_SENSORS', 10000))
        self.readings_per_second = int(os.getenv('READINGS_PER_SECOND', 100))
        
        self.running = True
        
        # Tipos de dispositivos con diferentes patrones
        self.device_types = {
            'temperature': {'weight': 0.4, 'data_size': 'small'},
            'humidity': {'weight': 0.3, 'data_size': 'small'},
            'pressure': {'weight': 0.15, 'data_size': 'medium'},
            'vibration': {'weight': 0.1, 'data_size': 'large'},
            'camera': {'weight': 0.05, 'data_size': 'xlarge'}
        }
        
        # Ubicaciones geográficas (algunas más activas)
        self.locations = {
            'datacenter_1': {'weight': 0.5, 'region': 'us-east'},
            'datacenter_2': {'weight': 0.25, 'region': 'us-west'},
            'datacenter_3': {'weight': 0.15, 'region': 'eu-west'},
            'datacenter_4': {'weight': 0.1, 'region': 'asia-pacific'}
        }
        
    def get_connection(self):
        """Obtiene conexión a MongoDB"""
        client = pymongo.MongoClient(self.mongo_host, self.mongo_port)
        return client[self.db_name]
    
    def generate_sensor_reading(self):
        """Genera una lectura de sensor con patrón problemático"""
        
        # PATRÓN PROBLEMÁTICO: 80% de los datos en el rango hotspot
        if random.random() < self.hotspot_probability:
            sensor_id = random.randint(self.hotspot_start, self.hotspot_end)
        else:
            # 20% distribuido en el resto
            sensor_id = random.randint(1, self.total_sensors)
            if self.hotspot_start <= sensor_id <= self.hotspot_end:
                # Evitar el rango hotspot en el 20%
                sensor_id = random.randint(self.hotspot_end + 1, self.total_sensors)
        
        # Seleccionar tipo de dispositivo (algunos generan más datos)
        device_type = random.choices(
            list(self.device_types.keys()),
            weights=[info['weight'] for info in self.device_types.values()]
        )[0]
        
        # Seleccionar ubicación (algunas más activas)
        location = random.choices(
            list(self.locations.keys()),
            weights=[info['weight'] for info in self.locations.values()]
        )[0]
        
        # Generar datos según el tipo de dispositivo
        data_size = self.device_types[device_type]['data_size']
        
        if data_size == 'small':
            sensor_data = {
                'value': round(random.uniform(0, 100), 2),
                'unit': 'celsius' if device_type == 'temperature' else 'percent'
            }
        elif data_size == 'medium':
            sensor_data = {
                'value': round(random.uniform(900, 1100), 2),
                'unit': 'hPa',
                'calibration': {
                    'offset': random.uniform(-0.5, 0.5),
                    'scale': random.uniform(0.98, 1.02)
                }
            }
        elif data_size == 'large':
            sensor_data = {
                'x_axis': [random.uniform(-10, 10) for _ in range(100)],
                'y_axis': [random.uniform(-10, 10) for _ in range(100)],
                'z_axis': [random.uniform(-10, 10) for _ in range(100)],
                'frequency': random.randint(1000, 5000),
                'amplitude': random.uniform(0.1, 2.0)
            }
        else:  # xlarge
            sensor_data = {
                'image_metadata': {
                    'resolution': '1920x1080',
                    'format': 'jpeg',
                    'size_bytes': random.randint(500000, 2000000)
                },
                'analysis': {
                    'objects_detected': random.randint(0, 10),
                    'confidence_scores': [random.uniform(0.5, 1.0) for _ in range(random.randint(1, 5))],
                    'processing_time_ms': random.randint(100, 1000)
                },
                'raw_data': 'x' * random.randint(1000, 5000)  # Simular datos grandes
            }
        
        return {
            'sensor_id': sensor_id,
            'device_type': device_type,
            'location': location,
            'region': self.locations[location]['region'],
            'timestamp': datetime.utcnow(),
            'sensor_data': sensor_data,
            'metadata': {
                'battery_level': random.randint(10, 100),
                'signal_strength': random.randint(-100, -30),
                'firmware_version': f"v{random.randint(1, 5)}.{random.randint(0, 9)}.{random.randint(0, 9)}"
            }
        }
    
    def sensor_data_generator(self, worker_id):
        """Genera datos de sensores continuamente"""
        db = self.get_connection()
        collection = db.sensor_readings
        
        batch_size = 50
        batch = []
        
        while self.running:
            try:
                # Generar batch de lecturas
                for _ in range(batch_size):
                    reading = self.generate_sensor_reading()
                    batch.append(reading)
                
                # Insertar batch
                result = collection.insert_many(batch)
                logging.info(f"DataGenerator {worker_id}: Insertadas {len(result.inserted_ids)} lecturas")
                
                batch = []  # Limpiar batch
                
                # Controlar velocidad de inserción
                time.sleep(batch_size / self.readings_per_second)
                
            except Exception as e:
                logging.error(f"DataGenerator {worker_id}: Error - {e}")
                time.sleep(5)
    
    def device_metadata_generator(self, worker_id):
        """Genera y actualiza metadatos de dispositivos"""
        db = self.get_connection()
        collection = db.device_metadata
        
        while self.running:
            try:
                # Generar metadatos para dispositivos en el rango hotspot
                devices_batch = []
                
                for _ in range(100):
                    # PROBLEMA: Concentrar metadatos en el mismo rango problemático
                    if random.random() < 0.7:
                        device_id = random.randint(self.hotspot_start, self.hotspot_end)
                    else:
                        device_id = random.randint(1, self.total_sensors)
                    
                    device_type = random.choice(list(self.device_types.keys()))
                    location = random.choice(list(self.locations.keys()))
                    
                    device_metadata = {
                        'device_id': device_id,
                        'device_type': device_type,
                        'location': location,
                        'region': self.locations[location]['region'],
                        'installation_date': datetime.utcnow() - timedelta(days=random.randint(1, 365)),
                        'last_maintenance': datetime.utcnow() - timedelta(days=random.randint(1, 90)),
                        'specifications': {
                            'model': f"Model-{device_type.upper()}-{random.randint(100, 999)}",
                            'manufacturer': random.choice(['SensorTech', 'IoTCorp', 'DataDevices']),
                            'power_consumption': random.uniform(0.5, 5.0),
                            'operating_range': {
                                'min_temp': random.randint(-40, 0),
                                'max_temp': random.randint(50, 85),
                                'humidity_tolerance': random.randint(0, 95)
                            }
                        },
                        'status': random.choice(['active', 'maintenance', 'offline']),
                        'last_updated': datetime.utcnow()
                    }
                    
                    devices_batch.append(device_metadata)
                
                # Upsert batch de metadatos
                for device in devices_batch:
                    collection.replace_one(
                        {'device_id': device['device_id']},
                        device,
                        upsert=True
                    )
                
                logging.info(f"MetadataGenerator {worker_id}: Actualizados {len(devices_batch)} dispositivos")
                
                # Pausa entre actualizaciones
                time.sleep(300)  # 5 minutos
                
            except Exception as e:
                logging.error(f"MetadataGenerator {worker_id}: Error - {e}")
                time.sleep(30)
    
    def aggregated_metrics_generator(self, worker_id):
        """Genera métricas agregadas por hora"""
        db = self.get_connection()
        collection = db.aggregated_metrics
        
        while self.running:
            try:
                # Generar métricas agregadas
                current_hour = datetime.utcnow().replace(minute=0, second=0, microsecond=0)
                
                metrics_batch = []
                
                # Métricas por tipo de dispositivo y ubicación
                for device_type in self.device_types.keys():
                    for location in self.locations.keys():
                        # PROBLEMA: Timestamp monotónico causa hotspots temporales
                        metric = {
                            'timestamp': current_hour,
                            'metric_type': 'hourly_summary',
                            'device_type': device_type,
                            'location': location,
                            'region': self.locations[location]['region'],
                            'metrics': {
                                'total_readings': random.randint(100, 10000),
                                'avg_value': random.uniform(10, 90),
                                'min_value': random.uniform(0, 20),
                                'max_value': random.uniform(80, 100),
                                'error_count': random.randint(0, 50),
                                'offline_devices': random.randint(0, 10)
                            },
                            'created_at': datetime.utcnow()
                        }
                        metrics_batch.append(metric)
                
                # Insertar métricas
                result = collection.insert_many(metrics_batch)
                logging.info(f"MetricsGenerator {worker_id}: Insertadas {len(result.inserted_ids)} métricas agregadas")
                
                # Esperar hasta la siguiente hora
                time.sleep(3600)  # 1 hora
                
            except Exception as e:
                logging.error(f"MetricsGenerator {worker_id}: Error - {e}")
                time.sleep(300)
    
    def start_simulation(self):
        """Inicia la simulación de datos desbalanceados"""
        logging.info("Iniciando simulación de sharding imbalance...")
        
        threads = []
        
        # Crear threads de generación de datos de sensores
        for i in range(3):
            thread = threading.Thread(
                target=self.sensor_data_generator,
                args=(i,),
                name=f"DataGenerator-{i}"
            )
            thread.daemon = True
            threads.append(thread)
            thread.start()
        
        # Crear thread de metadatos de dispositivos
        thread = threading.Thread(
            target=self.device_metadata_generator,
            args=(0,),
            name="MetadataGenerator-0"
        )
        thread.daemon = True
        threads.append(thread)
        thread.start()
        
        # Crear thread de métricas agregadas
        thread = threading.Thread(
            target=self.aggregated_metrics_generator,
            args=(0,),
            name="MetricsGenerator-0"
        )
        thread.daemon = True
        threads.append(thread)
        thread.start()
        
        logging.info(f"Simulación iniciada - Generando datos desbalanceados")
        logging.info(f"Hotspot range: {self.hotspot_start}-{self.hotspot_end} ({self.hotspot_probability*100}% de datos)")
        
        try:
            # Mantener simulación corriendo
            while True:
                time.sleep(60)
                logging.info("Simulación activa - generando desbalance...")
        except KeyboardInterrupt:
            logging.info("Deteniendo simulación...")
            self.running = False
            
            # Esperar que terminen los threads
            for thread in threads:
                thread.join(timeout=10)

if __name__ == "__main__":
    simulator = ShardingImbalanceSimulator()
    simulator.start_simulation()
