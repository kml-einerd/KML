-- ====================================================================
-- RANKING TOP 100 GRUPOS ECONÔMICOS
-- Filtro estratégico: processar apenas os maiores players do mercado
-- ====================================================================

-- ====================================================================
-- TABELA: Ranking Mensal dos Top 100 Grupos
-- Atualizada mensalmente com os dados da CVM
-- ====================================================================

CREATE TABLE ranking_top100_grupos (
    id SERIAL PRIMARY KEY,

    -- Período
    ano INTEGER NOT NULL,
    mes INTEGER NOT NULL,
    data_referencia DATE NOT NULL, -- Último dia do mês

    -- Grupo
    grupo_id INTEGER REFERENCES dim_grupos_economicos(id),
    nome_grupo VARCHAR(200) NOT NULL,
    tipo_grupo VARCHAR(50), -- Banco, Gestora Independente, Corretora

    -- CRITÉRIO 1: Patrimônio Líquido Total
    patrimonio_liquido_total DECIMAL(18,2) NOT NULL,

    -- CRITÉRIO 2: Volume Movimentado (Compras + Vendas)
    volume_compras DECIMAL(18,2) DEFAULT 0,
    volume_vendas DECIMAL(18,2) DEFAULT 0,
    volume_total_movimentado DECIMAL(18,2) GENERATED ALWAYS AS (volume_compras + volume_vendas) STORED,

    -- CRITÉRIO 3: Fluxo Líquido (Compras - Vendas)
    fluxo_liquido DECIMAL(18,2) GENERATED ALWAYS AS (volume_compras - volume_vendas) STORED,

    -- Métricas Adicionais
    qtd_fundos INTEGER DEFAULT 0,
    qtd_posicoes_acoes INTEGER DEFAULT 0, -- Apenas ações
    valor_total_acoes DECIMAL(18,2) DEFAULT 0,

    -- Rankings (1 = maior)
    ranking_patrimonio INTEGER NOT NULL,
    ranking_volume_movimentado INTEGER NOT NULL,
    ranking_fluxo_liquido INTEGER,

    -- Indicadores de Tendência
    tendencia_mes VARCHAR(20), -- 'COMPRADOR', 'VENDEDOR', 'NEUTRO'
    percentual_pl_em_acoes DECIMAL(8,4), -- % do PL investido em ações

    -- Controle
    dt_atualizacao TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    -- Constraint de unicidade
    UNIQUE(grupo_id, ano, mes)
);

-- Índices
CREATE INDEX idx_ranking_ano_mes ON ranking_top100_grupos(ano, mes);
CREATE INDEX idx_ranking_grupo ON ranking_top100_grupos(grupo_id);
CREATE INDEX idx_ranking_patrimonio ON ranking_top100_grupos(ranking_patrimonio);
CREATE INDEX idx_ranking_volume ON ranking_top100_grupos(ranking_volume_movimentado);
CREATE INDEX idx_ranking_nome_grupo ON ranking_top100_grupos(nome_grupo);

-- Comentários
COMMENT ON TABLE ranking_top100_grupos IS 'Ranking mensal dos top 100 grupos econômicos por patrimônio e movimentação';
COMMENT ON COLUMN ranking_top100_grupos.patrimonio_liquido_total IS 'Soma do PL de todos os fundos do grupo';
COMMENT ON COLUMN ranking_top100_grupos.volume_total_movimentado IS 'Compras + Vendas (indica atividade)';
COMMENT ON COLUMN ranking_top100_grupos.fluxo_liquido IS 'Compras - Vendas (indica direção)';
COMMENT ON COLUMN ranking_top100_grupos.ranking_patrimonio IS '1 = maior patrimônio (top 100 apenas)';


-- ====================================================================
-- VIEW: Top 100 do Mês Atual
-- Acesso rápido aos 100 maiores do último período disponível
-- ====================================================================

CREATE OR REPLACE VIEW v_top100_atual AS
SELECT
    ranking_patrimonio,
    nome_grupo,
    tipo_grupo,
    patrimonio_liquido_total / 1000000000.0 AS pl_bilhoes,
    volume_total_movimentado / 1000000.0 AS volume_movimentado_milhoes,
    fluxo_liquido / 1000000.0 AS fluxo_liquido_milhoes,
    qtd_fundos,
    qtd_posicoes_acoes,
    valor_total_acoes / 1000000000.0 AS acoes_bilhoes,
    ROUND(percentual_pl_em_acoes, 2) AS perc_acoes,
    tendencia_mes,
    ano,
    mes
FROM ranking_top100_grupos
WHERE (ano, mes) = (
    SELECT ano, mes FROM ranking_top100_grupos
    ORDER BY ano DESC, mes DESC LIMIT 1
)
ORDER BY ranking_patrimonio;

COMMENT ON VIEW v_top100_atual IS 'Top 100 grupos do mês mais recente disponível';


-- ====================================================================
-- VIEW: Ranking por Volume Movimentado
-- Quem está mais ativo no mercado (comprando/vendendo)
-- ====================================================================

CREATE OR REPLACE VIEW v_top100_por_volume AS
SELECT
    ranking_volume_movimentado AS ranking,
    nome_grupo,
    tipo_grupo,
    volume_total_movimentado / 1000000.0 AS volume_milhoes,
    volume_compras / 1000000.0 AS compras_milhoes,
    volume_vendas / 1000000.0 AS vendas_milhoes,
    fluxo_liquido / 1000000.0 AS fluxo_liquido_milhoes,
    tendencia_mes,
    patrimonio_liquido_total / 1000000000.0 AS pl_bilhoes,
    ano,
    mes
FROM ranking_top100_grupos
WHERE (ano, mes) = (
    SELECT ano, mes FROM ranking_top100_grupos
    ORDER BY ano DESC, mes DESC LIMIT 1
)
ORDER BY ranking_volume_movimentado;

COMMENT ON VIEW v_top100_por_volume IS 'Top 100 grupos ordenados por volume de movimentação';


-- ====================================================================
-- VIEW: Maiores Compradores do Mês
-- Grupos com maior fluxo positivo (comprando mais que vendendo)
-- ====================================================================

CREATE OR REPLACE VIEW v_maiores_compradores AS
SELECT
    ROW_NUMBER() OVER (ORDER BY fluxo_liquido DESC) AS ranking_comprador,
    nome_grupo,
    tipo_grupo,
    fluxo_liquido / 1000000.0 AS fluxo_liquido_milhoes,
    volume_compras / 1000000.0 AS compras_milhoes,
    volume_vendas / 1000000.0 AS vendas_milhoes,
    patrimonio_liquido_total / 1000000000.0 AS pl_bilhoes,
    qtd_fundos,
    ano,
    mes
FROM ranking_top100_grupos
WHERE (ano, mes) = (
    SELECT ano, mes FROM ranking_top100_grupos
    ORDER BY ano DESC, mes DESC LIMIT 1
)
AND fluxo_liquido > 0
ORDER BY fluxo_liquido DESC;

COMMENT ON VIEW v_maiores_compradores IS 'Grupos com maior fluxo de compra no mês';


-- ====================================================================
-- VIEW: Maiores Vendedores do Mês
-- Grupos com maior fluxo negativo (vendendo mais que comprando)
-- ====================================================================

CREATE OR REPLACE VIEW v_maiores_vendedores AS
SELECT
    ROW_NUMBER() OVER (ORDER BY fluxo_liquido ASC) AS ranking_vendedor,
    nome_grupo,
    tipo_grupo,
    ABS(fluxo_liquido) / 1000000.0 AS fluxo_liquido_milhoes,
    volume_compras / 1000000.0 AS compras_milhoes,
    volume_vendas / 1000000.0 AS vendas_milhoes,
    patrimonio_liquido_total / 1000000000.0 AS pl_bilhoes,
    qtd_fundos,
    ano,
    mes
FROM ranking_top100_grupos
WHERE (ano, mes) = (
    SELECT ano, mes FROM ranking_top100_grupos
    ORDER BY ano DESC, mes DESC LIMIT 1
)
AND fluxo_liquido < 0
ORDER BY fluxo_liquido ASC;

COMMENT ON VIEW v_maiores_vendedores IS 'Grupos com maior fluxo de venda no mês';


-- ====================================================================
-- FUNÇÃO: Atualizar Ranking Top 100
-- Calcula e atualiza o ranking para um período específico
-- ====================================================================

CREATE OR REPLACE FUNCTION atualizar_ranking_top100(
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
    -- Data de referência (último dia do mês)
    v_data_ref := (p_ano || '-' || p_mes || '-01')::DATE + INTERVAL '1 month' - INTERVAL '1 day';

    -- Limpar dados antigos do período
    DELETE FROM ranking_top100_grupos WHERE ano = p_ano AND mes = p_mes;

    -- Inserir top 100 grupos
    INSERT INTO ranking_top100_grupos (
        ano, mes, data_referencia, grupo_id, nome_grupo, tipo_grupo,
        patrimonio_liquido_total, volume_compras, volume_vendas,
        qtd_fundos, qtd_posicoes_acoes, valor_total_acoes,
        ranking_patrimonio, ranking_volume_movimentado,
        tendencia_mes, percentual_pl_em_acoes
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

            -- Métricas adicionais
            COUNT(DISTINCT f.id) AS total_fundos,
            COUNT(CASE WHEN ca.nivel1_macro = 'Renda Variável' THEN 1 END) AS posicoes_acoes,
            SUM(CASE WHEN ca.nivel1_macro = 'Renda Variável' THEN fp.valor_mercado_posicao ELSE 0 END) AS valor_acoes

        FROM dim_grupos_economicos g
        LEFT JOIN dim_fundos f ON g.id = f.grupo_economico_id AND f.ativo = TRUE
        LEFT JOIN dim_patrimonio_liquido pl ON f.id = pl.fundo_id
        LEFT JOIN dim_tempo t ON pl.data_id = t.id
        LEFT JOIN fato_posicoes fp ON f.id = fp.fundo_id AND pl.data_id = fp.data_id
        LEFT JOIN dim_categoria_ativo ca ON fp.categoria_ativo_id = ca.id
        WHERE t.ano = p_ano AND t.mes = p_mes AND t.fim_mes = TRUE
        GROUP BY g.id, g.nome_grupo, g.tipo_grupo
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
        CASE WHEN pl_total > 0 THEN (valor_acoes / pl_total * 100) ELSE 0 END
    FROM ranked
    WHERE rank_pl <= 100 -- TOP 100 APENAS
    ORDER BY rank_pl;

    GET DIAGNOSTICS v_grupos_count = ROW_COUNT;

    RETURN QUERY SELECT v_grupos_count, v_data_ref;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION atualizar_ranking_top100 IS 'Calcula e atualiza o ranking dos top 100 grupos para um período';


-- ====================================================================
-- EXEMPLO DE USO
-- ====================================================================

/*
-- Atualizar ranking para Outubro/2025
SELECT * FROM atualizar_ranking_top100(2025, 10);

-- Ver top 100 atual
SELECT * FROM v_top100_atual;

-- Ver top 10 por volume movimentado
SELECT * FROM v_top100_por_volume LIMIT 10;

-- Ver top 10 compradores
SELECT * FROM v_maiores_compradores LIMIT 10;

-- Ver top 10 vendedores
SELECT * FROM v_maiores_vendedores LIMIT 10;
*/
