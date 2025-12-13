# Início Rápido - Sistema de Análise de Fundos

Guia prático para começar a usar o sistema em 5 minutos.

---

## O Que Você Vai Fazer

1. ✅ Migrar estrutura para Supabase
2. ✅ Popular com dados (exemplo ou reais)
3. ✅ Calcular ranking Top 100
4. ✅ Fazer suas primeiras consultas

**Tempo:** 10-15 minutos

---

## Passo 1: Acessar Supabase

1. Acesse https://supabase.com
2. Faça login
3. Crie novo projeto ou acesse projeto existente
4. Vá em **SQL Editor** (ícone na lateral esquerda)

---

## Passo 2: Criar Estrutura

### Copie e Cole Este Script

Abra o arquivo `sql_scripts/17_migracao_completa_supabase.sql` e copie TODO o conteúdo.

Cole no SQL Editor do Supabase e clique em **RUN** (ou Ctrl+Enter).

**Aguarde:** 2-3 minutos

**O que foi criado:**
```
✅ 10 tabelas
✅ 20+ índices
✅ 2 views principais
```

### Verificar

Execute:
```sql
SELECT table_name FROM information_schema.tables
WHERE table_schema = 'public' AND table_type = 'BASE TABLE'
ORDER BY table_name;
```

**Deve listar:**
- dim_acoes_b3
- dim_ativos
- dim_categoria_ativo
- dim_emissores
- dim_fundos
- dim_grupos_economicos
- dim_patrimonio_liquido
- dim_tempo
- fato_posicoes
- ranking_top100_grupos

✅ **Sucesso!** Estrutura criada.

---

## Passo 3: Adicionar Rentabilidade

Copie e cole o conteúdo de `sql_scripts/16_adicionar_rentabilidade.sql`.

Execute no SQL Editor.

**Aguarde:** 30 segundos

**O que foi adicionado:**
```
✅ Campos de rentabilidade
✅ Função atualizada de ranking
✅ Views de performance
```

---

## Passo 4: Popular com Dados

### Opção A: Dados de Exemplo (Teste Rápido)

Copie e cole o conteúdo de `sql_scripts/09_dados_exemplo.sql`.

Execute no SQL Editor.

**Dados criados:**
- 4 grupos econômicos
- 4 fundos
- 4 ações
- 4 posições

### Opção B: Dados Reais (Produção)

Se você tem os CSVs da CVM na pasta `source/`:

```bash
# Importar via psql
psql "postgresql://postgres:[SENHA]@[HOST]:5432/postgres" \
  -c "\copy dim_tempo FROM 'source/tempo.csv' CSV HEADER"
# ... importar outros CSVs
```

**Ou** use ferramentas de import do Supabase (Table Editor → Import)

---

## Passo 5: Calcular Ranking

Execute esta query:

```sql
SELECT * FROM atualizar_ranking_top100_v2(2025, 10);
```

**Output esperado:**
```
grupos_atualizados | data_referencia
100                | 2025-10-31
```

✅ **Sucesso!** Ranking calculado.

---

## Passo 6: Suas Primeiras Consultas

### Ver Top 10
```sql
SELECT * FROM v_top100_atual LIMIT 10;
```

**Output:**
```
 ranking | nome_grupo        | pl_bilhoes | volume_milhoes | rentabilidade_pct
---------+-------------------+------------+----------------+------------------
 1       | BTG Pactual       | 180.5      | 1250.3         | 12.5
 2       | Itaú Unibanco     | 250.2      | 980.7          | 8.3
 3       | XP Investimentos  | 120.8      | 850.2          | 15.2
 ...
```

### Dashboard Completo
```sql
SELECT ranking_patrimonio, nome_grupo, pl_bilhoes,
       rentabilidade_pct, fluxo_milhoes, tendencia_mes
FROM v_dashboard_top100;
```

### Maiores Compradores
```sql
SELECT * FROM v_maiores_compradores LIMIT 10;
```

### Maiores Vendedores
```sql
SELECT * FROM v_maiores_vendedores LIMIT 10;
```

---

## Queries Úteis do Dia a Dia

### 1. Top 5 Grupos
```sql
SELECT ranking_patrimonio, nome_grupo, tipo_grupo,
       pl_bilhoes, rentabilidade_pct
FROM v_dashboard_top100
WHERE ranking_patrimonio <= 5;
```

### 2. Quem Está Comprando?
```sql
SELECT nome_grupo, fluxo_milhoes, volume_milhoes, tendencia_mes
FROM v_dashboard_top100
WHERE tendencia_mes = 'COMPRADOR'
ORDER BY fluxo_milhoes DESC LIMIT 10;
```

### 3. Melhor Rentabilidade
```sql
SELECT nome_grupo, rentabilidade_pct, lucro_milhoes,
       melhor_acao_ticker, melhor_acao_pct
FROM v_dashboard_top100
ORDER BY rentabilidade_pct DESC NULLS LAST LIMIT 10;
```

### 4. Evolução de um Grupo
```sql
SELECT ano, mes, ranking_patrimonio, pl_bilhoes, rentabilidade_pct
FROM ranking_top100_grupos
WHERE nome_grupo = 'BTG Pactual'
ORDER BY ano, mes;
```

### 5. Concentração de Mercado
```sql
SELECT faixa, COUNT(*) AS qtd_grupos,
       SUM(pl_bilhoes) AS pl_total,
       MAX(percentual_acumulado) AS perc_mercado
FROM v_concentracao_mercado_top100
GROUP BY faixa
ORDER BY MAX(percentual_acumulado);
```

---

## Análise de Ações (Se Populou com Dados Reais)

### Top Ações Mais Compradas
```sql
SELECT ticker, empresa_nome, setor,
       total_comprado / 1000000.0 AS comprado_milhoes,
       qtd_fundos_compradores
FROM v_ranking_compras_top100
WHERE ano = 2025 AND mes = 10 AND ranking_compra <= 10;
```

### Fluxo Líquido por Ação
```sql
SELECT ticker, empresa_nome, setor,
       fluxo_liquido / 1000000.0 AS fluxo_milhoes,
       tendencia_mercado
FROM v_fluxo_liquido_acoes_top100
WHERE ano = 2025 AND mes = 10
ORDER BY ABS(fluxo_liquido) DESC LIMIT 20;
```

---

## Acessar via API (Opcional)

### 1. Habilitar API

No Supabase Dashboard:
- **Settings** → **API**
- Copie **URL** e **anon key**

### 2. Testar

```bash
curl "https://[seu-projeto].supabase.co/rest/v1/v_top100_atual" \
  -H "apikey: [sua-key]" \
  -H "Authorization: Bearer [sua-key]"
```

### 3. Usar em Python

```python
from supabase import create_client

supabase = create_client(
    "https://[seu-projeto].supabase.co",
    "[sua-anon-key]"
)

result = supabase.table('v_top100_atual').select("*").execute()
print(result.data)
```

---

## Próximos Passos

### Atualização Mensal

```sql
-- Todo mês:
SELECT * FROM atualizar_ranking_top100_v2(2025, 11); -- Novembro
SELECT * FROM atualizar_ranking_top100_v2(2025, 12); -- Dezembro
```

### Aprofundar

1. **Leia:** `sql_scripts/GUIA_ANALISE_ACOES.md` - Análise detalhada de ações
2. **Leia:** `sql_scripts/EXEMPLO_OUTPUTS.md` - Exemplos visuais
3. **Leia:** `sql_scripts/15_estrategia_top100.md` - Entenda a estratégia
4. **Explore:** `sql_scripts/12_queries_insights_acoes.sql` - 10 queries prontas

### Criar Dashboard

Use ferramentas como:
- **Metabase** (open source)
- **Tableau**
- **Power BI**
- **Superset**

Conecte ao Supabase via PostgreSQL e use as views prontas.

---

## Troubleshooting

### "relation already exists"
**Solução:** Tabela já existe. Se quiser recriar:
```sql
DROP TABLE IF EXISTS [nome] CASCADE;
```

### Ranking vazio
**Solução:** Verifique se:
1. Há dados em `fato_posicoes`
2. Há dados em `dim_patrimonio_liquido`
3. Data existe em `dim_tempo`

### Query lenta
**Solução:**
1. Verifique índices: `\d [tabela]`
2. Use views _top100 (já filtradas)
3. Execute `EXPLAIN ANALYZE [sua-query]`

---

## Ajuda

- **Migração Detalhada:** `sql_scripts/README_MIGRACAO.md`
- **README Principal:** `README.md`
- **Scripts SQL:** Pasta `sql_scripts/`

---

## Resumo do Que Você Fez

✅ Criou estrutura completa no Supabase
✅ Adicionou métricas de rentabilidade
✅ Populou com dados (exemplo ou reais)
✅ Calculou ranking Top 100
✅ Fez suas primeiras consultas
✅ Está pronto para análises!

**Parabéns!** 🎉

Sistema rodando e pronto para insights estratégicos sobre o mercado de fundos brasileiro.

---

**Próxima Leitura Recomendada:** `sql_scripts/GUIA_ANALISE_ACOES.md`
