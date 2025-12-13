-- ====================================================================
-- TABELA FATO - POSIÇÕES DE FUNDOS
-- Fato principal do modelo dimensional (Star Schema)
-- ====================================================================

CREATE TABLE fato_posicoes (
    id BIGSERIAL PRIMARY KEY,

    -- Chaves Dimensionais (Foreign Keys)
    fundo_id INTEGER NOT NULL REFERENCES dim_fundos(id),
    emissor_id INTEGER REFERENCES dim_emissores(id),
    ativo_id INTEGER REFERENCES dim_ativos(id),
    data_id INTEGER NOT NULL REFERENCES dim_tempo(id),
    categoria_ativo_id INTEGER NOT NULL REFERENCES dim_categoria_ativo(id),

    -- Métricas de Posição
    quantidade_posicao_final DECIMAL(18,6) DEFAULT 0,
    valor_mercado_posicao DECIMAL(18,2) DEFAULT 0,
    valor_custo_posicao DECIMAL(18,2) DEFAULT 0,

    -- Métricas de Movimentação
    quantidade_venda DECIMAL(18,6) DEFAULT 0,
    valor_venda DECIMAL(18,2) DEFAULT 0,
    quantidade_aquisicao DECIMAL(18,6) DEFAULT 0,
    valor_aquisicao DECIMAL(18,2) DEFAULT 0,

    -- Métricas Calculadas (Desnormalizadas para Performance)
    percentual_pl DECIMAL(8,4), -- % da posição em relação ao PL do fundo
    valor_lucro_prejuizo DECIMAL(18,2), -- valor_mercado - valor_custo
    rentabilidade_posicao DECIMAL(8,4), -- (valor_mercado / valor_custo - 1) * 100

    -- Flags
    emissor_ligado BOOLEAN DEFAULT FALSE, -- Emissor tem ligação com o fundo
    ativo_confidencial BOOLEAN DEFAULT FALSE, -- Dados confidenciais (agregados)

    -- Metadados
    dt_carga TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    origem_arquivo VARCHAR(50) -- Ex: 'BLC_1', 'BLC_4', 'CONFID'
);

-- Índices Compostos para Queries Comuns
CREATE INDEX idx_fato_fundo_data ON fato_posicoes(fundo_id, data_id);
CREATE INDEX idx_fato_categoria_data ON fato_posicoes(categoria_ativo_id, data_id);
CREATE INDEX idx_fato_emissor_data ON fato_posicoes(emissor_id, data_id) WHERE emissor_id IS NOT NULL;
CREATE INDEX idx_fato_ativo_data ON fato_posicoes(ativo_id, data_id) WHERE ativo_id IS NOT NULL;
CREATE INDEX idx_fato_data ON fato_posicoes(data_id);
CREATE INDEX idx_fato_origem ON fato_posicoes(origem_arquivo);

-- Índice para análises de volume
CREATE INDEX idx_fato_valor_mercado ON fato_posicoes(valor_mercado_posicao) WHERE valor_mercado_posicao > 0;

-- Comentários
COMMENT ON TABLE fato_posicoes IS 'Tabela fato principal com posições diárias/mensais dos fundos';
COMMENT ON COLUMN fato_posicoes.quantidade_posicao_final IS 'Quantidade de ativos na posição final';
COMMENT ON COLUMN fato_posicoes.valor_mercado_posicao IS 'Valor de mercado da posição (mark-to-market)';
COMMENT ON COLUMN fato_posicoes.valor_custo_posicao IS 'Valor de custo histórico da posição';
COMMENT ON COLUMN fato_posicoes.percentual_pl IS 'Percentual da posição em relação ao PL do fundo';
COMMENT ON COLUMN fato_posicoes.emissor_ligado IS 'TRUE se o emissor tem ligação com gestor/administrador';
COMMENT ON COLUMN fato_posicoes.ativo_confidencial IS 'TRUE se os dados foram agregados por confidencialidade';
