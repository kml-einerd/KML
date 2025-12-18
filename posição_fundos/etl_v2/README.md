# ETL V2 - Análise de Fundos Simplificada

## 🎯 O Que Mudou?

### Antes (V1)
- ❌ 10 tabelas complexas (modelo dimensional)
- ❌ Processava TUDO (25 mil fundos, todos os ativos)
- ❌ Stored procedures complicadas
- ❌ Várias tabelas vazias sem uso
- ❌ Difícil entender resultados

### Agora (V2)
- ✅ **3 tabelas simples** focadas em ações
- ✅ **Top 100 grupos** apenas (95% do mercado)
- ✅ **Menu interativo** - escolhe mês e tipo de dados
- ✅ **Insights diretos** - o que os grandes estão fazendo
- ✅ **Queries úteis** - views prontas para consulta

---

## 🚀 Início Rápido

### 1. Instalar Dependências

```bash
cd etl_v2
python3 -m venv venv
source venv/bin/activate  # Windows: venv\Scripts\activate

pip install -r requirements.txt
```

### 2. Configurar Supabase

Criar arquivo `.env`:
```env
SUPABASE_URL=https://seu-projeto.supabase.co
SUPABASE_KEY=sua-service-role-key
```

### 3. Criar Schema no Supabase

No SQL Editor do Supabase, execute:
```sql
-- Copie e cole todo o conteúdo de:
../sql_scripts/schema_v2_simplificado.sql
```

### 4. Executar ETL Interativo

```bash
python main_interactive.py
```

Você verá um menu assim:
```
╔═══════════════════════════════════════════════════════════════╗
║                                                               ║
║         📊  ANÁLISE DE FUNDOS CVM - V2.0                     ║
║         Para Investidores Que Querem Copiar os Grandes       ║
║                                                               ║
╚═══════════════════════════════════════════════════════════════╝

📅 Meses Disponíveis
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Mês              Arquivos   Tamanho    Status
─────────────────────────────────────────────────
Agosto 2025            12    155.2 MB   ✓ Pronto
Setembro 2025          12    161.8 MB   ✓ Pronto
Outubro 2025           12    158.4 MB   ✓ Pronto
Novembro 2025          12    134.0 MB   ✓ Pronto

📅 Selecione os meses para processar:
> [x] Agosto 2025
  [x] Setembro 2025
  [x] Outubro 2025
  [x] Novembro 2025

📊 Selecione os tipos de dados:
> [x] Ações B3 (principal) ⭐⭐⭐⭐⭐
  [ ] Títulos Públicos ⭐⭐
  [ ] Investimento Exterior ⭐⭐⭐
```

---

## 📊 Estrutura de Dados

### 3 Tabelas Simples

**1. grupos_fundos**
```
id | nome_grupo | qtd_fundos | pl_total_bilhoes
---+------------+------------+------------------
1  | Itaú       | 1852       | 1706.83
2  | Bradesco   | 1100       | 1141.25
```

**2. acoes_fundos** (principal)
```
mes_ref    | grupo_id | ticker | valor_comprado | valor_vendido | tipo_mov
-----------+----------+--------+----------------+---------------+---------
2025-11-30 | 1        | PETR4  | 450000000      | 0             | COMPRA
2025-11-30 | 2        | VALE3  | 320000000      | 0             | COMPRA
```

**3. resumo_mensal** (agregado)
```
mes_ref    | ticker | total_comprado | qtd_fundos_compradores | top_comprador
-----------+--------+----------------+------------------------+--------------
2025-11-30 | PETR4  | 2300000000     | 234                    | Itaú
```

### 4 Views Prontas

```sql
-- Top 20 ações mais compradas do mês
SELECT * FROM v_top_compras_mes LIMIT 20;

-- Top 20 ações mais vendidas
SELECT * FROM v_top_vendas_mes LIMIT 20;

-- O que um grupo está fazendo
SELECT * FROM v_movimentos_grupo WHERE nome_grupo = 'Itaú';

-- Consenso de mercado (forte compra/venda)
SELECT * FROM v_consenso_mercado;
```

---

## 💡 Casos de Uso Reais

### 1. "O que o Itaú está comprando?"

```sql
SELECT ticker, empresa, fluxo_milhoes, tipo_movimento
FROM v_movimentos_grupo
WHERE nome_grupo = 'Itaú'
  AND mes_referencia = '2025-11-30'
  AND tipo_movimento = 'COMPRA'
ORDER BY fluxo_milhoes DESC
LIMIT 10;
```

**Resultado:**
```
ticker | empresa        | fluxo_milhoes | tipo_movimento
-------+----------------+---------------+---------------
PETR4  | PETROBRAS PN   | 450.23        | COMPRA
VALE3  | VALE PNA       | 320.15        | COMPRA
ITUB4  | ITAÚ PN        | 210.80        | COMPRA
```

### 2. "Quais ações têm consenso de compra?"

```sql
SELECT ticker, empresa, sinal, qtd_fundos_compradores
FROM v_consenso_mercado
WHERE tendencia_mercado = 'COMPRA'
  AND intensidade_consenso > 70
ORDER BY fluxo_bilhoes DESC
LIMIT 10;
```

**Resultado:**
```
ticker | empresa      | sinal           | fundos_compradores
-------+--------------+-----------------+-------------------
PETR4  | PETROBRAS PN | FORTE COMPRA ⬆️⬆️ | 234
VALE3  | VALE PNA     | FORTE COMPRA ⬆️⬆️ | 189
```

### 3. "Quem está vendendo MGLU3?"

```sql
SELECT
    g.nome_grupo,
    a.valor_vendido / 1000000.0 AS vendido_milhoes
FROM acoes_fundos a
JOIN grupos_fundos g ON a.grupo_id = g.id
WHERE a.ticker = 'MGLU3'
  AND a.mes_referencia = '2025-11-30'
  AND a.tipo_movimento = 'VENDA'
ORDER BY a.valor_vendido DESC
LIMIT 10;
```

---

## 🎯 Comparação com V1

| Aspecto | V1 (Antigo) | V2 (Novo) |
|---------|-------------|-----------|
| Tabelas | 10 | 3 |
| Complexidade | Alta | Baixa |
| Tempo setup | 2-3 horas | 15 minutos |
| Foco | Todos os ativos | Apenas ações |
| Fundos | Todos (25 mil) | Top 100 |
| Interface | Linha de comando | Menu interativo |
| Views úteis | 2-3 | 4 |
| Insights | Difícil extrair | Direto |

---

## 📁 Estrutura de Arquivos

```
etl_v2/
├── main_interactive.py      # ETL com menu interativo
├── requirements.txt          # Dependências
├── README.md                 # Este arquivo
├── .env.example             # Exemplo de configuração
│
└── processors/              # Processadores (a criar)
    ├── grupos_processor.py
    ├── acoes_processor.py
    └── resumo_processor.py
```

---

## 🔄 Fluxo de Processamento

```
1. Menu Interativo
   └─> Seleciona meses (ago, set, out, nov)
   └─> Seleciona tipo (ações, títulos, exterior)

2. Processamento
   └─> Lê PL_*.csv → Identifica Top 100 grupos
   └─> Lê BLC_4_*.csv → Extrai movimentos de ações
   └─> Classifica (COMPRA, VENDA, NEUTRO)

3. Upload Supabase
   └─> grupos_fundos (upsert)
   └─> acoes_fundos (insert)
   └─> Chama função atualizar_resumo_mensal()

4. Resultado
   └─> Views prontas para consulta
   └─> Dashboard (próximo passo)
```

---

## 🚧 Roadmap

- [x] Schema simplificado (3 tabelas)
- [x] Menu interativo
- [ ] Processadores de dados
- [ ] Upload para Supabase
- [ ] Dashboard Streamlit
- [ ] Alertas de movimentos grandes

---

## 📖 Documentação Adicional

- **Visão do Produto:** `../VISAO_PRODUTO_V2.md`
- **Schema SQL:** `../sql_scripts/schema_v2_simplificado.sql`

---

**Versão:** 2.0
**Data:** 2025-12-14
**Status:** 🚧 Em desenvolvimento
