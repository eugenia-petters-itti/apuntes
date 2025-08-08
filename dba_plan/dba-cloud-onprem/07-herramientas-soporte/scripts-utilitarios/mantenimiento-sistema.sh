#!/bin/bash
# Script de mantenimiento del sistema DBA

echo "🔧 MANTENIMIENTO DEL SISTEMA DBA"
echo "================================"

# Limpiar contenedores Docker
echo "🐳 Limpiando contenedores Docker..."
docker system prune -f 2>/dev/null || echo "Docker no disponible"

# Limpiar logs antiguos
echo "📝 Limpiando logs antiguos..."
find . -name "*.log" -mtime +7 -delete 2>/dev/null || true

# Verificar espacio en disco
echo "💾 Verificando espacio en disco..."
df -h . | tail -1

# Verificar estado de servicios
echo "⚡ Verificando servicios..."
docker ps --format "table {{.Names}}\t{{.Status}}" 2>/dev/null || echo "No hay contenedores corriendo"

echo "✅ Mantenimiento completado"
