# 📂 SQL Scripts - Organização

Esta pasta contém todos os scripts SQL do sistema de análise de fundos.

---

## 📋 ESTRUTURA

```
sql_scripts/
├── 00_LIMPAR_TUDO.sql          ⭐ Limpa V1 e V2 completo
├── 01_CRIAR_SCHEMA_V2.sql      ⭐ Cria schema V2 (3 tabelas + 4 views)
├── queries_uteis/              📊 Queries prontas para análise
│   └── consultas_frequentes.sql
└── excluir/                    🗑️  Scripts obsoletos do V1
```

---

## ⭐ SCRIPTS ESSENCIAIS (RAIZ)

### `00_LIMPAR_TUDO.sql`
**Quando usar:** Antes de criar o schema V2 pela primeira vez, ou quando quiser resetar tudo.

**O que faz:**
- Remove TODAS as tabelas do V1 (dimensional)
- Remove TODAS as views do V1
- Remove TODAS as funções antigas
- Remove tabelas do V2 (se existirem)

**Como usar:**
1. Abra Supabase SQL Editor
2. Copie e cole TODO o conteúdo deste arquivo
3. Clique RUN
4. Deve aparecer: `✅ Limpeza concluída!`

---

### `01_CRIAR_SCHEMA_V2.sql`
**Quando usar:** Após limpar tudo com `00_LIMPAR_TUDO.sql`

**O que faz:**
- Cria 3 tabelas: `grupos_fundos`, `acoes_fundos`, `resumo_mensal`
- Cria 4 views: `v_top_compras_mes`, `v_top_vendas_mes`, `v_movimentos_grupo`, `v_consenso_mercado`
- Cria 1 função: `atualizar_resumo_mensal()`

**Como usar:**
1. Abra Supabase SQL Editor
2. Copie e cole TODO o conteúdo deste arquivo
3. Clique RUN
4. Deve aparecer: `✅ Schema V2 criado com sucesso!`

---

## 📊 QUERIES ÚTEIS (`queries_uteis/`)

### `consultas_frequentes.sql`
**12 queries prontas para usar!**

1. Top 20 Ações Mais Compradas
2. Top 20 Ações Mais Vendidas
3. Consenso de Mercado
4. Movimentos de um Grupo
5. Evolução de uma Ação
6. Grupos Mais Ativos
7. Ações Mais Populares
8. Comparar Dois Grupos
9. Resumo Geral
10. Lista de Grupos
11. Ações com Divergência
12. Rentabilidade dos Grupos

---

## 🗑️ EXCLUIR (`excluir/`)

Scripts obsoletos do Sistema V1. Podem ser deletados.

Contém 17 arquivos antigos do modelo dimensional que foram substituídos pelo V2 simplificado.

---

## 🚀 PASSO A PASSO

**Primeira vez:**
1. Execute: `00_LIMPAR_TUDO.sql`
2. Execute: `01_CRIAR_SCHEMA_V2.sql`
3. Execute o ETL: `./executar_etl.sh`
4. Use queries de `queries_uteis/`

**Já configurado:**
- Use apenas queries de `queries_uteis/`
