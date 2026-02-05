'use client'

import { Card, CardContent } from './ui/card'
import { TrendingUp, TrendingDown, Activity, DollarSign } from 'lucide-react'
import { mockMarketStats } from '@/lib/mockData'
import { formatLargeNumber } from '@/lib/utils'

export function MarketStats() {
  const stats = [
    {
      title: 'Total de Ações',
      value: mockMarketStats.totalStocks.toString(),
      icon: Activity,
      color: 'text-blue-600',
      bgColor: 'bg-blue-100',
    },
    {
      title: 'P/L Médio',
      value: mockMarketStats.avgPE.toFixed(1),
      icon: DollarSign,
      color: 'text-purple-600',
      bgColor: 'bg-purple-100',
      subtitle: 'Abaixo da média do mercado',
    },
    {
      title: 'Dividend Yield Médio',
      value: `${mockMarketStats.avgDividend.toFixed(1)}%`,
      icon: TrendingUp,
      color: 'text-green-600',
      bgColor: 'bg-green-100',
      subtitle: 'Rendimento anual',
    },
    {
      title: 'Volume Total',
      value: formatLargeNumber(mockMarketStats.totalVolume),
      icon: Activity,
      color: 'text-orange-600',
      bgColor: 'bg-orange-100',
      subtitle: `${mockMarketStats.gainers} em alta, ${mockMarketStats.losers} em queda`,
    },
  ]

  return (
    <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-4">
      {stats.map((stat, index) => {
        const Icon = stat.icon
        return (
          <Card key={index} className="overflow-hidden transition-all hover:shadow-lg">
            <CardContent className="p-6">
              <div className="flex items-center justify-between">
                <div className="space-y-1">
                  <p className="text-sm font-medium text-muted-foreground">
                    {stat.title}
                  </p>
                  <p className="text-3xl font-bold">{stat.value}</p>
                  {stat.subtitle && (
                    <p className="text-xs text-muted-foreground">
                      {stat.subtitle}
                    </p>
                  )}
                </div>
                <div className={`rounded-full p-3 ${stat.bgColor}`}>
                  <Icon className={`h-6 w-6 ${stat.color}`} />
                </div>
              </div>
            </CardContent>
          </Card>
        )
      })}
    </div>
  )
}
