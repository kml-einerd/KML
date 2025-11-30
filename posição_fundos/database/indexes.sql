-- ===============================================
-- RADAR INSTITUCIONAL - Performance Indexes
-- ===============================================
--
-- Índices otimizados para queries do MVP
--
-- IMPORTANTE: Executar APÓS o schema.sql
-- ===============================================

-- ==========================================
-- ÍNDICES - TABELA: posicoes_acoes
-- ==========================================
-- Esta é a tabela mais pesada (150k+ registros)

-- Consultas por data (filtragem principal no MVP)
CREATE INDEX IF NOT EXISTS idx_posicoes_data
    ON posicoes_acoes(data_competencia);

-- Consultas por ticker (busca de ações específicas)
CREATE INDEX IF NOT EXISTS idx_posicoes_ticker
    ON posicoes_acoes(ticker);

-- Consultas combinadas (fundo + data) - muito comum
CREATE INDEX IF NOT EXISTS idx_posicoes_fundo_data
    ON posicoes_acoes(cnpj_fundo, data_competencia);

-- Consultas por ticker + data (drill-down em ativos)
CREATE INDEX IF NOT EXISTS idx_posicoes_ticker_data
    ON posicoes_acoes(ticker, data_competencia);

-- Índice para somas/agregações de valores
CREATE INDEX IF NOT EXISTS idx_posicoes_valores
    ON posicoes_acoes(data_competencia, valor_mercado_final)
    WHERE valor_mercado_final > 0;

-- ==========================================
-- ÍNDICES - TABELA: patrimonio_liquido_mensal
-- ==========================================

-- Consultas por fundo (JOIN com posicoes_acoes)
CREATE INDEX IF NOT EXISTS idx_pl_fundo
    ON patrimonio_liquido_mensal(cnpj_fundo);

-- Consultas por data
CREATE INDEX IF NOT EXISTS idx_pl_data
    ON patrimonio_liquido_mensal(data_competencia);

-- Combinado (otimiza JOINs)
CREATE INDEX IF NOT EXISTS idx_pl_fundo_data
    ON patrimonio_liquido_mensal(cnpj_fundo, data_competencia);

-- ==========================================
-- ÍNDICES - TABELA: fundos
-- ==========================================

-- Filtrar apenas grandes fundos (WHERE is_grande_fundo = TRUE)
CREATE INDEX IF NOT EXISTS idx_fundos_grandes
    ON fundos(is_grande_fundo)
    WHERE is_grande_fundo = TRUE;

-- Busca por nome de fundo (case-insensitive)
CREATE INDEX IF NOT EXISTS idx_fundos_nome
    ON fundos USING gin(to_tsvector('portuguese', nome_fundo));

-- Busca por gestora
CREATE INDEX IF NOT EXISTS idx_fundos_gestora
    ON fundos(gestora);

-- ==========================================
-- ÍNDICES - TABELA: top_movers
-- ==========================================

-- Consultas por data (seletor de mês)
CREATE INDEX IF NOT EXISTS idx_topmovers_data
    ON top_movers(data_competencia);

-- Ordenação por ranking de compradores
CREATE INDEX IF NOT EXISTS idx_topmovers_ranking_compradores
    ON top_movers(data_competencia, ranking_compradores)
    WHERE ranking_compradores <= 20;

-- Ordenação por ranking de vendedores
CREATE INDEX IF NOT EXISTS idx_topmovers_ranking_vendedores
    ON top_movers(data_competencia, ranking_vendedores)
    WHERE ranking_vendedores <= 20;

-- Ordenação por fluxo líquido (maior para menor)
CREATE INDEX IF NOT EXISTS idx_topmovers_fluxo
    ON top_movers(data_competencia, fluxo_liquido DESC);

-- ==========================================
-- ÍNDICES - TABELA: fresh_bets
-- ==========================================

-- Consultas por data
CREATE INDEX IF NOT EXISTS idx_freshbets_data
    ON fresh_bets(data_competencia);

-- Ordenação por consenso (número de fundos)
CREATE INDEX IF NOT EXISTS idx_freshbets_consenso
    ON fresh_bets(data_competencia, num_fundos_entraram DESC);

-- Busca por ticker específico
CREATE INDEX IF NOT EXISTS idx_freshbets_ticker
    ON fresh_bets(ticker);

-- Índice para queries com threshold mínimo
CREATE INDEX IF NOT EXISTS idx_freshbets_min_fundos
    ON fresh_bets(data_competencia, num_fundos_entraram)
    WHERE num_fundos_entraram >= 3;

-- ==========================================
-- ÍNDICES - TABELA: ativos_metadata
-- ==========================================

-- Busca por nome de empresa (case-insensitive)
CREATE INDEX IF NOT EXISTS idx_ativos_nome
    ON ativos_metadata USING gin(to_tsvector('portuguese', nome_empresa));

-- Filtrar por setor
CREATE INDEX IF NOT EXISTS idx_ativos_setor
    ON ativos_metadata(setor);

-- Filtrar por tipo (Ação, FII, BDR)
CREATE INDEX IF NOT EXISTS idx_ativos_tipo
    ON ativos_metadata(tipo);

-- ==========================================
-- ÍNDICES COMPOSTOS ESPECIALIZADOS
-- ==========================================

-- Para query "Ativos Mais Populares" (GROUP BY ticker + COUNT fundos)
CREATE INDEX IF NOT EXISTS idx_posicoes_popularidade
    ON posicoes_acoes(data_competencia, ticker, cnpj_fundo)
    WHERE valor_mercado_final > 1000000; -- > R$ 1M

-- Para drill-down em fundos (expandir detalhes de um fundo)
CREATE INDEX IF NOT EXISTS idx_posicoes_drilldown
    ON posicoes_acoes(cnpj_fundo, data_competencia, valor_compra DESC);

-- ==========================================
-- ANÁLISE E MANUTENÇÃO
-- ==========================================

-- Após criar os índices, analisar tabelas para otimizar query planner
ANALYZE fundos;
ANALYZE patrimonio_liquido_mensal;
ANALYZE posicoes_acoes;
ANALYZE top_movers;
ANALYZE fresh_bets;
ANALYZE ativos_metadata;

-- ==========================================
-- ESTATÍSTICAS DE ÍNDICES
-- ==========================================

-- Para verificar uso dos índices:
-- SELECT schemaname, tablename, indexname, idx_scan, idx_tup_read, idx_tup_fetch
-- FROM pg_stat_user_indexes
-- WHERE schemaname = 'public'
-- ORDER BY idx_scan DESC;

-- Para verificar tamanho dos índices:
-- SELECT
--     tablename,
--     indexname,
--     pg_size_pretty(pg_relation_size(indexrelid)) as index_size
-- FROM pg_stat_user_indexes
-- WHERE schemaname = 'public'
-- ORDER BY pg_relation_size(indexrelid) DESC;

-- ===============================================
-- FIM DOS ÍNDICES
-- ===============================================
