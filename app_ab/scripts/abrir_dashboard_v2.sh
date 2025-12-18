#!/bin/bash

GREEN='\033[0;32m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m'

echo -e "${PURPLE}========================================${NC}"
echo -e "${PURPLE}✨ Dashboard Fundos V2 - UX MELHORADO${NC}"
echo -e "${PURPLE}========================================${NC}\n"

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
APP_DIR="$(dirname "$SCRIPT_DIR")"
HTML_FILE="$APP_DIR/pages/dashboard_fundos_v2.html"

if [ ! -f "$HTML_FILE" ]; then
    echo "❌ Arquivo não encontrado: $HTML_FILE"
    exit 1
fi

echo -e "${GREEN}✅ Abrindo dashboard com UX redesenhado...${NC}\n"

if [[ "$OSTYPE" == "darwin"* ]]; then
    open "$HTML_FILE"
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    xdg-open "$HTML_FILE"
elif [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "cygwin" ]]; then
    start "$HTML_FILE"
fi

echo -e "${PURPLE}========================================${NC}"
echo -e "${PURPLE}Dashboard V2 aberto!${NC}"
echo -e "${PURPLE}========================================${NC}\n"
echo "✨ Design system completo"
echo "🎯 Hierarquia visual clara"
echo "💡 Insights inteligentes"
echo "🎨 Micro-interações"
echo "📊 Data storytelling"
echo ""
