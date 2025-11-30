// ============================================================================
// DATA FETCHING - Simulates fetching from external database
// Data is now in data.js to simulate separation of concerns
// ============================================================================

let stocks = []; // Will be populated from database

// ============================================================================
// RENDER TRADINGVIEW WIDGET
// ============================================================================

async function renderTradingViewWidget() {
    const container = document.getElementById('stockGrid');

    // Show loading state
    container.innerHTML = '<div class="loading-state">Carregando mercado...</div>';

    try {
        // Stocks are already loaded by the main initialization

        // Clear loading state
        container.innerHTML = '';

        // Create Widget Container
        const widgetContainer = document.createElement('div');
        widgetContainer.className = 'tradingview-widget-container market-overview-widget';

        const widgetDiv = document.createElement('div');
        widgetDiv.className = 'tradingview-widget-container__widget';
        widgetContainer.appendChild(widgetDiv);

        const copyrightDiv = document.createElement('div');
        copyrightDiv.className = 'tradingview-widget-copyright';
        copyrightDiv.innerHTML = '<a href="https://br.tradingview.com/" rel="noopener nofollow" target="_blank"><span class="blue-text">Acompanhe tudo no TradingView</span></a>';
        widgetContainer.appendChild(copyrightDiv);

        container.appendChild(widgetContainer);

        // Map stocks to TradingView format
        const symbols = stocks.map(stock => ({
            "s": `BMFBOVESPA:${stock.ticker}`,
            "d": stock.name
        }));

        // Create Script
        const script = document.createElement('script');
        script.type = 'text/javascript';
        script.src = 'https://s3.tradingview.com/external-embedding/embed-widget-market-overview.js';
        script.async = true;
        script.innerHTML = JSON.stringify({
            "colorTheme": "dark",
            "dateRange": "12M",
            "showChart": true,
            "locale": "br",
            "largeChartUrl": "", // Empty to prevent navigation
            "isTransparent": true,
            "showSymbolLogo": true,
            "showFloatingTooltip": false,
            "width": "100%",
            "height": "600",
            "plotLineColorGrowing": "rgba(41, 98, 255, 1)",
            "plotLineColorFalling": "rgba(41, 98, 255, 1)",
            "gridLineColor": "rgba(240, 243, 250, 0)",
            "scaleFontColor": "#DBDBDB",
            "belowLineFillColorGrowing": "rgba(41, 98, 255, 0.12)",
            "belowLineFillColorFalling": "rgba(41, 98, 255, 0.12)",
            "belowLineFillColorGrowingBottom": "rgba(41, 98, 255, 0)",
            "belowLineFillColorFallingBottom": "rgba(41, 98, 255, 0)",
            "symbolActiveColor": "rgba(41, 98, 255, 0.12)",
            "tabs": [
                {
                    "title": "Ações B3",
                    "symbols": symbols
                }
            ]
        });

        widgetContainer.appendChild(script);

        // Intercept clicks on the widget to open modal instead of navigating
        setTimeout(() => {
            const widgetIframe = widgetContainer.querySelector('iframe');
            if (widgetIframe) {
                // Add click listener to widget container as a fallback
                widgetContainer.addEventListener('click', (e) => {
                    // Try to detect which stock was clicked by checking the current URL
                    // This is a workaround since we can't access iframe content
                    const target = e.target;
                    if (target && target.closest('.tradingview-widget-container')) {
                        // Check if there's a symbol in the current context
                        // Note: This may not work perfectly due to iframe restrictions
                        console.log('Widget clicked - attempting to detect symbol');
                    }
                });
            }
        }, 2000); // Wait for widget to load

    } catch (error) {
        console.error('Error loading widget:', error);
        container.innerHTML = '<div class="error-state">Erro ao carregar o mercado. Tente novamente.</div>';
    }
}




// ============================================================================
// RENDER TICKER TAPE WIDGET (Top 5 Stocks)
// ============================================================================



// ============================================================================
// RENDER WIDGET OVERLAY (Interactive Layer)
// ============================================================================


// ============================================================================
// MODAL MANAGEMENT
// ============================================================================

function openStockModal(ticker) {
    const modal = document.getElementById('stockModal');
    const iframe = document.getElementById('widgetFrame');

    // Set iframe source with stock symbol parameter
    // Ensure we strip any "BMFBOVESPA:" prefix if present in the ticker passed
    const cleanTicker = ticker.replace('BMFBOVESPA:', '');
    iframe.src = `index.html?symbol=${cleanTicker}`;

    // Show modal
    modal.classList.add('active');
    document.body.style.overflow = 'hidden'; // Prevent background scroll
}

function closeModal() {
    const modal = document.getElementById('stockModal');
    const iframe = document.getElementById('widgetFrame');

    // Hide modal
    modal.classList.remove('active');
    document.body.style.overflow = ''; // Restore scroll

    // Clear iframe after animation
    setTimeout(() => {
        iframe.src = '';
    }, 300);
}

// Close modal on ESC key
document.addEventListener('keydown', (e) => {
    if (e.key === 'Escape') {
        closeModal();
    }
});

// ============================================================================
// INITIALIZATION
// ============================================================================

document.addEventListener('DOMContentLoaded', async () => {
    // CHECK FOR URL PARAMETER FROM WIDGET CLICK (Run this immediately)
    // The widget appends ?tvwidgetsymbol=BMFBOVESPA%3APETR4
    const urlParams = new URLSearchParams(window.location.search);
    const widgetSymbol = urlParams.get('tvwidgetsymbol');

    if (widgetSymbol) {
        console.log('Widget click detected:', widgetSymbol);

        // Open the modal with this symbol
        openStockModal(widgetSymbol);

        // Clean the URL (remove the ugly parameter) without reloading
        const newUrl = window.location.protocol + "//" + window.location.host + window.location.pathname;
        window.history.replaceState({ path: newUrl }, '', newUrl);
    }

    // Load data once
    try {
        stocks = await fetchStocksFromDatabase();

        // Render widgets
        renderTradingViewWidget();

    } catch (error) {
        console.error('Initialization error:', error);
    }
});

// ============================================================================
// FUTURE: SUPABASE INTEGRATION
// ============================================================================

/*
async function fetchStocksFromSupabase() {
    const { data, error } = await supabase
        .from('stocks')
        .select('*')
        .order('ticker', { ascending: true });

    if (error) {
        console.error('Error fetching stocks:', error);
        return [];
    }

    return data;
}
*/
