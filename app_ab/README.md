# AB Widget - Dashboard de Ações B3

Aplicação web para análise de ações brasileiras usando widgets TradingView.

## 📊 Páginas Disponíveis

### 1. Home (Market Overview)
**Arquivo:** `home.html`

Exibe um widget TradingView Market Overview com 12 ações principais da B3:
- VALE3, PETR4, ITUB4, BBDC4, ABEV3, WEGE3
- RENT3, MGLU3, BBAS3, SUZB3, GGBR4, VIVT3

### 2. Dashboard (Análise Completa)
**Arquivo:** `index.html`

Dashboard completo com:
- 🔍 Busca de ações
- 📊 Symbol Info Widget
- 📈 Symbol Overview (gráfico interativo)
- 🏢 Company Profile
- 💰 Fundamental Data
- 📉 Technical Analysis
- 📰 News Timeline

## 🚀 Como Usar

### GitHub Pages
Acesse diretamente:
- Home: `https://kml-einerd.github.io/KML/app_ab/home.html`
- Dashboard: `https://kml-einerd.github.io/KML/app_ab/index.html`

### Local
1. Clone o repositório
2. Abra os arquivos HTML no navegador
3. Ou use um servidor HTTP local:
   ```bash
   python3 -m http.server 8000
   # Acesse: http://localhost:8000/app_ab/
   ```

## 📁 Estrutura

```
app_ab/
├── data.js          # Mock database com ações B3
├── favicon.svg      # Ícone da aplicação
├── home.html        # Página principal
├── home.css         # Estilos da home
├── home.js          # Lógica da home
├── index.html       # Dashboard completo
├── script.js        # Widgets TradingView
└── style.css        # Estilos do dashboard
```

## 🎯 Tecnologias

- HTML5
- CSS3 (Design minimalista)
- JavaScript (Vanilla)
- TradingView Widgets API
- Google News RSS

## 📝 Notas

- Dados mockados em `data.js`
- Preparado para integração com Supabase
- Design responsivo
- Lazy loading de widgets
