# ⚡ INICIO RÁPIDO - 5 MINUTOS
## De cero a tu primer escenario funcionando

### 🎯 **OBJETIVO**
En 5 minutos tendrás tu primer escenario DBA funcionando y podrás empezar a practicar inmediatamente.

---

## ✅ **PASO 1: VERIFICAR REQUISITOS (1 minuto)**

### **Requisito ÚNICO: Docker**
```bash
# Verificar que Docker esté instalado
docker --version
docker-compose --version

# Debe mostrar algo como:
# Docker version 20.10.x
# docker-compose version 1.29.x
```

### **Si NO tienes Docker:**
- **Windows/Mac:** Descargar Docker Desktop desde https://docker.com
- **Linux:** `sudo apt install docker.io docker-compose` (Ubuntu/Debian)

---

## 🔧 **PASO 2: PREPARAR EL ENTORNO (1 minuto)**

```bash
# Navegar al directorio del paquete
cd PAQUETE-ESTUDIANTES-DBA

# Dar permisos a las herramientas
chmod +x herramientas/*.sh
chmod +x herramientas/*.py

# Verificar que todo esté correcto
./herramientas/validador-sistema.sh
```

**✅ Resultado esperado:** Mensaje "Sistema listo para usar"

---

## 🚀 **PASO 3: INICIAR TU PRIMER ESCENARIO (2 minutos)**

### **Escenario Recomendado para Empezar:**
```bash
# Iniciar el escenario más fácil (MySQL Performance)
./herramientas/gestor-escenarios.sh start mysql/escenario-02-performance

# Esperar a que aparezca: "✅ Escenario iniciado correctamente"
```

### **Verificar que funciona:**
```bash
# Ver el estado
./herramientas/gestor-escenarios.sh status

# Debe mostrar contenedores corriendo
```

---

## 🎯 **PASO 4: ACCEDER A LAS INTERFACES (1 minuto)**

### **Abrir en tu navegador:**
- **Dashboard Personal:** http://localhost:3000 (admin/admin)
- **Base de Datos:** http://localhost:8083 (root/dba2024!)
- **Monitoreo:** http://localhost:9093

### **Verificar conexión:**
- Debes ver gráficas y métricas en tiempo real
- La base de datos debe mostrar tablas con datos

---

## 🎓 **¡LISTO! AHORA PUEDES EMPEZAR**

### **Tu primer diagnóstico:**
1. **Lee el problema:** `escenarios-practica/mysql/escenario-02-performance/problema-descripcion.md`
2. **Analiza los síntomas** en las interfaces web
3. **Ejecuta diagnósticos** usando los scripts incluidos
4. **Implementa la solución** paso a paso
5. **Verifica los resultados** con las métricas

### **Comandos útiles mientras practicas:**
```bash
# Ver logs en tiempo real
./herramientas/gestor-escenarios.sh logs mysql/escenario-02-performance

# Evaluar tu progreso
python herramientas/evaluador-progreso.py mysql/escenario-02-performance

# Cuando termines, limpiar
./herramientas/gestor-escenarios.sh stop mysql/escenario-02-performance
```

---

## 🆘 **SI ALGO NO FUNCIONA**

### **Problemas Comunes:**

#### **Error: Puerto ocupado**
```bash
./herramientas/gestor-escenarios.sh clean all
sudo lsof -i :3000  # Ver qué usa el puerto
```

#### **Error: Docker no responde**
```bash
# Reiniciar Docker
sudo systemctl restart docker  # Linux
# O reiniciar Docker Desktop en Windows/Mac
```

#### **Error: Sin espacio en disco**
```bash
docker system prune -a  # Limpiar todo Docker
```

#### **Error: Memoria insuficiente**
```bash
docker stats  # Ver uso de memoria
# Cerrar otros programas si es necesario
```

---

## 📚 **PRÓXIMOS PASOS**

### **Una vez que tengas funcionando tu primer escenario:**

1. **📖 Lee la guía completa:** `GUIA-COMPLETA-ESTUDIANTE.md`
2. **📅 Revisa el plan de estudio:** `PLAN-ESTUDIO-5-SEMANAS.md`
3. **🎯 Sigue la ruta recomendada** de escenarios
4. **📊 Monitorea tu progreso** en el dashboard personal

### **Escenarios recomendados para continuar:**
1. `postgresql/escenario-02-connections` (25 min)
2. `mongodb/escenario-02-indexing` (30 min)
3. `mysql/escenario-01-deadlocks` (45 min)

---

## 🎉 **¡FELICIDADES!**

**Ya tienes funcionando el sistema de práctica DBA más avanzado del mundo.**

- ✅ **Entorno profesional** listo para usar
- ✅ **Problemas reales** de producción
- ✅ **Herramientas de monitoreo** incluidas
- ✅ **Evaluación automática** de tu progreso

**🚀 ¡Ahora a practicar y convertirte en un DBA experto!**

---

### **Comandos de Referencia Rápida:**
```bash
# Listar escenarios
./herramientas/gestor-escenarios.sh list

# Iniciar escenario
./herramientas/gestor-escenarios.sh start [escenario]

# Ver estado
./herramientas/gestor-escenarios.sh status

# Ver logs
./herramientas/gestor-escenarios.sh logs [escenario]

# Detener escenario
./herramientas/gestor-escenarios.sh stop [escenario]

# Limpiar todo
./herramientas/gestor-escenarios.sh clean all
```

**💡 Tip:** Guarda estos comandos, los usarás constantemente.
