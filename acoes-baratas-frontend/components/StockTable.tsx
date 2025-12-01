'use client'

import { useState } from 'react'
import { Stock } from '@/lib/mockData'
import { formatCurrency, formatPercent, formatLargeNumber, getBgColorByValue } from '@/lib/utils'
import { Card } from './ui/card'
import { Badge } from './ui/badge'
import { ArrowUpDown, TrendingUp, TrendingDown } from 'lucide-react'

interface StockTableProps {
  stocks: Stock[]
  onStockClick?: (stock: Stock) => void
}

type SortField = 'ticker' | 'price' | 'change' | 'pe' | 'dividend' | 'volume' | 'marketCap'
type SortDirection = 'asc' | 'desc'

export function StockTable({ stocks, onStockClick }: StockTableProps) {
  const [sortField, setSortField] = useState<SortField>('pe')
  const [sortDirection, setSortDirection] = useState<SortDirection>('asc')

  const handleSort = (field: SortField) => {
    if (sortField === field) {
      setSortDirection(sortDirection === 'asc' ? 'desc' : 'asc')
    } else {
      setSortField(field)
      setSortDirection('asc')
    }
  }

  const sortedStocks = [...stocks].sort((a, b) => {
    let aValue = a[sortField as keyof Stock]
    let bValue = b[sortField as keyof Stock]

    if (typeof aValue === 'string') aValue = aValue.toLowerCase()
    if (typeof bValue === 'string') bValue = bValue.toLowerCase()

    if (sortDirection === 'asc') {
      return aValue > bValue ? 1 : -1
    } else {
      return aValue < bValue ? 1 : -1
    }
  })

  const SortButton = ({ field, children }: { field: SortField; children: React.ReactNode }) => (
    <button
      onClick={() => handleSort(field)}
      className="flex items-center space-x-1 hover:text-foreground transition-colors"
    >
      <span>{children}</span>
      <ArrowUpDown className="h-3 w-3" />
    </button>
  )

  return (
    <Card className="overflow-hidden">
      <div className="overflow-x-auto">
        <table className="w-full">
          <thead className="bg-muted/50 border-b">
            <tr className="text-sm text-muted-foreground">
              <th className="px-6 py-4 text-left font-medium">
                <SortButton field="ticker">Ticker</SortButton>
              </th>
              <th className="px-6 py-4 text-left font-medium hidden md:table-cell">
                Nome
              </th>
              <th className="px-6 py-4 text-right font-medium">
                <SortButton field="price">Preço</SortButton>
              </th>
              <th className="px-6 py-4 text-right font-medium">
                <SortButton field="change">Variação</SortButton>
              </th>
              <th className="px-6 py-4 text-right font-medium">
                <SortButton field="pe">P/L</SortButton>
              </th>
              <th className="px-6 py-4 text-right font-medium">
                <SortButton field="dividend">Div. Yield</SortButton>
              </th>
              <th className="px-6 py-4 text-right font-medium hidden lg:table-cell">
                <SortButton field="volume">Volume</SortButton>
              </th>
              <th className="px-6 py-4 text-right font-medium hidden xl:table-cell">
                <SortButton field="marketCap">Market Cap</SortButton>
              </th>
            </tr>
          </thead>
          <tbody className="divide-y">
            {sortedStocks.map((stock) => (
              <tr
                key={stock.ticker}
                onClick={() => onStockClick?.(stock)}
                className="hover:bg-muted/30 cursor-pointer transition-colors"
              >
                <td className="px-6 py-4">
                  <div className="flex items-center space-x-2">
                    <span className="font-semibold">{stock.ticker}</span>
                    {stock.isUndervalued && (
                      <Badge variant="success" className="text-[10px] px-1.5 py-0">
                        SUB
                      </Badge>
                    )}
                  </div>
                </td>
                <td className="px-6 py-4 hidden md:table-cell">
                  <div className="max-w-[200px] truncate text-sm text-muted-foreground">
                    {stock.name}
                  </div>
                </td>
                <td className="px-6 py-4 text-right font-medium">
                  {formatCurrency(stock.price)}
                </td>
                <td className="px-6 py-4 text-right">
                  <div className="flex items-center justify-end">
                    <span className={`flex items-center font-medium ${getBgColorByValue(stock.changePercent)} rounded-md px-2 py-1`}>
                      {stock.changePercent >= 0 ? (
                        <TrendingUp className="mr-1 h-3 w-3" />
                      ) : (
                        <TrendingDown className="mr-1 h-3 w-3" />
                      )}
                      {formatPercent(stock.changePercent)}
                    </span>
                  </div>
                </td>
                <td className="px-6 py-4 text-right">
                  <span className="font-medium">
                    {stock.pe.toFixed(1)}x
                  </span>
                </td>
                <td className="px-6 py-4 text-right">
                  <span className="font-medium text-success">
                    {stock.dividendYield.toFixed(1)}%
                  </span>
                </td>
                <td className="px-6 py-4 text-right hidden lg:table-cell text-sm text-muted-foreground">
                  {formatLargeNumber(stock.volume)}
                </td>
                <td className="px-6 py-4 text-right hidden xl:table-cell text-sm text-muted-foreground">
                  {formatCurrency(stock.marketCap)}
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </Card>
  )
}
