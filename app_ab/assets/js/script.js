// ============================================================================
// CONFIGURATION & STATE
// ============================================================================

// Current symbol (fixed consistency issue - using PETR4 as default)
let currentSymbol = "BMFBOVESPA:PETR4";

// Cache for loaded symbols (prevents unnecessary reloading)
const loadedSymbols = new Map();

// Widget loading states
const widgetStates = new Map();

// ============================================================================
// WIDGET FACTORY - Centralized Configuration
// ============================================================================

const WidgetFactory = {
    // Centralized widget configurations
    configs: {
        'symbol-info': {
            type: 'script',
            scriptUrl: 'https://s3.tradingview.com/external-embedding/embed-widget-symbol-info.js',
            getConfig: (symbol) => ({
                "symbol": symbol,
                "width": "100%",
                "locale": "br",
                "colorTheme": "dark",
                "isTransparent": true
            })
        },
        'symbol-overview': {
            type: 'script',
            scriptUrl: 'https://s3.tradingview.com/external-embedding/embed-widget-symbol-overview.js',
            getConfig: (symbol) => {
                const tickerName = symbol.includes(':') ? symbol.split(':')[1] : symbol;
                return {
                    "symbols": [[tickerName, symbol + "|1D"]],
                    "chartOnly": false,
                    "width": "100%",
                    "height": "100%",
                    "locale": "br",
                    "colorTheme": "dark",
                    "autosize": true,
                    "showVolume": false,
                    "showMA": false,
                    "hideDateRanges": false,
                    "hideMarketStatus": false,
                    "hideSymbolLogo": false,
                    "scalePosition": "right",
                    "scaleMode": "Normal",
                    "fontFamily": "-apple-system, BlinkMacSystemFont, Trebuchet MS, Roboto, Ubuntu, sans-serif",
                    "fontSize": "10",
                    "noTimeScale": false,
                    "valuesTracking": "1",
                    "changeMode": "price-and-percent",
                    "chartType": "area",
                    "lineWidth": 2,
                    "lineType": 0,
                    "dateRanges": ["1d|1", "1m|30", "3m|60", "12m|1D", "60m|1W", "all|1M"],
                    "upColor": "#22ab94",
                    "downColor": "#f7525f",
                    "borderUpColor": "#22ab94",
                    "borderDownColor": "#f7525f",
                    "wickUpColor": "#22ab94",
                    "wickDownColor": "#f7525f",
                    "isTransparent": true,
                    "backgroundColor": "rgba(0, 0, 0, 0)",
                    "headerFontSize": "medium"
                };
            }
        },
        'company-profile': {
            type: 'script',
            scriptUrl: 'https://s3.tradingview.com/external-embedding/embed-widget-symbol-profile.js',
            getConfig: (symbol) => ({
                "width": "100%",
                "height": 400,
                "isTransparent": true,
                "colorTheme": "dark",
                "symbol": symbol,
                "locale": "br"
            })
        },
        'fundamental-data': {
            type: 'script',
            scriptUrl: 'https://s3.tradingview.com/external-embedding/embed-widget-financials.js',
            getConfig: (symbol) => ({
                "isTransparent": true,
                "largeChartUrl": "",
                "displayMode": "regular",
                "width": "100%",
                "height": 800,
                "colorTheme": "dark",
                "symbol": symbol,
                "locale": "br"
            })
        },
        'technical-analysis': {
            type: 'script',
            scriptUrl: 'https://s3.tradingview.com/external-embedding/embed-widget-technical-analysis.js',
            getConfig: (symbol) => ({
                "interval": "1D",
                "width": "100%",
                "isTransparent": true,
                "height": 450,
                "symbol": symbol,
                "showIntervalTabs": true,
                "displayMode": "single",
                "locale": "br",
                "colorTheme": "dark"
            })
        },
        'timeline': {
            type: 'news',
            getConfig: (symbol) => {
                const ticker = symbol.includes(':') ? symbol.split(':')[1] : symbol;
                return { ticker: ticker };
            }
        }
    },

    // Create widget with error handling
    create(widgetId, symbol) {
        const container = document.getElementById(widgetId + '-widget');
        if (!container) {
            console.error(`Container not found: ${widgetId}-widget`);
            return;
        }

        // Get widget configuration
        const widgetConfig = this.configs[widgetId];
        if (!widgetConfig) {
            console.error(`Widget configuration not found: ${widgetId}`);
            return;
        }

        try {
            // Set loading state
            widgetStates.set(widgetId, 'loading');

            // Show loading skeleton (this clears the container and adds skeleton)
            this.showLoading(container);

            // Handle different widget types
            if (widgetConfig.type === 'news') {
                this.createNewsWidget(container, widgetConfig, symbol, widgetId);
            } else {
                this.createScriptWidget(container, widgetConfig, symbol, widgetId);
            }

        } catch (error) {
            console.error(`Error creating widget ${widgetId}:`, error);
            this.showError(container, widgetId, symbol);
            widgetStates.set(widgetId, 'error');
        }
    },

    // Custom News Widget Implementation
    async createNewsWidget(container, config, symbol, widgetId) {
        const { ticker } = config.getConfig(symbol);

        // RSS URLs - Only Google News for Brazilian content
        const googleRss = `https://news.google.com/rss/search?q=${ticker}+ações+brasil&hl=pt-BR&gl=BR&ceid=BR:pt-419`;

        // API endpoints
        const googleApi = `https://api.rss2json.com/v1/api.json?rss_url=${encodeURIComponent(googleRss)}`;

        try {
            // Fetch Google News only
            const googleRes = await fetch(googleApi).then(r => r.json()).catch(() => ({ status: 'error', items: [] }));

            // Get items
            let allNews = [];
            if (googleRes.status === 'ok') allNews = googleRes.items;

            if (allNews.length > 0) {
                // Sort by date (newest first)
                allNews.sort((a, b) => new Date(b.pubDate) - new Date(a.pubDate));

                // Create container
                const newsContainer = document.createElement('div');
                newsContainer.className = 'news-widget-container';

                // Header
                const header = document.createElement('div');
                header.className = 'news-header';
                header.innerHTML = `<h3>Notícias sobre ${ticker}</h3>`;
                newsContainer.appendChild(header);

                // News List
                const list = document.createElement('div');
                list.className = 'news-list';

                // Deduplicate by title (simple check)
                const seenTitles = new Set();
                const uniqueNews = [];

                allNews.forEach(item => {
                    if (seenTitles.has(item.title)) return;
                    seenTitles.add(item.title);
                    uniqueNews.push(item);
                });

                // Initial display count
                let displayCount = 5;

                const renderNews = () => {
                    list.innerHTML = ''; // Clear list

                    uniqueNews.slice(0, displayCount).forEach(item => {
                        const newsItem = document.createElement('a');
                        newsItem.href = item.link;
                        newsItem.target = '_blank';
                        newsItem.className = 'news-item';

                        // Format date
                        const date = new Date(item.pubDate);
                        const timeAgo = this.getTimeAgo(date);

                        // Determine Source
                        let sourceName = 'Notícia';
                        if (item.link.includes('google')) sourceName = 'Google News';
                        else if (item.link.includes('yahoo')) sourceName = 'Yahoo Finance';
                        else if (item.author) sourceName = item.author;

                        // Text-only layout (No images)
                        newsItem.innerHTML = `
                            <div class="news-content">
                                <div class="news-meta-top">
                                    <span class="news-source">${sourceName}</span>
                                    <span class="news-date">${timeAgo}</span>
                                </div>
                                <h4 class="news-title">${item.title}</h4>
                            </div>
                        `;
                        list.appendChild(newsItem);
                    });

                    // Add "Ver Mais" button if there are more items
                    if (displayCount < uniqueNews.length) {
                        const loadMoreBtn = document.createElement('button');
                        loadMoreBtn.className = 'load-more-btn';
                        loadMoreBtn.textContent = 'Ver Mais';
                        loadMoreBtn.onclick = (e) => {
                            e.preventDefault();
                            displayCount += 5;
                            renderNews();
                        };
                        list.appendChild(loadMoreBtn);
                    }
                };

                renderNews();

                newsContainer.appendChild(list);

                // Clear skeleton and append news
                container.innerHTML = '';
                container.appendChild(newsContainer);

                widgetStates.set(widgetId, 'loaded');
                container.classList.remove('loading');
            } else {
                throw new Error('No news found');
            }
        } catch (error) {
            console.error('Error fetching news:', error);
            container.innerHTML = `
                <div class="error-state" style="height: 450px;">
                    <div class="error-icon">📰</div>
                    <h3>Sem notícias recentes</h3>
                    <p>Não encontramos notícias para este ativo no momento.</p>
                </div>
            `;
            container.classList.remove('loading');
            widgetStates.set(widgetId, 'error');
        }
    },

    getTimeAgo(date) {
        const seconds = Math.floor((new Date() - date) / 1000);
        let interval = seconds / 31536000;

        if (interval > 1) return Math.floor(interval) + " anos atrás";
        interval = seconds / 2592000;
        if (interval > 1) return Math.floor(interval) + " meses atrás";
        interval = seconds / 86400;
        if (interval > 1) return Math.floor(interval) + " dias atrás";
        interval = seconds / 3600;
        if (interval > 1) return Math.floor(interval) + "h atrás";
        interval = seconds / 60;
        if (interval > 1) return Math.floor(interval) + "m atrás";
        return "Agora mesmo";
    },

    createScriptWidget(container, config, symbol, widgetId) {
        // Create widget wrapper
        const wrapper = document.createElement('div');
        wrapper.className = 'tradingview-widget-container';

        // Special handling for symbol-overview (needs specific structure)
        if (widgetId === 'symbol-overview') {
            wrapper.style.height = '100%';
            wrapper.style.width = '100%';
        }

        const widgetDiv = document.createElement('div');
        widgetDiv.className = 'tradingview-widget-container__widget';

        if (widgetId === 'symbol-overview') {
            widgetDiv.style.height = '100%';
            widgetDiv.style.width = '100%';
        }

        wrapper.appendChild(widgetDiv);

        // Create script element
        const script = document.createElement('script');
        script.type = 'text/javascript';
        script.src = config.scriptUrl;
        script.async = true;
        script.innerHTML = JSON.stringify(config.getConfig(symbol));

        // Add error handler
        script.onerror = () => {
            this.showError(container, widgetId, symbol);
            widgetStates.set(widgetId, 'error');
        };

        // Add load handler
        script.onload = () => {
            widgetStates.set(widgetId, 'loaded');
            container.classList.remove('loading');
            // Remove skeleton loader
            const skeleton = container.querySelector('.skeleton-loader');
            if (skeleton) {
                skeleton.remove();
            }
        };

        wrapper.appendChild(script);
        container.appendChild(wrapper);
    },

    // Show loading skeleton
    showLoading(container) {
        container.classList.add('loading');
        container.innerHTML = `
            <div class="skeleton-loader">
                <div class="skeleton-header"></div>
                <div class="skeleton-body"></div>
                <div class="skeleton-footer"></div>
            </div>
        `;
    },

    // Show error state with retry
    showError(container, widgetId, symbol) {
        container.classList.remove('loading');
        container.innerHTML = `
            <div class="error-state">
                <div class="error-icon">⚠️</div>
                <h3>Erro ao carregar widget</h3>
                <p>Não foi possível carregar as informações. Verifique se o símbolo está correto.</p>
                <button class="retry-btn" onclick="WidgetFactory.create('${widgetId}', '${symbol}')">
                    🔄 Tentar Novamente
                </button>
            </div>
        `;
    }
};

// ============================================================================
// DEBOUNCE UTILITY
// ============================================================================

function debounce(func, wait) {
    let timeout;
    return function executedFunction(...args) {
        const later = () => {
            clearTimeout(timeout);
            func(...args);
        };
        clearTimeout(timeout);
        timeout = setTimeout(later, wait);
    };
}

// ============================================================================
// LAZY LOADING WITH INTERSECTION OBSERVER
// ============================================================================

const observerOptions = {
    root: null,
    rootMargin: '200px', // Increased margin to load earlier
    threshold: 0.01 // Reduced threshold for earlier triggering
};

const widgetObserver = new IntersectionObserver((entries) => {
    entries.forEach(entry => {
        if (entry.isIntersecting) {
            const widgetCard = entry.target;
            const widgetId = widgetCard.dataset.widgetId;

            // Check if widget hasn't been loaded yet or is pending update
            if (!widgetStates.has(widgetId) || widgetStates.get(widgetId) === 'pending') {
                loadWidget(widgetId, currentSymbol);

                // Stop observing this widget after loading
                widgetObserver.unobserve(widgetCard);
            }
        }
    });
}, observerOptions);

// Load individual widget
function loadWidget(widgetId, symbol) {
    WidgetFactory.create(widgetId, symbol);
}

// ============================================================================
// SYMBOL UPDATE & CACHING
// ============================================================================

// Core update logic (Immediate)
function performSymbolUpdate(symbol) {
    // Check cache if it's the exact same request
    if (loadedSymbols.has(symbol) && currentSymbol === symbol) {
        showNotification('✅ Símbolo já carregado', 'info');
        return;
    }

    // Update state
    loadedSymbols.set(symbol, Date.now());
    currentSymbol = symbol;

    // Reload all widgets
    reloadAllWidgets(symbol);

    showNotification(`📊 Atualizando para ${symbol}`, 'success');
}

// Debounced version (for typing events if needed)
const debouncedUpdate = debounce(performSymbolUpdate, 500);

// Update symbol function (User Triggered)
function updateSymbol() {
    const input = document.getElementById('symbolInput').value.trim().toUpperCase();

    if (!input) {
        showNotification('⚠️ Digite um símbolo válido', 'warning');
        return;
    }

    // Validate and format symbol
    let symbol = input;

    // Add BMFBOVESPA prefix if not present and it's a Brazilian stock (4-6 chars)
    if (!input.includes(':') && input.length >= 4 && input.length <= 6) {
        symbol = 'BMFBOVESPA:' + input;
    }

    // Update input display
    document.getElementById('symbolInput').value = symbol;

    // Call IMMEDIATE update (No debounce for button/enter)
    performSymbolUpdate(symbol);
}

// Reload all widgets
function reloadAllWidgets(symbol) {
    const widgetIds = ['symbol-info', 'symbol-overview', 'company-profile', 'fundamental-data', 'technical-analysis', 'timeline'];

    widgetIds.forEach(widgetId => {
        const container = document.getElementById(widgetId + '-widget');
        const card = container ? container.closest('.widget-card') : null;

        if (container && card) {
            if (isElementInViewport(container)) {
                // If visible, load immediately
                loadWidget(widgetId, symbol);
                // Ensure we don't observe it anymore if it's already loaded
                widgetObserver.unobserve(card);
            } else {
                // If hidden, mark as pending and observe
                widgetStates.set(widgetId, 'pending');

                // Show loading state immediately to avoid showing old data
                // This clears the container and adds the skeleton
                WidgetFactory.showLoading(container);

                // Re-observe so it loads when scrolled into view
                widgetObserver.observe(card);
            }
        }
    });
}

// Check if element is in viewport
function isElementInViewport(el) {
    const rect = el.getBoundingClientRect();
    return (
        rect.top >= 0 &&
        rect.left >= 0 &&
        rect.bottom <= (window.innerHeight || document.documentElement.clientHeight) &&
        rect.right <= (window.innerWidth || document.documentElement.clientWidth)
    );
}

// ============================================================================
// NOTIFICATION SYSTEM
// ============================================================================

function showNotification(message, type = 'info') {
    // Remove existing notification
    const existing = document.querySelector('.notification');
    if (existing) {
        existing.remove();
    }

    // Create notification
    const notification = document.createElement('div');
    notification.className = `notification notification-${type}`;
    notification.textContent = message;

    document.body.appendChild(notification);

    // Trigger animation
    setTimeout(() => notification.classList.add('show'), 10);

    // Auto remove after 3 seconds
    setTimeout(() => {
        notification.classList.remove('show');
        setTimeout(() => notification.remove(), 300);
    }, 3000);
}

// ============================================================================
// INITIALIZATION
// ============================================================================

document.addEventListener('DOMContentLoaded', function () {
    // Check for URL parameter FIRST to use it as initial symbol
    const urlParams = new URLSearchParams(window.location.search);

    // TradingView sends 'tvwidgetsymbol' parameter, check that first
    let symbolParam = urlParams.get('tvwidgetsymbol') || urlParams.get('symbol');

    if (symbolParam) {
        // Clean up the symbol (remove BMFBOVESPA: if present, we'll add it back)
        symbolParam = symbolParam.replace('BMFBOVESPA:', '').replace('BMFBOVESPA%3A', '');

        const formattedSymbol = `BMFBOVESPA:${symbolParam}`;
        document.getElementById('symbolInput').value = formattedSymbol;
        currentSymbol = formattedSymbol; // Set as current symbol BEFORE loading widgets

        console.log('📊 URL parameter detected:', symbolParam, '→', formattedSymbol);

        // Clean the URL to remove the ugly parameters
        const cleanUrl = window.location.protocol + "//" + window.location.host + window.location.pathname;
        window.history.replaceState({ path: cleanUrl }, '', cleanUrl);
    }

    // Set up lazy loading observers for all widget cards
    const widgetCards = document.querySelectorAll('.widget-card');
    widgetCards.forEach((card, index) => {
        const widgetId = card.querySelector('[id$="-widget"]').id.replace('-widget', '');
        card.dataset.widgetId = widgetId;

        // Set initial state
        widgetStates.set(widgetId, 'pending');

        // Observe for lazy loading
        widgetObserver.observe(card);
    });

    // Allow Enter key to trigger update
    const symbolInput = document.getElementById('symbolInput');
    symbolInput.addEventListener('keypress', function (e) {
        if (e.key === 'Enter') {
            updateSymbol();
        }
    });

    // Add input event for live feedback (optional)
    symbolInput.addEventListener('input', function (e) {
        const value = e.target.value.trim().toUpperCase();

        // Auto-format as user types
        if (value && !value.includes(':') && value.length >= 4 && value.length <= 6) {
            // Show preview of formatted symbol
            const preview = document.querySelector('.symbol-preview');
            if (preview) {
                preview.textContent = `BMFBOVESPA:${value}`;
            }
        }
    });

    // Initial notification
    showNotification('✨ Dashboard carregada com sucesso!', 'success');

    // If there was a URL parameter, the widgets will load with that symbol automatically
    // No need to call performSymbolUpdate because currentSymbol is already set
});
