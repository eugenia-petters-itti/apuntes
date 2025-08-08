# ⚡ INICIO RÁPIDO - 5 MINUTOS

## 🚀 Tu Primer Escenario DBA en 5 Minutos

### Paso 1: Verificar Requisitos (30 segundos)
```bash
# Verificar que tienes Docker
docker --version
docker-compose --version

# Si no tienes Docker, instálalo primero
```

### Paso 2: Navegar al Sistema (15 segundos)
```bash
cd /ruta/a/tu/sistema/07-herramientas-soporte
```

### Paso 3: Validar Sistema (30 segundos)
```bash
./scripts-utilitarios/validacion-final-simple.sh
# Debes ver: "🎉 SISTEMA ALTAMENTE FUNCIONAL (100%)"
```

### Paso 4: Ir al Escenario MySQL Deadlocks (15 segundos)
```bash
cd escenarios-diagnostico/mysql/escenario-01-deadlocks
```

### Paso 5: Levantar el Entorno (1 minuto)
```bash
# Levantar todos los servicios
docker-compose up -d

# Verificar que estén corriendo
docker-compose ps
```

### Paso 6: Ejecutar Simulador de Problemas (30 segundos)
```bash
# Ejecutar simulador en background
docker-compose exec -d simulator python3 main_simulator.py

# Ver que está generando deadlocks
docker-compose logs -f simulator
```

### Paso 7: Acceder a Herramientas (1 minuto)
```bash
# Abrir Grafana en navegador
open http://localhost:3000
# Usuario: admin, Password: admin

# En otra terminal, conectar a MySQL
docker-compose exec mysql-db mysql -u root -pdba2024! training_db
```

### Paso 8: Ver el Problema en Acción (1 minuto)
```sql
-- En MySQL, ejecutar:
SHOW ENGINE INNODB STATUS\G

-- Buscar sección "LATEST DETECTED DEADLOCK"
-- Verás deadlocks reales generados por el simulador
```

### Paso 9: Usar Herramientas de Diagnóstico (30 segundos)
```bash
# Salir de MySQL (Ctrl+D) y ejecutar:
cd ../../../herramientas-diagnostico/scripts-monitoring/mysql/
./deadlock_monitor.sh
```

### Paso 10: Limpiar (30 segundos)
```bash
# Cuando termines, limpiar:
cd ../../../escenarios-diagnostico/mysql/escenario-01-deadlocks/
docker-compose down
```

---

## 🎯 ¡Listo! Ya Experimentaste:

✅ **Simulación realista** de deadlocks MySQL  
✅ **Monitoreo en tiempo real** con Grafana  
✅ **Diagnóstico práctico** con herramientas profesionales  
✅ **Entorno seguro** con Docker  

---

## 🔥 Próximos Pasos Rápidos:

### Probar Otros Escenarios (5 min cada uno):
```bash
# PostgreSQL Vacuum Issues
cd ../../../postgresql/escenario-01-vacuum
docker-compose up -d

# MongoDB Sharding Problems  
cd ../../../mongodb/escenario-01-sharding
docker-compose up -d
```

### Ver Tutorial Completo:
```bash
cat ../../../documentacion/TUTORIAL-COMPLETO-USO.md
```

---

## 🆘 Si Algo No Funciona:

### Problema: Docker no inicia
```bash
# Reiniciar Docker Desktop o daemon
sudo systemctl restart docker  # Linux
```

### Problema: Puerto ocupado
```bash
# Ver qué usa el puerto 3306
netstat -tulpn | grep :3306

# Cambiar puerto en docker-compose.yml si es necesario
```

### Problema: Simulador no funciona
```bash
# Ver logs detallados
docker-compose logs simulator

# Reconstruir si es necesario
docker-compose build simulator
```

---

## 💡 Consejos Rápidos:

- **Grafana:** Los dashboards están preconfigurados
- **MySQL:** Password siempre es `dba2024!`
- **Logs:** Usa `docker-compose logs -f [servicio]` para ver en tiempo real
- **Limpieza:** Siempre ejecuta `docker-compose down` al terminar

---

**¡En 5 minutos ya estás usando un sistema profesional de entrenamiento DBA!** 🎓

*Para aprender más, consulta el tutorial completo en `documentacion/TUTORIAL-COMPLETO-USO.md`*
