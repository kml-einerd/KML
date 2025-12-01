# 📊 Análise Completa e Profunda do yfinance

## 🎯 Visão Geral Executiva

O **yfinance** é a biblioteca Python mais popular para acesso gratuito a dados financeiros do Yahoo Finance. Com mais de 10 milhões de downloads mensais, é a escolha preferida para análise de ações, criptomoedas, fundos e outros ativos financeiros.

**Documentação Oficial**: https://ranaroussi.github.io/yfinance/

---

## 📚 Recursos Principais e Aplicações

### 1. **Classe Ticker** - Núcleo do yfinance

A classe `Ticker` é o coração do yfinance, fornecendo acesso completo a dados de uma ação individual.

#### Inicialização

```python
import yfinance as yf

# Ação brasileira (adicione .SA)
ticker = yf.Ticker("VALE3.SA")

# Ação americana
ticker = yf.Ticker("AAPL")

# Com sessão customizada (para proxies, autenticação, etc.)
import requests
session = requests.Session()
session.headers.update({'User-Agent': 'Mozilla/5.0'})
ticker = yf.Ticker("PETR4.SA", session=session)
```

#### 1.1 Informações Gerais (`.info` e `.fast_info`)

**Referência**: `Ticker.info` e `Ticker.fast_info`

**Aplicação no Sistema**: Tela de detalhes da ação, cards de resumo

```python
# .info - Completo mas mais lento (1 requisição)
info = ticker.info

# Dados disponíveis:
{
    # Identificação
    'symbol': 'VALE3.SA',
    'longName': 'Vale S.A.',
    'shortName': 'VALE ON',
    'sector': 'Basic Materials',
    'industry': 'Steel',
    'website': 'http://www.vale.com',
    'longBusinessSummary': 'Vale S.A., together with...',

    # Preço e Volume
    'currentPrice': 62.45,
    'previousClose': 61.22,
    'open': 61.50,
    'dayHigh': 63.10,
    'dayLow': 61.30,
    'volume': 45678000,
    'averageVolume': 42000000,
    'averageVolume10days': 43500000,

    # Valuation
    'marketCap': 286500000000,
    'enterpriseValue': 295000000000,
    'trailingPE': 4.2,
    'forwardPE': 4.5,
    'pegRatio': 0.35,
    'priceToBook': 1.2,
    'priceToSalesTrailing12Months': 1.6,
    'enterpriseToRevenue': 1.65,
    'enterpriseToEbitda': 2.8,

    # Profitabilidade
    'profitMargins': 0.382,
    'operatingMargins': 0.421,
    'returnOnAssets': 0.182,
    'returnOnEquity': 0.285,
    'grossMargins': 0.495,
    'ebitdaMargins': 0.48,

    # Saúde Financeira
    'totalDebt': 45000000000,
    'totalCash': 28000000000,
    'debtToEquity': 38.5,
    'currentRatio': 1.85,
    'quickRatio': 1.42,
    'totalCashPerShare': 5.42,

    # Crescimento
    'revenueGrowth': 0.085,
    'earningsGrowth': 0.12,

    # Dividendos
    'dividendRate': 5.31,
    'dividendYield': 0.085,
    'exDividendDate': 1699920000,
    'payoutRatio': 0.452,
    'fiveYearAvgDividendYield': 7.2,

    # 52 semanas
    'fiftyTwoWeekHigh': 78.90,
    'fiftyTwoWeekLow': 55.30,
    'fiftyDayAverage': 64.20,
    'twoHundredDayAverage': 67.50,

    # Risco
    'beta': 1.15,

    # Ações
    'sharesOutstanding': 4587000000,
    'floatShares': 3950000000,
    'heldPercentInsiders': 0.052,
    'heldPercentInstitutions': 0.456,

    # Dados da empresa
    'fullTimeEmployees': 67000,
    'auditRisk': 4,
    'boardRisk': 6,
    'compensationRisk': 5,
    'shareHolderRightsRisk': 7,
    'overallRisk': 5,

    # Recomendações
    'recommendationKey': 'buy',
    'recommendationMean': 1.8,
    'numberOfAnalystOpinions': 25,
    'targetHighPrice': 95.0,
    'targetLowPrice': 65.0,
    'targetMeanPrice': 82.5,
    'targetMedianPrice': 82.0,
}

# .fast_info - Rápido, dados essenciais
fast = ticker.fast_info

{
    'lastPrice': 62.45,
    'lastVolume': 45678000,
    'marketCap': 286500000000,
    'open': 61.50,
    'previousClose': 61.22,
    'dayHigh': 63.10,
    'dayLow': 61.30,
    'regularMarketPreviousClose': 61.22,
    'fiftyDayAverage': 64.20,
    'twoHundredDayAverage': 67.50,
    'yearHigh': 78.90,
    'yearLow': 55.30,
    'currency': 'BRL',
    'quoteType': 'EQUITY',
    'shares': 4587000000,
}
```

**💡 Aplicação Prática**:
- **Dashboard**: Cards de resumo com preço atual, variação, volume
- **Screener**: Filtrar por P/L, Market Cap, Dividend Yield
- **Análise**: Calcular scores de subvalorização
- **Comparação**: Comparar múltiplos entre ações

---

#### 1.2 Histórico de Preços (`.history()`)

**Referência**: `Ticker.history(period, interval, start, end, ...)`

**Aplicação**: Gráficos de preço, análise técnica, backtesting

```python
# Períodos disponíveis
periods = ['1d', '5d', '1mo', '3mo', '6mo', '1y', '2y', '5y', '10y', 'ytd', 'max']

# Intervalos disponíveis
intervals = ['1m', '2m', '5m', '15m', '30m', '60m', '90m', '1h', '1d', '5d', '1wk', '1mo', '3mo']

# Exemplo 1: Últimos 6 meses, diário
hist = ticker.history(period="6mo", interval="1d")

# Exemplo 2: Dados intraday (últimos 7 dias)
hist = ticker.history(period="7d", interval="5m")

# Exemplo 3: Período customizado
hist = ticker.history(start="2023-01-01", end="2024-01-01", interval="1d")

# Exemplo 4: Com ações corporativas
hist = ticker.history(period="1y", actions=True)  # Inclui dividendos e splits

# DataFrame retornado:
"""
                 Open   High    Low  Close    Volume  Dividends  Stock Splits
Date
2024-01-02   61.50  62.10  61.20  61.80  42000000       0.0           0.0
2024-01-03   61.85  62.50  61.70  62.30  38000000       0.0           0.0
2024-01-04   62.40  63.00  62.20  62.80  41000000       0.0           0.0
...
"""

# Parâmetros importantes:
# - auto_adjust: Ajustar preços por splits/dividendos (padrão: True)
# - back_adjust: Ajustar para trás (padrão: False)
# - prepost: Incluir pré e pós mercado (padrão: False)
# - repair: Reparar erros de dados (padrão: False)
```

**💡 Aplicação Prática**:
- **Gráficos**: Line chart, candlestick, área
- **Indicadores técnicos**: Médias móveis, RSI, MACD, Bollinger Bands
- **Volatilidade**: Calcular desvio padrão, beta
- **Backtesting**: Testar estratégias de trading
- **Correlação**: Comparar movimento de preços entre ações

**Exemplo de Cálculo de Indicador**:

```python
import pandas as pd

# Pega histórico
hist = ticker.history(period="1y")

# Calcula média móvel de 20 e 50 dias
hist['MA20'] = hist['Close'].rolling(window=20).mean()
hist['MA50'] = hist['Close'].rolling(window=50).mean()

# Calcula RSI (Relative Strength Index)
delta = hist['Close'].diff()
gain = (delta.where(delta > 0, 0)).rolling(window=14).mean()
loss = (-delta.where(delta < 0, 0)).rolling(window=14).mean()
rs = gain / loss
hist['RSI'] = 100 - (100 / (1 + rs))

# Identifica cruzamento de médias (sinal de compra/venda)
hist['Signal'] = 0
hist.loc[hist['MA20'] > hist['MA50'], 'Signal'] = 1  # Compra
hist.loc[hist['MA20'] < hist['MA50'], 'Signal'] = -1  # Venda
```

---

#### 1.3 Demonstrações Financeiras

**Referência**: `get_income_stmt()`, `get_balance_sheet()`, `get_cash_flow()`

**Aplicação**: Análise fundamentalista profunda, cálculo de múltiplos

```python
# 1. Demonstração de Resultados (DRE)
income_stmt = ticker.get_income_stmt()  # Anual
quarterly_income = ticker.quarterly_income_stmt  # Trimestral
ttm_income = ticker.ttm_income_stmt  # Trailing Twelve Months

# Principais linhas disponíveis:
"""
- TotalRevenue (Receita Total)
- CostOfRevenue (Custo da Receita)
- GrossProfit (Lucro Bruto)
- OperatingExpense (Despesas Operacionais)
- OperatingIncome (EBIT)
- InterestExpense (Despesas Financeiras)
- TaxProvision (Impostos)
- NetIncome (Lucro Líquido)
- EBITDA
- BasicEPS (Lucro por Ação)
- DilutedEPS
"""

# 2. Balanço Patrimonial
balance = ticker.get_balance_sheet()  # Anual
quarterly_balance = ticker.quarterly_balance_sheet  # Trimestral

# Principais linhas:
"""
ATIVOS:
- TotalAssets (Ativo Total)
- CurrentAssets (Ativo Circulante)
- CashAndCashEquivalents (Caixa)
- AccountsReceivable (Contas a Receber)
- Inventory (Estoque)
- PropertyPlantEquipment (Imobilizado)
- Goodwill (Ágio)
- IntangibleAssets (Intangíveis)

PASSIVOS:
- TotalLiabilities (Passivo Total)
- CurrentLiabilities (Passivo Circulante)
- LongTermDebt (Dívida de Longo Prazo)
- AccountsPayable (Contas a Pagar)

PATRIMÔNIO:
- StockholdersEquity (Patrimônio Líquido)
- RetainedEarnings (Lucros Acumulados)
- TreasuryStock (Ações em Tesouraria)
"""

# 3. Fluxo de Caixa
cashflow = ticker.get_cash_flow()  # Anual
quarterly_cashflow = ticker.quarterly_cashflow  # Trimestral

# Principais linhas:
"""
OPERACIONAL:
- OperatingCashFlow (Fluxo de Caixa Operacional)
- NetIncome (Lucro Líquido)
- DepreciationAndAmortization (Depreciação)
- ChangeInWorkingCapital (Variação Capital de Giro)

INVESTIMENTO:
- InvestingCashFlow
- CapitalExpenditure (CapEx)
- NetIntangiblesPurchaseAndSale
- NetBusinessPurchaseAndSale

FINANCIAMENTO:
- FinancingCashFlow
- DividendsPaid (Dividendos Pagos)
- NetIssuancePaymentsOfDebt
- NetCommonStockIssuance

- FreeCashFlow (Fluxo de Caixa Livre)
"""

# Exemplo de uso:
income = ticker.get_income_stmt()

# Pega receita do último ano
last_year_revenue = income.iloc[0]['TotalRevenue']

# Pega lucro líquido
last_year_net_income = income.iloc[0]['NetIncome']

# Calcula margem líquida
profit_margin = (last_year_net_income / last_year_revenue) * 100

print(f"Margem Líquida: {profit_margin:.2f}%")
```

**💡 Aplicação Prática**:
- **Análise de Crescimento**: Comparar receitas ano a ano
- **Análise de Margens**: Margem bruta, operacional, líquida
- **Análise de Liquidez**: Current ratio, Quick ratio
- **Análise de Endividamento**: Dívida/Patrimônio, Dívida/EBITDA
- **Valuation**: Calcular P/L, EV/EBITDA, P/VP
- **Free Cash Flow**: FCF, FCF Yield
- **Crescimento**: CAGR de receita, lucro

---

#### 1.4 Dividendos e Splits

**Referência**: `get_dividends()`, `get_splits()`, `get_actions()`

**Aplicação**: Análise de rendimento, histórico de pagamentos

```python
# Dividendos
dividends = ticker.get_dividends()

"""
Date
2023-08-15    1.35
2023-11-15    1.41
2024-02-15    1.38
2024-05-15    1.52
2024-08-15    1.45
Name: Dividends, dtype: float64
"""

# Splits
splits = ticker.get_splits()

"""
Date
2020-03-15    2.0  # Split 2:1
Name: Stock Splits, dtype: float64
"""

# Todas as ações corporativas
actions = ticker.get_actions()

"""
            Dividends  Stock Splits
Date
2023-08-15       1.35           0.0
2024-02-15       1.38           0.0
"""

# Análises úteis:
dividends_df = dividends.to_frame()
dividends_df['Year'] = dividends_df.index.year

# Dividendos por ano
annual_dividends = dividends_df.groupby('Year')['Dividends'].sum()

# Taxa de crescimento de dividendos
dividend_growth = annual_dividends.pct_change().mean()

# Frequência de pagamento
payment_frequency = len(dividends) / len(dividends_df['Year'].unique())

print(f"Crescimento médio de dividendos: {dividend_growth*100:.2f}%/ano")
print(f"Pagamentos por ano: {payment_frequency:.1f}")
```

**💡 Aplicação Prática**:
- **Dividend Screener**: Encontrar ações com alto yield
- **Dividend Growth**: Ações com crescimento consistente de dividendos
- **Calendário de Dividendos**: Próximos pagamentos
- **Total Return**: Retorno incluindo dividendos reinvestidos
- **Payout Ratio**: Dividendos / Lucro

---

#### 1.5 Recomendações de Analistas

**Referência**: `get_recommendations()`, `get_analyst_price_targets()`

**Aplicação**: Sentiment analysis, consenso de mercado

```python
# Recomendações
recommendations = ticker.get_recommendations()

"""
                        Firm         To Grade  From Grade Action
Date
2024-01-15  Morgan Stanley      Overweight  Equal-weight   main
2024-02-20        Goldman         Buy             Hold   main
2024-03-10       Barclays         Buy              Buy   main
"""

# Preços-alvo
targets = ticker.get_analyst_price_targets()

"""
{
    'current': 62.45,
    'low': 65.0,
    'high': 95.0,
    'mean': 82.5,
    'median': 82.0
}
"""

# Análise de consenso:
rec_counts = recommendations['To Grade'].value_counts()

# Média de recomendações (1=Strong Buy, 5=Strong Sell)
rec_map = {
    'Strong Buy': 1,
    'Buy': 2,
    'Hold': 3,
    'Sell': 4,
    'Strong Sell': 5
}

recommendations['Score'] = recommendations['To Grade'].map(rec_map)
consensus_score = recommendations['Score'].mean()

if consensus_score <= 1.5:
    consensus = "Compra Forte"
elif consensus_score <= 2.5:
    consensus = "Compra"
elif consensus_score <= 3.5:
    consensus = "Neutro"
else:
    consensus = "Venda"
```

**💡 Aplicação Prática**:
- **Consenso de Mercado**: Mostrar recomendação média
- **Preço Alvo**: Upside/downside potencial
- **Tracking**: Acompanhar mudanças de recomendação
- **Alertas**: Notificar quando recomendação muda

---

#### 1.6 Holders (Acionistas)

**Referência**: `get_major_holders()`, `get_institutional_holders()`, `get_insider_transactions()`

**Aplicação**: Análise de propriedade, insider trading

```python
# Principais acionistas (resumo)
major = ticker.get_major_holders()

"""
                                      0                                1
0                             40.23%  % of Shares Held by All Insider
1                             52.67%  % of Shares Held by Institutions
2                             56.89%  % of Float Held by Institutions
3                               1250  Number of Institutions Holding Shares
"""

# Acionistas institucionais (detalhado)
institutional = ticker.get_institutional_holders()

"""
                    Holder    Shares  Date Reported   % Out        Value
0           Vanguard Group  458900000     2024-09-30  0.1001  28670000000
1         BlackRock Inc.   425000000     2024-09-30  0.0927  26580000000
2     Capital World Inv   312000000     2024-09-30  0.0680  19520000000
"""

# Transações de insiders
insider = ticker.get_insider_transactions()

"""
        Shares  Value       Insider           Transaction                     Start Date
0      -50000    NaN   CEO - Silva      Sale           2024-11-15
1      100000    NaN   CFO - Santos     Purchase       2024-10-20
"""
```

**💡 Aplicação Prática**:
- **Confiança Institucional**: Alta % institucional = confiança
- **Insider Activity**: Compras de insiders = sinal positivo
- **Concentração**: Risco de concentração de acionistas
- **Sentiment**: Tracking de movimentos de grandes players

---

#### 1.7 Notícias

**Referência**: `get_news(count)`

**Aplicação**: Feed de notícias, sentiment analysis

```python
# Últimas notícias
news = ticker.get_news(count=10)

"""
[
    {
        'uuid': 'abc123',
        'title': 'Vale anuncia investimento de R$ 5 bi em nova mina',
        'publisher': 'InfoMoney',
        'link': 'https://...',
        'providerPublishTime': 1700000000,
        'type': 'STORY',
        'thumbnail': {'resolutions': [...]},
        'relatedTickers': ['VALE3.SA']
    },
    ...
]
"""

# Análise de sentiment (básica)
positive_keywords = ['investimento', 'crescimento', 'lucro', 'alta', 'forte']
negative_keywords = ['queda', 'perda', 'prejuízo', 'baixa', 'risco']

for article in news:
    title = article['title'].lower()
    sentiment = 'neutral'

    if any(word in title for word in positive_keywords):
        sentiment = 'positive'
    elif any(word in title for word in negative_keywords):
        sentiment = 'negative'

    article['sentiment'] = sentiment
```

**💡 Aplicação Prática**:
- **Feed de Notícias**: Mostrar no detalhe da ação
- **Alertas**: Notificar sobre notícias importantes
- **Sentiment Analysis**: Análise automática de sentimento
- **Timeline**: Linha do tempo de eventos

---

#### 1.8 Earnings (Resultados)

**Referência**: `get_earnings()`, `get_earnings_dates()`

**Aplicação**: Calendário de resultados, análise de surpresas

```python
# Earnings históricos
earnings = ticker.get_earnings()

"""
      Revenue      Earnings
Year
2020  1.45e+11  3.2e+10
2021  1.78e+11  6.8e+10
2022  1.92e+11  7.5e+10
2023  1.85e+11  6.2e+10
"""

# Datas de earnings (futuras e passadas)
earnings_dates = ticker.get_earnings_dates()

"""
                    Earnings Date  EPS Estimate  Reported EPS  Surprise(%)
2024-10-30 12:00:00  2024-10-30         3.45          3.78         9.6
2024-07-25 12:00:00  2024-07-25         3.20          3.42         6.9
"""

# Análise de surpresas
positive_surprises = earnings_dates[earnings_dates['Surprise(%)'] > 0]
avg_surprise = earnings_dates['Surprise(%)'].mean()

print(f"Média de surpresa: {avg_surprise:.2f}%")
```

**💡 Aplicação Prática**:
- **Calendário de Earnings**: Próximas divulgações
- **Track Record**: Histórico de bater/perder estimativas
- **Surpresa Média**: Tendência de superar expectativas
- **Alertas**: Notificar antes da divulgação

---

### 2. **download()** - Download em Massa

**Referência**: `yfinance.download(tickers, ...)`

**Aplicação**: Atualização eficiente de múltiplas ações

```python
import yfinance as yf

# Lista de tickers
tickers = ['VALE3.SA', 'PETR4.SA', 'ITUB4.SA', 'BBDC4.SA']

# Download de múltiplas ações simultaneamente
data = yf.download(
    tickers=tickers,
    period='1mo',
    interval='1d',
    group_by='ticker',  # Agrupa por ticker
    auto_adjust=True,   # Ajusta por splits/dividendos
    threads=True,       # Download paralelo (muito mais rápido!)
    progress=True       # Mostra barra de progresso
)

# Acessa dados de cada ticker
vale_data = data['VALE3.SA']
petr_data = data['PETR4.SA']

# Ou itera sobre todos
for ticker in tickers:
    ticker_data = data[ticker]
    latest_close = ticker_data['Close'].iloc[-1]
    print(f"{ticker}: R$ {latest_close:.2f}")

# Parâmetros importantes:
# - period: '1d', '5d', '1mo', '3mo', '6mo', '1y', '2y', '5y', '10y', 'ytd', 'max'
# - interval: '1m', '2m', '5m', '15m', '30m', '1h', '1d', '5d', '1wk', '1mo', '3mo'
# - start/end: Datas específicas ('YYYY-MM-DD')
# - actions: Incluir dividendos e splits
# - repair: Reparar dados quebrados
# - keepna: Manter NaNs
```

**💡 Performance**:
- Download de 1 ticker: ~1-2 segundos
- Download de 50 tickers com `threads=True`: ~3-5 segundos
- Download de 50 tickers sem `threads`: ~50-100 segundos

**Aplicação Prática**:
- **Worker Jobs**: Atualizar todas as ações do banco diariamente
- **Screener**: Baixar dados de todas as ações da B3
- **Comparação**: Comparar performance de múltiplas ações
- **Portfolio**: Atualizar preços de carteira

---

### 3. **Screener** - Filtrar Ações

**Referência**: `yfinance.screen(query, ...)`

**Aplicação**: Encontrar ações baratas automaticamente

```python
import yfinance as yf
from yfinance import EquityQuery

# 1. Screeners Predefinidos
predefined_screeners = [
    'undervalued_growth_stocks',   # IDEAL PARA "AÇÕES BARATAS"!
    'day_gainers',
    'day_losers',
    'most_active',
    'undervalued_large_caps',
    'aggressive_small_caps',
    'small_cap_gainers',
    'growth_technology_stocks',
    'conservative_foreign_funds',
    'high_yield_bond',
]

# Usar screener predefinido
result = yf.screen('undervalued_growth_stocks')

# Resultado:
"""
{
    'quotes': [
        {
            'symbol': 'VALE3.SA',
            'shortName': 'VALE ON',
            'regularMarketPrice': 62.45,
            'regularMarketChangePercent': 2.01,
            'regularMarketVolume': 45678000,
            'marketCap': 286500000000,
            'trailingPE': 4.2,
            'dividendYield': 0.085,
            'sector': 'Basic Materials',
            ...
        },
        ...
    ],
    'count': 25,
    'start': 0,
    'total': 25
}
"""

# 2. Query Customizada Simples
query = EquityQuery('and', [
    EquityQuery('lte', ['trailingPE', 10]),        # P/L <= 10
    EquityQuery('gte', ['dividendYield', 0.05]),   # Div Yield >= 5%
    EquityQuery('eq', ['region', 'br'])            # Brasil
])

result = yf.screen(query, size=50)

# 3. Query Complexa (Múltiplos Critérios)
query = EquityQuery('and', [
    # Valuation
    EquityQuery('lte', ['trailingPE', 10]),
    EquityQuery('lte', ['priceToBook', 1.5]),
    EquityQuery('lte', ['pegRatio', 1]),

    # Dividendos
    EquityQuery('gte', ['dividendYield', 0.05]),

    # Tamanho
    EquityQuery('gte', ['marketCap', 1_000_000_000]),

    # Profitabilidade
    EquityQuery('gte', ['returnOnEquity', 0.15]),

    # Saúde Financeira
    EquityQuery('lte', ['debtToEquity', 0.8]),

    # Região
    EquityQuery('eq', ['region', 'br'])
])

result = yf.screen(
    query,
    size=250,              # Máximo de resultados
    sortField='trailingPE',  # Ordenar por P/L
    sortAsc=True           # Crescente (menor P/L primeiro)
)

# 4. Operadores Disponíveis
operators = {
    'eq': 'Igual',               # ==
    'gt': 'Maior que',           # >
    'lt': 'Menor que',           # <
    'gte': 'Maior ou igual',     # >=
    'lte': 'Menor ou igual',     # <=
    'btwn': 'Entre',             # between
    'is-in': 'Está em lista',    # in []
}

# 5. Campos de Filtro Disponíveis
filter_fields = {
    # Preço e Volume
    'regularMarketPrice': 'Preço',
    'regularMarketVolume': 'Volume',
    'averageVolume': 'Volume Médio',

    # Valuation
    'trailingPE': 'P/L (Trailing)',
    'forwardPE': 'P/L (Forward)',
    'pegRatio': 'PEG Ratio',
    'priceToBook': 'P/VP',
    'priceToSales': 'P/Vendas',
    'enterpriseToEbitda': 'EV/EBITDA',
    'enterpriseToRevenue': 'EV/Receita',

    # Crescimento
    'revenueGrowth': 'Crescimento Receita',
    'earningsGrowth': 'Crescimento Lucro',

    # Profitabilidade
    'returnOnAssets': 'ROA',
    'returnOnEquity': 'ROE',
    'profitMargins': 'Margem Líquida',
    'operatingMargins': 'Margem Operacional',
    'grossMargins': 'Margem Bruta',

    # Dividendos
    'dividendYield': 'Dividend Yield',
    'payoutRatio': 'Payout Ratio',

    # Saúde Financeira
    'debtToEquity': 'Dívida/Patrimônio',
    'currentRatio': 'Liquidez Corrente',
    'quickRatio': 'Liquidez Seca',

    # Tamanho
    'marketCap': 'Market Cap',
    'enterpriseValue': 'Valor da Empresa',

    # Localização
    'region': 'Região (br, us, etc.)',
    'sector': 'Setor',
    'industry': 'Indústria',
    'exchange': 'Bolsa',

    # Outros
    'beta': 'Beta',
    'percentChange': 'Variação %',
}
```

**💡 Aplicação Prática**:

**Sistema "Ações Baratas"**:

```python
def find_cheap_stocks():
    """
    Encontra ações baratas com múltiplos critérios
    """

    # Critérios para "ações baratas"
    query = EquityQuery('and', [
        # 1. Valuation atrativo
        EquityQuery('lte', ['trailingPE', 10]),    # P/L baixo
        EquityQuery('lte', ['pegRatio', 1]),       # PEG < 1 (crescimento > P/L)
        EquityQuery('lte', ['priceToBook', 1.5]),  # P/VP baixo

        # 2. Bons dividendos
        EquityQuery('gte', ['dividendYield', 0.05]),  # Yield >= 5%

        # 3. Rentabilidade saudável
        EquityQuery('gte', ['returnOnEquity', 0.12]),  # ROE >= 12%

        # 4. Endividamento controlado
        EquityQuery('lte', ['debtToEquity', 1.0]),  # Dívida/PL <= 100%

        # 5. Tamanho mínimo (evita empresas muito pequenas)
        EquityQuery('gte', ['marketCap', 1_000_000_000]),  # >= 1 bilhão

        # 6. Brasil
        EquityQuery('eq', ['region', 'br'])
    ])

    result = yf.screen(
        query,
        size=250,
        sortField='trailingPE',
        sortAsc=True
    )

    return result['quotes']

# Executar
cheap_stocks = find_cheap_stocks()
print(f"Encontradas {len(cheap_stocks)} ações subvalorizadas!")
```

---

### 4. **Search** - Busca de Ações

**Referência**: `yfinance.Search(query, ...)`

**Aplicação**: Autocomplete, busca inteligente

```python
from yfinance import Search

# Busca básica
search = Search('Vale')

# Resultados
search.quotes  # Lista de ações encontradas
"""
[
    {
        'symbol': 'VALE3.SA',
        'shortname': 'VALE ON',
        'longname': 'Vale S.A.',
        'exchange': 'SAO',
        'quoteType': 'EQUITY',
        'sector': 'Basic Materials',
        ...
    },
    {
        'symbol': 'VALE',
        'shortname': 'Vale SA',
        'exchange': 'NYSE',
        ...
    }
]
"""

search.news  # Notícias relacionadas
search.lists  # Listas de ações
search.research  # Relatórios de pesquisa

# Busca com opções
search = Search(
    query='petrobras',
    max_results=10,        # Máximo de resultados
    news_count=5,          # Número de notícias
    enable_fuzzy_query=True,  # Tolera erros de digitação
    enable_nav_links=True,
    enable_enhance_query=True
)

# Para autocomplete no frontend
def autocomplete(query):
    """
    Retorna sugestões para autocomplete
    """
    if len(query) < 2:
        return []

    search = Search(query, max_results=5)

    suggestions = []
    for quote in search.quotes:
        suggestions.append({
            'value': quote['symbol'],
            'label': f"{quote['symbol']} - {quote.get('shortname', '')}",
            'type': quote.get('quoteType', 'EQUITY'),
            'exchange': quote.get('exchange', '')
        })

    return suggestions
```

**💡 Aplicação Prática**:
- **Autocomplete**: Sugestões enquanto usuário digita
- **Busca Inteligente**: Busca por nome ou ticker
- **Multi-resultado**: Mostra ações de diferentes bolsas
- **Notícias**: Integra notícias na busca

---

### 5. **Sector & Industry** - Análise Setorial

**Referência**: `yfinance.Sector(key)`, `yfinance.Industry(key)`

```python
import yfinance as yf

# Análise de setor
sector = yf.Sector('Basic Materials')

# Informações do setor
sector.key            # 'basic-materials'
sector.name           # 'Basic Materials'
sector.symbol         # Símbolo do índice do setor
sector.overview       # Visão geral
sector.top_companies  # Principais empresas

# Top ETFs do setor
sector.top_etfs
"""
[
    {'symbol': 'XLB', 'name': 'Materials Select Sector SPDR Fund'},
    ...
]
"""

# Top fundos mútuos
sector.top_mutual_funds

# Pesquisa no setor
sector.research_reports

# Indústria específica
industry = yf.Industry('steel')

industry.top_companies
"""
[
    {'symbol': 'VALE3.SA', 'name': 'Vale S.A.'},
    {'symbol': 'CSN3.SA', 'name': 'CSN'},
    ...
]
"""
```

**💡 Aplicação Prática**:
- **Análise Setorial**: Comparar ação com setor
- **Diversificação**: Sugerir ações de diferentes setores
- **Rotação Setorial**: Identificar setores em alta
- **Benchmarking**: Comparar métricas com média do setor

---

## 🎯 Casos de Uso para "Ações Baratas da Bolsa"

### 1. **Screener Inteligente**

```python
def ultimate_value_screener():
    """
    Screener definitivo para encontrar ações baratas
    """

    # Critérios múltiplos
    criteria = {
        # Graham (Value Investing Clássico)
        'max_pe': 10,
        'max_pb': 1.5,
        'min_dividend': 5,

        # Qualidade
        'min_roe': 15,
        'min_current_ratio': 1.5,
        'max_debt_equity': 0.5,

        # Crescimento
        'min_revenue_growth': 0,
        'max_peg': 1,

        # Liquidez
        'min_market_cap': 1_000_000_000,
        'min_avg_volume': 500_000,
    }

    query = EquityQuery('and', [
        EquityQuery('lte', ['trailingPE', criteria['max_pe']]),
        EquityQuery('lte', ['priceToBook', criteria['max_pb']]),
        EquityQuery('gte', ['dividendYield', criteria['min_dividend'] / 100]),
        EquityQuery('gte', ['returnOnEquity', criteria['min_roe'] / 100]),
        EquityQuery('lte', ['debtToEquity', criteria['max_debt_equity']]),
        EquityQuery('gte', ['marketCap', criteria['min_market_cap']]),
        EquityQuery('eq', ['region', 'br'])
    ])

    return yf.screen(query, size=250, sortField='trailingPE')
```

### 2. **Score de Subvalorização**

```python
def calculate_undervaluation_score(ticker):
    """
    Calcula score 0-100 de subvalorização
    """
    stock = yf.Ticker(ticker)
    info = stock.info

    score = 0

    # P/L (25 pontos)
    pe = info.get('trailingPE', 999)
    if pe < 5: score += 25
    elif pe < 8: score += 20
    elif pe < 12: score += 15
    elif pe < 15: score += 10

    # PEG (20 pontos)
    peg = info.get('pegRatio', 999)
    if peg < 0.5: score += 20
    elif peg < 1: score += 15
    elif peg < 1.5: score += 10

    # Dividend Yield (20 pontos)
    div = info.get('dividendYield', 0) * 100
    if div > 10: score += 20
    elif div > 7: score += 15
    elif div > 5: score += 10

    # P/VP (15 pontos)
    pb = info.get('priceToBook', 999)
    if pb < 1: score += 15
    elif pb < 1.5: score += 10
    elif pb < 2: score += 5

    # ROE (10 pontos)
    roe = info.get('returnOnEquity', 0) * 100
    if roe > 20: score += 10
    elif roe > 15: score += 7
    elif roe > 10: score += 4

    # Dívida (10 pontos)
    debt = info.get('debtToEquity', 999)
    if debt < 30: score += 10
    elif debt < 50: score += 7
    elif debt < 80: score += 4

    return score
```

### 3. **Ranking de Ações**

```python
def rank_stocks(tickers):
    """
    Ranqueia ações por múltiplos critérios
    """
    scores = []

    for ticker in tickers:
        try:
            score = {
                'ticker': ticker,
                'undervaluation_score': calculate_undervaluation_score(ticker),
                'value_score': calculate_value_score(ticker),
                'quality_score': calculate_quality_score(ticker),
                'momentum_score': calculate_momentum_score(ticker),
            }

            # Score final (média ponderada)
            score['final_score'] = (
                score['undervaluation_score'] * 0.4 +
                score['value_score'] * 0.3 +
                score['quality_score'] * 0.2 +
                score['momentum_score'] * 0.1
            )

            scores.append(score)

        except Exception as e:
            print(f"Error processing {ticker}: {e}")

    # Ordena por score final
    scores.sort(key=lambda x: x['final_score'], reverse=True)

    return scores
```

---

## 🚀 Limitações e Considerações

### Limitações do yfinance:

1. **Rate Limiting**:
   - Yahoo Finance pode bloquear após muitas requisições
   - Solução: Implementar cache e rate limiting

2. **Dados Atrasados**:
   - Preços têm delay de ~15 minutos (não é real-time)
   - Solução: Usar WebSocket para dados em tempo real (premium)

3. **Inconsistências**:
   - Alguns campos podem estar ausentes ou desatualizados
   - Solução: Validação e fallbacks

4. **Nomenclatura B3**:
   - Ações brasileiras precisam de `.SA` no final
   - Exemplo: `VALE3.SA`, não apenas `VALE3`

5. **Sem Garantias**:
   - API não oficial, pode mudar sem aviso
   - Solução: Tratamento robusto de erros

### Boas Práticas:

```python
# 1. Use cache
from functools import lru_cache

@lru_cache(maxsize=128)
def get_stock_info_cached(ticker, ttl_hash=None):
    return yf.Ticker(ticker).info

# 2. Tratamento de erros
def safe_get_info(ticker):
    try:
        stock = yf.Ticker(ticker)
        return stock.info
    except Exception as e:
        logger.error(f"Error fetching {ticker}: {e}")
        return None

# 3. Retry logic
from tenacity import retry, stop_after_attempt, wait_exponential

@retry(stop=stop_after_attempt(3), wait=wait_exponential(multiplier=1, min=4, max=10))
def robust_fetch(ticker):
    return yf.Ticker(ticker).info

# 4. Rate limiting
import time
from datetime import datetime

class RateLimiter:
    def __init__(self, max_calls_per_minute=60):
        self.max_calls = max_calls_per_minute
        self.calls = []

    def wait_if_needed(self):
        now = datetime.now()
        # Remove chamadas antigas (> 1 minuto)
        self.calls = [call for call in self.calls if (now - call).seconds < 60]

        if len(self.calls) >= self.max_calls:
            sleep_time = 60 - (now - self.calls[0]).seconds
            time.sleep(sleep_time)

        self.calls.append(now)

limiter = RateLimiter()

def fetch_with_limit(ticker):
    limiter.wait_if_needed()
    return yf.Ticker(ticker).info
```

---

## 📚 Recursos e Referências

### Documentação Oficial
- **Site**: https://ranaroussi.github.io/yfinance/
- **GitHub**: https://github.com/ranaroussi/yfinance
- **PyPI**: https://pypi.org/project/yfinance/

### Tutoriais
- [Getting Started Guide](https://ranaroussi.github.io/yfinance/guide/quickstart.html)
- [API Reference](https://ranaroussi.github.io/yfinance/reference/index.html)

### Comunidade
- Issues: https://github.com/ranaroussi/yfinance/issues
- Discussions: https://github.com/ranaroussi/yfinance/discussions

---

## ✅ Checklist de Implementação

### Fase 1: Setup
- [ ] Instalar yfinance: `pip install yfinance`
- [ ] Testar conexão básica
- [ ] Configurar cache (Redis)
- [ ] Implementar rate limiting

### Fase 2: Core Features
- [ ] Wrapper service para yfinance
- [ ] Endpoints de stocks
- [ ] Screener customizado
- [ ] Sistema de cache inteligente

### Fase 3: Features Avançadas
- [ ] Worker para atualização automática
- [ ] Análise fundamentalista
- [ ] Sistema de scoring
- [ ] Ranking de ações

### Fase 4: Otimização
- [ ] Cache multi-layer
- [ ] Retry logic
- [ ] Error handling robusto
- [ ] Logging completo

---

**Documento criado para "Ações Baratas da Bolsa"**
**Versão**: 2.0 Completa
**Data**: Novembro 2024
