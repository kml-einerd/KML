# Scripts SQL - Modelo Dimensional Posição de Fundos

Scripts SQL para criação das tabelas do modelo dimensional no Supabase.

## Estrutura dos Scripts

### Scripts CREATE TABLE

Execute na ordem:

1. **01_dim_tempo.sql** - Dimensão temporal
2. **02_dim_grupos_economicos.sql** - Grupos econômicos (BTG, Itaú, XP, etc.)
3. **03_dim_categoria_ativo.sql** - Hierarquia de categorias (3 níveis)
4. **04_dim_emissores.sql** - Cadastro de emissores
5. **05_dim_ativos.sql** - Cadastro de ativos específicos
6. **06_dim_fundos.sql** - Cadastro de fundos (SCD Type 2)
7. **07_fato_posicoes.sql** - Tabela fato principal
8. **08_dim_patrimonio_liquido.sql** - Histórico de PL dos fundos
9. **09_dados_exemplo.sql** - Dados de exemplo (4 linhas por tabela)

## Como Usar no Supabase

### Opção 1: Via SQL Editor (Recomendado)

1. Acesse o Supabase Dashboard
2. Vá em **SQL Editor**
3. Crie uma nova query
4. Copie e cole o conteúdo de cada arquivo na ordem acima
5. Execute cada script (Cmd+Enter ou Ctrl+Enter)

### Opção 2: Via CLI

```bash
# Conectar ao banco
psql "postgresql://postgres:[PASSWORD]@[HOST]:5432/postgres"

# Executar scripts na ordem
\i 01_dim_tempo.sql
\i 02_dim_grupos_economicos.sql
\i 03_dim_categoria_ativo.sql
\i 04_dim_emissores.sql
\i 05_dim_ativos.sql
\i 06_dim_fundos.sql
\i 07_fato_posicoes.sql
\i 08_dim_patrimonio_liquido.sql
\i 09_dados_exemplo.sql
```

### Opção 3: Script Único

```bash
# Criar um único arquivo com todos os scripts
cat 01_dim_tempo.sql 02_dim_grupos_economicos.sql 03_dim_categoria_ativo.sql 04_dim_emissores.sql 05_dim_ativos.sql 06_dim_fundos.sql 07_fato_posicoes.sql 08_dim_patrimonio_liquido.sql > create_all_tables.sql

# Executar no Supabase
psql "postgresql://postgres:[PASSWORD]@[HOST]:5432/postgres" < create_all_tables.sql
```

## Tabelas Criadas

### Dimensões

| Tabela | Descrição | Registros Exemplo |
|--------|-----------|-------------------|
| `dim_tempo` | Dimensão temporal | 4 datas |
| `dim_grupos_economicos` | Grupos econômicos | 4 grupos |
| `dim_categoria_ativo` | Hierarquia de categorias | 4 categorias |
| `dim_emissores` | Cadastro de emissores | 4 emissores |
| `dim_ativos` | Cadastro de ativos | 4 ativos |
| `dim_fundos` | Cadastro de fundos | 4 fundos |
| `dim_patrimonio_liquido` | Histórico de PL | 4 registros |

### Fatos

| Tabela | Descrição | Registros Exemplo |
|--------|-----------|-------------------|
| `fato_posicoes` | Posições dos fundos | 4 posições |

## Dados de Exemplo

O arquivo `09_dados_exemplo.sql` contém 4 linhas de exemplo para cada tabela, baseadas nos arquivos CSV reais:

- **Títulos Públicos**: LFT com vencimentos diferentes
- **Ações**: ITUB3 (Itaú) e JHSF3 (JHSF Participações)
- **Fundos**: 4 fundos diferentes (FIF, FIA)
- **Grupos**: BTG Pactual, Itaú, XP, Caixa

Todos os valores (CNPJs, quantidades, valores) são reais extraídos de:
- `source/cda_fi_BLC_1_202510.csv` (Títulos Públicos)
- `source/cda_fi_BLC_4_202510.csv` (Ações)
- `source/cda_fi_PL_202510.csv` (Patrimônio Líquido)

## Relacionamentos

```
dim_grupos_economicos
    ↓
dim_fundos ──────────────┐
    ↓                     │
dim_patrimonio_liquido   │
                         │
dim_tempo ───────────────┤
                         │
dim_categoria_ativo ─────┤
                         ↓
dim_emissores ──────→ fato_posicoes
                         ↑
dim_ativos ──────────────┘
```

## Próximos Passos

Após criar as tabelas:

1. Popular dimensões com dados completos dos CSVs
2. Carregar fato_posicoes com todas as ~600K posições
3. Criar materialized views para agregações
4. Configurar refresh automático das views
5. Criar índices adicionais conforme necessário

## Manutenção

### Verificar tabelas criadas

```sql
SELECT table_name
FROM information_schema.tables
WHERE table_schema = 'public'
  AND table_name LIKE 'dim_%' OR table_name LIKE 'fato_%';
```

### Verificar registros

```sql
SELECT
    'dim_tempo' AS tabela, COUNT(*) AS registros FROM dim_tempo
UNION ALL
SELECT 'dim_grupos_economicos', COUNT(*) FROM dim_grupos_economicos
UNION ALL
SELECT 'dim_categoria_ativo', COUNT(*) FROM dim_categoria_ativo
UNION ALL
SELECT 'dim_emissores', COUNT(*) FROM dim_emissores
UNION ALL
SELECT 'dim_ativos', COUNT(*) FROM dim_ativos
UNION ALL
SELECT 'dim_fundos', COUNT(*) FROM dim_fundos
UNION ALL
SELECT 'dim_patrimonio_liquido', COUNT(*) FROM dim_patrimonio_liquido
UNION ALL
SELECT 'fato_posicoes', COUNT(*) FROM fato_posicoes;
```

### Limpar tudo (cuidado!)

```sql
-- ATENÇÃO: Apaga todas as tabelas
DROP TABLE IF EXISTS fato_posicoes CASCADE;
DROP TABLE IF EXISTS dim_patrimonio_liquido CASCADE;
DROP TABLE IF EXISTS dim_fundos CASCADE;
DROP TABLE IF EXISTS dim_ativos CASCADE;
DROP TABLE IF EXISTS dim_emissores CASCADE;
DROP TABLE IF EXISTS dim_categoria_ativo CASCADE;
DROP TABLE IF EXISTS dim_grupos_economicos CASCADE;
DROP TABLE IF EXISTS dim_tempo CASCADE;
```

## Referências

- **ANALISE_E_OTIMIZACAO.md** - Documentação completa do modelo
- **GUIA_MIGRACAO.md** - Guia de migração passo a passo
- **QUERIES_EXEMPLOS.md** - Queries de exemplo para análise
