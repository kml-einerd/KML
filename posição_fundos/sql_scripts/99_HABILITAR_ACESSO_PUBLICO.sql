-- ========================================
-- HABILITAR ACESSO PÚBLICO (DASHBOARD)
-- Execute no Supabase SQL Editor
-- ========================================

-- ⚠️ IMPORTANTE: Este script permite acesso público de LEITURA
-- para as tabelas e views do dashboard.
-- Os dados são públicos (CVM), então é seguro.

-- ========================================
-- DESABILITAR RLS (Opção mais simples)
-- ========================================

-- OPÇÃO 1: Desabilitar RLS completamente (RECOMENDADO para este caso)
-- Como os dados são públicos (CVM), não há problema

ALTER TABLE grupos_fundos DISABLE ROW LEVEL SECURITY;
ALTER TABLE acoes_fundos DISABLE ROW LEVEL SECURITY;
ALTER TABLE resumo_mensal DISABLE ROW LEVEL SECURITY;

-- Verificar
SELECT tablename, rowsecurity
FROM pg_tables
WHERE schemaname = 'public'
  AND tablename IN ('grupos_fundos', 'acoes_fundos', 'resumo_mensal');

-- Deve mostrar rowsecurity = false para todas

SELECT '✅ RLS desabilitado! Dashboard deve funcionar agora.' AS status;


-- ========================================
-- OU: CRIAR POLÍTICAS RLS (Opção mais segura)
-- ========================================

-- Se você preferir manter RLS habilitado mas permitir leitura pública:

/*
-- Habilitar RLS
ALTER TABLE grupos_fundos ENABLE ROW LEVEL SECURITY;
ALTER TABLE acoes_fundos ENABLE ROW LEVEL SECURITY;
ALTER TABLE resumo_mensal ENABLE ROW LEVEL SECURITY;

-- Criar políticas de leitura pública
CREATE POLICY "Permitir leitura pública grupos_fundos"
    ON grupos_fundos
    FOR SELECT
    USING (true);

CREATE POLICY "Permitir leitura pública acoes_fundos"
    ON acoes_fundos
    FOR SELECT
    USING (true);

CREATE POLICY "Permitir leitura pública resumo_mensal"
    ON resumo_mensal
    FOR SELECT
    USING (true);

-- Verificar políticas
SELECT schemaname, tablename, policyname, permissive, roles, cmd
FROM pg_policies
WHERE schemaname = 'public';

SELECT '✅ Políticas RLS criadas! Dashboard deve funcionar agora.' AS status;
*/

-- ========================================
-- NOTAS
-- ========================================

/*
QUAL OPÇÃO USAR?

OPÇÃO 1 (DESABILITAR RLS) - RECOMENDADO:
✅ Mais simples
✅ Funciona direto
✅ Dados são públicos mesmo (CVM)
✅ Sem complexidade

OPÇÃO 2 (POLÍTICAS RLS):
✅ Mais seguro tecnicamente
✅ Permite controle futuro
❌ Mais complexo
❌ Precisa criar políticas

RECOMENDAÇÃO: Use OPÇÃO 1 (desabilitar RLS)
*/
