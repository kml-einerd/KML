### 1. Bloco "Top Movers" (Quem está mexendo o mercado?)
*A ideia aqui é ver quem são os "tubarões" famintos (compradores) e quem está fugindo (vendedores).*

**Como exibir na tela (UI Sugerida):**
Divida a tela em duas colunas: **🟢 Top Compradores** e **🔴 Top Vendedores**.

*   **O Card do Fundo:**
    *   **Nome:** "Alaska Black Fia..."
    *   **Movimento Líquido:** "Comprou R$ 150 Milhões em ações este mês".
    *   **Botão "Ver Detalhes" (Expandir):** Ao clicar, mostra as 3 principais ações que compuseram esse movimento.
        *   *Exemplo:* 🔼 60% VALE3 | 🔼 20% PETR4 | 🔽 Vendeu PRIO3.

**Por que o público gosta:**
Humaniza o mercado. O usuário pensa: *"O Fundo Verde está comprando muito, o mercado deve subir"* ou *"A Dynamo está vendendo tudo, melhor eu ficar esperto"*.

---

### 2. Bloco "Fresh Bets" (As Novas Apostas - O seu "Gold Mine")
*Aqui está o valor premium. Ativos que saíram do zero para a carteira.*

**Conceito:** "Novas Entradas".
Identificar ativos onde `Quantidade Mês Anterior == 0` e `Quantidade Mês Atual > 0`.

**Como exibir na tela:**
Uma lista ranqueada por **"Consenso Institucional"**.

*   **Ranking:**
    1.  **Ação:** INTB3 (Intelbras)
        *   **O Sinal:** "5 Grandes Fundos adicionaram este ativo pela 1ª vez este mês".
        *   **Quem entrou:** Opportunity, Atmos, Leblon.
        *   **Volume Total:** R$ 45 Milhões alocados.
    2.  **Ação:** SMTO3 (São Martinho)
        *   **O Sinal:** "3 Grandes Fundos adicionaram...".

**Insight para o usuário:**
*"Esses gestores não combinaram entre si, mas todos decidiram comprar Intelbras agora. Eles devem saber algo que eu não sei."* Isso gera um senso de urgência e curiosidade muito forte.

### 💎 Bloco 3: Novas Descobertas (Radar de Entradas)

**Objetivo:** Mostrar ativos que **entraram** nos balancetes este mês (não existiam na carteira no mês anterior).

#### 1. A Visualização Principal: "O Consenso das Novidades"
Em vez de uma lista alfabética chata, mostre um ranking baseado em **popularidade institucional**.

*   **Título:** "As Queridinhas do Mês" (Ativos que entraram em múltiplas carteiras simultaneamente).

**Exemplo de Card:**
> **🚀 INTB3 (Intelbras)**
> *   **Investidor:** Os fundos entraram.
> *   **Volume Total:** R$ 45 Milhões.
> *   **Quem entrou:** Opportunity, Leblon, Trígono.
> *   **Destaque:** *"Entrada agressiva do Opportunity (3% do PL)"*.

**Por que é bom:** O usuário vê que não foi um movimento isolado. Se gestoras diferentes decidiram comprar Intelbras no mesmo mês, existe um consenso forte de oportunidade.

### 🎨 Resumo da Estrutura do Dashboard (MVP)

Imagino a "Home" do seu SaaS assim:

**Cabeçalho:** "Radar Institucional - Outubro/2025"

**Seção 1: O Que Está Quente (Sua ideia inicial)**
*   🔥 Ações Mais Compradas (Geral)
*   🧊 Ações Mais Vendidas (Geral)

**Seção 2: Quem Está Se Movendo (Top Movers)**
*   💰 **Ranking dos Fundos:** Lista dos 5 fundos que mais injetaram dinheiro no mercado (com breakdown das ações).

**Seção 3: O Tesouro Escondido (Fresh Bets)**
*   💎 **Novas Descobertas:** "Ações que acabaram de entrar na carteira dos gigantes."
    *   *Card:* **NOME DA AÇÃO**
    *   *Subtexto:* "Adicionada recentemente por [Fundo A] e [Fundo B]."