# Escenario MySQL 08: Brecha de Seguridad
## 🔴 Nivel: Avanzado | Tiempo estimado: 45 minutos

### 📋 Contexto del Problema

**Empresa:** E-commerce "ShopSecure"
**Sistema:** Base de datos de usuarios y transacciones
**Horario:** Martes 14:30 - Horario comercial pico
**Urgencia:** CRÍTICA - Posible brecha de seguridad detectada

### 🚨 Síntomas Reportados

**Reporte del equipo de seguridad:**
```
"Se detectaron patrones de acceso anómalos en la base de datos.
Múltiples intentos de login fallidos desde IPs sospechosas.
Consultas SQL inusuales en logs de auditoría.
Posible inyección SQL detectada en aplicación web.
Datos sensibles potencialmente comprometidos."
```

**Indicadores de compromiso:**
- ⚠️ 500+ intentos de login fallidos en 1 hora
- ⚠️ Consultas SELECT masivas en tabla de usuarios
- ⚠️ Accesos desde IPs geográficamente dispersas
- ⚠️ Patrones de SQL injection en logs de aplicación

### 🎯 Tu Misión

Como DBA de Seguridad, debes:

1. **Investigar la brecha** y determinar el alcance
2. **Asegurar la base de datos** inmediatamente
3. **Identificar datos comprometidos**
4. **Implementar medidas de seguridad** adicionales
5. **Documentar el incidente** para auditoría

### 📈 Criterios de Éxito

**Respuesta exitosa cuando:**
- ✅ Brecha contenida y accesos bloqueados
- ✅ Alcance del compromiso determinado
- ✅ Medidas de seguridad implementadas
- ✅ Datos sensibles protegidos
- ✅ Plan de remediación documentado

### 🔧 Herramientas Disponibles

**Scripts de seguridad:**
- `security-audit.sh` - Auditoría de seguridad
- `access-analyzer.py` - Análisis de patrones de acceso
- `sql-injection-detector.py` - Detector de inyecciones SQL
- `user-privilege-audit.sh` - Auditoría de privilegios

### ⏰ Cronómetro

**Tiempo límite:** 45 minutos
**Puntuación máxima:** 120 puntos

---

**¿Listo para la investigación?** 
Ejecuta: `docker-compose up -d` y comienza la investigación de seguridad.
