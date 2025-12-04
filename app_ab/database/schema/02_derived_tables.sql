-- =====================================================================
-- TABELAS DERIVADAS E AUDIT - Radar Institucional
-- Execute após 01_tables.sql
-- =====================================================================

-- =====================================================================
-- 1. TABELA DE AUDIT (Logs de execução do ETL)
-- =====================================================================
CREATE TABLE IF NOT EXISTS public.audit_etl (
  id BIGSERIAL PRIMARY KEY,
  run_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  run_by TEXT DEFAULT current_user,
  status TEXT NOT NULL CHECK (status IN ('started', 'success', 'failed')),
  rows_top_movers INTEGER DEFAULT 0,
  rows_fresh_bets INTEGER DEFAULT 0,
  duration_seconds DOUBLE PRECISION DEFAULT 0,
  attempts INTEGER DEFAULT 1,
  error_message TEXT,
  notes TEXT
);

COMMENT ON TABLE public.audit_etl IS 'Log de execuções do ETL';
COMMENT ON COLUMN public.audit_etl.status IS 'Status: started, success, failed';
COMMENT ON COLUMN public.audit_etl.duration_seconds IS 'Tempo de execução em segundos';

CREATE INDEX IF NOT EXISTS idx_audit_etl_run_at ON public.audit_etl(run_at DESC);
CREATE INDEX IF NOT EXISTS idx_audit_etl_status ON public.audit_etl(status);

-- =====================================================================
-- 2. SNAPSHOTS DE POSIÇÕES (Cache de posições por data)
-- =====================================================================
CREATE TABLE IF NOT EXISTS public.snapshots_posicoes (
  id BIGSERIAL PRIMARY KEY,
  fundo_id UUID NOT NULL,
  ativo_id UUID,
  data_snapshot DATE NOT NULL,
  quantidade NUMERIC(18, 6),
  valor_mark_to_market NUMERIC(18, 2),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (fundo_id, ativo_id, data_snapshot)
);

COMMENT ON TABLE public.snapshots_posicoes IS 'Snapshots de posições para cálculos de variação';

CREATE INDEX IF NOT EXISTS idx_snapshots_posicoes_fundo_data
  ON public.snapshots_posicoes(fundo_id, data_snapshot DESC);
CREATE INDEX IF NOT EXISTS idx_snapshots_posicoes_ativo
  ON public.snapshots_posicoes(ativo_id, data_snapshot DESC);
CREATE INDEX IF NOT EXISTS idx_snapshots_posicoes_data
  ON public.snapshots_posicoes(data_snapshot DESC);

-- =====================================================================
-- 3. TOP MOVERS (Maiores variações entre snapshots)
-- =====================================================================
CREATE TABLE IF NOT EXISTS public.top_movers (
  id BIGSERIAL PRIMARY KEY,
  fundo_id UUID NOT NULL,
  ativo_id UUID,
  data_snapshot DATE NOT NULL,
  pct_change NUMERIC(10, 4), -- Variação percentual
  change_absolute NUMERIC(18, 2), -- Variação absoluta em valor
  prev_quantity NUMERIC(18, 6), -- Quantidade anterior
  curr_quantity NUMERIC(18, 6), -- Quantidade atual
  prev_value NUMERIC(18, 2), -- Valor anterior
  curr_value NUMERIC(18, 2), -- Valor atual
  tipo_movimento TEXT CHECK (tipo_movimento IN ('compra', 'venda', NULL)),
  variacao_valor NUMERIC(18, 2), -- Alias para compatibilidade
  variacao_qtd NUMERIC(18, 6), -- Alias para compatibilidade
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

COMMENT ON TABLE public.top_movers IS 'Maiores variações (compras e vendas) entre snapshots';
COMMENT ON COLUMN public.top_movers.tipo_movimento IS 'Tipo: compra, venda ou NULL';
COMMENT ON COLUMN public.top_movers.pct_change IS 'Variação percentual entre snapshots';

CREATE INDEX IF NOT EXISTS idx_top_movers_fundo_data
  ON public.top_movers(fundo_id, data_snapshot DESC);
CREATE INDEX IF NOT EXISTS idx_top_movers_ativo
  ON public.top_movers(ativo_id, data_snapshot DESC);
CREATE INDEX IF NOT EXISTS idx_top_movers_tipo
  ON public.top_movers(data_snapshot DESC, tipo_movimento);
CREATE INDEX IF NOT EXISTS idx_top_movers_pct
  ON public.top_movers(data_snapshot DESC, pct_change DESC NULLS LAST);

-- =====================================================================
-- 4. FRESH BETS (Novas apostas / Posições recentes)
-- =====================================================================
CREATE TABLE IF NOT EXISTS public.fresh_bets (
  id BIGSERIAL PRIMARY KEY,
  fundo_id UUID NOT NULL,
  ativo_id UUID,
  data_competencia DATE, -- Compatibilidade com queries
  first_seen DATE NOT NULL,
  last_seen DATE NOT NULL,
  quantity NUMERIC(18, 6),
  value NUMERIC(18, 2),
  qtd_fundos INTEGER DEFAULT 1, -- Qtd de fundos que entraram neste ativo
  valor_total_investido NUMERIC(18, 2) DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

COMMENT ON TABLE public.fresh_bets IS 'Novas apostas (ativos que apareceram recentemente)';
COMMENT ON COLUMN public.fresh_bets.qtd_fundos IS 'Quantidade de fundos que entraram neste ativo';

CREATE INDEX IF NOT EXISTS idx_fresh_bets_fundo_first
  ON public.fresh_bets(fundo_id, first_seen DESC);
CREATE INDEX IF NOT EXISTS idx_fresh_bets_ativo
  ON public.fresh_bets(ativo_id, first_seen DESC);
CREATE INDEX IF NOT EXISTS idx_fresh_bets_data_comp
  ON public.fresh_bets(data_competencia DESC);

-- =====================================================================
-- 5. FRESH BETS PARTICIPANTES (Quem entrou em cada fresh bet)
-- =====================================================================
CREATE TABLE IF NOT EXISTS public.fresh_bets_participantes (
  id BIGSERIAL PRIMARY KEY,
  fresh_bet_id BIGINT REFERENCES public.fresh_bets(id) ON DELETE CASCADE,
  participante_id UUID,
  quantidade NUMERIC(18, 6),
  valor NUMERIC(18, 2),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

COMMENT ON TABLE public.fresh_bets_participantes IS 'Participantes de cada fresh bet';

CREATE INDEX IF NOT EXISTS idx_fresh_bets_participantes_fb
  ON public.fresh_bets_participantes(fresh_bet_id);
CREATE INDEX IF NOT EXISTS idx_fresh_bets_participantes_part
  ON public.fresh_bets_participantes(participante_id);

-- =====================================================================
-- 6. MATERIALIZED VIEWS
-- =====================================================================

-- MV: Fresh Bets últimos 30 dias
DROP MATERIALIZED VIEW IF EXISTS public.mv_fresh_bets_30d CASCADE;
CREATE MATERIALIZED VIEW public.mv_fresh_bets_30d AS
SELECT
  fb.id AS fresh_bet_id,
  fb.fundo_id,
  fb.ativo_id,
  fb.first_seen,
  fb.last_seen,
  fb.quantity,
  fb.value,
  fb.qtd_fundos,
  fb.valor_total_investido
FROM public.fresh_bets fb
WHERE fb.first_seen >= (CURRENT_DATE - INTERVAL '30 days')
ORDER BY fb.first_seen DESC, fb.qtd_fundos DESC;

CREATE UNIQUE INDEX IF NOT EXISTS idx_mv_fresh_bets_30d_pk
  ON public.mv_fresh_bets_30d(fresh_bet_id);

COMMENT ON MATERIALIZED VIEW public.mv_fresh_bets_30d IS 'Fresh bets dos últimos 30 dias (atualizada via ETL)';

-- MV: Resumo mensal por fundo
DROP MATERIALIZED VIEW IF EXISTS public.mv_fundo_summary_mes CASCADE;
CREATE MATERIALIZED VIEW public.mv_fundo_summary_mes AS
SELECT
  s.fundo_id,
  DATE_TRUNC('month', s.data_snapshot)::DATE AS mes,
  SUM(s.quantidade) AS total_quantidade,
  SUM(s.valor_mark_to_market) AS total_valor,
  COUNT(DISTINCT s.ativo_id) AS num_ativos
FROM public.snapshots_posicoes s
GROUP BY s.fundo_id, DATE_TRUNC('month', s.data_snapshot)
ORDER BY s.fundo_id, mes DESC;

CREATE UNIQUE INDEX IF NOT EXISTS idx_mv_fundo_summary_mes_pk
  ON public.mv_fundo_summary_mes(fundo_id, mes);

COMMENT ON MATERIALIZED VIEW public.mv_fundo_summary_mes IS 'Resumo mensal agregado por fundo';

-- =====================================================================
-- 7. TRIGGERS PARA COMPATIBILIDADE (variacao_valor, variacao_qtd)
-- =====================================================================

CREATE OR REPLACE FUNCTION sync_top_movers_aliases()
RETURNS TRIGGER AS $$
BEGIN
  -- Sincronizar aliases para compatibilidade com queries antigas
  NEW.variacao_valor := NEW.change_absolute;
  NEW.variacao_qtd := NEW.curr_quantity - NEW.prev_quantity;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_top_movers_sync BEFORE INSERT OR UPDATE ON public.top_movers
  FOR EACH ROW EXECUTE FUNCTION sync_top_movers_aliases();

COMMENT ON FUNCTION sync_top_movers_aliases IS 'Sincroniza colunas aliases para compatibilidade';

-- =====================================================================
-- 8. FUNÇÃO HELPER: Verificar existência de dados no mês
-- =====================================================================

CREATE OR REPLACE FUNCTION has_data_for_month(month_start DATE, month_end DATE)
RETURNS TABLE(has_positions BOOLEAN, has_pl BOOLEAN) AS $$
BEGIN
  RETURN QUERY
  SELECT
    EXISTS(SELECT 1 FROM public.posicoes WHERE data_competencia >= month_start AND data_competencia < month_end LIMIT 1) AS has_positions,
    EXISTS(SELECT 1 FROM public.patrimonio_liquido WHERE data_competencia >= month_start AND data_competencia < month_end LIMIT 1) AS has_pl;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION has_data_for_month IS 'Verifica se existe dados para um determinado mês';

-- =====================================================================
-- FIM DO SCRIPT DE TABELAS DERIVADAS
-- =====================================================================
