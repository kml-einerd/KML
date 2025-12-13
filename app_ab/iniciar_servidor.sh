#!/bin/bash

echo "════════════════════════════════════════════════════════════"
echo "  🚀 INICIANDO SERVIDOR HTTP - APP AB"
echo "════════════════════════════════════════════════════════════"
echo ""

# Ir para o diretório do projeto
cd "$(dirname "$0")"

# Verificar e matar processos na porta 8001
echo "🔍 Verificando porta 8001..."
if lsof -i:8001 >/dev/null 2>&1; then
    echo "⚠️  Porta 8001 em uso! Encerrando processos..."
    lsof -ti:8001 | xargs kill -9 2>/dev/null
    sleep 1
    echo "✅ Porta liberada!"
else
    echo "✅ Porta 8001 livre!"
fi

echo ""
echo "📡 Iniciando servidor HTTP na porta 8001..."
echo ""
echo "════════════════════════════════════════════════════════════"
echo ""
echo "  ✅ SERVIDOR RODANDO!"
echo ""
echo "  📊 Acesse as páginas:"
echo ""
echo "  → Dashboard:    http://localhost:8001/pages/index.html"
echo "  → Grade:        http://localhost:8001/pages/home.html"
echo "  → Teste:        http://localhost:8001/pages/test_widget.html"
echo "  → Carteiras:    http://localhost:8001/pages/carteiras.html"
echo ""
echo "════════════════════════════════════════════════════════════"
echo ""
echo "  💡 Para parar: Pressione Ctrl+C"
echo ""
echo "════════════════════════════════════════════════════════════"
echo ""

# Iniciar servidor
python3 -m http.server 8001
