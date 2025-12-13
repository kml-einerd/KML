-- ====================================================================
-- DIMENSÃO FUNDOS
-- Cadastro de fundos de investimento (SCD Type 2)
-- ====================================================================

CREATE TABLE dim_fundos (
    id SERIAL PRIMARY KEY,

    -- Identificação
    cnpj_fundo_classe VARCHAR(18) NOT NULL,
    nome_fundo TEXT NOT NULL,
    nome_fundo_clean TEXT, -- Versão normalizada

    -- Classificação CVM
    tipo_fundo VARCHAR(50), -- FIF, FIA, FIM, FIDC, etc.
    tp_fundo_classe VARCHAR(100), -- Classe conforme CVM

    -- Relacionamentos
    grupo_economico_id INTEGER REFERENCES dim_grupos_economicos(id),

    -- Classificações Adicionais
    categoria_anbima VARCHAR(100),
    classe_risco VARCHAR(20), -- 'Conservador', 'Moderado', 'Agressivo'
    publico_alvo VARCHAR(50), -- 'Varejo', 'Qualificado', 'Profissional'

    -- SCD Type 2 (Slowly Changing Dimension)
    data_inicio DATE NOT NULL DEFAULT CURRENT_DATE,
    data_fim DATE, -- NULL = registro atual
    versao INTEGER DEFAULT 1,
    ativo BOOLEAN DEFAULT TRUE,

    -- Controle
    dt_criacao TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    dt_ultima_atualizacao TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Índices
CREATE INDEX idx_fundo_cnpj ON dim_fundos(cnpj_fundo_classe);
CREATE INDEX idx_fundo_nome ON dim_fundos(nome_fundo);
CREATE INDEX idx_fundo_grupo ON dim_fundos(grupo_economico_id);
CREATE INDEX idx_fundo_tipo ON dim_fundos(tipo_fundo);
CREATE INDEX idx_fundo_ativo ON dim_fundos(ativo) WHERE ativo = TRUE;
CREATE INDEX idx_fundo_atual ON dim_fundos(cnpj_fundo_classe, data_fim) WHERE data_fim IS NULL;

-- Comentários
COMMENT ON TABLE dim_fundos IS 'Cadastro de fundos de investimento com SCD Type 2';
COMMENT ON COLUMN dim_fundos.data_fim IS 'NULL indica que é o registro atual do fundo';
COMMENT ON COLUMN dim_fundos.versao IS 'Versão do registro para controle de histórico (SCD Type 2)';
