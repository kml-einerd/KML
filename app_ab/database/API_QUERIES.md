# 📊 API Queries - Dashboard Radar Institucional

Queries prontas para implementar os endpoints da API do dashboard.

---

## 🎯 Endpoints do Dashboard

### 1. GET /api/meses

**Descrição:** Retorna lista de meses disponíveis para o seletor

```sql
SELECT * FROM v_meses_disponiveis
ORDER BY mes DESC
LIMIT 12;
```

**Resposta:**
```json
[
  {
    "mes": "2025-08-01",
    "mes_label": "Aug/2025",
    "mes_value": "2025-08"
  }
]
```

---

### 2. GET /api/resumo/:mes

**Descrição:** Métricas do header para um mês específico

```sql
SELECT * FROM v_resumo_mensal
WHERE mes = :mes;
```

**Parâmetros:**
- `:mes` - Data no formato YYYY-MM-DD (ex: 2025-08-01)

**Resposta:**
```json
{
  "mes": "2025-08-01",
  "num_fundos": 150,
  "total_pl": 1500000000.50,
  "media_pl": 10000000.00,
  "num_ativos_distintos": 450
}
```

---

### 3. GET /api/top-compradores/:mes

**Descrição:** Top 10 fundos compradores do mês

```sql
SELECT
    fundo_id,
    nome_fundo,
    gestor,
    total_compras,
    total_qtd,
    num_operacoes,
    valor_pl
FROM v_top_compradores
WHERE data_competencia >= :mes_start
  AND data_competencia < :mes_end
LIMIT 10;
```

**Parâmetros:**
- `:mes_start` - Primeiro dia do mês (ex: 2025-08-01)
- `:mes_end` - Primeiro dia do mês seguinte (ex: 2025-09-01)

**Resposta:**
```json
[
  {
    "fundo_id": "uuid",
    "nome_fundo": "Alaska Black FIA",
    "gestor": "Alaska Asset Management",
    "total_compras": 420000000.00,
    "total_qtd": 1500000.0,
    "num_operacoes": 25,
    "valor_pl": 2000000000.00
  }
]
```

---

### 4. GET /api/top-vendedores/:mes

**Descrição:** Top 10 fundos vendedores do mês

```sql
SELECT
    fundo_id,
    nome_fundo,
    gestor,
    total_vendas,
    total_qtd,
    num_operacoes,
    valor_pl
FROM v_top_vendedores
WHERE data_competencia >= :mes_start
  AND data_competencia < :mes_end
LIMIT 10;
```

**Resposta:** Similar ao top-compradores

---

### 5. GET /api/fresh-bets/:mes

**Descrição:** Fresh Bets (novas apostas) do mês

```sql
SELECT
    id,
    ativo_id,
    ticker,
    tipo_ativo,
    nome_emissor,
    qtd_fundos,
    valor_total_investido,
    pct_medio_alocacao,
    first_seen,
    last_seen
FROM v_fresh_bets_detalhado
WHERE data_competencia >= :mes_start
  AND data_competencia < :mes_end
ORDER BY qtd_fundos DESC, valor_total_investido DESC
LIMIT 20;
```

**Resposta:**
```json
[
  {
    "id": 123,
    "ativo_id": "uuid",
    "ticker": "INTB3",
    "tipo_ativo": "Ação",
    "nome_emissor": "Intelbras S.A.",
    "qtd_fundos": 5,
    "valor_total_investido": 45000000.00,
    "pct_medio_alocacao": 2.5,
    "first_seen": "2025-08-01",
    "last_seen": "2025-08-31"
  }
]
```

---

### 6. GET /api/fresh-bet/:ativo_id/participantes

**Descrição:** Fundos que entraram em um Fresh Bet específico

```sql
SELECT * FROM get_fresh_bet_participantes(
    :ativo_id,
    :data_competencia
)
ORDER BY valor_investido DESC
LIMIT 10;
```

**Parâmetros:**
- `:ativo_id` - UUID do ativo
- `:data_competencia` - Data do snapshot (ex: 2025-08-31)

**Resposta:**
```json
[
  {
    "fundo_id": "uuid",
    "nome_fundo": "Opportunity FIA",
    "valor_investido": 15000000.00,
    "pct_pl": 3.0,
    "percentual_carteira": 2.5
  }
]
```

---

### 7. GET /api/ativos-populares/:mes

**Descrição:** Ativos mais populares (mais fundos investidos)

```sql
SELECT
    ativo_id,
    ticker,
    tipo_ativo,
    nome_emissor,
    num_fundos,
    total_valor_mercado,
    pct_medio_carteira
FROM v_ativos_populares
WHERE data_competencia >= :mes_start
  AND data_competencia < :mes_end
ORDER BY num_fundos DESC
LIMIT 20;
```

**Resposta:**
```json
[
  {
    "ativo_id": "uuid",
    "ticker": "VALE3",
    "tipo_ativo": "Ação",
    "nome_emissor": "Vale S.A.",
    "num_fundos": 87,
    "total_valor_mercado": 5000000000.00,
    "pct_medio_carteira": 5.2
  }
]
```

---

### 8. GET /api/fundo/:fundo_id

**Descrição:** Detalhes completos de um fundo

```sql
SELECT * FROM v_fundo_detalhes
WHERE fundo_id = :fundo_id
ORDER BY data_competencia DESC
LIMIT 1;
```

**Resposta:**
```json
{
  "fundo_id": "uuid",
  "nome_fundo": "Alaska Black FIA",
  "cnpj": "12.345.678/0001-99",
  "gestor": "Alaska Asset Management",
  "administrador": "BTG Pactual",
  "tipo_fundo": "FIA",
  "classe": "Ações",
  "situacao": "ATIVO",
  "data_competencia": "2025-08-31",
  "valor_pl": 2000000000.00,
  "num_cotistas": 1500,
  "valor_cota": 1.5678,
  "rentabilidade_mes": 2.5,
  "top_ativos": [
    {"ticker": "VALE3", "valor": 270000000, "pct": 60},
    {"ticker": "PETR4", "valor": 112000000, "pct": 25}
  ]
}
```

---

### 9. GET /api/fundo/:fundo_id/top-ativos

**Descrição:** Top ativos de um fundo (para card expandido)

```sql
SELECT
    a.id AS ativo_id,
    COALESCE(a.codigo, a.descricao) AS ticker,
    SUM(p.valor_mercado_final) AS total_valor,
    AVG(p.percentual_carteira) AS pct_medio
FROM public.posicoes p
JOIN public.ativos a ON a.id = p.ativo_id
WHERE p.fundo_id = :fundo_id
  AND p.data_competencia >= :mes_start
  AND p.data_competencia < :mes_end
  AND p.ativo_id IS NOT NULL
GROUP BY a.id, ticker
ORDER BY total_valor DESC
LIMIT 10;
```

---

### 10. POST /api/check-data

**Descrição:** Verificar disponibilidade de dados para um período

```sql
SELECT * FROM check_data_availability(
    :month_start,
    :month_end
);
```

**Request Body:**
```json
{
  "month_start": "2025-08-01",
  "month_end": "2025-09-01"
}
```

**Resposta:**
```json
{
  "has_positions": true,
  "has_patrimonio": true,
  "num_fundos": 150,
  "num_posicoes": 2286
}
```

---

## 🔄 Endpoint de ETL (Admin)

### POST /api/admin/populate-data

**Descrição:** Executar ETL para popular dados derivados

```sql
SELECT * FROM populate_dashboard_data(:target_date);
```

**Request Body:**
```json
{
  "target_date": "2025-08-15"
}
```

**Resposta:**
```json
{
  "status": "success",
  "top_movers_inserted": 1500,
  "fresh_bets_inserted": 25,
  "execution_time_ms": 5420
}
```

---

### POST /api/admin/populate-all-months

**Descrição:** Popular todos os meses disponíveis

```sql
SELECT * FROM populate_all_months();
```

**Resposta:**
```json
[
  {
    "mes": "2025-08-01",
    "status": "success",
    "top_movers": 1500,
    "fresh_bets": 25
  },
  {
    "mes": "2025-07-01",
    "status": "success",
    "top_movers": 1450,
    "fresh_bets": 22
  }
]
```

---

## 🛠️ Implementação Sugerida

### Python (FastAPI)

```python
from fastapi import FastAPI, HTTPException
from supabase import create_client
import os

app = FastAPI()
supabase = create_client(
    os.getenv("SUPABASE_URL"),
    os.getenv("SUPABASE_SERVICE_KEY")
)

@app.get("/api/meses")
async def get_meses():
    response = supabase.rpc("v_meses_disponiveis").execute()
    return response.data

@app.get("/api/top-compradores/{mes}")
async def get_top_compradores(mes: str, limit: int = 10):
    response = supabase.from_("v_top_compradores")\\
        .select("*")\\
        .gte("data_competencia", f"{mes}-01")\\
        .lt("data_competencia", f"{mes}-32")\\
        .limit(limit)\\
        .execute()
    return response.data
```

### Node.js (Express)

```javascript
const express = require('express');
const { createClient } = require('@supabase/supabase-js');

const app = express();
const supabase = createClient(
  process.env.SUPABASE_URL,
  process.env.SUPABASE_SERVICE_KEY
);

app.get('/api/meses', async (req, res) => {
  const { data, error } = await supabase
    .from('v_meses_disponiveis')
    .select('*')
    .order('mes', { ascending: false })
    .limit(12);

  if (error) return res.status(500).json({ error });
  res.json(data);
});
```

---

## 📝 Notas de Performance

1. **Índices**: Todos os índices necessários já foram criados no schema
2. **Cache**: Considere cachear respostas de meses antigos (não mudam)
3. **Paginação**: Implemente para listas grandes (top compradores, etc)
4. **Rate Limiting**: Proteja endpoints de ETL (apenas admin)

---

**Fim da Documentação de API**
