#!/bin/bash

BLUE='\033[0;34m'
PURPLE='\033[0;35m'
GREEN='\033[0;32m'
NC='\033[0m'

echo -e "${PURPLE}========================================${NC}"
echo -e "${PURPLE}🎯 MASTER DASHBOARD - Fundos Top 100${NC}"
echo -e "${PURPLE}========================================${NC}\n"

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
APP_DIR="$(dirname "$SCRIPT_DIR")"
HTML_FILE="$APP_DIR/pages/dashboard_master.html"

if [ ! -f "$HTML_FILE" ]; then
    echo "❌ Arquivo não encontrado: $HTML_FILE"
    exit 1
fi

echo -e "${GREEN}✅ Abrindo Master Dashboard...${NC}\n"

if [[ "$OSTYPE" == "darwin"* ]]; then
    open "$HTML_FILE"
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    xdg-open "$HTML_FILE"
elif [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "cygwin" ]]; then
    start "$HTML_FILE"
fi

echo -e "${PURPLE}========================================${NC}"
echo -e "${PURPLE}Dashboard Master ativo!${NC}"
echo -e "${PURPLE}========================================${NC}\n"
echo -e "${BLUE}✨ Features:${NC}"
echo "  • 📊 Panorama completo do mercado"
echo "  • 🟢 Sinais de compra (consenso >80%)"
echo "  • 🔴 Sinais de venda (consenso >80%)"
echo "  • 📈 2 gráficos de análise (Chart.js)"
echo "  • 🏢 Análise detalhada por gestora"
echo "  • 💎 Descoberta de oportunidades"
echo "  • 🧠 Insights inteligentes automáticos"
echo "  • 🎨 Design profissional com Tailwind"
echo ""
echo -e "${GREEN}🚀 100% funcional • Self-contained • Mobile-friendly${NC}"
echo ""
