# Backend Ações Baratas B3

Backend completo em FastAPI para análise e consulta de ações baratas da Bolsa brasileira (B3).

## 📋 Visão Geral

Este backend fornece uma API REST para:
- Consultar ações da B3 com preço abaixo de R$ 101,00
- Obter informações detalhadas de qualquer ação
- Acessar dados de fundamentos, cotações e histórico de preços
- Calcular scores de valuation, qualidade e momento

Os dados são coletados automaticamente do Yahoo Finance (yfinance) e armazenados no Supabase (PostgreSQL).

## 🏗️ Arquitetura

```
backend-acoes-baratas/
├── app/
│   ├── main.py                 # Aplicação FastAPI principal
│   ├── config.py               # Configurações e variáveis de ambiente
│   ├── supabase_client.py      # Cliente Supabase
│   ├── models/
│   │   └── schemas.py          # Schemas Pydantic
│   ├── services/
│   │   ├── acoes_service.py    # Serviço de ações
│   │   ├── cotacoes_service.py # Serviço de cotações
│   │   ├── precos_service.py   # Serviço de preços
│   │   ├── fundamentos_service.py  # Serviço de fundamentos
│   │   └── sync_yfinance.py    # Sincronização com Yahoo Finance
│   └── jobs/
│       ├── atualizar_universo_acoes.py     # Job: universo de ações
│       ├── atualizar_fundamentos.py        # Job: fundamentos
│       ├── atualizar_precos_diarios.py     # Job: preços diários
│       └── atualizar_cotacoes_snapshot.py  # Job: cotações tempo real
├── requirements.txt
├── .env.example
└── README.md
```

## 🚀 Como Rodar Localmente

### Pré-requisitos

- Python 3.11+
- Conta no Supabase com as tabelas criadas
- Git

### 1. Clonar o Repositório

```bash
git clone https://github.com/kml-einerd/KML.git
cd KML/backend-acoes-baratas
```

### 2. Criar Ambiente Virtual

```bash
python -m venv venv

# Linux/Mac
source venv/bin/activate

# Windows
venv\Scripts\activate
```

### 3. Instalar Dependências

```bash
pip install --upgrade pip
pip install -r requirements.txt
```

### 4. Configurar Variáveis de Ambiente

Copie o arquivo `.env.example` para `.env`:

```bash
cp .env.example .env
```

Edite o arquivo `.env` e adicione suas credenciais do Supabase:

```env
# Configurações do Supabase
SUPABASE_URL=https://seu-projeto.supabase.co
SUPABASE_SERVICE_KEY=sua-chave-service-role-aqui

# Configurações da API
API_HOST=0.0.0.0
API_PORT=8000
API_RELOAD=true

# Ambiente
ENVIRONMENT=development
```

**⚠️ IMPORTANTE:** Nunca commite o arquivo `.env` no Git! Ele está no `.gitignore`.

### 5. Executar a API

```bash
# Opção 1: Usando Python diretamente
python -m app.main

# Opção 2: Usando Uvicorn
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

A API estará disponível em: `http://localhost:8000`

- **Documentação interativa (Swagger):** `http://localhost:8000/docs`
- **Documentação alternativa (ReDoc):** `http://localhost:8000/redoc`

## 📡 Endpoints da API

### 1. Health Check

```http
GET /health
```

**Resposta:**
```json
{
  "status": "ok",
  "timestamp": "2025-11-28T10:30:00.000Z",
  "versao": "1.0.0"
}
```

### 2. Listar Ações Baratas

```http
GET /acoes/baratas?preco_maximo=101
```

**Parâmetros:**
- `preco_maximo` (opcional): Preço máximo em reais (default: 101.0)

**Resposta:**
```json
[
  {
    "ticker": "PETR4.SA",
    "codigo_b3": "PETR4",
    "nome_curto": "PETROBRAS PN",
    "setor": "Energy",
    "preco_ultimo": 38.50,
    "variacao_dia_percentual": 2.15,
    "valor_mercado": 501234567890,
    "score_geral": 75.5,
    "score_valuation": 80.2,
    "score_qualidade": 70.1,
    "score_momento": 76.2
  }
]
```

### 3. Detalhes de uma Ação

```http
GET /acoes/{ticker}?periodo=1m
```

**Parâmetros:**
- `ticker` (obrigatório): Código do ticker (ex: PETR4.SA)
- `periodo` (opcional): Período para histórico (`7d`, `15d`, `1m`, `3m`, `6m`, `1a`, `3a`, `5a`)

**Resposta:**
```json
{
  "empresa": {
    "ticker": "PETR4.SA",
    "codigo_b3": "PETR4",
    "nome_curto": "PETROBRAS PN",
    "setor": "Energy",
    ...
  },
  "cotacao_atual": {
    "preco_ultimo": 38.50,
    "variacao_dia_percentual": 2.15,
    ...
  },
  "fundamentos": {
    "pl_trailing": 5.2,
    "dividend_yield": 0.08,
    "score_geral": 75.5,
    ...
  },
  "historico_precos": [...],
  "metricas": {
    "retorno_periodo": 15.5,
    "volatilidade": 2.3,
    "maxima_periodo": 42.0,
    "minima_periodo": 35.0
  }
}
```

## ⚙️ Jobs de Sincronização

Os jobs podem ser executados manualmente para popular o banco de dados:

### 1. Atualizar Universo de Ações (Semanal)

Busca e atualiza a lista de ações da B3.

```bash
python -m app.jobs.atualizar_universo_acoes
```

### 2. Atualizar Fundamentos (Semanal)

Atualiza fundamentos e calcula scores de todas as ações.

```bash
python -m app.jobs.atualizar_fundamentos
```

### 3. Atualizar Preços Diários (Diário)

Atualiza o histórico de preços diários.

```bash
python -m app.jobs.atualizar_precos_diarios
```

### 4. Atualizar Cotações Snapshot (A cada 5 minutos)

Atualiza as cotações em tempo real.

```bash
python -m app.jobs.atualizar_cotacoes_snapshot
```

## 🤖 GitHub Actions - Automação

O workflow `.github/workflows/sync_acoes_baratas.yml` automatiza a coleta de dados:

### Frequências de Execução

| Job | Frequência | Horário (UTC) | Descrição |
|-----|-----------|---------------|-----------|
| Universo de Ações | Semanal | Domingo 02:00 | Atualiza lista de ações |
| Fundamentos | Semanal | Domingo 02:00 | Atualiza fundamentos e scores |
| Preços Diários | Diário | Todo dia 03:00 | Atualiza histórico diário |
| Cotações | A cada 5 min | Seg-Sex 10:00-17:00 | Atualiza preços em tempo real |

### Configurar Secrets no GitHub

1. Acesse o repositório no GitHub
2. Vá em **Settings** → **Secrets and variables** → **Actions**
3. Clique em **New repository secret**
4. Adicione os seguintes secrets:

| Nome | Descrição |
|------|-----------|
| `SUPABASE_URL` | URL do seu projeto Supabase (ex: https://xxx.supabase.co) |
| `SUPABASE_SERVICE_KEY` | Service Role Key do Supabase |

**⚠️ IMPORTANTE:** Use sempre a `service_role` key, não a `anon` key!

### Executar Manualmente

Você pode executar o workflow manualmente:

1. Vá em **Actions** no GitHub
2. Selecione "Sincronização Ações Baratas B3"
3. Clique em **Run workflow**

## 🗄️ Estrutura do Banco de Dados

O backend espera que as seguintes tabelas existam no Supabase:

- `acoes`: Informações das empresas
- `cotacoes_snapshot`: Snapshots de cotações
- `precos_diarios`: Histórico de preços
- `fundamentos_snapshot`: Fundamentos e scores
- `dividendos`: Dividendos pagos
- `desdobramentos`: Desdobramentos de ações

**Nota:** As tabelas já devem estar criadas no Supabase. Este backend apenas insere/atualiza dados.

## 📊 Cálculo de Scores

O sistema calcula 4 scores (0-100) para cada ação:

### Score de Valuation
- P/L baixo = score alto
- P/VP baixo = score alto
- Dividend Yield alto = score alto

### Score de Qualidade
- ROE alto = score alto
- Margem líquida alta = score alta
- Liquidez corrente adequada = score alto

### Score de Momento
- Crescimento de receita = score alto
- Crescimento de lucro = score alto

### Score Geral
Média dos três scores acima.

## 🛠️ Tecnologias Utilizadas

- **FastAPI**: Framework web moderno e rápido
- **yfinance**: Coleta de dados do Yahoo Finance
- **Supabase (supabase-py)**: Cliente Python para Supabase/PostgreSQL
- **Pydantic**: Validação de dados
- **Uvicorn**: Servidor ASGI
- **GitHub Actions**: Automação de jobs

## 📝 Desenvolvimento

### Estrutura de Código

- **Código em português**: Funções, variáveis e comentários em português
- **snake_case**: Padrão para nomes de funções e variáveis
- **Type hints**: Uso extensivo de anotações de tipo
- **Docstrings**: Documentação em todas as funções

### Adicionar Novos Tickers

Edite o arquivo `app/services/sync_yfinance.py` na função `obter_tickers_b3()` e adicione novos tickers à lista.

## 🤝 Contribuindo

1. Faça um fork do projeto
2. Crie uma branch para sua feature (`git checkout -b feature/nova-funcionalidade`)
3. Commit suas mudanças (`git commit -m 'Adiciona nova funcionalidade'`)
4. Push para a branch (`git push origin feature/nova-funcionalidade`)
5. Abra um Pull Request

## 📄 Licença

Este projeto é de código aberto. Sinta-se livre para usar e modificar.

## 🆘 Suporte

Para dúvidas ou problemas:
- Abra uma issue no GitHub
- Consulte a documentação da API em `/docs`

## 🎯 Roadmap

- [ ] Adicionar cache Redis para melhorar performance
- [ ] Implementar rate limiting
- [ ] Adicionar testes automatizados
- [ ] Criar dashboard de monitoramento
- [ ] Expandir lista de tickers automaticamente
- [ ] Adicionar alertas de oportunidades

---

**Desenvolvido com ❤️ para análise de ações da B3**
