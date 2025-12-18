-- ========================================
-- 📊 DASHBOARD INVESTIDOR - QUERIES PRÁTICAS
-- Queries simples para gerar insights acionáveis
-- ========================================

-- ========================================
-- 🎯 CATEGORIA 1: SINAIS CLAROS (O MAIS IMPORTANTE)
-- ========================================

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 1.1 🟢 COMPRA FORTE (Consenso >80% + Volume Alto)
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 💡 INSIGHT: Ações que os grandes estão comprando com CONSENSO FORTE
-- 🎯 USO: Lista de ações para considerar comprar

SELECT
    ticker,
    empresa,
    '🟢 COMPRA FORTE' as sinal,
    qtd_fundos_compradores as fundos_comprando,
    ROUND(fluxo_bilhoes::numeric, 2) as bilhoes_comprados,
    ROUND(intensidade_consenso, 0) || '%' as consenso
FROM v_consenso_mercado
WHERE tendencia_mercado = 'COMPRA'
  AND intensidade_consenso > 80  -- Consenso muito forte
  AND ABS(fluxo_bilhoes) > 0.1   -- Volume mínimo 100 milhões
ORDER BY intensidade_consenso DESC, ABS(fluxo_bilhoes) DESC
LIMIT 15;

-- 📌 COMO INTERPRETAR:
-- • Consenso >90% = Quase unanimidade (sinal muito forte)
-- • Consenso 80-90% = Forte acordo entre fundos
-- • Volume >1 bilhão = Movimento muito significativo


-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 1.2 🔴 VENDA FORTE (Consenso >80% + Volume Alto)
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 💡 INSIGHT: Ações que os grandes estão VENDENDO com consenso
-- 🎯 USO: Ações para EVITAR ou considerar sair

SELECT
    ticker,
    empresa,
    '🔴 VENDA FORTE' as sinal,
    qtd_fundos_vendedores as fundos_vendendo,
    ROUND(ABS(fluxo_bilhoes::numeric), 2) as bilhoes_vendidos,
    ROUND(intensidade_consenso, 0) || '%' as consenso
FROM v_consenso_mercado
WHERE tendencia_mercado = 'VENDA'
  AND intensidade_consenso > 80
  AND ABS(fluxo_bilhoes) > 0.1
ORDER BY intensidade_consenso DESC, ABS(fluxo_bilhoes) DESC
LIMIT 15;


-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 1.3 🟡 OPORTUNIDADES MÉDIO CONSENSO (60-80%)
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 💡 INSIGHT: Ações com bom consenso mas menor risco
-- 🎯 USO: Alternativas mais conservadoras

SELECT
    ticker,
    empresa,
    CASE
        WHEN tendencia_mercado = 'COMPRA' THEN '🟢 Compra Moderada'
        ELSE '🔴 Venda Moderada'
    END as sinal,
    qtd_fundos_compradores as comprando,
    qtd_fundos_vendedores as vendendo,
    ROUND(fluxo_bilhoes::numeric, 2) as fluxo_bilhoes,
    ROUND(intensidade_consenso, 0) || '%' as consenso
FROM v_consenso_mercado
WHERE intensidade_consenso BETWEEN 60 AND 80
  AND ABS(fluxo_bilhoes) > 0.05
ORDER BY intensidade_consenso DESC
LIMIT 20;


-- ========================================
-- 📈 CATEGORIA 2: TENDÊNCIAS E MOMENTUM
-- ========================================

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 2.1 📊 MOMENTUM: Ações em Alta nos Últimos Meses
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 💡 INSIGHT: Ações consistentemente compradas mês após mês
-- 🎯 USO: Identificar tendências de longo prazo

WITH compras_mensais AS (
    SELECT
        ticker,
        MAX(empresa) as empresa,
        COUNT(CASE WHEN total_comprado > total_vendido THEN 1 END) as meses_comprando,
        COUNT(DISTINCT mes_referencia) as total_meses,
        SUM(total_comprado - total_vendido) / 1000000000.0 as fluxo_total_bilhoes
    FROM resumo_mensal
    GROUP BY ticker
)
SELECT
    ticker,
    empresa,
    meses_comprando || '/' || total_meses as meses_positivos,
    ROUND((meses_comprando::float / total_meses * 100), 0) || '%' as consistencia,
    ROUND(fluxo_total_bilhoes, 2) as fluxo_acumulado_bi
FROM compras_mensais
WHERE total_meses >= 3  -- Pelo menos 3 meses de dados
  AND meses_comprando >= 3  -- Comprado em pelo menos 3 meses
  AND fluxo_total_bilhoes > 0.1
ORDER BY (meses_comprando::float / total_meses) DESC, fluxo_total_bilhoes DESC
LIMIT 20;

-- 📌 COMO INTERPRETAR:
-- • 4/4 meses = Tendência super consistente
-- • 3/4 meses = Tendência forte
-- • Fluxo >1 bi = Volume muito significativo


-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 2.2 🔄 REVERSÕES: Mudança de Tendência
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 💡 INSIGHT: Ações que mudaram de venda para compra (ou vice-versa)
-- 🎯 USO: Identificar possíveis pontos de inflexão

WITH ultimo_mes AS (
    SELECT ticker, tendencia_mercado as tendencia_atual
    FROM resumo_mensal
    WHERE mes_referencia = '2025-11-30'  -- ⚠️ ÚLTIMO MÊS
),
mes_anterior AS (
    SELECT ticker, tendencia_mercado as tendencia_anterior
    FROM resumo_mensal
    WHERE mes_referencia = '2025-10-31'  -- ⚠️ MÊS ANTERIOR
)
SELECT
    u.ticker,
    r.empresa,
    m.tendencia_anterior || ' → ' || u.tendencia_atual as mudanca,
    CASE
        WHEN m.tendencia_anterior = 'VENDA' AND u.tendencia_atual = 'COMPRA'
        THEN '🟢 Virou Compra'
        WHEN m.tendencia_anterior = 'COMPRA' AND u.tendencia_atual = 'VENDA'
        THEN '🔴 Virou Venda'
        ELSE '🟡 Mudança Neutro'
    END as sinal,
    r.qtd_fundos_compradores as fundos_comprando,
    r.qtd_fundos_vendedores as fundos_vendendo,
    ROUND(r.fluxo_liquido / 1000000.0, 2) as fluxo_milhoes
FROM ultimo_mes u
JOIN mes_anterior m ON u.ticker = m.ticker
JOIN resumo_mensal r ON r.ticker = u.ticker AND r.mes_referencia = '2025-11-30'
WHERE u.tendencia_atual != m.tendencia_anterior
  AND u.tendencia_atual != 'NEUTRO'
  AND m.tendencia_anterior != 'NEUTRO'
ORDER BY ABS(r.fluxo_liquido) DESC
LIMIT 25;


-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 2.3 🚀 NOVAS APOSTAS: Ações Entrando no Radar
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 💡 INSIGHT: Ações que não estavam no top mas agora estão
-- 🎯 USO: Descobrir novas oportunidades antes da multidão

WITH ranking_atual AS (
    SELECT ticker, ranking
    FROM v_top_compras_mes
    WHERE mes_referencia = '2025-11-30'  -- ⚠️ MÊS ATUAL
      AND ranking <= 30
),
ranking_anterior AS (
    SELECT ticker, ranking
    FROM v_top_compras_mes
    WHERE mes_referencia = '2025-10-31'  -- ⚠️ MÊS ANTERIOR
)
SELECT
    r.ticker,
    r.empresa,
    a.ranking as posicao_atual,
    COALESCE(ant.ranking, 999) as posicao_anterior,
    (COALESCE(ant.ranking, 999) - a.ranking) as subiu_posicoes,
    ROUND(r.comprado_milhoes, 2) as milhoes_comprados,
    r.qtd_fundos_compradores as fundos_comprando
FROM ranking_atual a
LEFT JOIN ranking_anterior ant ON a.ticker = ant.ticker
JOIN v_top_compras_mes r ON r.ticker = a.ticker AND r.mes_referencia = '2025-11-30'
WHERE COALESCE(ant.ranking, 999) > 30  -- Não estava no top 30 antes
   OR ant.ranking IS NULL  -- Ou não existia
ORDER BY a.ranking
LIMIT 15;


-- ========================================
-- 🎓 CATEGORIA 3: APRENDA COM OS GRANDES
-- ========================================

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 3.1 👑 COPIE O LÍDER: O Que os Top 5 Grupos Estão Comprando
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 💡 INSIGHT: Decisões dos maiores gestores do Brasil
-- 🎯 USO: Seguir os profissionais mais bem-sucedidos

WITH top5_grupos AS (
    SELECT id, nome_grupo
    FROM grupos_fundos
    ORDER BY pl_total_bilhoes DESC
    LIMIT 5
)
SELECT
    g.nome_grupo as grande_grupo,
    a.ticker,
    a.empresa,
    a.tipo_movimento,
    ROUND(a.fluxo_liquido / 1000000.0, 2) as fluxo_milhoes,
    ROUND(a.valor_mercado / 1000000.0, 2) as posicao_milhoes,
    a.rentabilidade_pct
FROM acoes_fundos a
JOIN top5_grupos g ON a.grupo_id = g.id
WHERE a.mes_referencia = '2025-11-30'  -- ⚠️ ALTERE O MÊS
  AND a.tipo_movimento = 'COMPRA'
  AND ABS(a.fluxo_liquido) > 10000000  -- Mínimo 10 milhões
ORDER BY g.nome_grupo, ABS(a.fluxo_liquido) DESC;


-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 3.2 💰 MAIORES POSIÇÕES: Onde Há Mais Dinheiro?
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 💡 INSIGHT: Ações onde os fundos têm mais capital investido
-- 🎯 USO: Ver onde os grandes colocam MUITO dinheiro (convicção)

SELECT
    a.ticker,
    a.empresa,
    COUNT(DISTINCT g.id) as qtd_grupos_posicionados,
    ROUND(SUM(a.valor_mercado) / 1000000000.0, 2) as posicao_total_bilhoes,
    ROUND(AVG(a.rentabilidade_pct), 2) as rentabilidade_media_pct
FROM acoes_fundos a
JOIN grupos_fundos g ON a.grupo_id = g.id
WHERE a.mes_referencia = '2025-11-30'  -- ⚠️ ALTERE O MÊS
  AND a.valor_mercado > 0
GROUP BY a.ticker, a.empresa
HAVING SUM(a.valor_mercado) > 100000000  -- Mais de 100 milhões
ORDER BY posicao_total_bilhoes DESC
LIMIT 25;

-- 📌 COMO INTERPRETAR:
-- • Posição >5 bi = Mega convicção
-- • Muitos grupos + volume alto = Consenso de longo prazo


-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 3.3 🎯 CONCENTRAÇÃO: Apostas Específicas de um Grupo
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 💡 INSIGHT: Ver portfolio específico de um grande gestor
-- 🎯 USO: Entender estratégia de um grupo específico

SELECT
    a.ticker,
    a.empresa,
    ROUND(a.valor_mercado / 1000000.0, 2) as posicao_milhoes,
    ROUND(a.valor_mercado * 100.0 / SUM(a.valor_mercado) OVER (), 2) || '%' as pct_portfolio,
    a.tipo_movimento as ultimo_movimento,
    ROUND(a.fluxo_liquido / 1000000.0, 2) as fluxo_milhoes,
    a.rentabilidade_pct
FROM acoes_fundos a
JOIN grupos_fundos g ON a.grupo_id = g.id
WHERE g.nome_grupo = 'Itaú'  -- ⚠️ ALTERE O GRUPO
  AND a.mes_referencia = '2025-11-30'  -- ⚠️ ALTERE O MÊS
  AND a.valor_mercado > 0
ORDER BY a.valor_mercado DESC
LIMIT 20;


-- ========================================
-- 🔍 CATEGORIA 4: MONITORAMENTO ESPECÍFICO
-- ========================================

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 4.1 📍 RADAR DE UMA AÇÃO: Análise Completa
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 💡 INSIGHT: Tudo sobre uma ação específica em um mês
-- 🎯 USO: Análise profunda antes de comprar/vender

-- Parte 1: Resumo Geral
SELECT
    '📊 RESUMO GERAL' as secao,
    ticker,
    empresa,
    tendencia_mercado,
    ROUND(intensidade_consenso, 0) || '%' as consenso,
    qtd_fundos_compradores || ' comprando' as compradores,
    qtd_fundos_vendedores || ' vendendo' as vendedores,
    ROUND(fluxo_liquido / 1000000.0, 2) || ' milhões' as fluxo_liquido
FROM resumo_mensal
WHERE ticker = 'PETR4'  -- ⚠️ ALTERE O TICKER
  AND mes_referencia = '2025-11-30'  -- ⚠️ ALTERE O MÊS

UNION ALL

-- Parte 2: Quem está comprando
SELECT
    '🟢 TOP COMPRADORES' as secao,
    g.nome_grupo as ticker,
    '' as empresa,
    '' as tendencia_mercado,
    '' as consenso,
    ROUND(a.valor_comprado / 1000000.0, 2)::text as compradores,
    ROUND(a.fluxo_liquido / 1000000.0, 2)::text as vendedores,
    '' as fluxo_liquido
FROM acoes_fundos a
JOIN grupos_fundos g ON a.grupo_id = g.id
WHERE a.ticker = 'PETR4'  -- ⚠️ ALTERE O TICKER
  AND a.mes_referencia = '2025-11-30'  -- ⚠️ ALTERE O MÊS
  AND a.valor_comprado > a.valor_vendido
ORDER BY a.valor_comprado DESC
LIMIT 5;


-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 4.2 📈 EVOLUÇÃO TEMPORAL: Ação nos Últimos Meses
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 💡 INSIGHT: Histórico de compra/venda de uma ação
-- 🎯 USO: Ver se tendência está acelerando ou desacelerando

SELECT
    mes_referencia,
    ticker,
    tendencia_mercado,
    qtd_fundos_compradores as comprando,
    qtd_fundos_vendedores as vendendo,
    ROUND(total_comprado / 1000000.0, 2) as total_comprado_milhoes,
    ROUND(total_vendido / 1000000.0, 2) as total_vendido_milhoes,
    ROUND(fluxo_liquido / 1000000.0, 2) as fluxo_milhoes,
    ROUND(intensidade_consenso, 0) || '%' as consenso
FROM resumo_mensal
WHERE ticker = 'PETR4'  -- ⚠️ ALTERE O TICKER
ORDER BY mes_referencia;


-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 4.3 🆚 COMPARAR AÇÕES: Lado a Lado
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 💡 INSIGHT: Comparar duas ações similares
-- 🎯 USO: Decidir entre duas opções (ex: PETR4 vs PETR3)

SELECT
    ticker,
    empresa,
    tendencia_mercado,
    qtd_fundos_compradores as compradores,
    qtd_fundos_vendedores as vendedores,
    ROUND(fluxo_liquido / 1000000.0, 2) as fluxo_milhoes,
    ROUND(intensidade_consenso, 0) || '%' as consenso,
    top_comprador,
    ROUND(valor_top_comprador / 1000000.0, 2) as top_comprador_milhoes
FROM resumo_mensal
WHERE ticker IN ('PETR4', 'VALE3', 'BBAS3')  -- ⚠️ ALTERE OS TICKERS
  AND mes_referencia = '2025-11-30'  -- ⚠️ ALTERE O MÊS
ORDER BY ABS(fluxo_liquido) DESC;


-- ========================================
-- 💎 CATEGORIA 5: DESCOBERTA DE OPORTUNIDADES
-- ========================================

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 5.1 💎 HIDDEN GEMS: Ações Pouco Conhecidas com Forte Compra
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 💡 INSIGHT: Ações fora do radar com sinal de compra
-- 🎯 USO: Encontrar oportunidades antes da massa

SELECT
    ticker,
    empresa,
    qtd_fundos_compradores as fundos_comprando,
    ROUND(total_comprado / 1000000.0, 2) as comprado_milhoes,
    ROUND(intensidade_consenso, 0) || '%' as consenso,
    top_comprador
FROM resumo_mensal
WHERE mes_referencia = '2025-11-30'  -- ⚠️ ALTERE O MÊS
  AND tendencia_mercado = 'COMPRA'
  AND qtd_fundos_compradores BETWEEN 3 AND 10  -- Poucos fundos (não mainstream)
  AND intensidade_consenso > 70  -- Mas consenso forte entre os que compraram
  AND total_comprado > 50000000  -- Volume significativo (>50M)
ORDER BY intensidade_consenso DESC, total_comprado DESC
LIMIT 20;


-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 5.2 🔥 ALTA POPULARIDADE: O Que Todo Mundo Está Comprando
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 💡 INSIGHT: Ações muito populares (muitos fundos comprando)
-- 🎯 USO: Ver consenso amplo do mercado

SELECT
    ticker,
    empresa,
    qtd_fundos_posicionados as total_fundos,
    qtd_fundos_compradores as comprando,
    qtd_fundos_vendedores as vendendo,
    ROUND((qtd_fundos_compradores::float / qtd_fundos_posicionados * 100), 0) || '%' as pct_comprando,
    ROUND(total_comprado / 1000000.0, 2) as comprado_milhoes,
    tendencia_mercado
FROM resumo_mensal
WHERE mes_referencia = '2025-11-30'  -- ⚠️ ALTERE O MÊS
  AND qtd_fundos_posicionados >= 15  -- Muitos fundos posicionados
  AND tendencia_mercado = 'COMPRA'
ORDER BY qtd_fundos_compradores DESC, total_comprado DESC
LIMIT 20;


-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 5.3 ⚡ ALTA CONVICÇÃO: Poucos Fundos, Muito Dinheiro
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 💡 INSIGHT: Apostas concentradas (alta convicção)
-- 🎯 USO: Ver onde gestores colocam MUITO dinheiro em poucas ações

SELECT
    ticker,
    empresa,
    qtd_fundos_compradores as fundos,
    ROUND(total_comprado / 1000000.0, 2) as comprado_milhoes,
    ROUND(total_comprado / 1000000.0 / NULLIF(qtd_fundos_compradores, 0), 2) as milhoes_por_fundo,
    top_comprador,
    ROUND(valor_top_comprador / 1000000.0, 2) as top_milhoes
FROM resumo_mensal
WHERE mes_referencia = '2025-11-30'  -- ⚠️ ALTERE O MÊS
  AND tendencia_mercado = 'COMPRA'
  AND qtd_fundos_compradores <= 8  -- Poucos fundos
  AND total_comprado > 100000000  -- Mas muito dinheiro (>100M)
ORDER BY (total_comprado / NULLIF(qtd_fundos_compradores, 1)) DESC
LIMIT 20;

-- 📌 COMO INTERPRETAR:
-- • >50M por fundo = ALTA convicção
-- • Top comprador com >50% = Aposta concentrada


-- ========================================
-- 📊 CATEGORIA 6: VISÃO GERAL / CONTEXTO
-- ========================================

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 6.1 📊 PAINEL GERAL: Snapshot do Mercado
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 💡 INSIGHT: Visão macro do que está acontecendo
-- 🎯 USO: Contexto geral antes de analisar específicos

SELECT
    tendencia_mercado as tendencia,
    COUNT(*) as qtd_acoes,
    ROUND(AVG(intensidade_consenso), 0) || '%' as consenso_medio,
    ROUND(SUM(ABS(fluxo_liquido)) / 1000000000.0, 2) as volume_total_bilhoes
FROM resumo_mensal
WHERE mes_referencia = '2025-11-30'  -- ⚠️ ALTERE O MÊS
GROUP BY tendencia_mercado
ORDER BY
    CASE tendencia_mercado
        WHEN 'COMPRA' THEN 1
        WHEN 'NEUTRO' THEN 2
        WHEN 'VENDA' THEN 3
    END;


-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 6.2 📅 COMPARAÇÃO MENSAL: Como o Mercado Mudou
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 💡 INSIGHT: Evolução do sentimento do mercado
-- 🎯 USO: Ver se mercado está mais otimista ou pessimista

SELECT
    mes_referencia,
    COUNT(CASE WHEN tendencia_mercado = 'COMPRA' THEN 1 END) as acoes_em_compra,
    COUNT(CASE WHEN tendencia_mercado = 'VENDA' THEN 1 END) as acoes_em_venda,
    COUNT(CASE WHEN tendencia_mercado = 'NEUTRO' THEN 1 END) as acoes_neutras,
    ROUND(SUM(CASE WHEN tendencia_mercado = 'COMPRA' THEN fluxo_liquido ELSE 0 END) / 1000000000.0, 2) as fluxo_compra_bi,
    ROUND(SUM(CASE WHEN tendencia_mercado = 'VENDA' THEN ABS(fluxo_liquido) ELSE 0 END) / 1000000000.0, 2) as fluxo_venda_bi
FROM resumo_mensal
GROUP BY mes_referencia
ORDER BY mes_referencia;


-- ========================================
-- 🎓 GUIA DE USO RÁPIDO
-- ========================================

/*
🟢 PARA COMPRAR:
1. Comece com query 1.1 (Compra Forte)
2. Verifique momentum com 2.1
3. Confirme com query 3.2 (Maiores Posições)
4. Análise profunda com 4.1 (Radar)

🔴 PARA VENDER:
1. Verifique query 1.2 (Venda Forte)
2. Veja reversões com 2.2
3. Compare com sua carteira

🔍 PARA DESCOBRIR:
1. Hidden Gems (5.1)
2. Alta Convicção (5.3)
3. Novas Apostas (2.3)

📊 PARA CONTEXTO:
1. Painel Geral (6.1)
2. Comparação Mensal (6.2)

⚠️ LEMBRE-SE:
• Altere parâmetros marcados com ⚠️
• Não use apenas UMA query - combine várias
• Sinais fortes = Consenso >80% + Volume alto
• Sempre faça sua própria análise fundamentalista
*/
