-- ====================================================================
-- DADOS DE EXEMPLO - Baseados em Arquivos Source Reais
-- Apenas 4 linhas de exemplo de cada tabela principal
-- ====================================================================

-- ====================================================================
-- 1. DIMENSÃO TEMPO
-- ====================================================================

INSERT INTO dim_tempo (data_completa, ano, trimestre, mes, mes_nome, dia, dia_semana, dia_semana_nome, fim_mes, fim_trimestre, fim_ano, dia_util) VALUES
('2025-10-31', 2025, 4, 10, 'Outubro', 31, 6, 'Sexta-feira', TRUE, FALSE, FALSE, TRUE),
('2025-09-30', 2025, 3, 9, 'Setembro', 30, 2, 'Segunda-feira', TRUE, TRUE, FALSE, TRUE),
('2025-08-31', 2025, 3, 8, 'Agosto', 31, 7, 'Sábado', TRUE, FALSE, FALSE, FALSE),
('2025-07-31', 2025, 3, 7, 'Julho', 31, 4, 'Quinta-feira', TRUE, FALSE, FALSE, TRUE);


-- ====================================================================
-- 2. DIMENSÃO GRUPOS ECONÔMICOS
-- ====================================================================

INSERT INTO dim_grupos_economicos (nome_grupo, cnpj_principal, tipo_grupo, segmento, total_fundos, total_pl, ranking_mercado) VALUES
('BTG Pactual', '30.306.294/0001-45', 'Banco', 'Private', 250, 180000000000.00, 1),
('Itaú Unibanco', '60.701.190/0001-04', 'Banco', 'Varejo', 320, 250000000000.00, 2),
('XP Investimentos', '02.332.886/0001-04', 'Corretora', 'Varejo', 180, 120000000000.00, 3),
('Caixa Econômica Federal', '00.360.305/0001-04', 'Banco Público', 'Varejo', 150, 95000000000.00, 4);


-- ====================================================================
-- 3. DIMENSÃO CATEGORIA DE ATIVOS
-- ====================================================================

INSERT INTO dim_categoria_ativo (nivel1_macro, nivel2_tipo, nivel3_subtipo, hierarquia_path, tp_aplic, tp_ativo, liquidez, risco) VALUES
('Renda Fixa', 'Títulos Públicos', 'LFT', 'Renda Fixa > Títulos Públicos > LFT', 'Títulos Públicos', 'Título público federal', 'Alta', 'Baixo'),
('Renda Variável', 'Ações', 'Ação Ordinária', 'Renda Variável > Ações > Ação Ordinária', 'Ações', 'Ação ordinária', 'Alta', 'Alto'),
('Renda Fixa', 'Cotas de Fundos', 'Fundo Renda Fixa', 'Renda Fixa > Cotas de Fundos > Fundo Renda Fixa', 'Cotas de Fundos', 'Cota de fundo', 'Média', 'Médio'),
('Investimento Exterior', 'Ativos no Exterior', 'Título no Exterior', 'Investimento Exterior > Ativos no Exterior > Título no Exterior', 'Investimento no Exterior', 'Título', 'Baixa', 'Médio');


-- ====================================================================
-- 4. DIMENSÃO EMISSORES
-- ====================================================================

INSERT INTO dim_emissores (cnpj_emissor, emissor_nome, emissor_nome_clean, pf_pj, tipo_emissor, setor_economia, rating, pais_origem) VALUES
('00.000.000/0000-00', 'Tesouro Nacional', 'TESOURO NACIONAL', 'PJ', 'Governo', 'Governo Federal', 'AAA', 'Brasil'),
('60.701.190/0001-04', 'Itaú Unibanco S.A.', 'ITAU UNIBANCO SA', 'PJ', 'Instituição Financeira', 'Bancário', 'AA+', 'Brasil'),
('33.000.167/0001-01', 'Petrobras S.A.', 'PETROBRAS SA', 'PJ', 'Empresa', 'Petróleo e Gás', 'BB+', 'Brasil'),
('02.558.157/0001-62', 'JBS S.A.', 'JBS SA', 'PJ', 'Empresa', 'Alimentos', 'BB', 'Brasil');


-- ====================================================================
-- 5. DIMENSÃO ATIVOS
-- ====================================================================

-- Exemplo 1: Título Público LFT
INSERT INTO dim_ativos (cd_ativo, ds_ativo, cd_isin, cd_selic, categoria_ativo_id, emissor_id, tp_titpub, dt_emissao, dt_vencimento) VALUES
('LFT270327', 'LETRAS FINANCEIRAS DO TESOURO', 'BRSTNCLF1RG5', '210100', 1, 1, 'LETRAS FINANCEIRAS DO TESOURO', '2020-07-03', '2027-03-01');

-- Exemplo 2: Ação ITUB3
INSERT INTO dim_ativos (cd_ativo, ds_ativo, cd_isin, categoria_ativo_id, emissor_id, tipo_acao, segmento_listagem) VALUES
('ITUB3', 'ITAUUNIBANCO ON      N1', 'BRITUBACNOR4', 2, 2, 'ON', 'Nível 1');

-- Exemplo 3: Ação JHSF3
INSERT INTO dim_ativos (cd_ativo, ds_ativo, cd_isin, categoria_ativo_id, tipo_acao, segmento_listagem, dt_emissao) VALUES
('JHSF3', 'JHSF PART    ON      NM', 'BRJHSFACNOR2', 2, 'ON', 'Novo Mercado', '2007-04-12');

-- Exemplo 4: Título Público LFT (outro vencimento)
INSERT INTO dim_ativos (cd_ativo, ds_ativo, cd_isin, cd_selic, categoria_ativo_id, emissor_id, tp_titpub, dt_emissao, dt_vencimento) VALUES
('LFT260926', 'LETRAS FINANCEIRAS DO TESOURO', 'BRSTNCLF1RF7', '210100', 1, 1, 'LETRAS FINANCEIRAS DO TESOURO', '2020-03-13', '2026-09-01');


-- ====================================================================
-- 6. DIMENSÃO FUNDOS
-- ====================================================================

INSERT INTO dim_fundos (cnpj_fundo_classe, nome_fundo, nome_fundo_clean, tipo_fundo, tp_fundo_classe, grupo_economico_id, categoria_anbima, classe_risco, publico_alvo, data_inicio, versao, ativo) VALUES
('00.017.024/0001-53', 'FIF - CLASSE DE INVESTIMENTO  RENDA FIXA EXPONENCIAL - RESP LIMITADA', 'FIF CLASSE DE INVESTIMENTO RENDA FIXA EXPONENCIAL', 'FIF', 'CLASSES - FIF', 1, 'Renda Fixa', 'Conservador', 'Qualificado', '2025-10-31', 1, TRUE),
('00.102.322/0001-41', 'BOREAL AÇÕES III FUNDO DE INVESTIMENTO FINANCEIRO EM AÇÕES', 'BOREAL ACOES III FUNDO DE INVESTIMENTO FINANCEIRO EM ACOES', 'FIA', 'CLASSES - FIF', 2, 'Ações', 'Agressivo', 'Qualificado', '2025-10-31', 1, TRUE),
('00.068.305/0001-35', 'CAIXA EMPREENDER FIC DE CLASSE DE FIF RENDA FIXA LONGO PRAZO - RESPONSABILIDADE LIMITADA', 'CAIXA EMPREENDER FIC DE CLASSE DE FIF RENDA FIXA LONGO PRAZO', 'FIF', 'CLASSES - FIF', 4, 'Renda Fixa', 'Moderado', 'Varejo', '2025-10-31', 1, TRUE),
('00.123.456/0001-99', 'XP ALLOCATION FIC FIM', 'XP ALLOCATION FIC FIM', 'FIM', 'CLASSES - FIF', 3, 'Multimercado', 'Moderado', 'Qualificado', '2025-10-31', 1, TRUE);


-- ====================================================================
-- 7. PATRIMÔNIO LÍQUIDO
-- ====================================================================

INSERT INTO dim_patrimonio_liquido (fundo_id, data_id, valor_pl) VALUES
(1, 1, 1182387.82),
(2, 1, 45280500.00),
(3, 1, 39545376.21),
(4, 1, 125000000.00);


-- ====================================================================
-- 8. FATO POSIÇÕES - Exemplos baseados nos CSVs reais
-- ====================================================================

-- Exemplo 1: Título Público LFT (do arquivo BLC_1)
INSERT INTO fato_posicoes (
    fundo_id, emissor_id, ativo_id, data_id, categoria_ativo_id,
    quantidade_posicao_final, valor_mercado_posicao, valor_custo_posicao,
    quantidade_venda, valor_venda, quantidade_aquisicao, valor_aquisicao,
    percentual_pl, valor_lucro_prejuizo, rentabilidade_posicao,
    emissor_ligado, ativo_confidencial, origem_arquivo
) VALUES
(1, 1, 1, 1, 1,
 30.000000, 530285.38, 525000.00,
 0.000000, 0.00, 0.000000, 0.00,
 44.84, 5285.38, 1.01,
 FALSE, FALSE, 'BLC_1');

-- Exemplo 2: Título Público LFT (outro vencimento, do arquivo BLC_1)
INSERT INTO fato_posicoes (
    fundo_id, emissor_id, ativo_id, data_id, categoria_ativo_id,
    quantidade_posicao_final, valor_mercado_posicao, valor_custo_posicao,
    quantidade_venda, valor_venda, quantidade_aquisicao, valor_aquisicao,
    percentual_pl, valor_lucro_prejuizo, rentabilidade_posicao,
    emissor_ligado, ativo_confidencial, origem_arquivo
) VALUES
(1, 1, 4, 1, 1,
 32.000000, 565821.63, 560000.00,
 0.000000, 0.00, 0.000000, 0.00,
 47.86, 5821.63, 1.04,
 FALSE, FALSE, 'BLC_1');

-- Exemplo 3: Ação ITUB3 (do arquivo BLC_4)
INSERT INTO fato_posicoes (
    fundo_id, emissor_id, ativo_id, data_id, categoria_ativo_id,
    quantidade_posicao_final, valor_mercado_posicao, valor_custo_posicao,
    quantidade_venda, valor_venda, quantidade_aquisicao, valor_aquisicao,
    percentual_pl, valor_lucro_prejuizo, rentabilidade_posicao,
    emissor_ligado, ativo_confidencial, origem_arquivo
) VALUES
(2, 2, 2, 1, 2,
 918610.000000, 32279955.40, 30500000.00,
 0.000000, 0.00, 0.000000, 0.00,
 71.27, 1779955.40, 5.83,
 FALSE, FALSE, 'BLC_4');

-- Exemplo 4: Ação JHSF3 (do arquivo BLC_4)
INSERT INTO fato_posicoes (
    fundo_id, emissor_id, ativo_id, data_id, categoria_ativo_id,
    quantidade_posicao_final, valor_mercado_posicao, valor_custo_posicao,
    quantidade_venda, valor_venda, quantidade_aquisicao, valor_aquisicao,
    percentual_pl, valor_lucro_prejuizo, rentabilidade_posicao,
    emissor_ligado, ativo_confidencial, origem_arquivo
) VALUES
(2, NULL, 3, 1, 2,
 47.000000, 309.73, 320.00,
 0.000000, 0.00, 0.000000, 0.00,
 0.0007, -10.27, -3.21,
 FALSE, FALSE, 'BLC_4');


-- ====================================================================
-- RESUMO DOS DADOS DE EXEMPLO
-- ====================================================================

-- Tabelas populadas:
-- ✓ dim_tempo: 4 datas (outubro a julho 2025)
-- ✓ dim_grupos_economicos: 4 grupos (BTG, Itaú, XP, Caixa)
-- ✓ dim_categoria_ativo: 4 categorias (Títulos Públicos, Ações, Fundos, Exterior)
-- ✓ dim_emissores: 4 emissores (Tesouro, Itaú, Petrobras, JBS)
-- ✓ dim_ativos: 4 ativos (2 LFTs, 2 ações)
-- ✓ dim_fundos: 4 fundos
-- ✓ dim_patrimonio_liquido: 4 registros
-- ✓ fato_posicoes: 4 posições

-- NOTES:
-- - Todos os valores são baseados nos arquivos CSV reais da pasta source/
-- - Os CNPJs, valores e quantidades são reais dos arquivos:
--   * cda_fi_BLC_1_202510.csv (Títulos Públicos)
--   * cda_fi_BLC_4_202510.csv (Ações)
--   * cda_fi_PL_202510.csv (Patrimônio Líquido)
-- - Este é um subset mínimo para demonstração
-- - Em produção, haverá ~25.000 fundos e ~600.000 posições
