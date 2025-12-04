# 🗄️ Database - Radar Institucional

Estrutura completa do banco de dados para o Dashboard de análise de fundos.

---

## 📋 Visão Geral

Este banco de dados foi projetado para fornecer insights valiosos sobre movimentações de fundos institucionais, permitindo que investidores comuns identifiquem:

- 💰 **Top Movers**: Fundos com maiores compras e vendas
- 🚀 **Fresh Bets**: Novas apostas (ativos com aumento de interesse)
- 📊 **Ativos Populares**: Ativos mais investidos por fundos
- 🔍 **Análise Detalhada**: Drill-down em fundos específicos

---

## 🏗️ Estrutura do Banco

### Tabelas Principais (Dados Brutos)
- `fundos` - Cadastro de fundos (25.782 fundos)
- `emissores` - Emissores de ativos (2.112 emissores)
- `ativos` - Ativos negociáveis (19.306 ativos)
- `patrimonio_liquido` - PL mensal dos fundos
- `posicoes` - Posições dos fundos por ativo
- `posicoes_detalhes` - Detalhamento de transações

### Tabelas Derivadas (Calculadas)
- `top_movers` - Maiores variações (compras/vendas)
- `fresh_bets` - Ativos com entradas recentes

### Views Otimizadas
- `v_meses_disponiveis` - Meses com dados (para seletor)
- `v_resumo_mensal` - Métricas agregadas por mês
- `v_top_compradores` - Top fundos compradores
- `v_top_vendedores` - Top fundos vendedores
- `v_fresh_bets_detalhado` - Fresh Bets com detalhes
- `v_ativos_populares` - Ativos mais populares
- `v_fundo_detalhes` - Detalhes completos do fundo

### Funções
- `populate_dashboard_data(date)` - ETL para um mês específico
- `populate_all_months()` - ETL para todos os meses
- `get_fresh_bet_participantes()` - Lista participantes de fresh bet
- `check_data_availability()` - Verifica dados disponíveis

---

## 🚀 Como Executar

### Método 1: Executar Tudo de Uma Vez (Recomendado)

1. **Abra o Supabase SQL Editor**
   - Acesse: https://supabase.com/dashboard
   - Vá em: **SQL Editor**

2. **Execute os scripts na ordem:**

#### Passo 1: Schema do Dashboard
```sql
-- Copie e cole o conteúdo de:
-- database/schema/03_dashboard_complete.sql
```

#### Passo 2: Funções ETL
```sql
-- Copie e cole o conteúdo de:
-- database/schema/04_etl_function.sql
```

#### Passo 3: Popular Dados
```sql
-- Execute o ETL para popular as tabelas derivadas
SELECT * FROM populate_all_months();
```

### Método 2: Executar via Python

```bash
cd database/scripts
python3 execute_all.py
```

---

## ✅ Verificação

Após executar os scripts, verifique se tudo foi criado corretamente:

```sql
-- 1. Verificar views
SELECT viewname FROM pg_views
WHERE schemaname = 'public'
  AND viewname LIKE 'v_%'
ORDER BY viewname;

-- 2. Verificar dados em top_movers
SELECT
    data_competencia,
    COUNT(*) as registros,
    SUM(CASE WHEN tipo_movimento = 'compra' THEN 1 ELSE 0 END) as compras,
    SUM(CASE WHEN tipo_movimento = 'venda' THEN 1 ELSE 0 END) as vendas
FROM top_movers
GROUP BY data_competencia
ORDER BY data_competencia DESC;

-- 3. Verificar fresh_bets
SELECT
    data_competencia,
    COUNT(*) as num_fresh_bets,
    SUM(qtd_fundos) as total_fundos_entrantes
FROM fresh_bets
GROUP BY data_competencia
ORDER BY data_competencia DESC;

-- 4. Testar uma view
SELECT * FROM v_top_compradores
LIMIT 5;
```

---

## 📊 Exemplos de Queries

### Top 10 Compradores do Mês
```sql
SELECT
    nome_fundo,
    gestor,
    total_compras,
    valor_pl
FROM v_top_compradores
WHERE data_competencia >= '2025-08-01'
  AND data_competencia < '2025-09-01'
ORDER BY total_compras DESC
LIMIT 10;
```

### Fresh Bets com Mais de 5 Fundos
```sql
SELECT
    ticker,
    nome_emissor,
    qtd_fundos,
    valor_total_investido
FROM v_fresh_bets_detalhado
WHERE data_competencia >= '2025-08-01'
  AND qtd_fundos >= 5
ORDER BY qtd_fundos DESC;
```

### Ativos Mais Populares
```sql
SELECT
    ticker,
    tipo_ativo,
    num_fundos,
    total_valor_mercado
FROM v_ativos_populares
WHERE data_competencia = '2025-08-31'
ORDER BY num_fundos DESC
LIMIT 20;
```

### Participantes de um Fresh Bet
```sql
SELECT *
FROM get_fresh_bet_participantes(
    'uuid-do-ativo',
    '2025-08-31'
)
LIMIT 10;
```

---

## 🔄 Manutenção

### Atualizar Dados (ETL)

Execute mensalmente ou quando novos dados forem inseridos:

```sql
-- Para um mês específico
SELECT * FROM populate_dashboard_data('2025-09-15');

-- Para todos os meses
SELECT * FROM populate_all_months();
```

### Recriar Índices

Se o banco ficar lento:

```sql
-- Recriar índices
REINDEX TABLE top_movers;
REINDEX TABLE fresh_bets;
REINDEX TABLE posicoes;
```

### Limpar Dados Antigos

```sql
-- Remover top_movers de meses antigos (> 24 meses)
DELETE FROM top_movers
WHERE data_competencia < (CURRENT_DATE - INTERVAL '24 months');

-- Remover fresh_bets antigos
DELETE FROM fresh_bets
WHERE data_competencia < (CURRENT_DATE - INTERVAL '24 months');
```

---

## 📈 Performance

### Índices Criados
- `idx_posicoes_fundo_data_ativo` - Posições por fundo/data/ativo
- `idx_top_movers_data_tipo` - Top movers por data/tipo
- `idx_fresh_bets_data` - Fresh bets por data
- E mais...

### Estatísticas de Performance

```sql
-- Ver tamanho das tabelas
SELECT
    tablename,
    pg_size_pretty(pg_total_relation_size('public.' || tablename)) AS size
FROM pg_tables
WHERE schemaname = 'public'
ORDER BY pg_total_relation_size('public.' || tablename) DESC;

-- Ver índices mais usados
SELECT
    schemaname,
    tablename,
    indexname,
    idx_scan,
    idx_tup_read
FROM pg_stat_user_indexes
WHERE schemaname = 'public'
ORDER BY idx_scan DESC;
```

---

## 🐛 Troubleshooting

### Problema: ETL retorna 0 registros
**Solução:** Verifique se há dados no período:
```sql
SELECT
    DATE_TRUNC('month', data_competencia) AS mes,
    COUNT(*) AS total
FROM posicoes
WHERE ativo_id IS NOT NULL
GROUP BY mes
ORDER BY mes DESC;
```

### Problema: Views retornam vazio
**Solução:** Execute o ETL primeiro:
```sql
SELECT * FROM populate_all_months();
```

### Problema: Queries lentas
**Solução:** Verifique índices:
```sql
SELECT * FROM pg_indexes
WHERE schemaname = 'public'
  AND tablename IN ('posicoes', 'top_movers', 'fresh_bets');
```

---

## 📚 Documentação Adicional

- **API Queries**: Ver `API_QUERIES.md` para endpoints prontos
- **Design Interface**: Ver `../Docs/DESIGN_INTERFACE.md`
- **Queries Detalhadas**: Ver `../Docs/Querys_tables.md`

---

## 🔒 Segurança

- Views expõem apenas dados necessários
- Funções ETL protegidas (apenas admin)
- Sem exposição de dados sensíveis

---

**Fim da Documentação do Banco de Dados**
