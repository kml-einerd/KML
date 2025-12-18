-- ========================================
-- SCRIPT DE LIMPEZA COMPLETA
-- Execute PRIMEIRO para limpar tudo do V1
-- ========================================

-- Desabilitar verificação de foreign keys temporariamente
SET session_replication_role = 'replica';

-- ========================================
-- DELETAR TABELAS DO V1 (antigas)
-- ========================================

DROP TABLE IF EXISTS ranking_top100_grupos CASCADE;
DROP TABLE IF EXISTS dim_patrimonio_liquido CASCADE;
DROP TABLE IF EXISTS fato_posicoes CASCADE;
DROP TABLE IF EXISTS dim_fundos CASCADE;
DROP TABLE IF EXISTS dim_grupos_economicos CASCADE;
DROP TABLE IF EXISTS dim_gestores CASCADE;
DROP TABLE IF EXISTS dim_tempo CASCADE;
DROP TABLE IF EXISTS dim_ativos CASCADE;
DROP TABLE IF EXISTS dim_emissores CASCADE;
DROP TABLE IF EXISTS dim_categoria_ativo CASCADE;
DROP TABLE IF EXISTS dim_acoes_b3 CASCADE;

-- ========================================
-- DELETAR VIEWS ANTIGAS
-- ========================================

DROP VIEW IF EXISTS v_top100_atual CASCADE;
DROP VIEW IF EXISTS v_top100_por_volume CASCADE;
DROP VIEW IF EXISTS v_maiores_compradores CASCADE;
DROP VIEW IF EXISTS v_maiores_vendedores CASCADE;
DROP VIEW IF EXISTS v_dashboard_top100 CASCADE;
DROP VIEW IF EXISTS v_dashboard_top100_rentabilidade CASCADE;
DROP VIEW IF EXISTS v_ranking_por_rentabilidade CASCADE;
DROP VIEW IF EXISTS v_melhores_decisoes_grupos CASCADE;
DROP VIEW IF EXISTS v_fluxo_liquido_acoes_top100 CASCADE;
DROP VIEW IF EXISTS v_movimentacoes_acoes_top100 CASCADE;
DROP VIEW IF EXISTS v_concentracao_setor_acoes CASCADE;
DROP VIEW IF EXISTS v_ranking_compras_top100 CASCADE;
DROP VIEW IF EXISTS v_ranking_vendas_top100 CASCADE;

-- ========================================
-- DELETAR FUNÇÕES ANTIGAS
-- ========================================

DROP FUNCTION IF EXISTS get_or_create_data_id(DATE) CASCADE;
DROP FUNCTION IF EXISTS get_or_create_grupo_id(VARCHAR) CASCADE;
DROP FUNCTION IF EXISTS get_or_create_fundo_id(VARCHAR, TEXT, INTEGER) CASCADE;
DROP FUNCTION IF EXISTS upsert_patrimonio_liquido_top100(JSONB) CASCADE;
DROP FUNCTION IF EXISTS atualizar_ranking_top100(INTEGER, INTEGER) CASCADE;
DROP FUNCTION IF EXISTS atualizar_ranking_top100_v2(INTEGER, INTEGER) CASCADE;

-- ========================================
-- DELETAR TABELAS DO V2 (caso existam)
-- ========================================

DROP TABLE IF EXISTS resumo_mensal CASCADE;
DROP TABLE IF EXISTS acoes_fundos CASCADE;
DROP TABLE IF EXISTS grupos_fundos CASCADE;

-- ========================================
-- DELETAR VIEWS DO V2 (caso existam)
-- ========================================

DROP VIEW IF EXISTS v_top_compras_mes CASCADE;
DROP VIEW IF EXISTS v_top_vendas_mes CASCADE;
DROP VIEW IF EXISTS v_movimentos_grupo CASCADE;
DROP VIEW IF EXISTS v_consenso_mercado CASCADE;

-- ========================================
-- DELETAR FUNÇÕES DO V2 (caso existam)
-- ========================================

DROP FUNCTION IF EXISTS atualizar_resumo_mensal(DATE) CASCADE;

-- Reabilitar verificação de foreign keys
SET session_replication_role = 'origin';

-- ========================================
-- VERIFICAÇÃO
-- ========================================

-- Listar tabelas restantes
SELECT 'Tabelas restantes:' AS info;
SELECT table_name
FROM information_schema.tables
WHERE table_schema = 'public'
  AND table_type = 'BASE TABLE'
ORDER BY table_name;

-- Deve retornar vazio ou apenas tabelas do sistema

-- ========================================
-- CONCLUÍDO
-- ========================================

SELECT '✅ Limpeza concluída! Agora execute: 01_CRIAR_SCHEMA_V2.sql' AS status;
