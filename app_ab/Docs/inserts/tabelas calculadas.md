BEGIN;

-- 1) snapshots_posicoes: insert latest snapshot per fundo/ativo (within 30 days)
WITH latest_pos AS (
  SELECT DISTINCT ON (fundo_id, ativo_id) id, fundo_id, ativo_id, data_competencia, qtd_posicao_final AS quantidade, valor_mercado_final AS valor_mark_to_market
  FROM public.posicoes
  WHERE data_competencia >= CURRENT_DATE - INTERVAL '30 days'
  ORDER BY fundo_id, ativo_id, data_competencia DESC
)
INSERT INTO public.snapshots_posicoes (fundo_id, ativo_id, data_snapshot, quantidade, valor_mark_to_market)
SELECT fundo_id, ativo_id, data_competencia, quantidade, valor_mark_to_market
FROM latest_pos
ON CONFLICT DO NOTHING;

-- Validate quick count
SELECT 'snapshots_inserted' AS stage, count(*) FROM public.snapshots_posicoes;

-- 2) top_movers: compute prev and curr within 30 days window, pick top 10 by absolute change
, prev_pos AS (
  SELECT DISTINCT ON (fundo_id, ativo_id) fundo_id, ativo_id, data_competencia, qtd_posicao_final AS prev_quantity, valor_mercado_final AS prev_value
  FROM public.posicoes
  WHERE data_competencia <= CURRENT_DATE - INTERVAL '7 days'
  ORDER BY fundo_id, ativo_id, data_competencia DESC
), curr_pos AS (
  SELECT DISTINCT ON (fundo_id, ativo_id) fundo_id, ativo_id, data_competencia, qtd_posicao_final AS curr_quantity, valor_mercado_final AS curr_value
  FROM public.posicoes
  WHERE data_competencia >= CURRENT_DATE - INTERVAL '7 days'
  ORDER BY fundo_id, ativo_id, data_competencia DESC
), changes AS (
  SELECT c.fundo_id, c.ativo_id, p.prev_quantity, c.curr_quantity, p.prev_value, c.curr_value,
    (c.curr_value - p.prev_value) AS change_absolute,
    CASE WHEN p.prev_value = 0 THEN NULL ELSE (c.curr_value - p.prev_value)/NULLIF(p.prev_value,0) END AS pct_change,
    COALESCE(c.data_competencia, CURRENT_DATE) AS data_snapshot
  FROM curr_pos c
  JOIN prev_pos p USING (fundo_id, ativo_id)
)
INSERT INTO public.top_movers (fundo_id, ativo_id, data_snapshot, pct_change, change_absolute, prev_quantity, curr_quantity, prev_value, curr_value)
SELECT fundo_id, ativo_id, data_snapshot, pct_change, change_absolute, prev_quantity, curr_quantity, prev_value, curr_value
FROM changes
ORDER BY ABS(change_absolute) DESC
LIMIT 10
ON CONFLICT DO NOTHING;

-- Validate quick count
SELECT 'top_movers_inserted' AS stage, count(*) FROM public.top_movers;

-- 3) fresh_bets and fresh_bets_participantes
-- need latest PL per fundo
, latest_pl AS (
  SELECT DISTINCT ON (fundo_id) fundo_id, valor_pl
  FROM public.patrimonio_liquido
  ORDER BY fundo_id, data_competencia DESC NULLS LAST
), fresh_changes AS (
  SELECT c.fundo_id, c.ativo_id, (c.curr_quantity - p.prev_quantity) AS quantity, (c.curr_value - p.prev_value) AS value, c.data_snapshot
  FROM curr_pos c
  JOIN prev_pos p USING (fundo_id, ativo_id)
  WHERE (c.curr_value - p.prev_value) > 0
)
INSERT INTO public.fresh_bets (fundo_id, ativo_id, first_seen, last_seen, quantity, value)
SELECT fc.fundo_id, fc.ativo_id, fc.data_snapshot - INTERVAL '7 days', fc.data_snapshot, fc.quantity, fc.value
FROM fresh_changes fcß
JOIN latest_pl lp ON lp.fundo_id = fc.fundo_id
WHERE fc.value >= 0.005 * COALESCE(lp.valor_pl, 0)
ON CONFLICT DO NOTHING;

-- Insert participantes
INSERT INTO public.fresh_bets_participantes (fresh_bet_id, participante_id, quantidade, valor)
SELECT fb.id, fb.fundo_id, fb.quantity, fb.value
FROM public.fresh_bets fb
LEFT JOIN public.fresh_bets_participantes p ON p.fresh_bet_id = fb.id AND p.participante_id = fb.fundo_id
WHERE p.id IS NULL
ON CONFLICT DO NOTHING;

-- Validate counts
SELECT 'fresh_bets_count' AS stage, count(*) FROM public.fresh_bets;
SELECT 'fresh_bets_participantes_count' AS stage, count(*) FROM public.fresh_bets_participantes;

-- 4) audit_etl
INSERT INTO public.audit_etl (status, rows_top_movers, rows_fresh_bets, notes)
VALUES ('completed', (SELECT count(*) FROM public.top_movers), (SELECT count(*) FROM public.fresh_bets), 'ETL run: snapshots, top_movers, fresh_bets')
RETURNING id, run_at, status;

COMMIT;