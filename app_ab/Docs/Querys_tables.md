# Querys

### Nota Inicial
> **Obs:** Algumas queries dependem de tabelas derivadas (`top_movers`, `fresh_bets`, materialized views). Indico abaixo quando é melhor gerar via ETL e quando pode ser calculado *on-the-fly*.

---

### 1. Meses com atividade — Seletor de mês
*   **Uso na UI:** Popular as tabs / seletor de mês (Header).
*   **Parâmetros:** `Nenhum`
*   **SQL:**
    ```sql
    SELECT DISTINCT date_trunc('month', data_competencia)::date AS month_start
    FROM (
        SELECT data_competencia FROM patrimonio_liquido
        UNION ALL
        SELECT data_competencia FROM posicoes
    ) t
    ORDER BY month_start DESC;
    ```
*   **Observações:** Garante cobertura mesmo se PL tiver poucas linhas.
*   **Índice sugerido:** `patrimonio_liquido(data_competencia)`, `posicoes(data_competencia)`.

### 2. Verifica existência de dados no mês — Empty State
*   **Uso na UI:** Exibir estado vazio / loading antes de renderizar cards.
*   **Parâmetros:** `:month_start`, `:month_end`
*   **SQL:**
    ```sql
    SELECT EXISTS(SELECT 1 FROM posicoes p WHERE p.data_competencia >= :month_start AND p.data_competencia < :month_end LIMIT 1) AS has_positions,
           EXISTS(SELECT 1 FROM patrimonio_liquido pl WHERE pl.data_competencia >= :month_start AND pl.data_competencia < :month_end LIMIT 1) AS has_pl;
    ```

### 3. Contadores gerais do mês (nº fundos com PL, total PL do mês)
*   **Uso na UI:** Header / métricas principais.
*   **Parâmetros:** `:month_start`, `:month_end`
*   **SQL (Otimizada):**
    ```sql
    SELECT COUNT(DISTINCT pl.fundo_id) AS num_fundos_com_pl,
           SUM(pl.valor_pl) AS total_valor_pl_mes
    FROM patrimonio_liquido pl
    WHERE pl.data_competencia >= :month_start
      AND pl.data_competencia < :month_end;
    ```
*   **Observações:** Índices: `patrimonio_liquido(data_competencia, fundo_id)`.

### 4. Top Compradores (fundos com maior soma de compras)
*   **Uso na UI:** Card lista "Top Compradores" — ordenada por fluxo positivo.
*   **Parâmetros:** `:snapshot_date`, `:limit`
*   **SQL:**
    *(Usa `top_movers` se existir. Fallback on-the-fly não recomendado para grandes volumes)*
    ```sql
    SELECT f.id AS fundo_id,
           f.nome_fundo,
           SUM(tm.variacao_valor) AS total_variacao_valor,
           SUM(tm.variacao_qtd) AS total_variacao_qtd
    FROM top_movers tm
    JOIN fundos f ON f.id = tm.fundo_id
    WHERE tm.data_competencia = :snapshot_date
      AND tm.tipo_movimento = 'compra'
    GROUP BY f.id, f.nome_fundo
    ORDER BY total_variacao_valor DESC
    LIMIT :limit;
    ```
*   **Observações:** Se `top_movers` estiver vazio, executar ETL. Índice: `top_movers(data_competencia, tipo_movimento, fundo_id)`.

### 5. Top Vendedores (fundos com maior soma de vendas)
*   **Uso na UI:** Card lista "Top Vendedores".
*   **Parâmetros:** `:snapshot_date`, `:limit`
*   **SQL:**
    ```sql
    SELECT f.id AS fundo_id,
           f.nome_fundo,
           SUM(tm.variacao_valor) AS total_variacao_valor,
           SUM(tm.variacao_qtd) AS total_variacao_qtd
    FROM top_movers tm
    JOIN fundos f ON f.id = tm.fundo_id
    WHERE tm.data_competencia = :snapshot_date
      AND tm.tipo_movimento = 'venda'
    GROUP BY f.id, f.nome_fundo
    ORDER BY total_variacao_valor DESC
    LIMIT :limit;
    ```
*   **Observações:** Confirmar valores negativos/positivos; `tipo_movimento` case-sensitive.

### 6. Card de fundo (detalhe resumido)
*   **Uso na UI:** Listagem principal com R$ PL e indicador (fluxo).
*   **Parâmetros:** `:fundo_id` (para detalhe expandido), `:snapshot_date`
*   **SQL:**
    ```sql
    SELECT f.id,
           f.nome_fundo,
           COALESCE(pl.valor_pl, 0) AS valor_pl_atual
    FROM fundos f
    LEFT JOIN LATERAL (
        SELECT valor_pl
        FROM patrimonio_liquido pl
        WHERE pl.fundo_id = f.id AND pl.data_competencia = :snapshot_date
        LIMIT 1
    ) pl ON true
    ORDER BY valor_pl_atual DESC
    LIMIT :limit OFFSET :offset;
    ```
*   **Observações:** Use `LEFT JOIN LATERAL` para performance. Índice: `patrimonio_liquido(fundo_id, data_competencia)`.

### 7. Detalhe expandido do fundo — Top ativos
*   **Uso na UI:** Expander do card do fundo (value + pct).
*   **Parâmetros:** `:fundo_id`, `:month_start`, `:month_end`, `:limit`
*   **SQL:**
    ```sql
    SELECT a.id AS ativo_id,
           COALESCE(a.codigo, a.descricao) AS ticker,
           SUM(p.valor_mercado_final) AS total_valor_mercado_final,
           AVG(p.percentual_carteira) AS avg_pct_carteira
    FROM posicoes p
    JOIN ativos a ON a.id = p.ativo_id
    WHERE p.fundo_id = :fundo_id
      AND p.data_competencia >= :month_start
      AND p.data_competencia < :month_end
      AND p.ativo_id IS NOT NULL
    GROUP BY a.id, ticker
    ORDER BY total_valor_mercado_final DESC
    LIMIT :limit;
    ```

### 8. Fresh Bets — Ativos com entradas recentes
*   **Uso na UI:** Seção "Fresh Bets" com badge, qtd_fundos e total investido.
*   **Parâmetros:** `:snapshot_date`, `:limit`
*   **SQL:**
    ```sql
    SELECT fb.id AS fresh_id,
           a.id AS ativo_id,
           COALESCE(a.codigo, a.descricao) AS ticker,
           fb.qtd_fundos,
           fb.valor_total_investido
    FROM fresh_bets fb
    JOIN ativos a ON a.id = fb.ativo_id
    WHERE fb.data_competencia = :snapshot_date
    ORDER BY fb.qtd_fundos DESC, fb.valor_total_investido DESC
    LIMIT :limit;
    ```
*   **Observações:** Se tabela estiver vazia, criar ETL que detecte ativos com aumento no número de fundos.

### 9. Quem entrou num Fresh Bet — Participantes
*   **Uso na UI:** Dentro do badge, listar fundos entrantes e % PL.
*   **Parâmetros:** `:ativo_id`, `:snapshot_date`, `:prev_snapshot_date`
*   **SQL (Identifica novos entrantes):**
    ```sql
    SELECT p.fundo_id,
           f.nome_fundo,
           p.valor_mercado_final,
           p.percentual_carteira
    FROM posicoes p
    JOIN fundos f ON f.id = p.fundo_id
    WHERE p.ativo_id = :ativo_id
      AND p.data_competencia = :snapshot_date
      AND p.valor_mercado_final > 0
      AND NOT EXISTS (
          SELECT 1 FROM posicoes p2
          WHERE p2.fundo_id = p.fundo_id
            AND p2.ativo_id = p.ativo_id
            AND p2.data_competencia = :prev_snapshot_date
            AND COALESCE(p2.qtd_posicao_final, 0) > 0
      )
    ORDER BY p.valor_mercado_final DESC;
    ```

### 10. Ativos Mais Populares — Barra de popularidade
*   **Uso na UI:** Gráfico de barra horizontal com nº de fundos.
*   **Parâmetros:** `:snapshot_date`, `:limit`
*   **SQL:**
    ```sql
    SELECT a.id AS ativo_id,
           COALESCE(a.codigo, a.descricao) AS ticker,
           COUNT(DISTINCT p.fundo_id) AS num_fundos,
           SUM(p.valor_mercado_final) AS total_market_value
    FROM posicoes p
    JOIN ativos a ON a.id = p.ativo_id
    WHERE p.data_competencia = :snapshot_date
    GROUP BY a.id, ticker
    ORDER BY num_fundos DESC, total_market_value DESC
    LIMIT :limit;
    ```

### 11. KPI do fundo (PL, Variação %, Nº Ativos)
*   **Uso na UI:** Métricas no card expandido.
*   **Parâmetros:** `:fundo_id`, `:snapshot_date`, `:start_date`
*   **SQL (CTE Otimizada):**
    ```sql
    WITH pl AS (
        SELECT MAX(CASE WHEN data_competencia = :snapshot_date THEN valor_pl END) AS valor_pl_atual,
               MAX(CASE WHEN data_competencia = :start_date THEN valor_pl END) AS valor_pl_inicio
        FROM patrimonio_liquido pl
        WHERE pl.fundo_id = :fundo_id
    )
    SELECT f.id,
           f.nome_fundo,
           COALESCE(pl.valor_pl_atual, 0) AS valor_pl_atual,
           COALESCE(pl.valor_pl_inicio, 0) AS valor_pl_inicio,
           CASE
               WHEN COALESCE(pl.valor_pl_inicio, 0) = 0 THEN NULL
               ELSE (pl.valor_pl_atual - pl.valor_pl_inicio) / pl.valor_pl_inicio * 100
           END AS pct_change_pl,
           (SELECT COUNT(*) FROM posicoes p WHERE p.fundo_id = f.id AND p.data_competencia = :snapshot_date AND COALESCE(p.qtd_posicao_final, 0) > 0) AS num_ativos
    FROM fundos f
    LEFT JOIN pl ON true
    WHERE f.id = :fundo_id;
    ```

### 12. Timeseries de PL (Mensal)
*   **Uso na UI:** Chart de evolução.
*   **Parâmetros:** `:fundo_id` (nullable), `:start_date`, `:end_date`
*   **SQL:**
    ```sql
    SELECT date_trunc('month', pl.data_competencia)::date AS period,
           SUM(pl.valor_pl) AS total_valor_pl
    FROM patrimonio_liquido pl
    WHERE pl.data_competencia >= :start_date
      AND pl.data_competencia <= :end_date
      AND (:fundo_id::uuid IS NULL OR pl.fundo_id = :fundo_id)
    GROUP BY period
    ORDER BY period;
    ```

### 13. Indicadores de consenso por ativo
*   **Uso na UI:** Detalhe do ativo (avg %, mediana).
*   **Parâmetros:** `:ativo_id`, `:snapshot_date`
*   **SQL:**
    ```sql
    SELECT AVG(p.percentual_carteira) AS avg_pct,
           PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY p.percentual_carteira) AS median_pct,
           COUNT(*) AS num_fundos
    FROM posicoes p
    WHERE p.ativo_id = :ativo_id
      AND p.data_competencia = :snapshot_date
      AND p.percentual_carteira IS NOT NULL;
    ```

### 14. Busca de fundos com paginação
*   **Uso na UI:** Barra de busca global.
*   **Parâmetros:** `:q`, `:snapshot_date`, `:limit`, `:offset`
*   **SQL:**
    ```sql
    SELECT f.id,
           f.nome_fundo,
           COALESCE(pl.valor_pl, 0) AS valor_pl
    FROM fundos f
    LEFT JOIN LATERAL (
        SELECT valor_pl
        FROM patrimonio_liquido pl
        WHERE pl.fundo_id = f.id AND pl.data_competencia = :snapshot_date
        LIMIT 1
    ) pl ON true
    WHERE f.nome_fundo ILIKE '%' || :q || '%'
    ORDER BY valor_pl DESC
    LIMIT :limit OFFSET :offset;
    ```

### 15. Materialized View Sugerida — `mv_fresh_bets_30d`
*   **Uso na UI:** Acelerar seção Fresh Bets e permitir ordenação.
*   **DDL:**
    ```sql
    CREATE MATERIALIZED VIEW mv_fresh_bets_30d AS
    SELECT a.id AS ativo_id,
           COALESCE(a.codigo, a.descricao) AS ticker,
           COUNT(DISTINCT p.fundo_id) FILTER (WHERE p.data_competencia >= now() - interval '30 days') AS qtd_fundos_30d,
           SUM(p.valor_mercado_final) FILTER (WHERE p.data_competencia >= now() - interval '30 days') AS valor_total_30d,
           MAX(p.data_competencia) AS last_date
    FROM posicoes p
    JOIN ativos a ON a.id = p.ativo_id
    WHERE p.data_competencia >= now() - interval '30 days'
    GROUP BY a.id, ticker
    ORDER BY qtd_fundos_30d DESC, valor_total_30d DESC;
    ```
*   **Obs Operacionais:**
    *   Criar índice unique: `CREATE UNIQUE INDEX CONCURRENTLY idx_mv_fresh_bets_30d_ativo ON mv_fresh_bets_30d(ativo_id);`
    *   Agendar `REFRESH MATERIALIZED VIEW CONCURRENTLY`.

---

### Recomendações de Implementação e Prioridades

#### ETL / Tarefas Derivadas (Imprescindível para UX Consistente)
*   **Snapshot Diffs (Popula `top_movers`):** Comparar posições snapshot atual vs previous. Registrar `variacao_qtd`, `variacao_valor`, `pct_variacao` e `tipo_movimento`.
*   **Fresh Bets Detection:** Detectar ativos com aumento no nº de fundos e popular tabelas `fresh_bets` e `fresh_bets_participantes`.
*   **Ferramentas:** pg_cron, Airflow, ou Edge Function agendada.

#### Índices Recomendados (Resumo Prático)
1.  `posicoes(data_competencia, ativo_id, fundo_id)`
2.  `posicoes(fundo_id, data_competencia)`
3.  `patrimonio_liquido(fundo_id, data_competencia)`
4.  `top_movers(data_competencia, tipo_movimento, fundo_id)`
5.  `fresh_bets(data_competencia, ativo_id)`
6.  `mv_fresh_bets_30d(ativo_id)` (Unique)
7.  `fundos(nome_fundo gin_trgm_ops)` (Opcional para busca rápida)

#### Matriz de Prioridades

**1. Prioridade Alta (Funcionalidade Crítica)**
*   **ETL de Snapshot/Diff:** Sem isso, tabelas derivadas ficam vazias e o dashboard falha.
    *   *Ação:* Criar job para gerar snapshots, calcular diffs e popular `top_movers` e `fresh_bets`.
*   **Índices Faltantes:** Criar os índices listados acima antes de rodar cargas.
*   **Definição de Snapshot:** Documentar qual data define o mês (ex: último dia útil) para consistência.

**2. Prioridade Média (Performance e UX)**
*   **Materialized Views:** Implementar `mv_fresh_bets_30d` e agendar refresh. Considerar `mv_fundo_summary_mes`.
*   **Paginação e Limites:** Implementar paginação no backend (cursor-based preferível) para evitar sobrecarga.
*   **Busca:** Adicionar índices trigram se busca por texto for lenta.

**3. Prioridade Baixa (Segurança e Manutenção)**
*   **Views Públicas:** Expor apenas colunas necessárias via Views com `GRANT SELECT`.
*   **RLS/Roles:** Revisar políticas de segurança.
*   **Logs/Audit:** Tabela de logs para monitorar execuções do ETL.
*   **Testes:** Validar contagens e duplicatas após ETL.

---

### Próximos Passos (Oferta de Entrega)
Posso entregar agora qualquer um dos itens abaixo:
1.  **SQL ETL Completo:** Script que calcula snapshots, diffs e popula `top_movers` + `fresh_bets` + participantes.
2.  **DDL de Infra:** Script pronto de índices, MVs e instruções de refresh.
3.  **Views de Frontend:** Views seguras e scripts de índices trigrams.
4.  **Testes e Audit:** Scripts de validação de dados e tabela de logs.

*Recomendo começar pelo ETL (item 1).*