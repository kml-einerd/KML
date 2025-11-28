# 📈 Ações Baratas da Bolsa - Frontend

Sistema MicroSaaS de classe mundial para descobrir ações subvalorizadas na bolsa brasileira (B3).

## 🎨 Design & Arquitetura

Este projeto foi desenvolvido seguindo os mais altos padrões de qualidade em UI/UX, inspirado em:

- **Bloomberg Terminal** - Densidade de informação organizada
- **Robinhood** - Simplicidade e clareza visual
- **TradingView** - Gráficos interativos poderosos

### Stack Tecnológica

- **Next.js 14** - Framework React com App Router
- **TypeScript** - Type safety em todo o código
- **Tailwind CSS** - Utility-first CSS framework
- **Shadcn/UI** - Componentes UI de alta qualidade
- **Recharts** - Biblioteca de gráficos profissional
- **Framer Motion** - Animações suaves
- **Radix UI** - Componentes acessíveis

## 🚀 Como Executar

### Pré-requisitos

- Node.js 18+
- npm ou yarn

### Instalação

```bash
# Clone o repositório
cd acoes-baratas-frontend

# Instale as dependências
npm install

# Execute o servidor de desenvolvimento
npm run dev
```

Abra [http://localhost:3000](http://localhost:3000) no seu navegador.

## 📁 Estrutura do Projeto

```
acoes-baratas-frontend/
├── app/                      # Next.js App Router
│   ├── layout.tsx           # Layout principal
│   ├── page.tsx             # Página principal (Dashboard)
│   └── globals.css          # Estilos globais
├── components/              # Componentes React
│   ├── ui/                  # Componentes base (Shadcn)
│   │   ├── button.tsx
│   │   ├── card.tsx
│   │   ├── badge.tsx
│   │   └── input.tsx
│   ├── Header.tsx           # Cabeçalho da aplicação
│   ├── MarketStats.tsx      # Estatísticas do mercado
│   ├── StockCard.tsx        # Card de ação individual
│   ├── StockTable.tsx       # Tabela de ações
│   └── PriceChart.tsx       # Gráfico de preços
├── lib/                     # Utilitários e dados
│   ├── utils.ts             # Funções utilitárias
│   └── mockData.ts          # Dados mockados para desenvolvimento
├── package.json
├── tsconfig.json
├── tailwind.config.ts
└── next.config.js
```

## 🎯 Features Implementadas

### Dashboard Principal
- ✅ Visão geral do mercado com estatísticas
- ✅ Lista de ações subvalorizadas
- ✅ Filtros inteligentes (P/L, Dividend Yield, Market Cap, Setor)
- ✅ Alternância entre visualização em grid e tabela
- ✅ Ordenação por múltiplos critérios

### Detalhes de Ação
- ✅ Informações completas de preço
- ✅ Gráfico histórico de 90 dias
- ✅ Métricas de valuation (P/L, P/VP, PEG, etc.)
- ✅ Indicadores de rentabilidade (ROE, ROA, margens)
- ✅ Análise de solidez financeira
- ✅ Histórico de dividendos
- ✅ Notícias recentes
- ✅ Recomendações de analistas

### UI/UX Features
- ✅ Design responsivo (mobile-first)
- ✅ Tema claro/escuro (preparado)
- ✅ Animações suaves
- ✅ Loading states
- ✅ Hover effects profissionais
- ✅ Tipografia premium (Inter + JetBrains Mono)
- ✅ Scrollbar customizada
- ✅ Cores semânticas (success/danger para variações)

## 🔄 Próximos Passos (Integração com Backend)

Quando o backend estiver pronto, substitua os dados em `lib/mockData.ts` por chamadas à API:

```typescript
// Exemplo de integração futura
const response = await fetch('/api/stocks/screener?maxPE=10&minDividend=5')
const stocks = await response.json()
```

## 🎨 Design System

### Cores

- **Primary**: Blue (#3b82f6) - Ações principais
- **Success**: Green (#22c55e) - Variações positivas, dividendos
- **Danger**: Red (#ef4444) - Variações negativas
- **Muted**: Gray - Informações secundárias

### Tipografia

- **Headings**: Inter (Variable font)
- **Body**: Inter (Variable font)
- **Monospace**: JetBrains Mono (para números e códigos)

### Espaçamento

Seguindo escala do Tailwind:
- 4px (1), 8px (2), 12px (3), 16px (4), 24px (6), 32px (8)

## 📊 Dados Mockados

O projeto inclui dados realistas mockados para 12 ações brasileiras:

- VALE3, PETR4, ITUB4, BBDC4, BBAS3 (Blue chips)
- CMIG4, CPLE6, ELET3 (Energia)
- USIM5, CSNA3 (Siderurgia)
- CYRE3, MRFG3 (Outros setores)

Todos com dados de:
- Preços e variações
- Métricas fundamentalistas
- Histórico de 180 dias
- Dividendos e notícias

## 🛠️ Build para Produção

```bash
npm run build
npm start
```

## 📝 Licença

Projeto proprietário - Ações Baratas © 2024
