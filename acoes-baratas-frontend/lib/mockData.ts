export interface Stock {
  ticker: string
  name: string
  price: number
  change: number
  changePercent: number
  volume: number
  marketCap: number
  pe: number
  dividendYield: number
  week52High: number
  week52Low: number
  sector: string
  logo?: string
  peRank: 'low' | 'medium' | 'high'
  isUndervalued: boolean
}

export interface StockDetail extends Stock {
  beta: number
  eps: number
  revenue: number
  netIncome: number
  debtToEquity: number
  currentRatio: number
  roe: number
  roa: number
  profitMargin: number
  operatingMargin: number
  peg: number
  priceToBook: number
  priceToSales: number
  evToEbitda: number
  institutionalOwnership: number
  insiderOwnership: number
  analystRating: 'Compra Forte' | 'Compra' | 'Neutro' | 'Venda' | 'Venda Forte'
  targetPrice: number
}

export interface HistoricalData {
  date: string
  open: number
  high: number
  low: number
  close: number
  volume: number
}

export interface Dividend {
  date: string
  value: number
}

export interface NewsItem {
  id: string
  title: string
  source: string
  date: string
  sentiment: 'positive' | 'neutral' | 'negative'
  url: string
}

// Mock data para ações baratas brasileiras
export const mockStocks: Stock[] = [
  {
    ticker: 'VALE3',
    name: 'Vale S.A.',
    price: 62.45,
    change: 1.23,
    changePercent: 2.01,
    volume: 45_678_000,
    marketCap: 286_500_000_000,
    pe: 4.2,
    dividendYield: 8.5,
    week52High: 78.90,
    week52Low: 55.30,
    sector: 'Mineração',
    peRank: 'low',
    isUndervalued: true,
  },
  {
    ticker: 'BBDC4',
    name: 'Bradesco S.A.',
    price: 13.87,
    change: -0.34,
    changePercent: -2.39,
    volume: 38_456_000,
    marketCap: 118_900_000_000,
    pe: 6.8,
    dividendYield: 7.2,
    week52High: 16.45,
    week52Low: 12.10,
    sector: 'Bancos',
    peRank: 'low',
    isUndervalued: true,
  },
  {
    ticker: 'PETR4',
    name: 'Petrobras PN',
    price: 38.92,
    change: 0.78,
    changePercent: 2.04,
    volume: 62_345_000,
    marketCap: 506_700_000_000,
    pe: 3.1,
    dividendYield: 14.2,
    week52High: 42.80,
    week52Low: 32.50,
    sector: 'Petróleo e Gás',
    peRank: 'low',
    isUndervalued: true,
  },
  {
    ticker: 'ITUB4',
    name: 'Itaú Unibanco',
    price: 26.54,
    change: 0.45,
    changePercent: 1.72,
    volume: 28_934_000,
    marketCap: 259_800_000_000,
    pe: 7.5,
    dividendYield: 5.8,
    week52High: 29.90,
    week52Low: 23.40,
    sector: 'Bancos',
    peRank: 'low',
    isUndervalued: true,
  },
  {
    ticker: 'BBAS3',
    name: 'Banco do Brasil',
    price: 28.34,
    change: -0.12,
    changePercent: -0.42,
    volume: 15_678_000,
    marketCap: 95_600_000_000,
    pe: 5.9,
    dividendYield: 9.1,
    week52High: 32.50,
    week52Low: 24.80,
    sector: 'Bancos',
    peRank: 'low',
    isUndervalued: true,
  },
  {
    ticker: 'CMIG4',
    name: 'Cemig PN',
    price: 10.23,
    change: 0.15,
    changePercent: 1.49,
    volume: 8_234_000,
    marketCap: 23_400_000_000,
    pe: 8.2,
    dividendYield: 6.5,
    week52High: 12.80,
    week52Low: 9.10,
    sector: 'Energia Elétrica',
    peRank: 'low',
    isUndervalued: true,
  },
  {
    ticker: 'CPLE6',
    name: 'Copel PNB',
    price: 8.67,
    change: 0.23,
    changePercent: 2.73,
    volume: 4_567_000,
    marketCap: 23_700_000_000,
    pe: 6.1,
    dividendYield: 8.9,
    week52High: 10.50,
    week52Low: 7.20,
    sector: 'Energia Elétrica',
    peRank: 'low',
    isUndervalued: true,
  },
  {
    ticker: 'ELET3',
    name: 'Eletrobras ON',
    price: 42.18,
    change: 1.05,
    changePercent: 2.55,
    volume: 12_456_000,
    marketCap: 58_900_000_000,
    pe: 5.7,
    dividendYield: 4.2,
    week52High: 48.90,
    week52Low: 35.60,
    sector: 'Energia Elétrica',
    peRank: 'low',
    isUndervalued: true,
  },
  {
    ticker: 'USIM5',
    name: 'Usiminas PNA',
    price: 6.89,
    change: -0.28,
    changePercent: -3.90,
    volume: 9_876_000,
    marketCap: 8_900_000_000,
    pe: 4.5,
    dividendYield: 3.8,
    week52High: 9.45,
    week52Low: 5.60,
    sector: 'Siderurgia',
    peRank: 'low',
    isUndervalued: true,
  },
  {
    ticker: 'CSNA3',
    name: 'CSN ON',
    price: 12.45,
    change: 0.34,
    changePercent: 2.81,
    volume: 14_567_000,
    marketCap: 16_800_000_000,
    pe: 5.2,
    dividendYield: 5.5,
    week52High: 15.80,
    week52Low: 10.20,
    sector: 'Siderurgia',
    peRank: 'low',
    isUndervalued: true,
  },
  {
    ticker: 'CYRE3',
    name: 'Cyrela Realty',
    price: 19.87,
    change: 0.67,
    changePercent: 3.49,
    volume: 5_234_000,
    marketCap: 7_450_000_000,
    pe: 7.8,
    dividendYield: 4.6,
    week52High: 23.40,
    week52Low: 16.50,
    sector: 'Construção Civil',
    peRank: 'low',
    isUndervalued: true,
  },
  {
    ticker: 'MRFG3',
    name: 'Marfrig ON',
    price: 8.34,
    change: -0.18,
    changePercent: -2.11,
    volume: 7_890_000,
    marketCap: 6_890_000_000,
    pe: 6.3,
    dividendYield: 2.9,
    week52High: 10.90,
    week52Low: 7.20,
    sector: 'Alimentos',
    peRank: 'low',
    isUndervalued: true,
  },
];

// Dados detalhados da VALE3 como exemplo
export const mockStockDetail: StockDetail = {
  ...mockStocks[0],
  beta: 1.15,
  eps: 14.87,
  revenue: 178_500_000_000,
  netIncome: 68_200_000_000,
  debtToEquity: 0.38,
  currentRatio: 1.85,
  roe: 28.5,
  roa: 18.2,
  profitMargin: 38.2,
  operatingMargin: 42.1,
  peg: 0.35,
  priceToBook: 1.2,
  priceToSales: 1.6,
  evToEbitda: 2.8,
  institutionalOwnership: 45.6,
  insiderOwnership: 5.2,
  analystRating: 'Compra Forte',
  targetPrice: 82.50,
};

// Histórico de preços (últimos 6 meses)
export const mockHistoricalData: HistoricalData[] = Array.from({ length: 180 }, (_, i) => {
  const date = new Date();
  date.setDate(date.getDate() - (180 - i));
  const basePrice = 58 + Math.random() * 12;
  const volatility = 0.02;

  return {
    date: date.toISOString().split('T')[0],
    open: basePrice,
    high: basePrice * (1 + Math.random() * volatility),
    low: basePrice * (1 - Math.random() * volatility),
    close: basePrice * (1 + (Math.random() - 0.5) * volatility),
    volume: Math.floor(30_000_000 + Math.random() * 30_000_000),
  };
});

// Dividendos
export const mockDividends: Dividend[] = [
  { date: '2024-11-15', value: 1.45 },
  { date: '2024-08-15', value: 1.38 },
  { date: '2024-05-15', value: 1.52 },
  { date: '2024-02-15', value: 1.41 },
  { date: '2023-11-15', value: 1.35 },
  { date: '2023-08-15', value: 1.29 },
];

// Notícias
export const mockNews: NewsItem[] = [
  {
    id: '1',
    title: 'Vale anuncia investimento de R$ 5 bilhões em nova mina de ferro',
    source: 'InfoMoney',
    date: '2024-11-27',
    sentiment: 'positive',
    url: '#',
  },
  {
    id: '2',
    title: 'Preço do minério de ferro atinge maior valor em 3 meses',
    source: 'Valor Econômico',
    date: '2024-11-26',
    sentiment: 'positive',
    url: '#',
  },
  {
    id: '3',
    title: 'Analistas elevam recomendação de Vale para compra forte',
    source: 'Bloomberg Brasil',
    date: '2024-11-25',
    sentiment: 'positive',
    url: '#',
  },
  {
    id: '4',
    title: 'Produção de minério da Vale supera expectativas no trimestre',
    source: 'Reuters',
    date: '2024-11-24',
    sentiment: 'positive',
    url: '#',
  },
  {
    id: '5',
    title: 'China anuncia pacote de estímulo à construção civil',
    source: 'Financial Times',
    date: '2024-11-23',
    sentiment: 'positive',
    url: '#',
  },
];

// Estatísticas do mercado
export interface MarketStats {
  totalStocks: number
  avgPE: number
  avgDividend: number
  totalVolume: number
  gainers: number
  losers: number
  unchanged: number
}

export const mockMarketStats: MarketStats = {
  totalStocks: 12,
  avgPE: 5.9,
  avgDividend: 6.4,
  totalVolume: 253_920_000,
  gainers: 8,
  losers: 4,
  unchanged: 0,
};

// Screener filters
export interface ScreenerFilters {
  maxPE: number
  minDividend: number
  minMarketCap: number
  sectors: string[]
  sortBy: 'pe' | 'dividend' | 'volume' | 'change'
  sortOrder: 'asc' | 'desc'
}

export const defaultFilters: ScreenerFilters = {
  maxPE: 10,
  minDividend: 3,
  minMarketCap: 1_000_000_000,
  sectors: [],
  sortBy: 'pe',
  sortOrder: 'asc',
};
