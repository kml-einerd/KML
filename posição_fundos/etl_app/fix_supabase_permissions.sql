-- =====================================================================
-- SCRIPT PARA CORRIGIR PERMISSÕES DO SUPABASE
-- =====================================================================
-- Execute este script no SQL Editor do Supabase Dashboard
-- Caminho: Supabase Dashboard > SQL Editor > New Query
-- =====================================================================

-- 1. DESABILITAR RLS (Row Level Security) EM TODAS AS TABELAS
-- Isso permite que a service_role key tenha acesso total

ALTER TABLE IF EXISTS public.fundos DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.emissores DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.ativos DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.patrimonio_liquido DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.posicoes DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.posicoes_detalhes DISABLE ROW LEVEL SECURITY;

-- Tabelas de balancete (se existirem)
ALTER TABLE IF EXISTS public.fi_blc_1 DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.fi_blc_2 DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.fi_blc_3 DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.fi_blc_4 DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.fi_blc_5 DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.fi_blc_6 DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.fi_blc_7 DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.fi_blc_8 DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.fi_pl DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.fi_confid DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.fie DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.fie_confid DISABLE ROW LEVEL SECURITY;

-- Tabelas de agregações
ALTER TABLE IF EXISTS public.top_movers DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.fresh_bets DISABLE ROW LEVEL SECURITY;

-- 2. GARANTIR PERMISSÕES PARA SERVICE_ROLE
-- Isso garante que a service_role tenha permissões no schema public

GRANT USAGE ON SCHEMA public TO service_role;
GRANT ALL ON ALL TABLES IN SCHEMA public TO service_role;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO service_role;
GRANT ALL ON ALL FUNCTIONS IN SCHEMA public TO service_role;

-- 3. CONFIGURAR PERMISSÕES PADRÃO PARA NOVAS TABELAS
-- Isso garante que futuras tabelas também terão as permissões corretas

ALTER DEFAULT PRIVILEGES IN SCHEMA public
GRANT ALL ON TABLES TO service_role;

ALTER DEFAULT PRIVILEGES IN SCHEMA public
GRANT ALL ON SEQUENCES TO service_role;

ALTER DEFAULT PRIVILEGES IN SCHEMA public
GRANT ALL ON FUNCTIONS TO service_role;

-- =====================================================================
-- VERIFICAÇÃO
-- =====================================================================
-- Após executar o script acima, execute as queries abaixo para verificar:

-- Ver status do RLS em todas as tabelas
SELECT
    schemaname,
    tablename,
    rowsecurity as rls_enabled
FROM pg_tables
WHERE schemaname = 'public'
ORDER BY tablename;

-- Ver permissões do service_role
SELECT
    grantee,
    table_schema,
    table_name,
    privilege_type
FROM information_schema.table_privileges
WHERE grantee = 'service_role'
AND table_schema = 'public'
ORDER BY table_name;

-- =====================================================================
-- RESULTADO ESPERADO
-- =====================================================================
-- Todas as tabelas devem mostrar rls_enabled = false
-- service_role deve ter privilégios: INSERT, SELECT, UPDATE, DELETE
-- =====================================================================
