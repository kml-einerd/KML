-- =====================================================================
-- TABELAS PRINCIPAIS - Radar Institucional
-- Execute este script primeiro no Supabase SQL Editor
-- =====================================================================

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pg_trgm"; -- Para busca de texto

-- =====================================================================
-- 1. FUNDOS
-- =====================================================================
CREATE TABLE IF NOT EXISTS public.fundos (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  cnpj TEXT UNIQUE,
  nome_fundo TEXT NOT NULL,
  gestor TEXT,
  administrador TEXT,
  tipo_fundo TEXT, -- FIA, FIC-FIA, etc
  classe TEXT, -- Ações, Multimercado, etc
  situacao TEXT DEFAULT 'ATIVO', -- ATIVO, CANCELADO, etc
  data_inicio DATE,
  data_registro DATE,
  data_cancelamento DATE,
  publico_alvo TEXT, -- Investidor Qualificado, Geral, etc
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

COMMENT ON TABLE public.fundos IS 'Cadastro de fundos de investimento';
COMMENT ON COLUMN public.fundos.cnpj IS 'CNPJ do fundo';
COMMENT ON COLUMN public.fundos.nome_fundo IS 'Nome completo do fundo';

-- =====================================================================
-- 2. EMISSORES
-- =====================================================================
CREATE TABLE IF NOT EXISTS public.emissores (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  cnpj TEXT UNIQUE,
  nome_emissor TEXT NOT NULL,
  tipo_emissor TEXT, -- Companhia Aberta, Banco, etc
  setor TEXT,
  segmento TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

COMMENT ON TABLE public.emissores IS 'Cadastro de emissores de ativos';

-- =====================================================================
-- 3. ATIVOS
-- =====================================================================
CREATE TABLE IF NOT EXISTS public.ativos (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  codigo TEXT, -- Ticker (ex: PETR4, VALE3)
  descricao TEXT,
  tipo_ativo TEXT, -- Ação, FII, Título Público, Debênture, etc
  emissor_id UUID REFERENCES public.emissores(id) ON DELETE SET NULL,
  isin TEXT,
  preco NUMERIC(18, 6), -- Preço mais recente (para mark-to-market)
  data_preco DATE,
  mercado TEXT, -- B3, ANBIMA, etc
  ativo BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

COMMENT ON TABLE public.ativos IS 'Cadastro de ativos negociáveis';
COMMENT ON COLUMN public.ativos.codigo IS 'Ticker ou código do ativo (ex: PETR4)';
COMMENT ON COLUMN public.ativos.preco IS 'Último preço conhecido para mark-to-market';

-- =====================================================================
-- 4. PATRIMÔNIO LÍQUIDO
-- =====================================================================
CREATE TABLE IF NOT EXISTS public.patrimonio_liquido (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  fundo_id UUID NOT NULL REFERENCES public.fundos(id) ON DELETE CASCADE,
  data_competencia DATE NOT NULL,
  valor_pl NUMERIC(18, 2) NOT NULL DEFAULT 0,
  num_cotistas INTEGER,
  valor_cota NUMERIC(18, 6),
  captacao_mes NUMERIC(18, 2),
  resgate_mes NUMERIC(18, 2),
  rentabilidade_mes NUMERIC(8, 4), -- Em percentual (ex: 1.5 = 1.5%)
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (fundo_id, data_competencia)
);

COMMENT ON TABLE public.patrimonio_liquido IS 'Patrimônio líquido mensal dos fundos';
COMMENT ON COLUMN public.patrimonio_liquido.valor_pl IS 'Valor do patrimônio líquido em R$';
COMMENT ON COLUMN public.patrimonio_liquido.rentabilidade_mes IS 'Rentabilidade do mês em %';

-- =====================================================================
-- 5. POSIÇÕES (Carteira dos fundos)
-- =====================================================================
CREATE TABLE IF NOT EXISTS public.posicoes (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  fundo_id UUID NOT NULL REFERENCES public.fundos(id) ON DELETE CASCADE,
  ativo_id UUID REFERENCES public.ativos(id) ON DELETE SET NULL,
  data_competencia DATE NOT NULL,
  quantidade NUMERIC(18, 6), -- Quantidade de ativos (fallback)
  qtd_posicao_final NUMERIC(18, 6), -- Quantidade final no período
  valor_mercado_final NUMERIC(18, 2), -- Valor de mercado em R$
  percentual_carteira NUMERIC(8, 4), -- % da carteira (ex: 15.5 = 15.5%)
  tipo_aplicacao TEXT, -- Ações, Títulos Públicos, etc
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (fundo_id, ativo_id, data_competencia)
);

COMMENT ON TABLE public.posicoes IS 'Posições dos fundos por ativo e data';
COMMENT ON COLUMN public.posicoes.qtd_posicao_final IS 'Quantidade final de ativos no período';
COMMENT ON COLUMN public.posicoes.valor_mercado_final IS 'Valor de mercado da posição';
COMMENT ON COLUMN public.posicoes.percentual_carteira IS 'Percentual da carteira (%)';

-- =====================================================================
-- 6. POSIÇÕES DETALHADAS (Transações/Movimentações)
-- =====================================================================
CREATE TABLE IF NOT EXISTS public.posicoes_detalhes (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  fundo_id UUID NOT NULL REFERENCES public.fundos(id) ON DELETE CASCADE,
  ativo_id UUID REFERENCES public.ativos(id) ON DELETE SET NULL,
  participante_id UUID, -- Pode ser outro fundo, emissor, etc
  data_operacao DATE NOT NULL,
  tipo_operacao TEXT, -- Compra, Venda, etc
  quantidade NUMERIC(18, 6),
  preco_unitario NUMERIC(18, 6),
  valor_total NUMERIC(18, 2),
  taxa_corretagem NUMERIC(18, 2),
  observacoes TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

COMMENT ON TABLE public.posicoes_detalhes IS 'Detalhamento de transações e movimentações';

-- =====================================================================
-- ÍNDICES BÁSICOS (Performance)
-- =====================================================================

-- Fundos
CREATE INDEX IF NOT EXISTS idx_fundos_nome ON public.fundos(nome_fundo);
CREATE INDEX IF NOT EXISTS idx_fundos_cnpj ON public.fundos(cnpj);
CREATE INDEX IF NOT EXISTS idx_fundos_situacao ON public.fundos(situacao);

-- Ativos
CREATE INDEX IF NOT EXISTS idx_ativos_codigo ON public.ativos(codigo);
CREATE INDEX IF NOT EXISTS idx_ativos_tipo ON public.ativos(tipo_ativo);
CREATE INDEX IF NOT EXISTS idx_ativos_emissor ON public.ativos(emissor_id);

-- Patrimônio Líquido
CREATE INDEX IF NOT EXISTS idx_pl_fundo_data ON public.patrimonio_liquido(fundo_id, data_competencia DESC);
CREATE INDEX IF NOT EXISTS idx_pl_data ON public.patrimonio_liquido(data_competencia DESC);

-- Posições
CREATE INDEX IF NOT EXISTS idx_posicoes_fundo_data ON public.posicoes(fundo_id, data_competencia DESC);
CREATE INDEX IF NOT EXISTS idx_posicoes_ativo_data ON public.posicoes(ativo_id, data_competencia DESC);
CREATE INDEX IF NOT EXISTS idx_posicoes_data ON public.posicoes(data_competencia DESC);

-- Posições Detalhes
CREATE INDEX IF NOT EXISTS idx_posicoes_det_fundo ON public.posicoes_detalhes(fundo_id, data_operacao DESC);
CREATE INDEX IF NOT EXISTS idx_posicoes_det_ativo ON public.posicoes_detalhes(ativo_id, data_operacao DESC);

-- =====================================================================
-- TRIGGERS (Atualizar updated_at automaticamente)
-- =====================================================================

CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_fundos_updated_at BEFORE UPDATE ON public.fundos
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_emissores_updated_at BEFORE UPDATE ON public.emissores
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_ativos_updated_at BEFORE UPDATE ON public.ativos
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_pl_updated_at BEFORE UPDATE ON public.patrimonio_liquido
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_posicoes_updated_at BEFORE UPDATE ON public.posicoes
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_posicoes_det_updated_at BEFORE UPDATE ON public.posicoes_detalhes
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- =====================================================================
-- FIM DO SCRIPT DE TABELAS PRINCIPAIS
-- =====================================================================
