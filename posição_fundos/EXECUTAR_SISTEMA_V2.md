# 🚀 GUIA DE EXECUÇÃO - SISTEMA V2

## PASSO 1: Limpar e Criar Schema no Supabase

### 1.1 Acesse o Supabase
https://app.supabase.com → Seu Projeto → SQL Editor

### 1.2 Execute o Script de Limpeza

Copie e cole **TODO** o conteúdo de:
```
sql_scripts/00_LIMPAR_TUDO.sql
```

Clique em **RUN** (ou Ctrl+Enter)

**Deve aparecer:**
```
✅ Limpeza concluída! Agora execute: 01_CRIAR_SCHEMA_V2.sql
```

### 1.3 Execute o Script de Criação

Copie e cole **TODO** o conteúdo de:
```
sql_scripts/01_CRIAR_SCHEMA_V2.sql
```

Clique em **RUN**

**Deve aparecer:**
```
✅ Schema V2 criado com sucesso!
📊 3 tabelas: grupos_fundos, acoes_fundos, resumo_mensal
👁️  4 views: v_top_compras_mes, v_top_vendas_mes, v_movimentos_grupo, v_consenso_mercado
```

### 1.4 Verificar

Execute:
```sql
SELECT table_name FROM information_schema.tables
WHERE table_schema = 'public' AND table_type = 'BASE TABLE';
```

**Deve mostrar APENAS:**
- grupos_fundos
- acoes_fundos
- resumo_mensal

---

## PASSO 2: Executar ETL

### 2.1 Abrir Terminal

```bash
cd posição_fundos/etl_v2
source venv/bin/activate
```

### 2.2 Verificar Credenciais

O arquivo `.env` já está configurado com:
```
SUPABASE_URL=https://ryfhupidxkghwkczulgg.supabase.co
SUPABASE_KEY=eyJhbGci...
```

### 2.3 Executar Menu Interativo

```bash
python main_interactive.py
```

### 2.4 Seguir Menu

```
╔═══════════════════════════════════════════════════════════════╗
║         📊  ANÁLISE DE FUNDOS CVM - V2.0                     ║
║         Para Investidores Que Querem Copiar os Grandes       ║
╚═══════════════════════════════════════════════════════════════╝

📅 Selecione os meses para processar:
  Use ESPAÇO para marcar, ENTER para confirmar

> [x] Agosto 2025
  [x] Setembro 2025
  [x] Outubro 2025
  [x] Novembro 2025

📊 Selecione os tipos de dados:
> [x] Ações B3 (principal) ⭐⭐⭐⭐⭐
  [ ] Títulos Públicos ⭐⭐
  [ ] Investimento Exterior ⭐⭐⭐
```

**Recomendação para primeiro teste:**
- Marque APENAS "Novembro 2025" (mais recente)
- Marque "Ações B3"
- Confirme

**Tempo estimado:** ~30 segundos por mês

### 2.5 Aguardar Processamento

Você verá:
```
🚀 INICIANDO PROCESSAMENTO...

📅 Processando Novembro 2025...
   📊 Processando ações...
      ✓ 100 grupos Top 100
      ✓ PL total: R$ 13024.87 bi
      ✓ 40,793 posições
      ✓ 2,856 tickers
   📤 Upload para Supabase...
      ✓ 100 grupos | 40,793 ações | 2,856 tickers

✅ PROCESSAMENTO CONCLUÍDO!
```

---

## PASSO 3: Consultar Dados

### 3.1 Top 20 Ações Mais Compradas

```sql
SELECT
    ticker,
    empresa,
    comprado_milhoes,
    qtd_fundos_compradores,
    top_comprador,
    top_comprador_milhoes
FROM v_top_compras_mes
WHERE mes_referencia = '2025-11-30'
  AND ranking <= 20
ORDER BY ranking;
```

### 3.2 Consenso de Mercado

```sql
SELECT
    ticker,
    empresa,
    sinal,
    fluxo_bilhoes,
    qtd_fundos_compradores,
    qtd_fundos_vendedores
FROM v_consenso_mercado
WHERE intensidade_consenso > 70
LIMIT 20;
```

### 3.3 O que o Itaú Está Fazendo

```sql
SELECT
    ticker,
    empresa,
    tipo_movimento,
    fluxo_milhoes,
    posicao_milhoes
FROM v_movimentos_grupo
WHERE nome_grupo = 'Itaú'
  AND mes_referencia = '2025-11-30'
  AND tipo_movimento = 'COMPRA'
ORDER BY fluxo_milhoes DESC
LIMIT 10;
```

### 3.4 Comparar 4 Meses (Após processar todos)

```sql
SELECT
    mes_referencia,
    ticker,
    comprado_milhoes
FROM v_top_compras_mes
WHERE ticker = 'PETR4'
ORDER BY mes_referencia;
```

---

## 🎯 RESUMO DO QUE FOI FEITO

### Arquivos SQL
- ✅ `00_LIMPAR_TUDO.sql` - Remove V1 completo
- ✅ `01_CRIAR_SCHEMA_V2.sql` - Cria 3 tabelas + 4 views

### Código Python
- ✅ `processors/grupos_processor.py` - Extrai Top 100
- ✅ `processors/acoes_processor.py` - Processa ações
- ✅ `uploader.py` - Upload para Supabase
- ✅ `main_interactive.py` - Menu interativo completo

### Dados
- 📅 4 meses disponíveis (Ago-Nov 2025)
- 🎯 Top 100 grupos (~95% do mercado)
- 📊 Apenas ações (BLC_4) - o que importa

---

## ⚠️ Solução de Problemas

### Erro: "Credenciais não encontradas"

Verifique `.env`:
```bash
cat etl_v2/.env
```

Deve ter:
```
SUPABASE_URL=https://...
SUPABASE_KEY=eyJ...
```

### Erro: "Módulo não encontrado"

```bash
cd etl_v2
source venv/bin/activate
pip install -r requirements.txt
```

### Tabelas vazias após ETL

1. Verifique se executou `00_LIMPAR_TUDO.sql` ANTES
2. Verifique se executou `01_CRIAR_SCHEMA_V2.sql` DEPOIS
3. Execute ETL novamente

### Ver logs de erro

Durante execução do ETL, erros aparecem em vermelho.
Copie e envie para análise.

---

## 📈 PRÓXIMOS PASSOS

Após ter dados carregados:

1. **Dashboard Streamlit** (opcional)
   - Gráficos bonitos
   - Comparação temporal
   - Filtros interativos

2. **Alertas** (opcional)
   - Avisar quando um grupo grande muda posição
   - Notificar consenso forte (>80%)

3. **API** (opcional)
   - Expor dados via REST
   - Usar em aplicativo mobile

---

## ✅ CHECKLIST DE EXECUÇÃO

- [ ] Executei `00_LIMPAR_TUDO.sql` no Supabase
- [ ] Executei `01_CRIAR_SCHEMA_V2.sql` no Supabase
- [ ] Verifiquei que existem apenas 3 tabelas
- [ ] Executei `python main_interactive.py`
- [ ] Processei pelo menos 1 mês
- [ ] Consultei `v_top_compras_mes` e vi dados
- [ ] Consultei `v_consenso_mercado` e vi sinais

---

**Se tudo deu certo, você terá:**
- ✅ Schema limpo no Supabase
- ✅ Dados de ações dos Top 100 grupos
- ✅ 4 views prontas para análise
- ✅ Insights sobre o mercado

**Tempo total:** ~5 minutos

Sucesso! 🎉
