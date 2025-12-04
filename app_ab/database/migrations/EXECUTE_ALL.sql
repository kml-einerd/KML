-- =====================================================================
-- SCRIPT MESTRE - EXECUTAR TUDO
-- Execute este arquivo no Supabase SQL Editor para implementar tudo
-- =====================================================================

\echo '🚀 Iniciando implementação completa do Dashboard...'
\echo ''

-- =====================================================================
-- PASSO 1: Schema Completo do Dashboard
-- =====================================================================
\echo '📊 Passo 1/4: Criando schema completo...'

\i ../schema/03_dashboard_complete.sql

\echo '✅ Schema criado com sucesso!'
\echo ''

-- =====================================================================
-- PASSO 2: Funções ETL
-- =====================================================================
\echo '⚙️ Passo 2/4: Criando funções ETL...'

\i ../schema/04_etl_function.sql

\echo '✅ Funções ETL criadas!'
\echo ''

-- =====================================================================
-- PASSO 3: Popular Dados (ETL)
-- =====================================================================
\echo '📈 Passo 3/4: Populando tabelas derivadas...'
\echo 'Isso pode demorar alguns minutos...'
\echo ''

SELECT * FROM populate_all_months();

\echo '✅ Dados populados!'
\echo ''

-- =====================================================================
-- PASSO 4: Verificação Final
-- =====================================================================
\echo '🔍 Passo 4/4: Verificando implementação...'
\echo ''

-- Contar registros criados
SELECT
    'top_movers' AS tabela,
    COUNT(*) AS registros,
    MIN(data_competencia) AS data_min,
    MAX(data_competencia) AS data_max
FROM public.top_movers

UNION ALL

SELECT
    'fresh_bets' AS tabela,
    COUNT(*) AS registros,
    MIN(data_competencia) AS data_min,
    MAX(data_competencia) AS data_max
FROM public.fresh_bets;

-- Testar views
\echo ''
\echo '📋 Views disponíveis:'

SELECT
    viewname AS view_name,
    'OK' AS status
FROM pg_views
WHERE schemaname = 'public'
  AND viewname LIKE 'v_%'
ORDER BY viewname;

-- Testar funções
\echo ''
\echo '⚙️ Funções disponíveis:'

SELECT
    p.proname AS function_name,
    pg_get_function_identity_arguments(p.oid) AS arguments
FROM pg_proc p
JOIN pg_namespace n ON p.pronamespace = n.oid
WHERE n.nspname = 'public'
  AND p.proname IN (
      'populate_dashboard_data',
      'populate_all_months',
      'get_fresh_bet_participantes',
      'check_data_availability'
  )
ORDER BY p.proname;

\echo ''
\echo '✅ IMPLEMENTAÇÃO COMPLETA!'
\echo ''
\echo '📊 Próximos passos:'
\echo '1. Teste as views no dashboard'
\echo '2. Configure agendamento do ETL (opcional)'
\echo '3. Crie endpoints de API para o frontend'
\echo ''

-- =====================================================================
-- FIM DO SCRIPT MESTRE
-- =====================================================================
