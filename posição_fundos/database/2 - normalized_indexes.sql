-- ============================================================================
-- ÍNDICES - SCHEMA NORMALIZADO
-- ============================================================================

-- 1. FUNDOS
CREATE INDEX IF NOT EXISTS idx_fundos_cnpj ON fundos(cnpj);
CREATE INDEX IF NOT EXISTS idx_fundos_nome ON fundos USING gin(to_tsvector('portuguese', nome_fundo));
CREATE INDEX IF NOT EXISTS idx_fundos_classe ON fundos(classe);
CREATE INDEX IF NOT EXISTS idx_fundos_grande ON fundos(is_grande_fundo) WHERE is_grande_fundo = TRUE;

-- 2. EMISSORES
CREATE INDEX IF NOT EXISTS idx_emissores_cnpj_cpf ON emissores(cnpj_cpf);
CREATE INDEX IF NOT EXISTS idx_emissores_nome ON emissores USING gin(to_tsvector('portuguese', nome_emissor));

-- 3. ATIVOS
CREATE INDEX IF NOT EXISTS idx_ativos_codigo ON ativos(codigo);
CREATE INDEX IF NOT EXISTS idx_ativos_tipo ON ativos(tipo_ativo);
CREATE INDEX IF NOT EXISTS idx_ativos_emissor ON ativos(emissor_id);

-- 4. PATRIMÔNIO LÍQUIDO
CREATE INDEX IF NOT EXISTS idx_pl_fundo_data ON patrimonio_liquido(fundo_id, data_competencia);
CREATE INDEX IF NOT EXISTS idx_pl_data ON patrimonio_liquido(data_competencia);

-- 5. POSIÇÕES
CREATE INDEX IF NOT EXISTS idx_posicoes_fundo_data ON posicoes(fundo_id, data_competencia);
CREATE INDEX IF NOT EXISTS idx_posicoes_ativo_data ON posicoes(ativo_id, data_competencia);
CREATE INDEX IF NOT EXISTS idx_posicoes_data ON posicoes(data_competencia);
CREATE INDEX IF NOT EXISTS idx_posicoes_tipo_aplicacao ON posicoes(tipo_aplicacao);
CREATE INDEX IF NOT EXISTS idx_posicoes_fundo_ativo ON posicoes(fundo_id, ativo_id);

-- 6. POSIÇÕES DETALHES
CREATE INDEX IF NOT EXISTS idx_posicoes_detalhes_posicao ON posicoes_detalhes(posicao_id);

-- 7. ANALYTICAL
CREATE INDEX IF NOT EXISTS idx_top_movers_data ON top_movers(data_competencia);
CREATE INDEX IF NOT EXISTS idx_fresh_bets_data ON fresh_bets(data_competencia);

-- 8. ANALYZE
ANALYZE fundos;
ANALYZE emissores;
ANALYZE ativos;
ANALYZE patrimonio_liquido;
ANALYZE posicoes;
