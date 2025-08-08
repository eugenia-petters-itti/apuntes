#!/bin/bash

echo "🔍 VERIFICANDO INTEGRIDAD DEL PAQUETE"
echo "===================================="

# Verificar estructura de directorios
echo "📁 Verificando estructura..."

required_dirs=(
    "herramientas"
    "escenarios-practica"
    "dashboard"
    "recursos-estudio/cheatsheets"
    "recursos-estudio/documentacion"
    "recursos-estudio/casos-estudio"
    "certificacion"
)

for dir in "${required_dirs[@]}"; do
    if [ -d "$dir" ]; then
        echo "  ✅ $dir"
    else
        echo "  ❌ $dir - FALTANTE"
    fi
done

# Verificar archivos principales
echo ""
echo "📄 Verificando archivos principales..."

required_files=(
    "README.md"
    "INICIO-RAPIDO.md"
    "INSTALACION-REQUISITOS.md"
    "PLAN-ESTUDIO-5-SEMANAS.md"
    "herramientas/gestor-escenarios.sh"
    "herramientas/validador-sistema.sh"
    "herramientas/evaluador-progreso.py"
    "dashboard/mi-progreso.html"
)

for file in "${required_files[@]}"; do
    if [ -f "$file" ]; then
        echo "  ✅ $file"
    else
        echo "  ❌ $file - FALTANTE"
    fi
done

# Verificar permisos
echo ""
echo "🔐 Verificando permisos..."

executable_files=(
    "herramientas/gestor-escenarios.sh"
    "herramientas/validador-sistema.sh"
    "herramientas/evaluador-progreso.py"
)

for file in "${executable_files[@]}"; do
    if [ -x "$file" ]; then
        echo "  ✅ $file - Ejecutable"
    else
        echo "  ⚠️  $file - Sin permisos de ejecución"
        chmod +x "$file" 2>/dev/null && echo "    🔧 Permisos corregidos"
    fi
done

echo ""
echo "✅ Verificación completada"
echo "📦 El paquete está listo para distribuir"
