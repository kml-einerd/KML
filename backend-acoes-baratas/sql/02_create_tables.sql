-- ============================================
-- Script para CRIAR tabelas no formato brapi.dev
-- Execute no Supabase SQL Editor APÓS executar 01_drop_tables.sql
-- ============================================

-- Tabela de Ações (informações básicas)
CREATE TABLE acoes (
    id BIGSERIAL PRIMARY KEY,

    -- Identificação
    ticker TEXT NOT NULL UNIQUE,  -- Ex: PETR4
    symbol TEXT,                   -- Ex: PETR4 (mesmo que ticker na brapi)
    nome_curto TEXT,              -- shortName
    nome_longo TEXT,              -- longName

    -- Classificação
    setor TEXT,                   -- sector
    industria TEXT,               -- industry

    -- Informações Adicionais
    moeda TEXT DEFAULT 'BRL',     -- currency
    logo_url TEXT,                -- logourl

    -- Controle
    ativo BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    atualizado_em TIMESTAMPTZ DEFAULT NOW()
);

-- Tabela de Cotações em Tempo Real (snapshot)
CREATE TABLE cotacoes_snapshot (
    id BIGSERIAL PRIMARY KEY,
    ticker TEXT NOT NULL REFERENCES acoes(ticker) ON DELETE CASCADE,

    -- Preços
    preco_atual DECIMAL(12, 2),           -- regularMarketPrice
    preco_abertura DECIMAL(12, 2),        -- regularMarketOpen
    preco_maximo_dia DECIMAL(12, 2),      -- regularMarketDayHigh
    preco_minimo_dia DECIMAL(12, 2),      -- regularMarketDayLow
    preco_fechamento_anterior DECIMAL(12, 2), -- regularMarketPreviousClose

    -- Variações
    variacao_dia DECIMAL(12, 2),          -- regularMarketChange
    variacao_dia_percentual DECIMAL(8, 4), -- regularMarketChangePercent

    -- Volume e Negociação
    volume BIGINT,                        -- regularMarketVolume
    volume_medio BIGINT,                  -- averageDailyVolume10Day

    -- Valores de Mercado
    market_cap BIGINT,                    -- marketCap

    -- Faixas de Preço
    preco_maximo_52_semanas DECIMAL(12, 2), -- fiftyTwoWeekHigh
    preco_minimo_52_semanas DECIMAL(12, 2), -- fiftyTwoWeekLow

    -- Timestamp
    timestamp TIMESTAMPTZ DEFAULT NOW(),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Tabela de Preços Históricos Diários
CREATE TABLE precos_diarios (
    id BIGSERIAL PRIMARY KEY,
    ticker TEXT NOT NULL REFERENCES acoes(ticker) ON DELETE CASCADE,
    data DATE NOT NULL,

    -- OHLC (Open, High, Low, Close)
    abertura DECIMAL(12, 2),
    maxima DECIMAL(12, 2),
    minima DECIMAL(12, 2),
    fechamento DECIMAL(12, 2),

    -- Volume
    volume BIGINT,

    -- Ajustes
    fechamento_ajustado DECIMAL(12, 2),

    -- Controle
    created_at TIMESTAMPTZ DEFAULT NOW(),

    -- Garantir unicidade por ticker + data
    UNIQUE(ticker, data)
);

-- Tabela de Fundamentos
CREATE TABLE fundamentos (
    id BIGSERIAL PRIMARY KEY,
    ticker TEXT NOT NULL REFERENCES acoes(ticker) ON DELETE CASCADE,

    -- Identificação
    nome_empresa TEXT,                    -- longName
    setor TEXT,                          -- sector
    industria TEXT,                       -- industry

    -- Dados Fundamentalistas
    valor_mercado BIGINT,                 -- marketCap
    valor_empresa BIGINT,                 -- enterpriseValue

    -- Múltiplos de Mercado
    preco_sobre_lucro DECIMAL(12, 4),    -- trailingPE
    preco_sobre_valor_patrimonial DECIMAL(12, 4), -- priceToBook
    preco_sobre_vendas DECIMAL(12, 4),   -- priceToSalesTrailing12Months
    ev_sobre_receita DECIMAL(12, 4),     -- enterpriseToRevenue
    ev_sobre_ebitda DECIMAL(12, 4),      -- enterpriseToEbitda

    -- Margens (em percentual)
    margem_lucro DECIMAL(8, 4),          -- profitMargins
    margem_bruta DECIMAL(8, 4),          -- grossMargins
    margem_ebitda DECIMAL(8, 4),         -- ebitdaMargins
    margem_operacional DECIMAL(8, 4),    -- operatingMargins

    -- Indicadores Financeiros
    roe DECIMAL(8, 4),                   -- returnOnEquity (ROE)
    roa DECIMAL(8, 4),                   -- returnOnAssets (ROA)

    -- Receita e Lucros
    receita_total BIGINT,                -- totalRevenue
    receita_por_acao DECIMAL(12, 4),    -- revenuePerShare
    lucro_bruto BIGINT,                  -- grossProfits
    lucro_liquido BIGINT,                -- netIncome
    ebitda BIGINT,                       -- ebitda
    lucro_por_acao DECIMAL(12, 4),      -- trailingEps

    -- Crescimento
    crescimento_receita DECIMAL(8, 4),   -- revenueGrowth
    crescimento_lucro DECIMAL(8, 4),     -- earningsGrowth

    -- Dividendos
    dividend_yield DECIMAL(8, 4),        -- dividendYield
    taxa_pagamento DECIMAL(8, 4),        -- payoutRatio

    -- Análise Técnica
    beta DECIMAL(8, 4),                  -- beta
    preco_alvo_medio DECIMAL(12, 2),     -- targetMeanPrice
    recomendacao TEXT,                    -- recommendationKey

    -- Número de Ações
    acoes_em_circulacao BIGINT,          -- sharesOutstanding

    -- Data de Referência e Controle
    data_referencia DATE DEFAULT CURRENT_DATE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    atualizado_em TIMESTAMPTZ DEFAULT NOW(),

    -- Garantir apenas um registro de fundamentos por ticker
    UNIQUE(ticker, data_referencia)
);

-- Índices para otimizar consultas
CREATE INDEX idx_acoes_ticker ON acoes(ticker);
CREATE INDEX idx_acoes_ativo ON acoes(ativo);
CREATE INDEX idx_acoes_setor ON acoes(setor);

CREATE INDEX idx_cotacoes_ticker ON cotacoes_snapshot(ticker);
CREATE INDEX idx_cotacoes_timestamp ON cotacoes_snapshot(timestamp DESC);

CREATE INDEX idx_precos_ticker ON precos_diarios(ticker);
CREATE INDEX idx_precos_data ON precos_diarios(data DESC);
CREATE INDEX idx_precos_ticker_data ON precos_diarios(ticker, data DESC);

CREATE INDEX idx_fundamentos_ticker ON fundamentos(ticker);
CREATE INDEX idx_fundamentos_data ON fundamentos(data_referencia DESC);

-- Confirmar criação
SELECT 'Todas as tabelas foram criadas com sucesso!' as status;

-- Ver tabelas criadas
SELECT table_name
FROM information_schema.tables
WHERE table_schema = 'public'
  AND table_type = 'BASE TABLE'
ORDER BY table_name;
