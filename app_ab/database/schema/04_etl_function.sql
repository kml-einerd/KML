-- =====================================================================
-- FUNÇÃO ETL COMPLETA - Popular Tabelas Derivadas
-- Calcula top_movers e fresh_bets baseado nos dados reais
-- =====================================================================

CREATE OR REPLACE FUNCTION populate_dashboard_data(
    p_target_date DATE DEFAULT CURRENT_DATE
)
RETURNS TABLE (
    status TEXT,
    top_movers_inserted INTEGER,
    fresh_bets_inserted INTEGER,
    execution_time_ms INTEGER
) AS $$
DECLARE
    v_start_time TIMESTAMP;
    v_top_movers_count INTEGER := 0;
    v_fresh_bets_count INTEGER := 0;
    v_prev_month_start DATE;
    v_prev_month_end DATE;
    v_target_month_start DATE;
    v_target_month_end DATE;
BEGIN
    v_start_time := clock_timestamp();

    -- Calcular períodos
    v_target_month_start := DATE_TRUNC('month', p_target_date)::DATE;
    v_target_month_end := (v_target_month_start + INTERVAL '1 month')::DATE;
    v_prev_month_start := (v_target_month_start - INTERVAL '1 month')::DATE;
    v_prev_month_end := v_target_month_start;

    RAISE NOTICE 'Processando período: % a %', v_target_month_start, v_target_month_end;

    -- =====================================================================
    -- 1. POPULAR TOP_MOVERS
    -- =====================================================================
    RAISE NOTICE 'Calculando Top Movers...';

    -- Limpar dados existentes do mês
    DELETE FROM public.top_movers
    WHERE data_competencia >= v_target_month_start
      AND data_competencia < v_target_month_end;

    -- Calcular variações comparando mês atual vs mês anterior
    WITH posicoes_mes_atual AS (
        SELECT
            fundo_id,
            ativo_id,
            data_competencia,
            SUM(qtd_posicao_final) AS quantidade,
            SUM(valor_mercado_final) AS valor_mercado
        FROM public.posicoes
        WHERE data_competencia >= v_target_month_start
          AND data_competencia < v_target_month_end
          AND ativo_id IS NOT NULL
          AND valor_mercado_final > 0
        GROUP BY fundo_id, ativo_id, data_competencia
    ),
    posicoes_mes_anterior AS (
        SELECT
            fundo_id,
            ativo_id,
            SUM(qtd_posicao_final) AS quantidade,
            SUM(valor_mercado_final) AS valor_mercado
        FROM public.posicoes
        WHERE data_competencia >= v_prev_month_start
          AND data_competencia < v_prev_month_end
          AND ativo_id IS NOT NULL
        GROUP BY fundo_id, ativo_id
    ),
    variacoes AS (
        SELECT
            COALESCE(curr.fundo_id, prev.fundo_id) AS fundo_id,
            COALESCE(curr.ativo_id, prev.ativo_id) AS ativo_id,
            COALESCE(curr.data_competencia, v_target_month_start) AS data_competencia,
            COALESCE(prev.quantidade, 0) AS prev_quantity,
            COALESCE(curr.quantidade, 0) AS curr_quantity,
            COALESCE(prev.valor_mercado, 0) AS prev_value,
            COALESCE(curr.valor_mercado, 0) AS curr_value,
            (COALESCE(curr.valor_mercado, 0) - COALESCE(prev.valor_mercado, 0)) AS change_absolute,
            CASE
                WHEN COALESCE(prev.valor_mercado, 0) = 0 THEN NULL
                ELSE ((COALESCE(curr.valor_mercado, 0) - COALESCE(prev.valor_mercado, 0)) / NULLIF(prev.valor_mercado, 0))
            END AS pct_change,
            CASE
                WHEN (COALESCE(curr.valor_mercado, 0) - COALESCE(prev.valor_mercado, 0)) > 1000 THEN 'compra'
                WHEN (COALESCE(curr.valor_mercado, 0) - COALESCE(prev.valor_mercado, 0)) < -1000 THEN 'venda'
                ELSE NULL
            END AS tipo_movimento
        FROM posicoes_mes_atual curr
        FULL OUTER JOIN posicoes_mes_anterior prev
            ON prev.fundo_id = curr.fundo_id
            AND prev.ativo_id = curr.ativo_id
        WHERE ABS(COALESCE(curr.valor_mercado, 0) - COALESCE(prev.valor_mercado, 0)) > 1000
    )
    INSERT INTO public.top_movers (
        fundo_id,
        ativo_id,
        data_snapshot,
        data_competencia,
        prev_quantity,
        curr_quantity,
        prev_value,
        curr_value,
        change_absolute,
        pct_change,
        tipo_movimento
    )
    SELECT
        fundo_id,
        ativo_id,
        data_competencia,
        data_competencia,
        prev_quantity,
        curr_quantity,
        prev_value,
        curr_value,
        change_absolute,
        pct_change,
        tipo_movimento
    FROM variacoes
    WHERE tipo_movimento IS NOT NULL;

    GET DIAGNOSTICS v_top_movers_count = ROW_COUNT;
    RAISE NOTICE '✓ Top Movers inseridos: %', v_top_movers_count;

    -- =====================================================================
    -- 2. POPULAR FRESH_BETS
    -- =====================================================================
    RAISE NOTICE 'Calculando Fresh Bets...';

    -- Limpar dados existentes do mês
    DELETE FROM public.fresh_bets
    WHERE data_competencia >= v_target_month_start
      AND data_competencia < v_target_month_end;

    -- Detectar ativos com aumento significativo no número de fundos investidos
    WITH fundos_por_ativo_atual AS (
        SELECT
            ativo_id,
            COUNT(DISTINCT fundo_id) AS num_fundos_atual,
            SUM(valor_mercado_final) AS valor_total_atual
        FROM public.posicoes
        WHERE data_competencia >= v_target_month_start
          AND data_competencia < v_target_month_end
          AND ativo_id IS NOT NULL
          AND valor_mercado_final > 0
        GROUP BY ativo_id
    ),
    fundos_por_ativo_anterior AS (
        SELECT
            ativo_id,
            COUNT(DISTINCT fundo_id) AS num_fundos_anterior,
            SUM(valor_mercado_final) AS valor_total_anterior
        FROM public.posicoes
        WHERE data_competencia >= v_prev_month_start
          AND data_competencia < v_prev_month_end
          AND ativo_id IS NOT NULL
          AND valor_mercado_final > 0
        GROUP BY ativo_id
    ),
    fresh_candidates AS (
        SELECT
            COALESCE(curr.ativo_id, prev.ativo_id) AS ativo_id,
            COALESCE(curr.num_fundos_atual, 0) AS num_fundos_atual,
            COALESCE(prev.num_fundos_anterior, 0) AS num_fundos_anterior,
            (COALESCE(curr.num_fundos_atual, 0) - COALESCE(prev.num_fundos_anterior, 0)) AS aumento_fundos,
            COALESCE(curr.valor_total_atual, 0) AS valor_total_atual,
            COALESCE(prev.valor_total_anterior, 0) AS valor_total_anterior
        FROM fundos_por_ativo_atual curr
        FULL OUTER JOIN fundos_por_ativo_anterior prev
            ON prev.ativo_id = curr.ativo_id
        WHERE (COALESCE(curr.num_fundos_atual, 0) - COALESCE(prev.num_fundos_anterior, 0)) >= 3
           OR (COALESCE(curr.num_fundos_atual, 0) > 0 AND COALESCE(prev.num_fundos_anterior, 0) = 0 AND COALESCE(curr.num_fundos_atual, 0) >= 2)
    )
    INSERT INTO public.fresh_bets (
        fundo_id,
        ativo_id,
        data_competencia,
        first_seen,
        last_seen,
        qtd_fundos,
        valor_total_investido,
        quantity,
        value
    )
    SELECT
        (SELECT id FROM public.fundos LIMIT 1) AS fundo_id, -- Placeholder
        fc.ativo_id,
        v_target_month_start,
        v_target_month_start,
        v_target_month_end - INTERVAL '1 day',
        fc.num_fundos_atual,
        fc.valor_total_atual,
        fc.num_fundos_atual,
        fc.valor_total_atual
    FROM fresh_candidates fc
    WHERE fc.ativo_id IS NOT NULL;

    GET DIAGNOSTICS v_fresh_bets_count = ROW_COUNT;
    RAISE NOTICE '✓ Fresh Bets inseridos: %', v_fresh_bets_count;

    -- =====================================================================
    -- 3. RETORNAR RESULTADO
    -- =====================================================================
    RETURN QUERY
    SELECT
        'success'::TEXT AS status,
        v_top_movers_count AS top_movers_inserted,
        v_fresh_bets_count AS fresh_bets_inserted,
        EXTRACT(MILLISECONDS FROM (clock_timestamp() - v_start_time))::INTEGER AS execution_time_ms;

EXCEPTION
    WHEN OTHERS THEN
        RAISE WARNING 'Erro no ETL: %', SQLERRM;
        RETURN QUERY
        SELECT
            'error'::TEXT AS status,
            0 AS top_movers_inserted,
            0 AS fresh_bets_inserted,
            EXTRACT(MILLISECONDS FROM (clock_timestamp() - v_start_time))::INTEGER AS execution_time_ms;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION populate_dashboard_data IS 'ETL para popular top_movers e fresh_bets com dados reais';

-- =====================================================================
-- FUNÇÃO HELPER: Popular múltiplos meses
-- =====================================================================

CREATE OR REPLACE FUNCTION populate_all_months()
RETURNS TABLE (
    mes DATE,
    status TEXT,
    top_movers INTEGER,
    fresh_bets INTEGER
) AS $$
DECLARE
    v_month RECORD;
BEGIN
    -- Para cada mês com dados
    FOR v_month IN
        SELECT DISTINCT DATE_TRUNC('month', data_competencia)::DATE AS mes
        FROM public.posicoes
        WHERE data_competencia IS NOT NULL
          AND ativo_id IS NOT NULL
        ORDER BY mes DESC
        LIMIT 12 -- Últimos 12 meses
    LOOP
        RAISE NOTICE 'Processando mês: %', v_month.mes;

        RETURN QUERY
        SELECT
            v_month.mes,
            r.status,
            r.top_movers_inserted,
            r.fresh_bets_inserted
        FROM populate_dashboard_data(v_month.mes + INTERVAL '15 days') r;
    END LOOP;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION populate_all_months IS 'Popula dados derivados para todos os meses disponíveis';

-- =====================================================================
-- FIM DAS FUNÇÕES ETL
-- =====================================================================
