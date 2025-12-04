-- =====================================================================
-- SCHEMA COMPLETO PARA DASHBOARD - Radar Institucional
-- Implementa TODAS as necessidades do DESIGN_INTERFACE.md
-- =====================================================================

BEGIN;

-- =====================================================================
-- 1. ADICIONAR COLUNAS FALTANTES EM top_movers
-- =====================================================================

DO $$
BEGIN
    -- Adicionar data_competencia se não existir
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'top_movers' AND column_name = 'data_competencia'
    ) THEN
        ALTER TABLE public.top_movers
        ADD COLUMN data_competencia DATE;

        -- Copiar valores de data_snapshot para data_competencia
        UPDATE public.top_movers
        SET data_competencia = data_snapshot
        WHERE data_competencia IS NULL;
    END IF;

    -- Adicionar variacao_valor como alias computed
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'top_movers' AND column_name = 'variacao_valor'
    ) THEN
        ALTER TABLE public.top_movers
        ADD COLUMN variacao_valor NUMERIC(18, 2)
        GENERATED ALWAYS AS (change_absolute) STORED;
    END IF;

    -- Adicionar variacao_qtd como alias computed
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'top_movers' AND column_name = 'variacao_qtd'
    ) THEN
        ALTER TABLE public.top_movers
        ADD COLUMN variacao_qtd NUMERIC(18, 6)
        GENERATED ALWAYS AS (curr_quantity - prev_quantity) STORED;
    END IF;
END $$;

-- =====================================================================
-- 2. ADICIONAR COLUNAS FALTANTES EM fresh_bets
-- =====================================================================

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'fresh_bets' AND column_name = 'data_competencia'
    ) THEN
        ALTER TABLE public.fresh_bets
        ADD COLUMN data_competencia DATE;

        -- Copiar valor de first_seen se vazio
        UPDATE public.fresh_bets
        SET data_competencia = first_seen
        WHERE data_competencia IS NULL;
    END IF;
END $$;

-- =====================================================================
-- 3. CRIAR ÍNDICES OTIMIZADOS PARA PERFORMANCE
-- =====================================================================

-- Índices para queries do dashboard
CREATE INDEX IF NOT EXISTS idx_posicoes_fundo_data_ativo
    ON public.posicoes(fundo_id, data_competencia DESC, ativo_id)
    WHERE ativo_id IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_posicoes_data_ativo
    ON public.posicoes(data_competencia DESC, ativo_id)
    WHERE ativo_id IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_top_movers_data_tipo
    ON public.top_movers(data_competencia DESC, tipo_movimento);

CREATE INDEX IF NOT EXISTS idx_fresh_bets_data
    ON public.fresh_bets(data_competencia DESC, qtd_fundos DESC);

CREATE INDEX IF NOT EXISTS idx_patrimonio_liquido_data_valor
    ON public.patrimonio_liquido(data_competencia DESC, valor_pl DESC);

-- =====================================================================
-- 4. VIEWS OTIMIZADAS PARA O DASHBOARD
-- =====================================================================

-- View 1: Meses Disponíveis (para seletor de mês)
CREATE OR REPLACE VIEW v_meses_disponiveis AS
SELECT DISTINCT
    DATE_TRUNC('month', data_competencia)::DATE AS mes,
    TO_CHAR(data_competencia, 'Mon/YYYY') AS mes_label,
    TO_CHAR(data_competencia, 'YYYY-MM') AS mes_value
FROM (
    SELECT data_competencia FROM public.patrimonio_liquido
    UNION
    SELECT data_competencia FROM public.posicoes
) t
WHERE data_competencia IS NOT NULL
ORDER BY mes DESC;

COMMENT ON VIEW v_meses_disponiveis IS 'Meses com dados disponíveis para seletor de período';

-- View 2: Resumo Mensal (para header/métricas)
CREATE OR REPLACE VIEW v_resumo_mensal AS
SELECT
    DATE_TRUNC('month', pl.data_competencia)::DATE AS mes,
    COUNT(DISTINCT pl.fundo_id) AS num_fundos,
    SUM(pl.valor_pl) AS total_pl,
    AVG(pl.valor_pl) AS media_pl,
    COUNT(DISTINCT p.ativo_id) AS num_ativos_distintos
FROM public.patrimonio_liquido pl
LEFT JOIN public.posicoes p
    ON p.fundo_id = pl.fundo_id
    AND DATE_TRUNC('month', p.data_competencia) = DATE_TRUNC('month', pl.data_competencia)
WHERE pl.data_competencia IS NOT NULL
GROUP BY DATE_TRUNC('month', pl.data_competencia);

COMMENT ON VIEW v_resumo_mensal IS 'Resumo agregado por mês para métricas do header';

-- View 3: Top Compradores (para card do dashboard)
CREATE OR REPLACE VIEW v_top_compradores AS
SELECT
    f.id AS fundo_id,
    f.nome_fundo,
    f.gestor,
    tm.data_competencia,
    SUM(tm.change_absolute) AS total_compras,
    SUM(tm.curr_quantity - tm.prev_quantity) AS total_qtd,
    COUNT(*) AS num_operacoes,
    pl.valor_pl
FROM public.top_movers tm
JOIN public.fundos f ON f.id = tm.fundo_id
LEFT JOIN public.patrimonio_liquido pl
    ON pl.fundo_id = f.id
    AND pl.data_competencia = tm.data_competencia
WHERE tm.tipo_movimento = 'compra'
GROUP BY f.id, f.nome_fundo, f.gestor, tm.data_competencia, pl.valor_pl
ORDER BY tm.data_competencia DESC, total_compras DESC;

COMMENT ON VIEW v_top_compradores IS 'Fundos com maiores compras (Top Movers positivos)';

-- View 4: Top Vendedores (para card do dashboard)
CREATE OR REPLACE VIEW v_top_vendedores AS
SELECT
    f.id AS fundo_id,
    f.nome_fundo,
    f.gestor,
    tm.data_competencia,
    SUM(ABS(tm.change_absolute)) AS total_vendas,
    SUM(ABS(tm.curr_quantity - tm.prev_quantity)) AS total_qtd,
    COUNT(*) AS num_operacoes,
    pl.valor_pl
FROM public.top_movers tm
JOIN public.fundos f ON f.id = tm.fundo_id
LEFT JOIN public.patrimonio_liquido pl
    ON pl.fundo_id = f.id
    AND pl.data_competencia = tm.data_competencia
WHERE tm.tipo_movimento = 'venda'
GROUP BY f.id, f.nome_fundo, f.gestor, tm.data_competencia, pl.valor_pl
ORDER BY tm.data_competencia DESC, total_vendas DESC;

COMMENT ON VIEW v_top_vendedores IS 'Fundos com maiores vendas (Top Movers negativos)';

-- View 5: Fresh Bets com Detalhes (para card Fresh Bets)
CREATE OR REPLACE VIEW v_fresh_bets_detalhado AS
SELECT
    fb.id,
    fb.ativo_id,
    COALESCE(a.codigo, a.descricao) AS ticker,
    a.tipo_ativo,
    e.nome_emissor,
    fb.data_competencia,
    fb.qtd_fundos,
    fb.valor_total_investido,
    fb.first_seen,
    fb.last_seen,
    -- Calcular percentual médio alocado
    (SELECT AVG(p.percentual_carteira)
     FROM public.posicoes p
     WHERE p.ativo_id = fb.ativo_id
       AND p.data_competencia >= fb.first_seen
       AND p.percentual_carteira IS NOT NULL) AS pct_medio_alocacao
FROM public.fresh_bets fb
LEFT JOIN public.ativos a ON a.id = fb.ativo_id
LEFT JOIN public.emissores e ON e.id = a.emissor_id
ORDER BY fb.data_competencia DESC, fb.qtd_fundos DESC, fb.valor_total_investido DESC;

COMMENT ON VIEW v_fresh_bets_detalhado IS 'Fresh Bets com informações completas do ativo';

-- View 6: Ativos Mais Populares (para gráfico de barras)
CREATE OR REPLACE VIEW v_ativos_populares AS
SELECT
    a.id AS ativo_id,
    COALESCE(a.codigo, a.descricao) AS ticker,
    a.tipo_ativo,
    e.nome_emissor,
    p.data_competencia,
    COUNT(DISTINCT p.fundo_id) AS num_fundos,
    SUM(p.valor_mercado_final) AS total_valor_mercado,
    AVG(p.percentual_carteira) AS pct_medio_carteira
FROM public.posicoes p
JOIN public.ativos a ON a.id = p.ativo_id
LEFT JOIN public.emissores e ON e.id = a.emissor_id
WHERE p.ativo_id IS NOT NULL
  AND p.valor_mercado_final > 0
GROUP BY a.id, ticker, a.tipo_ativo, e.nome_emissor, p.data_competencia
ORDER BY p.data_competencia DESC, num_fundos DESC;

COMMENT ON VIEW v_ativos_populares IS 'Ativos mais populares (maior número de fundos investidos)';

-- View 7: Detalhes do Fundo (para card expandido)
CREATE OR REPLACE VIEW v_fundo_detalhes AS
SELECT
    f.id AS fundo_id,
    f.nome_fundo,
    f.cnpj,
    f.gestor,
    f.administrador,
    f.tipo_fundo,
    f.classe,
    f.situacao,
    pl.data_competencia,
    pl.valor_pl,
    pl.num_cotistas,
    pl.valor_cota,
    pl.rentabilidade_mes,
    -- Top 5 ativos do fundo
    (SELECT JSON_AGG(top_ativos ORDER BY valor DESC)
     FROM (
         SELECT
             COALESCE(a.codigo, a.descricao) AS ticker,
             p.valor_mercado_final AS valor,
             p.percentual_carteira AS pct
         FROM public.posicoes p
         JOIN public.ativos a ON a.id = p.ativo_id
         WHERE p.fundo_id = f.id
           AND p.data_competencia = pl.data_competencia
           AND p.ativo_id IS NOT NULL
         ORDER BY p.valor_mercado_final DESC
         LIMIT 5
     ) top_ativos) AS top_ativos
FROM public.fundos f
LEFT JOIN public.patrimonio_liquido pl ON pl.fundo_id = f.id
WHERE f.situacao = 'ATIVO'
ORDER BY pl.data_competencia DESC, pl.valor_pl DESC;

COMMENT ON VIEW v_fundo_detalhes IS 'Detalhes completos do fundo com top ativos';

-- =====================================================================
-- 5. FUNÇÕES AUXILIARES PARA O DASHBOARD
-- =====================================================================

-- Função: Obter participantes de um Fresh Bet
CREATE OR REPLACE FUNCTION get_fresh_bet_participantes(
    p_ativo_id UUID,
    p_data_competencia DATE
)
RETURNS TABLE (
    fundo_id UUID,
    nome_fundo TEXT,
    valor_investido NUMERIC,
    pct_pl NUMERIC,
    percentual_carteira NUMERIC
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        f.id AS fundo_id,
        f.nome_fundo,
        p.valor_mercado_final AS valor_investido,
        CASE
            WHEN pl.valor_pl > 0 THEN (p.valor_mercado_final / pl.valor_pl * 100)
            ELSE NULL
        END AS pct_pl,
        p.percentual_carteira
    FROM public.posicoes p
    JOIN public.fundos f ON f.id = p.fundo_id
    LEFT JOIN public.patrimonio_liquido pl
        ON pl.fundo_id = f.id
        AND pl.data_competencia = p.data_competencia
    WHERE p.ativo_id = p_ativo_id
      AND p.data_competencia = p_data_competencia
      AND p.valor_mercado_final > 0
    ORDER BY p.valor_mercado_final DESC;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION get_fresh_bet_participantes IS 'Lista fundos que entraram em um Fresh Bet específico';

-- Função: Verificar se há dados para um mês
CREATE OR REPLACE FUNCTION check_data_availability(
    p_month_start DATE,
    p_month_end DATE
)
RETURNS TABLE (
    has_positions BOOLEAN,
    has_patrimonio BOOLEAN,
    num_fundos INTEGER,
    num_posicoes INTEGER
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        EXISTS(
            SELECT 1 FROM public.posicoes
            WHERE data_competencia >= p_month_start
              AND data_competencia < p_month_end
            LIMIT 1
        ) AS has_positions,
        EXISTS(
            SELECT 1 FROM public.patrimonio_liquido
            WHERE data_competencia >= p_month_start
              AND data_competencia < p_month_end
            LIMIT 1
        ) AS has_patrimonio,
        (SELECT COUNT(DISTINCT fundo_id)
         FROM public.patrimonio_liquido
         WHERE data_competencia >= p_month_start
           AND data_competencia < p_month_end
        )::INTEGER AS num_fundos,
        (SELECT COUNT(*)
         FROM public.posicoes
         WHERE data_competencia >= p_month_start
           AND data_competencia < p_month_end
           AND ativo_id IS NOT NULL
        )::INTEGER AS num_posicoes;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION check_data_availability IS 'Verifica disponibilidade de dados para um período';

COMMIT;

-- =====================================================================
-- FIM DO SCHEMA COMPLETO PARA DASHBOARD
-- =====================================================================
