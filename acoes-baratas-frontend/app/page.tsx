'use client'

import { useState } from 'react'
import { MarketStats } from '@/components/MarketStats'
import { StockCard } from '@/components/StockCard'
import { StockTable } from '@/components/StockTable'
import { PriceChart } from '@/components/PriceChart'
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from '@/components/ui/card'
import { Button } from '@/components/ui/button'
import { Badge } from '@/components/ui/badge'
import { mockStocks, mockHistoricalData, mockStockDetail, mockDividends, mockNews, Stock } from '@/lib/mockData'
import { formatCurrency, formatPercent, formatLargeNumber, getBgColorByValue } from '@/lib/utils'
import {
  LayoutGrid,
  List,
  TrendingUp,
  DollarSign,
  Calendar,
  Newspaper,
  BarChart3,
  Building2,
  Users,
  Award,
  Target,
} from 'lucide-react'

export default function Home() {
  const [viewMode, setViewMode] = useState<'grid' | 'table'>('grid')
  const [selectedStock, setSelectedStock] = useState<Stock | null>(null)

  return (
    <div className="container py-8 space-y-8">
      {/* Hero Section */}
      <section className="space-y-4">
        <div className="flex items-center justify-between">
          <div className="space-y-2">
            <h1 className="text-4xl font-bold tracking-tight">
              Ações Baratas da Bolsa 📈
            </h1>
            <p className="text-lg text-muted-foreground">
              Descubra oportunidades subvalorizadas com análise fundamentalista profunda
            </p>
          </div>
          <div className="flex items-center space-x-2">
            <Button
              variant={viewMode === 'grid' ? 'default' : 'outline'}
              size="icon"
              onClick={() => setViewMode('grid')}
            >
              <LayoutGrid className="h-4 w-4" />
            </Button>
            <Button
              variant={viewMode === 'table' ? 'default' : 'outline'}
              size="icon"
              onClick={() => setViewMode('table')}
            >
              <List className="h-4 w-4" />
            </Button>
          </div>
        </div>
      </section>

      {/* Market Statistics */}
      <section>
        <MarketStats />
      </section>

      {/* Filters */}
      <section>
        <Card>
          <CardHeader>
            <CardTitle className="text-lg">Filtros Inteligentes</CardTitle>
          </CardHeader>
          <CardContent>
            <div className="flex flex-wrap gap-2">
              <Badge variant="outline" className="cursor-pointer hover:bg-primary hover:text-white transition-colors">
                P/L {'<'} 10
              </Badge>
              <Badge variant="outline" className="cursor-pointer hover:bg-primary hover:text-white transition-colors">
                Dividend Yield {'>'} 5%
              </Badge>
              <Badge variant="outline" className="cursor-pointer hover:bg-primary hover:text-white transition-colors">
                Market Cap {'>'} 1B
              </Badge>
              <Badge variant="outline" className="cursor-pointer hover:bg-primary hover:text-white transition-colors">
                Setor Financeiro
              </Badge>
              <Badge variant="outline" className="cursor-pointer hover:bg-primary hover:text-white transition-colors">
                Energia Elétrica
              </Badge>
              <Badge variant="outline" className="cursor-pointer hover:bg-primary hover:text-white transition-colors">
                Subvalorizadas
              </Badge>
            </div>
          </CardContent>
        </Card>
      </section>

      {/* Main Content */}
      {selectedStock ? (
        /* Stock Detail View */
        <section className="space-y-6">
          <div className="flex items-center justify-between">
            <div className="space-y-1">
              <div className="flex items-center space-x-3">
                <h2 className="text-3xl font-bold">{selectedStock.ticker}</h2>
                <Badge variant="success">Subvalorizada</Badge>
                <Badge variant="outline">{mockStockDetail.analystRating}</Badge>
              </div>
              <p className="text-lg text-muted-foreground">{selectedStock.name}</p>
            </div>
            <Button variant="outline" onClick={() => setSelectedStock(null)}>
              Voltar
            </Button>
          </div>

          {/* Price Info */}
          <Card>
            <CardContent className="pt-6">
              <div className="flex items-baseline space-x-4">
                <div className="text-5xl font-bold">{formatCurrency(selectedStock.price)}</div>
                <div className={`flex items-center text-xl font-semibold ${getBgColorByValue(selectedStock.changePercent)} rounded-lg px-3 py-1.5`}>
                  {selectedStock.changePercent >= 0 ? <TrendingUp className="mr-2 h-5 w-5" /> : <TrendingUp className="mr-2 h-5 w-5 rotate-180" />}
                  {formatPercent(selectedStock.changePercent)}
                </div>
              </div>
              <div className="mt-4 grid grid-cols-2 md:grid-cols-4 gap-4 text-sm">
                <div>
                  <span className="text-muted-foreground">Abertura: </span>
                  <span className="font-semibold">{formatCurrency(selectedStock.price * 0.98)}</span>
                </div>
                <div>
                  <span className="text-muted-foreground">Máx. 52s: </span>
                  <span className="font-semibold">{formatCurrency(selectedStock.week52High)}</span>
                </div>
                <div>
                  <span className="text-muted-foreground">Mín. 52s: </span>
                  <span className="font-semibold">{formatCurrency(selectedStock.week52Low)}</span>
                </div>
                <div>
                  <span className="text-muted-foreground">Volume: </span>
                  <span className="font-semibold">{formatLargeNumber(selectedStock.volume)}</span>
                </div>
              </div>
            </CardContent>
          </Card>

          {/* Price Chart */}
          <PriceChart data={mockHistoricalData} />

          {/* Key Metrics */}
          <div className="grid gap-6 md:grid-cols-2 lg:grid-cols-3">
            <Card>
              <CardHeader>
                <CardTitle className="flex items-center text-lg">
                  <DollarSign className="mr-2 h-5 w-5 text-primary" />
                  Valuation
                </CardTitle>
              </CardHeader>
              <CardContent className="space-y-3">
                <div className="flex justify-between">
                  <span className="text-muted-foreground">P/L (Price/Earnings)</span>
                  <span className="font-semibold">{mockStockDetail.pe.toFixed(1)}x</span>
                </div>
                <div className="flex justify-between">
                  <span className="text-muted-foreground">P/VP (Price/Book)</span>
                  <span className="font-semibold">{mockStockDetail.priceToBook.toFixed(2)}x</span>
                </div>
                <div className="flex justify-between">
                  <span className="text-muted-foreground">PEG Ratio</span>
                  <span className="font-semibold text-success">{mockStockDetail.peg.toFixed(2)}</span>
                </div>
                <div className="flex justify-between">
                  <span className="text-muted-foreground">P/Vendas</span>
                  <span className="font-semibold">{mockStockDetail.priceToSales.toFixed(2)}x</span>
                </div>
                <div className="flex justify-between">
                  <span className="text-muted-foreground">EV/EBITDA</span>
                  <span className="font-semibold">{mockStockDetail.evToEbitda.toFixed(2)}x</span>
                </div>
              </CardContent>
            </Card>

            <Card>
              <CardHeader>
                <CardTitle className="flex items-center text-lg">
                  <BarChart3 className="mr-2 h-5 w-5 text-primary" />
                  Rentabilidade
                </CardTitle>
              </CardHeader>
              <CardContent className="space-y-3">
                <div className="flex justify-between">
                  <span className="text-muted-foreground">ROE (Return on Equity)</span>
                  <span className="font-semibold text-success">{mockStockDetail.roe.toFixed(1)}%</span>
                </div>
                <div className="flex justify-between">
                  <span className="text-muted-foreground">ROA (Return on Assets)</span>
                  <span className="font-semibold text-success">{mockStockDetail.roa.toFixed(1)}%</span>
                </div>
                <div className="flex justify-between">
                  <span className="text-muted-foreground">Margem Operacional</span>
                  <span className="font-semibold">{mockStockDetail.operatingMargin.toFixed(1)}%</span>
                </div>
                <div className="flex justify-between">
                  <span className="text-muted-foreground">Margem Líquida</span>
                  <span className="font-semibold">{mockStockDetail.profitMargin.toFixed(1)}%</span>
                </div>
                <div className="flex justify-between">
                  <span className="text-muted-foreground">Dividend Yield</span>
                  <span className="font-semibold text-success">{mockStockDetail.dividendYield.toFixed(1)}%</span>
                </div>
              </CardContent>
            </Card>

            <Card>
              <CardHeader>
                <CardTitle className="flex items-center text-lg">
                  <Building2 className="mr-2 h-5 w-5 text-primary" />
                  Solidez Financeira
                </CardTitle>
              </CardHeader>
              <CardContent className="space-y-3">
                <div className="flex justify-between">
                  <span className="text-muted-foreground">Dívida/Patrimônio</span>
                  <span className="font-semibold text-success">{mockStockDetail.debtToEquity.toFixed(2)}</span>
                </div>
                <div className="flex justify-between">
                  <span className="text-muted-foreground">Liquidez Corrente</span>
                  <span className="font-semibold">{mockStockDetail.currentRatio.toFixed(2)}</span>
                </div>
                <div className="flex justify-between">
                  <span className="text-muted-foreground">Beta</span>
                  <span className="font-semibold">{mockStockDetail.beta.toFixed(2)}</span>
                </div>
                <div className="flex justify-between">
                  <span className="text-muted-foreground">Market Cap</span>
                  <span className="font-semibold">{formatCurrency(mockStockDetail.marketCap)}</span>
                </div>
                <div className="flex justify-between">
                  <span className="text-muted-foreground">Setor</span>
                  <span className="font-semibold">{mockStockDetail.sector}</span>
                </div>
              </CardContent>
            </Card>
          </div>

          {/* Dividends & News */}
          <div className="grid gap-6 md:grid-cols-2">
            <Card>
              <CardHeader>
                <CardTitle className="flex items-center text-lg">
                  <Calendar className="mr-2 h-5 w-5 text-primary" />
                  Histórico de Dividendos
                </CardTitle>
                <CardDescription>Últimos 6 pagamentos</CardDescription>
              </CardHeader>
              <CardContent>
                <div className="space-y-3">
                  {mockDividends.map((dividend, idx) => (
                    <div key={idx} className="flex items-center justify-between py-2 border-b last:border-0">
                      <span className="text-sm text-muted-foreground">
                        {new Date(dividend.date).toLocaleDateString('pt-BR')}
                      </span>
                      <span className="font-semibold text-success">
                        {formatCurrency(dividend.value)}
                      </span>
                    </div>
                  ))}
                </div>
              </CardContent>
            </Card>

            <Card>
              <CardHeader>
                <CardTitle className="flex items-center text-lg">
                  <Newspaper className="mr-2 h-5 w-5 text-primary" />
                  Notícias Recentes
                </CardTitle>
              </CardHeader>
              <CardContent>
                <div className="space-y-4">
                  {mockNews.slice(0, 4).map((news) => (
                    <div key={news.id} className="space-y-1">
                      <h4 className="text-sm font-medium leading-tight hover:text-primary cursor-pointer transition-colors">
                        {news.title}
                      </h4>
                      <div className="flex items-center space-x-2 text-xs text-muted-foreground">
                        <span>{news.source}</span>
                        <span>•</span>
                        <span>{new Date(news.date).toLocaleDateString('pt-BR')}</span>
                      </div>
                    </div>
                  ))}
                </div>
              </CardContent>
            </Card>
          </div>

          {/* Analyst Info */}
          <Card>
            <CardHeader>
              <CardTitle className="flex items-center text-lg">
                <Target className="mr-2 h-5 w-5 text-primary" />
                Análise de Especialistas
              </CardTitle>
            </CardHeader>
            <CardContent>
              <div className="grid gap-6 md:grid-cols-3">
                <div className="space-y-2">
                  <p className="text-sm text-muted-foreground">Recomendação</p>
                  <Badge variant="success" className="text-base px-3 py-1">
                    {mockStockDetail.analystRating}
                  </Badge>
                </div>
                <div className="space-y-2">
                  <p className="text-sm text-muted-foreground">Preço Alvo</p>
                  <p className="text-2xl font-bold">{formatCurrency(mockStockDetail.targetPrice)}</p>
                  <p className="text-xs text-success">
                    Potencial de {((mockStockDetail.targetPrice / selectedStock.price - 1) * 100).toFixed(1)}%
                  </p>
                </div>
                <div className="space-y-2">
                  <p className="text-sm text-muted-foreground">Propriedade Institucional</p>
                  <p className="text-2xl font-bold">{mockStockDetail.institutionalOwnership.toFixed(1)}%</p>
                </div>
              </div>
            </CardContent>
          </Card>
        </section>
      ) : (
        /* Stock List View */
        <section className="space-y-6">
          <div>
            <h2 className="text-2xl font-bold mb-1">Ações Subvalorizadas</h2>
            <p className="text-muted-foreground">
              {mockStocks.length} ações com P/L abaixo de 10 e bom potencial de valorização
            </p>
          </div>

          {viewMode === 'grid' ? (
            <div className="grid gap-6 md:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4">
              {mockStocks.map((stock) => (
                <StockCard
                  key={stock.ticker}
                  stock={stock}
                  onClick={() => setSelectedStock(stock)}
                />
              ))}
            </div>
          ) : (
            <StockTable stocks={mockStocks} onStockClick={setSelectedStock} />
          )}
        </section>
      )}
    </div>
  )
}
