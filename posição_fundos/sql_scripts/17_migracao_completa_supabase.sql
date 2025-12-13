-- ====================================================================
-- MIGRAÇÃO COMPLETA PARA NOVO SUPABASE
-- Script único para criar toda a estrutura em outro projeto
-- ====================================================================

-- INSTRUÇÕES:
-- 1. Copie este arquivo completo
-- 2. Cole no SQL Editor do NOVO projeto Supabase
-- 3. Execute (pode demorar alguns minutos)
-- 4. Após criar estrutura, use script de dados (18_exportar_dados.sql)

-- ====================================================================
-- BLOCO 1: DIMENSÕES
-- ====================================================================

-- dim_tempo
CREATE TABLE dim_tempo (
    id SERIAL PRIMARY KEY,
    data_completa DATE UNIQUE NOT NULL,
    ano INTEGER NOT NULL,
    trimestre INTEGER NOT NULL,
    mes INTEGER NOT NULL,
    mes_nome VARCHAR(20) NOT NULL,
    dia INTEGER NOT NULL,
    dia_semana INTEGER NOT NULL,
    dia_semana_nome VARCHAR(20) NOT NULL,
    fim_mes BOOLEAN DEFAULT FALSE,
    fim_trimestre BOOLEAN DEFAULT FALSE,
    fim_ano BOOLEAN DEFAULT FALSE,
    dia_util BOOLEAN DEFAULT TRUE,
    mes_anterior_id INTEGER,
    ano_anterior_id INTEGER,
    dt_criacao TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_tempo_data ON dim_tempo(data_completa);
CREATE INDEX idx_tempo_ano_mes ON dim_tempo(ano, mes);
CREATE INDEX idx_tempo_fim_mes ON dim_tempo(fim_mes) WHERE fim_mes = TRUE;

-- dim_grupos_economicos
CREATE TABLE dim_grupos_economicos (
    id SERIAL PRIMARY KEY,
    nome_grupo VARCHAR(200) NOT NULL,
    cnpj_principal VARCHAR(18),
    tipo_grupo VARCHAR(50),
    segmento VARCHAR(50),
    total_fundos INTEGER DEFAULT 0,
    total_pl DECIMAL(18,2) DEFAULT 0,
    ranking_mercado INTEGER,
    ativo BOOLEAN DEFAULT TRUE,
    dt_criacao TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    dt_ultima_atualizacao TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_grupo_nome ON dim_grupos_economicos(nome_grupo);
CREATE INDEX idx_grupo_tipo ON dim_grupos_economicos(tipo_grupo);
CREATE INDEX idx_grupo_ranking ON dim_grupos_economicos(ranking_mercado);
CREATE INDEX idx_grupo_ativo ON dim_grupos_economicos(ativo) WHERE ativo = TRUE;

-- dim_categoria_ativo
CREATE TABLE dim_categoria_ativo (
    id SERIAL PRIMARY KEY,
    nivel1_macro VARCHAR(50) NOT NULL,
    nivel2_tipo VARCHAR(100) NOT NULL,
    nivel3_subtipo VARCHAR(100),
    hierarquia_path VARCHAR(300),
    tp_aplic VARCHAR(100),
    tp_ativo VARCHAR(100),
    liquidez VARCHAR(20),
    risco VARCHAR(20),
    dt_criacao TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_categoria_nivel1 ON dim_categoria_ativo(nivel1_macro);
CREATE INDEX idx_categoria_nivel2 ON dim_categoria_ativo(nivel2_tipo);
CREATE INDEX idx_categoria_nivel3 ON dim_categoria_ativo(nivel3_subtipo);

-- dim_emissores
CREATE TABLE dim_emissores (
    id SERIAL PRIMARY KEY,
    cnpj_emissor VARCHAR(18),
    cpf_emissor VARCHAR(14),
    emissor_nome TEXT NOT NULL,
    emissor_nome_clean TEXT,
    pf_pj VARCHAR(2),
    tipo_emissor VARCHAR(50),
    setor_economia VARCHAR(100),
    rating VARCHAR(20),
    pais_origem VARCHAR(50) DEFAULT 'Brasil',
    ativo BOOLEAN DEFAULT TRUE,
    dt_criacao TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    dt_ultima_atualizacao TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_cnpj_cpf CHECK (cnpj_emissor IS NOT NULL OR cpf_emissor IS NOT NULL)
);

CREATE INDEX idx_emissor_cnpj ON dim_emissores(cnpj_emissor);
CREATE INDEX idx_emissor_nome ON dim_emissores(emissor_nome);
CREATE INDEX idx_emissor_tipo ON dim_emissores(tipo_emissor);

-- dim_ativos
CREATE TABLE dim_ativos (
    id SERIAL PRIMARY KEY,
    cd_ativo VARCHAR(50),
    ds_ativo TEXT,
    cd_isin VARCHAR(12),
    cd_selic VARCHAR(20),
    categoria_ativo_id INTEGER REFERENCES dim_categoria_ativo(id),
    emissor_id INTEGER REFERENCES dim_emissores(id),
    tp_titpub VARCHAR(50),
    dt_emissao DATE,
    dt_vencimento DATE,
    tipo_acao VARCHAR(10),
    segmento_listagem VARCHAR(50),
    ativo BOOLEAN DEFAULT TRUE,
    dt_criacao TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    dt_ultima_atualizacao TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_ativo_codigo ON dim_ativos(cd_ativo);
CREATE INDEX idx_ativo_isin ON dim_ativos(cd_isin);
CREATE INDEX idx_ativo_categoria ON dim_ativos(categoria_ativo_id);
CREATE INDEX idx_ativo_emissor ON dim_ativos(emissor_id);

-- dim_fundos
CREATE TABLE dim_fundos (
    id SERIAL PRIMARY KEY,
    cnpj_fundo_classe VARCHAR(18) NOT NULL,
    nome_fundo TEXT NOT NULL,
    nome_fundo_clean TEXT,
    tipo_fundo VARCHAR(50),
    tp_fundo_classe VARCHAR(100),
    grupo_economico_id INTEGER REFERENCES dim_grupos_economicos(id),
    categoria_anbima VARCHAR(100),
    classe_risco VARCHAR(20),
    publico_alvo VARCHAR(50),
    data_inicio DATE NOT NULL DEFAULT CURRENT_DATE,
    data_fim DATE,
    versao INTEGER DEFAULT 1,
    ativo BOOLEAN DEFAULT TRUE,
    dt_criacao TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    dt_ultima_atualizacao TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_fundo_cnpj ON dim_fundos(cnpj_fundo_classe);
CREATE INDEX idx_fundo_grupo ON dim_fundos(grupo_economico_id);
CREATE INDEX idx_fundo_ativo ON dim_fundos(ativo) WHERE ativo = TRUE;

-- dim_acoes_b3
CREATE TABLE dim_acoes_b3 (
    id SERIAL PRIMARY KEY,
    ticker VARCHAR(10) NOT NULL UNIQUE,
    ativo_id INTEGER REFERENCES dim_ativos(id),
    empresa_nome VARCHAR(200) NOT NULL,
    empresa_nome_curto VARCHAR(100),
    setor VARCHAR(100),
    subsetor VARCHAR(100),
    segmento_b3 VARCHAR(50),
    capitalizacao_faixa VARCHAR(20),
    liquidez_classificacao VARCHAR(20),
    volume_medio_diario DECIMAL(18,2),
    ibovespa BOOLEAN DEFAULT FALSE,
    ibrx100 BOOLEAN DEFAULT FALSE,
    small_caps BOOLEAN DEFAULT FALSE,
    idiv BOOLEAN DEFAULT FALSE,
    tipo_acao VARCHAR(10),
    tag_along_on DECIMAL(5,2),
    tag_along_pn DECIMAL(5,2),
    pagadora_dividendos BOOLEAN DEFAULT FALSE,
    dividend_yield_medio DECIMAL(8,4),
    nivel_governanca VARCHAR(50),
    categoria_analise VARCHAR(50),
    ativo BOOLEAN DEFAULT TRUE,
    dt_criacao TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    dt_ultima_atualizacao TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_acoes_ticker ON dim_acoes_b3(ticker);
CREATE INDEX idx_acoes_setor ON dim_acoes_b3(setor);
CREATE INDEX idx_acoes_cap_faixa ON dim_acoes_b3(capitalizacao_faixa);
CREATE INDEX idx_acoes_ibovespa ON dim_acoes_b3(ibovespa) WHERE ibovespa = TRUE;

-- dim_patrimonio_liquido
CREATE TABLE dim_patrimonio_liquido (
    id BIGSERIAL PRIMARY KEY,
    fundo_id INTEGER NOT NULL REFERENCES dim_fundos(id),
    data_id INTEGER NOT NULL REFERENCES dim_tempo(id),
    valor_pl DECIMAL(18,2) NOT NULL,
    dt_carga TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(fundo_id, data_id)
);

CREATE INDEX idx_pl_fundo_data ON dim_patrimonio_liquido(fundo_id, data_id);
CREATE INDEX idx_pl_data ON dim_patrimonio_liquido(data_id);


-- ====================================================================
-- BLOCO 2: TABELA FATO
-- ====================================================================

CREATE TABLE fato_posicoes (
    id BIGSERIAL PRIMARY KEY,
    fundo_id INTEGER NOT NULL REFERENCES dim_fundos(id),
    emissor_id INTEGER REFERENCES dim_emissores(id),
    ativo_id INTEGER REFERENCES dim_ativos(id),
    data_id INTEGER NOT NULL REFERENCES dim_tempo(id),
    categoria_ativo_id INTEGER NOT NULL REFERENCES dim_categoria_ativo(id),
    quantidade_posicao_final DECIMAL(18,6) DEFAULT 0,
    valor_mercado_posicao DECIMAL(18,2) DEFAULT 0,
    valor_custo_posicao DECIMAL(18,2) DEFAULT 0,
    quantidade_venda DECIMAL(18,6) DEFAULT 0,
    valor_venda DECIMAL(18,2) DEFAULT 0,
    quantidade_aquisicao DECIMAL(18,6) DEFAULT 0,
    valor_aquisicao DECIMAL(18,2) DEFAULT 0,
    percentual_pl DECIMAL(8,4),
    valor_lucro_prejuizo DECIMAL(18,2),
    rentabilidade_posicao DECIMAL(8,4),
    emissor_ligado BOOLEAN DEFAULT FALSE,
    ativo_confidencial BOOLEAN DEFAULT FALSE,
    dt_carga TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    origem_arquivo VARCHAR(50)
);

CREATE INDEX idx_fato_fundo_data ON fato_posicoes(fundo_id, data_id);
CREATE INDEX idx_fato_categoria_data ON fato_posicoes(categoria_ativo_id, data_id);
CREATE INDEX idx_fato_emissor_data ON fato_posicoes(emissor_id, data_id) WHERE emissor_id IS NOT NULL;
CREATE INDEX idx_fato_ativo_data ON fato_posicoes(ativo_id, data_id) WHERE ativo_id IS NOT NULL;
CREATE INDEX idx_fato_data ON fato_posicoes(data_id);


-- ====================================================================
-- BLOCO 3: RANKING TOP 100
-- ====================================================================

CREATE TABLE ranking_top100_grupos (
    id SERIAL PRIMARY KEY,
    ano INTEGER NOT NULL,
    mes INTEGER NOT NULL,
    data_referencia DATE NOT NULL,
    grupo_id INTEGER REFERENCES dim_grupos_economicos(id),
    nome_grupo VARCHAR(200) NOT NULL,
    tipo_grupo VARCHAR(50),
    patrimonio_liquido_total DECIMAL(18,2) NOT NULL,
    volume_compras DECIMAL(18,2) DEFAULT 0,
    volume_vendas DECIMAL(18,2) DEFAULT 0,
    volume_total_movimentado DECIMAL(18,2) GENERATED ALWAYS AS (volume_compras + volume_vendas) STORED,
    fluxo_liquido DECIMAL(18,2) GENERATED ALWAYS AS (volume_compras - volume_vendas) STORED,
    qtd_fundos INTEGER DEFAULT 0,
    qtd_posicoes_acoes INTEGER DEFAULT 0,
    valor_total_acoes DECIMAL(18,2) DEFAULT 0,
    ranking_patrimonio INTEGER NOT NULL,
    ranking_volume_movimentado INTEGER NOT NULL,
    ranking_fluxo_liquido INTEGER,
    tendencia_mes VARCHAR(20),
    percentual_pl_em_acoes DECIMAL(8,4),
    rentabilidade_media_acoes DECIMAL(8,4),
    lucro_prejuizo_total DECIMAL(18,2),
    rentabilidade_pl DECIMAL(8,4),
    performance_vs_ibov DECIMAL(8,4),
    melhor_acao_ticker VARCHAR(10),
    melhor_acao_rentabilidade DECIMAL(8,4),
    pior_acao_ticker VARCHAR(10),
    pior_acao_rentabilidade DECIMAL(8,4),
    dt_atualizacao TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(grupo_id, ano, mes)
);

CREATE INDEX idx_ranking_ano_mes ON ranking_top100_grupos(ano, mes);
CREATE INDEX idx_ranking_grupo ON ranking_top100_grupos(grupo_id);
CREATE INDEX idx_ranking_patrimonio ON ranking_top100_grupos(ranking_patrimonio);
CREATE INDEX idx_ranking_volume ON ranking_top100_grupos(ranking_volume_movimentado);


-- ====================================================================
-- BLOCO 4: VIEWS
-- ====================================================================

-- View: Top 100 Atual
CREATE OR REPLACE VIEW v_top100_atual AS
SELECT
    ranking_patrimonio,
    nome_grupo,
    tipo_grupo,
    patrimonio_liquido_total / 1000000000.0 AS pl_bilhoes,
    volume_total_movimentado / 1000000.0 AS volume_movimentado_milhoes,
    fluxo_liquido / 1000000.0 AS fluxo_liquido_milhoes,
    qtd_fundos,
    qtd_posicoes_acoes,
    valor_total_acoes / 1000000000.0 AS acoes_bilhoes,
    ROUND(percentual_pl_em_acoes, 2) AS perc_acoes,
    ROUND(rentabilidade_media_acoes, 2) AS rentabilidade_pct,
    tendencia_mes,
    ano,
    mes
FROM ranking_top100_grupos
WHERE (ano, mes) = (
    SELECT ano, mes FROM ranking_top100_grupos
    ORDER BY ano DESC, mes DESC LIMIT 1
)
ORDER BY ranking_patrimonio;

-- View: Dashboard com Rentabilidade
CREATE OR REPLACE VIEW v_dashboard_top100 AS
SELECT
    r.ranking_patrimonio,
    r.nome_grupo,
    r.tipo_grupo,
    r.patrimonio_liquido_total / 1000000000.0 AS pl_bilhoes,
    r.valor_total_acoes / 1000000000.0 AS acoes_bilhoes,
    r.percentual_pl_em_acoes AS perc_acoes,
    r.volume_total_movimentado / 1000000.0 AS volume_milhoes,
    r.fluxo_liquido / 1000000.0 AS fluxo_milhoes,
    r.tendencia_mes,
    ROUND(r.rentabilidade_media_acoes, 2) AS rentabilidade_pct,
    r.lucro_prejuizo_total / 1000000.0 AS lucro_milhoes,
    r.melhor_acao_ticker,
    ROUND(r.melhor_acao_rentabilidade, 2) AS melhor_acao_pct,
    r.qtd_fundos,
    r.ano,
    r.mes
FROM ranking_top100_grupos r
WHERE (ano, mes) = (
    SELECT ano, mes FROM ranking_top100_grupos
    ORDER BY ano DESC, mes DESC LIMIT 1
)
ORDER BY r.ranking_patrimonio;


-- ====================================================================
-- SUCESSO!
-- ====================================================================

-- Verificar tabelas criadas
SELECT
    table_name,
    (SELECT COUNT(*) FROM information_schema.columns WHERE table_name = t.table_name) AS colunas
FROM information_schema.tables t
WHERE table_schema = 'public'
  AND table_type = 'BASE TABLE'
ORDER BY table_name;

-- Próximo passo: Importar dados usando script 18_exportar_dados.sql
