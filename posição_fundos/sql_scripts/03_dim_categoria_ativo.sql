-- ====================================================================
-- DIMENSÃO CATEGORIA DE ATIVOS
-- Hierarquia de 3 níveis para classificação de ativos
-- ====================================================================

CREATE TABLE dim_categoria_ativo (
    id SERIAL PRIMARY KEY,

    -- Hierarquia de 3 Níveis
    nivel1_macro VARCHAR(50) NOT NULL, -- 'Renda Fixa', 'Renda Variável', 'Multimercado', 'Exterior'
    nivel2_tipo VARCHAR(100) NOT NULL, -- 'Títulos Públicos', 'Ações', 'Cotas de Fundos', etc.
    nivel3_subtipo VARCHAR(100), -- 'LFT', 'Ação ON', 'FI Renda Fixa', etc.

    -- Path Completo (facilita drill-down)
    hierarquia_path VARCHAR(300), -- 'Renda Fixa > Títulos Públicos > LFT'

    -- Classificação CVM
    tp_aplic VARCHAR(100), -- Tipo de aplicação conforme CVM
    tp_ativo VARCHAR(100), -- Tipo de ativo conforme CVM

    -- Características
    liquidez VARCHAR(20), -- 'Alta', 'Média', 'Baixa'
    risco VARCHAR(20), -- 'Baixo', 'Médio', 'Alto'

    -- Controle
    dt_criacao TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Índices
CREATE INDEX idx_categoria_nivel1 ON dim_categoria_ativo(nivel1_macro);
CREATE INDEX idx_categoria_nivel2 ON dim_categoria_ativo(nivel2_tipo);
CREATE INDEX idx_categoria_nivel3 ON dim_categoria_ativo(nivel3_subtipo);
CREATE INDEX idx_categoria_path ON dim_categoria_ativo(hierarquia_path);

-- Comentários
COMMENT ON TABLE dim_categoria_ativo IS 'Hierarquia de categorização de ativos (3 níveis)';
COMMENT ON COLUMN dim_categoria_ativo.nivel1_macro IS 'Nível 1: Macro categoria (Renda Fixa, Renda Variável, etc.)';
COMMENT ON COLUMN dim_categoria_ativo.nivel2_tipo IS 'Nível 2: Tipo de ativo (Títulos Públicos, Ações, etc.)';
COMMENT ON COLUMN dim_categoria_ativo.nivel3_subtipo IS 'Nível 3: Subtipo detalhado (LFT, Ação ON, etc.)';
COMMENT ON COLUMN dim_categoria_ativo.hierarquia_path IS 'Caminho completo da hierarquia para facilitar drill-down';
