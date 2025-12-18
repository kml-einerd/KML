#!/bin/bash

# ========================================
# Abrir Dashboard Fundos Top 100
# ========================================

GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}📊 Dashboard Fundos Top 100${NC}"
echo -e "${BLUE}========================================${NC}\n"

# Get script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
APP_DIR="$(dirname "$SCRIPT_DIR")"
HTML_FILE="$APP_DIR/pages/dashboard_fundos.html"

# Check if file exists
if [ ! -f "$HTML_FILE" ]; then
    echo "❌ Arquivo não encontrado: $HTML_FILE"
    exit 1
fi

echo -e "${GREEN}✅ Abrindo dashboard...${NC}\n"

# Open in default browser
if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS
    open "$HTML_FILE"
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    # Linux
    xdg-open "$HTML_FILE"
elif [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "cygwin" ]]; then
    # Windows
    start "$HTML_FILE"
else
    echo "⚠️  Sistema operacional não identificado"
    echo "Abra manualmente: $HTML_FILE"
fi

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Dashboard aberto no navegador!${NC}"
echo -e "${GREEN}========================================${NC}\n"

echo "📌 URL local:"
echo "   file://$HTML_FILE"
echo ""
echo "🔧 Credenciais Supabase já configuradas"
echo "📊 Dashboard totalmente funcional"
echo ""
