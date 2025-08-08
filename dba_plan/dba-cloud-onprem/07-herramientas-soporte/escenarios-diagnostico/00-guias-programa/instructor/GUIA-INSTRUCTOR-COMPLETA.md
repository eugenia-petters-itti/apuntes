# 👨‍🏫 Guía Completa del Instructor
## Programa DBA Cloud OnPrem Junior

### 🎯 Visión General del Programa

Este programa está diseñado para transformar estudiantes junior en DBAs competentes con experiencia práctica en entornos híbridos OnPrem + Cloud.

### 📊 Estructura Pedagógica

#### Metodología 70/30:
- **70% Práctica:** Escenarios reales dockerizados
- **30% Teoría:** Conceptos fundamentales y mejores prácticas

#### Progresión de Aprendizaje:
1. **Diagnóstico** - Identificar problemas
2. **Análisis** - Entender causas raíz
3. **Solución** - Implementar fixes
4. **Verificación** - Confirmar resolución
5. **Documentación** - Capturar aprendizajes

### 🚀 Preparación del Curso

#### Setup Inicial:
```bash
# 1. Verificar infraestructura
./validador-sistema.sh

# 2. Probar todos los escenarios
for scenario in mysql/escenario-* postgresql/escenario-* mongodb/escenario-*; do
    echo "Probando $scenario..."
    ./gestor-escenarios.sh test "$scenario"
done

# 3. Preparar dashboard de instructor
open dashboard-instructor.html
```

#### Recursos Necesarios:
- **Hardware:** 16GB RAM, 100GB espacio libre
- **Software:** Docker, Docker Compose
- **Red:** Puertos 3000-3010, 8080-8090, 9090-9100
- **Tiempo:** 2 horas de preparación inicial

### 📋 Gestión de Escenarios

#### Comandos Esenciales:
```bash
# Ver estado general
./gestor-escenarios.sh status

# Iniciar escenario para demostración
./gestor-escenarios.sh start mysql/escenario-01-deadlocks

# Monitorear estudiantes
./gestor-escenarios.sh logs mysql/escenario-01-deadlocks

# Limpiar al final de clase
./gestor-escenarios.sh clean all
```

#### Dashboard de Instructor:
- **URL:** http://localhost:3000
- **Funciones:** Monitoreo en tiempo real, métricas de estudiantes
- **Alertas:** Problemas de infraestructura, escenarios caídos

### 🎓 Metodología de Enseñanza

#### Estructura de Clase (2 horas):
1. **Introducción** (15 min) - Contexto del problema
2. **Demostración** (20 min) - Mostrar síntomas
3. **Trabajo Individual** (60 min) - Estudiantes resuelven
4. **Revisión Grupal** (20 min) - Discutir soluciones
5. **Cierre** (5 min) - Lecciones aprendidas

#### Técnicas Pedagógicas:
- **Learning by Doing** - Experiencia práctica directa
- **Problem-Based Learning** - Casos reales de producción
- **Peer Learning** - Estudiantes se ayudan mutuamente
- **Gamification** - Sistema de puntos y rankings

### 📊 Sistema de Evaluación

#### Evaluación Automática:
```bash
# Evaluar estudiante específico
python evaluador-automatico.py mysql/escenario-01-deadlocks

# Generar reporte de clase
./gestor-escenarios.sh report all
```

#### Criterios de Evaluación:
- **Técnicos:** Solución correcta, eficiencia, mejores prácticas
- **Proceso:** Metodología de diagnóstico, documentación
- **Tiempo:** Resolución dentro del límite establecido
- **Comunicación:** Explicación clara de la solución

#### Rubrica de Puntuación:
- **90-100:** Solución óptima, proceso ejemplar
- **80-89:** Solución correcta, proceso sólido
- **70-79:** Solución funcional, proceso básico
- **60-69:** Solución parcial, necesita mejoras
- **<60:** No resuelto, requiere refuerzo

### 🔧 Gestión de Problemas Comunes

#### Issues Técnicos:
```bash
# Contenedor no inicia
docker-compose logs [servicio]
docker system prune -f

# Puerto ocupado
sudo lsof -i :[puerto]
./gestor-escenarios.sh clean all

# Performance lenta
docker stats
# Reducir número de escenarios simultáneos
```

#### Issues Pedagógicos:
- **Estudiante atascado:** Proporcionar pista progresiva
- **Solución incorrecta:** Guiar hacia análisis más profundo
- **Tiempo insuficiente:** Extender o simplificar escenario
- **Falta de engagement:** Gamificar más, agregar competencia

### 📈 Personalización del Programa

#### Adaptación por Audiencia:
- **Principiantes:** Más tiempo, más pistas, escenarios básicos
- **Intermedios:** Tiempo estándar, escenarios variados
- **Avanzados:** Menos tiempo, escenarios complejos, menos pistas

#### Configuración de Escenarios:
```yaml
# Archivo: escenario-config.yml
time_limit_minutes: 45  # Ajustar según nivel
max_hints: 3           # Reducir para avanzados
hint_penalty: 10       # Aumentar para motivar autonomía
```

### 📊 Métricas de Éxito del Curso

#### KPIs del Instructor:
- **Tasa de completación:** >85% de estudiantes completan
- **Satisfacción:** >4.5/5 en evaluaciones
- **Retención de conocimiento:** >80% en evaluación final
- **Aplicación práctica:** >70% usan conocimientos en trabajo

#### Reportes Disponibles:
- **Individual:** Progreso por estudiante
- **Grupal:** Estadísticas de la clase
- **Comparativo:** Rendimiento entre cohortes
- **Temporal:** Evolución del aprendizaje

### 🎯 Mejores Prácticas

#### Facilitación Efectiva:
1. **Establecer expectativas** claras desde el inicio
2. **Crear ambiente seguro** para experimentar y fallar
3. **Fomentar colaboración** entre estudiantes
4. **Proporcionar feedback** constructivo y oportuno
5. **Celebrar éxitos** individuales y grupales

#### Gestión del Tiempo:
- **Buffer time** para problemas técnicos
- **Checkpoints** regulares de progreso
- **Flexibilidad** para ajustar según ritmo del grupo
- **Extensiones** para casos especiales

### 🔄 Mejora Continua

#### Feedback Loop:
1. **Recopilar feedback** de estudiantes regularmente
2. **Analizar métricas** de performance de escenarios
3. **Actualizar contenido** basado en tendencias de la industria
4. **Refinar metodología** según resultados

#### Actualizaciones del Material:
- **Nuevos escenarios** basados en problemas emergentes
- **Mejoras técnicas** en la infraestructura
- **Optimizaciones pedagógicas** basadas en data
- **Integración de nuevas tecnologías**

---

**¡Éxito en tu rol como instructor transformador!** 🎓
