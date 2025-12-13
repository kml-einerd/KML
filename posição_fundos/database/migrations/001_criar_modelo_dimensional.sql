-- ========================================
-- MIGRAÇÃO 001: Modelo Dimensional
-- Descrição: Cria estrutura dimensional otimizada para analytics
-- Data: 2025-12-11
-- ========================================

-- ========================================
-- 1. DIMENSÕES
-- ========================================

-- Dimensão Tempo (completa)
CREATE TABLE IF NOT EXISTS dim_tempo (
    id SERIAL PRIMARY KEY,
    data_completa DATE UNIQUE NOT NULL,

    -- Componentes temporais
    ano INTEGER NOT NULL,
    trimestre INTEGER NOT NULL,
    mes INTEGER NOT NULL,
    mes_nome VARCHAR(20) NOT NULL,
    dia INTEGER NOT NULL,
    dia_semana INTEGER NOT NULL,
    dia_semana_nome VARCHAR(20) NOT NULL,
    semana_ano INTEGER NOT NULL,

    -- Flags de períodos
    fim_mes BOOLEAN DEFAULT FALSE,
    fim_trimestre BOOLEAN DEFAULT FALSE,
    fim_semestre BOOLEAN DEFAULT FALSE,
    fim_ano BOOLEAN DEFAULT FALSE,
    dia_util BOOLEAN DEFAULT TRUE,

    -- Períodos relativos (para comparações)
    mes_anterior_id INTEGER,
    ano_anterior_id INTEGER,

    -- Metadados
    dt_criacao TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_dim_tempo_data ON dim_tempo(data_completa);
CREATE INDEX idx_dim_tempo_ano_mes ON dim_tempo(ano, mes);
CREATE INDEX idx_dim_tempo_fim_mes ON dim_tempo(fim_mes) WHERE fim_mes = TRUE;

COMMENT ON TABLE dim_tempo IS 'Dimensão temporal completa para análises time-series';

-- Dimensão Grupos Econômicos
CREATE TABLE IF NOT EXISTS dim_grupos_economicos (
    id SERIAL PRIMARY KEY,
    nome_grupo VARCHAR(200) NOT NULL UNIQUE,
    cnpj_principal VARCHAR(18),
    tipo_grupo VARCHAR(50), -- 'Banco', 'Gestora Independente', 'Corretora', 'Asset Manager'
    segmento VARCHAR(50), -- 'Varejo', 'Private', 'Corporativo', 'Institucional'

    -- Classificação
    categoria VARCHAR(50), -- 'Grande', 'Médio', 'Pequeno'
    origem VARCHAR(50), -- 'Nacional', 'Estrangeiro'

    -- Métricas agregadas (desnormalizadas para performance)
    total_fundos INTEGER DEFAULT 0,
    total_pl DECIMAL(18,2) DEFAULT 0,
    ranking_mercado INTEGER,

    -- Controle
    ativo BOOLEAN DEFAULT TRUE,
    dt_cadastro TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    dt_ultima_atualizacao TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT chk_tipo_grupo CHECK (tipo_grupo IN ('Banco', 'Gestora Independente', 'Corretora', 'Asset Manager', 'Outro'))
);

CREATE INDEX idx_dim_grupos_nome ON dim_grupos_economicos(nome_grupo);
CREATE INDEX idx_dim_grupos_tipo ON dim_grupos_economicos(tipo_grupo);
CREATE INDEX idx_dim_grupos_ranking ON dim_grupos_economicos(ranking_mercado);
CREATE INDEX idx_dim_grupos_ativo ON dim_grupos_economicos(ativo) WHERE ativo = TRUE;

COMMENT ON TABLE dim_grupos_economicos IS 'Grupos econômicos/gestoras responsáveis pelos fundos';

-- Dimensão Gestores
CREATE TABLE IF NOT EXISTS dim_gestores (
    id SERIAL PRIMARY KEY,
    cnpj_gestor VARCHAR(18) UNIQUE NOT NULL,
    nome_gestor VARCHAR(300) NOT NULL,
    grupo_economico_id INTEGER REFERENCES dim_grupos_economicos(id),

    -- Classificação
    tipo_gestor VARCHAR(50), -- 'Autônomo', 'Vinculado a Banco', 'Independente'
    porte VARCHAR(20), -- 'Grande', 'Médio', 'Pequeno'

    -- Estatísticas
    total_pl_gerido DECIMAL(18,2),
    qtd_fundos INTEGER DEFAULT 0,

    -- Controle
    ativo BOOLEAN DEFAULT TRUE,
    dt_registro_cvm DATE,
    dt_cadastro TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    dt_ultima_atualizacao TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_dim_gestores_cnpj ON dim_gestores(cnpj_gestor);
CREATE INDEX idx_dim_gestores_grupo ON dim_gestores(grupo_economico_id);
CREATE INDEX idx_dim_gestores_ativo ON dim_gestores(ativo) WHERE ativo = TRUE;

COMMENT ON TABLE dim_gestores IS 'Gestores de fundos de investimento';

-- Dimensão Administradores
CREATE TABLE IF NOT EXISTS dim_administradores (
    id SERIAL PRIMARY KEY,
    cnpj_administrador VARCHAR(18) UNIQUE NOT NULL,
    nome_administrador VARCHAR(300) NOT NULL,
    grupo_economico_id INTEGER REFERENCES dim_grupos_economicos(id),

    -- Estatísticas
    qtd_fundos_administrados INTEGER DEFAULT 0,

    -- Controle
    ativo BOOLEAN DEFAULT TRUE,
    dt_cadastro TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    dt_ultima_atualizacao TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_dim_administradores_cnpj ON dim_administradores(cnpj_administrador);
CREATE INDEX idx_dim_administradores_grupo ON dim_administradores(grupo_economico_id);

COMMENT ON TABLE dim_administradores IS 'Administradores de fundos de investimento';

-- Dimensão Fundos (SCD Type 2)
CREATE TABLE IF NOT EXISTS dim_fundos (
    id SERIAL PRIMARY KEY,
    cnpj_fundo_classe VARCHAR(18) NOT NULL,
    nome_fundo TEXT NOT NULL,
    nome_fundo_clean TEXT, -- versão normalizada sem caracteres especiais

    -- Tipo e Classe
    tipo_fundo_classe VARCHAR(100), -- 'CLASSES - FIF', 'CLASSES - FIP', etc.
    classe_cvm VARCHAR(100),
    categoria_anbima VARCHAR(100),

    -- Relacionamentos
    gestor_id INTEGER REFERENCES dim_gestores(id),
    administrador_id INTEGER REFERENCES dim_administradores(id),
    grupo_economico_id INTEGER REFERENCES dim_grupos_economicos(id),

    -- Classificações
    classe_risco VARCHAR(20), -- 'Baixo', 'Médio', 'Alto'
    publico_alvo VARCHAR(50), -- 'Varejo', 'Qualificado', 'Profissional'
    regime_tributario VARCHAR(50), -- 'Curto Prazo', 'Longo Prazo'

    -- SCD Type 2 - Controle de versões
    data_inicio DATE NOT NULL,
    data_fim DATE,
    versao INTEGER DEFAULT 1,
    ativo BOOLEAN DEFAULT TRUE,

    -- Metadados
    dt_cadastro TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    dt_ultima_atualizacao TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT chk_dim_fundos_datas CHECK (data_fim IS NULL OR data_fim > data_inicio)
);

-- Índices para busca e JOIN
CREATE INDEX idx_dim_fundos_cnpj ON dim_fundos(cnpj_fundo_classe);
CREATE INDEX idx_dim_fundos_ativo ON dim_fundos(ativo) WHERE ativo = TRUE;
CREATE INDEX idx_dim_fundos_gestor ON dim_fundos(gestor_id);
CREATE INDEX idx_dim_fundos_grupo ON dim_fundos(grupo_economico_id);
CREATE INDEX idx_dim_fundos_tipo ON dim_fundos(tipo_fundo_classe);
CREATE INDEX idx_dim_fundos_categoria ON dim_fundos(categoria_anbima);
CREATE UNIQUE INDEX idx_dim_fundos_scd ON dim_fundos(cnpj_fundo_classe, data_inicio);

COMMENT ON TABLE dim_fundos IS 'Fundos de investimento com versionamento SCD Type 2';

-- Dimensão Categoria de Ativo (Hierárquica)
CREATE TABLE IF NOT EXISTS dim_categoria_ativo (
    id SERIAL PRIMARY KEY,

    -- Hierarquia de 3 níveis
    nivel1_macro VARCHAR(50) NOT NULL, -- Ex: 'Renda Fixa', 'Renda Variável', 'Multimercado'
    nivel2_tipo VARCHAR(100) NOT NULL, -- Ex: 'Títulos Públicos', 'Ações', 'Fundos'
    nivel3_subtipo VARCHAR(100), -- Ex: 'LFT', 'Ação ON', 'FI Renda Fixa'

    -- Path para drill-down
    hierarquia_path VARCHAR(300), -- 'Renda Fixa > Títulos Públicos > LFT'

    -- Mapeamento CVM
    tp_aplic VARCHAR(100), -- Tipo de aplicação CVM
    tp_ativo_cvm VARCHAR(100), -- Tipo de ativo CVM

    -- Características
    liquidez VARCHAR(20), -- 'Alta', 'Média', 'Baixa', 'Muito Baixa'
    nivel_risco VARCHAR(20), -- 'Baixo', 'Médio', 'Alto', 'Muito Alto'
    indexador_principal VARCHAR(50), -- 'CDI', 'IPCA', 'PRÉ', 'IGPM', etc.

    -- Metadados
    descricao TEXT,
    dt_cadastro TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT uq_categoria_path UNIQUE (hierarquia_path)
);

CREATE INDEX idx_dim_categoria_nivel1 ON dim_categoria_ativo(nivel1_macro);
CREATE INDEX idx_dim_categoria_nivel2 ON dim_categoria_ativo(nivel2_tipo);
CREATE INDEX idx_dim_categoria_nivel3 ON dim_categoria_ativo(nivel3_subtipo);
CREATE INDEX idx_dim_categoria_tp_aplic ON dim_categoria_ativo(tp_aplic);

COMMENT ON TABLE dim_categoria_ativo IS 'Hierarquia de categorias de ativos para drill-down';

-- Dimensão Emissores
CREATE TABLE IF NOT EXISTS dim_emissores (
    id SERIAL PRIMARY KEY,
    cpf_cnpj_emissor VARCHAR(18),
    emissor_nome VARCHAR(500) NOT NULL,
    emissor_nome_clean VARCHAR(500), -- normalizado
    pf_pj_emissor VARCHAR(2), -- 'PF' ou 'PJ'

    -- Classificação
    setor_economico VARCHAR(100),
    segmento VARCHAR(100),
    rating VARCHAR(20),

    -- Controle
    ativo BOOLEAN DEFAULT TRUE,
    dt_cadastro TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    dt_ultima_atualizacao TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT chk_pf_pj CHECK (pf_pj_emissor IN ('PF', 'PJ'))
);

CREATE INDEX idx_dim_emissores_cpf_cnpj ON dim_emissores(cpf_cnpj_emissor);
CREATE INDEX idx_dim_emissores_nome ON dim_emissores(emissor_nome_clean);
CREATE INDEX idx_dim_emissores_tipo ON dim_emissores(pf_pj_emissor);
CREATE INDEX idx_dim_emissores_ativo ON dim_emissores(ativo) WHERE ativo = TRUE;

COMMENT ON TABLE dim_emissores IS 'Emissores de ativos (empresas, instituições financeiras)';

-- Dimensão Ativos
CREATE TABLE IF NOT EXISTS dim_ativos (
    id SERIAL PRIMARY KEY,
    cd_ativo VARCHAR(50),
    ds_ativo VARCHAR(500),
    cd_isin VARCHAR(50),
    cd_selic VARCHAR(50),

    -- Relacionamento
    categoria_ativo_id INTEGER REFERENCES dim_categoria_ativo(id),
    emissor_id INTEGER REFERENCES dim_emissores(id),

    -- Características específicas
    tp_titulo_publico VARCHAR(50), -- para títulos públicos
    indexador VARCHAR(50),
    taxa_cupom DECIMAL(8,4),

    -- Datas
    dt_emissao DATE,
    dt_vencimento DATE,

    -- Controle
    ativo BOOLEAN DEFAULT TRUE,
    dt_cadastro TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    dt_ultima_atualizacao TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_dim_ativos_codigo ON dim_ativos(cd_ativo);
CREATE INDEX idx_dim_ativos_isin ON dim_ativos(cd_isin);
CREATE INDEX idx_dim_ativos_categoria ON dim_ativos(categoria_ativo_id);
CREATE INDEX idx_dim_ativos_emissor ON dim_ativos(emissor_id);
CREATE INDEX idx_dim_ativos_ativo ON dim_ativos(ativo) WHERE ativo = TRUE;

COMMENT ON TABLE dim_ativos IS 'Ativos financeiros (títulos, ações, cotas, etc.)';

-- ========================================
-- 2. TABELA FATO
-- ========================================

CREATE TABLE IF NOT EXISTS fato_posicoes (
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
    percentual_pl DECIMAL(8,4) DEFAULT 0, -- % da posição em relação ao PL do fundo
    valor_lucro_prejuizo DECIMAL(18,2) DEFAULT 0, -- valor_mercado - valor_custo
    rentabilidade_posicao DECIMAL(8,4) DEFAULT 0, -- (valor_mercado / valor_custo - 1) * 100

    -- Flags e Classificações
    emissor_ligado BOOLEAN DEFAULT FALSE,
    tipo_negociacao VARCHAR(50), -- 'Para negociação', 'Até o vencimento', etc.
    ativo_confidencial BOOLEAN DEFAULT FALSE,

    -- Características específicas (podem ser NULL dependendo do tipo)
    prazo_vencimento_dias INTEGER,
    indexador VARCHAR(50),
    percentual_indexador DECIMAL(8,4),
    taxa_prefixada DECIMAL(8,4),

    -- Metadados
    dt_carga TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    hash_dedup VARCHAR(64), -- para evitar duplicatas

    -- Constraints
    CONSTRAINT chk_valores_positivos CHECK (
        valor_mercado_posicao >= 0 AND
        valor_custo_posicao >= 0 AND
        quantidade_posicao_final >= 0
    )
);

-- Índices estratégicos para queries comuns
CREATE INDEX idx_fato_posicoes_fundo_data ON fato_posicoes(fundo_id, data_id);
CREATE INDEX idx_fato_posicoes_categoria_data ON fato_posicoes(categoria_ativo_id, data_id);
CREATE INDEX idx_fato_posicoes_emissor_data ON fato_posicoes(emissor_id, data_id);
CREATE INDEX idx_fato_posicoes_ativo_data ON fato_posicoes(ativo_id, data_id);
CREATE INDEX idx_fato_posicoes_data ON fato_posicoes(data_id);
CREATE INDEX idx_fato_posicoes_hash ON fato_posicoes(hash_dedup);
CREATE INDEX idx_fato_posicoes_valor_mercado ON fato_posicoes(valor_mercado_posicao) WHERE valor_mercado_posicao > 0;

COMMENT ON TABLE fato_posicoes IS 'Tabela fato com todas as posições dos fundos';

-- Tabela auxiliar de Patrimônio Líquido (snapshot mensal)
CREATE TABLE IF NOT EXISTS fato_patrimonio_liquido (
    id SERIAL PRIMARY KEY,
    fundo_id INTEGER NOT NULL REFERENCES dim_fundos(id),
    data_id INTEGER NOT NULL REFERENCES dim_tempo(id),
    vl_patrim_liq DECIMAL(18,2) NOT NULL,

    -- Métricas derivadas
    variacao_pl_mes DECIMAL(18,2),
    variacao_pl_mes_pct DECIMAL(8,4),

    dt_carga TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    UNIQUE(fundo_id, data_id)
);

CREATE INDEX idx_fato_pl_fundo_data ON fato_patrimonio_liquido(fundo_id, data_id);
CREATE INDEX idx_fato_pl_data ON fato_patrimonio_liquido(data_id);

COMMENT ON TABLE fato_patrimonio_liquido IS 'Patrimônio líquido dos fundos (snapshot mensal)';

-- ========================================
-- 3. FUNÇÕES AUXILIARES
-- ========================================

-- Função para popular dimensão tempo
CREATE OR REPLACE FUNCTION popular_dim_tempo(
    data_inicio DATE,
    data_fim DATE
) RETURNS INTEGER AS $$
DECLARE
    dt DATE;
    qtd INTEGER := 0;
BEGIN
    dt := data_inicio;

    WHILE dt <= data_fim LOOP
        INSERT INTO dim_tempo (
            data_completa, ano, trimestre, mes, mes_nome, dia,
            dia_semana, dia_semana_nome, semana_ano,
            fim_mes, fim_trimestre, fim_semestre, fim_ano
        ) VALUES (
            dt,
            EXTRACT(YEAR FROM dt)::INTEGER,
            EXTRACT(QUARTER FROM dt)::INTEGER,
            EXTRACT(MONTH FROM dt)::INTEGER,
            TO_CHAR(dt, 'TMMonth'),
            EXTRACT(DAY FROM dt)::INTEGER,
            EXTRACT(ISODOW FROM dt)::INTEGER,
            TO_CHAR(dt, 'TMDay'),
            EXTRACT(WEEK FROM dt)::INTEGER,
            dt = (DATE_TRUNC('MONTH', dt) + INTERVAL '1 month - 1 day')::DATE,
            dt = (DATE_TRUNC('QUARTER', dt) + INTERVAL '3 months - 1 day')::DATE,
            dt = (DATE_TRUNC('YEAR', dt) + INTERVAL '6 months - 1 day')::DATE,
            dt = (DATE_TRUNC('YEAR', dt) + INTERVAL '1 year - 1 day')::DATE
        )
        ON CONFLICT (data_completa) DO NOTHING;

        qtd := qtd + 1;
        dt := dt + INTERVAL '1 day';
    END LOOP;

    -- Atualizar referências de períodos anteriores
    UPDATE dim_tempo t1
    SET mes_anterior_id = t2.id,
        ano_anterior_id = t3.id
    FROM dim_tempo t2, dim_tempo t3
    WHERE t2.data_completa = t1.data_completa - INTERVAL '1 month'
      AND t3.data_completa = t1.data_completa - INTERVAL '1 year';

    RETURN qtd;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION popular_dim_tempo IS 'Popula a dimensão tempo com datas entre início e fim';

-- Popular dimensão tempo com 5 anos de dados
SELECT popular_dim_tempo('2020-01-01'::DATE, '2030-12-31'::DATE);

-- ========================================
-- 4. GRANTS (ajustar conforme necessário)
-- ========================================

-- Conceder permissões de leitura para role de analytics
-- GRANT SELECT ON ALL TABLES IN SCHEMA public TO analytics_user;

-- ========================================
-- FIM DA MIGRAÇÃO 001
-- ========================================
