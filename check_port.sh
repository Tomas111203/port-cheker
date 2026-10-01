#!/bin/bash

# ============================================
# Script: check_port.sh
# Uso: check_port.sh <puerto> [host]
# ============================================

if [ $# -lt 1 ]; then
    echo "Uso: $0 <puerto> [host]"
    echo "Ejemplo: $0 80 google.com"
    exit 1
fi

PUERTO=$1
HOST=${2:-127.0.0.1}

# Validar que el puerto sea un número entre 1 y 65535
if ! [[ "$PUERTO" =~ ^[0-9]+$ ]] || [ "$PUERTO" -lt 1 ] || [ "$PUERTO" -gt 65535 ]; then
    echo "❌ Error: El puerto debe ser un número entre 1 y 65535"
    exit 1
fi

echo "🔍 Verificando puerto $PUERTO en $HOST..."

nc -z -w 3 "$HOST" "$PUERTO" 2>/dev/null

if [ $? -eq 0 ]; then
    echo "✅ El puerto $PUERTO está ABIERTO en $HOST"
    exit 0
else
    echo "❌ El puerto $PUERTO está CERRADO en $HOST"
    exit 1
fi