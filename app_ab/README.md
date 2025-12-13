# App AB - Análise de Ações B3

Sistema de visualização de ações brasileiras com widgets TradingView e coleta automatizada de dados.

## O que é

Aplicação web para monitorar ações da B3 com:
- Widgets TradingView em tempo real
- 4 páginas com diferentes visualizações
- Scraper Node.js para coleta de dados
- Carteiras customizáveis via JSON

## Início Rápido

### Iniciar o servidor

```bash
bash iniciar_servidor.sh
```

Ou manualmente:
```bash
python3 -m http.server 8001
```

### Acessar as páginas

- **Carteiras:** http://localhost:8001/pages/carteiras.html
- **Dashboard:** http://localhost:8001/pages/index.html
- **Grade:** http://localhost:8001/pages/home.html
- **Teste:** http://localhost:8001/pages/test_widget.html

### Scripts disponíveis

```bash
bash scripts/abrir_carteiras.sh      # Inicia servidor e abre carteiras
bash scripts/iniciar_scraper.sh      # Coleta dados a cada 10 segundos
```

## Estrutura do Projeto

```
app_ab/
├── pages/          → Páginas HTML (index, home, carteiras, test_widget)
├── assets/         → CSS, JavaScript, imagens
├── data/           → JSONs com dados das carteiras
├── scripts/        → Automação (scraper.js + shell scripts)
└── iniciar_servidor.sh
```

## Editar Carteiras

1. Edite os arquivos JSON em `data/`:
   - `fonte_acoes_1.json`
   - `fonte_acoes_2.json`

2. Formato:
```json
[
  {
    "id": 1,
    "ticket": "VAMO3",
    "empresa": "Grupo Vamos",
    "setor": "Logística/Aluguel de Caminhões."
  }
]
```

3. Recarregue a página (Ctrl+R ou Cmd+R)

## Scraper

O scraper usa Puppeteer para capturar dados dos widgets e salvar em CSV.

**Primeira vez:**
```bash
cd scripts
npm install
```

**Executar:**
```bash
bash scripts/iniciar_scraper.sh
```

**Configuração:** `scripts/scraper.js` (linha 14)

## Comandos Úteis

```bash
# Parar servidor
pkill -f "python3 -m http.server"

# Verificar porta
lsof -i:8001

# Liberar porta
lsof -ti:8001 | xargs kill -9
```

## Solução de Problemas

**Widgets não carregam:**
- Use `http://localhost:8001` (não `file://`)
- Aguarde 5-10 segundos
- Veja console do navegador (F12)

**Scraper não conecta:**
- Verifique se o servidor está rodando: `lsof -i:8001`
- Instale as dependências: `cd scripts && npm install`

**Erro ao carregar JSON:**
- Verifique se os arquivos existem em `data/`
- Valide o JSON em jsonlint.com
- Confirme que o servidor está rodando

## Tecnologias

- HTML5, CSS3, JavaScript
- TradingView Widgets API
- Node.js + Puppeteer (scraper)
- Python 3 (servidor HTTP)
