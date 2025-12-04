# Tabelas Deruvadas


## Parte 1
-- =====================================================================
-- MVP RADAR DASHBOARD - PACKAGE SQL (v1)
-- Objetivo: criar tabelas derivadas, snapshots, função ETL, materialized views,
-- índices e instruções de agendamento (comentada).
-- Execute no Supabase SQL Editor.
-- =====================================================================

-- 0. Observação: o script assume que as tabelas fontes existem no schema public:
-- fundos, emissores, ativos, patrimonio_liquido, posicoes, posicoes_detalhes
-- Caso algum nome difira, ajuste antes de executar.

-- =====================================================================
-- 1) TABELAS DE SUPORTE / AUDIT
-- =====================================================================

-- audit_etl: guarda execução do ETL
DROP TABLE IF EXISTS public.audit_etl;
CREATE TABLE public.audit_etl (
  id             BIGSERIAL PRIMARY KEY,
  run_at         TIMESTAMPTZ NOT NULL DEFAULT now(),
  run_by         TEXT DEFAULT current_user,
  status         TEXT NOT NULL, -- started, success, failed
  rows_top_movers INTEGER DEFAULT 0,
  rows_fresh_bets INTEGER DEFAULT 0,
  notes          TEXT
);

-- snapshots: snapshot de posições por fundo por data
DROP TABLE IF EXISTS public.snapshots_posicoes;
CREATE TABLE public.snapshots_posicoes (
  id               BIGSERIAL PRIMARY KEY,
  fundo_id         UUID,
  ativo_id         UUID,
  data_snapshot    DATE NOT NULL,
  quantidade       NUMERIC,
  valor_mark_to_market NUMERIC,
  created_at       TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_snapshots_posicoes_fundo_data
  ON public.snapshots_posicoes (fundo_id, data_snapshot);

-- Tabela top_movers: mudanças percentuais entre snapshots
DROP TABLE IF EXISTS public.top_movers;
CREATE TABLE public.top_movers (
  id              BIGSERIAL PRIMARY KEY,
  fundo_id        UUID,
  ativo_id        UUID,
  data_snapshot   DATE NOT NULL,
  pct_change      NUMERIC, -- percentual entre snapshots (ex: 0.12 = +12%)
  change_absolute NUMERIC,
  prev_quantity   NUMERIC,
  curr_quantity   NUMERIC,
  prev_value      NUMERIC,
  curr_value      NUMERIC,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_top_movers_fundo_data
  ON public.top_movers (fundo_id, data_snapshot);

-- Tabela fresh_bets: apostas recentes (exemplo: ativos que entraram recentemente)
DROP TABLE IF EXISTS public.fresh_bets;
CREATE TABLE public.fresh_bets (
  id             BIGSERIAL PRIMARY KEY,
  fundo_id       UUID,
  ativo_id       UUID,
  first_seen     DATE NOT NULL,
  last_seen      DATE NOT NULL,
  quantity       NUMERIC,
  value          NUMERIC,
  created_at     TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_fresh_bets_fundo_firstseen
  ON public.fresh_bets (fundo_id, first_seen);

-- Tabela fresh_bets_participantes: participantes / detalhe por aposta
DROP TABLE IF EXISTS public.fresh_bets_participantes;
CREATE TABLE public.fresh_bets_participantes (
  id              BIGSERIAL PRIMARY KEY,
  fresh_bet_id    BIGINT REFERENCES public.fresh_bets(id) ON DELETE CASCADE,
  participante_id UUID,
  quantidade      NUMERIC,
  valor           NUMERIC,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_fresh_bets_participantes_fb
  ON public.fresh_bets_participantes (fresh_bet_id);

-- =====================================================================
-- 2) MATERIALIZED VIEWS EXEMPLO
-- =====================================================================

-- mv_fresh_bets_30d: top fresh bets nos últimos 30 dias (exemplo)
DROP MATERIALIZED VIEW IF EXISTS public.mv_fresh_bets_30d;
CREATE MATERIALIZED VIEW public.mv_fresh_bets_30d AS
SELECT
  fb.id AS fresh_bet_id,
  fb.fundo_id,
  fb.ativo_id,
  fb.first_seen,
  fb.last_seen,
  fb.quantity,
  fb.value
FROM public.fresh_bets fb
WHERE fb.first_seen >= (current_date - INTERVAL '30 days')
ORDER BY fb.first_seen DESC;

-- mv_fundo_summary_mes: resumo mensal por fundo (exemplo)
DROP MATERIALIZED VIEW IF EXISTS public.mv_fundo_summary_mes;
CREATE MATERIALIZED VIEW public.mv_fundo_summary_mes AS
SELECT
  p.fundo_id,
  date_trunc('month', p.data_snapshot) AS mes,
  SUM(p.quantidade) AS total_quantidade,
  SUM(p.valor_mark_to_market) AS total_valor
FROM public.snapshots_posicoes p
GROUP BY p.fundo_id, date_trunc('month', p.data_snapshot)
ORDER BY p.fundo_id, mes DESC;

-- Recomenda-se criar índices nas materialized views conforme necessidade:
-- Create indexes if queries sobre elas forem lentas
-- (não criamos índices por padrão aqui para evitar overhead inicial)

-- =====================================================================
-- 3) FUNÇÃO ETL (PL/pgSQL)
-- =====================================================================

-- Remove versão anterior da função se existir
DROP FUNCTION IF EXISTS public.etl_populate_derivatives() CASCADE;
CREATE OR REPLACE FUNCTION public.etl_populate_derivatives()
RETURNS void
LANGUAGE plpgsql
AS $$
DECLARE
  v_run_id    BIGINT;
  v_now       TIMESTAMPTZ := now();
  v_rows_top  INTEGER := 0;
  v_rows_fresh INTEGER := 0;
  -- cursors / temporaries
BEGIN
  -- Inserir registro de inicio
  INSERT INTO public.audit_etl (run_at, status, run_by, notes)
  VALUES (v_now, 'started', current_user, NULL)
  RETURNING id INTO v_run_id;

  -- 1) Criar snapshot do dia (exemplo: agregando posicoes)
  -- Limpeza do snapshot do dia atual para evitar duplicados
  DELETE FROM public.snapshots_posicoes WHERE data_snapshot = current_date;

  INSERT INTO public.snapshots_posicoes (fundo_id, ativo_id, data_snapshot, quantidade, valor_mark_to_market)
  SELECT
    p.fundo_id::uuid,
    p.ativo_id::uuid,
    current_date AS data_snapshot,
    SUM(p.quantidade) AS quantidade,
    SUM(p.quantidade * COALESCE(a.preco, 0)) AS valor_mark_to_market
  FROM public.posicoes p
  LEFT JOIN public.ativos a ON a.id::uuid = p.ativo_id::uuid
  GROUP BY p.fundo_id, p.ativo_id;

  -- 2) Calcular top_movers comparando com snapshot anterior (última data anterior à atual)
  -- Limpar top_movers para a data atual (v1 behavior)
  DELETE FROM public.top_movers WHERE data_snapshot = current_date;

  INSERT INTO public.top_movers (
    fundo_id, ativo_id, data_snapshot,
    pct_change, change_absolute, prev_quantity, curr_quantity, prev_value, curr_value
  )
  SELECT
    curr.fundo_id,
    curr.ativo_id,
    current_date AS data_snapshot,
    CASE WHEN prev.quantidade IS NULL OR prev.quantidade = 0 THEN NULL
         ELSE (curr.quantidade - prev.quantidade) / NULLIF(prev.quantidade,0)
    END AS pct_change,
    (curr.quantidade - COALESCE(prev.quantidade,0)) AS change_absolute,
    COALESCE(prev.quantidade,0) AS prev_quantity,
    curr.quantidade AS curr_quantity,
    COALESCE(prev.valor_mark_to_market,0) AS prev_value,
    curr.valor_mark_to_market AS curr_value
  FROM (
    SELECT fondo.fundo_id, fondo.ativo_id, fondo.quantidade, fondo.valor_mark_to_market
    FROM public.snapshots_posicoes fondo
    WHERE fondo.data_snapshot = current_date
  ) curr
  LEFT JOIN LATERAL (
    SELECT s.quantidade, s.valor_mark_to_market
    FROM public.snapshots_posicoes s
    WHERE s.fundo_id = curr.fundo_id
      AND s.ativo_id = curr.ativo_id
      AND s.data_snapshot < current_date
    ORDER BY s.data_snapshot DESC
    LIMIT 1
  ) prev ON TRUE
  RETURNING id INTO v_rows_top; -- note: this returns only the last id; we'll count separately below

  -- Count rows inserted into top_movers for reporting
  GET DIAGNOSTICS v_rows_top = ROW_COUNT;

  -- 3) Calcular fresh_bets: ativos que apareceram pela primeira vez nos últimos N dias
  -- Param: janela de detecção (ex: 30 dias)
  PERFORM 1; -- no-op to keep structure
  DELETE FROM public.fresh_bets WHERE first_seen = current_date; -- manter idempotência se rerodado no mesmo dia

  WITH first_seen_dates AS (
    SELECT
      s.fundo_id,
      s.ativo_id,
      s.data_snapshot,
      ROW_NUMBER() OVER (PARTITION BY s.fundo_id, s.ativo_id ORDER BY s.data_snapshot ASC) AS rn
    FROM public.snapshots_posicoes s
    WHERE s.data_snapshot >= (current_date - INTERVAL '90 days') -- janela de busca histórica
  )
  INSERT INTO public.fresh_bets (fundo_id, ativo_id, first_seen, last_seen, quantity, value)
  SELECT
    f.fundo_id,
    f.ativo_id,
    f.data_snapshot AS first_seen,
    currs.last_seen,
    f.quantidade,
    f.valor_mark_to_market
  FROM first_seen_dates f
  JOIN (
    -- última ocorrência conhecida (para preencher last_seen)
    SELECT s.fundo_id, s.ativo_id, MAX(s.data_snapshot) AS last_seen
    FROM public.snapshots_posicoes s
    WHERE s.data_snapshot >= (current_date - INTERVAL '90 days')
    GROUP BY s.fundo_id, s.ativo_id
  ) currs ON currs.fundo_id = f.fundo_id AND currs.ativo_id = f.ativo_id
  WHERE f.rn = 1
    AND f.data_snapshot >= (current_date - INTERVAL '30 days') -- considerar fresh se primeiro visto nos últimos 30 dias
  RETURNING id INTO v_rows_fresh;

  GET DIAGNOSTICS v_rows_fresh = ROW_COUNT;

  -- 4) Popular fresh_bets_participantes com dados a partir de posicoes_detalhes (se existir)
  -- Remover particpantes para fresh_bets criados hoje (idempotência)
  DELETE FROM public.fresh_bets_participantes WHERE created_at::date = current_date;

  INSERT INTO public.fresh_bets_participantes (fresh_bet_id, participante_id, quantidade, valor)
  SELECT
    fb.id AS fresh_bet_id,
    pd.participante_id::uuid,
    SUM(pd.quantidade) AS quantidade,
    SUM(pd.quantidade * COALESCE(a.preco,0)) AS valor
  FROM public.fresh_bets fb
  JOIN public.posicoes_detalhes pd ON pd.fundo_id::uuid = fb.fundo_id::uuid
    AND pd.ativo_id::uuid = fb.ativo_id::uuid
    AND pd.data_operacao >= fb.first_seen
  LEFT JOIN public.ativos a ON a.id::uuid = pd.ativo_id::uuid
  GROUP BY fb.id, pd.participante_id
  ON CONFLICT DO NOTHING;

  -- 5) Refresh materialized views (concurrently where possible)
  BEGIN
    -- Try concurrent refresh (requires unique index); if fails, fallback to normal refresh
    BEGIN
      REFRESH MATERIALIZED VIEW CONCURRENTLY public.mv_fresh_bets_30d;
    EXCEPTION WHEN OTHERS THEN
      -- fallback
      REFRESH MATERIALIZED VIEW public.mv_fresh_bets_30d;
    END;

    BEGIN
      REFRESH MATERIALIZED VIEW CONCURRENTLY public.mv_fundo_summary_mes;
    EXCEPTION WHEN OTHERS THEN
      REFRESH MATERIALIZED VIEW public.mv_fundo_summary_mes;
    END;
  END;

  -- 6) Atualizar audit_etl com sucesso
  UPDATE public.audit_etl
  SET status = 'success',
      rows_top_movers = v_rows_top,
      rows_fresh_bets = v_rows_fresh,
      notes = 'Completed successfully',
      run_at = v_now
  WHERE id = v_run_id;

  RETURN;

EXCEPTION
  WHEN OTHERS THEN
    -- Registrar falha
    UPDATE public.audit_etl
    SET status = 'failed',
        notes = SQLERRM,
        run_at = now()
    WHERE id = v_run_id;
    RAISE;
END;
$$;

-- Grant execute on function to service_role if desired (comentado)
-- GRANT EXECUTE ON FUNCTION public.etl_populate_derivatives() TO service_role;

-- =====================================================================
-- 4) ÍNDICES RECOMENDADOS (para desempenho nas queries e policies)
-- =====================================================================

-- Índices já criados sobre snapshots/top_movers/fresh_bets/fresh_bets_participantes parcialmente acima.
-- Adicionais:
CREATE INDEX IF NOT EXISTS idx_snapshots_posicoes_ativo ON public.snapshots_posicoes (ativo_id, data_snapshot);
CREATE INDEX IF NOT EXISTS idx_top_movers_ativo ON public.top_movers (ativo_id, data_snapshot);
CREATE INDEX IF NOT EXISTS idx_fresh_bets_ativo ON public.fresh_bets (ativo_id, first_seen);

-- =====================================================================
-- 5) FUNÇÕES AUXILIARES DE VALIDAÇÃO (queries úteis)
-- =====================================================================

-- Query 1: Verificar últimas execuções do ETL
-- SELECT * FROM public.audit_etl ORDER BY run_at DESC LIMIT 10;

-- Query 2: Top movers recentes (últimos 7 dias)
-- SELECT * FROM public.top_movers WHERE data_snapshot >= (current_date - INTERVAL '7 days') ORDER BY pct_change DESC NULLS LAST LIMIT 50;

-- Query 3: Fresh bets últimos 30 dias
-- SELECT * FROM public.mv_fresh_bets_30d ORDER BY first_seen DESC LIMIT 100;

-- =====================================================================
-- 6) INSTRUÇÃO EXEMPLO DE AGENDAMENTO (pg_cron) - opcional
-- =====================================================================

-- Observação: pg_cron deve estar instalado e habilitado pelo provedor.
-- Se disponível, a entrada abaixo agenda a execução diária às 03:30 UTC.
-- Para usar, descomente as linhas abaixo.

-- SELECT cron.schedule('etl_daily_0330', '30 3 * * *', $$SELECT public.etl_populate_derivatives();$$);

-- =====================================================================
-- 7) INSTRUÇÕES DE USO RÁPIDAS
-- =====================================================================
-- 1) Cole e execute todo o script acima no SQL Editor.
-- 2) Para rodar o ETL pela primeira vez manualmente:
--    SELECT public.etl_populate_derivatives();
-- 3) Verifique logs:
--    SELECT * FROM public.audit_etl ORDER BY run_at DESC LIMIT 10;
-- 4) Veja materialized views:
--    SELECT * FROM public.mv_fresh_bets_30d LIMIT 100;
-- =====================================================================


## Parte 2
-- =====================================================================
-- Fortified ETL + Audit + Views (v1)
-- Execute no Supabase SQL Editor
-- =====================================================================

-- 0) Assunção: tabelas fontes existentes em public:
--    fundos, emissores, ativos, patrimonio_liquido, posicoes, posicoes_detalhes

-- =====================================================================
-- 1) EXTENDER / CRIAR audit_etl (com colunas extras)
-- =====================================================================
CREATE TABLE IF NOT EXISTS public.audit_etl (
  id BIGSERIAL PRIMARY KEY,
  run_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  run_by TEXT DEFAULT current_user,
  status TEXT NOT NULL, -- started, success, failed
  rows_top_movers INTEGER DEFAULT 0,
  rows_fresh_bets INTEGER DEFAULT 0,
  duration_seconds DOUBLE PRECISION DEFAULT 0,
  attempts INTEGER DEFAULT 1,
  error_message TEXT,
  notes TEXT
);

-- Add columns if missing (safe ALTERs) — usar DO blocks com LANGUAGE plpgsql
DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public'
      AND table_name = 'audit_etl'
      AND column_name = 'duration_seconds'
  ) THEN
    ALTER TABLE public.audit_etl ADD COLUMN duration_seconds DOUBLE PRECISION DEFAULT 0;
  END IF;
END $$;

DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public'
      AND table_name = 'audit_etl'
      AND column_name = 'attempts'
  ) THEN
    ALTER TABLE public.audit_etl ADD COLUMN attempts INTEGER DEFAULT 1;
  END IF;
END $$;

DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public'
      AND table_name = 'audit_etl'
      AND column_name = 'error_message'
  ) THEN
    ALTER TABLE public.audit_etl ADD COLUMN error_message TEXT;
  END IF;
END $$;

-- =====================================================================
-- 2) GARANTIR TABELAS DERIVADAS EXISTENTES (cria se não existirem) - idempotente
-- =====================================================================

-- snapshots_posicoes
CREATE TABLE IF NOT EXISTS public.snapshots_posicoes (
  id BIGSERIAL PRIMARY KEY,
  fundo_id UUID,
  ativo_id UUID,
  data_snapshot DATE NOT NULL,
  quantidade NUMERIC,
  valor_mark_to_market NUMERIC,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_snapshots_posicoes_fundo_data
  ON public.snapshots_posicoes (fundo_id, data_snapshot);

CREATE INDEX IF NOT EXISTS idx_snapshots_posicoes_ativo
  ON public.snapshots_posicoes (ativo_id, data_snapshot);

-- top_movers
CREATE TABLE IF NOT EXISTS public.top_movers (
  id BIGSERIAL PRIMARY KEY,
  fundo_id UUID,
  ativo_id UUID,
  data_snapshot DATE NOT NULL,
  pct_change NUMERIC,
  change_absolute NUMERIC,
  prev_quantity NUMERIC,
  curr_quantity NUMERIC,
  prev_value NUMERIC,
  curr_value NUMERIC,
  tipo_movimento TEXT, -- 'compra' / 'venda' / null
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_top_movers_fundo_data
  ON public.top_movers (fundo_id, data_snapshot);

CREATE INDEX IF NOT EXISTS idx_top_movers_ativo
  ON public.top_movers (ativo_id, data_snapshot);

-- fresh_bets
CREATE TABLE IF NOT EXISTS public.fresh_bets (
  id BIGSERIAL PRIMARY KEY,
  fundo_id UUID,
  ativo_id UUID,
  first_seen DATE NOT NULL,
  last_seen DATE NOT NULL,
  quantity NUMERIC,
  value NUMERIC,
  qtd_fundos INTEGER DEFAULT 0,
  valor_total_investido NUMERIC DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_fresh_bets_fundo_firstseen
  ON public.fresh_bets (fundo_id, first_seen);

CREATE INDEX IF NOT EXISTS idx_fresh_bets_ativo
  ON public.fresh_bets (ativo_id, first_seen);

-- fresh_bets_participantes
CREATE TABLE IF NOT EXISTS public.fresh_bets_participantes (
  id BIGSERIAL PRIMARY KEY,
  fresh_bet_id BIGINT REFERENCES public.fresh_bets(id) ON DELETE CASCADE,
  participante_id UUID,
  quantidade NUMERIC,
  valor NUMERIC,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_fresh_bets_participantes_fb
  ON public.fresh_bets_participantes (fresh_bet_id);

-- =====================================================================
-- 3) FUNÇÃO ETL MELHORADA (lock, timing, validações, updates audit)
-- =====================================================================

DROP FUNCTION IF EXISTS public.etl_populate_derivatives() CASCADE;

CREATE OR REPLACE FUNCTION public.etl_populate_derivatives()
RETURNS void
LANGUAGE plpgsql
AS $$
DECLARE
  v_run_id BIGINT;
  v_start TIMESTAMPTZ := clock_timestamp();
  v_now TIMESTAMPTZ := now();
  v_rows_top INTEGER := 0;
  v_rows_fresh INTEGER := 0;
  v_attempts INTEGER := 1;
  v_lock_key BIGINT := 1234567890; -- change if multiple ETLs; constant for advisory lock
  v_err_msg TEXT;
BEGIN
  -- Try to acquire advisory lock to avoid concurrent runs
  PERFORM pg_advisory_lock(v_lock_key);

  -- Insert audit start row
  INSERT INTO public.audit_etl (run_at, status, run_by, attempts, notes)
  VALUES (v_now, 'started', current_user, v_attempts, 'ETL started')
  RETURNING id INTO v_run_id;

  BEGIN
    -- Ensure idempotência for today's snapshot
    DELETE FROM public.snapshots_posicoes WHERE data_snapshot = current_date;

    -- Build today's snapshot from posicoes
    INSERT INTO public.snapshots_posicoes (fundo_id, ativo_id, data_snapshot, quantidade, valor_mark_to_market)
    SELECT
      (p.fundo_id)::uuid,
      (p.ativo_id)::uuid,
      current_date AS data_snapshot,
      SUM(COALESCE(p.qtd_posicao_final, p.quantidade, 0)) AS quantidade,
      SUM(COALESCE(p.qtd_posicao_final, p.quantidade, 0) * COALESCE(a.preco, 0)) AS valor_mark_to_market
    FROM public.posicoes p
    LEFT JOIN public.ativos a ON a.id::text = p.ativo_id::text
    WHERE p.data_competencia = current_date
    GROUP BY p.fundo_id, p.ativo_id;

    -- Compute top_movers for today: remove existing for today and insert fresh
    DELETE FROM public.top_movers WHERE data_snapshot = current_date;

    INSERT INTO public.top_movers (
      fundo_id, ativo_id, data_snapshot,
      pct_change, change_absolute, prev_quantity, curr_quantity, prev_value, curr_value, tipo_movimento
    )
    SELECT
      curr.fundo_id,
      curr.ativo_id,
      current_date AS data_snapshot,
      CASE WHEN prev.quantidade IS NULL OR prev.quantidade = 0 THEN NULL
           ELSE (curr.quantidade - prev.quantidade) / NULLIF(prev.quantidade,0)
      END AS pct_change,
      (curr.quantidade - COALESCE(prev.quantidade,0)) AS change_absolute,
      COALESCE(prev.quantidade,0) AS prev_quantity,
      curr.quantidade AS curr_quantity,
      COALESCE(prev.valor_mark_to_market,0) AS prev_value,
      curr.valor_mark_to_market AS curr_value,
      CASE
        WHEN (curr.quantidade - COALESCE(prev.quantidade,0)) > 0 THEN 'compra'
        WHEN (curr.quantidade - COALESCE(prev.quantidade,0)) < 0 THEN 'venda'
        ELSE NULL
      END AS tipo_movimento
    FROM (
      SELECT fundo_id::uuid AS fundo_id, ativo_id::uuid AS ativo_id, quantidade, valor_mark_to_market
      FROM public.snapshots_posicoes
      WHERE data_snapshot = current_date
    ) curr
    LEFT JOIN LATERAL (
      SELECT s.quantidade, s.valor_mark_to_market
      FROM public.snapshots_posicoes s
      WHERE s.fundo_id = curr.fundo_id
        AND s.ativo_id = curr.ativo_id
        AND s.data_snapshot < current_date
      ORDER BY s.data_snapshot DESC
      LIMIT 1
    ) prev ON TRUE;

    GET DIAGNOSTICS v_rows_top = ROW_COUNT;

    -- Fresh bets detection
    -- Remove fresh_bets recorded today for idempotency
    DELETE FROM public.fresh_bets WHERE first_seen = current_date;

    WITH first_seen_dates AS (
      SELECT
        s.fundo_id::uuid AS fundo_id,
        s.ativo_id::uuid AS ativo_id,
        s.data_snapshot,
        ROW_NUMBER() OVER (PARTITION BY s.fundo_id, s.ativo_id ORDER BY s.data_snapshot ASC) AS rn
      FROM public.snapshots_posicoes s
      WHERE s.data_snapshot >= (current_date - INTERVAL '90 days')
    ),
    firsts AS (
      SELECT f.fundo_id, f.ativo_id, f.data_snapshot
      FROM first_seen_dates f
      WHERE f.rn = 1
        AND f.data_snapshot >= (current_date - INTERVAL '30 days') -- first seen in last 30 days
    ),
    aggregates AS (
      SELECT fs.ativo_id,
             COUNT(DISTINCT fs.fundo_id) AS qtd_fundos
      FROM firsts fs
      GROUP BY fs.ativo_id
    )
    INSERT INTO public.fresh_bets (fundo_id, ativo_id, first_seen, last_seen, quantity, value, qtd_fundos, valor_total_investido)
    SELECT
      f.fundo_id,
      f.ativo_id,
      f.data_snapshot,
      currs.last_seen,
      COALESCE(fsnap.quantidade,0),
      COALESCE(fsnap.valor_mark_to_market,0),
      COALESCE(agg.qtd_fundos,1),
      COALESCE(fsnap.valor_mark_to_market,0)
    FROM firsts f
    LEFT JOIN (
      SELECT s.fundo_id::uuid, s.ativo_id::uuid, MAX(s.data_snapshot) AS last_seen
      FROM public.snapshots_posicoes s
      WHERE s.data_snapshot >= (current_date - INTERVAL '90 days')
      GROUP BY s.fundo_id, s.ativo_id
    ) currs ON currs.fundo_id = f.fundo_id AND currs.ativo_id = f.ativo_id
    LEFT JOIN (
      SELECT s.fundo_id::uuid, s.ativo_id::uuid, s.quantidade, s.valor_mark_to_market
      FROM public.snapshots_posicoes s
      WHERE s.data_snapshot = (SELECT MAX(data_snapshot) FROM public.snapshots_posicoes)
    ) fsnap ON fsnap.fundo_id = f.fundo_id AND fsnap.ativo_id = f.ativo_id
    LEFT JOIN aggregates agg ON agg.ativo_id = f.ativo_id;

    GET DIAGNOSTICS v_rows_fresh = ROW_COUNT;

    -- Populate participants for today's fresh_bets (idempotent)
    DELETE FROM public.fresh_bets_participantes WHERE created_at::date = current_date;

    INSERT INTO public.fresh_bets_participantes (fresh_bet_id, participante_id, quantidade, valor)
    SELECT
      fb.id AS fresh_bet_id,
      pd.participante_id::uuid,
      SUM(COALESCE(pd.quantidade,0)) AS quantidade,
      SUM(COALESCE(pd.quantidade,0) * COALESCE(a.preco,0)) AS valor
    FROM public.fresh_bets fb
    JOIN public.posicoes_detalhes pd
      ON pd.fundo_id::uuid = fb.fundo_id::uuid
     AND pd.ativo_id::uuid = fb.ativo_id::uuid
     AND pd.data_operacao >= fb.first_seen
    LEFT JOIN public.ativos a ON a.id::text = pd.ativo_id::text
    GROUP BY fb.id, pd.participante_id;

    -- Refresh materialized views safely (attempt CONCURRENTLY, fallback to non-concurrent)
    BEGIN
      PERFORM 1;
      BEGIN
        REFRESH MATERIALIZED VIEW CONCURRENTLY public.mv_fresh_bets_30d;
      EXCEPTION WHEN OTHERS THEN
        -- fallback
        REFRESH MATERIALIZED VIEW public.mv_fresh_bets_30d;
      END;
    EXCEPTION WHEN UNDEFINED_TABLE THEN
      -- materialized view doesn't exist; ignore
      PERFORM 1;
    END;

    BEGIN
      PERFORM 1;
      BEGIN
        REFRESH MATERIALIZED VIEW CONCURRENTLY public.mv_fundo_summary_mes;
      EXCEPTION WHEN OTHERS THEN
        REFRESH MATERIALIZED VIEW public.mv_fundo_summary_mes;
      END;
    EXCEPTION WHEN UNDEFINED_TABLE THEN
      PERFORM 1;
    END;

    -- Basic post-ETL sanity checks
    IF NOT EXISTS (SELECT 1 FROM public.snapshots_posicoes WHERE data_snapshot = current_date LIMIT 1) THEN
      UPDATE public.audit_etl
      SET status = 'failed', error_message = 'No snapshots created for today', notes = 'No snapshot rows - check posicoes data for current_date'
      WHERE id = v_run_id;
      RAISE NOTICE 'No snapshots created for today';
    ELSE
      UPDATE public.audit_etl
      SET status = 'success',
          rows_top_movers = v_rows_top,
          rows_fresh_bets = v_rows_fresh,
          duration_seconds = EXTRACT(EPOCH FROM (clock_timestamp() - v_start)),
          notes = 'Completed successfully'
      WHERE id = v_run_id;
    END IF;

  EXCEPTION WHEN OTHERS THEN
    v_err_msg := LEFT(SQLERRM, 2000);
    UPDATE public.audit_etl
    SET status = 'failed', error_message = v_err_msg,
        duration_seconds = EXTRACT(EPOCH FROM (clock_timestamp() - v_start)),
        notes = 'ETL error'
    WHERE id = v_run_id;
    RAISE;
  END;

  -- release advisory lock
  PERFORM pg_advisory_unlock(v_lock_key);

  RETURN;

END;
$$;

-- Grant execute to service_role commented (optional)
-- GRANT EXECUTE ON FUNCTION public.etl_populate_derivatives() TO service_role;

-- =====================================================================
-- 4) VIEWS SEGUROS PARA FRONTEND (expor somente o necessário)
-- =====================================================================

DROP VIEW IF EXISTS public.view_dashboard_fundos;
CREATE VIEW public.view_dashboard_fundos AS
SELECT
  f.id AS fundo_id,
  f.nome_fundo,
  COALESCE(pl.valor_pl, 0) AS valor_pl_atual,
  COALESCE(pl.data_competencia, current_date) AS data_competencia
FROM public.fundos f
LEFT JOIN LATERAL (
  SELECT p.valor_pl, p.data_competencia
  FROM public.patrimonio_liquido p
  WHERE p.fundo_id = f.id
  ORDER BY p.data_competencia DESC
  LIMIT 1
) pl ON true;

DROP VIEW IF EXISTS public.view_fresh_bets_summary;
CREATE VIEW public.view_fresh_bets_summary AS
SELECT
  fb.ativo_id,
  COALESCE(a.codigo, a.descricao) AS ticker,
  COUNT(DISTINCT fb.fundo_id) AS qtd_fundos,
  SUM(COALESCE(fb.value,0)) AS valor_total_investido,
  MIN(fb.first_seen) AS first_seen,
  MAX(fb.last_seen) AS last_seen
FROM public.fresh_bets fb
LEFT JOIN public.ativos a ON a.id::text = fb.ativo_id::text
GROUP BY fb.ativo_id, ticker
ORDER BY qtd_fundos DESC, valor_total_investido DESC;

-- =====================================================================
-- 5) ÍNDICES RECOMENDADOS (já em parte criados; mais sugeridos aqui)
-- =====================================================================

-- posicoes index (não-concurrent dentro PL/pgSQL)
DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_class c
    JOIN pg_namespace n ON n.oid = c.relnamespace
    WHERE c.relname = 'idx_posicoes_data_competencia'
  ) THEN
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema='public' AND table_name='posicoes' AND column_name='data_competencia') THEN
      EXECUTE 'CREATE INDEX IF NOT EXISTS idx_posicoes_data_competencia ON public.posicoes (data_competencia)';
    END IF;
  END IF;
END $$;

-- patrimonio_liquido index (não-concurrent dentro PL/pgSQL)
DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_class c
    JOIN pg_namespace n ON n.oid = c.relnamespace
    WHERE c.relname = 'idx_patrimonio_liquido_data_fundo'
  ) THEN
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema='public' AND table_name='patrimonio_liquido' AND column_name='data_competencia') THEN
      EXECUTE 'CREATE INDEX IF NOT EXISTS idx_patrimonio_liquido_data_fundo ON public.patrimonio_liquido (data_competencia, fundo_id)';
    END IF;
  END IF;
END $$;

-- If you prefer concurrent index creation (recommended in production), run these ONCE directly in the SQL editor (outside DO blocks):
-- CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_posicoes_data_competencia ON public.posicoes (data_competencia);
-- CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_patrimonio_liquido_data_fundo ON public.patrimonio_liquido (data_competencia, fundo_id);

-- trigram index suggestion for fundos.nome_fundo (if pg_trgm installed)
-- CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_fundos_nome_trgm ON public.fundos USING gin (nome_fundo gin_trgm_ops);

-- =====================================================================
-- 6) SCRIPTS DE VALIDAÇÃO SUGERIDOS (rodar manualmente após ETL)
-- =====================================================================
-- SELECT * FROM public.audit_etl ORDER BY run_at DESC LIMIT 20;
-- SELECT COUNT(*) FROM public.snapshots_posicoes WHERE data_snapshot = current_date;
-- SELECT * FROM public.top_movers WHERE data_snapshot = current_date ORDER BY pct_change DESC NULLS LAST LIMIT 50;

-- =====================================================================
-- 7) INSTRUÇÃO EXEMPLO PARA AGENDAR (pg_cron) - apenas instrução, comentada
-- =====================================================================
-- SELECT cron.schedule('etl_daily_0330', '30 3 * * *', 'SELECT public.etl_populate_derivatives();');
