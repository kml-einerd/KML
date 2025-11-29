-- Script para criar a tabela acoes_info no Supabase
-- Esta tabela armazena informações extras das empresas obtidas via yfinance

CREATE TABLE IF NOT EXISTS public.acoes_info (
    -- Identificação
    id BIGSERIAL PRIMARY KEY,
    ticker TEXT NOT NULL UNIQUE,  -- Referência ao ticker da tabela acoes
    symbol TEXT,  -- Symbol usado no yfinance (ex: PETR4.SA)

    -- Informações Básicas da Empresa
    nome_longo TEXT,
    nome_curto TEXT,
    descricao TEXT,

    -- Localização e Contato
    pais TEXT,
    estado TEXT,
    cidade TEXT,
    endereco TEXT,
    cep TEXT,
    telefone TEXT,
    website TEXT,

    -- Classificação
    setor TEXT,
    industria TEXT,
    industria_chave TEXT,

    -- Informações Corporativas
    numero_funcionarios INTEGER,

    -- Informações de Mercado (fixas)
    moeda TEXT,
    exchange TEXT,
    tipo_ativo TEXT,

    -- Informações Fiscais
    ano_fiscal_termina TEXT,
    proximo_ano_fiscal TEXT,

    -- Governança
    auditoria_risco INTEGER,
    conselho_risco INTEGER,
    compensacao_risco INTEGER,
    shareholders_risco INTEGER,
    risco_geral INTEGER,

    -- Timestamps
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    atualizado_em TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Criar índice para busca rápida por ticker
CREATE INDEX IF NOT EXISTS idx_acoes_info_ticker ON public.acoes_info(ticker);

-- Adicionar foreign key para a tabela acoes (opcional - remova o comentário se quiser)
-- ALTER TABLE public.acoes_info
-- ADD CONSTRAINT fk_acoes_info_ticker
-- FOREIGN KEY (ticker) REFERENCES public.acoes(ticker) ON DELETE CASCADE;

-- Adicionar comentário na tabela
COMMENT ON TABLE public.acoes_info IS 'Informações extras das empresas obtidas via yfinance (dados fixos)';
