-- ============================================================================
-- SCRIPT DE RESET E CRIAÇÃO DE TABELAS - RADAR INSTITUCIONAL
-- ============================================================================
-- ATENÇÃO: Este script APAGA todas as tabelas existentes e cria novas.
-- Execute com cautela!

-- 1. DROP TABLES (Ordem inversa de dependência)
DROP TABLE IF EXISTS top_movers CASCADE;
DROP TABLE IF EXISTS fi_blc_1 CASCADE;
DROP TABLE IF EXISTS fi_blc_2 CASCADE;
DROP TABLE IF EXISTS fi_blc_3 CASCADE;
DROP TABLE IF EXISTS fi_blc_4 CASCADE;
DROP TABLE IF EXISTS fi_blc_5 CASCADE;
DROP TABLE IF EXISTS fi_blc_6 CASCADE;
DROP TABLE IF EXISTS fi_blc_7 CASCADE;
DROP TABLE IF EXISTS fi_blc_8 CASCADE;
DROP TABLE IF EXISTS fi_confid CASCADE;
DROP TABLE IF EXISTS fi_pl CASCADE;
DROP TABLE IF EXISTS fie CASCADE;
DROP TABLE IF EXISTS fie_confid CASCADE;
DROP TABLE IF EXISTS fundos CASCADE;
DROP TABLE IF EXISTS posicoes_acoes CASCADE; -- Tabela antiga, se existir

-- 2. CREATE TABLES

-- Tabela Mestra de Fundos
CREATE TABLE fundos (
    cnpj TEXT PRIMARY KEY,
    nome_fundo TEXT,
    is_grande_fundo BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Tabela de Patrimônio Líquido (fi_pl)
CREATE TABLE fi_pl (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    cnpj_fundo_classe TEXT,
    denom_social TEXT,
    dt_comptc DATE,
    vl_patrim_liq NUMERIC,
    mes_referencia DATE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(cnpj_fundo_classe, dt_comptc, mes_referencia)
);

-- Template para tabelas de Balancete (BLC 1-8)
-- Inclui todas as colunas possíveis mapeadas no config.py
CREATE TABLE fi_blc_1 (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    cnpj_fundo_classe TEXT,
    tp_fundo_classe TEXT,
    denom_social TEXT,
    dt_comptc DATE,
    tp_aplic TEXT,
    tp_ativo TEXT,
    cd_ativo TEXT,
    ds_ativo TEXT,
    emissor_ligado TEXT,
    tp_negoc TEXT,
    qt_venda_negoc NUMERIC,
    vl_venda_negoc NUMERIC,
    qt_aquis_negoc NUMERIC,
    vl_aquis_negoc NUMERIC,
    qt_pos_final NUMERIC,
    vl_merc_pos_final NUMERIC,
    vl_custo_pos_final NUMERIC,
    dt_confid_aplic DATE,
    dt_venc DATE,
    cd_selic TEXT,
    dt_ini_vigencia DATE,
    cnpj_emissor TEXT,
    emissor TEXT,
    titulo_posfx TEXT,
    cd_indexador_posfx TEXT,
    ds_indexador_posfx TEXT,
    pr_indexador_posfx NUMERIC,
    pr_cupom_posfx NUMERIC,
    pr_taxa_prefx NUMERIC,
    risco_emissor TEXT,
    ag_risco TEXT,
    dt_risco DATE,
    grau_risco TEXT,
    pf_pj_emissor TEXT,
    cpf_cnpj_emissor TEXT,
    cnpj_fundo_invest TEXT,
    fundo_invest TEXT,
    id_doc TEXT,
    mes_referencia DATE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(cnpj_fundo_classe, dt_comptc, cd_ativo, mes_referencia)
);

-- Replicar estrutura para outras tabelas BLC (com ajustes nas chaves únicas conforme config.py)

CREATE TABLE fi_blc_2 (LIKE fi_blc_1 INCLUDING ALL);
ALTER TABLE fi_blc_2 DROP CONSTRAINT IF EXISTS fi_blc_2_cnpj_fundo_classe_dt_comptc_cd_ativo_mes_referenc_key;
ALTER TABLE fi_blc_2 ADD UNIQUE (cnpj_fundo_classe, dt_comptc, cnpj_emissor, dt_venc, mes_referencia);

CREATE TABLE fi_blc_3 (LIKE fi_blc_1 INCLUDING ALL);
-- Mantém a unique key padrão (cnpj, data, ativo)

CREATE TABLE fi_blc_4 (LIKE fi_blc_1 INCLUDING ALL);
ALTER TABLE fi_blc_4 DROP CONSTRAINT IF EXISTS fi_blc_4_cnpj_fundo_classe_dt_comptc_cd_ativo_mes_referenc_key;
ALTER TABLE fi_blc_4 ADD UNIQUE (cnpj_fundo_classe, dt_comptc, cnpj_fundo_invest, mes_referencia);

CREATE TABLE fi_blc_5 (LIKE fi_blc_1 INCLUDING ALL);
-- Derivativos podem ter chaves complexas, mantendo padrão ou ajustando se necessário
-- Ajuste conforme config: cd_ativo_derivativo (assumindo que entra em cd_ativo ou ds_ativo)

CREATE TABLE fi_blc_6 (LIKE fi_blc_1 INCLUDING ALL);
ALTER TABLE fi_blc_6 DROP CONSTRAINT IF EXISTS fi_blc_6_cnpj_fundo_classe_dt_comptc_cd_ativo_mes_referenc_key;
ALTER TABLE fi_blc_6 ADD UNIQUE (cnpj_fundo_classe, dt_comptc, cpf_cnpj_emissor, dt_venc, mes_referencia);

CREATE TABLE fi_blc_7 (LIKE fi_blc_1 INCLUDING ALL);
-- Ativos no exterior

CREATE TABLE fi_blc_8 (LIKE fi_blc_1 INCLUDING ALL);
ALTER TABLE fi_blc_8 DROP CONSTRAINT IF EXISTS fi_blc_8_cnpj_fundo_classe_dt_comptc_cd_ativo_mes_referenc_key;
ALTER TABLE fi_blc_8 ADD UNIQUE (cnpj_fundo_classe, dt_comptc, ds_ativo, mes_referencia);

CREATE TABLE fi_confid (LIKE fi_blc_1 INCLUDING ALL);
ALTER TABLE fi_confid DROP CONSTRAINT IF EXISTS fi_confid_cnpj_fundo_classe_dt_comptc_cd_ativo_mes_referenc_key;
ALTER TABLE fi_confid ADD UNIQUE (cnpj_fundo_classe, dt_comptc, tp_aplic, mes_referencia);

CREATE TABLE fie (LIKE fi_blc_1 INCLUDING ALL);

CREATE TABLE fie_confid (LIKE fi_blc_1 INCLUDING ALL);
ALTER TABLE fie_confid DROP CONSTRAINT IF EXISTS fie_confid_cnpj_fundo_classe_dt_comptc_cd_ativo_mes_referenc_key;
ALTER TABLE fie_confid ADD UNIQUE (cnpj_fundo_classe, dt_comptc, tp_aplic, mes_referencia);

-- Tabela Top Movers (Agregações)
CREATE TABLE top_movers (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    cnpj_fundo TEXT,
    nome_fundo TEXT,
    ticker TEXT,
    variacao_qtd NUMERIC,
    variacao_valor NUMERIC,
    pct_variacao NUMERIC,
    tipo_movimento TEXT,
    data_competencia DATE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(cnpj_fundo, data_competencia, ticker)
);

-- 3. PERMISSÕES E RLS (LIBERAÇÃO TOTAL)

-- Função helper para liberar tabela
CREATE OR REPLACE FUNCTION liberar_tabela(tabela text) RETURNS void AS $$
BEGIN
    EXECUTE format('ALTER TABLE %I ENABLE ROW LEVEL SECURITY', tabela);
    EXECUTE format('DROP POLICY IF EXISTS "Acesso Total" ON %I', tabela);
    EXECUTE format('CREATE POLICY "Acesso Total" ON %I FOR ALL USING (true) WITH CHECK (true)', tabela);
    EXECUTE format('GRANT ALL ON %I TO anon, authenticated, service_role', tabela);
END;
$$ LANGUAGE plpgsql;

-- Aplicar liberações
SELECT liberar_tabela('fundos');
SELECT liberar_tabela('fi_pl');
SELECT liberar_tabela('fi_blc_1');
SELECT liberar_tabela('fi_blc_2');
SELECT liberar_tabela('fi_blc_3');
SELECT liberar_tabela('fi_blc_4');
SELECT liberar_tabela('fi_blc_5');
SELECT liberar_tabela('fi_blc_6');
SELECT liberar_tabela('fi_blc_7');
SELECT liberar_tabela('fi_blc_8');
SELECT liberar_tabela('fi_confid');
SELECT liberar_tabela('fie');
SELECT liberar_tabela('fie_confid');
SELECT liberar_tabela('top_movers');

-- Cleanup
DROP FUNCTION liberar_tabela(text);

-- ============================================================================
-- FIM DO SCRIPT
-- ============================================================================
