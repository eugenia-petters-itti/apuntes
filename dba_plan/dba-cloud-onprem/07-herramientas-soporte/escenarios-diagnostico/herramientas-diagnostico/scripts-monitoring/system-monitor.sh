#!/bin/bash
# Script de monitoreo del sistema para escenarios de diagnóstico

echo "=== MONITOREO DEL SISTEMA ==="
echo "Fecha: $(date)"
echo "Uptime: $(uptime)"
echo ""

echo "=== CPU Y MEMORIA ==="
top -bn1 | head -20

echo ""
echo "=== ESPACIO EN DISCO ==="
df -h

echo ""
echo "=== PROCESOS DE BASE DE DATOS ==="
ps aux | grep -E "(mysql|postgres|mongo)" | grep -v grep

echo ""
echo "=== CONEXIONES DE RED ==="
netstat -tlnp | grep -E "(3306|5432|27017)"
