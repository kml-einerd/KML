#!/bin/bash

echo "═══════════════════════════════════════════════════════════"
echo "  🤖 SCRAPER AUTOMÁTICO - TRADINGVIEW WIDGETS"
echo "═══════════════════════════════════════════════════════════"
echo ""

cd "$(dirname "$0")"

# Verificar Node.js
if ! command -v node &> /dev/null; then
    echo "❌ Node.js não encontrado!"
    echo "   Instale em: https://nodejs.org"
    exit 1
fi

echo "✅ Node.js $(node --version) detectado"

# Instalar dependências se necessário
if [ ! -d "node_modules" ]; then
    echo ""
    echo "📦 Instalando dependências..."
    npm install
    echo ""
fi

# Verificar servidor HTTP
echo "🔍 Verificando servidor HTTP..."
if ! lsof -i:8001 &> /dev/null; then
    echo "⚠️  Servidor não está rodando!"
    echo ""
    echo "🚀 Iniciando servidor HTTP..."
    python3 -m http.server 8001 &
    SERVER_PID=$!
    echo "✅ Servidor iniciado (PID: $SERVER_PID)"
    sleep 2
else
    echo "✅ Servidor já rodando na porta 8001"
fi

echo ""
echo "═══════════════════════════════════════════════════════════"
echo ""

# Iniciar scraper
node scraper.js

# Cleanup
if [ ! -z "$SERVER_PID" ]; then
    echo ""
    echo "🛑 Parando servidor..."
    kill $SERVER_PID 2>/dev/null
fi

echo ""
echo "═══════════════════════════════════════════════════════════"
echo "  ✅ FINALIZADO"
echo "═══════════════════════════════════════════════════════════"
