-- ============================================
-- Script para DROPAR todas as tabelas antigas
-- Execute no Supabase SQL Editor
-- ============================================

-- Dropar tabelas na ordem correta (respeitar foreign keys)
DROP TABLE IF EXISTS cotacoes_snapshot CASCADE;
DROP TABLE IF EXISTS precos_diarios CASCADE;
DROP TABLE IF EXISTS fundamentos CASCADE;
DROP TABLE IF EXISTS acoes CASCADE;

-- Confirmar que todas foram removidas
SELECT 'Todas as tabelas foram removidas com sucesso!' as status;
