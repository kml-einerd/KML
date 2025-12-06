# 🎨 Design da Interface - MVP Radar Institucional

Especificações visuais, layout e experiência do usuário para o dashboard MVP.

---

## 📐 Princípios de Design

### 1. Página Única (Single Page Application)
- Todo conteúdo visível com scroll
- Sem navegação complexa
- Elementos expansíveis para drill-down

### 2. Mobile-First
- Responsivo desde o design
- Cards empilhados em mobile
- Touch-friendly (botões grandes)

### 3. Hierarquia Visual Clara
- Headers grandes e coloridos
- Métricas em destaque (números grandes)
- Detalhes secundários menores

### 4. Feedback Imediato
- Loading states visíveis
- Animações sutis (expandir/colapsar)
- Estados hover/active claros

---

## 📱 Layout Responsivo

### Desktop (>1024px)

```
┌────────────────────────────────────────┐
│  HEADER (Logo + Seletor de mês)        │
├────────────────────────────────────────┤
│                                        │
│  ┌───────────┐    ┌───────────┐      │
│  │  TOP      │    │  TOP      │      │
│  │  COMPRA-  │    │  VENDE-   │      │
│  │  DORES    │    │  DORES    │      │
│  └───────────┘    └───────────┘      │
│                                        │
│  ┌──────────────────────────────┐    │
│  │  FRESH BETS (Lista)          │    │
│  └──────────────────────────────┘    │
│                                        │
│  ┌──────────────────────────────┐    │
│  │  ATIVOS POPULARES (Gráfico)  │    │
│  └──────────────────────────────┘    │
│                                        │
└────────────────────────────────────────┘
```

### Tablet (768-1024px)

```
┌──────────────────────┐
│  HEADER              │
├──────────────────────┤
│  ┌────────────────┐ │
│  │ TOP COMPRADORES│ │
│  └────────────────┘ │
│                      │
│  ┌────────────────┐ │
│  │ TOP VENDEDORES │ │
│  └────────────────┘ │
│                      │
│  ┌────────────────┐ │
│  │ FRESH BETS     │ │
│  └────────────────┘ │
│                      │
│  ┌────────────────┐ │
│  │ ATIVOS POPULARES│ │
│  └────────────────┘ │
└──────────────────────┘
```

### Mobile (<768px)

```
┌──────────────┐
│  HEADER      │
│  (compacto)  │
├──────────────┤
│              │
│  [Card 1]    │
│  [Card 2]    │
│  [Card 3]    │
│  ...         │
│              │
│ (scroll vert)│
└──────────────┘
```

---

## 🧩 Componentes Principais

### Header

```
┌──────────────────────────────────────────┐
│  🎯 RADAR INSTITUCIONAL                   │
│                                           │
│  ┌───────┐ ┌───────┐ ┌───────┐          │
│  │  Set  │ │  Out ✓│ │  Nov  │  ← Tabs │
│  └───────┘ └───────┘ └───────┘          │
└──────────────────────────────────────────┘
```


### Card de Fundo (Top Movers)

```
┌────────────────────────────────┐
│  🏦  Alaska Black FIA           │
│      Alaska Asset Management   │
│                                 │
│  💰 R$ 420 milhões              │ ← Valor grande
│  ▲ Fluxo líquido positivo       │
│                                 │
│  ┌──────────────────────────┐  │
│  │   Ver detalhes ▼          │  │ ← Expandível
│  └──────────────────────────┘  │
└────────────────────────────────┘

(Expandido)
┌────────────────────────────────┐
│  🏦  Alaska Black FIA           │
│  ...                            │
│                                 │
│  📊 Top Compras:                │
│  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━│
│  • VALE3    R$ 270M  (60%)     │
│  • PETR4    R$ 112M  (25%)     │
│  • ITUB4    R$  45M  (10%)     │
│                                 │
│  ┌──────────────────────────┐  │
│  │   Fechar ▲                │  │
│  └──────────────────────────┘  │
└────────────────────────────────┘
```

**Especificações:**
- Borda: 1px solid #E5E7EB
- Border-radius: 12px
- Padding: 24px
- Box-shadow: 0 1px 3px rgba(0,0,0,0.1)
- Hover: shadow mais forte
- Transição de expansão: 200ms ease

**Streamlit:**
```python
with st.expander(f"🏦 {fundo['nome_fundo']}", expanded=False):
    st.metric("Fluxo Líquido", f"R$ {fundo['fluxo_liquido']:,.0f}")
    # Detalhes...
```

---

### Badge de Consenso (Fresh Bets)

```
┌────────────────────────────────┐
│  🚀  INTB3 - Intelbras          │
│                                 │
│  ⭐ 5 grandes fundos entraram   │ ← Badge
│  💰 R$ 45 milhões alocados      │
│                                 │
│  📋 Quem entrou:                │
│  • Opportunity FIA  (3% do PL) │
│  • Leblon Ações     (2% do PL) │
│  • Atmos Capital  (1.5% do PL) │
│                                 │
└────────────────────────────────┘
```

**Badge de Consenso:**
- Background: --purple-accent com 10% opacidade
- Border: 1px solid --purple-accent
- Padding: 4px 12px
- Border-radius: 16px (pill)
- Font-size: 14px, font-weight: 600

---

### Barra de Popularidade (Ativos Mais Populares)

```
┌────────────────────────────────┐
│  1. VALE3 │ ████████████  87   │
│  2. PETR4 │ ███████████   76   │
│  3. ITUB4 │ ██████████    65   │
│  4. BBDC4 │ █████████     58   │
└────────────────────────────────┘
```

**Especificações:**
- Barra: Progress bar com gradiente
- Cor: Verde se >média, cinza se <média
- Altura: 24px
- Transição: width 300ms ease
- Número à direita: font-weight 700

**Streamlit:**
```python
st.bar_chart(df_populares[['ticker', 'num_fundos']])
```

---

## 🎭 Estados e Interações

### Loading State

```
┌────────────────────────────────┐
│   ⏳  Carregando dados...       │
│   ▀▀▀▀▀▀▀▀░░░░░░  60%         │
└────────────────────────────────┘
```

**Spinner:**
- Animação de rotação
- Cor: --blue-neutral
- Texto: "Carregando dados...", "Processando...", etc.

**Streamlit:**
```python
with st.spinner("Carregando Top Movers..."):
    data = fetch_top_movers()
```

---

### Empty State

```
┌────────────────────────────────┐
│   📭                            │
│   Nenhum dado disponível        │
│   para este mês                 │
└────────────────────────────────┘
```

**Especificações:**
- Centralizado
- Ícone grande (48px)
- Texto secundário em --text-muted

---

### Hover (Desktop)

**Cards:**
- Transform: translateY(-2px)
- Box-shadow: 0 4px 12px rgba(0,0,0,0.15)
- Transição: 150ms ease

**Botões:**
- Background: Escurecer 10%
- Cursor: pointer
- Transição: 100ms ease

---

## 📊 Gráficos e Visualizações

### Recomendações

**Biblioteca:** Plotly (via Streamlit)

**Tipos de gráfico:**

1. **Top Movers:** Cards + métricas (não precisa de gráfico)
2. **Fresh Bets:** Lista com badges
3. **Ativos Populares:** Barra horizontal

**Configurações Plotly:**
```python
import plotly.express as px

fig = px.bar(
    df,
    x='num_fundos',
    y='ticker',
    orientation='h',
    color='num_fundos',
    color_continuous_scale='Greens'
)

fig.update_layout(
    showlegend=False,
    plot_bgcolor='rgba(0,0,0,0)',
    height=400
)

st.plotly_chart(fig, use_container_width=True)
```

---

## 🔤 Tipografia

### Fontes

**Primária:** Inter (sans-serif)
- Títulos: 700 (Bold)
- Corpo: 400 (Regular)
- Labels: 500 (Medium)

**Monospace:** JetBrains Mono (para valores)

### Hierarquia

```css
h1 { font-size: 32px; font-weight: 700; }
h2 { font-size: 24px; font-weight: 600; }
h3 { font-size: 18px; font-weight: 600; }
body { font-size: 16px; font-weight: 400; }
small { font-size: 14px; color: var(--text-secondary); }
```

---

## ♿ Acessibilidade

- ✅ Contraste mínimo 4.5:1 (WCAG AA)
- ✅ Foco visível em botões/links
- ✅ Labels descritivos
- ✅ Alt text em ícones
- ✅ Navegação por teclado

---

## 🚀 Animações

**Princípios:**
- Sutis e rápidas (<300ms)
- Easing natural (ease, ease-out)
- Reduzir em mobile (performance)

**Tipos:**
1. **Fade in:** Opacity 0→1 (200ms)
2. **Slide down:** Expandir (200ms ease-out)
3. **Hover lift:** translateY(-2px) (150ms)

---

## 📱 Breakpoints

```css
/* Mobile first */
@media (min-width: 640px) { /* sm */ }
@media (min-width: 768px) { /* md */ }
@media (min-width: 1024px) { /* lg - 2 colunas */ }
@media (min-width: 1280px) { /* xl */ }
```

---

## 🎯 Wireframe Completo (Desktop)

```
┌──────────────────────────────────────────────────────────┐
│  🎯 RADAR INSTITUCIONAL                                   │
│  Outubro/2025  ┌──────┐ ┌──────┐ ┌──────┐               │
│                │  Set │ │ Out ✓│ │  Nov │                │
│                └──────┘ └──────┘ └──────┘                │
├──────────────────────────────────────────────────────────┤
│                                                           │
│  💰 QUEM ESTÁ SE MOVENDO                                  │
│                                                           │
│  ┌─────────────────────────┐  ┌────────────────────────┐│
│  │ TOP COMPRADORES          │  │ TOP VENDEDORES         ││
│  │                          │  │                        ││
│  │ 🏦 Alaska Black FIA      │  │ 🏦 Dynamo Total FIM    ││
│  │    R$ 420M               │  │    R$ -380M            ││
│  │    [Ver detalhes ▼]      │  │    [Ver detalhes ▼]    ││
│  │                          │  │                        ││
│  │ 🏦 Opportunity Equity    │  │ 🏦 Verde Asset         ││
│  │    R$ 350M               │  │    R$ -310M            ││
│  │    [Ver detalhes ▼]      │  │    [Ver detalhes ▼]    ││
│  │                          │  │                        ││
│  │ ...                      │  │ ...                    ││
│  └─────────────────────────┘  └────────────────────────┘│
│                                                           │
├──────────────────────────────────────────────────────────┤
│                                                           │
│  💎 NOVAS APOSTAS (Fresh Bets)                            │
│                                                           │
│  ┌───────────────────────────────────────────────────┐  │
│  │  #1  🚀 INTB3 (Intelbras)                         │  │
│  │      ⭐ 5 grandes fundos entraram                  │  │
│  │      💰 R$ 45 milhões                             │  │
│  │      📋 [Ver quem entrou ▼]                       │  │
│  │                                                    │  │
│  │  #2  🚀 SMTO3 (São Martinho)                      │  │
│  │      ⭐ 3 grandes fundos entraram                  │  │
│  │      💰 R$ 28 milhões                             │  │
│  │                                                    │  │
│  │  ...                                               │  │
│  └───────────────────────────────────────────────────┘  │
│                                                           │
├──────────────────────────────────────────────────────────┤
│                                                           │
│  🏆 ATIVOS MAIS POPULARES                                 │
│                                                           │
│  ┌───────────────────────────────────────────────────┐  │
│  │  1. VALE3   │ ████████████  87 fundos            │  │
│  │  2. PETR4   │ ███████████   76 fundos            │  │
│  │  3. ITUB4   │ ██████████    65 fundos            │  │
│  │  4. BBDC4   │ █████████     58 fundos            │  │
│  │  5. BBAS3   │ ████████      52 fundos            │  │
│  │  ...                                               │  │
│  └───────────────────────────────────────────────────┘  │
│                                                           │
└──────────────────────────────────────────────────────────┘
```

---

**Fim do Design da Interface**


