#!/bin/bash
# ========================================
# Script de Execução do ETL V2
# Garante uso do venv correto
# ========================================

# Cores para output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}========================================${NC}"
echo -e "${YELLOW}🚀 INICIANDO ETL V2${NC}"
echo -e "${YELLOW}========================================${NC}\n"

# Ir para o diretório correto
cd "$(dirname "$0")"

# Desativar qualquer venv ativo
if [ -n "$VIRTUAL_ENV" ]; then
    echo -e "${YELLOW}⚠️  Desativando venv global...${NC}"
    deactivate 2>/dev/null || true
fi

# Verificar se venv local existe
if [ ! -d "venv" ]; then
    echo -e "${RED}❌ venv não encontrado!${NC}"
    echo -e "${YELLOW}Criando venv...${NC}"
    python3 -m venv venv
    echo -e "${GREEN}✅ venv criado${NC}\n"
fi

# Ativar venv local
echo -e "${GREEN}✅ Ativando venv local (etl_v2/venv)...${NC}"
source venv/bin/activate

# Verificar se está usando o venv correto
PYTHON_PATH=$(which python)
if [[ "$PYTHON_PATH" != *"etl_v2/venv"* ]]; then
    echo -e "${RED}❌ ERRO: Ainda usando venv errado!${NC}"
    echo -e "${RED}Python path: $PYTHON_PATH${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Usando venv correto: $PYTHON_PATH${NC}\n"

# Instalar dependências se necessário
echo -e "${YELLOW}📦 Verificando dependências...${NC}"
pip install -q -r requirements.txt
echo -e "${GREEN}✅ Dependências instaladas${NC}\n"

# Executar ETL
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}📊 EXECUTANDO MENU INTERATIVO${NC}"
echo -e "${GREEN}========================================${NC}\n"

python main_interactive.py

# Status final
if [ $? -eq 0 ]; then
    echo -e "\n${GREEN}========================================${NC}"
    echo -e "${GREEN}✅ ETL CONCLUÍDO COM SUCESSO!${NC}"
    echo -e "${GREEN}========================================${NC}\n"
else
    echo -e "\n${RED}========================================${NC}"
    echo -e "${RED}❌ ERRO NA EXECUÇÃO${NC}"
    echo -e "${RED}========================================${NC}\n"
fi
