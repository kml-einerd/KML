# Guia de Análise de Ações B3

Sistema completo para análise de movimentações de ações pelos fundos de investimento brasileiros.

## Objetivo

Responder perguntas estratégicas como:
- **O que os grandes fundos estão comprando?**
- **Quais ações estão sendo vendidas?**
- **Quanto foi investido em cada setor?**
- **Quais as tendências do mercado?**
- **Quem são os maiores investidores em uma ação?**

---

## Estrutura de Dados

### 1. Categorização de Ações (dim_acoes_b3)

Cada ação é classificada por múltiplos critérios:

#### Setor e Subsetor
```
Bancos → Bancos Comerciais
Petróleo e Gás → Exploração e Refino
Varejo → Varejo de Linha Dura
Alimentos → Bebidas, Frigoríficos
```

#### Tamanho (Market Cap)
- **Large Cap**: > R$ 10 bilhões (ex: PETR4, VALE3, ITUB4)
- **Mid Cap**: R$ 1 bi - R$ 10 bi (ex: MGLU3, VAMO3)
- **Small Cap**: < R$ 1 bilhão (ex: ROMI3, TASA4)

#### Liquidez
- **Alta**: Volume diário > R$ 100 milhões
- **Média**: Volume entre R$ 10 mi e R$ 100 mi
- **Baixa**: Volume < R$ 10 milhões

#### Categoria de Análise
- **Blue Chip**: Large caps consolidadas, dividendos consistentes (PETR4, VALE3, ITUB4)
- **Growth**: Empresas em crescimento (MGLU3, VAMO3)
- **Value**: Empresas subvalorizadas (LREN3, BEEF3)
- **Especulativa**: Small caps voláteis (ROMI3, TASA4)

#### Índices
```
✓ IBOVESPA (principal)
✓ IBrX 100 (top 100)
✓ SMLL (small caps)
✓ IDIV (dividendos)
✓ Setoriais (ICON, IFNC, IMAT, etc.)
```

---

## Views Criadas

### v_movimentacoes_acoes
**Dados brutos detalhados de cada operação**

Colunas principais:
- Data, Ticker, Empresa, Setor
- Fundo, Grupo Econômico
- Quantidade e Valor da Posição
- Compras e Vendas do Período
- Saldo Líquido
- Rentabilidade

### v_ranking_compras_mes
**Top ações MAIS COMPRADAS**

Mostra:
- Quantos fundos compraram
- Valor total comprado
- Quantidade comprada
- Ranking de compra

### v_ranking_vendas_mes
**Top ações MAIS VENDIDAS**

Mostra:
- Quantos fundos venderam
- Valor total vendido
- Quantidade vendida
- Ranking de venda

### v_fluxo_liquido_acoes
**Saldo líquido por ação (compra - venda)**

Identifica:
- FORTE COMPRA: Fluxo > R$ 1 milhão
- COMPRA MODERADA: Fluxo positivo
- VENDA MODERADA: Fluxo negativo
- FORTE VENDA: Fluxo < -R$ 1 milhão

### v_concentracao_setor_acoes
**Análise por setor econômico**

Mostra:
- Valor total investido por setor
- Compras e vendas do mês
- Fluxo líquido setorial
- Rentabilidade média
- % do total investido em ações

### v_top_posicoes_grupos
**Maiores posições de cada grupo econômico**

Top 10 ações de:
- BTG Pactual
- Itaú Unibanco
- XP Investimentos
- Caixa Econômica Federal
- Outros grupos

### v_analise_dividendos
**Ações pagadoras de dividendos**

Combina:
- Dividend Yield médio
- Valor investido
- Dividendos estimados
- Movimentações

---

## Queries de Insights (10 casos práticos)

### Insight 1: O que os grandes fundos estão comprando?
```sql
SELECT ticker, empresa_nome, setor, total_comprado_milhoes
FROM v_ranking_compras_mes
WHERE ano = 2025 AND mes = 10 AND ranking_compra <= 20;
```

**Resultado esperado:**
```
PETR4  | Petrobras       | Petróleo e Gás | R$ 120 mi
VALE3  | Vale            | Mineração      | R$ 95 mi
ITUB4  | Itaú            | Bancos         | R$ 80 mi
```

### Insight 2: O que estão vendendo?
```sql
SELECT ticker, empresa_nome, setor, total_vendido_milhoes
FROM v_ranking_vendas_mes
WHERE ano = 2025 AND mes = 10 AND ranking_venda <= 20;
```

### Insight 3: Fluxo líquido (tendência)
```sql
SELECT ticker, empresa_nome, setor,
       fluxo_liquido_milhoes, tendencia_mercado
FROM v_fluxo_liquido_acoes
WHERE ano = 2025 AND mes = 10
  AND tendencia_mercado IN ('FORTE COMPRA', 'FORTE VENDA')
ORDER BY ABS(fluxo_liquido) DESC;
```

**Interpretação:**
- **FORTE COMPRA**: Consenso positivo do mercado
- **FORTE VENDA**: Consenso negativo do mercado

### Insight 4: Setores em alta
```sql
SELECT setor, valor_investido_bilhoes,
       fluxo_liquido_milhoes, percentual_total_acoes
FROM v_concentracao_setor_acoes
WHERE ano = 2025 AND mes = 10
ORDER BY fluxo_liquido_mes DESC;
```

**Use para:**
- Identificar rotação setorial
- Entender onde o dinheiro está indo

### Insight 5: Small Caps em movimento
```sql
SELECT ticker, empresa_nome, setor,
       fluxo_liquido_milhoes, tendencia_mercado
FROM v_fluxo_liquido_acoes
WHERE ano = 2025 AND mes = 10
  AND categoria_analise = 'Small Cap'
  AND ABS(fluxo_liquido) > 500000
ORDER BY ABS(fluxo_liquido) DESC;
```

### Insight 6: Blue Chips
```sql
SELECT ticker, empresa_nome, setor,
       fluxo_liquido_milhoes, tendencia_mercado
FROM v_fluxo_liquido_acoes
WHERE ano = 2025 AND mes = 10
  AND categoria_analise = 'Blue Chip'
ORDER BY ABS(fluxo_liquido) DESC;
```

### Insight 7: Quem investe em uma ação específica?
```sql
SELECT nome_grupo, nome_fundo,
       posicao_milhoes, tipo_movimentacao
FROM v_movimentacoes_acoes
WHERE ticker = 'PETR4' -- MUDE AQUI
  AND ano = 2025 AND mes = 10
ORDER BY valor_mercado_posicao DESC
LIMIT 20;
```

**Use para:**
- Ver quem são os grandes holders
- Descobrir se estão comprando ou vendendo

### Insight 8: Carteira sugerida (compra + dividendos)
```sql
SELECT f.ticker, f.empresa_nome,
       f.fluxo_liquido_milhoes,
       d.dividend_yield_medio
FROM v_fluxo_liquido_acoes f
JOIN v_analise_dividendos d
  ON f.ticker = d.ticker AND f.ano = d.ano AND f.mes = d.mes
WHERE f.ano = 2025 AND f.mes = 10
  AND f.tendencia_mercado IN ('FORTE COMPRA', 'COMPRA MODERADA')
  AND d.dividend_yield_medio >= 4.0
ORDER BY f.fluxo_liquido DESC;
```

**Estratégia:**
- Fundos comprando (expectativa de alta)
- Dividendos altos (renda passiva)

### Insight 9: Apostas de cada grupo
```sql
SELECT nome_grupo, ticker, empresa_nome,
       investido_milhoes, ranking_grupo
FROM v_top_posicoes_grupos
WHERE ano = 2025 AND mes = 10
  AND nome_grupo IN ('BTG Pactual', 'Itaú Unibanco', 'XP Investimentos')
  AND ranking_grupo <= 10
ORDER BY nome_grupo, ranking_grupo;
```

**Use para:**
- Copiar estratégias de grandes grupos
- Identificar consensos ou divergências

### Insight 10: Tendência de 3 meses
```sql
SELECT mes_nome, ticker, empresa_nome,
       fluxo_liquido_milhoes, tendencia_mercado
FROM v_fluxo_liquido_acoes
WHERE ano = 2025 AND mes IN (8, 9, 10)
  AND ticker IN (
      SELECT ticker FROM v_fluxo_liquido_acoes
      WHERE ano = 2025 AND mes = 10
      ORDER BY ABS(fluxo_liquido) DESC LIMIT 10
  )
ORDER BY ticker, mes;
```

**Use para:**
- Confirmar tendências persistentes
- Detectar reversões

---

## Workflow Recomendado

### 1. Identificar Tendências Gerais
```sql
-- Top 10 compras do mês
SELECT * FROM v_ranking_compras_mes
WHERE ano = 2025 AND mes = 10 AND ranking_compra <= 10;

-- Top 10 vendas do mês
SELECT * FROM v_ranking_vendas_mes
WHERE ano = 2025 AND mes = 10 AND ranking_venda <= 10;
```

### 2. Análise Setorial
```sql
-- Fluxo por setor
SELECT setor, fluxo_liquido_milhoes, percentual_total_acoes
FROM v_concentracao_setor_acoes
WHERE ano = 2025 AND mes = 10
ORDER BY fluxo_liquido_mes DESC;
```

### 3. Deep Dive em Ação Específica
```sql
-- Escolha uma ação e veja quem são os investidores
SELECT nome_grupo, posicao_milhoes, tipo_movimentacao
FROM v_movimentacoes_acoes
WHERE ticker = 'VALE3' AND ano = 2025 AND mes = 10
ORDER BY valor_mercado_posicao DESC;
```

### 4. Montar Carteira
```sql
-- Combine múltiplos critérios:
-- 1. Fundos comprando (tendência)
-- 2. Dividendos altos (renda)
-- 3. Blue chips (segurança)
SELECT ticker, empresa_nome, setor,
       fluxo_liquido_milhoes, dividend_yield_medio
FROM v_fluxo_liquido_acoes f
JOIN v_analise_dividendos d USING (ticker, ano, mes)
WHERE f.ano = 2025 AND f.mes = 10
  AND tendencia_mercado = 'FORTE COMPRA'
  AND categoria_analise = 'Blue Chip'
  AND dividend_yield_medio >= 4.0;
```

---

## Exemplos Práticos

### Caso 1: "Quero investir como o BTG Pactual"
```sql
SELECT ticker, empresa_nome, setor, investido_milhoes
FROM v_top_posicoes_grupos
WHERE nome_grupo = 'BTG Pactual'
  AND ano = 2025 AND mes = 10
  AND ranking_grupo <= 5
ORDER BY ranking_grupo;
```

### Caso 2: "Quero ações de Small Caps que fundos estão comprando"
```sql
SELECT ticker, empresa_nome, setor,
       fluxo_liquido_milhoes, fundos_compradores
FROM v_fluxo_liquido_acoes
WHERE ano = 2025 AND mes = 10
  AND categoria_analise = 'Small Cap'
  AND tendencia_mercado IN ('FORTE COMPRA', 'COMPRA MODERADA')
ORDER BY fluxo_liquido DESC;
```

### Caso 3: "Quais setores estão recebendo capital?"
```sql
SELECT setor, fluxo_liquido_milhoes,
       qtd_acoes_diferentes, qtd_fundos_investidores
FROM v_concentracao_setor_acoes
WHERE ano = 2025 AND mes = 10
  AND fluxo_liquido_mes > 0
ORDER BY fluxo_liquido_mes DESC;
```

### Caso 4: "Quero ações pagadoras de dividendos com DY > 6%"
```sql
SELECT ticker, empresa_nome, dividend_yield_medio,
       valor_total_investido / 1000000.0 AS investido_milhoes,
       dividendos_estimados_ano / 1000000.0 AS dividendos_milhoes
FROM v_analise_dividendos
WHERE ano = 2025 AND mes = 10
  AND dividend_yield_medio >= 6.0
ORDER BY dividend_yield_medio DESC;
```

---

## Interpretação dos Resultados

### Fluxo Líquido
- **Positivo grande**: Consenso de compra, expectativa de alta
- **Positivo pequeno**: Acumulação gradual
- **Negativo pequeno**: Realização de lucros
- **Negativo grande**: Consenso de venda, expectativa de queda

### Quantidade de Fundos
- **Muitos fundos comprando**: Forte consenso positivo
- **Muitos fundos vendendo**: Forte consenso negativo
- **Dividido**: Sem consenso, análise individual necessária

### Setores
- **Fluxo positivo**: Capital entrando, setor em alta
- **Fluxo negativo**: Capital saindo, rotação setorial

---

## Próximos Passos

1. Criar dashboard com os principais insights
2. Alertas automáticos quando:
   - Fluxo > R$ 10 milhões em uma ação
   - Grupo grande muda posição significativamente
   - Setor recebe fluxo > R$ 100 milhões
3. API para consultas em tempo real
4. Relatórios semanais automatizados

---

## Arquivos Relacionados

- `10_dim_acoes_b3.sql` - Tabela de categorização
- `11_views_movimentacoes_acoes.sql` - 7 views analíticas
- `12_queries_insights_acoes.sql` - 10 queries práticas
- `README.md` - Documentação geral do projeto
