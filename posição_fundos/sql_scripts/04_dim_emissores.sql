-- ====================================================================
-- DIMENSÃO EMISSORES
-- Cadastro de emissores de títulos e valores mobiliários
-- ====================================================================

CREATE TABLE dim_emissores (
    id SERIAL PRIMARY KEY,

    -- Identificação
    cnpj_emissor VARCHAR(18),
    cpf_emissor VARCHAR(14),
    emissor_nome TEXT NOT NULL,
    emissor_nome_clean TEXT, -- Versão normalizada do nome

    -- Classificação
    pf_pj VARCHAR(2), -- 'PF' ou 'PJ'
    tipo_emissor VARCHAR(50), -- 'Governo', 'Instituição Financeira', 'Empresa', etc.
    setor_economia VARCHAR(100), -- Setor da economia

    -- Informações Adicionais
    rating VARCHAR(20), -- Rating de crédito
    pais_origem VARCHAR(50) DEFAULT 'Brasil',

    -- Controle
    ativo BOOLEAN DEFAULT TRUE,
    dt_criacao TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    dt_ultima_atualizacao TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    -- Constraint: CNPJ ou CPF deve estar preenchido
    CONSTRAINT chk_cnpj_cpf CHECK (cnpj_emissor IS NOT NULL OR cpf_emissor IS NOT NULL)
);

-- Índices
CREATE INDEX idx_emissor_cnpj ON dim_emissores(cnpj_emissor);
CREATE INDEX idx_emissor_cpf ON dim_emissores(cpf_emissor);
CREATE INDEX idx_emissor_nome ON dim_emissores(emissor_nome);
CREATE INDEX idx_emissor_tipo ON dim_emissores(tipo_emissor);
CREATE INDEX idx_emissor_ativo ON dim_emissores(ativo) WHERE ativo = TRUE;

-- Comentários
COMMENT ON TABLE dim_emissores IS 'Cadastro de emissores de títulos e valores mobiliários';
COMMENT ON COLUMN dim_emissores.emissor_nome_clean IS 'Nome normalizado (sem acentos, maiúsculas, etc.) para facilitar buscas';
COMMENT ON COLUMN dim_emissores.tipo_emissor IS 'Governo, Instituição Financeira, Empresa, etc.';
