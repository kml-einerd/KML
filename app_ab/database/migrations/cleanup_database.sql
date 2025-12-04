-- =====================================================================
-- LIMPEZA DO BANCO DE DADOS
-- Remove todos os objetos EXCETO as 10 tabelas especificadas
-- =====================================================================
-- IMPORTANTE: Execute este script no Supabase SQL Editor
-- =====================================================================

BEGIN;

-- Mensagem inicial
DO $$
BEGIN
    RAISE NOTICE '🧹 Iniciando limpeza do banco de dados...';
END $$;

-- =====================================================================
-- 1. REMOVER MATERIALIZED VIEWS
-- =====================================================================
DO $$
BEGIN
    RAISE NOTICE '📋 Removendo Materialized Views...';
END $$;

DROP MATERIALIZED VIEW IF EXISTS public.mv_fresh_bets_30d CASCADE;
DROP MATERIALIZED VIEW IF EXISTS public.mv_fundo_summary_mes CASCADE;

-- =====================================================================
-- 2. REMOVER VIEWS
-- =====================================================================
DO $$
BEGIN
    RAISE NOTICE '👁️  Removendo Views...';
END $$;

DROP VIEW IF EXISTS public.view_dashboard_fundos CASCADE;
DROP VIEW IF EXISTS public.view_fresh_bets_summary CASCADE;

-- =====================================================================
-- 3. REMOVER TRIGGERS
-- =====================================================================
DO $$
BEGIN
    RAISE NOTICE '⚡ Removendo Triggers...';
END $$;

DROP TRIGGER IF EXISTS trg_top_movers_sync ON public.top_movers;
DROP TRIGGER IF EXISTS update_fundos_updated_at ON public.fundos;
DROP TRIGGER IF EXISTS update_emissores_updated_at ON public.emissores;
DROP TRIGGER IF EXISTS update_ativos_updated_at ON public.ativos;
DROP TRIGGER IF EXISTS update_pl_updated_at ON public.patrimonio_liquido;
DROP TRIGGER IF EXISTS update_posicoes_updated_at ON public.posicoes;
DROP TRIGGER IF EXISTS update_posicoes_det_updated_at ON public.posicoes_detalhes;

-- =====================================================================
-- 4. REMOVER TABELAS NÃO DESEJADAS
-- =====================================================================
DO $$
BEGIN
    RAISE NOTICE '🗑️  Removendo Tabelas não desejadas...';
END $$;

-- Ordem de remoção respeitando foreign keys
DROP TABLE IF EXISTS public.fresh_bets_participantes CASCADE;
DROP TABLE IF EXISTS public.snapshots_posicoes CASCADE;
DROP TABLE IF EXISTS public.audit_etl CASCADE;

-- =====================================================================
-- 5. REMOVER FUNÇÕES
-- =====================================================================
DO $$
BEGIN
    RAISE NOTICE '⚙️  Removendo Funções...';
END $$;

DROP FUNCTION IF EXISTS public.etl_populate_derivatives() CASCADE;
DROP FUNCTION IF EXISTS public.sync_top_movers_aliases() CASCADE;
DROP FUNCTION IF EXISTS public.has_data_for_month(DATE, DATE) CASCADE;
DROP FUNCTION IF EXISTS public.update_updated_at_column() CASCADE;

-- =====================================================================
-- 6. VERIFICAÇÃO FINAL
-- =====================================================================
DO $$
DECLARE
    table_count INTEGER;
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '✅ Limpeza concluída!';
    RAISE NOTICE '';
    RAISE NOTICE '📊 Tabelas restantes no schema public:';

    FOR table_count IN
        SELECT tablename FROM pg_tables WHERE schemaname = 'public' ORDER BY tablename
    LOOP
        RAISE NOTICE '   • %', table_count;
    END LOOP;
END $$;

-- Verificação SQL
SELECT
    '✅ Tabelas mantidas:' as status,
    count(*) as total
FROM pg_tables
WHERE schemaname = 'public';

SELECT
    tablename as "Tabela",
    pg_size_pretty(pg_total_relation_size('public.'||tablename)) as "Tamanho"
FROM pg_tables
WHERE schemaname = 'public'
ORDER BY tablename;

COMMIT;

-- =====================================================================
-- FIM DA LIMPEZA
-- =====================================================================
