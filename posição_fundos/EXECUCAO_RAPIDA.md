# Execução Rápida - Sistema Completo

Guia prático para colocar o sistema funcionando em **15 minutos**.

---

## ⚡ Resumo do Sistema

**Sistema de Análise de Fundos Top 100**
- Processa dados da CVM
- Foca nos 100 maiores grupos (95%+ do mercado)
- Rankings múltiplos (patrimônio, volume, fluxo, rentabilidade)
- Sobe para Supabase automaticamente

---

## 📋 Checklist Rápido

- [ ] Criar projeto no Supabase
- [ ] Executar script de migração SQL
- [ ] Configurar credenciais no ETL
- [ ] Instalar dependências Python
- [ ] Executar ETL
- [ ] Verificar dados no Supabase

---

## 🚀 Passo a Passo

### 1. Criar Estrutura no Supabase (5 min)

**1.1. Acessar Supabase**
```
https://supabase.com → Login → New Project
```

**1.2. Executar Migração**
1. Vá em **SQL Editor** (ícone na lateral)
2. Abra: `sql_scripts/17_migracao_completa_supabase.sql`
3. Copie TODO o conteúdo
4. Cole no SQL Editor
5. Clique em **RUN** (ou Ctrl+Enter)
6. Aguarde 2-3 minutos

**1.3. Adicionar Rentabilidade**
1. Abra: `sql_scripts/16_adicionar_rentabilidade.sql`
2. Copie e cole no SQL Editor
3. Execute (RUN)

✅ **Estrutura criada!** (10 tabelas, 20+ índices, 2 views)

---

### 2. Configurar ETL (3 min)

**2.1. Obter Credenciais do Supabase**
1. No Supabase, vá em **Settings** → **API**
2. Copie:
   - **URL:** `https://[seu-projeto].supabase.co`
   - **service_role key** (chave secreta, não a anon!)

**2.2. Configurar .env**
```bash
cd etl_app
cp .env.example .env
nano .env  # ou abra em editor de texto
```

**Cole suas credenciais:**
```env
SUPABASE_URL=https://[seu-projeto].supabase.co
SUPABASE_KEY=[sua-service-role-key-aqui]
```

Salve e feche.

---

### 3. Instalar Dependências (2 min)

```bash
# Criar ambiente virtual
python3 -m venv venv
source venv/bin/activate  # Windows: venv\Scripts\activate

# Instalar
pip install -r requirements.txt
```

---

### 4. Executar ETL (5 min)

**Certifique-se que tem os CSVs:**
```bash
ls ../source/
# Deve listar: cda_fi_PL_202510.csv, cda_fi_BLC_4_202510.csv, etc.
```

**Executar:**
```bash
python main.py --mes 10
```

**O que acontece:**
1. ✅ Lê CSVs da CVM
2. ✅ Identifica Top 100 grupos
3. ✅ Processa posições em ações
4. ✅ Faz upload para Supabase
5. ✅ Calcula ranking

**Tempo estimado:** 3-5 minutos (depende do tamanho dos CSVs)

---

### 5. Verificar Resultado (1 min)

**No Supabase SQL Editor:**

```sql
-- Ver Top 10 grupos
SELECT * FROM v_top100_atual LIMIT 10;

-- Dashboard completo
SELECT ranking_patrimonio, nome_grupo, pl_bilhoes,
       rentabilidade_pct, fluxo_milhoes, tendencia_mes
FROM v_dashboard_top100;

-- Verificar quantidade de dados
SELECT
  (SELECT COUNT(*) FROM ranking_top100_grupos) as ranking_count,
  (SELECT COUNT(*) FROM dim_fundos) as fundos_count,
  (SELECT COUNT(*) FROM fato_posicoes) as posicoes_count;
```

✅ **Se retornar dados, está funcionando!**

---

## 📊 Consultas Úteis

### Top 10 por Patrimônio
```sql
SELECT ranking_patrimonio, nome_grupo, pl_bilhoes, qtd_fundos
FROM v_top100_atual
WHERE ranking_patrimonio <= 10;
```

### Top 10 por Rentabilidade
```sql
SELECT nome_grupo, rentabilidade_pct, lucro_milhoes,
       melhor_acao_ticker, melhor_acao_pct
FROM v_dashboard_top100
ORDER BY rentabilidade_pct DESC NULLS LAST LIMIT 10;
```

### Maiores Compradores
```sql
SELECT nome_grupo, fluxo_milhoes, volume_milhoes
FROM v_dashboard_top100
WHERE tendencia_mes = 'COMPRADOR'
ORDER BY fluxo_milhoes DESC LIMIT 10;
```

### Ações Mais Compradas
```sql
SELECT ticker, empresa_nome, setor,
       total_comprado / 1000000.0 AS comprado_milhoes,
       qtd_fundos_compradores
FROM v_ranking_compras_top100
WHERE ano = 2025 AND mes = 10 AND ranking_compra <= 10;
```

---

## 🔄 Atualização Mensal

**Todo mês, quando CVM divulgar novos dados:**

```bash
# 1. Baixar novos CSVs da CVM para pasta source/

# 2. Executar ETL
cd etl_app
source venv/bin/activate
python main.py --mes 11  # Próximo mês

# 3. Verificar no Supabase
# SELECT * FROM v_top100_atual;
```

---

## ⚠️ Troubleshooting

### "Arquivo não encontrado"
**Problema:** CSVs da CVM não estão na pasta `source/`

**Solução:**
```bash
# Verificar
ls source/

# Deve ter:
# cda_fi_PL_202510.csv
# cda_fi_BLC_4_202510.csv
# cda_fie_202510.csv
```

### "Credenciais do Supabase não encontradas"
**Problema:** Arquivo `.env` não configurado

**Solução:**
```bash
cd etl_app
cat .env  # Verificar se tem URL e KEY

# Se não tiver, copiar do example:
cp .env.example .env
nano .env  # Editar com credenciais
```

### "Error: relation does not exist"
**Problema:** Estrutura não foi criada no Supabase

**Solução:**
1. Execute `sql_scripts/17_migracao_completa_supabase.sql` no Supabase
2. Execute `sql_scripts/16_adicionar_rentabilidade.sql`

### Pipeline demora muito
**Problema:** Processando muitos dados

**Solução:**
- Normal: 3-5 minutos para ~25.000 fundos
- Se > 10 min, aumente BATCH_SIZE no .env:
```env
BATCH_SIZE=2000
```

---

## 📁 Estrutura de Arquivos

```
posição_fundos/
├── EXECUCAO_RAPIDA.md        ← Você está aqui
├── README.md                  ← Documentação completa
├── INICIO_RAPIDO.md           ← Guia do sistema
│
├── source/                    ← CSVs da CVM (baixar da CVM)
│   ├── cda_fi_PL_202510.csv
│   ├── cda_fi_BLC_4_202510.csv
│   └── cda_fie_202510.csv
│
├── etl_app/                   ← Pipeline ETL (executar aqui)
│   ├── main.py                ← Executar: python main.py --mes 10
│   ├── .env                   ← Configurar suas credenciais
│   └── README.md              ← Guia do ETL
│
├── sql_scripts/               ← Scripts SQL para Supabase
│   ├── 17_migracao_completa_supabase.sql  ← Executar 1º no Supabase
│   └── 16_adicionar_rentabilidade.sql     ← Executar 2º no Supabase
│
├── processed/                 ← Dados processados (backup local)
└── logs/                      ← Logs de execução
```

---

## 🎯 Próximos Passos

### 1. Criar Dashboard
Use as views prontas para criar visualizações:
- **Metabase** (open source)
- **Tableau**
- **Power BI**
- **Streamlit** (Python)

Conecte via PostgreSQL:
```
Host: [seu-projeto].supabase.co
Port: 5432
Database: postgres
User: postgres
Password: [sua-senha-do-projeto]
```

### 2. Agendar Execução Automática

**Linux/Mac (cron):**
```bash
# Executar todo dia 1º do mês às 6h
0 6 1 * * cd /path/to/etl_app && ./main.py --mes $(date +\%m)
```

**Windows (Task Scheduler):**
1. Abrir Task Scheduler
2. Create Basic Task
3. Agendar para 1º de cada mês
4. Action: `python C:\path\to\etl_app\main.py --mes XX`

### 3. API REST

O Supabase já expõe API REST automaticamente:

```bash
# Exemplo
curl "https://[seu-projeto].supabase.co/rest/v1/v_top100_atual" \
  -H "apikey: [sua-anon-key]" \
  -H "Authorization: Bearer [sua-anon-key]"
```

---

## 📚 Documentação Adicional

- **README.md** - Visão geral completa do sistema
- **INICIO_RAPIDO.md** - Guia detalhado passo a passo
- **etl_app/README.md** - Documentação do ETL
- **sql_scripts/README_MIGRACAO.md** - Migração para novo Supabase
- **sql_scripts/15_estrategia_top100.md** - Estratégia Top 100
- **sql_scripts/GUIA_ANALISE_ACOES.md** - Como analisar ações

---

## ✅ Checklist Final

Depois de executar tudo, verifique:

- [ ] ✅ Estrutura criada no Supabase (10 tabelas)
- [ ] ✅ ETL configurado (.env com credenciais)
- [ ] ✅ Dependências instaladas (requirements.txt)
- [ ] ✅ Pipeline executado com sucesso
- [ ] ✅ Dados visíveis no Supabase (v_top100_atual)
- [ ] ✅ Ranking calculado (ranking_top100_grupos)
- [ ] ✅ Backup local salvo (processed/)

**Se todos marcados: SISTEMA PRONTO! 🎉**

---

**Versão:** 1.0.0
**Data:** 2025-12-13
**Status:** ✅ Pronto para produção
