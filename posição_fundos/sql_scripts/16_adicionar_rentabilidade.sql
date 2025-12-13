-- ====================================================================
-- ADICIONAR MÉTRICAS DE RENTABILIDADE AO RANKING TOP 100
-- Performance das decisões de investimento dos grupos
-- ====================================================================

-- Adicionar colunas de rentabilidade na tabela ranking
ALTER TABLE ranking_top100_grupos
ADD COLUMN IF NOT EXISTS rentabilidade_media_acoes DECIMAL(8,4),
ADD COLUMN IF NOT EXISTS lucro_prejuizo_total DECIMAL(18,2),
ADD COLUMN IF NOT EXISTS rentabilidade_pl DECIMAL(8,4),
ADD COLUMN IF NOT EXISTS performance_vs_ibov DECIMAL(8,4),
ADD COLUMN IF NOT EXISTS melhor_acao_ticker VARCHAR(10),
ADD COLUMN IF NOT EXISTS melhor_acao_rentabilidade DECIMAL(8,4),
ADD COLUMN IF NOT EXISTS pior_acao_ticker VARCHAR(10),
ADD COLUMN IF NOT EXISTS pior_acao_rentabilidade DECIMAL(8,4);

-- Comentários
COMMENT ON COLUMN ranking_top100_grupos.rentabilidade_media_acoes IS 'Rentabilidade média de todas as posições em ações (%)';
COMMENT ON COLUMN ranking_top100_grupos.lucro_prejuizo_total IS 'Lucro ou prejuízo total em ações (valor_mercado - valor_custo)';
COMMENT ON COLUMN ranking_top100_grupos.rentabilidade_pl IS 'Rentabilidade como % do patrimônio líquido (lucro/PL * 100)';
COMMENT ON COLUMN ranking_top100_grupos.performance_vs_ibov IS 'Performance relativa ao IBOVESPA (%)';
COMMENT ON COLUMN ranking_top100_grupos.melhor_acao_ticker IS 'Ação com melhor rentabilidade na carteira';
COMMENT ON COLUMN ranking_top100_grupos.melhor_acao_rentabilidade IS 'Rentabilidade da melhor ação (%)';
COMMENT ON COLUMN ranking_top100_grupos.pior_acao_ticker IS 'Ação com pior rentabilidade na carteira';
COMMENT ON COLUMN ranking_top100_grupos.pior_acao_rentabilidade IS 'Rentabilidade da pior ação (%)';


-- ====================================================================
-- ATUALIZAR FUNÇÃO DE RANKING COM RENTABILIDADE
-- ====================================================================

CREATE OR REPLACE FUNCTION atualizar_ranking_top100_v2(
    p_ano INTEGER,
    p_mes INTEGER
) RETURNS TABLE(
    grupos_atualizados INTEGER,
    data_referencia DATE
) AS $$
DECLARE
    v_data_ref DATE;
    v_grupos_count INTEGER;
BEGIN
    v_data_ref := (p_ano || '-' || p_mes || '-01')::DATE + INTERVAL '1 month' - INTERVAL '1 day';

    DELETE FROM ranking_top100_grupos WHERE ano = p_ano AND mes = p_mes;

    INSERT INTO ranking_top100_grupos (
        ano, mes, data_referencia, grupo_id, nome_grupo, tipo_grupo,
        patrimonio_liquido_total, volume_compras, volume_vendas,
        qtd_fundos, qtd_posicoes_acoes, valor_total_acoes,
        ranking_patrimonio, ranking_volume_movimentado,
        tendencia_mes, percentual_pl_em_acoes,
        -- NOVOS CAMPOS DE RENTABILIDADE
        rentabilidade_media_acoes, lucro_prejuizo_total, rentabilidade_pl,
        melhor_acao_ticker, melhor_acao_rentabilidade,
        pior_acao_ticker, pior_acao_rentabilidade
    )
    WITH grupo_metricas AS (
        SELECT
            g.id AS grupo_id,
            g.nome_grupo,
            g.tipo_grupo,

            -- PL Total
            SUM(pl.valor_pl) AS pl_total,

            -- Movimentações em Ações
            SUM(CASE WHEN ca.nivel1_macro = 'Renda Variável' THEN fp.valor_aquisicao ELSE 0 END) AS compras,
            SUM(CASE WHEN ca.nivel1_macro = 'Renda Variável' THEN fp.valor_venda ELSE 0 END) AS vendas,

            -- Métricas
            COUNT(DISTINCT f.id) AS total_fundos,
            COUNT(CASE WHEN ca.nivel1_macro = 'Renda Variável' THEN 1 END) AS posicoes_acoes,
            SUM(CASE WHEN ca.nivel1_macro = 'Renda Variável' THEN fp.valor_mercado_posicao ELSE 0 END) AS valor_acoes,

            -- RENTABILIDADE
            AVG(CASE WHEN ca.nivel1_macro = 'Renda Variável' AND fp.valor_custo_posicao > 0
                THEN ((fp.valor_mercado_posicao / fp.valor_custo_posicao - 1) * 100)
                ELSE NULL END) AS rentabilidade_media,
            SUM(CASE WHEN ca.nivel1_macro = 'Renda Variável' THEN fp.valor_lucro_prejuizo ELSE 0 END) AS lucro_prejuizo,

            -- Melhor e Pior Ação (subquery)
            (
                SELECT acoes.ticker
                FROM fato_posicoes fp2
                JOIN dim_ativos a2 ON fp2.ativo_id = a2.id
                JOIN dim_acoes_b3 acoes ON a2.id = acoes.ativo_id
                JOIN dim_fundos f2 ON fp2.fundo_id = f2.id
                WHERE f2.grupo_economico_id = g.id
                  AND fp2.data_id = t.id
                  AND fp2.valor_custo_posicao > 0
                ORDER BY fp2.rentabilidade_posicao DESC NULLS LAST
                LIMIT 1
            ) AS melhor_ticker,
            (
                SELECT MAX(fp2.rentabilidade_posicao)
                FROM fato_posicoes fp2
                JOIN dim_fundos f2 ON fp2.fundo_id = f2.id
                WHERE f2.grupo_economico_id = g.id
                  AND fp2.data_id = t.id
            ) AS melhor_rent,
            (
                SELECT acoes.ticker
                FROM fato_posicoes fp2
                JOIN dim_ativos a2 ON fp2.ativo_id = a2.id
                JOIN dim_acoes_b3 acoes ON a2.id = acoes.ativo_id
                JOIN dim_fundos f2 ON fp2.fundo_id = f2.id
                WHERE f2.grupo_economico_id = g.id
                  AND fp2.data_id = t.id
                  AND fp2.valor_custo_posicao > 0
                ORDER BY fp2.rentabilidade_posicao ASC NULLS LAST
                LIMIT 1
            ) AS pior_ticker,
            (
                SELECT MIN(fp2.rentabilidade_posicao)
                FROM fato_posicoes fp2
                JOIN dim_fundos f2 ON fp2.fundo_id = f2.id
                WHERE f2.grupo_economico_id = g.id
                  AND fp2.data_id = t.id
            ) AS pior_rent

        FROM dim_grupos_economicos g
        LEFT JOIN dim_fundos f ON g.id = f.grupo_economico_id AND f.ativo = TRUE
        LEFT JOIN dim_patrimonio_liquido pl ON f.id = pl.fundo_id
        LEFT JOIN dim_tempo t ON pl.data_id = t.id
        LEFT JOIN fato_posicoes fp ON f.id = fp.fundo_id AND pl.data_id = fp.data_id
        LEFT JOIN dim_categoria_ativo ca ON fp.categoria_ativo_id = ca.id
        WHERE t.ano = p_ano AND t.mes = p_mes AND t.fim_mes = TRUE
        GROUP BY g.id, g.nome_grupo, g.tipo_grupo, t.id
        HAVING SUM(pl.valor_pl) > 0
    ),
    ranked AS (
        SELECT
            *,
            ROW_NUMBER() OVER (ORDER BY pl_total DESC) AS rank_pl,
            ROW_NUMBER() OVER (ORDER BY (compras + vendas) DESC) AS rank_volume
        FROM grupo_metricas
    )
    SELECT
        p_ano,
        p_mes,
        v_data_ref,
        grupo_id,
        nome_grupo,
        tipo_grupo,
        pl_total,
        compras,
        vendas,
        total_fundos,
        posicoes_acoes,
        valor_acoes,
        rank_pl::INTEGER,
        rank_volume::INTEGER,
        CASE
            WHEN (compras - vendas) > 1000000 THEN 'COMPRADOR'
            WHEN (compras - vendas) < -1000000 THEN 'VENDEDOR'
            ELSE 'NEUTRO'
        END,
        CASE WHEN pl_total > 0 THEN (valor_acoes / pl_total * 100) ELSE 0 END,
        -- RENTABILIDADE
        rentabilidade_media,
        lucro_prejuizo,
        CASE WHEN pl_total > 0 THEN (lucro_prejuizo / pl_total * 100) ELSE 0 END,
        melhor_ticker,
        melhor_rent,
        pior_ticker,
        pior_rent
    FROM ranked
    WHERE rank_pl <= 100
    ORDER BY rank_pl;

    GET DIAGNOSTICS v_grupos_count = ROW_COUNT;

    RETURN QUERY SELECT v_grupos_count, v_data_ref;
END;
$$ LANGUAGE plpgsql;


-- ====================================================================
-- VIEW: Dashboard com Rentabilidade
-- ====================================================================

CREATE OR REPLACE VIEW v_dashboard_top100_rentabilidade AS
SELECT
    r.ranking_patrimonio,
    r.nome_grupo,
    r.tipo_grupo,

    -- Patrimônio
    r.patrimonio_liquido_total / 1000000000.0 AS pl_bilhoes,
    r.valor_total_acoes / 1000000000.0 AS acoes_bilhoes,
    r.percentual_pl_em_acoes AS perc_acoes,

    -- Movimentação
    r.volume_total_movimentado / 1000000.0 AS volume_movimentado_milhoes,
    r.fluxo_liquido / 1000000.0 AS fluxo_liquido_milhoes,
    r.tendencia_mes,

    -- RENTABILIDADE
    ROUND(r.rentabilidade_media_acoes, 2) AS rentabilidade_media_pct,
    r.lucro_prejuizo_total / 1000000.0 AS lucro_prejuizo_milhoes,
    ROUND(r.rentabilidade_pl, 2) AS rentabilidade_pl_pct,

    -- Melhor e Pior
    r.melhor_acao_ticker,
    ROUND(r.melhor_acao_rentabilidade, 2) AS melhor_acao_pct,
    r.pior_acao_ticker,
    ROUND(r.pior_acao_rentabilidade, 2) AS pior_acao_pct,

    -- Classificação de Performance
    CASE
        WHEN r.rentabilidade_media_acoes > 10 THEN 'EXCELENTE'
        WHEN r.rentabilidade_media_acoes > 5 THEN 'BOA'
        WHEN r.rentabilidade_media_acoes > 0 THEN 'POSITIVA'
        WHEN r.rentabilidade_media_acoes > -5 THEN 'NEGATIVA'
        ELSE 'RUIM'
    END AS classificacao_performance,

    -- Métricas
    r.qtd_fundos,
    r.qtd_posicoes_acoes,

    -- Período
    r.ano,
    r.mes

FROM ranking_top100_grupos r
WHERE (ano, mes) = (
    SELECT ano, mes FROM ranking_top100_grupos
    ORDER BY ano DESC, mes DESC LIMIT 1
)
ORDER BY r.ranking_patrimonio;

COMMENT ON VIEW v_dashboard_top100_rentabilidade IS 'Dashboard top 100 com métricas de rentabilidade';


-- ====================================================================
-- VIEW: Ranking por Rentabilidade
-- ====================================================================

CREATE OR REPLACE VIEW v_ranking_por_rentabilidade AS
SELECT
    ROW_NUMBER() OVER (ORDER BY rentabilidade_media_acoes DESC NULLS LAST) AS ranking_rentabilidade,
    nome_grupo,
    tipo_grupo,
    ROUND(rentabilidade_media_acoes, 2) AS rentabilidade_pct,
    lucro_prejuizo_total / 1000000.0 AS lucro_milhoes,
    valor_total_acoes / 1000000000.0 AS acoes_bilhoes,
    melhor_acao_ticker,
    ROUND(melhor_acao_rentabilidade, 2) AS melhor_acao_pct,
    ranking_patrimonio,
    ano,
    mes
FROM ranking_top100_grupos
WHERE (ano, mes) = (
    SELECT ano, mes FROM ranking_top100_grupos
    ORDER BY ano DESC, mes DESC LIMIT 1
)
AND rentabilidade_media_acoes IS NOT NULL
ORDER BY rentabilidade_media_acoes DESC;

COMMENT ON VIEW v_ranking_por_rentabilidade IS 'Ranking dos grupos por rentabilidade das ações';


-- ====================================================================
-- VIEW: Melhores Decisões (Top Ações por Grupo)
-- ====================================================================

CREATE OR REPLACE VIEW v_melhores_decisoes_grupos AS
SELECT
    ranking_patrimonio,
    nome_grupo,
    melhor_acao_ticker AS ticker,
    ROUND(melhor_acao_rentabilidade, 2) AS rentabilidade_pct,
    'MELHOR' AS tipo_decisao,
    ano,
    mes
FROM ranking_top100_grupos
WHERE melhor_acao_ticker IS NOT NULL
  AND (ano, mes) = (
      SELECT ano, mes FROM ranking_top100_grupos
      ORDER BY ano DESC, mes DESC LIMIT 1
  )
ORDER BY melhor_acao_rentabilidade DESC NULLS LAST
LIMIT 20;

COMMENT ON VIEW v_melhores_decisoes_grupos IS 'Top 20 melhores decisões de investimento dos grupos';
