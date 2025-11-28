# 🔧 Documentação Completa do Backend - Ações Baratas da Bolsa

## 📋 Índice

1. [Visão Geral](#visão-geral)
2. [Arquitetura do Sistema](#arquitetura-do-sistema)
3. [Stack Tecnológica Recomendada](#stack-tecnológica-recomendada)
4. [Estrutura do Projeto](#estrutura-do-projeto)
5. [Recursos do yfinance e Implementação](#recursos-do-yfinance-e-implementação)
6. [APIs e Endpoints](#apis-e-endpoints)
7. [Models e Schemas](#models-e-schemas)
8. [Serviços e Business Logic](#serviços-e-business-logic)
9. [Cache e Performance](#cache-e-performance)
10. [Segurança e Autenticação](#segurança-e-autenticação)
11. [Deploy e Infraestrutura](#deploy-e-infraestrutura)
12. [Monitoramento e Logs](#monitoramento-e-logs)

---

## 🎯 Visão Geral

Sistema backend robusto e escalável para o microsaas "Ações Baratas da Bolsa", responsável por:

- **Coleta de dados** em tempo real da bolsa brasileira (B3) via yfinance
- **Análise fundamentalista** automática de ações
- **Screening e filtragem** de ações subvalorizadas
- **Cache inteligente** para performance máxima
- **API REST** para consumo do frontend
- **Sistema de alertas** e notificações
- **Gestão de usuários** e portfólios

---

## 🏗️ Arquitetura do Sistema

### Arquitetura em Camadas (Clean Architecture)

```
┌─────────────────────────────────────────────┐
│           Frontend (Next.js)                │
└─────────────────┬───────────────────────────┘
                  │ HTTP/REST
┌─────────────────▼───────────────────────────┐
│        API Layer (FastAPI/Express)          │
│  • Controllers                              │
│  • Request Validation                       │
│  • Response Formatting                      │
└─────────────────┬───────────────────────────┘
                  │
┌─────────────────▼───────────────────────────┐
│      Business Logic Layer (Services)        │
│  • Stock Service                            │
│  • Screener Service                         │
│  • Analysis Service                         │
│  • Alert Service                            │
└─────────────────┬───────────────────────────┘
                  │
┌─────────────────▼───────────────────────────┐
│       Data Access Layer (Repositories)      │
│  • Stock Repository                         │
│  • User Repository                          │
│  • Portfolio Repository                     │
└─────────────────┬───────────────────────────┘
                  │
┌─────────────────▼───────────────────────────┐
│          Data Sources                       │
│  • PostgreSQL (persistent data)             │
│  • Redis (cache)                            │
│  • yfinance API (market data)               │
└─────────────────────────────────────────────┘
```

### Componentes Principais

1. **API Gateway**: Ponto de entrada para todas as requisições
2. **Worker Jobs**: Processamento assíncrono de dados
3. **Cache Layer**: Redis para dados de alta frequência
4. **Database**: PostgreSQL para dados persistentes
5. **Message Queue**: Celery/Bull para jobs assíncronos

---

## 💻 Stack Tecnológica Recomendada

### Opção 1: Python Stack (Recomendada para yfinance)

```
Backend: FastAPI 0.104+
Database: PostgreSQL 15+
Cache: Redis 7+
Queue: Celery + Redis
ORM: SQLAlchemy 2.0+
Migration: Alembic
Validation: Pydantic V2
Testing: pytest
Container: Docker + Docker Compose
```

### Opção 2: Node.js Stack (Alternativa)

```
Backend: Express.js + TypeScript
Database: PostgreSQL 15+ (Prisma ORM)
Cache: Redis 7+
Queue: Bull
Validation: Zod
Testing: Jest
Container: Docker + Docker Compose
```

**Recomendação**: **Python Stack** por melhor integração com yfinance e bibliotecas de análise financeira (pandas, numpy).

---

## 📁 Estrutura do Projeto (Python/FastAPI)

```
acoes-baratas-backend/
├── app/
│   ├── __init__.py
│   ├── main.py                      # Entry point FastAPI
│   ├── config.py                    # Configurações
│   ├── dependencies.py              # Dependency injection
│   │
│   ├── api/                         # API Layer
│   │   ├── __init__.py
│   │   ├── v1/
│   │   │   ├── __init__.py
│   │   │   ├── router.py           # Main router
│   │   │   └── endpoints/
│   │   │       ├── stocks.py       # Stock endpoints
│   │   │       ├── screener.py     # Screener endpoints
│   │   │       ├── portfolio.py    # Portfolio endpoints
│   │   │       ├── alerts.py       # Alert endpoints
│   │   │       └── auth.py         # Authentication
│   │
│   ├── services/                    # Business Logic
│   │   ├── __init__.py
│   │   ├── stock_service.py        # Stock operations
│   │   ├── screener_service.py     # Screening logic
│   │   ├── analysis_service.py     # Financial analysis
│   │   ├── yfinance_service.py     # yfinance wrapper
│   │   ├── alert_service.py        # Alert management
│   │   └── portfolio_service.py    # Portfolio management
│   │
│   ├── repositories/                # Data Access Layer
│   │   ├── __init__.py
│   │   ├── stock_repository.py
│   │   ├── user_repository.py
│   │   ├── portfolio_repository.py
│   │   └── alert_repository.py
│   │
│   ├── models/                      # SQLAlchemy Models
│   │   ├── __init__.py
│   │   ├── stock.py
│   │   ├── user.py
│   │   ├── portfolio.py
│   │   ├── alert.py
│   │   └── historical_data.py
│   │
│   ├── schemas/                     # Pydantic Schemas
│   │   ├── __init__.py
│   │   ├── stock.py
│   │   ├── user.py
│   │   ├── portfolio.py
│   │   ├── alert.py
│   │   └── screener.py
│   │
│   ├── core/                        # Core utilities
│   │   ├── __init__.py
│   │   ├── database.py             # DB connection
│   │   ├── redis.py                # Redis connection
│   │   ├── security.py             # Auth utilities
│   │   └── exceptions.py           # Custom exceptions
│   │
│   ├── workers/                     # Background jobs
│   │   ├── __init__.py
│   │   ├── celery_app.py
│   │   ├── tasks/
│   │   │   ├── update_stocks.py    # Update stock data
│   │   │   ├── run_screener.py     # Run screener
│   │   │   └── send_alerts.py      # Send notifications
│   │
│   └── utils/                       # Utilities
│       ├── __init__.py
│       ├── formatters.py
│       ├── validators.py
│       └── calculations.py
│
├── tests/                           # Tests
│   ├── unit/
│   ├── integration/
│   └── e2e/
│
├── migrations/                      # Alembic migrations
│   └── versions/
│
├── scripts/                         # Utility scripts
│   ├── seed_database.py
│   └── backfill_historical.py
│
├── docker/
│   ├── Dockerfile
│   ├── Dockerfile.worker
│   └── docker-compose.yml
│
├── .env.example
├── requirements.txt
├── pyproject.toml
├── pytest.ini
└── README.md
```

---

## 📊 Recursos do yfinance e Implementação

### Mapeamento Completo: Funcionalidade ↔ yfinance

#### 1. **Ticker Class** - Informações Detalhadas de Ações

**Referência**: `https://ranaroussi.github.io/yfinance/reference/api/yfinance.Ticker.html`

| Método yfinance | Aplicação no Sistema | Endpoint API |
|----------------|---------------------|-------------|
| `Ticker(symbol)` | Obter dados de uma ação específica | `GET /api/v1/stocks/{ticker}` |
| `.info` | Informações gerais (setor, descrição, etc.) | Incluído em `GET /api/v1/stocks/{ticker}` |
| `.fast_info` | Dados rápidos de preço e volume | `GET /api/v1/stocks/{ticker}/quick` |
| `.history()` | Histórico de preços (OHLCV) | `GET /api/v1/stocks/{ticker}/history` |
| `.get_income_stmt()` | Demonstração de Resultados | `GET /api/v1/stocks/{ticker}/financials/income` |
| `.get_balance_sheet()` | Balanço Patrimonial | `GET /api/v1/stocks/{ticker}/financials/balance` |
| `.get_cash_flow()` | Fluxo de Caixa | `GET /api/v1/stocks/{ticker}/financials/cashflow` |
| `.get_dividends()` | Histórico de Dividendos | `GET /api/v1/stocks/{ticker}/dividends` |
| `.get_splits()` | Histórico de Splits | `GET /api/v1/stocks/{ticker}/splits` |
| `.get_recommendations()` | Recomendações de Analistas | `GET /api/v1/stocks/{ticker}/recommendations` |
| `.get_analyst_price_targets()` | Preços-alvo de Analistas | `GET /api/v1/stocks/{ticker}/targets` |
| `.get_earnings()` | Dados de Earnings | `GET /api/v1/stocks/{ticker}/earnings` |
| `.get_major_holders()` | Principais Acionistas | `GET /api/v1/stocks/{ticker}/holders` |
| `.get_institutional_holders()` | Investidores Institucionais | `GET /api/v1/stocks/{ticker}/institutional` |
| `.get_insider_transactions()` | Transações de Insiders | `GET /api/v1/stocks/{ticker}/insider-trades` |
| `.get_news()` | Notícias da Ação | `GET /api/v1/stocks/{ticker}/news` |

**Exemplo de Implementação**:

```python
# app/services/yfinance_service.py

import yfinance as yf
from typing import Dict, Any, List
from datetime import datetime, timedelta
import pandas as pd

class YFinanceService:
    """Wrapper service para yfinance API"""

    def __init__(self, cache_service):
        self.cache = cache_service

    def get_stock_info(self, ticker: str) -> Dict[str, Any]:
        """
        Obtém informações completas de uma ação
        Usa: Ticker.info
        """
        cache_key = f"stock_info:{ticker}"

        # Tenta buscar do cache (TTL: 1 hora)
        cached = self.cache.get(cache_key)
        if cached:
            return cached

        try:
            stock = yf.Ticker(ticker)
            info = stock.info

            # Processa e normaliza dados
            result = {
                'ticker': ticker,
                'name': info.get('longName'),
                'sector': info.get('sector'),
                'industry': info.get('industry'),
                'description': info.get('longBusinessSummary'),
                'website': info.get('website'),
                'employees': info.get('fullTimeEmployees'),
                'market_cap': info.get('marketCap'),
                'price': info.get('currentPrice'),
                'previous_close': info.get('previousClose'),
                'volume': info.get('volume'),
                'avg_volume': info.get('averageVolume'),
                'pe_ratio': info.get('trailingPE'),
                'forward_pe': info.get('forwardPE'),
                'peg_ratio': info.get('pegRatio'),
                'price_to_book': info.get('priceToBook'),
                'price_to_sales': info.get('priceToSalesTrailing12Months'),
                'dividend_yield': info.get('dividendYield'),
                'beta': info.get('beta'),
                'week_52_high': info.get('fiftyTwoWeekHigh'),
                'week_52_low': info.get('fiftyTwoWeekLow'),
                'updated_at': datetime.now().isoformat()
            }

            # Salva no cache
            self.cache.set(cache_key, result, ttl=3600)

            return result

        except Exception as e:
            raise Exception(f"Error fetching stock info for {ticker}: {str(e)}")

    def get_stock_history(
        self,
        ticker: str,
        period: str = "1y",
        interval: str = "1d"
    ) -> List[Dict[str, Any]]:
        """
        Obtém histórico de preços
        Usa: Ticker.history()

        Args:
            ticker: Símbolo da ação
            period: "1d", "5d", "1mo", "3mo", "6mo", "1y", "2y", "5y", "10y", "ytd", "max"
            interval: "1m", "2m", "5m", "15m", "30m", "60m", "90m", "1h", "1d", "5d", "1wk", "1mo", "3mo"
        """
        cache_key = f"stock_history:{ticker}:{period}:{interval}"

        cached = self.cache.get(cache_key)
        if cached:
            return cached

        try:
            stock = yf.Ticker(ticker)
            hist = stock.history(period=period, interval=interval)

            # Converte DataFrame para lista de dicts
            result = []
            for index, row in hist.iterrows():
                result.append({
                    'date': index.isoformat(),
                    'open': float(row['Open']),
                    'high': float(row['High']),
                    'low': float(row['Low']),
                    'close': float(row['Close']),
                    'volume': int(row['Volume'])
                })

            # Cache por 15 minutos (dados históricos mudam menos)
            self.cache.set(cache_key, result, ttl=900)

            return result

        except Exception as e:
            raise Exception(f"Error fetching history for {ticker}: {str(e)}")

    def get_dividends(self, ticker: str) -> List[Dict[str, Any]]:
        """
        Obtém histórico de dividendos
        Usa: Ticker.get_dividends()
        """
        try:
            stock = yf.Ticker(ticker)
            dividends = stock.dividends

            result = []
            for date, value in dividends.items():
                result.append({
                    'date': date.isoformat(),
                    'value': float(value)
                })

            return sorted(result, key=lambda x: x['date'], reverse=True)

        except Exception as e:
            raise Exception(f"Error fetching dividends for {ticker}: {str(e)}")

    def get_financial_statements(
        self,
        ticker: str,
        statement_type: str = "income",  # income, balance, cashflow
        freq: str = "yearly"  # yearly, quarterly
    ) -> Dict[str, Any]:
        """
        Obtém demonstrações financeiras
        Usa: Ticker.get_income_stmt(), get_balance_sheet(), get_cash_flow()
        """
        try:
            stock = yf.Ticker(ticker)

            if statement_type == "income":
                if freq == "quarterly":
                    df = stock.quarterly_income_stmt
                else:
                    df = stock.income_stmt
            elif statement_type == "balance":
                if freq == "quarterly":
                    df = stock.quarterly_balance_sheet
                else:
                    df = stock.balance_sheet
            elif statement_type == "cashflow":
                if freq == "quarterly":
                    df = stock.quarterly_cashflow
                else:
                    df = stock.cashflow
            else:
                raise ValueError(f"Invalid statement type: {statement_type}")

            # Converte DataFrame para dict estruturado
            result = df.to_dict(orient='index')

            return result

        except Exception as e:
            raise Exception(f"Error fetching {statement_type} statement for {ticker}: {str(e)}")

    def get_analyst_recommendations(self, ticker: str) -> List[Dict[str, Any]]:
        """
        Obtém recomendações de analistas
        Usa: Ticker.get_recommendations()
        """
        try:
            stock = yf.Ticker(ticker)
            recommendations = stock.recommendations

            if recommendations is None or recommendations.empty:
                return []

            result = []
            for index, row in recommendations.tail(20).iterrows():
                result.append({
                    'date': index.isoformat(),
                    'firm': row.get('Firm'),
                    'to_grade': row.get('To Grade'),
                    'from_grade': row.get('From Grade'),
                    'action': row.get('Action')
                })

            return result

        except Exception as e:
            raise Exception(f"Error fetching recommendations for {ticker}: {str(e)}")
```

#### 2. **download()** - Download em Massa

**Referência**: `https://ranaroussi.github.io/yfinance/reference/api/yfinance.download.html`

**Aplicação**: Atualização em lote de múltiplas ações

```python
# app/workers/tasks/update_stocks.py

from celery import shared_task
import yfinance as yf
from datetime import datetime, timedelta

@shared_task
def update_all_stocks_daily():
    """
    Job diário para atualizar todas as ações do screener
    Usa: yf.download() para eficiência
    """
    # Lista de tickers brasileiros
    tickers = [
        'VALE3.SA', 'PETR4.SA', 'ITUB4.SA', 'BBDC4.SA', 'BBAS3.SA',
        'CMIG4.SA', 'CPLE6.SA', 'ELET3.SA', 'USIM5.SA', 'CSNA3.SA',
        # ... mais tickers
    ]

    try:
        # Download em lote (muito mais eficiente que individual)
        data = yf.download(
            tickers=' '.join(tickers),
            period='1d',
            interval='1d',
            group_by='ticker',
            auto_adjust=True,
            threads=True  # Download paralelo
        )

        # Processa e salva no banco
        for ticker in tickers:
            ticker_data = data[ticker]

            # Salva no PostgreSQL
            save_stock_data(ticker, ticker_data)

        return {"status": "success", "stocks_updated": len(tickers)}

    except Exception as e:
        return {"status": "error", "message": str(e)}
```

#### 3. **screen()** - Screener de Ações

**Referência**: `https://ranaroussi.github.io/yfinance/reference/api/yfinance.screen.html`

**Aplicação**: Filtrar ações baratas automaticamente

```python
# app/services/screener_service.py

import yfinance as yf
from yfinance import EquityQuery

class ScreenerService:
    """Serviço de screening de ações"""

    def screen_undervalued_stocks(
        self,
        max_pe: float = 10,
        min_dividend: float = 5,
        min_market_cap: float = 1_000_000_000,
        region: str = 'br'
    ):
        """
        Encontra ações subvalorizadas
        Usa: yf.screen() com EquityQuery customizado
        """
        try:
            # Screener predefinido do yfinance
            # response = yf.screen("undervalued_growth_stocks")

            # Ou criar query customizada
            query = EquityQuery('and', [
                EquityQuery('lte', ['trailingPE', max_pe]),  # P/L <= 10
                EquityQuery('gte', ['dividendYield', min_dividend / 100]),  # Div >= 5%
                EquityQuery('gte', ['marketCap', min_market_cap]),  # Cap >= 1B
                EquityQuery('eq', ['region', region])  # Brasil
            ])

            response = yf.screen(
                query,
                size=250,  # Máximo de resultados
                sortField='trailingPE',
                sortAsc=True  # Ordenar por menor P/L
            )

            # Processa resultados
            stocks = []
            for quote in response['quotes']:
                stocks.append({
                    'ticker': quote['symbol'],
                    'name': quote['shortName'],
                    'price': quote['regularMarketPrice'],
                    'change_percent': quote['regularMarketChangePercent'],
                    'volume': quote['regularMarketVolume'],
                    'market_cap': quote['marketCap'],
                    'pe_ratio': quote.get('trailingPE'),
                    'dividend_yield': quote.get('dividendYield', 0) * 100,
                    'sector': quote.get('sector')
                })

            return stocks

        except Exception as e:
            raise Exception(f"Error in screener: {str(e)}")

    def screen_with_custom_criteria(self, criteria: Dict[str, Any]):
        """
        Screening com critérios totalmente customizados
        """
        # Exemplo de critérios avançados
        # criteria = {
        #     'filters': [
        #         {'field': 'trailingPE', 'operator': 'lte', 'value': 10},
        #         {'field': 'priceToBook', 'operator': 'lte', 'value': 1.5},
        #         {'field': 'debtToEquity', 'operator': 'lte', 'value': 0.5},
        #         {'field': 'roe', 'operator': 'gte', 'value': 15}
        #     ],
        #     'sort_by': 'trailingPE',
        #     'limit': 50
        # }

        # Constrói query dinâmica
        conditions = []
        for f in criteria.get('filters', []):
            operator = f['operator']  # 'eq', 'gt', 'lt', 'gte', 'lte'
            conditions.append(
                EquityQuery(operator, [f['field'], f['value']])
            )

        query = EquityQuery('and', conditions)

        response = yf.screen(
            query,
            size=criteria.get('limit', 100),
            sortField=criteria.get('sort_by', 'ticker'),
            sortAsc=criteria.get('sort_order', 'asc') == 'asc'
        )

        return response['quotes']
```

#### 4. **Search** - Busca de Ações

**Referência**: `https://ranaroussi.github.io/yfinance/reference/api/yfinance.Search.html`

**Aplicação**: Busca inteligente para autocomplete

```python
# app/services/search_service.py

from yfinance import Search

class SearchService:
    """Serviço de busca de ações"""

    def search_stocks(self, query: str, max_results: int = 8):
        """
        Busca ações por ticker ou nome
        Usa: yfinance.Search
        """
        try:
            search = Search(
                query=query,
                max_results=max_results,
                enable_fuzzy_query=True  # Tolera erros de digitação
            )

            results = []

            # Quotes (cotações encontradas)
            for quote in search.quotes:
                results.append({
                    'type': 'stock',
                    'ticker': quote['symbol'],
                    'name': quote['shortname'] or quote['longname'],
                    'exchange': quote['exchange'],
                    'type_display': quote.get('quoteType', 'Equity')
                })

            return results

        except Exception as e:
            raise Exception(f"Error searching for '{query}': {str(e)}")
```

---

## 🔌 APIs e Endpoints

### Estrutura Base

```
Base URL: https://api.acoesbaratas.com.br/api/v1
```

### Endpoints Principais

#### 1. **Stocks** - Gerenciamento de Ações

```
GET    /stocks                           # Lista todas as ações
GET    /stocks/{ticker}                  # Detalhes de uma ação
GET    /stocks/{ticker}/quick            # Dados rápidos (fast_info)
GET    /stocks/{ticker}/history          # Histórico de preços
GET    /stocks/{ticker}/dividends        # Histórico de dividendos
GET    /stocks/{ticker}/splits           # Splits
GET    /stocks/{ticker}/financials       # Demonstrações financeiras
GET    /stocks/{ticker}/recommendations  # Recomendações de analistas
GET    /stocks/{ticker}/holders          # Principais acionistas
GET    /stocks/{ticker}/news             # Notícias
POST   /stocks/compare                   # Comparar múltiplas ações
```

**Exemplo de Response** - `GET /stocks/VALE3`:

```json
{
  "ticker": "VALE3",
  "name": "Vale S.A.",
  "sector": "Mineração",
  "industry": "Metais & Mineração",
  "description": "A Vale é uma mineradora brasileira...",
  "price": {
    "current": 62.45,
    "previous_close": 61.22,
    "change": 1.23,
    "change_percent": 2.01,
    "currency": "BRL"
  },
  "volume": {
    "current": 45678000,
    "average": 42000000
  },
  "market_cap": 286500000000,
  "valuation": {
    "pe_ratio": 4.2,
    "forward_pe": 4.5,
    "peg_ratio": 0.35,
    "price_to_book": 1.2,
    "price_to_sales": 1.6,
    "ev_to_ebitda": 2.8
  },
  "profitability": {
    "roe": 28.5,
    "roa": 18.2,
    "profit_margin": 38.2,
    "operating_margin": 42.1
  },
  "financial_health": {
    "debt_to_equity": 0.38,
    "current_ratio": 1.85,
    "quick_ratio": 1.42
  },
  "dividends": {
    "yield": 8.5,
    "payout_ratio": 45.2,
    "ex_dividend_date": "2024-11-15"
  },
  "week_52": {
    "high": 78.90,
    "low": 55.30
  },
  "beta": 1.15,
  "is_undervalued": true,
  "undervalued_score": 8.5,
  "updated_at": "2024-11-28T10:30:00Z"
}
```

#### 2. **Screener** - Filtragem de Ações

```
GET    /screener                         # Screener com filtros padrão
POST   /screener/custom                  # Screener customizado
GET    /screener/presets                 # Filtros predefinidos
GET    /screener/sectors                 # Lista de setores
```

**Exemplo de Request** - `POST /screener/custom`:

```json
{
  "filters": {
    "max_pe": 10,
    "min_dividend_yield": 5,
    "min_market_cap": 1000000000,
    "max_debt_to_equity": 0.8,
    "min_roe": 15,
    "sectors": ["Bancos", "Energia Elétrica", "Mineração"],
    "min_liquidity": 1000000
  },
  "sort": {
    "field": "pe_ratio",
    "order": "asc"
  },
  "pagination": {
    "page": 1,
    "per_page": 20
  }
}
```

**Response**:

```json
{
  "total": 45,
  "page": 1,
  "per_page": 20,
  "pages": 3,
  "stocks": [
    {
      "ticker": "PETR4",
      "name": "Petrobras PN",
      "price": 38.92,
      "change_percent": 2.04,
      "pe_ratio": 3.1,
      "dividend_yield": 14.2,
      "market_cap": 506700000000,
      "sector": "Petróleo e Gás",
      "is_undervalued": true,
      "undervalued_score": 9.2
    },
    // ... mais ações
  ],
  "filters_applied": { /* ... */ },
  "generated_at": "2024-11-28T10:30:00Z"
}
```

#### 3. **Portfolio** - Gestão de Portfólio

```
GET    /portfolios                       # Listar portfólios do usuário
POST   /portfolios                       # Criar portfólio
GET    /portfolios/{id}                  # Detalhes do portfólio
PUT    /portfolios/{id}                  # Atualizar portfólio
DELETE /portfolios/{id}                  # Deletar portfólio
POST   /portfolios/{id}/stocks           # Adicionar ação
DELETE /portfolios/{id}/stocks/{ticker}  # Remover ação
GET    /portfolios/{id}/performance      # Performance do portfólio
```

#### 4. **Alerts** - Sistema de Alertas

```
GET    /alerts                           # Listar alertas do usuário
POST   /alerts                           # Criar alerta
PUT    /alerts/{id}                      # Atualizar alerta
DELETE /alerts/{id}                      # Deletar alerta
GET    /alerts/triggered                 # Alertas disparados
```

**Exemplo** - Criar alerta de preço:

```json
{
  "ticker": "VALE3",
  "type": "price",
  "condition": "below",
  "value": 60.00,
  "notification_method": ["email", "push"],
  "active": true
}
```

#### 5. **Analysis** - Análises e Indicadores

```
GET    /analysis/{ticker}/fundamentals   # Análise fundamentalista
GET    /analysis/{ticker}/technical      # Análise técnica
GET    /analysis/{ticker}/fair-value     # Valuation (valor justo)
GET    /analysis/{ticker}/comparison     # Comparação com setor
POST   /analysis/batch                   # Análise em lote
```

#### 6. **Market** - Dados de Mercado

```
GET    /market/summary                   # Resumo do mercado
GET    /market/indices                   # Índices (IBOV, IFIX, etc.)
GET    /market/sectors                   # Performance por setor
GET    /market/movers                    # Maiores altas/baixas do dia
```

#### 7. **Auth** - Autenticação

```
POST   /auth/register                    # Registrar usuário
POST   /auth/login                       # Login
POST   /auth/refresh                     # Refresh token
POST   /auth/logout                      # Logout
POST   /auth/forgot-password             # Recuperar senha
```

---

## 📦 Models e Schemas

### SQLAlchemy Models (PostgreSQL)

```python
# app/models/stock.py

from sqlalchemy import Column, Integer, String, Float, DateTime, Boolean, JSON
from sqlalchemy.orm import relationship
from app.core.database import Base
from datetime import datetime

class Stock(Base):
    __tablename__ = "stocks"

    id = Column(Integer, primary_key=True, index=True)
    ticker = Column(String(10), unique=True, index=True, nullable=False)
    name = Column(String(255), nullable=False)
    sector = Column(String(100), index=True)
    industry = Column(String(100))
    description = Column(String)

    # Price data
    current_price = Column(Float)
    previous_close = Column(Float)
    volume = Column(Integer)
    average_volume = Column(Integer)
    market_cap = Column(Float)

    # Valuation metrics
    pe_ratio = Column(Float, index=True)
    forward_pe = Column(Float)
    peg_ratio = Column(Float)
    price_to_book = Column(Float)
    price_to_sales = Column(Float)
    ev_to_ebitda = Column(Float)

    # Profitability
    roe = Column(Float)
    roa = Column(Float)
    profit_margin = Column(Float)
    operating_margin = Column(Float)

    # Financial health
    debt_to_equity = Column(Float)
    current_ratio = Column(Float)
    quick_ratio = Column(Float)

    # Dividends
    dividend_yield = Column(Float, index=True)
    payout_ratio = Column(Float)
    ex_dividend_date = Column(DateTime)

    # 52-week range
    week_52_high = Column(Float)
    week_52_low = Column(Float)

    # Risk
    beta = Column(Float)

    # Flags
    is_undervalued = Column(Boolean, default=False, index=True)
    undervalued_score = Column(Float)  # 0-10 score

    # Metadata
    last_updated = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    created_at = Column(DateTime, default=datetime.utcnow)

    # Relationships
    historical_data = relationship("HistoricalData", back_populates="stock")
    dividends = relationship("Dividend", back_populates="stock")

    # Additional data stored as JSON
    analyst_data = Column(JSON)  # recommendations, price targets, etc.
    holders_data = Column(JSON)  # major holders, institutional, etc.
```

```python
# app/models/historical_data.py

from sqlalchemy import Column, Integer, String, Float, DateTime, ForeignKey, Date
from sqlalchemy.orm import relationship
from app.core.database import Base

class HistoricalData(Base):
    __tablename__ = "historical_data"

    id = Column(Integer, primary_key=True, index=True)
    stock_id = Column(Integer, ForeignKey("stocks.id"), nullable=False, index=True)
    date = Column(Date, nullable=False, index=True)

    open = Column(Float, nullable=False)
    high = Column(Float, nullable=False)
    low = Column(Float, nullable=False)
    close = Column(Float, nullable=False)
    volume = Column(Integer, nullable=False)

    # Adjusted values
    adj_close = Column(Float)

    stock = relationship("Stock", back_populates="historical_data")

    __table_args__ = (
        # Unique constraint: uma entrada por ação por dia
        UniqueConstraint('stock_id', 'date', name='uix_stock_date'),
    )
```

```python
# app/models/user.py

from sqlalchemy import Column, Integer, String, DateTime, Boolean
from sqlalchemy.orm import relationship
from app.core.database import Base
from datetime import datetime

class User(Base):
    __tablename__ = "users"

    id = Column(Integer, primary_key=True, index=True)
    email = Column(String(255), unique=True, index=True, nullable=False)
    hashed_password = Column(String(255), nullable=False)
    full_name = Column(String(255))

    is_active = Column(Boolean, default=True)
    is_verified = Column(Boolean, default=False)
    is_premium = Column(Boolean, default=False)

    created_at = Column(DateTime, default=datetime.utcnow)
    last_login = Column(DateTime)

    # Relationships
    portfolios = relationship("Portfolio", back_populates="user")
    alerts = relationship("Alert", back_populates="user")
```

```python
# app/models/portfolio.py

from sqlalchemy import Column, Integer, String, Float, DateTime, ForeignKey, Table
from sqlalchemy.orm import relationship
from app.core.database import Base
from datetime import datetime

# Association table for many-to-many
portfolio_stocks = Table(
    'portfolio_stocks',
    Base.metadata,
    Column('portfolio_id', Integer, ForeignKey('portfolios.id')),
    Column('stock_id', Integer, ForeignKey('stocks.id')),
    Column('quantity', Float),
    Column('average_price', Float),
    Column('added_at', DateTime, default=datetime.utcnow)
)

class Portfolio(Base):
    __tablename__ = "portfolios"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False, index=True)
    name = Column(String(255), nullable=False)
    description = Column(String)

    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    user = relationship("User", back_populates="portfolios")
    stocks = relationship("Stock", secondary=portfolio_stocks)
```

### Pydantic Schemas (Validation)

```python
# app/schemas/stock.py

from pydantic import BaseModel, Field, validator
from typing import Optional, List
from datetime import datetime

class StockBase(BaseModel):
    ticker: str = Field(..., min_length=4, max_length=10)
    name: str
    sector: Optional[str]
    industry: Optional[str]

class StockPrice(BaseModel):
    current: float
    previous_close: float
    change: float
    change_percent: float
    currency: str = "BRL"

class StockValuation(BaseModel):
    pe_ratio: Optional[float]
    forward_pe: Optional[float]
    peg_ratio: Optional[float]
    price_to_book: Optional[float]
    price_to_sales: Optional[float]
    ev_to_ebitda: Optional[float]

class StockResponse(BaseModel):
    ticker: str
    name: str
    sector: Optional[str]
    price: StockPrice
    valuation: StockValuation
    dividend_yield: Optional[float]
    market_cap: float
    is_undervalued: bool
    undervalued_score: Optional[float]
    updated_at: datetime

    class Config:
        from_attributes = True

class ScreenerFilters(BaseModel):
    max_pe: Optional[float] = Field(None, ge=0)
    min_dividend_yield: Optional[float] = Field(None, ge=0, le=100)
    min_market_cap: Optional[float] = Field(None, ge=0)
    max_debt_to_equity: Optional[float] = Field(None, ge=0)
    min_roe: Optional[float] = Field(None)
    sectors: Optional[List[str]] = []
    min_liquidity: Optional[float] = Field(None, ge=0)

    @validator('sectors')
    def validate_sectors(cls, v):
        valid_sectors = [
            'Bancos', 'Energia Elétrica', 'Mineração', 'Petróleo e Gás',
            'Siderurgia', 'Construção Civil', 'Alimentos', 'Varejo'
        ]
        for sector in v:
            if sector not in valid_sectors:
                raise ValueError(f'Invalid sector: {sector}')
        return v

class ScreenerRequest(BaseModel):
    filters: ScreenerFilters
    sort: Optional[dict] = {"field": "pe_ratio", "order": "asc"}
    pagination: Optional[dict] = {"page": 1, "per_page": 20}
```

---

## ⚙️ Serviços e Business Logic

### Service Pattern

```python
# app/services/analysis_service.py

from typing import Dict, Any
import numpy as np
import pandas as pd

class AnalysisService:
    """Serviço de análise fundamentalista"""

    def __init__(self, yfinance_service, stock_repository):
        self.yf = yfinance_service
        self.stocks = stock_repository

    def calculate_undervalued_score(self, ticker: str) -> float:
        """
        Calcula score de subvalorização (0-10)
        Quanto maior, mais subvalorizada
        """
        stock_data = self.yf.get_stock_info(ticker)

        score = 0
        max_score = 10

        # 1. P/L baixo (até 3 pontos)
        pe = stock_data.get('pe_ratio')
        if pe and pe > 0:
            if pe < 5:
                score += 3
            elif pe < 8:
                score += 2
            elif pe < 12:
                score += 1

        # 2. PEG baixo (até 2 pontos)
        peg = stock_data.get('peg_ratio')
        if peg and peg > 0:
            if peg < 0.5:
                score += 2
            elif peg < 1:
                score += 1

        # 3. Dividend Yield alto (até 2 pontos)
        div_yield = stock_data.get('dividend_yield', 0) * 100
        if div_yield > 8:
            score += 2
        elif div_yield > 5:
            score += 1

        # 4. P/VP baixo (até 2 pontos)
        pb = stock_data.get('price_to_book')
        if pb and pb > 0:
            if pb < 1:
                score += 2
            elif pb < 1.5:
                score += 1

        # 5. Saúde financeira (até 1 ponto)
        debt_equity = stock_data.get('debt_to_equity', 999)
        if debt_equity < 0.5:
            score += 1

        return round(score, 1)

    def calculate_fair_value(self, ticker: str) -> Dict[str, Any]:
        """
        Calcula valor justo usando múltiplos métodos
        - DCF (Discounted Cash Flow)
        - P/L comparativo
        - Graham Number
        """
        stock = self.yf.get_stock_info(ticker)

        results = {}

        # 1. Graham Number (Benjamin Graham)
        eps = stock.get('eps')
        book_value = stock.get('book_value_per_share')

        if eps and book_value and eps > 0 and book_value > 0:
            graham = (22.5 * eps * book_value) ** 0.5
            results['graham_number'] = round(graham, 2)

        # 2. P/L Comparativo (média do setor)
        sector_avg_pe = self._get_sector_average_pe(stock['sector'])
        if sector_avg_pe and eps:
            pe_based = sector_avg_pe * eps
            results['pe_based_value'] = round(pe_based, 2)

        # 3. Dividend Discount Model
        dividend = stock.get('dividend_per_share')
        growth_rate = 0.05  # Assumindo 5% de crescimento
        required_return = 0.12  # 12% retorno esperado

        if dividend and dividend > 0:
            ddm_value = dividend * (1 + growth_rate) / (required_return - growth_rate)
            results['dividend_discount_value'] = round(ddm_value, 2)

        # Média dos métodos
        values = [v for v in results.values() if v > 0]
        if values:
            results['average_fair_value'] = round(np.mean(values), 2)
            results['current_price'] = stock['price']
            results['upside_potential'] = round(
                (results['average_fair_value'] / stock['price'] - 1) * 100, 2
            )

        return results

    def compare_to_sector(self, ticker: str) -> Dict[str, Any]:
        """
        Compara ação com médias do setor
        """
        stock = self.stocks.get_by_ticker(ticker)
        sector_stocks = self.stocks.get_by_sector(stock.sector)

        # Calcula médias do setor
        sector_avg = {
            'pe_ratio': np.mean([s.pe_ratio for s in sector_stocks if s.pe_ratio]),
            'dividend_yield': np.mean([s.dividend_yield for s in sector_stocks if s.dividend_yield]),
            'roe': np.mean([s.roe for s in sector_stocks if s.roe]),
            'debt_to_equity': np.mean([s.debt_to_equity for s in sector_stocks if s.debt_to_equity]),
        }

        # Compara
        comparison = {
            'stock': {
                'ticker': ticker,
                'pe_ratio': stock.pe_ratio,
                'dividend_yield': stock.dividend_yield,
                'roe': stock.roe,
                'debt_to_equity': stock.debt_to_equity,
            },
            'sector_average': sector_avg,
            'comparison': {
                'pe_vs_sector': 'lower' if stock.pe_ratio < sector_avg['pe_ratio'] else 'higher',
                'div_vs_sector': 'higher' if stock.dividend_yield > sector_avg['dividend_yield'] else 'lower',
                'roe_vs_sector': 'higher' if stock.roe > sector_avg['roe'] else 'lower',
            }
        }

        return comparison
```

---

## 🚀 Cache e Performance

### Redis Cache Strategy

```python
# app/core/redis.py

import redis
import json
from typing import Any, Optional
from datetime import timedelta

class RedisCache:
    def __init__(self, redis_url: str):
        self.redis = redis.from_url(redis_url, decode_responses=True)

    def get(self, key: str) -> Optional[Any]:
        """Get value from cache"""
        data = self.redis.get(key)
        if data:
            return json.loads(data)
        return None

    def set(self, key: str, value: Any, ttl: int = 3600):
        """Set value in cache with TTL (seconds)"""
        self.redis.setex(
            key,
            timedelta(seconds=ttl),
            json.dumps(value, default=str)
        )

    def delete(self, key: str):
        """Delete key from cache"""
        self.redis.delete(key)

    def invalidate_pattern(self, pattern: str):
        """Invalidate all keys matching pattern"""
        for key in self.redis.scan_iter(pattern):
            self.redis.delete(key)
```

### Cache Strategy por Tipo de Dado

| Tipo de Dado | TTL | Invalidação |
|--------------|-----|-------------|
| Stock info (preço atual) | 5 min | Update job |
| Histórico de preços | 15 min | Diário |
| Dados fundamentalistas | 1 hora | Trimestral |
| Screener results | 10 min | Update job |
| Notícias | 30 min | - |
| Recomendações de analistas | 24 horas | - |

---

## 🔐 Segurança e Autenticação

### JWT Authentication

```python
# app/core/security.py

from datetime import datetime, timedelta
from typing import Optional
from jose import JWTError, jwt
from passlib.context import CryptContext

SECRET_KEY = "your-secret-key"  # Use .env
ALGORITHM = "HS256"
ACCESS_TOKEN_EXPIRE_MINUTES = 30
REFRESH_TOKEN_EXPIRE_DAYS = 7

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

def verify_password(plain_password: str, hashed_password: str) -> bool:
    return pwd_context.verify(plain_password, hashed_password)

def get_password_hash(password: str) -> str:
    return pwd_context.hash(password)

def create_access_token(data: dict, expires_delta: Optional[timedelta] = None):
    to_encode = data.copy()
    if expires_delta:
        expire = datetime.utcnow() + expires_delta
    else:
        expire = datetime.utcnow() + timedelta(minutes=15)

    to_encode.update({"exp": expire, "type": "access"})
    encoded_jwt = jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)
    return encoded_jwt

def create_refresh_token(data: dict):
    to_encode = data.copy()
    expire = datetime.utcnow() + timedelta(days=REFRESH_TOKEN_EXPIRE_DAYS)
    to_encode.update({"exp": expire, "type": "refresh"})
    encoded_jwt = jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)
    return encoded_jwt
```

### Rate Limiting

```python
# app/middleware/rate_limit.py

from fastapi import Request, HTTPException
from redis import Redis
import time

class RateLimiter:
    def __init__(self, redis: Redis):
        self.redis = redis

    async def check_rate_limit(
        self,
        request: Request,
        max_requests: int = 100,
        window: int = 60
    ):
        """
        Rate limit: max_requests per window (seconds)
        """
        # Identifica usuário (IP ou user_id)
        identifier = request.client.host
        if hasattr(request.state, 'user'):
            identifier = f"user:{request.state.user.id}"

        key = f"rate_limit:{identifier}"

        current = self.redis.get(key)

        if current is None:
            self.redis.setex(key, window, 1)
            return

        if int(current) >= max_requests:
            raise HTTPException(
                status_code=429,
                detail="Rate limit exceeded. Try again later."
            )

        self.redis.incr(key)
```

---

## 🚀 Deploy e Infraestrutura

### Docker Compose

```yaml
# docker-compose.yml

version: '3.8'

services:
  # PostgreSQL Database
  postgres:
    image: postgres:15-alpine
    environment:
      POSTGRES_USER: acoes_baratas
      POSTGRES_PASSWORD: ${DB_PASSWORD}
      POSTGRES_DB: acoes_baratas_db
    volumes:
      - postgres_data:/var/lib/postgresql/data
    ports:
      - "5432:5432"
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U acoes_baratas"]
      interval: 10s
      timeout: 5s
      retries: 5

  # Redis Cache
  redis:
    image: redis:7-alpine
    ports:
      - "6379:6379"
    volumes:
      - redis_data:/data
    command: redis-server --appendonly yes

  # FastAPI Backend
  api:
    build:
      context: .
      dockerfile: docker/Dockerfile
    ports:
      - "8000:8000"
    environment:
      DATABASE_URL: postgresql://acoes_baratas:${DB_PASSWORD}@postgres:5432/acoes_baratas_db
      REDIS_URL: redis://redis:6379
      SECRET_KEY: ${SECRET_KEY}
    depends_on:
      postgres:
        condition: service_healthy
      redis:
        condition: service_started
    volumes:
      - ./app:/app/app
    command: uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload

  # Celery Worker
  worker:
    build:
      context: .
      dockerfile: docker/Dockerfile.worker
    environment:
      DATABASE_URL: postgresql://acoes_baratas:${DB_PASSWORD}@postgres:5432/acoes_baratas_db
      REDIS_URL: redis://redis:6379
    depends_on:
      - postgres
      - redis
    command: celery -A app.workers.celery_app worker --loglevel=info

  # Celery Beat (Scheduler)
  beat:
    build:
      context: .
      dockerfile: docker/Dockerfile.worker
    environment:
      DATABASE_URL: postgresql://acoes_baratas:${DB_PASSWORD}@postgres:5432/acoes_baratas_db
      REDIS_URL: redis://redis:6379
    depends_on:
      - postgres
      - redis
    command: celery -A app.workers.celery_app beat --loglevel=info

  # Nginx (Reverse Proxy)
  nginx:
    image: nginx:alpine
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./nginx/nginx.conf:/etc/nginx/nginx.conf
      - ./nginx/ssl:/etc/nginx/ssl
    depends_on:
      - api

volumes:
  postgres_data:
  redis_data:
```

### Celery Tasks

```python
# app/workers/celery_app.py

from celery import Celery
from celery.schedules import crontab

celery_app = Celery(
    'acoes_baratas',
    broker='redis://redis:6379/0',
    backend='redis://redis:6379/0'
)

# Configuração
celery_app.conf.update(
    task_serializer='json',
    accept_content=['json'],
    result_serializer='json',
    timezone='America/Sao_Paulo',
    enable_utc=True,
)

# Schedule de tasks
celery_app.conf.beat_schedule = {
    # Atualiza preços a cada 5 minutos durante horário de mercado
    'update-prices-5min': {
        'task': 'app.workers.tasks.update_stocks.update_all_prices',
        'schedule': crontab(minute='*/5', hour='10-17', day_of_week='1-5'),
    },

    # Atualiza dados fundamentalistas diariamente
    'update-fundamentals-daily': {
        'task': 'app.workers.tasks.update_stocks.update_fundamentals',
        'schedule': crontab(hour=18, minute=0),
    },

    # Roda screener a cada hora
    'run-screener-hourly': {
        'task': 'app.workers.tasks.run_screener.screen_undervalued',
        'schedule': crontab(minute=0),
    },

    # Checa alertas a cada 10 minutos
    'check-alerts-10min': {
        'task': 'app.workers.tasks.send_alerts.check_and_send',
        'schedule': crontab(minute='*/10'),
    },
}
```

---

## 📊 Monitoramento e Logs

### Logging

```python
# app/core/logging.py

import logging
import sys
from loguru import logger

# Remove handler padrão
logger.remove()

# Console output
logger.add(
    sys.stdout,
    colorize=True,
    format="<green>{time:YYYY-MM-DD HH:mm:ss}</green> | <level>{level: <8}</level> | <cyan>{name}</cyan>:<cyan>{function}</cyan> - <level>{message}</level>",
    level="INFO"
)

# File output
logger.add(
    "logs/app.log",
    rotation="500 MB",
    retention="10 days",
    compression="zip",
    level="DEBUG"
)

# Error file
logger.add(
    "logs/errors.log",
    rotation="100 MB",
    retention="30 days",
    level="ERROR"
)
```

### Health Check

```python
# app/api/v1/endpoints/health.py

from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from app.core.database import get_db
from app.core.redis import RedisCache

router = APIRouter()

@router.get("/health")
async def health_check(db: Session = Depends(get_db)):
    """Health check endpoint"""

    health = {
        "status": "healthy",
        "components": {}
    }

    # Check PostgreSQL
    try:
        db.execute("SELECT 1")
        health["components"]["database"] = "healthy"
    except Exception as e:
        health["status"] = "unhealthy"
        health["components"]["database"] = f"unhealthy: {str(e)}"

    # Check Redis
    try:
        redis = RedisCache()
        redis.redis.ping()
        health["components"]["cache"] = "healthy"
    except Exception as e:
        health["status"] = "unhealthy"
        health["components"]["cache"] = f"unhealthy: {str(e)}"

    return health
```

---

## 📝 Resumo de Implementação

### Fase 1: MVP (2-3 semanas)
- ✅ Setup básico (FastAPI + PostgreSQL + Redis)
- ✅ Integração yfinance básica
- ✅ Endpoints de stocks e screener
- ✅ Cache simples
- ✅ Frontend conectado

### Fase 2: Core Features (3-4 semanas)
- ✅ Sistema de autenticação completo
- ✅ Portfólios de usuário
- ✅ Sistema de alertas
- ✅ Workers para atualização automática
- ✅ Análise fundamentalista avançada

### Fase 3: Otimização (2-3 semanas)
- ✅ Cache inteligente
- ✅ Rate limiting
- ✅ Testes automatizados
- ✅ Monitoramento e logs
- ✅ Deploy em produção

### Fase 4: Features Premium (ongoing)
- ✅ Análise técnica
- ✅ Backtesting
- ✅ Notificações push
- ✅ Exportação de relatórios
- ✅ API pública para desenvolvedores

---

## 🎯 Métricas de Sucesso

- **Performance**: API responde em < 200ms (p95)
- **Disponibilidade**: 99.9% uptime
- **Dados**: Atualização a cada 5min durante pregão
- **Cache Hit Rate**: > 80%
- **Usuários**: Suportar 10k usuários simultâneos

---

## 📚 Recursos Adicionais

### Documentação yfinance
- [Referência Completa](https://ranaroussi.github.io/yfinance/reference/index.html)
- [Ticker Class](https://ranaroussi.github.io/yfinance/reference/api/yfinance.Ticker.html)
- [Download Function](https://ranaroussi.github.io/yfinance/reference/api/yfinance.download.html)
- [Screener](https://ranaroussi.github.io/yfinance/reference/api/yfinance.screen.html)

### Bibliotecas Python Recomendadas
- **pandas**: Manipulação de dados financeiros
- **numpy**: Cálculos numéricos
- **ta-lib**: Análise técnica (opcional)
- **plotly**: Gráficos interativos
- **fastapi**: Framework web
- **sqlalchemy**: ORM
- **celery**: Tasks assíncronas
- **redis-py**: Cliente Redis
- **pytest**: Testes

---

**Desenvolvido para "Ações Baratas da Bolsa" - Sistema MicroSaaS de Análise Fundamentalista**

**Versão**: 1.0
**Data**: Novembro 2024
**Autor**: Arquitetura de Software - World-class Development Team
