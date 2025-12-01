'use client'

import { Card, CardContent, CardHeader, CardTitle } from './ui/card'
import { LineChart, Line, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer, Area, AreaChart } from 'recharts'
import { HistoricalData } from '@/lib/mockData'
import { formatCurrency } from '@/lib/utils'

interface PriceChartProps {
  data: HistoricalData[]
  title?: string
}

export function PriceChart({ data, title = 'Histórico de Preços' }: PriceChartProps) {
  // Pega apenas os últimos 90 dias para melhor visualização
  const chartData = data.slice(-90).map(d => ({
    date: new Date(d.date).toLocaleDateString('pt-BR', { day: '2-digit', month: 'short' }),
    price: d.close,
    high: d.high,
    low: d.low,
  }))

  const minPrice = Math.min(...chartData.map(d => d.low))
  const maxPrice = Math.max(...chartData.map(d => d.high))
  const priceChange = chartData[chartData.length - 1].price - chartData[0].price
  const isPositive = priceChange >= 0

  return (
    <Card className="col-span-full">
      <CardHeader>
        <div className="flex items-center justify-between">
          <CardTitle>{title}</CardTitle>
          <div className="flex items-center space-x-4 text-sm">
            <div>
              <span className="text-muted-foreground">Mín: </span>
              <span className="font-semibold">{formatCurrency(minPrice)}</span>
            </div>
            <div>
              <span className="text-muted-foreground">Máx: </span>
              <span className="font-semibold">{formatCurrency(maxPrice)}</span>
            </div>
            <div>
              <span className="text-muted-foreground">Variação: </span>
              <span className={`font-semibold ${isPositive ? 'text-success' : 'text-danger'}`}>
                {isPositive ? '+' : ''}{formatCurrency(priceChange)}
              </span>
            </div>
          </div>
        </div>
      </CardHeader>
      <CardContent>
        <div className="h-[400px] w-full">
          <ResponsiveContainer width="100%" height="100%">
            <AreaChart data={chartData}>
              <defs>
                <linearGradient id="colorPrice" x1="0" y1="0" x2="0" y2="1">
                  <stop offset="5%" stopColor="hsl(221.2 83.2% 53.3%)" stopOpacity={0.3}/>
                  <stop offset="95%" stopColor="hsl(221.2 83.2% 53.3%)" stopOpacity={0}/>
                </linearGradient>
              </defs>
              <CartesianGrid strokeDasharray="3 3" className="stroke-muted" />
              <XAxis
                dataKey="date"
                className="text-xs"
                tick={{ fill: 'hsl(var(--muted-foreground))' }}
                tickMargin={10}
              />
              <YAxis
                className="text-xs"
                tick={{ fill: 'hsl(var(--muted-foreground))' }}
                tickFormatter={(value) => `R$ ${value.toFixed(0)}`}
                domain={[minPrice * 0.98, maxPrice * 1.02]}
              />
              <Tooltip
                contentStyle={{
                  backgroundColor: 'hsl(var(--popover))',
                  border: '1px solid hsl(var(--border))',
                  borderRadius: '8px',
                  padding: '12px',
                }}
                labelStyle={{ color: 'hsl(var(--foreground))', fontWeight: 600 }}
                formatter={(value: number) => [formatCurrency(value), 'Preço']}
              />
              <Area
                type="monotone"
                dataKey="price"
                stroke="hsl(221.2 83.2% 53.3%)"
                strokeWidth={2}
                fill="url(#colorPrice)"
              />
            </AreaChart>
          </ResponsiveContainer>
        </div>
      </CardContent>
    </Card>
  )
}
