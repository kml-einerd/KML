# 📊 Dashboards Disponíveis

Você tem **2 versões** do dashboard. Escolha a que melhor se encaixa no seu uso:

---

## 📱 DASHBOARD SIMPLES (RECOMENDADO)

**Arquivo:** `dashboard_fundos_simples.html`

### ✅ Características:
- 📱 **Mobile-first** - Perfeito para celular
- 🎯 **Tela única** - Tudo em uma página, sem abas
- ⚡ **Ultra simples** - Só o essencial
- 🚀 **Carrega rápido** - Sem gráficos pesados
- 💡 **Insights claros** - Direto ao ponto

### 📊 O que mostra:
1. **Seletor de Mês Dinâmico**
   - Todos os meses disponíveis no banco
   - Troca instantânea entre períodos

2. **4 Cards de Estatísticas**
   - Qtd ações em compra
   - Qtd ações em venda
   - Ações com consenso >80%
   - Volume total (bilhões)

3. **Top 10 Compra Forte** 🟢
   - Ações com consenso >80% de compra
   - Volume em milhões
   - % de consenso

4. **Top 10 Venda Forte** 🔴
   - Ações com consenso >80% de venda
   - Volume em milhões
   - % de consenso

5. **Top 5 Maiores Movimentações** 📊
   - Ações com maior volume total negociado
   - Soma de compra + venda

6. **Top 5 Grupos Mais Ativos** 🏢
   - Gestores que mais movimentaram capital
   - Volume em bilhões

7. **Top 5 Ações Mais Populares** ⭐
   - Ações em mais carteiras
   - Quantos fundos possuem cada ação

8. **Top 5 Compradores** 🏆
   - Maiores compradores de cada ação
   - Grupo + valor comprado

9. **Top 5 Vendedores** 📉
   - Maiores vendedores de cada ação
   - Grupo + valor vendido

10. **Top 5 Maiores Posições** 💎
    - Ações com maior valor em carteira
    - Valor total de mercado

11. **Dica de Uso Completa**
    - Explicação de cada bloco

### 🚀 Como abrir:
```bash
cd /Users/kemueldemelleopoldino/Desktop/DEV_KML/GITHUB/KML-1/app_ab
./scripts/abrir_dashboard_simples.sh
```

### 👤 Para quem:
✅ Investidor pessoa física
✅ Quem quer rapidez
✅ Uso no celular
✅ Decisões práticas
✅ Menos é mais

---

## 📊 DASHBOARD COMPLETO

**Arquivo:** `dashboard_fundos.html`

### ✅ Características:
- 💻 **Desktop-first** - Melhor em tela grande
- 📑 **5 abas** - Muitas análises
- 📈 **6 gráficos** - Visualizações detalhadas
- 🔍 **Análise profunda** - Dados completos
- 🎓 **Muitas features** - Para analistas

### 📊 O que mostra:
- Aba Sinais (compra/venda)
- Aba Momentum (tendências)
- Aba Grandes Gestores (portfolios)
- Aba Descoberta (hidden gems)
- Aba Panorama (visão geral)

### 🚀 Como abrir:
```bash
cd /Users/kemueldemelleopoldino/Desktop/DEV_KML/GITHUB/KML-1/app_ab
./scripts/abrir_dashboard_fundos.sh
```

### 👤 Para quem:
✅ Analistas
✅ Quem quer explorar
✅ Uso em desktop
✅ Análises complexas
✅ Mais informação

---

## 🎯 QUAL USAR?

### Use SIMPLES se você quer:
- ✅ Ver rapidinho no celular
- ✅ Só saber compra/venda forte
- ✅ Decisão rápida
- ✅ Menos complexidade

### Use COMPLETO se você quer:
- ✅ Análise profunda
- ✅ Ver gráficos
- ✅ Explorar tendências
- ✅ Ver portfolios de grupos

---

## 📱 COMPARAÇÃO LADO A LADO

| Característica | SIMPLES | COMPLETO |
|----------------|---------|----------|
| **Telas** | 1 única | 5 abas |
| **Tabelas** | 8 (compactas) | 8 (top 20) |
| **Gráficos** | 0 | 6 |
| **Cards Stats** | 4 | 4 |
| **Blocos Info** | 10 blocos | 5 abas |
| **Seletor Meses** | ✅ Dinâmico | ✅ Dinâmico |
| **Tamanho** | ~15KB | 31KB |
| **Mobile** | ⭐⭐⭐⭐⭐ | ⭐⭐⭐ |
| **Desktop** | ⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ |
| **Rapidez** | ⚡⚡⚡⚡⚡ | ⚡⚡⚡ |
| **Profundidade** | ⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ |

---

## 🎨 PREVIEW

### Dashboard SIMPLES:
```
┌─────────────────────────┐
│  💰 Fundos Top 100     │
│  O que os grandes...   │
└─────────────────────────┘

┌─────────────────────────┐
│  [Novembro 2024    ▼]  │  ← Todos os meses
└─────────────────────────┘

┌──────┬──────┬──────┬──────┐
│ 324  │ 189  │  87  │ 45.3 │
│Compra│Venda │Cons+ │Volume│
└──────┴──────┴──────┴──────┘

🟢 COMPRA FORTE (Top 10)
┌──────────────────────────┐
│ 1  PETR4    R$234M  92% │
│ 2  VALE3    R$189M  89% │
│ 3  BBAS3    R$156M  87% │
│    ...                   │
└──────────────────────────┘

🔴 VENDA FORTE (Top 10)
┌──────────────────────────┐
│ 1  MGLU3    R$123M  91% │
│ 2  VVAR3    R$98M   88% │
│    ...                   │
└──────────────────────────┘

📊 MAIORES MOVIMENTAÇÕES (Top 5)
┌──────────────────────────┐
│ 1  PETR4    R$456M vol. │
│ 2  VALE3    R$389M vol. │
│    ...                   │
└──────────────────────────┘

🏢 GRUPOS MAIS ATIVOS (Top 5)
┌──────────────────────────┐
│ 1  Bradesco  R$12.5B    │
│ 2  Itaú      R$11.8B    │
│    ...                   │
└──────────────────────────┘

⭐ AÇÕES MAIS POPULARES (Top 5)
┌──────────────────────────┐
│ 1  PETR4    92 fundos   │
│ 2  VALE3    87 fundos   │
│    ...                   │
└──────────────────────────┘

🏆 TOP COMPRADORES (Top 5)
📉 TOP VENDEDORES (Top 5)
💎 MAIORES POSIÇÕES (Top 5)

💡 Como usar
[Dicas completas de interpretação]
```

### Dashboard COMPLETO:
```
┌─────────────────────────────────┐
│  📊 Dashboard Fundos Top 100   │
└─────────────────────────────────┘

[Sinais][Momentum][Grandes][...]

📊 Gráficos | 📋 Tabelas | 🔍 Filtros
```

---

## 🚀 RECOMENDAÇÃO

**Para 90% dos casos: Use o SIMPLES**

É mais prático, rápido e focado no que importa:
- ✅ O que comprar (consenso >80%)
- ✅ O que evitar (consenso >80%)

**Use o COMPLETO apenas se:**
- Você quer ver tendências ao longo do tempo
- Quer analisar portfolio de grupos específicos
- Gosta de gráficos e visualizações
- Tem tempo para explorar

---

## 📞 AMBOS FUNCIONAM:

- ✅ Mesmas credenciais Supabase
- ✅ Mesmos dados
- ✅ Mesmo banco de dados
- ✅ Atualizados mensalmente

**A diferença é só na apresentação!**

---

**💡 Dica:** Abra ambos e veja qual prefere!
