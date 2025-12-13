#!/bin/bash

# Script para abrir carteiras.html automaticamente

echo "════════════════════════════════════════"
echo "  🚀 Iniciando Carteiras de Ações"
echo "════════════════════════════════════════"
echo ""

# Matar servidores antigos
pkill -f "python3 -m http.server" 2>/dev/null

# Ir para o diretório
cd "$(dirname "$0")"

# Iniciar servidor
echo "📡 Iniciando servidor HTTP..."
python3 -m http.server 8001 &
SERVER_PID=$!

sleep 2

# Abrir navegador
echo "🌐 Abrindo navegador..."
open http://localhost:8001/carteiras.html

echo ""
echo "════════════════════════════════════════"
echo "  ✅ PRONTO!"
echo "════════════════════════════════════════"
echo ""
echo "📊 URL: http://localhost:8001/carteiras.html"
echo "🖥️  Servidor PID: $SERVER_PID"
echo ""
echo "💡 Para parar o servidor:"
echo "   Pressione Ctrl+C no Terminal"
echo "   ou execute: kill $SERVER_PID"
echo ""
echo "════════════════════════════════════════"
echo ""
echo "Aguardando... (Ctrl+C para sair)"

# Aguardar
wait $SERVER_PID
