-- ====================================================================
-- DIMENSÃO TEMPO
-- Tabela de dimensão temporal completa para análise de séries históricas
-- ====================================================================

CREATE TABLE dim_tempo (
    id SERIAL PRIMARY KEY,
    data_completa DATE UNIQUE NOT NULL,

    -- Componentes da Data
    ano INTEGER NOT NULL,
    trimestre INTEGER NOT NULL,
    mes INTEGER NOT NULL,
    mes_nome VARCHAR(20) NOT NULL,
    dia INTEGER NOT NULL,
    dia_semana INTEGER NOT NULL,
    dia_semana_nome VARCHAR(20) NOT NULL,

    -- Flags Úteis
    fim_mes BOOLEAN DEFAULT FALSE,
    fim_trimestre BOOLEAN DEFAULT FALSE,
    fim_ano BOOLEAN DEFAULT FALSE,
    dia_util BOOLEAN DEFAULT TRUE,

    -- Para Comparações Temporais
    mes_anterior_id INTEGER,
    ano_anterior_id INTEGER,

    -- Metadados
    dt_criacao TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Índices
CREATE INDEX idx_tempo_data ON dim_tempo(data_completa);
CREATE INDEX idx_tempo_ano_mes ON dim_tempo(ano, mes);
CREATE INDEX idx_tempo_fim_mes ON dim_tempo(fim_mes) WHERE fim_mes = TRUE;

-- Comentários
COMMENT ON TABLE dim_tempo IS 'Dimensão temporal para análise de séries históricas de posições de fundos';
COMMENT ON COLUMN dim_tempo.data_completa IS 'Data completa (formato YYYY-MM-DD)';
COMMENT ON COLUMN dim_tempo.fim_mes IS 'TRUE se é o último dia do mês (usado para posições mensais da CVM)';
