// ============================================================================
// DATA FETCHING - Simulates fetching from external database
// ============================================================================

let stocks = []; // Will be populated from database
let widgetsLoaded = new Set(); // Track loaded widgets
let isInitialized = false; // Prevent multiple initializations

// ============================================================================
// RENDER TRADINGVIEW MARKET OVERVIEW WIDGET
// ============================================================================

async function renderTradingViewWidget() {
    const container = document.getElementById('stockGrid');

    if (!container) return;

    // Show loading state
    container.innerHTML = '<div class="loading-state">Carregando mercado...</div>';

    try {
        // Clear loading state
        container.innerHTML = '';

        // Create Widget Container
        const widgetContainer = document.createElement('div');
        widgetContainer.className = 'tradingview-widget-container market-overview-widget';
        widgetContainer.id = 'market-overview-widget';

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
            "largeChartUrl": "",
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
            "tabs": [{
                "title": "Ações B3",
                "symbols": symbols
            }]
        });

        widgetContainer.appendChild(script);

    } catch (error) {
        console.error('Error loading widget:', error);
        container.innerHTML = '<div class="error-state">Erro ao carregar o mercado. Tente novamente.</div>';
    }
}

// ============================================================================
// RENDER STOCK CARDS WITH LAZY LOADING (Optimized)
// ============================================================================

function renderStockCards() {
    const container = document.getElementById('stockCards');

    if (!container || !stocks || stocks.length === 0) {
        console.error('Container or stocks not found');
        return;
    }

    // Clear container
    container.innerHTML = '';

    // Create placeholder rows for lazy loading
    stocks.forEach((stock, index) => {
        const widgetWrapper = document.createElement('div');
        widgetWrapper.className = 'stock-widget-row';
        widgetWrapper.dataset.ticker = stock.ticker;
        widgetWrapper.dataset.loaded = 'false';

        // Add click handler
        widgetWrapper.addEventListener('click', () => {
            openStockModal(stock.ticker);
        });

        // Add loading placeholder
        widgetWrapper.innerHTML = `
            <div class="widget-loading">
                <span class="loading-ticker">${stock.ticker}</span>
                <span class="loading-spinner">Carregando...</span>
            </div>
        `;

        container.appendChild(widgetWrapper);
    });

    // Initialize Intersection Observer for lazy loading
    initLazyLoading();
}

// ============================================================================
// LAZY LOADING WITH INTERSECTION OBSERVER
// ============================================================================

let observer = null;

function initLazyLoading() {
    // Clean up existing observer
    if (observer) {
        observer.disconnect();
    }

    const options = {
        root: null,
        rootMargin: '100px',
        threshold: 0.1
    };

    observer = new IntersectionObserver((entries) => {
        entries.forEach(entry => {
            if (entry.isIntersecting) {
                const wrapper = entry.target;
                const ticker = wrapper.dataset.ticker;
                const isLoaded = wrapper.dataset.loaded === 'true';

                if (!isLoaded && !widgetsLoaded.has(ticker)) {
                    loadSymbolInfoWidget(wrapper, ticker);
                    widgetsLoaded.add(ticker);
                    observer.unobserve(wrapper);
                }
            }
        });
    }, options);

    // Observe all widget rows
    const rows = document.querySelectorAll('.stock-widget-row');
    rows.forEach(row => observer.observe(row));
}

// ============================================================================
// LOAD INDIVIDUAL SYMBOL INFO WIDGET
// ============================================================================

function loadSymbolInfoWidget(wrapper, ticker) {
    // Clear loading placeholder
    wrapper.innerHTML = '';
    wrapper.dataset.loaded = 'true';

    // Create TradingView Symbol Info widget
    const widgetContainer = document.createElement('div');
    widgetContainer.className = 'tradingview-widget-container stock-widget-item';

    const widgetDiv = document.createElement('div');
    widgetDiv.className = 'tradingview-widget-container__widget';
    widgetContainer.appendChild(widgetDiv);

    // Create script
    const script = document.createElement('script');
    script.type = 'text/javascript';
    script.src = 'https://s3.tradingview.com/external-embedding/embed-widget-symbol-info.js';
    script.async = true;
    script.innerHTML = JSON.stringify({
        "symbol": `BMFBOVESPA:${ticker}`,
        "width": "100%",
        "locale": "br",
        "colorTheme": "dark",
        "isTransparent": true
    });

    // Error handling
    script.onerror = () => {
        wrapper.innerHTML = `
            <div class="widget-error">
                <span>${ticker}</span>
                <span style="color: #f7525f; font-size: 0.8rem;">Erro ao carregar</span>
            </div>
        `;
    };

    widgetContainer.appendChild(script);
    wrapper.appendChild(widgetContainer);
}

// ============================================================================
// MODAL MANAGEMENT
// ============================================================================

function openStockModal(ticker) {
    const modal = document.getElementById('stockModal');
    const iframe = document.getElementById('widgetFrame');

    if (!modal || !iframe) return;

    // Clean ticker
    const cleanTicker = ticker.replace('BMFBOVESPA:', '');
    iframe.src = `index.html?symbol=${cleanTicker}`;

    // Show modal
    modal.classList.add('active');
    document.body.style.overflow = 'hidden';
}

function closeModal() {
    const modal = document.getElementById('stockModal');
    const iframe = document.getElementById('widgetFrame');

    if (!modal || !iframe) return;

    // Hide modal
    modal.classList.remove('active');
    document.body.style.overflow = '';

    // Clear iframe after animation
    setTimeout(() => {
        iframe.src = '';
    }, 300);
}

// ============================================================================
// EVENT LISTENERS (with cleanup)
// ============================================================================

let escKeyHandler = null;

function initEventListeners() {
    // Remove existing listener if any
    if (escKeyHandler) {
        document.removeEventListener('keydown', escKeyHandler);
    }

    // Create new listener
    escKeyHandler = (e) => {
        if (e.key === 'Escape') {
            closeModal();
        }
    };

    document.addEventListener('keydown', escKeyHandler);
}

// ============================================================================
// INITIALIZATION
// ============================================================================

document.addEventListener('DOMContentLoaded', async () => {
    // Prevent multiple initializations
    if (isInitialized) return;
    isInitialized = true;

    // Check for URL parameter
    const urlParams = new URLSearchParams(window.location.search);
    const widgetSymbol = urlParams.get('tvwidgetsymbol');

    if (widgetSymbol) {
        console.log('Widget click detected:', widgetSymbol);
        openStockModal(widgetSymbol);

        // Clean URL
        const newUrl = window.location.protocol + "//" + window.location.host + window.location.pathname;
        window.history.replaceState({ path: newUrl }, '', newUrl);
    }

    // Initialize event listeners
    initEventListeners();

    // Load data
    try {
        stocks = await fetchStocksFromDatabase();

        if (stocks && stocks.length > 0) {
            // Render Market Overview widget
            renderTradingViewWidget();

            // Render stock cards with lazy loading
            renderStockCards();
        } else {
            console.error('No stocks data available');
        }

    } catch (error) {
        console.error('Initialization error:', error);
        const container = document.getElementById('stockCards');
        if (container) {
            container.innerHTML = '<div class="error-state">Erro ao carregar dados. Recarregue a página.</div>';
        }
    }
});

// ============================================================================
// CLEANUP ON PAGE UNLOAD
// ============================================================================

window.addEventListener('beforeunload', () => {
    // Disconnect observer
    if (observer) {
        observer.disconnect();
    }

    // Clear loaded widgets set
    widgetsLoaded.clear();

    // Remove event listeners
    if (escKeyHandler) {
        document.removeEventListener('keydown', escKeyHandler);
    }
});
