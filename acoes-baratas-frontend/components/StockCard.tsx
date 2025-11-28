'use client'

import { Card, CardContent, CardHeader, CardTitle } from './ui/card'
import { Badge } from './ui/badge'
import { TrendingUp, TrendingDown, DollarSign, Activity } from 'lucide-react'
import { Stock } from '@/lib/mockData'
import { formatCurrency, formatPercent, formatLargeNumber, getBgColorByValue } from '@/lib/utils'

interface StockCardProps {
  stock: Stock
  onClick?: () => void
}

export function StockCard({ stock, onClick }: StockCardProps) {
  const isPositive = stock.changePercent >= 0

  return (
    <Card
      className="overflow-hidden transition-all hover:shadow-xl cursor-pointer group"
      onClick={onClick}
    >
      <CardHeader className="pb-3">
        <div className="flex items-start justify-between">
          <div>
            <CardTitle className="text-lg font-bold group-hover:text-primary transition-colors">
              {stock.ticker}
            </CardTitle>
            <p className="text-sm text-muted-foreground mt-1 line-clamp-1">
              {stock.name}
            </p>
          </div>
          {stock.isUndervalued && (
            <Badge variant="success" className="text-xs">
              Subvalorizada
            </Badge>
          )}
        </div>
      </CardHeader>
      <CardContent className="space-y-4">
        <div className="flex items-baseline justify-between">
          <div>
            <div className="text-3xl font-bold">
              {formatCurrency(stock.price)}
            </div>
            <div className={`flex items-center mt-1 ${getBgColorByValue(stock.changePercent)} rounded-md px-2 py-1 inline-flex`}>
              {isPositive ? (
                <TrendingUp className="mr-1 h-3 w-3" />
              ) : (
                <TrendingDown className="mr-1 h-3 w-3" />
              )}
              <span className="text-sm font-semibold">
                {formatPercent(stock.changePercent)}
              </span>
            </div>
          </div>
        </div>

        <div className="grid grid-cols-2 gap-4">
          <div className="space-y-1">
            <div className="flex items-center text-xs text-muted-foreground">
              <DollarSign className="mr-1 h-3 w-3" />
              P/L
            </div>
            <div className="text-lg font-semibold">
              {stock.pe.toFixed(1)}x
            </div>
          </div>
          <div className="space-y-1">
            <div className="flex items-center text-xs text-muted-foreground">
              <TrendingUp className="mr-1 h-3 w-3" />
              Div. Yield
            </div>
            <div className="text-lg font-semibold text-success">
              {stock.dividendYield.toFixed(1)}%
            </div>
          </div>
        </div>

        <div className="border-t pt-3 space-y-2">
          <div className="flex justify-between text-xs">
            <span className="text-muted-foreground">Volume</span>
            <span className="font-medium">{formatLargeNumber(stock.volume)}</span>
          </div>
          <div className="flex justify-between text-xs">
            <span className="text-muted-foreground">Market Cap</span>
            <span className="font-medium">{formatCurrency(stock.marketCap)}</span>
          </div>
          <div className="flex justify-between text-xs">
            <span className="text-muted-foreground">Setor</span>
            <span className="font-medium">{stock.sector}</span>
          </div>
        </div>
      </CardContent>
    </Card>
  )
}
