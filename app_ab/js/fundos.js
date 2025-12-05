/* ============================================================================
   SUPABASE CONNECTION
   ============================================================================ */

// Supabase Configuration (from .env - to be replaced in production)
const SUPABASE_URL = 'https://ajrdmeqsanhvwjzqowxc.supabase.co';
const SUPABASE_ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImFqcmRtZXFzYW5odndqenFvd3hjIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MzI1NTkzNDksImV4cCI6MjA0ODEzNTM0OX0.JY6rXJ-KLx2XPT8SzGxEXsMi9-tqPQ1kXh-_AW8PD0k';

// Initialize Supabase client
const supabase = window.supabase.createClient(SUPABASE_URL, SUPABASE_ANON_KEY);

/* ============================================================================
   STATE MANAGEMENT
   ============================================================================ */

let currentMonth = null;
let availableMonths = [];

/* ============================================================================
   UTILITY FUNCTIONS
   ============================================================================ */

// Format currency
function formatCurrency(value) {
    if (!value || isNaN(value)) return 'R$ 0,00';

    const absValue = Math.abs(value);

    if (absValue >= 1e9) {
        return `R$ ${(value / 1e9).toFixed(2)}B`;
    } else if (absValue >= 1e6) {
        return `R$ ${(value / 1e6).toFixed(2)}M`;
    } else if (absValue >= 1e3) {
        return `R$ ${(value / 1e3).toFixed(2)}K`;
    }

    return new Intl.NumberFormat('pt-BR', {
        style: 'currency',
        currency: 'BRL'
    }).format(value);
}

// Format number
function formatNumber(value) {
    if (!value || isNaN(value)) return '0';
    return new Intl.NumberFormat('pt-BR').format(value);
}

// Format date
function formatDate(dateStr) {
    if (!dateStr) return '';
    const date = new Date(dateStr);
    return date.toLocaleDateString('pt-BR', { year: 'numeric', month: 'short' });
}

// Get month range
function getMonthRange(monthStr) {
    const date = new Date(monthStr);
    const start = new Date(date.getFullYear(), date.getMonth(), 1);
    const end = new Date(date.getFullYear(), date.getMonth() + 1, 1);

    return {
        start: start.toISOString().split('T')[0],
        end: end.toISOString().split('T')[0]
    };
}

/* ============================================================================
   DATA FETCHING FUNCTIONS
   ============================================================================ */

// Fetch available months
async function fetchAvailableMonths() {
    try {
        const { data, error } = await supabase
            .from('v_meses_disponiveis')
            .select('*')
            .order('mes', { ascending: false })
            .limit(12);

        if (error) throw error;

        availableMonths = data || [];
        return availableMonths;
    } catch (error) {
        console.error('Error fetching months:', error);
        return [];
    }
}

// Fetch summary metrics
async function fetchSummaryMetrics(monthStart, monthEnd) {
    try {
        // Get total fundos
        const { data: fundosData, error: fundosError } = await supabase
            .from('patrimonio_liquido')
            .select('fundo_id', { count: 'exact', head: true })
            .gte('data_competencia', monthStart)
            .lt('data_competencia', monthEnd);

        // Get total PL
        const { data: plData, error: plError } = await supabase
            .from('patrimonio_liquido')
            .select('valor_pl')
            .gte('data_competencia', monthStart)
            .lt('data_competencia', monthEnd);

        // Get distinct ativos
        const { data: ativosData, error: ativosError } = await supabase
            .from('posicoes')
            .select('ativo_id', { count: 'exact', head: true })
            .gte('data_competencia', monthStart)
            .lt('data_competencia', monthEnd)
            .not('ativo_id', 'is', null);

        const totalPL = plData?.reduce((sum, row) => sum + (row.valor_pl || 0), 0) || 0;

        return {
            totalFundos: fundosData?.length || 0,
            totalPL: totalPL,
            totalAtivos: ativosData?.length || 0
        };
    } catch (error) {
        console.error('Error fetching summary metrics:', error);
        return { totalFundos: 0, totalPL: 0, totalAtivos: 0 };
    }
}

// Fetch top compradores
async function fetchTopCompradores(monthStart, monthEnd) {
    try {
        const { data, error } = await supabase
            .from('v_top_compradores')
            .select('*')
            .gte('data_competencia', monthStart)
            .lt('data_competencia', monthEnd)
            .order('total_compras', { ascending: false })
            .limit(10);

        if (error) throw error;
        return data || [];
    } catch (error) {
        console.error('Error fetching top compradores:', error);
        return [];
    }
}

// Fetch top vendedores
async function fetchTopVendedores(monthStart, monthEnd) {
    try {
        const { data, error } = await supabase
            .from('v_top_vendedores')
            .select('*')
            .gte('data_competencia', monthStart)
            .lt('data_competencia', monthEnd)
            .order('total_vendas', { ascending: false })
            .limit(10);

        if (error) throw error;
        return data || [];
    } catch (error) {
        console.error('Error fetching top vendedores:', error);
        return [];
    }
}

// Fetch patrimônio evolution
async function fetchPatrimonioEvolution() {
    try {
        const { data, error } = await supabase
            .from('patrimonio_liquido')
            .select('data_competencia, valor_pl')
            .order('data_competencia', { ascending: false })
            .limit(12);

        if (error) throw error;

        // Aggregate by month
        const monthlyData = {};
        data.forEach(row => {
            const month = row.data_competencia.substring(0, 7); // YYYY-MM
            if (!monthlyData[month]) {
                monthlyData[month] = 0;
            }
            monthlyData[month] += row.valor_pl || 0;
        });

        // Convert to array and sort
        return Object.entries(monthlyData)
            .map(([month, total]) => ({ month, total }))
            .sort((a, b) => b.month.localeCompare(a.month))
            .slice(0, 6);
    } catch (error) {
        console.error('Error fetching patrimônio evolution:', error);
        return [];
    }
}

// Fetch ativos populares
async function fetchAtivosPopulares(monthStart, monthEnd) {
    try {
        const { data, error } = await supabase
            .from('v_ativos_populares')
            .select('*')
            .gte('data_competencia', monthStart)
            .lt('data_competencia', monthEnd)
            .order('num_fundos', { ascending: false })
            .limit(20);

        if (error) throw error;
        return data || [];
    } catch (error) {
        console.error('Error fetching ativos populares:', error);
        return [];
    }
}

// Fetch fundo details
async function fetchFundoDetails(fundoId, monthStart, monthEnd) {
    try {
        // Get fundo info
        const { data: fundoData, error: fundoError } = await supabase
            .from('fundos')
            .select('*')
            .eq('id', fundoId)
            .single();

        if (fundoError) throw fundoError;

        // Get PL
        const { data: plData, error: plError } = await supabase
            .from('patrimonio_liquido')
            .select('valor_pl, num_cotistas')
            .eq('fundo_id', fundoId)
            .gte('data_competencia', monthStart)
            .lt('data_competencia', monthEnd)
            .order('data_competencia', { ascending: false })
            .limit(1);

        // Get top ativos
        const { data: ativosData, error: ativosError } = await supabase
            .rpc('get_fundo_top_ativos', {
                p_fundo_id: fundoId,
                p_mes_start: monthStart,
                p_mes_end: monthEnd
            });

        return {
            fundo: fundoData,
            pl: plData?.[0] || null,
            ativos: ativosData || []
        };
    } catch (error) {
        console.error('Error fetching fundo details:', error);
        return null;
    }
}

/* ============================================================================
   RENDER FUNCTIONS
   ============================================================================ */

// Render month selector
function renderMonthSelector(months) {
    const selector = document.getElementById('monthSelector');

    if (!months || months.length === 0) {
        selector.innerHTML = '<p style="color: rgba(255,255,255,0.6)">Nenhum mês disponível</p>';
        return;
    }

    selector.innerHTML = months.map((m, index) => {
        const active = index === 0 ? 'active' : '';
        return `
            <button class="month-btn ${active}" data-month="${m.mes}">
                ${formatDate(m.mes)}
            </button>
        `;
    }).join('');

    // Add click handlers
    selector.querySelectorAll('.month-btn').forEach(btn => {
        btn.addEventListener('click', () => handleMonthChange(btn.dataset.month));
    });

    // Set current month to first available
    if (months.length > 0) {
        currentMonth = months[0].mes;
    }
}

// Render summary metrics
function renderSummaryMetrics(metrics) {
    document.getElementById('totalFundos').textContent = formatNumber(metrics.totalFundos);
    document.getElementById('totalPL').textContent = formatCurrency(metrics.totalPL);
    document.getElementById('totalAtivos').textContent = formatNumber(metrics.totalAtivos);
}

// Render mover card
function renderMoverCard(mover, type) {
    const value = type === 'compra' ? mover.total_compras : mover.total_vendas;
    const valueClass = type === 'compra' ? 'positive' : 'negative';
    const sign = type === 'compra' ? '+' : '-';

    return `
        <div class="mover-card" data-fundo-id="${mover.fundo_id}" onclick="openFundoModal('${mover.fundo_id}')">
            <div class="mover-card-header">
                <div class="mover-info">
                    <h4>${mover.nome_fundo}</h4>
                    <p>${mover.gestor || 'Gestor não disponível'}</p>
                </div>
                <div class="mover-value">
                    <div class="value-change ${valueClass}">
                        ${sign}${formatCurrency(Math.abs(value))}
                    </div>
                    <div class="num-operacoes">${mover.num_operacoes || 0} ops</div>
                </div>
            </div>
            <div class="mover-meta">
                <div class="meta-item">
                    <div class="meta-label">Patrimônio</div>
                    <div class="meta-value">${formatCurrency(mover.valor_pl)}</div>
                </div>
            </div>
        </div>
    `;
}

// Render top movers lists
function renderTopMovers(compradores, vendedores) {
    const compradoresContainer = document.getElementById('topCompradores');
    const vendedoresContainer = document.getElementById('topVendedores');
    const compradoresCount = document.getElementById('compradoresCount');
    const vendedoresCount = document.getElementById('vendedoresCount');

    // Update counts
    compradoresCount.textContent = compradores.length;
    vendedoresCount.textContent = vendedores.length;

    // Render compradores
    if (compradores.length === 0) {
        compradoresContainer.innerHTML = document.getElementById('emptyStateTemplate').innerHTML;
    } else {
        compradoresContainer.innerHTML = compradores.map(c => renderMoverCard(c, 'compra')).join('');
    }

    // Render vendedores
    if (vendedores.length === 0) {
        vendedoresContainer.innerHTML = document.getElementById('emptyStateTemplate').innerHTML;
    } else {
        vendedoresContainer.innerHTML = vendedores.map(v => renderMoverCard(v, 'venda')).join('');
    }
}

// Render patrimônio evolution
function renderPatrimonioEvolution(data) {
    const container = document.getElementById('patrimonioContent');

    if (!data || data.length === 0) {
        container.innerHTML = document.getElementById('emptyStateTemplate').innerHTML;
        return;
    }

    const maxValue = Math.max(...data.map(d => d.total));

    container.innerHTML = `
        <div class="patrimonio-chart">
            ${data.map(item => {
                const percentage = (item.total / maxValue) * 100;
                return `
                    <div class="patrimonio-item">
                        <div class="patrimonio-month">${formatDate(item.month + '-01')}</div>
                        <div class="patrimonio-bar-container">
                            <div class="patrimonio-bar" style="width: ${percentage}%">
                                <span class="patrimonio-bar-value">${formatCurrency(item.total)}</span>
                            </div>
                        </div>
                    </div>
                `;
            }).join('')}
        </div>
    `;
}

// Render ativos populares
function renderAtivosPopulares(ativos) {
    const container = document.getElementById('ativosPopulares');

    if (!ativos || ativos.length === 0) {
        container.innerHTML = document.getElementById('emptyStateTemplate').innerHTML;
        return;
    }

    container.innerHTML = ativos.map((ativo, index) => `
        <div class="popular-item">
            <div class="popular-rank">${index + 1}</div>
            <div class="popular-info">
                <div class="popular-ticker">${ativo.ticker || 'N/A'}</div>
                <div class="popular-tipo">${ativo.tipo_ativo || ''}</div>
            </div>
            <div class="popular-stats">
                <div class="stat">
                    <span class="stat-value">${formatNumber(ativo.num_fundos)}</span>
                    <span class="stat-label">Fundos</span>
                </div>
                <div class="stat">
                    <span class="stat-value">${formatCurrency(ativo.total_valor_mercado)}</span>
                    <span class="stat-label">Valor Total</span>
                </div>
            </div>
        </div>
    `).join('');
}

/* ============================================================================
   MODAL FUNCTIONS
   ============================================================================ */

async function openFundoModal(fundoId) {
    const modal = document.getElementById('fundoModal');
    const modalContent = document.getElementById('modalContent');

    // Show modal with loading
    modal.classList.add('active');
    modalContent.innerHTML = `
        <div class="loading-state">
            <div class="spinner"></div>
            <p>Carregando detalhes...</p>
        </div>
    `;

    // Fetch data
    const range = getMonthRange(currentMonth);
    const details = await fetchFundoDetails(fundoId, range.start, range.end);

    if (!details || !details.fundo) {
        modalContent.innerHTML = `
            <div class="empty-state">
                <div class="empty-icon">⚠️</div>
                <p class="empty-text">Não foi possível carregar os detalhes do fundo</p>
            </div>
        `;
        return;
    }

    // Render fundo details
    modalContent.innerHTML = `
        <div class="fundo-detail-header">
            <h2 class="fundo-name">${details.fundo.nome_fundo}</h2>
            <p class="fundo-gestor">${details.fundo.gestor || 'Gestor não disponível'}</p>
        </div>

        <div class="fundo-stats">
            <div class="fundo-stat-card">
                <div class="fundo-stat-label">Patrimônio Líquido</div>
                <div class="fundo-stat-value">${formatCurrency(details.pl?.valor_pl)}</div>
            </div>
            <div class="fundo-stat-card">
                <div class="fundo-stat-label">Cotistas</div>
                <div class="fundo-stat-value">${formatNumber(details.pl?.num_cotistas)}</div>
            </div>
            <div class="fundo-stat-card">
                <div class="fundo-stat-label">CNPJ</div>
                <div class="fundo-stat-value" style="font-size: 1rem;">${details.fundo.cnpj || 'N/A'}</div>
            </div>
        </div>

        ${details.ativos && details.ativos.length > 0 ? `
            <div class="fundo-ativos">
                <h3>Top Ativos</h3>
                ${details.ativos.map(ativo => `
                    <div class="ativo-item">
                        <span class="ativo-ticker">${ativo.ticker}</span>
                        <span class="ativo-value">${formatCurrency(ativo.total_valor)}</span>
                    </div>
                `).join('')}
            </div>
        ` : ''}
    `;
}

function closeModal() {
    document.getElementById('fundoModal').classList.remove('active');
}

// Close modal on Escape key
document.addEventListener('keydown', (e) => {
    if (e.key === 'Escape') {
        closeModal();
    }
});

/* ============================================================================
   EVENT HANDLERS
   ============================================================================ */

async function handleMonthChange(month) {
    currentMonth = month;

    // Update active button
    document.querySelectorAll('.month-btn').forEach(btn => {
        btn.classList.toggle('active', btn.dataset.month === month);
    });

    // Load data for selected month
    await loadMonthData(month);
}

async function loadMonthData(month) {
    const range = getMonthRange(month);

    // Show loading states
    document.getElementById('topCompradores').innerHTML = '<div class="loading-state"><div class="spinner"></div><p>Carregando...</p></div>';
    document.getElementById('topVendedores').innerHTML = '<div class="loading-state"><div class="spinner"></div><p>Carregando...</p></div>';
    document.getElementById('ativosPopulares').innerHTML = '<div class="loading-state"><div class="spinner"></div><p>Carregando...</p></div>';

    // Fetch all data in parallel
    const [metrics, compradores, vendedores, ativos] = await Promise.all([
        fetchSummaryMetrics(range.start, range.end),
        fetchTopCompradores(range.start, range.end),
        fetchTopVendedores(range.start, range.end),
        fetchAtivosPopulares(range.start, range.end)
    ]);

    // Render data
    renderSummaryMetrics(metrics);
    renderTopMovers(compradores, vendedores);
    renderAtivosPopulares(ativos);
}

/* ============================================================================
   INITIALIZATION
   ============================================================================ */

async function init() {
    try {
        // Fetch available months
        const months = await fetchAvailableMonths();
        renderMonthSelector(months);

        if (months.length > 0) {
            // Load data for first month
            await loadMonthData(months[0].mes);

            // Load patrimônio evolution (independent of month selection)
            const patrimonioData = await fetchPatrimonioEvolution();
            renderPatrimonioEvolution(patrimonioData);
        } else {
            // No data available
            document.getElementById('summaryMetrics').innerHTML = '<p style="grid-column: 1/-1; text-align: center; color: rgba(255,255,255,0.6)">Nenhum dado disponível</p>';
        }
    } catch (error) {
        console.error('Error initializing dashboard:', error);
    }
}

// Run on page load
document.addEventListener('DOMContentLoaded', init);
