-- ====================================================================
-- DIMENSÃO AÇÕES B3 - Categorização Detalhada de Ações Brasileiras
-- Classificação por setor, tamanho, liquidez e índices
-- ====================================================================

CREATE TABLE dim_acoes_b3 (
    id SERIAL PRIMARY KEY,

    -- Identificação
    ticker VARCHAR(10) NOT NULL UNIQUE, -- PETR4, VALE3, ITUB4, etc.
    ativo_id INTEGER REFERENCES dim_ativos(id), -- Link com dim_ativos
    empresa_nome VARCHAR(200) NOT NULL,
    empresa_nome_curto VARCHAR(100),

    -- SETOR E SEGMENTO (Classificação B3/Economatica)
    setor VARCHAR(100), -- Ex: 'Petróleo e Gás', 'Bancos', 'Varejo', etc.
    subsetor VARCHAR(100), -- Ex: 'Exploração e Refino', 'Bancos Comerciais', etc.
    segmento_b3 VARCHAR(50), -- 'Novo Mercado', 'Nível 1', 'Nível 2', 'Tradicional'

    -- TAMANHO DA EMPRESA (Market Cap)
    capitalizacao_faixa VARCHAR(20), -- 'Large Cap', 'Mid Cap', 'Small Cap'
    -- Large Cap: > R$ 10 bi
    -- Mid Cap: R$ 1 bi - R$ 10 bi
    -- Small Cap: < R$ 1 bi

    -- LIQUIDEZ
    liquidez_classificacao VARCHAR(20), -- 'Alta', 'Média', 'Baixa'
    volume_medio_diario DECIMAL(18,2), -- Volume médio negociado/dia (últimos 30 dias)

    -- ÍNDICES QUE COMPÕEM
    ibovespa BOOLEAN DEFAULT FALSE, -- Faz parte do IBOV?
    ibrx100 BOOLEAN DEFAULT FALSE, -- Faz parte do IBrX 100?
    small_caps BOOLEAN DEFAULT FALSE, -- Faz parte do SMLL (Small Caps)?
    idiv BOOLEAN DEFAULT FALSE, -- Faz parte do IDIV (Dividendos)?
    ifix BOOLEAN DEFAULT FALSE, -- Para FIIs
    icon BOOLEAN DEFAULT FALSE, -- ICON (Consumo)
    iee BOOLEAN DEFAULT FALSE, -- IEE (Energia Elétrica)
    ifnc BOOLEAN DEFAULT FALSE, -- IFNC (Financeiro)
    imat BOOLEAN DEFAULT FALSE, -- IMAT (Materiais Básicos)
    imob BOOLEAN DEFAULT FALSE, -- IMOB (Imobiliário)
    indx BOOLEAN DEFAULT FALSE, -- INDX (Industrial)
    util BOOLEAN DEFAULT FALSE, -- UTIL (Utilidade Pública)

    -- TIPO DE AÇÃO
    tipo_acao VARCHAR(10), -- 'ON', 'PN', 'UNIT'
    tag_along_on DECIMAL(5,2), -- % de tag along para ON
    tag_along_pn DECIMAL(5,2), -- % de tag along para PN

    -- CARACTERÍSTICAS
    pagadora_dividendos BOOLEAN DEFAULT FALSE,
    dividend_yield_medio DECIMAL(8,4), -- DY médio (últimos 12 meses)

    -- GOVERNANÇA
    nivel_governanca VARCHAR(50), -- 'Novo Mercado', 'Nível 1', 'Nível 2', 'Tradicional', 'Bovespa Mais'

    -- CATEGORIA PARA ANÁLISE (simplificada)
    categoria_analise VARCHAR(50), -- 'Blue Chip', 'Growth', 'Value', 'Especulativa'

    -- Controle
    ativo BOOLEAN DEFAULT TRUE,
    dt_criacao TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    dt_ultima_atualizacao TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Índices
CREATE INDEX idx_acoes_ticker ON dim_acoes_b3(ticker);
CREATE INDEX idx_acoes_setor ON dim_acoes_b3(setor);
CREATE INDEX idx_acoes_subsetor ON dim_acoes_b3(subsetor);
CREATE INDEX idx_acoes_cap_faixa ON dim_acoes_b3(capitalizacao_faixa);
CREATE INDEX idx_acoes_liquidez ON dim_acoes_b3(liquidez_classificacao);
CREATE INDEX idx_acoes_ibovespa ON dim_acoes_b3(ibovespa) WHERE ibovespa = TRUE;
CREATE INDEX idx_acoes_categoria ON dim_acoes_b3(categoria_analise);
CREATE INDEX idx_acoes_ativo ON dim_acoes_b3(ativo) WHERE ativo = TRUE;

-- Comentários
COMMENT ON TABLE dim_acoes_b3 IS 'Classificação detalhada de ações brasileiras para análise';
COMMENT ON COLUMN dim_acoes_b3.ticker IS 'Código de negociação na B3 (ex: PETR4, VALE3)';
COMMENT ON COLUMN dim_acoes_b3.capitalizacao_faixa IS 'Large Cap (>10bi), Mid Cap (1-10bi), Small Cap (<1bi)';
COMMENT ON COLUMN dim_acoes_b3.liquidez_classificacao IS 'Alta, Média ou Baixa (baseado em volume diário)';
COMMENT ON COLUMN dim_acoes_b3.categoria_analise IS 'Blue Chip, Growth, Value ou Especulativa';
COMMENT ON COLUMN dim_acoes_b3.dividend_yield_medio IS 'Dividend Yield médio dos últimos 12 meses (%)';


-- ====================================================================
-- DADOS DE EXEMPLO - Principais Ações B3
-- ====================================================================

INSERT INTO dim_acoes_b3 (
    ticker, empresa_nome, empresa_nome_curto, setor, subsetor, segmento_b3,
    capitalizacao_faixa, liquidez_classificacao, volume_medio_diario,
    ibovespa, ibrx100, tipo_acao, nivel_governanca, categoria_analise,
    pagadora_dividendos, dividend_yield_medio
) VALUES
-- Blue Chips - Bancos
('ITUB4', 'Itaú Unibanco Holding S.A.', 'Itaú', 'Bancos', 'Bancos Comerciais', 'Nível 1',
 'Large Cap', 'Alta', 450000000.00, TRUE, TRUE, 'PN', 'Nível 1', 'Blue Chip', TRUE, 5.20),

('BBDC4', 'Banco Bradesco S.A.', 'Bradesco', 'Bancos', 'Bancos Comerciais', 'Nível 1',
 'Large Cap', 'Alta', 380000000.00, TRUE, TRUE, 'PN', 'Nível 1', 'Blue Chip', TRUE, 6.80),

('BBAS3', 'Banco do Brasil S.A.', 'Banco do Brasil', 'Bancos', 'Bancos Comerciais', 'Novo Mercado',
 'Large Cap', 'Alta', 320000000.00, TRUE, TRUE, 'ON', 'Novo Mercado', 'Blue Chip', TRUE, 7.50),

('SANB11', 'Banco Santander Brasil S.A.', 'Santander', 'Bancos', 'Bancos Comerciais', 'Nível 2',
 'Large Cap', 'Alta', 180000000.00, TRUE, TRUE, 'UNIT', 'Nível 2', 'Blue Chip', TRUE, 6.20),

-- Petróleo e Gás
('PETR4', 'Petróleo Brasileiro S.A.', 'Petrobras', 'Petróleo e Gás', 'Exploração e Refino', 'Tradicional',
 'Large Cap', 'Alta', 1200000000.00, TRUE, TRUE, 'PN', 'Tradicional', 'Blue Chip', TRUE, 14.50),

('PETR3', 'Petróleo Brasileiro S.A.', 'Petrobras', 'Petróleo e Gás', 'Exploração e Refino', 'Tradicional',
 'Large Cap', 'Alta', 850000000.00, TRUE, TRUE, 'ON', 'Tradicional', 'Blue Chip', TRUE, 15.20),

-- Mineração
('VALE3', 'Vale S.A.', 'Vale', 'Mineração', 'Mineração Metálica', 'Novo Mercado',
 'Large Cap', 'Alta', 980000000.00, TRUE, TRUE, 'ON', 'Novo Mercado', 'Blue Chip', TRUE, 10.30),

-- Varejo
('MGLU3', 'Magazine Luiza S.A.', 'Magazine Luiza', 'Varejo', 'Varejo de Linha Dura', 'Novo Mercado',
 'Mid Cap', 'Alta', 280000000.00, TRUE, TRUE, 'ON', 'Novo Mercado', 'Growth', FALSE, 0.00),

('LREN3', 'Lojas Renner S.A.', 'Renner', 'Varejo', 'Varejo de Vestuário', 'Novo Mercado',
 'Mid Cap', 'Média', 120000000.00, TRUE, TRUE, 'ON', 'Novo Mercado', 'Value', TRUE, 3.20),

-- Alimentos
('ABEV3', 'Ambev S.A.', 'Ambev', 'Alimentos', 'Bebidas', 'Nível 1',
 'Large Cap', 'Alta', 340000000.00, TRUE, TRUE, 'ON', 'Nível 1', 'Blue Chip', TRUE, 4.80),

-- Frigoríficos
('BEEF3', 'Minerva S.A.', 'Minerva', 'Alimentos', 'Frigoríficos', 'Novo Mercado',
 'Small Cap', 'Média', 45000000.00, FALSE, TRUE, 'ON', 'Novo Mercado', 'Value', FALSE, 0.00),

-- Máquinas e Equipamentos
('ROMI3', 'Indústrias Romi S.A.', 'Romi', 'Máquinas e Equipamentos', 'Máquinas e Ferramentas', 'Novo Mercado',
 'Small Cap', 'Baixa', 8000000.00, FALSE, FALSE, 'ON', 'Novo Mercado', 'Especulativa', TRUE, 2.50),

-- Defesa
('TASA4', 'Taurus Armas S.A.', 'Taurus', 'Defesa e Segurança', 'Armas e Munições', 'Novo Mercado',
 'Small Cap', 'Média', 12000000.00, FALSE, TRUE, 'PN', 'Novo Mercado', 'Especulativa', FALSE, 0.00),

-- Logística
('VAMO3', 'Vamos Locação de Caminhões S.A.', 'Vamos', 'Logística', 'Aluguel de Veículos', 'Novo Mercado',
 'Mid Cap', 'Média', 55000000.00, FALSE, TRUE, 'ON', 'Novo Mercado', 'Growth', FALSE, 0.00);


-- ====================================================================
-- COMENTÁRIOS SOBRE CRITÉRIOS DE CLASSIFICAÇÃO
-- ====================================================================

/*
SETOR: Classificação baseada na B3 e Economatica
- Bancos, Petróleo e Gás, Mineração, Varejo, Alimentos, etc.

CAPITALIZAÇÃO:
- Large Cap: Market Cap > R$ 10 bilhões
- Mid Cap: Market Cap entre R$ 1 bi e R$ 10 bi
- Small Cap: Market Cap < R$ 1 bilhão

LIQUIDEZ:
- Alta: Volume médio diário > R$ 100 milhões
- Média: Volume entre R$ 10 mi e R$ 100 mi
- Baixa: Volume < R$ 10 milhões

CATEGORIA DE ANÁLISE:
- Blue Chip: Large caps consolidadas, alta liquidez, dividendos consistentes
- Growth: Empresas em crescimento, foco em expansão
- Value: Empresas subvalorizadas, bons fundamentos
- Especulativa: Small caps voláteis, maior risco

ÍNDICES:
- IBOVESPA: Principal índice da bolsa brasileira
- IBrX 100: Top 100 ações mais negociadas
- SMLL: Small Caps
- IDIV: Maiores pagadoras de dividendos
*/
