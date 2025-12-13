## Migração para Novo Supabase - Guia Completo

Guia passo a passo para migrar o sistema de análise de fundos para um novo projeto Supabase.

---

## Estrutura do Sistema

### Foco Estratégico: Top 100 Grupos

O sistema foi otimizado para processar apenas os **100 maiores grupos econômicos** do mercado, que representam **95%+ do patrimônio total** dos fundos brasileiros.

**Benefícios:**
- ✅ 90% menos dados para processar
- ✅ Queries 90% mais rápidas
- ✅ Cobertura de 95%+ do mercado
- ✅ Fácil manutenção

---

## Passo 1: Criar Estrutura no Novo Supabase

### 1.1. Acessar o Novo Projeto Supabase
1. Acesse https://supabase.com
2. Crie novo projeto ou acesse projeto existente
3. Vá em **SQL Editor**

### 1.2. Executar Script de Criação

Copie e cole o conteúdo do arquivo `17_migracao_completa_supabase.sql` no SQL Editor e execute.

**O que será criado:**
- 8 tabelas dimensão (dim_tempo, dim_grupos_economicos, dim_categoria_ativo, etc.)
- 1 tabela fato (fato_posicoes)
- 1 tabela de ranking (ranking_top100_grupos)
- 2 views principais (v_top100_atual, v_dashboard_top100)
- Todos os índices necessários

**Tempo estimado:** 2-3 minutos

### 1.3. Verificar Criação

Execute no SQL Editor:
```sql
SELECT table_name
FROM information_schema.tables
WHERE table_schema = 'public'
  AND table_type = 'BASE TABLE'
ORDER BY table_name;
```

**Resultado esperado:**
```
dim_acoes_b3
dim_ativos
dim_categoria_ativo
dim_emissores
dim_fundos
dim_grupos_economicos
dim_patrimonio_liquido
dim_tempo
fato_posicoes
ranking_top100_grupos
```

---

## Passo 2: Popular com Dados

### Opção A: Importar CSVs da CVM (Recomendado)

Use o pipeline ETL para processar os arquivos CSV da pasta `source/`:

```bash
cd etl_app
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
python3 main_etl.py --mes 202510 --top100
```

O parâmetro `--top100` faz com que apenas os 100 maiores grupos sejam processados.

### Opção B: Exportar do Supabase Antigo (Se já tem dados)

Se você já tem dados em outro Supabase, use pg_dump/pg_restore:

```bash
# Exportar do antigo
pg_dump -h <host-antigo> -U <user> -d <database> \
  -t ranking_top100_grupos \
  -t dim_grupos_economicos \
  --data-only \
  -F c \
  -f dados_ranking.dump

# Importar no novo
pg_restore -h <host-novo> -U <user> -d <database> \
  --data-only \
  dados_ranking.dump
```

### Opção C: Dados de Exemplo (Para Testar)

Execute o script `09_dados_exemplo.sql` para popular com dados de teste:

```sql
-- No SQL Editor do novo Supabase
-- Copie e cole o conteúdo de 09_dados_exemplo.sql
```

---

## Passo 3: Adicionar Rentabilidade

Execute o script `16_adicionar_rentabilidade.sql` no SQL Editor:

```sql
-- Adiciona campos de rentabilidade
-- Cria função atualizada de ranking
-- Cria views de performance
```

**Novos campos adicionados:**
- `rentabilidade_media_acoes` - Rentabilidade média das posições
- `lucro_prejuizo_total` - Lucro/prejuízo total
- `rentabilidade_pl` - Rentabilidade como % do PL
- `melhor_acao_ticker` - Melhor ação na carteira
- `melhor_acao_rentabilidade` - Rentabilidade da melhor ação
- `pior_acao_ticker` - Pior ação na carteira
- `pior_acao_rentabilidade` - Rentabilidade da pior ação

---

## Passo 4: Calcular Ranking

Após popular os dados, execute:

```sql
-- Calcular ranking para Outubro/2025
SELECT * FROM atualizar_ranking_top100_v2(2025, 10);

-- Verificar resultado
SELECT * FROM v_top100_atual LIMIT 10;
```

**Output esperado:**
```
 ranking | nome_grupo        | pl_bilhoes | volume_milhoes | rentabilidade_pct
---------+-------------------+------------+----------------+------------------
 1       | BTG Pactual       | 180.5      | 1250.3         | 12.5
 2       | Itaú Unibanco     | 250.2      | 980.7          | 8.3
 3       | XP Investimentos  | 120.8      | 850.2          | 15.2
 ...
```

---

## Passo 5: Configurar API (Opcional)

### 5.1. Habilitar API REST

No dashboard do Supabase:
1. Vá em **Settings** → **API**
2. Copie a **URL** e a **anon/public key**

### 5.2. Testar API

```bash
curl "https://<seu-projeto>.supabase.co/rest/v1/v_top100_atual" \
  -H "apikey: <sua-key>" \
  -H "Authorization: Bearer <sua-key>"
```

### 5.3. Criar RLS Policies (Segurança)

Se quiser controlar acesso:

```sql
-- Permitir leitura pública nas views
ALTER TABLE v_top100_atual ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Permitir leitura pública"
ON v_top100_atual FOR SELECT
USING (true);
```

---

## Passo 6: Queries Úteis

### Ver Top 10 por Patrimônio
```sql
SELECT ranking_patrimonio, nome_grupo, pl_bilhoes,
       rentabilidade_pct, tendencia_mes
FROM v_top100_atual
WHERE ranking_patrimonio <= 10;
```

### Ver Top 10 por Rentabilidade
```sql
SELECT nome_grupo, rentabilidade_pct,
       lucro_milhoes, melhor_acao_ticker
FROM v_dashboard_top100
ORDER BY rentabilidade_pct DESC NULLS LAST
LIMIT 10;
```

### Ver Maiores Compradores
```sql
SELECT nome_grupo, fluxo_milhoes, volume_milhoes
FROM v_dashboard_top100
WHERE tendencia_mes = 'COMPRADOR'
ORDER BY fluxo_milhoes DESC
LIMIT 10;
```

### Ver Evolução de um Grupo
```sql
SELECT ano, mes, ranking_patrimonio, pl_bilhoes,
       rentabilidade_pct, tendencia_mes
FROM ranking_top100_grupos
WHERE nome_grupo = 'BTG Pactual'
ORDER BY ano, mes;
```

---

## Estrutura de Arquivos

```
sql_scripts/
├── 01-08: Tabelas dimensão e fato
├── 09: Dados de exemplo
├── 10-12: Análise de ações B3
├── 13-14: Ranking Top 100
├── 15: Estratégia Top 100 (documentação)
├── 16: Adicionar rentabilidade
├── 17: Migração completa (ESTE ARQUIVO)
└── README_MIGRACAO.md (ESTE GUIA)
```

---

## Ordem de Execução

Para novo Supabase completamente vazio:

1. **17_migracao_completa_supabase.sql** → Criar estrutura
2. Importar dados (ETL ou pg_dump)
3. **16_adicionar_rentabilidade.sql** → Adicionar campos de performance
4. Executar `atualizar_ranking_top100_v2(ano, mes)` → Calcular ranking
5. Testar queries

---

## Troubleshooting

### Erro: "relation already exists"
**Solução:** A tabela já existe. Se quiser recriar:
```sql
DROP TABLE IF EXISTS <nome_tabela> CASCADE;
-- Depois execute novamente o script de criação
```

### Erro: "foreign key constraint"
**Solução:** Execute os scripts na ordem correta (dimensões antes do fato)

### Ranking vazio
**Solução:** Verifique se:
1. Dimensões estão populadas
2. fato_posicoes tem dados
3. Data especificada existe em dim_tempo

### Performance lenta
**Solução:**
1. Verifique índices: `\d <tabela>`
2. Analise query plan: `EXPLAIN ANALYZE <sua-query>`
3. Certifique-se que está usando views _top100

---

## Conexão do Supabase

### Via psql
```bash
psql "postgresql://postgres:[SUA-SENHA]@[SEU-HOST]:5432/postgres"
```

### Via Python
```python
from supabase import create_client, Client

url = "https://[seu-projeto].supabase.co"
key = "[sua-anon-key]"
supabase: Client = create_client(url, key)

# Query
result = supabase.table('v_top100_atual').select("*").execute()
print(result.data)
```

### Via JavaScript
```javascript
import { createClient } from '@supabase/supabase-js'

const supabase = createClient(
  'https://[seu-projeto].supabase.co',
  '[sua-anon-key]'
)

const { data } = await supabase
  .from('v_top100_atual')
  .select('*')

console.log(data)
```

---

## Manutenção Mensal

```sql
-- Todo mês, executar:
SELECT * FROM atualizar_ranking_top100_v2(2025, 11); -- Novembro
SELECT * FROM atualizar_ranking_top100_v2(2025, 12); -- Dezembro
-- etc.

-- Verificar resultado
SELECT * FROM v_top100_atual;
```

---

## Próximos Passos

1. ✅ Migrar estrutura
2. ✅ Importar dados
3. ✅ Calcular ranking
4. 📊 Criar dashboard (Metabase, Tableau, Power BI)
5. 🔔 Configurar alertas
6. 📈 Análises avançadas

---

## Suporte

- Documentação Supabase: https://supabase.com/docs
- Documentação PostgreSQL: https://www.postgresql.org/docs/
- Issues: Ver README.md principal do projeto

---

**Última atualização:** 2025-12-13
**Versão:** 2.0 (Top 100 + Rentabilidade)
