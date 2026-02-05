'use client'

import { TrendingDown, Search } from 'lucide-react'
import { Input } from './ui/input'

export function Header() {
  return (
    <header className="sticky top-0 z-50 w-full border-b bg-background/95 backdrop-blur supports-[backdrop-filter]:bg-background/60">
      <div className="container flex h-16 items-center">
        <div className="mr-8 flex items-center space-x-2">
          <div className="flex h-10 w-10 items-center justify-center rounded-lg bg-primary">
            <TrendingDown className="h-6 w-6 text-white" />
          </div>
          <div className="flex flex-col">
            <span className="text-lg font-bold leading-none">Ações Baratas</span>
            <span className="text-xs text-muted-foreground">Oportunidades em valor</span>
          </div>
        </div>

        <div className="flex flex-1 items-center justify-between space-x-2 md:justify-end">
          <div className="w-full flex-1 md:w-auto md:flex-none">
            <div className="relative">
              <Search className="absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-muted-foreground" />
              <Input
                placeholder="Buscar ações (ex: VALE3, PETR4...)"
                className="pl-10 md:w-[300px] lg:w-[400px]"
              />
            </div>
          </div>
          <nav className="hidden md:flex items-center space-x-6 text-sm font-medium">
            <a
              href="#"
              className="text-foreground/80 transition-colors hover:text-foreground"
            >
              Dashboard
            </a>
            <a
              href="#"
              className="text-foreground/60 transition-colors hover:text-foreground"
            >
              Screener
            </a>
            <a
              href="#"
              className="text-foreground/60 transition-colors hover:text-foreground"
            >
              Portfólio
            </a>
            <a
              href="#"
              className="text-foreground/60 transition-colors hover:text-foreground"
            >
              Alertas
            </a>
          </nav>
        </div>
      </div>
    </header>
  )
}
