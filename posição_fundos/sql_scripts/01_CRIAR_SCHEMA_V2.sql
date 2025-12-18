-- ========================================
-- SCHEMA V2 - ANÁLISE DE FUNDOS SIMPLIFICADA
-- Execute APÓS 00_LIMPAR_TUDO.sql
-- ========================================

-- ========================================
-- TABELA 1: GRUPOS DE FUNDOS
-- ========================================

CREATE TABLE grupos_fundos (
    id SERIAL PRIMARY KEY,
    nome_grupo VARCHAR(200) NOT NULL UNIQUE,
    qtd_fundos INTEGER DEFAULT 0,
    pl_total_bilhoes DECIMAL(12,2) DEFAULT 0,
    dt_criacao TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    dt_atualizacao TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_grupos_nome ON grupos_fundos(nome_grupo);
CREATE INDEX idx_grupos_pl ON grupos_fundos(pl_total_bilhoes DESC);

COMMENT ON TABLE grupos_fundos IS 'Top 100 grupos econômicos';

-- ========================================
-- TABELA 2: AÇÕES DOS FUNDOS
-- ========================================

CREATE TABLE acoes_fundos (
    id BIGSERIAL PRIMARY KEY,
    mes_referencia DATE NOT NULL,
    grupo_id INTEGER NOT NULL REFERENCES grupos_fundos(id) ON DELETE CASCADE,
    ticker VARCHAR(10) NOT NULL,
    empresa VARCHAR(200),
    qtd_comprada DECIMAL(18,2) DEFAULT 0,
    valor_comprado DECIMAL(18,2) DEFAULT 0,
    qtd_vendida DECIMAL(18,2) DEFAULT 0,
    valor_vendido DECIMAL(18,2) DEFAULT 0,
    posicao_final DECIMAL(18,2) DEFAULT 0,
    valor_mercado DECIMAL(18,2) DEFAULT 0,
    valor_custo DECIMAL(18,2) DEFAULT 0,
    tipo_movimento VARCHAR(10),
    fluxo_liquido DECIMAL(18,2) GENERATED ALWAYS AS (valor_comprado - valor_vendido) STORED,
    rentabilidade_pct DECIMAL(8,4),
    dt_carga TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(mes_referencia, grupo_id, ticker)
);

CREATE INDEX idx_acoes_mes ON acoes_fundos(mes_referencia DESC);
CREATE INDEX idx_acoes_ticker ON acoes_fundos(ticker);
CREATE INDEX idx_acoes_grupo ON acoes_fundos(grupo_id);
CREATE INDEX idx_acoes_tipo_mov ON acoes_fundos(tipo_movimento);
CREATE INDEX idx_acoes_mes_ticker ON acoes_fundos(mes_referencia, ticker);
CREATE INDEX idx_acoes_fluxo ON acoes_fundos(fluxo_liquido DESC);

COMMENT ON TABLE acoes_fundos IS 'Movimentos e posições em ações dos fundos Top 100';

-- ========================================
-- TABELA 3: RESUMO MENSAL
-- ========================================

CREATE TABLE resumo_mensal (
    id SERIAL PRIMARY KEY,
    mes_referencia DATE NOT NULL,
    ticker VARCHAR(10) NOT NULL,
    empresa VARCHAR(200),
    total_comprado DECIMAL(18,2) DEFAULT 0,
    total_vendido DECIMAL(18,2) DEFAULT 0,
    fluxo_liquido DECIMAL(18,2) GENERATED ALWAYS AS (total_comprado - total_vendido) STORED,
    qtd_fundos_compradores INTEGER DEFAULT 0,
    qtd_fundos_vendedores INTEGER DEFAULT 0,
    qtd_fundos_posicionados INTEGER DEFAULT 0,
    top_comprador VARCHAR(200),
    valor_top_comprador DECIMAL(18,2),
    top_vendedor VARCHAR(200),
    valor_top_vendedor DECIMAL(18,2),
    tendencia_mercado VARCHAR(10),
    intensidade_consenso DECIMAL(5,2),
    dt_carga TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(mes_referencia, ticker)
);

CREATE INDEX idx_resumo_mes ON resumo_mensal(mes_referencia DESC);
CREATE INDEX idx_resumo_ticker ON resumo_mensal(ticker);
CREATE INDEX idx_resumo_fluxo ON resumo_mensal(fluxo_liquido DESC);
CREATE INDEX idx_resumo_tendencia ON resumo_mensal(tendencia_mercado);

COMMENT ON TABLE resumo_mensal IS 'Resumo mensal agregado por ação';

-- ========================================
-- VIEW 1: Top Compras do Mês
-- ========================================

CREATE OR REPLACE VIEW v_top_compras_mes AS
SELECT
    mes_referencia,
    ticker,
    empresa,
    total_comprado / 1000000.0 AS comprado_milhoes,
    qtd_fundos_compradores,
    top_comprador,
    valor_top_comprador / 1000000.0 AS top_comprador_milhoes,
    ROW_NUMBER() OVER (PARTITION BY mes_referencia ORDER BY total_comprado DESC) AS ranking
FROM resumo_mensal
WHERE total_comprado > 0
ORDER BY mes_referencia DESC, total_comprado DESC;

-- ========================================
-- VIEW 2: Top Vendas do Mês
-- ========================================

CREATE OR REPLACE VIEW v_top_vendas_mes AS
SELECT
    mes_referencia,
    ticker,
    empresa,
    total_vendido / 1000000.0 AS vendido_milhoes,
    qtd_fundos_vendedores,
    top_vendedor,
    valor_top_vendedor / 1000000.0 AS top_vendedor_milhoes,
    ROW_NUMBER() OVER (PARTITION BY mes_referencia ORDER BY total_vendido DESC) AS ranking
FROM resumo_mensal
WHERE total_vendido > 0
ORDER BY mes_referencia DESC, total_vendido DESC;

-- ========================================
-- VIEW 3: Movimentos de um Grupo
-- ========================================

CREATE OR REPLACE VIEW v_movimentos_grupo AS
SELECT
    g.nome_grupo,
    a.mes_referencia,
    a.ticker,
    a.empresa,
    a.tipo_movimento,
    a.fluxo_liquido / 1000000.0 AS fluxo_milhoes,
    a.valor_mercado / 1000000.0 AS posicao_milhoes,
    a.rentabilidade_pct
FROM acoes_fundos a
JOIN grupos_fundos g ON a.grupo_id = g.id
ORDER BY g.nome_grupo, a.mes_referencia DESC, ABS(a.fluxo_liquido) DESC;

-- ========================================
-- VIEW 4: Consenso de Mercado
-- ========================================

CREATE OR REPLACE VIEW v_consenso_mercado AS
SELECT
    ticker,
    empresa,
    mes_referencia,
    tendencia_mercado,
    intensidade_consenso,
    qtd_fundos_compradores,
    qtd_fundos_vendedores,
    fluxo_liquido / 1000000000.0 AS fluxo_bilhoes,
    CASE
        WHEN tendencia_mercado = 'COMPRA' AND intensidade_consenso > 70 THEN 'FORTE COMPRA ⬆️⬆️'
        WHEN tendencia_mercado = 'COMPRA' AND intensidade_consenso > 50 THEN 'COMPRA ⬆️'
        WHEN tendencia_mercado = 'VENDA' AND intensidade_consenso > 70 THEN 'FORTE VENDA ⬇️⬇️'
        WHEN tendencia_mercado = 'VENDA' AND intensidade_consenso > 50 THEN 'VENDA ⬇️'
        ELSE 'NEUTRO ↔️'
    END AS sinal
FROM resumo_mensal
WHERE mes_referencia = (SELECT MAX(mes_referencia) FROM resumo_mensal)
ORDER BY ABS(fluxo_liquido) DESC;

-- ========================================
-- FUNÇÃO: Atualizar Resumo Mensal
-- ========================================

CREATE OR REPLACE FUNCTION atualizar_resumo_mensal(p_mes_ref DATE)
RETURNS INTEGER AS $$
DECLARE
    v_count INTEGER;
BEGIN
    DELETE FROM resumo_mensal WHERE mes_referencia = p_mes_ref;

    INSERT INTO resumo_mensal (
        mes_referencia, ticker, empresa,
        total_comprado, total_vendido,
        qtd_fundos_compradores, qtd_fundos_vendedores, qtd_fundos_posicionados,
        top_comprador, valor_top_comprador,
        top_vendedor, valor_top_vendedor,
        tendencia_mercado, intensidade_consenso
    )
    WITH stats_por_ticker AS (
        SELECT
            a.ticker,
            MAX(a.empresa) AS empresa,
            SUM(a.valor_comprado) AS total_comprado,
            SUM(a.valor_vendido) AS total_vendido,
            COUNT(CASE WHEN a.valor_comprado > a.valor_vendido THEN 1 END) AS compradores,
            COUNT(CASE WHEN a.valor_vendido > a.valor_comprado THEN 1 END) AS vendedores,
            COUNT(*) AS total_fundos
        FROM acoes_fundos a
        WHERE a.mes_referencia = p_mes_ref
        GROUP BY a.ticker
    ),
    top_compradores AS (
        SELECT
            a.ticker,
            g.nome_grupo AS nome,
            a.valor_comprado AS valor,
            ROW_NUMBER() OVER (PARTITION BY a.ticker ORDER BY a.valor_comprado DESC) AS rn
        FROM acoes_fundos a
        JOIN grupos_fundos g ON a.grupo_id = g.id
        WHERE a.mes_referencia = p_mes_ref
          AND a.valor_comprado > 0
    ),
    top_vendedores AS (
        SELECT
            a.ticker,
            g.nome_grupo AS nome,
            a.valor_vendido AS valor,
            ROW_NUMBER() OVER (PARTITION BY a.ticker ORDER BY a.valor_vendido DESC) AS rn
        FROM acoes_fundos a
        JOIN grupos_fundos g ON a.grupo_id = g.id
        WHERE a.mes_referencia = p_mes_ref
          AND a.valor_vendido > 0
    )
    SELECT
        p_mes_ref,
        s.ticker,
        s.empresa,
        s.total_comprado,
        s.total_vendido,
        s.compradores,
        s.vendedores,
        s.total_fundos,
        tc.nome AS top_comprador,
        tc.valor AS valor_top_comprador,
        tv.nome AS top_vendedor,
        tv.valor AS valor_top_vendedor,
        CASE
            WHEN s.total_comprado > s.total_vendido * 1.2 THEN 'COMPRA'
            WHEN s.total_vendido > s.total_comprado * 1.2 THEN 'VENDA'
            ELSE 'NEUTRO'
        END AS tendencia_mercado,
        CASE
            WHEN s.total_comprado > s.total_vendido THEN (s.compradores::DECIMAL / s.total_fundos * 100)
            ELSE (s.vendedores::DECIMAL / s.total_fundos * 100)
        END AS intensidade_consenso
    FROM stats_por_ticker s
    LEFT JOIN top_compradores tc ON s.ticker = tc.ticker AND tc.rn = 1
    LEFT JOIN top_vendedores tv ON s.ticker = tv.ticker AND tv.rn = 1;

    GET DIAGNOSTICS v_count = ROW_COUNT;
    RETURN v_count;
END;
$$ LANGUAGE plpgsql;

-- ========================================
-- VERIFICAÇÃO
-- ========================================

SELECT 'Tabelas criadas:' AS info;
SELECT table_name FROM information_schema.tables
WHERE table_schema = 'public' AND table_type = 'BASE TABLE'
ORDER BY table_name;

SELECT 'Views criadas:' AS info;
SELECT table_name FROM information_schema.views
WHERE table_schema = 'public'
ORDER BY table_name;

-- ========================================
-- CONCLUÍDO
-- ========================================

SELECT '✅ Schema V2 criado com sucesso!' AS status;
SELECT '📊 3 tabelas: grupos_fundos, acoes_fundos, resumo_mensal' AS tabelas;
SELECT '👁️  4 views: v_top_compras_mes, v_top_vendas_mes, v_movimentos_grupo, v_consenso_mercado' AS views;
SELECT '🎯 Próximo passo: Execute o ETL para carregar dados' AS proximo;
