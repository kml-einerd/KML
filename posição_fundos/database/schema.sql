-- ===============================================
-- RADAR INSTITUCIONAL - Database Schema
-- Supabase PostgreSQL
-- ===============================================
--
-- Este schema define as tabelas necessárias para
-- o MVP do Radar Institucional (análise de fundos CVM)
--
-- Autor: Sistema ETL Radar Institucional
-- Data: 2025-11
-- ===============================================

-- ==================
-- TABELA 1: FUNDOS
-- ==================
-- Cadastro de fundos de investimento (dimensão)

CREATE TABLE IF NOT EXISTS fundos (
    cnpj VARCHAR(20) PRIMARY KEY,
    nome_fundo VARCHAR(500) NOT NULL,
    gestora VARCHAR(200),
    pl_atual DECIMAL(20,2),
    categoria VARCHAR(50),
    is_grande_fundo BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

COMMENT ON TABLE fundos IS 'Cadastro de fundos de investimento';
COMMENT ON COLUMN fundos.cnpj IS 'CNPJ do fundo (chave primária)';
COMMENT ON COLUMN fundos.is_grande_fundo IS 'Flag para fundos com PL > R$ 50M ou Top 200';

-- ==========================================
-- TABELA 2: PATRIMÔNIO LÍQUIDO MENSAL
-- ==========================================
-- Histórico mensal de PL dos fundos

CREATE TABLE IF NOT EXISTS patrimonio_liquido_mensal (
    id BIGSERIAL PRIMARY KEY,
    cnpj_fundo VARCHAR(20) NOT NULL REFERENCES fundos(cnpj) ON DELETE CASCADE,
    data_competencia DATE NOT NULL,
    valor_pl DECIMAL(20,2) NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    CONSTRAINT uk_pl_fundo_data UNIQUE(cnpj_fundo, data_competencia)
);

COMMENT ON TABLE patrimonio_liquido_mensal IS 'Histórico mensal de Patrimônio Líquido';
COMMENT ON COLUMN patrimonio_liquido_mensal.valor_pl IS 'Valor do PL em reais';

-- ==============================
-- TABELA 3: POSIÇÕES EM AÇÕES
-- ==============================
-- Tabela de fatos com posições de cada fundo em ações

CREATE TABLE IF NOT EXISTS posicoes_acoes (
    id BIGSERIAL PRIMARY KEY,
    cnpj_fundo VARCHAR(20) NOT NULL REFERENCES fundos(cnpj) ON DELETE CASCADE,
    data_competencia DATE NOT NULL,
    ticker VARCHAR(20) NOT NULL,
    tipo_ativo VARCHAR(100),

    -- Movimentações do mês
    qtd_compra DECIMAL(20,6) DEFAULT 0,
    valor_compra DECIMAL(20,2) DEFAULT 0,
    qtd_venda DECIMAL(20,6) DEFAULT 0,
    valor_venda DECIMAL(20,2) DEFAULT 0,

    -- Posição final
    qtd_posicao_final DECIMAL(20,6),
    valor_mercado_final DECIMAL(20,2),
    valor_custo_final DECIMAL(20,2),

    created_at TIMESTAMPTZ DEFAULT NOW(),
    CONSTRAINT uk_posicao_fundo_data_ticker UNIQUE(cnpj_fundo, data_competencia, ticker)
);

COMMENT ON TABLE posicoes_acoes IS 'Posições de fundos em ações (tabela fato principal)';
COMMENT ON COLUMN posicoes_acoes.ticker IS 'Código da ação (ex: PETR4, VALE3)';
COMMENT ON COLUMN posicoes_acoes.valor_compra IS 'Valor total de compras no mês (R$)';
COMMENT ON COLUMN posicoes_acoes.valor_venda IS 'Valor total de vendas no mês (R$)';

-- ===============================
-- TABELA 4: TOP MOVERS
-- ===============================
-- Tabela materializada com rankings de fundos

CREATE TABLE IF NOT EXISTS top_movers (
    id BIGSERIAL PRIMARY KEY,
    cnpj_fundo VARCHAR(20) NOT NULL REFERENCES fundos(cnpj) ON DELETE CASCADE,
    data_competencia DATE NOT NULL,
    total_compras DECIMAL(20,2) DEFAULT 0,
    total_vendas DECIMAL(20,2) DEFAULT 0,
    fluxo_liquido DECIMAL(20,2),
    ranking_compradores INT,
    ranking_vendedores INT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    CONSTRAINT uk_topmovers_fundo_data UNIQUE(cnpj_fundo, data_competencia)
);

COMMENT ON TABLE top_movers IS 'Rankings de fundos por fluxo de compra/venda (pré-calculado)';
COMMENT ON COLUMN top_movers.fluxo_liquido IS 'Compras - Vendas (positivo = comprador líquido)';
COMMENT ON COLUMN top_movers.ranking_compradores IS 'Posição no ranking de compradores (1 = maior)';

-- ================================
-- TABELA 5: FRESH BETS
-- ================================
-- Ativos que entraram nas carteiras (novas apostas)

CREATE TABLE IF NOT EXISTS fresh_bets (
    id BIGSERIAL PRIMARY KEY,
    ticker VARCHAR(20) NOT NULL,
    data_competencia DATE NOT NULL,
    num_fundos_entraram INT DEFAULT 0,
    volume_total DECIMAL(20,2) DEFAULT 0,
    fundos_lista TEXT[], -- Array de CNPJs
    created_at TIMESTAMPTZ DEFAULT NOW(),
    CONSTRAINT uk_freshbets_ticker_data UNIQUE(ticker, data_competencia)
);

COMMENT ON TABLE fresh_bets IS 'Ativos que entraram em múltiplas carteiras (consenso institucional)';
COMMENT ON COLUMN fresh_bets.num_fundos_entraram IS 'Quantos fundos grandes adicionaram este ativo';
COMMENT ON COLUMN fresh_bets.fundos_lista IS 'Array com CNPJs dos fundos que entraram';

-- ===================================
-- TABELA 6: METADADOS DOS ATIVOS
-- ===================================
-- Informações complementares sobre ações

CREATE TABLE IF NOT EXISTS ativos_metadata (
    ticker VARCHAR(20) PRIMARY KEY,
    nome_empresa VARCHAR(200),
    setor VARCHAR(100),
    subsetor VARCHAR(100),
    tipo VARCHAR(50), -- 'Ação', 'FII', 'BDR', 'Unit'
    ultima_cotacao DECIMAL(10,2),
    data_ultima_cotacao DATE,
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

COMMENT ON TABLE ativos_metadata IS 'Informações complementares dos ativos (nome, setor, etc)';
COMMENT ON COLUMN ativos_metadata.tipo IS 'Tipo do ativo: Ação, FII, BDR ou Unit';

-- ===============================================
-- TRIGGER: Atualizar updated_at automaticamente
-- ===============================================

CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_fundos_updated_at
    BEFORE UPDATE ON fundos
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_ativos_metadata_updated_at
    BEFORE UPDATE ON ativos_metadata
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- ===============================================
-- VIEWS ÚTEIS
-- ===============================================

-- View: Últimos dados disponíveis
CREATE OR REPLACE VIEW v_ultima_competencia AS
SELECT MAX(data_competencia) as ultima_data
FROM posicoes_acoes;

COMMENT ON VIEW v_ultima_competencia IS 'Retorna a última data de competência disponível';

-- View: Resumo dos fundos grandes
CREATE OR REPLACE VIEW v_fundos_grandes_resumo AS
SELECT
    f.cnpj,
    f.nome_fundo,
    f.gestora,
    pl.valor_pl as pl_atual,
    COUNT(DISTINCT pa.ticker) as num_acoes_carteira,
    SUM(pa.valor_mercado_final) as total_acoes
FROM fundos f
LEFT JOIN patrimonio_liquido_mensal pl
    ON f.cnpj = pl.cnpj_fundo
    AND pl.data_competencia = (SELECT ultima_data FROM v_ultima_competencia)
LEFT JOIN posicoes_acoes pa
    ON f.cnpj = pa.cnpj_fundo
    AND pa.data_competencia = (SELECT ultima_data FROM v_ultima_competencia)
WHERE f.is_grande_fundo = TRUE
GROUP BY f.cnpj, f.nome_fundo, f.gestora, pl.valor_pl;

COMMENT ON VIEW v_fundos_grandes_resumo IS 'Resumo dos grandes fundos com PL e número de ações';

-- ===============================================
-- ÍNDICES DE PERFORMANCE
-- ===============================================
-- (Ver arquivo indexes.sql para índices detalhados)

-- ===============================================
-- PERMISSÕES E SEGURANÇA
-- ===============================================

-- Para uso com Supabase, habilitar RLS (Row Level Security)
ALTER TABLE fundos ENABLE ROW LEVEL SECURITY;
ALTER TABLE patrimonio_liquido_mensal ENABLE ROW LEVEL SECURITY;
ALTER TABLE posicoes_acoes ENABLE ROW LEVEL SECURITY;
ALTER TABLE top_movers ENABLE ROW LEVEL SECURITY;
ALTER TABLE fresh_bets ENABLE ROW LEVEL SECURITY;
ALTER TABLE ativos_metadata ENABLE ROW LEVEL SECURITY;

-- Políticas de leitura pública (ajustar conforme necessário)
CREATE POLICY "Permitir leitura pública de fundos"
    ON fundos FOR SELECT
    USING (true);

CREATE POLICY "Permitir leitura pública de PL"
    ON patrimonio_liquido_mensal FOR SELECT
    USING (true);

CREATE POLICY "Permitir leitura pública de posições"
    ON posicoes_acoes FOR SELECT
    USING (true);

CREATE POLICY "Permitir leitura pública de top_movers"
    ON top_movers FOR SELECT
    USING (true);

CREATE POLICY "Permitir leitura pública de fresh_bets"
    ON fresh_bets FOR SELECT
    USING (true);

CREATE POLICY "Permitir leitura pública de ativos_metadata"
    ON ativos_metadata FOR SELECT
    USING (true);

-- ===============================================
-- FIM DO SCHEMA
-- ===============================================

-- Para verificar se tudo foi criado corretamente:
-- SELECT table_name FROM information_schema.tables WHERE table_schema = 'public';
