-- ====================================================================
-- DIMENSÃO GRUPOS ECONÔMICOS
-- Hierarquia de grupos/conglomerados que controlam gestoras
-- ====================================================================

CREATE TABLE dim_grupos_economicos (
    id SERIAL PRIMARY KEY,

    -- Identificação
    nome_grupo VARCHAR(200) NOT NULL,
    cnpj_principal VARCHAR(18),

    -- Classificação
    tipo_grupo VARCHAR(50), -- 'Banco', 'Gestora Independente', 'Corretora', 'Seguradora'
    segmento VARCHAR(50), -- 'Varejo', 'Private', 'Corporativo', 'Institucional'

    -- Métricas Agregadas (Desnormalizado para Performance)
    total_fundos INTEGER DEFAULT 0,
    total_pl DECIMAL(18,2) DEFAULT 0,
    ranking_mercado INTEGER,

    -- Controle
    ativo BOOLEAN DEFAULT TRUE,
    dt_criacao TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    dt_ultima_atualizacao TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Índices
CREATE INDEX idx_grupo_nome ON dim_grupos_economicos(nome_grupo);
CREATE INDEX idx_grupo_tipo ON dim_grupos_economicos(tipo_grupo);
CREATE INDEX idx_grupo_ranking ON dim_grupos_economicos(ranking_mercado);
CREATE INDEX idx_grupo_ativo ON dim_grupos_economicos(ativo) WHERE ativo = TRUE;

-- Comentários
COMMENT ON TABLE dim_grupos_economicos IS 'Grupos econômicos que controlam gestoras e administradoras de fundos';
COMMENT ON COLUMN dim_grupos_economicos.tipo_grupo IS 'Tipo do grupo: Banco, Gestora Independente, Corretora, etc.';
COMMENT ON COLUMN dim_grupos_economicos.ranking_mercado IS 'Posição no ranking por patrimônio líquido total';
