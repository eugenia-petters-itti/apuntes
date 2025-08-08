# Escenario MySQL 02: Crisis de Performance
## 🟢 Nivel: Básico | Tiempo estimado: 30 minutos

### 📋 Contexto del Problema

**Empresa:** E-learning "EduTech Solutions"
**Sistema:** Plataforma de cursos online
**Horario:** Lunes 08:00 - Inicio de semana laboral
**Urgencia:** ALTA - Dashboard de estudiantes extremadamente lento

### 🚨 Síntomas Reportados

**Reporte del equipo de desarrollo:**
```
"El dashboard principal que muestra los cursos tarda más de 30 segundos en cargar.
Las consultas de búsqueda de cursos fallan por timeout.
Los reportes de progreso de estudiantes no cargan.
La base de datos parece estar funcionando pero muy lenta."
```

**Métricas observadas:**
- ⚠️ Tiempo de carga del dashboard: 30-45 segundos (normal: 2-3 seg)
- ⚠️ Queries de búsqueda: >20 segundos (normal: <1 seg)
- ⚠️ CPU del servidor: 45% (normal, pero I/O muy alto)
- ⚠️ Conexiones activas: 25/100 (normal)
- ⚠️ Slow query log: 150+ queries/minuto

### 📊 Datos Disponibles

**Tablas principales afectadas:**
- `courses` - Catálogo de cursos (50,000 registros)
- `enrollments` - Inscripciones de estudiantes (500,000 registros)
- `lessons` - Lecciones por curso (200,000 registros)
- `student_progress` - Progreso de estudiantes (1,000,000 registros)
- `users` - Usuarios del sistema (100,000 registros)

**Queries problemáticas identificadas:**
1. **Dashboard principal** - Lista cursos con estadísticas
2. **Búsqueda de cursos** - Filtros por categoría y texto
3. **Progreso de estudiante** - Cálculos de porcentaje completado
4. **Reportes de instructor** - Agregaciones complejas

### 🎯 Tu Misión

Como DBA Junior, debes:

1. **Identificar queries lentas** usando herramientas de MySQL
2. **Analizar planes de ejecución** de las queries problemáticas
3. **Crear índices optimizados** para mejorar performance
4. **Optimizar queries existentes** si es necesario
5. **Verificar mejora de performance** con métricas

### 📈 Criterios de Éxito

**Resolución exitosa cuando:**
- ✅ Dashboard carga en <5 segundos
- ✅ Búsquedas responden en <2 segundos
- ✅ Slow queries reducidas a <10/minuto
- ✅ I/O Wait <20%
- ✅ Índices apropiados creados y utilizados

### 🔧 Herramientas Disponibles

**En el contenedor MySQL:**
- Slow query log habilitado
- Performance Schema activo
- Herramientas de análisis de queries
- Datos de prueba realistas cargados

**Scripts de diagnóstico:**
- `slow-query-analyzer.sql`
- `index-analyzer.sql`
- `query-optimizer.sql`
- `performance-monitor.sql`

### ⏰ Cronómetro

**Tiempo límite:** 30 minutos
**Pistas disponibles:** 3 (penalización: -10 puntos cada una)
**Puntuación máxima:** 100 puntos

---

**¿Listo para comenzar?** 
Ejecuta: `docker-compose up -d` en el directorio del escenario.
