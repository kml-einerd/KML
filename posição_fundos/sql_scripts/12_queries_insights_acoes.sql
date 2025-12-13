-- ====================================================================
-- QUERIES DE INSIGHTS - AÇÕES B3
-- Consultas práticas para análise de movimentações e tendências
-- ====================================================================

-- ====================================================================
-- INSIGHT 1: O que os grandes fundos estão comprando AGORA?
-- Top 20 ações mais compradas no último mês
-- ====================================================================

-- Use esta query para descobrir tendências de compra
SELECT
    ticker,
    empresa_nome,
    setor,
    categoria_analise,
    qtd_fundos_compradores,
    total_comprado / 1000000.0 AS total_comprado_milhoes,
    total_quantidade_comprada,
    ranking_compra
FROM v_ranking_compras_mes
WHERE ano = 2025 AND mes = 10
  AND ranking_compra <= 20
ORDER BY ranking_compra;

/*
INTERPRETAÇÃO:
- Se muitos fundos estão comprando uma ação, pode indicar:
  1. Expectativa de valorização
  2. Fundamentos melhorando
  3. Oportunidade identificada pelo mercado
*/


-- ====================================================================
-- INSIGHT 2: O que os grandes fundos estão VENDENDO?
-- Top 20 ações mais vendidas no último mês
-- ====================================================================

SELECT
    ticker,
    empresa_nome,
    setor,
    categoria_analise,
    qtd_fundos_vendedores,
    total_vendido / 1000000.0 AS total_vendido_milhoes,
    total_quantidade_vendida,
    ranking_venda
FROM v_ranking_vendas_mes
WHERE ano = 2025 AND mes = 10
  AND ranking_venda <= 20
ORDER BY ranking_venda;

/*
INTERPRETAÇÃO:
- Vendas massivas podem indicar:
  1. Realização de lucros
  2. Deterioração de fundamentos
  3. Rebalanceamento de carteira
  4. Risco identificado
*/


-- ====================================================================
-- INSIGHT 3: Fluxo Líquido - Ações em Forte Compra vs Forte Venda
-- Identifica tendências claras do mercado
-- ====================================================================

SELECT
    ticker,
    empresa_nome,
    setor,
    categoria_analise,
    total_compras / 1000000.0 AS compras_milhoes,
    total_vendas / 1000000.0 AS vendas_milhoes,
    fluxo_liquido / 1000000.0 AS fluxo_liquido_milhoes,
    fundos_compradores,
    fundos_vendedores,
    tendencia_mercado
FROM v_fluxo_liquido_acoes
WHERE ano = 2025 AND mes = 10
  AND tendencia_mercado IN ('FORTE COMPRA', 'FORTE VENDA')
ORDER BY ABS(fluxo_liquido) DESC
LIMIT 30;

/*
INTERPRETAÇÃO:
- FORTE COMPRA: Muitos fundos comprando, poucos vendendo
- FORTE VENDA: Muitos fundos vendendo, poucos comprando
- Pode indicar consenso do mercado sobre a ação
*/


-- ====================================================================
-- INSIGHT 4: Setores em Alta - Onde o dinheiro está indo?
-- Análise de concentração por setor
-- ====================================================================

SELECT
    setor,
    valor_total_posicoes / 1000000000.0 AS valor_investido_bilhoes,
    total_compras_mes / 1000000.0 AS compras_mes_milhoes,
    total_vendas_mes / 1000000.0 AS vendas_mes_milhoes,
    fluxo_liquido_mes / 1000000.0 AS fluxo_liquido_milhoes,
    qtd_acoes_diferentes,
    qtd_fundos_investidores,
    ROUND(rentabilidade_media_setor, 2) AS rentabilidade_media_pct,
    percentual_total_acoes
FROM v_concentracao_setor_acoes
WHERE ano = 2025 AND mes = 10
ORDER BY fluxo_liquido_mes DESC;

/*
INTERPRETAÇÃO:
- Setores com fluxo líquido positivo: Dinheiro entrando
- Setores com fluxo líquido negativo: Dinheiro saindo
- Identifique rotações setoriais
*/


-- ====================================================================
-- INSIGHT 5: Small Caps em Movimento
-- Pequenas empresas com grande movimentação
-- ====================================================================

SELECT
    ticker,
    empresa_nome,
    setor,
    subsetor,
    total_compras / 1000000.0 AS compras_milhoes,
    total_vendas / 1000000.0 AS vendas_milhoes,
    fluxo_liquido / 1000000.0 AS fluxo_liquido_milhoes,
    fundos_compradores,
    fundos_vendedores,
    tendencia_mercado
FROM v_fluxo_liquido_acoes
WHERE ano = 2025 AND mes = 10
  AND categoria_analise = 'Small Cap'
  AND ABS(fluxo_liquido) > 500000 -- Movimentação > R$ 500mil
ORDER BY ABS(fluxo_liquido) DESC;

/*
INTERPRETAÇÃO:
- Small Caps com alta movimentação podem indicar:
  1. Oportunidades de valor
  2. Eventos corporativos (M&A, IPO, etc.)
  3. Mudança de perspectiva do mercado
*/


-- ====================================================================
-- INSIGHT 6: Blue Chips - O que os grandes fazem?
-- Movimentação em ações consolidadas
-- ====================================================================

SELECT
    ticker,
    empresa_nome,
    setor,
    total_compras / 1000000.0 AS compras_milhoes,
    total_vendas / 1000000.0 AS vendas_milhoes,
    fluxo_liquido / 1000000.0 AS fluxo_liquido_milhoes,
    fundos_compradores,
    fundos_vendedores,
    tendencia_mercado
FROM v_fluxo_liquido_acoes
WHERE ano = 2025 AND mes = 10
  AND categoria_analise = 'Blue Chip'
ORDER BY ABS(fluxo_liquido) DESC;

/*
INTERPRETAÇÃO:
- Blue Chips são menos voláteis
- Grandes movimentações podem indicar:
  1. Mudanças estruturais no setor
  2. Rebalanceamento de portfólios
  3. Eventos macroeconômicos
*/


-- ====================================================================
-- INSIGHT 7: Quem são os maiores investidores em uma ação específica?
-- Exemplo: ITUB4 (Itaú)
-- ====================================================================

SELECT
    nome_grupo,
    tipo_grupo,
    nome_fundo,
    valor_mercado_posicao / 1000000.0 AS posicao_milhoes,
    percentual_pl,
    valor_compra / 1000.0 AS compra_mes_milhares,
    valor_venda / 1000.0 AS venda_mes_milhares,
    saldo_liquido / 1000.0 AS saldo_liquido_milhares,
    tipo_movimentacao,
    ROUND(rentabilidade_posicao, 2) AS rentabilidade_pct
FROM v_movimentacoes_acoes
WHERE ticker = 'ITUB4' -- MUDAR AQUI PARA OUTRO TICKER
  AND ano = 2025 AND mes = 10
  AND valor_mercado_posicao > 0
ORDER BY valor_mercado_posicao DESC
LIMIT 20;

/*
USO:
- Substitua 'ITUB4' pelo ticker desejado
- Descubra quem são os grandes holders
- Veja se estão comprando ou vendendo
*/


-- ====================================================================
-- INSIGHT 8: Carteira Sugerida - Ações com Forte Compra + Dividendos
-- Ações que fundos estão comprando E pagam bons dividendos
-- ====================================================================

SELECT
    f.ticker,
    f.empresa_nome,
    f.setor,
    f.tendencia_mercado,
    f.fluxo_liquido / 1000000.0 AS fluxo_liquido_milhoes,
    f.fundos_compradores,
    d.dividend_yield_medio,
    d.dividendos_estimados_ano / 1000000.0 AS dividendos_estimados_milhoes,
    d.qtd_fundos AS fundos_com_posicao
FROM v_fluxo_liquido_acoes f
JOIN v_analise_dividendos d
    ON f.ticker = d.ticker
    AND f.ano = d.ano
    AND f.mes = d.mes
WHERE f.ano = 2025 AND f.mes = 10
  AND f.tendencia_mercado IN ('FORTE COMPRA', 'COMPRA MODERADA')
  AND d.dividend_yield_medio >= 4.0 -- DY mínimo de 4%
ORDER BY f.fluxo_liquido DESC, d.dividend_yield_medio DESC
LIMIT 15;

/*
ESTRATÉGIA:
- Combina tendência de compra institucional com dividendos
- Ideal para investidores que buscam:
  1. Valorização (fundos comprando)
  2. Renda passiva (dividendos)
*/


-- ====================================================================
-- INSIGHT 9: Grupos Econômicos - Apostas de Cada Player
-- O que BTG, Itaú, XP, etc. estão comprando?
-- ====================================================================

SELECT
    nome_grupo,
    ticker,
    empresa_nome,
    setor,
    valor_total_investido / 1000000.0 AS investido_milhoes,
    qtd_fundos_com_posicao,
    ROUND(rentabilidade_media, 2) AS rentabilidade_media_pct,
    ranking_grupo
FROM v_top_posicoes_grupos
WHERE ano = 2025 AND mes = 10
  AND nome_grupo IN ('BTG Pactual', 'Itaú Unibanco', 'XP Investimentos', 'Caixa Econômica Federal')
  AND ranking_grupo <= 10 -- Top 10 de cada grupo
ORDER BY nome_grupo, ranking_grupo;

/*
ANÁLISE:
- Compare as apostas de diferentes grupos
- Identifique convergências (todos comprando mesma ação)
- Identifique divergências (um comprando, outro vendendo)
*/


-- ====================================================================
-- INSIGHT 10: Evolução Temporal - Tendência de 3 Meses
-- Como as movimentações evoluíram nos últimos 3 meses?
-- ====================================================================

SELECT
    mes_nome,
    ticker,
    empresa_nome,
    setor,
    fluxo_liquido / 1000000.0 AS fluxo_liquido_milhoes,
    tendencia_mercado
FROM v_fluxo_liquido_acoes
WHERE ano = 2025
  AND mes IN (8, 9, 10) -- Ago, Set, Out
  AND ticker IN (
      -- Top 10 mais movimentadas em outubro
      SELECT ticker
      FROM v_fluxo_liquido_acoes
      WHERE ano = 2025 AND mes = 10
      ORDER BY ABS(fluxo_liquido) DESC
      LIMIT 10
  )
ORDER BY ticker, mes;

/*
ANÁLISE:
- Identifique tendências consistentes (3 meses de compra ou venda)
- Detecte reversões de tendência
- Avalie persistência de movimentos
*/


-- ====================================================================
-- RESUMO DE USO
-- ====================================================================

/*
WORKFLOW RECOMENDADO:

1. IDENTIFICAR TENDÊNCIAS (Insight 1, 2, 3)
   - O que está sendo comprado?
   - O que está sendo vendido?
   - Fluxo líquido por ação

2. ANÁLISE SETORIAL (Insight 4)
   - Quais setores estão recebendo capital?
   - Rotação setorial

3. ANÁLISE POR CATEGORIA (Insight 5, 6)
   - Small Caps em movimento
   - Blue Chips estáveis

4. DEEP DIVE EM AÇÕES ESPECÍFICAS (Insight 7)
   - Quem são os grandes holders?
   - Estão comprando ou vendendo?

5. ESTRATÉGIAS (Insight 8)
   - Combinar múltiplos critérios
   - Montar carteiras baseadas em insights

6. BENCHMARKING (Insight 9)
   - O que os grandes grupos fazem?
   - Copiar estratégias vencedoras

7. ANÁLISE TEMPORAL (Insight 10)
   - Confirmar tendências
   - Detectar mudanças
*/
