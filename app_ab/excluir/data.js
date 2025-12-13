// ============================================================================
// MOCK DATABASE - Simulating external data source
// This file simulates data that would come from Supabase
// ============================================================================

const stocksDatabase = [
    {
        ticker: "VALE3",
        name: "Vale ON",
        price: 65.20,
        change: -1.2,
        sector: "Mineração",
        volume: "98.7M",
        marketCap: "312.5B"
    },
    {
        ticker: "PETR4",
        name: "Petrobras PN",
        price: 38.50,
        change: 2.5,
        sector: "Petróleo e Gás",
        volume: "125.4M",
        marketCap: "501.2B"
    },
    {
        ticker: "ITUB4",
        name: "Itaú Unibanco PN",
        price: 28.90,
        change: 0.8,
        sector: "Bancos",
        volume: "67.3M",
        marketCap: "283.1B"
    },
    {
        ticker: "BBDC4",
        name: "Bradesco PN",
        price: 13.45,
        change: 1.5,
        sector: "Bancos",
        volume: "54.2M",
        marketCap: "145.8B"
    },
    {
        ticker: "ABEV3",
        name: "Ambev ON",
        price: 11.80,
        change: -0.3,
        sector: "Bebidas",
        volume: "89.1M",
        marketCap: "185.6B"
    },
    {
        ticker: "WEGE3",
        name: "WEG ON",
        price: 42.30,
        change: 3.2,
        sector: "Máquinas",
        volume: "23.5M",
        marketCap: "79.4B"
    },
    {
        ticker: "RENT3",
        name: "Localiza ON",
        price: 52.10,
        change: -2.1,
        sector: "Aluguel de Carros",
        volume: "12.8M",
        marketCap: "56.2B"
    },
    {
        ticker: "MGLU3",
        name: "Magazine Luiza ON",
        price: 2.85,
        change: 5.5,
        sector: "Varejo",
        volume: "156.9M",
        marketCap: "19.3B"
    },
    {
        ticker: "BBAS3",
        name: "Banco do Brasil ON",
        price: 26.70,
        change: 0.5,
        sector: "Bancos",
        volume: "34.6M",
        marketCap: "92.7B"
    },
    {
        ticker: "SUZB3",
        name: "Suzano ON",
        price: 48.90,
        change: -1.8,
        sector: "Papel e Celulose",
        volume: "18.4M",
        marketCap: "66.8B"
    },
    {
        ticker: "GGBR4",
        name: "Gerdau PN",
        price: 19.25,
        change: 2.2,
        sector: "Siderurgia",
        volume: "41.7M",
        marketCap: "32.1B"
    },
    {
        ticker: "VIVT3",
        name: "Telefônica Brasil ON",
        price: 45.60,
        change: 0.9,
        sector: "Telecomunicações",
        volume: "8.9M",
        marketCap: "76.5B"
    }
];

// ============================================================================
// API SIMULATION - Simulating async data fetch
// ============================================================================

/**
 * Simulates fetching stocks from a database (e.g., Supabase)
 * Returns a Promise to simulate async behavior
 */
async function fetchStocksFromDatabase() {
    // Simulate network delay
    return new Promise((resolve) => {
        setTimeout(() => {
            resolve(stocksDatabase);
        }, 300); // 300ms delay to simulate API call
    });
}

/**
 * Future Supabase integration example:
 *
 * import { createClient } from '@supabase/supabase-js'
 *
 * const supabase = createClient(
 *   'YOUR_SUPABASE_URL',
 *   'YOUR_SUPABASE_ANON_KEY'
 * )
 *
 * async function fetchStocksFromSupabase() {
 *   const { data, error } = await supabase
 *     .from('stocks')
 *     .select('*')
 *     .order('ticker', { ascending: true });
 *
 *   if (error) {
 *     console.error('Error fetching stocks:', error);
 *     return [];
 *   }
 *
 *   return data;
 * }
 */
