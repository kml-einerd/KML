-- ====================================================================
-- VIEWS PARA ANÁLISE DE MOVIMENTAÇÕES DE AÇÕES
-- Foco em compra, venda e análise de tendências
-- ====================================================================

-- ====================================================================
-- VIEW 1: Movimentações Detalhadas por Ação
-- Mostra todas as operações de compra/venda com valores
-- ====================================================================

CREATE OR REPLACE VIEW v_movimentacoes_acoes AS
SELECT
    -- Identificação
    t.data_completa,
    t.ano,
    t.mes,
    t.mes_nome,

    -- Ação
    acoes.ticker,
    acoes.empresa_nome,
    acoes.setor,
    acoes.subsetor,
    acoes.capitalizacao_faixa,
    acoes.liquidez_classificacao,
    acoes.categoria_analise,

    -- Fundo
    f.cnpj_fundo_classe,
    f.nome_fundo,
    g.nome_grupo,
    g.tipo_grupo,

    -- Métricas de Posição
    fp.quantidade_posicao_final,
    fp.valor_mercado_posicao,
    fp.valor_custo_posicao,
    fp.percentual_pl,

    -- Movimentações (COMPRA/VENDA)
    fp.quantidade_aquisicao AS qtd_compra,
    fp.valor_aquisicao AS valor_compra,
    fp.quantidade_venda AS qtd_venda,
    fp.valor_venda AS valor_venda,

    -- Saldo Líquido
    (fp.valor_aquisicao - fp.valor_venda) AS saldo_liquido,

    -- Indicadores
    CASE
        WHEN fp.valor_aquisicao > fp.valor_venda THEN 'COMPRA'
        WHEN fp.valor_venda > fp.valor_aquisicao THEN 'VENDA'
        ELSE 'SEM MOVIMENTAÇÃO'
    END AS tipo_movimentacao,

    -- Rentabilidade
    fp.valor_lucro_prejuizo,
    fp.rentabilidade_posicao,

    -- Patrimônio Líquido do Fundo
    pl.valor_pl AS pl_fundo

FROM fato_posicoes fp
JOIN dim_tempo t ON fp.data_id = t.id
JOIN dim_fundos f ON fp.fundo_id = f.id
LEFT JOIN dim_grupos_economicos g ON f.grupo_economico_id = g.id
JOIN dim_ativos a ON fp.ativo_id = a.id
JOIN dim_acoes_b3 acoes ON a.id = acoes.ativo_id
LEFT JOIN dim_patrimonio_liquido pl ON fp.fundo_id = pl.fundo_id AND fp.data_id = pl.data_id
WHERE fp.categoria_ativo_id IN (
    SELECT id FROM dim_categoria_ativo WHERE nivel1_macro = 'Renda Variável'
);

COMMENT ON VIEW v_movimentacoes_acoes IS 'Movimentações detalhadas de compra/venda de ações por fundo';


-- ====================================================================
-- VIEW 2: Ranking de Compras do Mês
-- Quais ações os fundos MAIS COMPRARAM no mês
-- ====================================================================

CREATE OR REPLACE VIEW v_ranking_compras_mes AS
SELECT
    ano,
    mes,
    mes_nome,
    ticker,
    empresa_nome,
    setor,
    categoria_analise,

    -- Agregações
    COUNT(DISTINCT cnpj_fundo_classe) AS qtd_fundos_compradores,
    SUM(valor_compra) AS total_comprado,
    AVG(valor_compra) AS media_compra_por_fundo,
    SUM(qtd_compra) AS total_quantidade_comprada,

    -- Rank
    RANK() OVER (PARTITION BY ano, mes ORDER BY SUM(valor_compra) DESC) AS ranking_compra

FROM v_movimentacoes_acoes
WHERE tipo_movimentacao = 'COMPRA'
GROUP BY ano, mes, mes_nome, ticker, empresa_nome, setor, categoria_analise;

COMMENT ON VIEW v_ranking_compras_mes IS 'Ranking das ações mais compradas pelos fundos no mês';


-- ====================================================================
-- VIEW 3: Ranking de Vendas do Mês
-- Quais ações os fundos MAIS VENDERAM no mês
-- ====================================================================

CREATE OR REPLACE VIEW v_ranking_vendas_mes AS
SELECT
    ano,
    mes,
    mes_nome,
    ticker,
    empresa_nome,
    setor,
    categoria_analise,

    -- Agregações
    COUNT(DISTINCT cnpj_fundo_classe) AS qtd_fundos_vendedores,
    SUM(valor_venda) AS total_vendido,
    AVG(valor_venda) AS media_venda_por_fundo,
    SUM(qtd_venda) AS total_quantidade_vendida,

    -- Rank
    RANK() OVER (PARTITION BY ano, mes ORDER BY SUM(valor_venda) DESC) AS ranking_venda

FROM v_movimentacoes_acoes
WHERE tipo_movimentacao = 'VENDA'
GROUP BY ano, mes, mes_nome, ticker, empresa_nome, setor, categoria_analise;

COMMENT ON VIEW v_ranking_vendas_mes IS 'Ranking das ações mais vendidas pelos fundos no mês';


-- ====================================================================
-- VIEW 4: Fluxo Líquido por Ação
-- Saldo líquido (compra - venda) por ação
-- ====================================================================

CREATE OR REPLACE VIEW v_fluxo_liquido_acoes AS
SELECT
    ano,
    mes,
    mes_nome,
    ticker,
    empresa_nome,
    setor,
    subsetor,
    categoria_analise,

    -- Volume Total
    SUM(valor_compra) AS total_compras,
    SUM(valor_venda) AS total_vendas,
    SUM(saldo_liquido) AS fluxo_liquido,

    -- Quantidade
    SUM(qtd_compra) AS qtd_total_comprada,
    SUM(qtd_venda) AS qtd_total_vendida,
    SUM(qtd_compra - qtd_venda) AS saldo_quantidade,

    -- Fundos Participantes
    COUNT(DISTINCT CASE WHEN valor_compra > 0 THEN cnpj_fundo_classe END) AS fundos_compradores,
    COUNT(DISTINCT CASE WHEN valor_venda > 0 THEN cnpj_fundo_classe END) AS fundos_vendedores,
    COUNT(DISTINCT cnpj_fundo_classe) AS total_fundos,

    -- Classificação
    CASE
        WHEN SUM(saldo_liquido) > 1000000 THEN 'FORTE COMPRA'
        WHEN SUM(saldo_liquido) > 0 THEN 'COMPRA MODERADA'
        WHEN SUM(saldo_liquido) < -1000000 THEN 'FORTE VENDA'
        WHEN SUM(saldo_liquido) < 0 THEN 'VENDA MODERADA'
        ELSE 'NEUTRO'
    END AS tendencia_mercado

FROM v_movimentacoes_acoes
GROUP BY ano, mes, mes_nome, ticker, empresa_nome, setor, subsetor, categoria_analise;

COMMENT ON VIEW v_fluxo_liquido_acoes IS 'Fluxo líquido (compra - venda) por ação no período';


-- ====================================================================
-- VIEW 5: Concentração por Setor
-- Quanto foi investido em cada setor
-- ====================================================================

CREATE OR REPLACE VIEW v_concentracao_setor_acoes AS
SELECT
    ano,
    mes,
    mes_nome,
    setor,

    -- Volume Investido
    SUM(valor_mercado_posicao) AS valor_total_posicoes,
    AVG(valor_mercado_posicao) AS media_posicao,

    -- Movimentações
    SUM(valor_compra) AS total_compras_mes,
    SUM(valor_venda) AS total_vendas_mes,
    SUM(saldo_liquido) AS fluxo_liquido_mes,

    -- Quantidade de Ações e Fundos
    COUNT(DISTINCT ticker) AS qtd_acoes_diferentes,
    COUNT(DISTINCT cnpj_fundo_classe) AS qtd_fundos_investidores,

    -- Performance
    AVG(rentabilidade_posicao) AS rentabilidade_media_setor,
    SUM(valor_lucro_prejuizo) AS lucro_prejuizo_total,

    -- Percentual do Total
    ROUND(
        100.0 * SUM(valor_mercado_posicao) /
        SUM(SUM(valor_mercado_posicao)) OVER (PARTITION BY ano, mes),
        2
    ) AS percentual_total_acoes

FROM v_movimentacoes_acoes
GROUP BY ano, mes, mes_nome, setor
ORDER BY ano DESC, mes DESC, valor_total_posicoes DESC;

COMMENT ON VIEW v_concentracao_setor_acoes IS 'Análise de concentração de investimentos por setor';


-- ====================================================================
-- VIEW 6: Top Posições por Grupo Econômico
-- Maiores posições em ações de cada grupo
-- ====================================================================

CREATE OR REPLACE VIEW v_top_posicoes_grupos AS
SELECT
    ano,
    mes,
    nome_grupo,
    tipo_grupo,
    ticker,
    empresa_nome,
    setor,

    -- Valor Total Investido
    SUM(valor_mercado_posicao) AS valor_total_investido,
    COUNT(DISTINCT cnpj_fundo_classe) AS qtd_fundos_com_posicao,

    -- Performance
    SUM(valor_lucro_prejuizo) AS lucro_prejuizo_total,
    AVG(rentabilidade_posicao) AS rentabilidade_media,

    -- Ranking dentro do grupo
    RANK() OVER (
        PARTITION BY ano, mes, nome_grupo
        ORDER BY SUM(valor_mercado_posicao) DESC
    ) AS ranking_grupo

FROM v_movimentacoes_acoes
WHERE nome_grupo IS NOT NULL
GROUP BY ano, mes, nome_grupo, tipo_grupo, ticker, empresa_nome, setor;

COMMENT ON VIEW v_top_posicoes_grupos IS 'Top posições em ações de cada grupo econômico';


-- ====================================================================
-- VIEW 7: Análise de Dividend Yield
-- Ações pagadoras de dividendos com DY
-- ====================================================================

CREATE OR REPLACE VIEW v_analise_dividendos AS
SELECT
    ano,
    mes,
    ticker,
    empresa_nome,
    setor,
    acoes.dividend_yield_medio,
    acoes.pagadora_dividendos,

    -- Posições
    SUM(valor_mercado_posicao) AS valor_total_investido,
    COUNT(DISTINCT cnpj_fundo_classe) AS qtd_fundos,

    -- Estimativa de Dividendos (apenas ilustrativo)
    ROUND(
        SUM(valor_mercado_posicao) * (acoes.dividend_yield_medio / 100),
        2
    ) AS dividendos_estimados_ano,

    -- Movimentações
    SUM(saldo_liquido) AS fluxo_liquido_mes

FROM v_movimentacoes_acoes
WHERE pagadora_dividendos = TRUE
  AND dividend_yield_medio > 0
GROUP BY ano, mes, ticker, empresa_nome, setor,
         acoes.dividend_yield_medio, acoes.pagadora_dividendos
ORDER BY dividendos_estimados_ano DESC;

COMMENT ON VIEW v_analise_dividendos IS 'Análise de investimentos em ações pagadoras de dividendos';
