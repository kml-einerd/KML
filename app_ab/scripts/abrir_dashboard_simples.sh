#!/bin/bash

GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}📱 Dashboard Fundos SIMPLES${NC}"
echo -e "${BLUE}========================================${NC}\n"

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
APP_DIR="$(dirname "$SCRIPT_DIR")"
HTML_FILE="$APP_DIR/pages/dashboard_fundos_simples.html"

if [ ! -f "$HTML_FILE" ]; then
    echo "❌ Arquivo não encontrado: $HTML_FILE"
    exit 1
fi

echo -e "${GREEN}✅ Abrindo dashboard mobile-first...${NC}\n"

if [[ "$OSTYPE" == "darwin"* ]]; then
    open "$HTML_FILE"
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    xdg-open "$HTML_FILE"
elif [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "cygwin" ]]; then
    start "$HTML_FILE"
fi

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Dashboard aberto!${NC}"
echo -e "${GREEN}========================================${NC}\n"
echo "📱 Otimizado para celular"
echo "🎯 Tela única - sem abas"
echo "⚡ Super simples e prático"
echo ""
