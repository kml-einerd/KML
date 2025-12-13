-- ========================================
-- MIGRAÇÃO 002: Agregações e Views Analíticas
-- Descrição: Cria materialized views e views para análises de negócio
-- Data: 2025-12-11
-- Dependência: 001_criar_modelo_dimensional.sql
-- ========================================

-- ========================================
-- 1. MATERIALIZED VIEWS (PRÉ-AGREGAÇÕES)
-- ========================================

-- Agregação por Grupo Econômico + Categoria + Mês
CREATE MATERIALIZED VIEW IF NOT EXISTS agg_grupo_categoria_mes AS
SELECT
    g.id AS grupo_id,
    g.nome_grupo,
    g.tipo_grupo,
    ca.id AS categoria_id,
    ca.nivel1_macro,
    ca.nivel2_tipo,
    ca.nivel3_subtipo,
    t.id AS data_id,
    t.ano,
    t.mes,
    t.mes_nome,

    -- Métricas de Volume
    COUNT(DISTINCT f.fundo_id) AS qtd_fundos,
    COUNT(*) AS qtd_posicoes,
    SUM(fp.valor_mercado_posicao) AS total_valor_mercado,
    SUM(fp.valor_custo_posicao) AS total_valor_custo,
    SUM(fp.valor_lucro_prejuizo) AS total_lucro_prejuizo,
    AVG(fp.percentual_pl) AS media_percentual_pl,

    -- Métricas de Movimentação
    SUM(fp.quantidade_venda) AS total_quantidade_venda,
    SUM(fp.valor_venda) AS total_valor_venda,
    SUM(fp.quantidade_aquisicao) AS total_quantidade_aquisicao,
    SUM(fp.valor_aquisicao) AS total_valor_aquisicao,
    SUM(fp.valor_aquisicao - fp.valor_venda) AS saldo_liquido,

    -- Rentabilidade
    CASE
        WHEN SUM(fp.valor_custo_posicao) > 0
        THEN ((SUM(fp.valor_mercado_posicao) / SUM(fp.valor_custo_posicao)) - 1) * 100
        ELSE 0
    END AS rentabilidade_pct,

    -- Metadados
    CURRENT_TIMESTAMP AS dt_atualizacao

FROM fato_posicoes fp
JOIN dim_fundos f ON fp.fundo_id = f.id
JOIN dim_grupos_economicos g ON f.grupo_economico_id = g.id
JOIN dim_categoria_ativo ca ON fp.categoria_ativo_id = ca.id
JOIN dim_tempo t ON fp.data_id = t.id
WHERE f.ativo = TRUE AND g.ativo = TRUE
GROUP BY
    g.id, g.nome_grupo, g.tipo_grupo,
    ca.id, ca.nivel1_macro, ca.nivel2_tipo, ca.nivel3_subtipo,
    t.id, t.ano, t.mes, t.mes_nome;

-- Índices para queries otimizadas
CREATE UNIQUE INDEX idx_agg_grupo_cat_mes_pk
    ON agg_grupo_categoria_mes(grupo_id, categoria_id, data_id);
CREATE INDEX idx_agg_grupo_cat_mes_grupo
    ON agg_grupo_categoria_mes(grupo_id, ano, mes);
CREATE INDEX idx_agg_grupo_cat_mes_categoria
    ON agg_grupo_categoria_mes(categoria_id, ano, mes);
CREATE INDEX idx_agg_grupo_cat_mes_data
    ON agg_grupo_categoria_mes(ano, mes);

COMMENT ON MATERIALIZED VIEW agg_grupo_categoria_mes IS
    'Agregação por grupo econômico e categoria de ativo (mensal)';

-- ========================================

-- Agregação por Emissor + Tempo
CREATE MATERIALIZED VIEW IF NOT EXISTS agg_emissor_tempo AS
SELECT
    e.id AS emissor_id,
    e.emissor_nome,
    e.cpf_cnpj_emissor,
    e.pf_pj_emissor,
    e.setor_economico,
    t.id AS data_id,
    t.ano,
    t.mes,

    -- Métricas de Exposição
    COUNT(DISTINCT fp.fundo_id) AS qtd_fundos_investidores,
    COUNT(*) AS qtd_posicoes,
    SUM(fp.valor_mercado_posicao) AS total_exposicao,
    AVG(fp.valor_mercado_posicao) AS media_exposicao_posicao,
    MAX(fp.valor_mercado_posicao) AS maior_exposicao,
    MIN(fp.valor_mercado_posicao) AS menor_exposicao,

    -- Concentração
    SUM(CASE WHEN fp.percentual_pl > 5 THEN 1 ELSE 0 END) AS posicoes_acima_5pct_pl,
    SUM(CASE WHEN fp.percentual_pl > 10 THEN 1 ELSE 0 END) AS posicoes_acima_10pct_pl,

    -- Liquidez
    SUM(fp.valor_venda) AS total_vendas,
    SUM(fp.valor_aquisicao) AS total_compras,

    CURRENT_TIMESTAMP AS dt_atualizacao

FROM fato_posicoes fp
JOIN dim_emissores e ON fp.emissor_id = e.id
JOIN dim_tempo t ON fp.data_id = t.id
WHERE e.ativo = TRUE
GROUP BY
    e.id, e.emissor_nome, e.cpf_cnpj_emissor, e.pf_pj_emissor, e.setor_economico,
    t.id, t.ano, t.mes;

CREATE UNIQUE INDEX idx_agg_emissor_tempo_pk
    ON agg_emissor_tempo(emissor_id, data_id);
CREATE INDEX idx_agg_emissor_tempo_exposicao
    ON agg_emissor_tempo(total_exposicao DESC);
CREATE INDEX idx_agg_emissor_tempo_data
    ON agg_emissor_tempo(ano, mes);

COMMENT ON MATERIALIZED VIEW agg_emissor_tempo IS
    'Exposição a emissores por período';

-- ========================================

-- Agregação por Fundo (Resumo de Carteira)
CREATE MATERIALIZED VIEW IF NOT EXISTS agg_fundo_carteira AS
SELECT
    fd.id AS fundo_id,
    fd.cnpj_fundo_classe,
    fd.nome_fundo,
    g.id AS grupo_id,
    g.nome_grupo,
    t.id AS data_id,
    t.ano,
    t.mes,

    -- Patrimônio Líquido
    fpl.vl_patrim_liq,

    -- Diversificação
    COUNT(DISTINCT ca.nivel1_macro) AS qtd_categorias_nivel1,
    COUNT(DISTINCT ca.nivel2_tipo) AS qtd_categorias_nivel2,
    COUNT(DISTINCT fp.emissor_id) AS qtd_emissores,
    COUNT(*) AS qtd_posicoes,

    -- Valores por Categoria Macro
    SUM(CASE WHEN ca.nivel1_macro = 'Renda Fixa' THEN fp.valor_mercado_posicao ELSE 0 END) AS valor_renda_fixa,
    SUM(CASE WHEN ca.nivel1_macro = 'Renda Variável' THEN fp.valor_mercado_posicao ELSE 0 END) AS valor_renda_variavel,
    SUM(CASE WHEN ca.nivel1_macro = 'Multimercado' THEN fp.valor_mercado_posicao ELSE 0 END) AS valor_multimercado,
    SUM(CASE WHEN ca.nivel1_macro = 'Exterior' THEN fp.valor_mercado_posicao ELSE 0 END) AS valor_exterior,
    SUM(CASE WHEN ca.nivel1_macro NOT IN ('Renda Fixa', 'Renda Variável', 'Multimercado', 'Exterior')
        THEN fp.valor_mercado_posicao ELSE 0 END) AS valor_outros,

    -- Percentuais
    CASE WHEN SUM(fp.valor_mercado_posicao) > 0
        THEN SUM(CASE WHEN ca.nivel1_macro = 'Renda Fixa' THEN fp.valor_mercado_posicao ELSE 0 END) /
             SUM(fp.valor_mercado_posicao) * 100
        ELSE 0 END AS pct_renda_fixa,
    CASE WHEN SUM(fp.valor_mercado_posicao) > 0
        THEN SUM(CASE WHEN ca.nivel1_macro = 'Renda Variável' THEN fp.valor_mercado_posicao ELSE 0 END) /
             SUM(fp.valor_mercado_posicao) * 100
        ELSE 0 END AS pct_renda_variavel,

    -- Performance
    SUM(fp.valor_mercado_posicao) AS valor_total_carteira,
    SUM(fp.valor_custo_posicao) AS valor_custo_total,
    SUM(fp.valor_lucro_prejuizo) AS lucro_prejuizo_total,
    AVG(fp.rentabilidade_posicao) AS rentabilidade_media_posicoes,

    -- Movimentação
    SUM(fp.valor_aquisicao) AS total_compras_mes,
    SUM(fp.valor_venda) AS total_vendas_mes,
    SUM(fp.valor_aquisicao - fp.valor_venda) AS fluxo_liquido_mes,

    CURRENT_TIMESTAMP AS dt_atualizacao

FROM fato_posicoes fp
JOIN dim_fundos fd ON fp.fundo_id = fd.id
JOIN dim_grupos_economicos g ON fd.grupo_economico_id = g.id
JOIN dim_categoria_ativo ca ON fp.categoria_ativo_id = ca.id
JOIN dim_tempo t ON fp.data_id = t.id
LEFT JOIN fato_patrimonio_liquido fpl ON fpl.fundo_id = fd.id AND fpl.data_id = t.id
WHERE fd.ativo = TRUE
GROUP BY
    fd.id, fd.cnpj_fundo_classe, fd.nome_fundo,
    g.id, g.nome_grupo,
    t.id, t.ano, t.mes,
    fpl.vl_patrim_liq;

CREATE UNIQUE INDEX idx_agg_fundo_carteira_pk
    ON agg_fundo_carteira(fundo_id, data_id);
CREATE INDEX idx_agg_fundo_carteira_grupo
    ON agg_fundo_carteira(grupo_id, ano, mes);
CREATE INDEX idx_agg_fundo_carteira_pl
    ON agg_fundo_carteira(vl_patrim_liq DESC NULLS LAST);

COMMENT ON MATERIALIZED VIEW agg_fundo_carteira IS
    'Resumo completo da carteira de cada fundo por mês';

-- ========================================

-- Agregação de Mercado Total por Período
CREATE MATERIALIZED VIEW IF NOT EXISTS agg_mercado_periodo AS
SELECT
    t.id AS data_id,
    t.ano,
    t.mes,
    t.mes_nome,

    -- Totais de Mercado
    COUNT(DISTINCT fp.fundo_id) AS qtd_fundos_ativos,
    SUM(fpl.vl_patrim_liq) AS pl_total_mercado,
    SUM(fp.valor_mercado_posicao) AS valor_total_posicoes,
    COUNT(*) AS qtd_posicoes_total,

    -- Por Categoria
    SUM(CASE WHEN ca.nivel1_macro = 'Renda Fixa' THEN fp.valor_mercado_posicao ELSE 0 END) AS mercado_renda_fixa,
    SUM(CASE WHEN ca.nivel1_macro = 'Renda Variável' THEN fp.valor_mercado_posicao ELSE 0 END) AS mercado_renda_variavel,
    SUM(CASE WHEN ca.nivel1_macro = 'Multimercado' THEN fp.valor_mercado_posicao ELSE 0 END) AS mercado_multimercado,

    -- Movimentação Total
    SUM(fp.valor_aquisicao) AS total_compras_mercado,
    SUM(fp.valor_venda) AS total_vendas_mercado,
    SUM(fp.valor_aquisicao - fp.valor_venda) AS fluxo_liquido_mercado,

    CURRENT_TIMESTAMP AS dt_atualizacao

FROM fato_posicoes fp
JOIN dim_categoria_ativo ca ON fp.categoria_ativo_id = ca.id
JOIN dim_tempo t ON fp.data_id = t.id
LEFT JOIN (
    SELECT data_id, SUM(vl_patrim_liq) AS vl_patrim_liq
    FROM fato_patrimonio_liquido
    GROUP BY data_id
) fpl ON fpl.data_id = t.id
WHERE t.fim_mes = TRUE
GROUP BY t.id, t.ano, t.mes, t.mes_nome, fpl.vl_patrim_liq;

CREATE UNIQUE INDEX idx_agg_mercado_periodo_pk
    ON agg_mercado_periodo(data_id);

COMMENT ON MATERIALIZED VIEW agg_mercado_periodo IS
    'Visão geral do mercado de fundos por período';

-- ========================================
-- 2. VIEWS ANALÍTICAS (SEM PRÉ-AGREGAÇÃO)
-- ========================================

-- View: Top Movimentadores do Mês
CREATE OR REPLACE VIEW v_top_movimentadores_mes AS
WITH movimentacao_mensal AS (
    SELECT
        g.id AS grupo_id,
        g.nome_grupo,
        g.tipo_grupo,
        ca.nivel1_macro AS categoria,
        t.ano,
        t.mes,
        SUM(fp.valor_aquisicao) AS total_compras,
        SUM(fp.valor_venda) AS total_vendas,
        SUM(fp.valor_aquisicao - fp.valor_venda) AS saldo_liquido
    FROM fato_posicoes fp
    JOIN dim_fundos fd ON fp.fundo_id = fd.id
    JOIN dim_grupos_economicos g ON fd.grupo_economico_id = g.id
    JOIN dim_categoria_ativo ca ON fp.categoria_ativo_id = ca.id
    JOIN dim_tempo t ON fp.data_id = t.id
    WHERE t.fim_mes = TRUE
      AND fd.ativo = TRUE
      AND g.ativo = TRUE
    GROUP BY g.id, g.nome_grupo, g.tipo_grupo, ca.nivel1_macro, t.ano, t.mes
)
SELECT
    nome_grupo,
    tipo_grupo,
    categoria,
    ano,
    mes,
    total_compras,
    total_vendas,
    saldo_liquido,
    ABS(saldo_liquido) AS volume_absoluto,
    CASE
        WHEN saldo_liquido > 0 THEN 'Comprador Líquido'
        WHEN saldo_liquido < 0 THEN 'Vendedor Líquido'
        ELSE 'Neutro'
    END AS posicao,
    ROW_NUMBER() OVER (
        PARTITION BY ano, mes, categoria
        ORDER BY ABS(saldo_liquido) DESC
    ) AS ranking_categoria
FROM movimentacao_mensal
WHERE ABS(saldo_liquido) > 0
ORDER BY ano DESC, mes DESC, ABS(saldo_liquido) DESC;

COMMENT ON VIEW v_top_movimentadores_mes IS
    'Ranking dos grupos que mais movimentaram por categoria e mês';

-- ========================================

-- View: Concentração de Mercado
CREATE OR REPLACE VIEW v_concentracao_mercado AS
WITH pl_por_grupo AS (
    SELECT
        g.id AS grupo_id,
        g.nome_grupo,
        g.tipo_grupo,
        t.ano,
        t.mes,
        SUM(fpl.vl_patrim_liq) AS pl_total
    FROM fato_patrimonio_liquido fpl
    JOIN dim_fundos f ON fpl.fundo_id = f.id
    JOIN dim_grupos_economicos g ON f.grupo_economico_id = g.id
    JOIN dim_tempo t ON fpl.data_id = t.id
    WHERE f.ativo = TRUE AND g.ativo = TRUE
    GROUP BY g.id, g.nome_grupo, g.tipo_grupo, t.ano, t.mes
),
pl_mercado AS (
    SELECT ano, mes, SUM(pl_total) AS pl_total_mercado
    FROM pl_por_grupo
    GROUP BY ano, mes
)
SELECT
    pg.nome_grupo,
    pg.tipo_grupo,
    pg.ano,
    pg.mes,
    pg.pl_total,
    pm.pl_total_mercado,
    (pg.pl_total / pm.pl_total_mercado * 100) AS percentual_mercado,
    SUM(pg.pl_total / pm.pl_total_mercado * 100) OVER (
        PARTITION BY pg.ano, pg.mes
        ORDER BY pg.pl_total DESC
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS percentual_acumulado,
    ROW_NUMBER() OVER (
        PARTITION BY pg.ano, pg.mes
        ORDER BY pg.pl_total DESC
    ) AS ranking,
    CASE
        WHEN ROW_NUMBER() OVER (PARTITION BY pg.ano, pg.mes ORDER BY pg.pl_total DESC) <= 5
        THEN 'Top 5'
        WHEN ROW_NUMBER() OVER (PARTITION BY pg.ano, pg.mes ORDER BY pg.pl_total DESC) <= 10
        THEN 'Top 6-10'
        WHEN ROW_NUMBER() OVER (PARTITION BY pg.ano, pg.mes ORDER BY pg.pl_total DESC) <= 20
        THEN 'Top 11-20'
        ELSE 'Demais'
    END AS segmento_ranking
FROM pl_por_grupo pg
JOIN pl_mercado pm ON pg.ano = pm.ano AND pg.mes = pm.mes
ORDER BY pg.ano DESC, pg.mes DESC, pg.pl_total DESC;

COMMENT ON VIEW v_concentracao_mercado IS
    'Análise de concentração de mercado por grupo econômico';

-- ========================================

-- View: Fluxo de Investimentos por Categoria
CREATE OR REPLACE VIEW v_fluxo_categoria_tempo AS
WITH fluxo_mensal AS (
    SELECT
        ca.id AS categoria_id,
        ca.nivel1_macro,
        ca.nivel2_tipo,
        t.id AS data_id,
        t.ano,
        t.mes,
        t.mes_nome,
        COUNT(DISTINCT fp.fundo_id) AS qtd_fundos,
        SUM(fp.valor_aquisicao) AS valor_aquisicoes,
        SUM(fp.valor_venda) AS valor_vendas,
        SUM(fp.valor_aquisicao - fp.valor_venda) AS fluxo_liquido,
        SUM(fp.valor_mercado_posicao) AS estoque_final
    FROM fato_posicoes fp
    JOIN dim_categoria_ativo ca ON fp.categoria_ativo_id = ca.id
    JOIN dim_tempo t ON fp.data_id = t.id
    WHERE t.fim_mes = TRUE
    GROUP BY ca.id, ca.nivel1_macro, ca.nivel2_tipo, t.id, t.ano, t.mes, t.mes_nome
)
SELECT
    nivel1_macro,
    nivel2_tipo,
    ano,
    mes,
    mes_nome,
    qtd_fundos,
    valor_aquisicoes,
    valor_vendas,
    fluxo_liquido,
    estoque_final,

    -- Estoque mês anterior
    LAG(estoque_final) OVER (
        PARTITION BY categoria_id
        ORDER BY ano, mes
    ) AS estoque_mes_anterior,

    -- Variação MoM
    (estoque_final - LAG(estoque_final) OVER (
        PARTITION BY categoria_id
        ORDER BY ano, mes
    )) AS variacao_absoluta_mom,

    -- Variação MoM %
    CASE
        WHEN LAG(estoque_final) OVER (PARTITION BY categoria_id ORDER BY ano, mes) > 0
        THEN ((estoque_final - LAG(estoque_final) OVER (
            PARTITION BY categoria_id ORDER BY ano, mes
        )) / LAG(estoque_final) OVER (
            PARTITION BY categoria_id ORDER BY ano, mes
        )) * 100
        ELSE NULL
    END AS variacao_pct_mom

FROM fluxo_mensal
ORDER BY ano DESC, mes DESC, estoque_final DESC;

COMMENT ON VIEW v_fluxo_categoria_tempo IS
    'Fluxo de investimentos e estoque por categoria ao longo do tempo';

-- ========================================

-- View: Maiores Posições por Fundo
CREATE OR REPLACE VIEW v_maiores_posicoes_fundo AS
SELECT
    fd.cnpj_fundo_classe,
    fd.nome_fundo,
    g.nome_grupo,
    ca.nivel1_macro,
    ca.nivel2_tipo,
    a.cd_ativo,
    a.ds_ativo,
    e.emissor_nome,
    fp.quantidade_posicao_final,
    fp.valor_mercado_posicao,
    fp.valor_custo_posicao,
    fp.valor_lucro_prejuizo,
    fp.percentual_pl,
    fp.rentabilidade_posicao,
    t.data_completa,
    ROW_NUMBER() OVER (
        PARTITION BY fd.id, t.id
        ORDER BY fp.valor_mercado_posicao DESC
    ) AS ranking_no_fundo
FROM fato_posicoes fp
JOIN dim_fundos fd ON fp.fundo_id = fd.id
JOIN dim_grupos_economicos g ON fd.grupo_economico_id = g.id
JOIN dim_categoria_ativo ca ON fp.categoria_ativo_id = ca.id
JOIN dim_ativos a ON fp.ativo_id = a.id
JOIN dim_emissores e ON fp.emissor_id = e.id
JOIN dim_tempo t ON fp.data_id = t.id
WHERE fd.ativo = TRUE
  AND fp.valor_mercado_posicao > 0
ORDER BY fd.id, t.data_completa DESC, fp.valor_mercado_posicao DESC;

COMMENT ON VIEW v_maiores_posicoes_fundo IS
    'Ranking das maiores posições dentro de cada fundo';

-- ========================================

-- View: Exposição a Emissores (Visão Consolidada)
CREATE OR REPLACE VIEW v_exposicao_emissores AS
SELECT
    e.emissor_nome,
    e.cpf_cnpj_emissor,
    e.pf_pj_emissor,
    e.setor_economico,
    t.ano,
    t.mes,
    COUNT(DISTINCT fp.fundo_id) AS qtd_fundos_expostos,
    COUNT(DISTINCT g.id) AS qtd_grupos_expostos,
    SUM(fp.valor_mercado_posicao) AS exposicao_total,
    AVG(fp.valor_mercado_posicao) AS exposicao_media,
    MAX(fp.valor_mercado_posicao) AS exposicao_maxima,

    -- Concentração
    SUM(CASE WHEN fp.percentual_pl > 5 THEN 1 ELSE 0 END) AS fundos_exposicao_acima_5pct,
    SUM(CASE WHEN fp.percentual_pl > 10 THEN 1 ELSE 0 END) AS fundos_exposicao_acima_10pct,

    -- Distribuição por categoria
    SUM(CASE WHEN ca.nivel1_macro = 'Renda Fixa' THEN fp.valor_mercado_posicao ELSE 0 END) AS exposicao_renda_fixa,
    SUM(CASE WHEN ca.nivel1_macro = 'Renda Variável' THEN fp.valor_mercado_posicao ELSE 0 END) AS exposicao_renda_variavel

FROM fato_posicoes fp
JOIN dim_emissores e ON fp.emissor_id = e.id
JOIN dim_fundos fd ON fp.fundo_id = fd.id
JOIN dim_grupos_economicos g ON fd.grupo_economico_id = g.id
JOIN dim_categoria_ativo ca ON fp.categoria_ativo_id = ca.id
JOIN dim_tempo t ON fp.data_id = t.id
WHERE e.ativo = TRUE
  AND fd.ativo = TRUE
  AND fp.valor_mercado_posicao > 0
GROUP BY
    e.emissor_nome, e.cpf_cnpj_emissor, e.pf_pj_emissor, e.setor_economico,
    t.ano, t.mes
ORDER BY t.ano DESC, t.mes DESC, SUM(fp.valor_mercado_posicao) DESC;

COMMENT ON VIEW v_exposicao_emissores IS
    'Análise de exposição consolidada a cada emissor';

-- ========================================
-- 3. PROCEDURES PARA REFRESH DAS MATERIALIZED VIEWS
-- ========================================

CREATE OR REPLACE PROCEDURE refresh_todas_agregacoes()
LANGUAGE plpgsql
AS $$
BEGIN
    RAISE NOTICE 'Iniciando refresh de todas as agregações...';

    RAISE NOTICE 'Refreshing agg_grupo_categoria_mes...';
    REFRESH MATERIALIZED VIEW CONCURRENTLY agg_grupo_categoria_mes;

    RAISE NOTICE 'Refreshing agg_emissor_tempo...';
    REFRESH MATERIALIZED VIEW CONCURRENTLY agg_emissor_tempo;

    RAISE NOTICE 'Refreshing agg_fundo_carteira...';
    REFRESH MATERIALIZED VIEW CONCURRENTLY agg_fundo_carteira;

    RAISE NOTICE 'Refreshing agg_mercado_periodo...';
    REFRESH MATERIALIZED VIEW CONCURRENTLY agg_mercado_periodo;

    RAISE NOTICE 'Refresh completo!';
END;
$$;

COMMENT ON PROCEDURE refresh_todas_agregacoes IS
    'Atualiza todas as materialized views de agregação';

-- ========================================
-- FIM DA MIGRAÇÃO 002
-- ========================================
