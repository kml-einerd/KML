-- ====================================================================
-- DIMENSÃO PATRIMÔNIO LÍQUIDO
-- Histórico de PL dos fundos (usado para calcular % das posições)
-- ====================================================================

CREATE TABLE dim_patrimonio_liquido (
    id BIGSERIAL PRIMARY KEY,

    -- Chaves
    fundo_id INTEGER NOT NULL REFERENCES dim_fundos(id),
    data_id INTEGER NOT NULL REFERENCES dim_tempo(id),

    -- Métricas
    valor_pl DECIMAL(18,2) NOT NULL,

    -- Controle
    dt_carga TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    -- Constraint de unicidade
    UNIQUE(fundo_id, data_id)
);

-- Índices
CREATE INDEX idx_pl_fundo_data ON dim_patrimonio_liquido(fundo_id, data_id);
CREATE INDEX idx_pl_data ON dim_patrimonio_liquido(data_id);

-- Comentários
COMMENT ON TABLE dim_patrimonio_liquido IS 'Histórico de patrimônio líquido dos fundos';
COMMENT ON COLUMN dim_patrimonio_liquido.valor_pl IS 'Valor do patrimônio líquido do fundo na data';
