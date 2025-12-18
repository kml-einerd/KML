# 📊 Queries Úteis - Guia de Uso

Esta pasta contém queries SQL prontas para análise de fundos.

---

## 📁 ARQUIVOS DISPONÍVEIS

### 1. `consultas_frequentes.sql`
**📚 Queries Gerais e Técnicas**

**12 queries** para análises diversas:
- Top compras/vendas
- Consenso de mercado
- Movimentos de grupos
- Comparações
- Estatísticas gerais

**👤 Para quem:**
- Analistas técnicos
- Quem quer explorar os dados
- Análises ad-hoc

---

### 2. `dashboard_investidor.sql` ⭐ **RECOMENDADO**
**🎯 Dashboard Prático para Investidor Comum**

**20+ queries organizadas por categoria:**

#### 🎯 Sinais Claros (Mais Importante)
1. **Compra Forte** - Consenso >80% + Volume alto
2. **Venda Forte** - Evitar estas ações
3. **Oportunidades Médio Consenso** - Menos arriscadas

#### 📈 Tendências e Momentum
4. **Momentum** - Ações compradas consistentemente
5. **Reversões** - Mudanças de tendência
6. **Novas Apostas** - Entrando no radar

#### 🎓 Aprenda com os Grandes
7. **Copie o Líder** - Top 5 gestores
8. **Maiores Posições** - Onde há mais dinheiro
9. **Concentração** - Portfolio de um grupo

#### 🔍 Monitoramento Específico
10. **Radar de Ação** - Análise completa
11. **Evolução Temporal** - Histórico
12. **Comparar Ações** - Lado a lado

#### 💎 Descoberta de Oportunidades
13. **Hidden Gems** - Fora do radar
14. **Alta Popularidade** - Consenso amplo
15. **Alta Convicção** - Apostas concentradas

#### 📊 Visão Geral
16. **Painel Geral** - Snapshot do mercado
17. **Comparação Mensal** - Evolução

**👤 Para quem:**
- Investidor pessoa física
- Quem quer sinais claros
- Decisões de compra/venda

---

## 🚀 QUAL USAR?

### Use `dashboard_investidor.sql` se você quer:
✅ Sinais claros de compra/venda
✅ Queries organizadas por objetivo
✅ Explicações de como interpretar
✅ Foco em decisões práticas
✅ Guia de uso integrado

### Use `consultas_frequentes.sql` se você quer:
✅ Explorar os dados livremente
✅ Fazer análises customizadas
✅ Queries mais técnicas
✅ Estatísticas gerais

---

## 💡 WORKFLOW RECOMENDADO PARA INVESTIDOR

### 🔍 Passo 1: Contexto Geral (5 min)
```sql
-- Use query 6.1 de dashboard_investidor.sql
-- Veja o sentimento geral do mercado
```

### 🎯 Passo 2: Buscar Sinais (10 min)
```sql
-- Use queries 1.1 e 1.2 de dashboard_investidor.sql
-- Veja listas de compra forte e venda forte
```

### 📊 Passo 3: Validar com Momentum (5 min)
```sql
-- Use query 2.1 de dashboard_investidor.sql
-- Confirme se ações estão em tendência consistente
```

### 🔬 Passo 4: Análise Profunda (10 min)
```sql
-- Use query 4.1 de dashboard_investidor.sql
-- Analise cada ação que chamou atenção
```

### ✅ Passo 5: Decisão Final
- Compare com sua análise fundamentalista
- Verifique valuation
- Decida comprar/vender

**Tempo total:** ~30 minutos

---

## 📌 DICAS IMPORTANTES

### ⚠️ Parâmetros Ajustáveis
Procure por `⚠️` nos arquivos SQL:
```sql
WHERE mes_referencia = '2025-11-30'  -- ⚠️ ALTERE O MÊS
  AND ticker = 'PETR4'  -- ⚠️ ALTERE O TICKER
```

### 🎯 Níveis de Consenso
- **>90%** = Unanimidade (sinal MUITO forte)
- **80-90%** = Consenso forte
- **60-80%** = Consenso moderado
- **<60%** = Sem consenso claro

### 💰 Volumes Significativos
- **>1 bilhão** = Mega movimento
- **100M - 1bi** = Movimento forte
- **50M - 100M** = Movimento moderado
- **<50M** = Movimento pequeno

### 🔍 Como Combinar Queries
**Para COMPRAR uma ação:**
1. Está em "Compra Forte" (query 1.1)? ✅
2. Tem momentum positivo (query 2.1)? ✅
3. Grandes gestores comprando (query 3.1)? ✅
4. Posição significativa (query 3.2)? ✅
→ **Sinal FORTE de compra!**

**Para VENDER uma ação:**
1. Está em "Venda Forte" (query 1.2)? 🔴
2. Reversão de tendência (query 2.2)? 🔴
3. Grandes saindo (query 3.1)? 🔴
→ **Considere sair!**

---

## 🎓 EXEMPLOS PRÁTICOS

### Exemplo 1: Procurar ação para comprar
```sql
-- 1. Abra dashboard_investidor.sql
-- 2. Execute query 1.1 (Compra Forte)
-- 3. Veja lista de 15 ações com consenso >80%
-- 4. Escolha 3 que te interessam
-- 5. Para cada uma, execute query 4.1 (Radar)
-- 6. Decida com base em fundamentalista
```

### Exemplo 2: Verificar se devo sair de PETR4
```sql
-- 1. Execute query 4.2 com ticker='PETR4'
-- 2. Veja evolução nos últimos 4 meses
-- 3. Execute query 2.2 (Reversões)
-- 4. Veja se PETR4 virou venda
-- 5. Decida baseado no contexto
```

### Exemplo 3: Descobrir novas oportunidades
```sql
-- 1. Execute query 5.1 (Hidden Gems)
-- 2. Execute query 5.3 (Alta Convicção)
-- 3. Execute query 2.3 (Novas Apostas)
-- 4. Pesquise fundamentalista das que aparecerem
```

---

## ⚠️ AVISOS IMPORTANTES

### ❌ NÃO faça isso:
- ❌ Comprar baseado APENAS nas queries
- ❌ Ignorar análise fundamentalista
- ❌ Seguir cegamente os fundos
- ❌ Usar apenas 1 query isolada

### ✅ FAÇA isso:
- ✅ Use queries como FILTRO inicial
- ✅ Combine múltiplas queries
- ✅ Valide com fundamentalista
- ✅ Considere seu perfil de risco
- ✅ Diversifique

---

## 📞 PERGUNTAS FREQUENTES

**P: Qual arquivo devo usar primeiro?**
R: `dashboard_investidor.sql` - mais prático e organizado

**P: Como sei qual mês usar?**
R: Execute isto para ver meses disponíveis:
```sql
SELECT DISTINCT mes_referencia
FROM acoes_fundos
ORDER BY mes_referencia DESC;
```

**P: Posso confiar 100% nas queries?**
R: **NÃO!** Use como filtro, não como decisão final. Sempre faça sua análise.

**P: Como interpretar "consenso 85%"?**
R: 85% dos fundos que mexeram nesta ação estão comprando (ou vendendo)

**P: Preciso executar todas as queries?**
R: Não! Veja o "Workflow Recomendado" acima

---

## 🎯 PRÓXIMOS PASSOS

1. ✅ Abra `dashboard_investidor.sql`
2. ✅ Execute query 6.1 (Painel Geral) para contexto
3. ✅ Execute query 1.1 (Compra Forte) para ideias
4. ✅ Escolha 3 ações que te interessam
5. ✅ Analise cada uma com query 4.1 (Radar)
6. ✅ Faça análise fundamentalista
7. ✅ Decida!

---

**Boa sorte nos investimentos! 📈**

*Lembre-se: Este sistema mostra o que os grandes fundos fazem, mas eles podem estar errados. Sempre faça sua própria análise.*
