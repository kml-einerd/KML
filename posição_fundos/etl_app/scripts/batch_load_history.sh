#!/bin/bash

# Script para carregar histórico de dados (Carga em Lote)
# Uso: ./batch_load_history.sh

# Ativar virtual env
source ../venv/bin/activate

echo "============================================"
echo "INICIANDO CARGA DE HISTÓRICO (Jun/24 - Jan/25)"
echo "============================================"

# Loop para 2024 (Junho a Dezembro)
for mes in {6..12}; do
    echo "---------------------------------"
    echo "Processando Mês $mes/2024..."
    python ../main.py --ano 2024 --mes $mes --top 100
done

# Janeiro 2025
echo "---------------------------------"
echo "Processando Mês 1/2025..."
python ../main.py --ano 2025 --mes 1 --top 100

echo "============================================"
echo "CARGA CONCLUÍDA!"
echo "Verifique o dashboard para ver os novos dados."
