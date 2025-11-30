# 📊 Plano de Visualização - MVP Radar Institucional

Este documento detalha as queries SQL e a lógica para combinar tabelas e gerar os dados do dashboard MVP.

---

## 🎯 Blocos do Dashboard

### Bloco 1: Top Movers (Quem está se movendo)

**Objetivo:** Mostrar os fundos que mais compraram e venderam ações no mês.

#### Query: Top 10 Compradores

```sql
SELECT
    f.nome_fundo,
    f.gestora,
    tm.total_compras,
    tm.fluxo_liquido,
    tm.ranking_compradores
FROM top_movers tm
JOIN fundos f ON tm.cnpj_fundo = f.cnpj
WHERE
    tm.data_competencia = '2025-10-31'
    AND tm.ranking_compradores <= 10
ORDER BY tm.fluxo_liquido DESC;
```

**Resultado esperado:**
| nome_fundo | gestora | total_compras | fluxo_liquido | ranking |
|------------|---------|---------------|---------------|---------|
| Alaska Black FIA | Alaska | 450.000.000 | 420.000.000 | 1 |
| Opportunity Equity | Opportunity | 380.000.000 | 350.000.000 | 2 |

#### Query: Detalhamento de um fundo (drill-down)

```sql
SELECT
    pa.ticker,
    am.nome_empresa,
    am.setor,
    pa.valor_compra,
    pa.qtd_compra,
    (pa.valor_compra / :total_compras_fundo * 100) as percentual
FROM posicoes_acoes pa
LEFT JOIN ativos_metadata am ON pa.ticker = am.ticker
WHERE
    pa.cnpj_fundo = :cnpj_selecionado
    AND pa.data_competencia = '2025-10-31'
    AND pa.valor_compra > 0
ORDER BY pa.valor_compra DESC
LIMIT 10;
```

**Uso no frontend:**
- Card expansível por fundo
- Ao clicar "Ver detalhes", executa query com o CNPJ
- Mostra top 5-10 ações compradas

---

### Bloco 2: Fresh Bets (Novas Apostas)

**Objetivo:** Ativos que entraram nas carteiras dos grandes fundos (consenso institucional).

#### Query: Ativos com maior consenso

```sql
SELECT
    fb.ticker,
    am.nome_empresa,
    am.setor,
    fb.num_fundos_entraram,
    fb.volume_total,
    fb.fundos_lista
FROM fresh_bets fb
LEFT JOIN ativos_metadata am ON fb.ticker = am.ticker
WHERE fb.data_competencia = '2025-10-31'
ORDER BY fb.num_fundos_entraram DESC
LIMIT 20;
```

**Resultado esperado:**
| ticker | nome_empresa | num_fundos | volume_total |
|--------|--------------|------------|--------------|
| INTB3 | Intelbras | 5 | 45.000.000 |
| SMTO3 | São Martinho | 3 | 28.000.000 |

#### Query: Quais fundos entraram (drill-down)

```sql
SELECT
    f.nome_fundo,
    f.gestora,
    pa.valor_mercado_final,
    pl.valor_pl,
    (pa.valor_mercado_final / pl.valor_pl * 100) as percentual_carteira
FROM posicoes_acoes pa
JOIN fundos f ON pa.cnpj_fundo = f.cnpj
JOIN patrimonio_liquido_mensal pl
    ON pa.cnpj_fundo = pl.cnpj_fundo
    AND pa.data_competencia = pl.data_competencia
WHERE
    pa.ticker = :ticker_selecionado
    AND pa.data_competencia = '2025-10-31'
    AND pa.cnpj_fundo = ANY(:array_cnpjs)  -- CNPJs do fresh_bets.fundos_lista
ORDER BY pa.valor_mercado_final DESC;
```

---

### Bloco 3: Ativos Mais Populares

**Objetivo:** Ações presentes em mais carteiras de grandes fundos.

#### Query Principal

```sql
SELECT
    pa.ticker,
    am.nome_empresa,
    am.setor,
    COUNT(DISTINCT pa.cnpj_fundo) as num_fundos,
    SUM(pa.valor_mercado_final) as volume_total,
    AVG(pa.valor_mercado_final / pl.valor_pl * 100) as media_percentual_carteira
FROM posicoes_acoes pa
LEFT JOIN ativos_metadata am ON pa.ticker = am.ticker
JOIN patrimonio_liquido_mensal pl
    ON pa.cnpj_fundo = pl.cnpj_fundo
    AND pa.data_competencia = pl.data_competencia
WHERE
    pa.data_competencia = '2025-10-31'
    AND pa.valor_mercado_final > 1000000  -- > R$ 1M
GROUP BY pa.ticker, am.nome_empresa, am.setor
HAVING COUNT(DISTINCT pa.cnpj_fundo) >= 5
ORDER BY num_fundos DESC
LIMIT 50;
```

**Resultado esperado:**
| ticker | nome_empresa | num_fundos | volume_total |
|--------|--------------|------------|--------------|
| VALE3 | Vale | 87 | 8.500.000.000 |
| PETR4 | Petrobras | 76 | 6.200.000.000 |

---

## 🔀 Lógica de Combinação de Tabelas

### Diagrama de Relacionamentos

```
fundos (dimensão)
    ↓ 1:N
patrimonio_liquido_mensal
    ↓
posicoes_acoes (fato principal)
    ↓ N:1
ativos_metadata (dimensão)

fundos → top_movers (agregação)
posicoes_acoes → fresh_bets (agregação)
```

### JOINs Comuns

**1. Posições com dados do fundo:**
```sql
FROM posicoes_acoes pa
JOIN fundos f ON pa.cnpj_fundo = f.cnpj
```

**2. Posições com PL (para calcular %):**
```sql
FROM posicoes_acoes pa
JOIN patrimonio_liquido_mensal pl
    ON pa.cnpj_fundo = pl.cnpj_fundo
    AND pa.data_competencia = pl.data_competencia
```

**3. Posições com metadata dos ativos:**
```sql
FROM posicoes_acoes pa
LEFT JOIN ativos_metadata am ON pa.ticker = am.ticker
```

---

## ⚡ Otimizações de Performance

### Índices críticos já criados

✅ `idx_posicoes_data` - Filtros por data
✅ `idx_posicoes_ticker` - Busca por ação
✅ `idx_posicoes_fundo_data` - JOIN com fundos
✅ `idx_topmovers_ranking_compradores` - Top 10 rápido
✅ `idx_fresh_bets_consenso` - Ordenação por consenso

### Dicas de Query

1. **Sempre filtrar por data primeiro**
   ```sql
   WHERE pa.data_competencia = :data_atual
   ```

2. **Usar LIMIT para evitar scans grandes**
   ```sql
   LIMIT 50  -- Retorna rapidamente
   ```

3. **Pré-calcular agregações complexas** (já feito em top_movers e fresh_bets)

4. **LEFT JOIN com ativos_metadata** (pode ter ativos sem metadata)

---

## 🎨 Formato de Dados para Frontend

### Exemplo de resposta para Top Movers

```json
{
  "data": [
    {
      "cnpj": "00017024000153",
      "nome_fundo": "Alaska Black FIA",
      "gestora": "Alaska Asset",
      "fluxo_liquido": 420000000,
      "total_compras": 450000000,
      "total_vendas": 30000000,
      "ranking": 1,
      "detalhes": [
        {
          "ticker": "VALE3",
          "nome_empresa": "Vale",
          "valor_compra": 270000000,
          "percentual": 60
        }
      ]
    }
  ],
  "meta": {
    "data_competencia": "2025-10-31",
    "total_fundos": 289
  }
}
```

---

## 🔄 Atualizações Mensais

Quando novos dados forem carregados:

1. ETL processa novos CSVs
2. Upload faz **UPSERT** (atualiza ou insere)
3. Agregações são recalculadas
4. Frontend busca pela nova `data_competencia`

**Importante:** O sistema suporta múltiplos meses simultaneamente. Filtrar sempre por `data_competencia`.

---

## 📱 Implementação Recomendada (Streamlit)

```python
import streamlit as st
from supabase import create_client

# Conectar
supabase = create_client(SUPABASE_URL, SUPABASE_KEY)

# Query
response = supabase.table('top_movers').select(
    '*',
    'fundos(nome_fundo, gestora)'
).eq('data_competencia', '2025-10-31').lte('ranking_compradores', 10).order('fluxo_liquido', desc=True).execute()

# Mostrar
for fundo in response.data:
    st.metric(fundo['fundos']['nome_fundo'], f"R$ {fundo['fluxo_liquido']:,.0f}")
```

---

**Fim do Plano de Visualização**
