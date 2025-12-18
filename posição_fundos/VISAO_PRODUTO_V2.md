# 📊 Análise de Fundos CVM - Visão do Produto V2.0

**Análise completa dos dados brutos e proposta de solução focada no investidor comum**

---

## 🎯 PERSONA: O INVESTIDOR COMUM BRASILEIRO

### Quem é?
- **Nome:** João, 35 anos, analista de sistemas
- **Patrimônio:** R$ 200 mil investidos
- **Objetivo:** Copiar estratégias dos grandes players
- **Conhecimento:** Intermediário - sabe o básico de ações
- **Frustração:** Não sabe onde os "tubarões" estão investindo

### O que João quer saber?

**Top 3 Perguntas:**
1. **"O que o Itaú está comprando?"** - Ver quais ações os grandes estão acumulando
2. **"Quem está vendendo PETR4?"** - Identificar movimentos de entrada/saída
3. **"Quais ações estão bombando entre fundos?"** - Descobrir tendências

### O que João NÃO quer?
- ❌ Tabelas gigantes com 25 mil fundos
- ❌ Modelo dimensional complexo com 10 tabelas
- ❌ Análise de debêntures, CRIs, CRAs
- ❌ Ver cotas de fundos de fundos

---

## 📁 DADOS DISPONÍVEIS (4 meses: Ago-Nov 2025)

### Estrutura dos Arquivos

Cada mês tem **12 arquivos CSV** organizados por tipo de ativo:

| Arquivo | Conteúdo | Tamanho | Relevância para João |
|---------|----------|---------|---------------------|
| **cda_fi_PL** | Patrimônio Líquido | 3.3MB | ⭐⭐⭐ Essencial |
| **cda_fi_BLC_1** | Títulos Públicos (LFT, NTN) | 8MB | ⭐ Baixa |
| **cda_fi_BLC_2** | Cotas de Fundos + Crédito | 24MB | ⭐ Baixa |
| **cda_fi_BLC_3** | ? (muito pequeno) | 25KB | ❌ Irrelevante |
| **cda_fi_BLC_4** | **AÇÕES B3** | 27MB | ⭐⭐⭐⭐⭐ **OURO!** |
| **cda_fi_BLC_5** | CDB/RDB | 12MB | ⭐ Baixa |
| **cda_fi_BLC_6** | Debêntures | 1MB | ⭐ Baixa |
| **cda_fi_BLC_7** | Investimento Exterior | 19MB | ⭐⭐ Média |
| **cda_fi_BLC_8** | Disponibilidades | 25MB | ❌ Irrelevante |
| cda_fi_CONFID | Dados confidenciais | 8MB | ❌ Não usar |
| cda_fie | Cadastro de fundos | 3-4MB | ⭐⭐ Útil |
| cda_fie_CONFID | Cadastro confidencial | 100KB | ❌ Não usar |

---

## 🎯 PROPOSTA DE SOLUÇÃO SIMPLIFICADA

### Arquitetura Minimalista

Em vez de **10 tabelas dimensionais complexas**, vamos criar **3 tabelas simples**:

```
1. grupos_fundos (dimensão)
   - id
   - nome_grupo (ex: "Itaú", "Bradesco")
   - qtd_fundos
   - pl_total

2. acoes_fundos (fato principal)
   - id
   - mes_referencia (ex: "2025-11")
   - grupo_id
   - ticker (ex: "PETR4")
   - empresa (ex: "PETROBRAS PN")
   - qtd_comprada
   - valor_comprado
   - qtd_vendida
   - valor_vendido
   - posicao_final
   - valor_mercado
   - tipo_movimento (COMPRA, VENDA, NEUTRO)

3. resumo_mensal (agregação)
   - mes_referencia
   - ticker
   - total_comprado_mercado
   - total_vendido_mercado
   - fluxo_liquido
   - qtd_fundos_compradores
   - qtd_fundos_vendedores
   - top_comprador (nome do grupo)
   - top_vendedor (nome do grupo)
```

### Dashboard que João Quer Ver

**Tela 1: Top Movimentações do Mês**
```
🔥 AÇÕES MAIS COMPRADAS (Novembro 2025)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
1. PETR4  | ↗️  R$ 2,3 bi  | 234 fundos comprando
2. VALE3  | ↗️  R$ 1,8 bi  | 189 fundos comprando
3. ITUB4  | ↗️  R$ 1,2 bi  | 156 fundos comprando

🔻 AÇÕES MAIS VENDIDAS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
1. MGLU3  | ↘️  R$ -890 mi | 98 fundos vendendo
2. VVAR3  | ↘️  R$ -650 mi | 67 fundos vendendo
```

**Tela 2: O que os Grandes Estão Fazendo**
```
💼 ITAÚ (Nov 2025)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Comprando:
  PETR4   +R$ 450 mi  (↗️ +15% vs Out)
  VALE3   +R$ 320 mi  (↗️ +8% vs Out)

Vendendo:
  MGLU3   -R$ 180 mi  (↘️ -25% vs Out)

Posição Total em Ações: R$ 267 bi
```

**Tela 3: Comparar Meses**
```
📈 PETR4 - Fluxo dos Últimos 4 Meses
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Ago: +R$ 1,2 bi ████████░░
Set: +R$ 890 mi ██████░░░░
Out: +R$ 1,8 bi ████████████
Nov: +R$ 2,3 bi ███████████████
```

---

## 🏗️ PROCESSO ETL REDESENHADO

### Fase 1: Menu Interativo

```
╔════════════════════════════════════════╗
║   ANÁLISE DE FUNDOS CVM v2.0          ║
╠════════════════════════════════════════╣
║                                        ║
║  Meses disponíveis:                    ║
║  [x] Agosto 2025                       ║
║  [x] Setembro 2025                     ║
║  [x] Outubro 2025                      ║
║  [x] Novembro 2025                     ║
║                                        ║
║  O que processar?                      ║
║  [x] Ações B3 (principal)              ║
║  [ ] Títulos Públicos                  ║
║  [ ] Investimento Exterior             ║
║                                        ║
║  [Processar] [Cancelar]                ║
╚════════════════════════════════════════╝
```

### Fase 2: Processamento Inteligente

**Apenas 2 arquivos por mês:**
1. `cda_fi_PL_*.csv` → Identificar grupos e PL
2. `cda_fi_BLC_4_*.csv` → Extrair movimentos de ações

**Transformações:**
```python
# Passo 1: Identificar Top 100 grupos por PL
grupos_top100 = identificar_top_grupos(pl_data, n=100)

# Passo 2: Filtrar ações dos Top 100
acoes_top100 = filtrar_acoes(blc4_data, grupos_top100)

# Passo 3: Classificar movimentos
acoes_top100['tipo_movimento'] = classificar(
    compras, vendas
)  # COMPRA, VENDA, NEUTRO

# Passo 4: Agregar por ticker
resumo = agregar_por_ticker(acoes_top100)
```

### Fase 3: Upload Simplificado

**Sem stored procedures complexas!**

Apenas 3 tabelas simples com UPSERT direto:

```sql
-- Limpar mês anterior
DELETE FROM acoes_fundos WHERE mes_referencia = '2025-11';
DELETE FROM resumo_mensal WHERE mes_referencia = '2025-11';

-- Inserir dados
INSERT INTO acoes_fundos (...) VALUES (...);
INSERT INTO resumo_mensal (...) VALUES (...);
```

---

## 📊 EXEMPLO DE INSIGHTS REAIS

### Insight 1: "Migração de Capital"
```
Em Novembro 2025, os fundos do Top 100 moveram:
- SAÍRAM de Tech (MGLU3, VVAR3): -R$ 1,5 bi
- ENTRARAM em Commodities (PETR4, VALE3): +R$ 4,1 bi

Interpretação: Rotação setorial - tech → commodities
```

### Insight 2: "Consenso vs Divergência"
```
PETR4:
- 234 fundos comprando vs 45 vendendo
- Consenso FORTE de compra ✓

MGLU3:
- 98 fundos vendendo vs 23 comprando
- Consenso FORTE de venda ⚠️
```

### Insight 3: "Siga o Líder"
```
Top 5 compradores de PETR4 (Nov):
1. Itaú        +R$ 450 mi
2. Bradesco    +R$ 380 mi
3. BB          +R$ 320 mi
4. Santander   +R$ 210 mi
5. BTG         +R$ 180 mi

Se você confia nos bancos, PETR4 parece boa aposta.
```

---

## 🚀 IMPLEMENTAÇÃO

### Stack Técnico Simplificado

```
Python (ETL)
   ↓
pandas + click (menu interativo)
   ↓
Supabase (3 tabelas)
   ↓
Streamlit (dashboard)
```

### Cronograma

**Fase 1 (2h):** ETL com menu interativo
**Fase 2 (1h):** Upload para Supabase
**Fase 3 (2h):** Dashboard básico Streamlit
**Fase 4 (1h):** Testes e ajustes

**Total: 6 horas** (vs 3 dias do modelo anterior)

---

## ✅ VALIDAÇÃO DA PROPOSTA

### O que conseguimos responder?

✅ **"O que o Itaú está comprando?"** → Sim, direto na tabela `acoes_fundos`
✅ **"Quem está vendendo PETR4?"** → Sim, filtro por ticker + tipo_movimento
✅ **"Quais ações estão bombando?"** → Sim, `resumo_mensal` ordenado por fluxo

### O que NÃO vamos fazer (e está OK)?

❌ Análise de debêntures (João não se importa)
❌ Modelo dimensional complexo (desnecessário)
❌ Processar todos os 25 mil fundos (Top 100 é suficiente)
❌ 17 scripts SQL diferentes (3 tabelas bastam)

---

## 🎯 PRÓXIMOS PASSOS

1. **Criar ETL interativo** com menu de seleção
2. **Desenhar 3 tabelas simples** no Supabase
3. **Processar 4 meses** de dados de ações
4. **Criar dashboard** para João usar

**Foco:** Simples, rápido, útil.

---

**Versão:** 2.0
**Data:** 2025-12-14
**Status:** 🎯 Pronto para implementar
