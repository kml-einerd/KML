# 🚀 GUIA DE EXECUÇÃO - Implementar Dashboard Completo

## ⚡ Execução Rápida (3 passos simples)

### 📍 PASSO 1: Abrir Supabase SQL Editor

1. Acesse: **https://supabase.com/dashboard**
2. Selecione seu projeto
3. No menu lateral, clique em: **SQL Editor**
4. Clique em **New Query** (botão verde)

---

### 📍 PASSO 2: Executar Schema + Funções

**Copie TODO o conteúdo abaixo e cole no SQL Editor:**

```sql
-- =====================================================================
-- IMPLEMENTAÇÃO COMPLETA DO DASHBOARD
-- Este script cria TUDO que é necessário
-- =====================================================================

BEGIN;

-- ============================================================
-- PARTE 1: AJUSTAR TABELAS EXISTENTES
-- ============================================================

-- Adicionar colunas faltantes em top_movers
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'top_movers' AND column_name = 'data_competencia'
    ) THEN
        ALTER TABLE public.top_movers ADD COLUMN data_competencia DATE;
        UPDATE public.top_movers SET data_competencia = data_snapshot WHERE data_competencia IS NULL;
    END IF;
END $$;

-- Adicionar colunas em fresh_bets
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'fresh_bets' AND column_name = 'data_competencia'
    ) THEN
        ALTER TABLE public.fresh_bets ADD COLUMN data_competencia DATE;
        UPDATE public.fresh_bets SET data_competencia = first_seen WHERE data_competencia IS NULL;
    END IF;
END $$;

-- ============================================================
-- PARTE 2: CRIAR ÍNDICES OTIMIZADOS
-- ============================================================

CREATE INDEX IF NOT EXISTS idx_posicoes_fundo_data_ativo
    ON public.posicoes(fundo_id, data_competencia DESC, ativo_id)
    WHERE ativo_id IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_posicoes_data_ativo
    ON public.posicoes(data_competencia DESC, ativo_id)
    WHERE ativo_id IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_top_movers_data_tipo
    ON public.top_movers(data_competencia DESC, tipo_movimento);

CREATE INDEX IF NOT EXISTS idx_fresh_bets_data
    ON public.fresh_bets(data_competencia DESC, qtd_fundos DESC);

-- ============================================================
-- PARTE 3: CRIAR VIEWS PARA O DASHBOARD
-- ============================================================

-- View: Meses Disponíveis
CREATE OR REPLACE VIEW v_meses_disponiveis AS
SELECT DISTINCT
    DATE_TRUNC('month', data_competencia)::DATE AS mes,
    TO_CHAR(data_competencia, 'Mon/YYYY') AS mes_label
FROM (
    SELECT data_competencia FROM public.patrimonio_liquido
    UNION
    SELECT data_competencia FROM public.posicoes
) t
WHERE data_competencia IS NOT NULL
ORDER BY mes DESC;

-- View: Top Compradores
CREATE OR REPLACE VIEW v_top_compradores AS
SELECT
    f.id AS fundo_id,
    f.nome_fundo,
    f.gestor,
    tm.data_competencia,
    SUM(tm.change_absolute) AS total_compras,
    COUNT(*) AS num_operacoes,
    pl.valor_pl
FROM public.top_movers tm
JOIN public.fundos f ON f.id = tm.fundo_id
LEFT JOIN public.patrimonio_liquido pl
    ON pl.fundo_id = f.id
    AND pl.data_competencia = tm.data_competencia
WHERE tm.tipo_movimento = 'compra'
GROUP BY f.id, f.nome_fundo, f.gestor, tm.data_competencia, pl.valor_pl;

-- View: Top Vendedores
CREATE OR REPLACE VIEW v_top_vendedores AS
SELECT
    f.id AS fundo_id,
    f.nome_fundo,
    f.gestor,
    tm.data_competencia,
    SUM(ABS(tm.change_absolute)) AS total_vendas,
    COUNT(*) AS num_operacoes,
    pl.valor_pl
FROM public.top_movers tm
JOIN public.fundos f ON f.id = tm.fundo_id
LEFT JOIN public.patrimonio_liquido pl
    ON pl.fundo_id = f.id
    AND pl.data_competencia = tm.data_competencia
WHERE tm.tipo_movimento = 'venda'
GROUP BY f.id, f.nome_fundo, f.gestor, tm.data_competencia, pl.valor_pl;

-- View: Fresh Bets Detalhado
CREATE OR REPLACE VIEW v_fresh_bets_detalhado AS
SELECT
    fb.id,
    fb.ativo_id,
    COALESCE(a.codigo, a.descricao) AS ticker,
    a.tipo_ativo,
    e.nome_emissor,
    fb.data_competencia,
    fb.qtd_fundos,
    fb.valor_total_investido
FROM public.fresh_bets fb
LEFT JOIN public.ativos a ON a.id = fb.ativo_id
LEFT JOIN public.emissores e ON e.id = a.emissor_id;

-- View: Ativos Populares
CREATE OR REPLACE VIEW v_ativos_populares AS
SELECT
    a.id AS ativo_id,
    COALESCE(a.codigo, a.descricao) AS ticker,
    a.tipo_ativo,
    p.data_competencia,
    COUNT(DISTINCT p.fundo_id) AS num_fundos,
    SUM(p.valor_mercado_final) AS total_valor_mercado
FROM public.posicoes p
JOIN public.ativos a ON a.id = p.ativo_id
WHERE p.ativo_id IS NOT NULL AND p.valor_mercado_final > 0
GROUP BY a.id, ticker, a.tipo_ativo, p.data_competencia;

-- ============================================================
-- PARTE 4: CRIAR FUNÇÃO ETL
-- ============================================================

CREATE OR REPLACE FUNCTION populate_dashboard_data(p_target_date DATE DEFAULT CURRENT_DATE)
RETURNS TABLE (
    status TEXT,
    top_movers_inserted INTEGER,
    fresh_bets_inserted INTEGER
) AS $$
DECLARE
    v_top_movers_count INTEGER := 0;
    v_fresh_bets_count INTEGER := 0;
    v_target_month_start DATE;
    v_target_month_end DATE;
    v_prev_month_start DATE;
    v_prev_month_end DATE;
BEGIN
    v_target_month_start := DATE_TRUNC('month', p_target_date)::DATE;
    v_target_month_end := (v_target_month_start + INTERVAL '1 month')::DATE;
    v_prev_month_start := (v_target_month_start - INTERVAL '1 month')::DATE;
    v_prev_month_end := v_target_month_start;

    -- Limpar dados existentes
    DELETE FROM public.top_movers
    WHERE data_competencia >= v_target_month_start
      AND data_competencia < v_target_month_end;

    DELETE FROM public.fresh_bets
    WHERE data_competencia >= v_target_month_start
      AND data_competencia < v_target_month_end;

    -- Popular top_movers
    WITH posicoes_atual AS (
        SELECT fundo_id, ativo_id, data_competencia,
               SUM(qtd_posicao_final) AS qtd, SUM(valor_mercado_final) AS valor
        FROM public.posicoes
        WHERE data_competencia >= v_target_month_start
          AND data_competencia < v_target_month_end
          AND ativo_id IS NOT NULL AND valor_mercado_final > 0
        GROUP BY fundo_id, ativo_id, data_competencia
    ),
    posicoes_anterior AS (
        SELECT fundo_id, ativo_id,
               SUM(qtd_posicao_final) AS qtd, SUM(valor_mercado_final) AS valor
        FROM public.posicoes
        WHERE data_competencia >= v_prev_month_start
          AND data_competencia < v_prev_month_end
          AND ativo_id IS NOT NULL
        GROUP BY fundo_id, ativo_id
    )
    INSERT INTO public.top_movers (
        fundo_id, ativo_id, data_snapshot, data_competencia,
        prev_quantity, curr_quantity, prev_value, curr_value,
        change_absolute, tipo_movimento
    )
    SELECT
        COALESCE(curr.fundo_id, prev.fundo_id),
        COALESCE(curr.ativo_id, prev.ativo_id),
        COALESCE(curr.data_competencia, v_target_month_start),
        COALESCE(curr.data_competencia, v_target_month_start),
        COALESCE(prev.qtd, 0),
        COALESCE(curr.qtd, 0),
        COALESCE(prev.valor, 0),
        COALESCE(curr.valor, 0),
        (COALESCE(curr.valor, 0) - COALESCE(prev.valor, 0)),
        CASE
            WHEN (COALESCE(curr.valor, 0) - COALESCE(prev.valor, 0)) > 1000 THEN 'compra'
            WHEN (COALESCE(curr.valor, 0) - COALESCE(prev.valor, 0)) < -1000 THEN 'venda'
        END
    FROM posicoes_atual curr
    FULL OUTER JOIN posicoes_anterior prev
        ON prev.fundo_id = curr.fundo_id AND prev.ativo_id = curr.ativo_id
    WHERE ABS(COALESCE(curr.valor, 0) - COALESCE(prev.valor, 0)) > 1000;

    GET DIAGNOSTICS v_top_movers_count = ROW_COUNT;

    -- Popular fresh_bets
    WITH fundos_atual AS (
        SELECT ativo_id,
               COUNT(DISTINCT fundo_id) AS num_fundos,
               SUM(valor_mercado_final) AS valor_total
        FROM public.posicoes
        WHERE data_competencia >= v_target_month_start
          AND data_competencia < v_target_month_end
          AND ativo_id IS NOT NULL AND valor_mercado_final > 0
        GROUP BY ativo_id
    ),
    fundos_anterior AS (
        SELECT ativo_id, COUNT(DISTINCT fundo_id) AS num_fundos
        FROM public.posicoes
        WHERE data_competencia >= v_prev_month_start
          AND data_competencia < v_prev_month_end
          AND ativo_id IS NOT NULL AND valor_mercado_final > 0
        GROUP BY ativo_id
    )
    INSERT INTO public.fresh_bets (
        fundo_id, ativo_id, data_competencia, first_seen, last_seen,
        qtd_fundos, valor_total_investido, quantity, value
    )
    SELECT
        (SELECT id FROM public.fundos LIMIT 1),
        curr.ativo_id,
        v_target_month_start,
        v_target_month_start,
        v_target_month_end - INTERVAL '1 day',
        curr.num_fundos,
        curr.valor_total,
        curr.num_fundos,
        curr.valor_total
    FROM fundos_atual curr
    LEFT JOIN fundos_anterior prev ON prev.ativo_id = curr.ativo_id
    WHERE (curr.num_fundos - COALESCE(prev.num_fundos, 0)) >= 3
       OR (curr.num_fundos > 0 AND COALESCE(prev.num_fundos, 0) = 0 AND curr.num_fundos >= 2);

    GET DIAGNOSTICS v_fresh_bets_count = ROW_COUNT;

    RETURN QUERY SELECT 'success'::TEXT, v_top_movers_count, v_fresh_bets_count;
END;
$$ LANGUAGE plpgsql;

COMMIT;

-- ============================================================
-- SUCESSO!
-- ============================================================

SELECT '✅ Schema e funções criados com sucesso!' AS status;
```

**Depois de colar, clique em RUN (ou Ctrl+Enter)**

Aguarde terminar (pode demorar ~30 segundos)

---

### 📍 PASSO 3: Popular os Dados (ETL)

**Cole e execute esta query:**

```sql
-- Popular dados de TODOS os meses disponíveis
DO $$
DECLARE
    v_month RECORD;
    v_result RECORD;
BEGIN
    RAISE NOTICE 'Iniciando ETL...';

    FOR v_month IN
        SELECT DISTINCT DATE_TRUNC('month', data_competencia)::DATE AS mes
        FROM public.posicoes
        WHERE data_competencia IS NOT NULL AND ativo_id IS NOT NULL
        ORDER BY mes DESC
        LIMIT 12
    LOOP
        RAISE NOTICE 'Processando: %', v_month.mes;

        SELECT * INTO v_result
        FROM populate_dashboard_data(v_month.mes + INTERVAL '15 days');

        RAISE NOTICE '  Top Movers: %, Fresh Bets: %',
            v_result.top_movers_inserted,
            v_result.fresh_bets_inserted;
    END LOOP;

    RAISE NOTICE '✅ ETL Concluído!';
END $$;

-- Verificar resultados
SELECT
    'top_movers' AS tabela,
    data_competencia,
    COUNT(*) AS registros,
    SUM(CASE WHEN tipo_movimento = 'compra' THEN 1 ELSE 0 END) AS compras,
    SUM(CASE WHEN tipo_movimento = 'venda' THEN 1 ELSE 0 END) AS vendas
FROM public.top_movers
GROUP BY data_competencia
ORDER BY data_competencia DESC;
```

**Aguarde o processamento (pode demorar 1-3 minutos)**

---

## ✅ Verificação Final

Execute para confirmar que tudo funcionou:

```sql
-- 1. Ver meses disponíveis
SELECT * FROM v_meses_disponiveis LIMIT 5;

-- 2. Ver top compradores
SELECT
    nome_fundo,
    gestor,
    total_compras,
    data_competencia
FROM v_top_compradores
ORDER BY data_competencia DESC, total_compras DESC
LIMIT 10;

-- 3. Ver fresh bets
SELECT
    ticker,
    qtd_fundos,
    valor_total_investido,
    data_competencia
FROM v_fresh_bets_detalhado
ORDER BY data_competencia DESC, qtd_fundos DESC
LIMIT 10;

-- 4. Ver ativos populares
SELECT
    ticker,
    num_fundos,
    total_valor_mercado,
    data_competencia
FROM v_ativos_populares
ORDER BY data_competencia DESC, num_fundos DESC
LIMIT 10;
```

Se todas as queries retornarem dados, **está tudo funcionando!** ✅

---

## 📚 Próximos Passos

1. **API**: Ver `database/API_QUERIES.md` para criar endpoints
2. **Frontend**: Implementar dashboard usando as views criadas
3. **Manutenção**: Executar ETL mensalmente quando novos dados chegarem

---

## 🆘 Problemas?

### Erro: "relation does not exist"
**Solução**: Execute o Passo 2 novamente (schema e funções)

### Erro: "column does not exist"
**Solução**: Verifique se as colunas foram adicionadas no Passo 2

### ETL retorna 0 registros
**Solução**: Verifique se há dados:
```sql
SELECT
    DATE_TRUNC('month', data_competencia) AS mes,
    COUNT(*) AS total
FROM posicoes
WHERE ativo_id IS NOT NULL
GROUP BY mes
ORDER BY mes DESC;
```

---

**✨ Boa sorte com seu dashboard!**
