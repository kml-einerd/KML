-- ============================================================================
-- NORMALIZED SCHEMA - RADAR INSTITUCIONAL
-- ============================================================================

-- 1. CLEANUP
DROP TABLE IF EXISTS fresh_bets CASCADE;
DROP TABLE IF EXISTS top_movers CASCADE;
DROP TABLE IF EXISTS posicoes_confidenciais CASCADE;
DROP TABLE IF EXISTS posicoes_exterior CASCADE;
DROP TABLE IF EXISTS posicoes_detalhes CASCADE;
DROP TABLE IF EXISTS posicoes CASCADE;
DROP TABLE IF EXISTS patrimonio_liquido CASCADE;
DROP TABLE IF EXISTS ativos CASCADE;
DROP TABLE IF EXISTS emissores CASCADE;
DROP TABLE IF EXISTS fundos CASCADE;

-- 2. MASTER TABLES (DIMENSIONS)

-- Fundos (Cadastro Único)
CREATE TABLE fundos (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    cnpj TEXT UNIQUE NOT NULL,
    nome_fundo TEXT,
    classe TEXT, -- TP_FUNDO_CLASSE
    is_grande_fundo BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Emissores (Cadastro Único)
CREATE TABLE emissores (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    cnpj_cpf TEXT UNIQUE, -- CPF_CNPJ_EMISSOR
    nome_emissor TEXT, -- EMISSOR
    tipo_pessoa TEXT, -- PF_PJ_EMISSOR
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Ativos (Cadastro Único)
CREATE TABLE ativos (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    codigo TEXT, -- CD_ATIVO
    descricao TEXT, -- DS_ATIVO
    tipo_ativo TEXT, -- TP_ATIVO
    emissor_id UUID REFERENCES emissores(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(codigo, tipo_ativo, emissor_id) -- Composite unique key might need adjustment based on data
);

-- Patrimônio Líquido (Série Temporal)
CREATE TABLE patrimonio_liquido (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    fundo_id UUID REFERENCES fundos(id) NOT NULL,
    data_competencia DATE NOT NULL,
    valor_pl NUMERIC,
    mes_referencia DATE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(fundo_id, data_competencia)
);

-- 3. FACT TABLES (TRANSACTIONS)

-- Posições Consolidadas (Tabela Principal)
CREATE TABLE posicoes (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    fundo_id UUID REFERENCES fundos(id) NOT NULL,
    ativo_id UUID REFERENCES ativos(id), -- Pode ser nulo para alguns tipos de ativos?
    data_competencia DATE NOT NULL,
    tipo_aplicacao TEXT, -- TP_APLIC
    qtd_posicao_final NUMERIC, -- QT_POS_FINAL
    valor_mercado_final NUMERIC, -- VL_MERC_POS_FINAL
    valor_custo_final NUMERIC, -- VL_CUSTO_POS_FINAL
    percentual_carteira NUMERIC, -- Calculado (opcional)
    mes_referencia DATE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(fundo_id, ativo_id, data_competencia)
);

-- Detalhes Específicos (JSONB para flexibilidade)
CREATE TABLE posicoes_detalhes (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    posicao_id UUID REFERENCES posicoes(id) ON DELETE CASCADE,
    detalhes JSONB, -- Armazena campos específicos como taxas, indexadores, vencimentos
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Ativos no Exterior
CREATE TABLE posicoes_exterior (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    fundo_id UUID REFERENCES fundos(id) NOT NULL,
    data_competencia DATE NOT NULL,
    codigo_ativo TEXT,
    descricao_ativo TEXT,
    valor_mercado NUMERIC,
    mes_referencia DATE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Dados Confidenciais
CREATE TABLE posicoes_confidenciais (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    fundo_id UUID REFERENCES fundos(id) NOT NULL,
    data_competencia DATE NOT NULL,
    tipo_aplicacao TEXT,
    valor_mercado NUMERIC,
    mes_referencia DATE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 4. ANALYTICAL TABLES (AGGREGATIONS)

-- Top Movers
CREATE TABLE top_movers (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    fundo_id UUID REFERENCES fundos(id),
    ativo_id UUID REFERENCES ativos(id),
    data_competencia DATE,
    variacao_qtd NUMERIC,
    variacao_valor NUMERIC,
    pct_variacao NUMERIC,
    tipo_movimento TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(fundo_id, ativo_id, data_competencia)
);

-- Fresh Bets (Consensos)
CREATE TABLE fresh_bets (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    ativo_id UUID REFERENCES ativos(id),
    data_competencia DATE,
    qtd_fundos INTEGER,
    valor_total_investido NUMERIC,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(ativo_id, data_competencia)
);

-- 5. PERMISSIONS
-- Função helper para liberar tabela
CREATE OR REPLACE FUNCTION liberar_tabela(tabela text) RETURNS void AS $$
BEGIN
    EXECUTE format('ALTER TABLE %I ENABLE ROW LEVEL SECURITY', tabela);
    EXECUTE format('DROP POLICY IF EXISTS "Acesso Total" ON %I', tabela);
    EXECUTE format('CREATE POLICY "Acesso Total" ON %I FOR ALL USING (true) WITH CHECK (true)', tabela);
    EXECUTE format('GRANT ALL ON %I TO anon, authenticated, service_role', tabela);
END;
$$ LANGUAGE plpgsql;

-- Aplicar liberações
SELECT liberar_tabela('fundos');
SELECT liberar_tabela('emissores');
SELECT liberar_tabela('ativos');
SELECT liberar_tabela('patrimonio_liquido');
SELECT liberar_tabela('posicoes');
SELECT liberar_tabela('posicoes_detalhes');
SELECT liberar_tabela('posicoes_exterior');
SELECT liberar_tabela('posicoes_confidenciais');
SELECT liberar_tabela('top_movers');
SELECT liberar_tabela('fresh_bets');

DROP FUNCTION liberar_tabela(text);
