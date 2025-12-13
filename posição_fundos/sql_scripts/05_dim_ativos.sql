-- ====================================================================
-- DIMENSÃO ATIVOS
-- Cadastro de ativos específicos (ações, títulos, etc.)
-- ====================================================================

CREATE TABLE dim_ativos (
    id SERIAL PRIMARY KEY,

    -- Identificação
    cd_ativo VARCHAR(50), -- Código do ativo (ex: PETR4, ITUB3)
    ds_ativo TEXT, -- Descrição do ativo
    cd_isin VARCHAR(12), -- Código ISIN internacional
    cd_selic VARCHAR(20), -- Código SELIC (para títulos públicos)

    -- Classificação
    categoria_ativo_id INTEGER REFERENCES dim_categoria_ativo(id),
    emissor_id INTEGER REFERENCES dim_emissores(id),

    -- Informações Específicas por Tipo
    tp_titpub VARCHAR(50), -- Tipo de título público (LFT, LTN, etc.)
    dt_emissao DATE, -- Data de emissão
    dt_vencimento DATE, -- Data de vencimento

    -- Informações de Ações
    tipo_acao VARCHAR(10), -- ON, PN, etc.
    segmento_listagem VARCHAR(50), -- Novo Mercado, Nível 1, etc.

    -- Controle
    ativo BOOLEAN DEFAULT TRUE,
    dt_criacao TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    dt_ultima_atualizacao TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Índices
CREATE INDEX idx_ativo_codigo ON dim_ativos(cd_ativo);
CREATE INDEX idx_ativo_isin ON dim_ativos(cd_isin);
CREATE INDEX idx_ativo_selic ON dim_ativos(cd_selic);
CREATE INDEX idx_ativo_categoria ON dim_ativos(categoria_ativo_id);
CREATE INDEX idx_ativo_emissor ON dim_ativos(emissor_id);
CREATE INDEX idx_ativo_vencimento ON dim_ativos(dt_vencimento);

-- Comentários
COMMENT ON TABLE dim_ativos IS 'Cadastro de ativos específicos (ações, títulos, fundos, etc.)';
COMMENT ON COLUMN dim_ativos.cd_ativo IS 'Código do ativo (ticker para ações, código para títulos)';
COMMENT ON COLUMN dim_ativos.cd_isin IS 'Código ISIN (International Securities Identification Number)';
COMMENT ON COLUMN dim_ativos.cd_selic IS 'Código SELIC para títulos públicos';
