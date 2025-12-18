-- ========================================
-- QUERIES ÚTEIS - SISTEMA V2
-- Consultas prontas para análise
-- ========================================

-- ========================================
-- 1. TOP 20 AÇÕES MAIS COMPRADAS (MÊS ATUAL)
-- ========================================
-- Use esta query para ver quais ações os Top 100 fundos mais compraram

SELECT
    ranking,
    ticker,
    empresa,
    ROUND(comprado_milhoes, 2) as milhoes_comprados,
    qtd_fundos_compradores as qtd_fundos,
    top_comprador,
    ROUND(top_comprador_milhoes, 2) as top_comprador_milhoes
FROM v_top_compras_mes
WHERE mes_referencia = '2025-11-30'  -- ⚠️ ALTERE PARA O MÊS DESEJADO
  AND ranking <= 20
ORDER BY ranking;


-- ========================================
-- 2. TOP 20 AÇÕES MAIS VENDIDAS (MÊS ATUAL)
-- ========================================

SELECT
    ranking,
    ticker,
    empresa,
    ROUND(vendido_milhoes, 2) as milhoes_vendidos,
    qtd_fundos_vendedores as qtd_fundos,
    top_vendedor,
    ROUND(top_vendedor_milhoes, 2) as top_vendedor_milhoes
FROM v_top_vendas_mes
WHERE mes_referencia = '2025-11-30'  -- ⚠️ ALTERE PARA O MÊS DESEJADO
  AND ranking <= 20
ORDER BY ranking;


-- ========================================
-- 3. CONSENSO DE MERCADO (SINAIS FORTES)
-- ========================================
-- Mostra ações com consenso forte de compra/venda (>70% dos fundos concordam)

SELECT
    ticker,
    empresa,
    sinal,
    ROUND(fluxo_bilhoes::numeric, 2) as fluxo_bilhoes,
    qtd_fundos_compradores,
    qtd_fundos_vendedores,
    ROUND(intensidade_consenso, 1) as consenso_pct
FROM v_consenso_mercado
WHERE intensidade_consenso > 70  -- Consenso forte
ORDER BY ABS(fluxo_bilhoes) DESC
LIMIT 20;


-- ========================================
-- 4. MOVIMENTOS DE UM GRUPO ESPECÍFICO
-- ========================================
-- Veja o que um grupo econômico comprou ou vendeu

-- COMPRAS do Itaú em Novembro
SELECT
    ticker,
    empresa,
    tipo_movimento,
    ROUND(fluxo_milhoes, 2) as fluxo_milhoes,
    ROUND(posicao_milhoes, 2) as posicao_milhoes,
    rentabilidade_pct
FROM v_movimentos_grupo
WHERE nome_grupo = 'Itaú'  -- ⚠️ ALTERE O GRUPO
  AND mes_referencia = '2025-11-30'  -- ⚠️ ALTERE O MÊS
  AND tipo_movimento = 'COMPRA'
ORDER BY fluxo_milhoes DESC
LIMIT 20;

-- VENDAS do Itaú em Novembro
SELECT
    ticker,
    empresa,
    tipo_movimento,
    ROUND(fluxo_milhoes, 2) as fluxo_milhoes,
    ROUND(posicao_milhoes, 2) as posicao_milhoes,
    rentabilidade_pct
FROM v_movimentos_grupo
WHERE nome_grupo = 'Itaú'  -- ⚠️ ALTERE O GRUPO
  AND mes_referencia = '2025-11-30'  -- ⚠️ ALTERE O MÊS
  AND tipo_movimento = 'VENDA'
ORDER BY ABS(fluxo_milhoes) DESC
LIMIT 20;


-- ========================================
-- 5. EVOLUÇÃO DE UMA AÇÃO AO LONGO DOS MESES
-- ========================================
-- Compare compras/vendas de uma ação específica nos 4 meses

SELECT
    mes_referencia,
    ticker,
    empresa,
    ROUND(comprado_milhoes, 2) as comprado_milhoes,
    qtd_fundos_compradores,
    top_comprador
FROM v_top_compras_mes
WHERE ticker = 'PETR4'  -- ⚠️ ALTERE O TICKER
ORDER BY mes_referencia;


-- ========================================
-- 6. GRUPOS MAIS ATIVOS (MAIORES COMPRADORES)
-- ========================================
-- Veja quais grupos mais compraram ações em um mês

SELECT
    g.nome_grupo,
    COUNT(DISTINCT a.ticker) as qtd_acoes_diferentes,
    SUM(a.valor_comprado) / 1000000000.0 as total_comprado_bilhoes,
    ROUND(AVG(a.rentabilidade_pct), 2) as rentabilidade_media_pct
FROM acoes_fundos a
JOIN grupos_fundos g ON a.grupo_id = g.id
WHERE a.mes_referencia = '2025-11-30'  -- ⚠️ ALTERE O MÊS
  AND a.tipo_movimento = 'COMPRA'
GROUP BY g.nome_grupo
ORDER BY total_comprado_bilhoes DESC
LIMIT 20;


-- ========================================
-- 7. AÇÕES MAIS POPULARES (MAIS FUNDOS POSICIONADOS)
-- ========================================

SELECT
    ticker,
    empresa,
    qtd_fundos_posicionados,
    qtd_fundos_compradores,
    qtd_fundos_vendedores,
    ROUND(fluxo_liquido / 1000000.0, 2) as fluxo_milhoes,
    tendencia_mercado
FROM resumo_mensal
WHERE mes_referencia = '2025-11-30'  -- ⚠️ ALTERE O MÊS
ORDER BY qtd_fundos_posicionados DESC
LIMIT 30;


-- ========================================
-- 8. COMPARAR DOIS GRUPOS (ITAÚ vs BRADESCO)
-- ========================================

WITH grupos_comparacao AS (
    SELECT
        g.nome_grupo,
        a.ticker,
        a.tipo_movimento,
        a.fluxo_liquido / 1000000.0 as fluxo_milhoes
    FROM acoes_fundos a
    JOIN grupos_fundos g ON a.grupo_id = g.id
    WHERE a.mes_referencia = '2025-11-30'  -- ⚠️ ALTERE O MÊS
      AND g.nome_grupo IN ('Itaú', 'Bradesco')  -- ⚠️ ALTERE OS GRUPOS
      AND a.tipo_movimento = 'COMPRA'
)
SELECT
    ticker,
    MAX(CASE WHEN nome_grupo = 'Itaú' THEN ROUND(fluxo_milhoes, 2) END) as itau_milhoes,
    MAX(CASE WHEN nome_grupo = 'Bradesco' THEN ROUND(fluxo_milhoes, 2) END) as bradesco_milhoes
FROM grupos_comparacao
GROUP BY ticker
HAVING MAX(CASE WHEN nome_grupo = 'Itaú' THEN fluxo_milhoes END) IS NOT NULL
   AND MAX(CASE WHEN nome_grupo = 'Bradesco' THEN fluxo_milhoes END) IS NOT NULL
ORDER BY itau_milhoes DESC
LIMIT 20;


-- ========================================
-- 9. RESUMO GERAL DO SISTEMA
-- ========================================

SELECT
    'Grupos cadastrados' as metrica,
    COUNT(*)::text as valor
FROM grupos_fundos

UNION ALL

SELECT
    'Total de ações (todos os meses)' as metrica,
    COUNT(*)::text as valor
FROM acoes_fundos

UNION ALL

SELECT
    'Meses disponíveis' as metrica,
    COUNT(DISTINCT mes_referencia)::text as valor
FROM acoes_fundos

UNION ALL

SELECT
    'Tickers únicos' as metrica,
    COUNT(DISTINCT ticker)::text as valor
FROM acoes_fundos;


-- ========================================
-- 10. LISTA DE GRUPOS DISPONÍVEIS
-- ========================================
-- Use esta query para ver quais grupos você pode consultar

SELECT
    id,
    nome_grupo,
    qtd_fundos,
    ROUND(pl_total_bilhoes, 2) as pl_bilhoes
FROM grupos_fundos
ORDER BY pl_total_bilhoes DESC;


-- ========================================
-- 11. AÇÕES COM MAIOR DIVERGÊNCIA (COMPRA E VENDA)
-- ========================================
-- Ações onde muitos fundos compraram E muitos venderam (opiniões divididas)

SELECT
    ticker,
    empresa,
    qtd_fundos_compradores,
    qtd_fundos_vendedores,
    ROUND(fluxo_liquido / 1000000.0, 2) as fluxo_milhoes,
    tendencia_mercado
FROM resumo_mensal
WHERE mes_referencia = '2025-11-30'  -- ⚠️ ALTERE O MÊS
  AND qtd_fundos_compradores >= 5
  AND qtd_fundos_vendedores >= 5
ORDER BY (qtd_fundos_compradores + qtd_fundos_vendedores) DESC
LIMIT 20;


-- ========================================
-- 12. RENTABILIDADE DOS GRUPOS
-- ========================================
-- Veja quais grupos tiveram melhor rentabilidade nas posições

SELECT
    g.nome_grupo,
    COUNT(DISTINCT a.ticker) as qtd_acoes,
    ROUND(AVG(a.rentabilidade_pct), 2) as rentabilidade_media_pct,
    ROUND(SUM(a.valor_mercado) / 1000000000.0, 2) as valor_mercado_bilhoes
FROM acoes_fundos a
JOIN grupos_fundos g ON a.grupo_id = g.id
WHERE a.mes_referencia = '2025-11-30'  -- ⚠️ ALTERE O MÊS
  AND a.rentabilidade_pct IS NOT NULL
GROUP BY g.nome_grupo
ORDER BY rentabilidade_media_pct DESC
LIMIT 20;
