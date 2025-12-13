-- ====================================================================
-- VIEWS OTIMIZADAS - Apenas Top 100 Grupos
-- Todas as análises filtradas para os 100 maiores grupos
-- ====================================================================

-- ====================================================================
-- VIEW: Movimentações de Ações (Top 100 apenas)
-- Substitui v_movimentacoes_acoes com filtro automático
-- ====================================================================

CREATE OR REPLACE VIEW v_movimentacoes_acoes_top100 AS
WITH top100_grupos AS (
    SELECT DISTINCT grupo_id
    FROM ranking_top100_grupos
    WHERE (ano, mes) = (
        SELECT ano, mes FROM ranking_top100_grupos
        ORDER BY ano DESC, mes DESC LIMIT 1
    )
)
SELECT
    t.data_completa,
    t.ano,
    t.mes,
    t.mes_nome,
    acoes.ticker,
    acoes.empresa_nome,
    acoes.setor,
    acoes.subsetor,
    acoes.capitalizacao_faixa,
    acoes.categoria_analise,
    f.cnpj_fundo_classe,
    f.nome_fundo,
    g.nome_grupo,
    g.tipo_grupo,
    fp.quantidade_posicao_final,
    fp.valor_mercado_posicao,
    fp.valor_custo_posicao,
    fp.percentual_pl,
    fp.quantidade_aquisicao AS qtd_compra,
    fp.valor_aquisicao AS valor_compra,
    fp.quantidade_venda AS qtd_venda,
    fp.valor_venda AS valor_venda,
    (fp.valor_aquisicao - fp.valor_venda) AS saldo_liquido,
    CASE
        WHEN fp.valor_aquisicao > fp.valor_venda THEN 'COMPRA'
        WHEN fp.valor_venda > fp.valor_aquisicao THEN 'VENDA'
        ELSE 'SEM MOVIMENTAÇÃO'
    END AS tipo_movimentacao,
    fp.valor_lucro_prejuizo,
    fp.rentabilidade_posicao,
    pl.valor_pl AS pl_fundo
FROM fato_posicoes fp
JOIN dim_tempo t ON fp.data_id = t.id
JOIN dim_fundos f ON fp.fundo_id = f.id
JOIN dim_grupos_economicos g ON f.grupo_economico_id = g.id
JOIN dim_ativos a ON fp.ativo_id = a.id
JOIN dim_acoes_b3 acoes ON a.id = acoes.ativo_id
LEFT JOIN dim_patrimonio_liquido pl ON fp.fundo_id = pl.fundo_id AND fp.data_id = pl.data_id
WHERE fp.categoria_ativo_id IN (
    SELECT id FROM dim_categoria_ativo WHERE nivel1_macro = 'Renda Variável'
)
AND g.id IN (SELECT grupo_id FROM top100_grupos); -- FILTRO TOP 100

COMMENT ON VIEW v_movimentacoes_acoes_top100 IS 'Movimentações de ações filtradas para os top 100 grupos';


-- ====================================================================
-- VIEW: Fluxo Líquido por Ação (Top 100)
-- ====================================================================

CREATE OR REPLACE VIEW v_fluxo_liquido_acoes_top100 AS
SELECT
    ano,
    mes,
    mes_nome,
    ticker,
    empresa_nome,
    setor,
    subsetor,
    categoria_analise,
    SUM(valor_compra) AS total_compras,
    SUM(valor_venda) AS total_vendas,
    SUM(saldo_liquido) AS fluxo_liquido,
    SUM(qtd_compra) AS qtd_total_comprada,
    SUM(qtd_venda) AS qtd_total_vendida,
    SUM(qtd_compra - qtd_venda) AS saldo_quantidade,
    COUNT(DISTINCT CASE WHEN valor_compra > 0 THEN cnpj_fundo_classe END) AS fundos_compradores,
    COUNT(DISTINCT CASE WHEN valor_venda > 0 THEN cnpj_fundo_classe END) AS fundos_vendedores,
    COUNT(DISTINCT cnpj_fundo_classe) AS total_fundos,
    CASE
        WHEN SUM(saldo_liquido) > 1000000 THEN 'FORTE COMPRA'
        WHEN SUM(saldo_liquido) > 0 THEN 'COMPRA MODERADA'
        WHEN SUM(saldo_liquido) < -1000000 THEN 'FORTE VENDA'
        WHEN SUM(saldo_liquido) < 0 THEN 'VENDA MODERADA'
        ELSE 'NEUTRO'
    END AS tendencia_mercado
FROM v_movimentacoes_acoes_top100
GROUP BY ano, mes, mes_nome, ticker, empresa_nome, setor, subsetor, categoria_analise;

COMMENT ON VIEW v_fluxo_liquido_acoes_top100 IS 'Fluxo líquido de ações dos top 100 grupos';


-- ====================================================================
-- VIEW: Ranking Compras (Top 100)
-- ====================================================================

CREATE OR REPLACE VIEW v_ranking_compras_top100 AS
SELECT
    ano,
    mes,
    mes_nome,
    ticker,
    empresa_nome,
    setor,
    categoria_analise,
    COUNT(DISTINCT cnpj_fundo_classe) AS qtd_fundos_compradores,
    SUM(valor_compra) AS total_comprado,
    AVG(valor_compra) AS media_compra_por_fundo,
    SUM(qtd_compra) AS total_quantidade_comprada,
    RANK() OVER (PARTITION BY ano, mes ORDER BY SUM(valor_compra) DESC) AS ranking_compra
FROM v_movimentacoes_acoes_top100
WHERE tipo_movimentacao = 'COMPRA'
GROUP BY ano, mes, mes_nome, ticker, empresa_nome, setor, categoria_analise;

COMMENT ON VIEW v_ranking_compras_top100 IS 'Ranking de compras dos top 100 grupos';


-- ====================================================================
-- VIEW: Ranking Vendas (Top 100)
-- ====================================================================

CREATE OR REPLACE VIEW v_ranking_vendas_top100 AS
SELECT
    ano,
    mes,
    mes_nome,
    ticker,
    empresa_nome,
    setor,
    categoria_analise,
    COUNT(DISTINCT cnpj_fundo_classe) AS qtd_fundos_vendedores,
    SUM(valor_venda) AS total_vendido,
    AVG(valor_venda) AS media_venda_por_fundo,
    SUM(qtd_venda) AS total_quantidade_vendida,
    RANK() OVER (PARTITION BY ano, mes ORDER BY SUM(valor_venda) DESC) AS ranking_venda
FROM v_movimentacoes_acoes_top100
WHERE tipo_movimentacao = 'VENDA'
GROUP BY ano, mes, mes_nome, ticker, empresa_nome, setor, categoria_analise;

COMMENT ON VIEW v_ranking_vendas_top100 IS 'Ranking de vendas dos top 100 grupos';


-- ====================================================================
-- VIEW: Dashboard Executivo - Visão Consolidada
-- Tudo em uma única view para dashboards
-- ====================================================================

CREATE OR REPLACE VIEW v_dashboard_top100 AS
SELECT
    r.ranking_patrimonio,
    r.nome_grupo,
    r.tipo_grupo,

    -- Patrimônio
    r.patrimonio_liquido_total / 1000000000.0 AS pl_bilhoes,
    r.percentual_pl_em_acoes AS perc_acoes,

    -- Movimentação
    r.volume_total_movimentado / 1000000.0 AS volume_movimentado_milhoes,
    r.volume_compras / 1000000.0 AS compras_milhoes,
    r.volume_vendas / 1000000.0 AS vendas_milhoes,
    r.fluxo_liquido / 1000000.0 AS fluxo_liquido_milhoes,
    r.tendencia_mes,

    -- Métricas
    r.qtd_fundos,
    r.qtd_posicoes_acoes,
    r.valor_total_acoes / 1000000000.0 AS acoes_bilhoes,

    -- Rankings
    r.ranking_volume_movimentado,

    -- Período
    r.ano,
    r.mes,
    r.data_referencia

FROM ranking_top100_grupos r
WHERE (ano, mes) = (
    SELECT ano, mes FROM ranking_top100_grupos
    ORDER BY ano DESC, mes DESC LIMIT 1
)
ORDER BY r.ranking_patrimonio;

COMMENT ON VIEW v_dashboard_top100 IS 'Dashboard executivo consolidado dos top 100 grupos';


-- ====================================================================
-- VIEW: Comparação Mês a Mês (Top 100)
-- Evolução dos top 100 ao longo do tempo
-- ====================================================================

CREATE OR REPLACE VIEW v_evolucao_top100 AS
SELECT
    r.nome_grupo,
    r.ano,
    r.mes,
    r.ranking_patrimonio,
    r.patrimonio_liquido_total / 1000000000.0 AS pl_bilhoes,
    r.volume_total_movimentado / 1000000.0 AS volume_milhoes,
    r.fluxo_liquido / 1000000.0 AS fluxo_milhoes,
    r.tendencia_mes,

    -- Variação vs mês anterior
    LAG(r.ranking_patrimonio) OVER (PARTITION BY r.grupo_id ORDER BY r.ano, r.mes) AS ranking_anterior,
    LAG(r.patrimonio_liquido_total) OVER (PARTITION BY r.grupo_id ORDER BY r.ano, r.mes) AS pl_anterior,

    -- Calculado
    r.ranking_patrimonio - LAG(r.ranking_patrimonio) OVER (PARTITION BY r.grupo_id ORDER BY r.ano, r.mes) AS variacao_ranking,
    (r.patrimonio_liquido_total - LAG(r.patrimonio_liquido_total) OVER (PARTITION BY r.grupo_id ORDER BY r.ano, r.mes)) / 1000000.0 AS variacao_pl_milhoes

FROM ranking_top100_grupos r
ORDER BY r.nome_grupo, r.ano, r.mes;

COMMENT ON VIEW v_evolucao_top100 IS 'Evolução temporal dos top 100 grupos (mês a mês)';


-- ====================================================================
-- VIEW: Concentração de Mercado (Top 10, Top 20, Top 50, Top 100)
-- Quanto % do mercado cada grupo controla
-- ====================================================================

CREATE OR REPLACE VIEW v_concentracao_mercado_top100 AS
WITH totais AS (
    SELECT
        ano,
        mes,
        SUM(patrimonio_liquido_total) AS pl_total_mercado
    FROM ranking_top100_grupos
    GROUP BY ano, mes
)
SELECT
    r.ranking_patrimonio,
    r.nome_grupo,
    r.patrimonio_liquido_total / 1000000000.0 AS pl_bilhoes,
    ROUND(100.0 * r.patrimonio_liquido_total / t.pl_total_mercado, 2) AS percentual_mercado,

    -- Concentração Acumulada
    ROUND(
        100.0 * SUM(r.patrimonio_liquido_total) OVER (
            PARTITION BY r.ano, r.mes
            ORDER BY r.ranking_patrimonio
        ) / t.pl_total_mercado,
        2
    ) AS percentual_acumulado,

    -- Classificação
    CASE
        WHEN r.ranking_patrimonio <= 10 THEN 'Top 10'
        WHEN r.ranking_patrimonio <= 20 THEN 'Top 20'
        WHEN r.ranking_patrimonio <= 50 THEN 'Top 50'
        ELSE 'Top 100'
    END AS faixa,

    r.ano,
    r.mes

FROM ranking_top100_grupos r
JOIN totais t ON r.ano = t.ano AND r.mes = t.mes
WHERE (r.ano, r.mes) = (
    SELECT ano, mes FROM ranking_top100_grupos
    ORDER BY ano DESC, mes DESC LIMIT 1
)
ORDER BY r.ranking_patrimonio;

COMMENT ON VIEW v_concentracao_mercado_top100 IS 'Análise de concentração de mercado (Top 10/20/50/100)';
