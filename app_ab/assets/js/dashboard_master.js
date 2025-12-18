// ========================================
// MASTER DASHBOARD CONTROLLER
// ========================================

const SUPABASE_URL = 'https://ryfhupidxkghwkczulgg.supabase.co';
const SUPABASE_ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJ5Zmh1cGlkeGtnaHdrY3p1bGdnIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjU0NjYyMzcsImV4cCI6MjA4MTA0MjIzN30.Bne0WnMN9URE3kock_jd4u-0ZeyFUkKVAcGKr27kF5Q';
const supabase = window.supabase.createClient(SUPABASE_URL, SUPABASE_ANON_KEY);

// State
let state = {
    currentMonth: null,
    charts: {},
};

// ========================================
// INITIALIZATION
// ========================================

document.addEventListener('DOMContentLoaded', async () => {
    lucide.createIcons();
    await initData();
});

async function initData() {
    try {
        await loadMonths();
        
        // Listeners
        document.getElementById('mesSelect').addEventListener('change', (e) => loadData(e.target.value));
        document.getElementById('managerSelect').addEventListener('change', (e) => loadManagerDetails(e.target.value));

    } catch (err) {
        console.error('Init failed:', err);
        alert('Erro ao inicializar dashboard. Verifique sua conexão.');
    }
}

// ========================================
// DATA LOADING
// ========================================

async function loadMonths() {
    // 1. Fetch from summary table (FAST)
    const { data, error } = await supabase
        .from('resumo_mensal')
        .select('mes_referencia')
        .order('mes_referencia', { ascending: false });

    if (error) {
        console.error('Error loading months:', error);
        return;
    }

    // 2. Filter unique strings
    const uniqueMonths = [...new Set(data.map(d => d.mes_referencia))];
    const select = document.getElementById('mesSelect');
    
    if (uniqueMonths.length === 0) {
        select.innerHTML = '<option value="">Sem dados disponíveis</option>';
        return;
    }

    // 3. Populate Select with Timezone-Safe Logic
    select.innerHTML = uniqueMonths.map(m => {
        // m is 'YYYY-MM-DD'
        // We create a Date object using components to avoid timezone shifts
        const parts = m.split('-'); // [2025, 11, 01]
        const year = parseInt(parts[0]);
        const monthIndex = parseInt(parts[1]) - 1; // JS months are 0-11
        const day = parseInt(parts[2]);
        
        const date = new Date(year, monthIndex, day);
        
        // Format: "Novembro 2025"
        const label = date.toLocaleDateString('pt-BR', { month: 'long', year: 'numeric' });
        
        // Capitalize first letter
        const finalLabel = label.charAt(0).toUpperCase() + label.slice(1);
        
        return `<option value="${m}">${finalLabel}</option>`;
    }).join('');

    // 4. Auto-load first month
    if (uniqueMonths.length > 0) {
        select.value = uniqueMonths[0];
        loadData(uniqueMonths[0]);
    }
}

async function loadData(month) {
    if (!month) return;
    state.currentMonth = month;
    toggleLoading(true);

    try {
        // Fetch core data in parallel
        const [overview, managers] = await Promise.all([
            fetchOverview(month),
            fetchManagers()
        ]);

        if (!overview || overview.length === 0) {
            console.warn('No overview data for month:', month);
            // Optional: show empty state
        }

        // Process derived data
        const buys = await fetchTopSignals(month, 'COMPRA');
        const sells = await fetchTopSignals(month, 'VENDA');

        // Update UI Components
        updateOverviewSection(overview || []);
        updateConvictionSection(overview || []); 
        updateSmartMoneySection(buys || [], sells || []);
        updateDiscoverySection(month);
        updateManagersDropdown(managers || []);

        // Update Header Date Display
        const parts = month.split('-');
        const date = new Date(parseInt(parts[0]), parseInt(parts[1]) - 1, parseInt(parts[2]));
        document.getElementById('lastUpdated').textContent = `Dados ref. ${date.toLocaleDateString('pt-BR', {month:'long', year:'numeric'})}`;

    } catch (err) {
        console.error(err);
        alert('Erro ao carregar dados. Verifique a tabela resumo_mensal.');
    } finally {
        toggleLoading(false);
    }
}

// ========================================
// FETCH HELPERS
// ========================================

async function fetchOverview(month) {
    const { data, error } = await supabase
        .from('resumo_mensal')
        .select('*')
        .eq('mes_referencia', month);
    
    if (error) throw error;
    return data;
}

async function fetchTopSignals(month, type) {
    const { data, error } = await supabase
        .from('resumo_mensal')
        .select('*')
        .eq('mes_referencia', month)
        .eq('tendencia_mercado', type)
        .order('intensidade_consenso', { ascending: false })
        .order(type === 'COMPRA' ? 'total_comprado' : 'total_vendido', { ascending: false })
        .limit(50);
        
    if (error) throw error;
    return data;
}

async function fetchManagers() {
    const { data, error } = await supabase
        .from('grupos_fundos')
        .select('id, nome_grupo, pl_total_bilhoes')
        .order('pl_total_bilhoes', { ascending: false })
        .limit(20);
        
    if (error) throw error;
    return data;
}

// ========================================
// RENDER FUNCTIONS
// ========================================

function updateOverviewSection(data) {
    if (data.length === 0) {
        document.getElementById('sentimentScore').textContent = '-';
        return;
    }

    const totalBuy = data.filter(d => d.tendencia_mercado === 'COMPRA').reduce((s, d) => s + (d.total_comprado || 0), 0);
    const totalSell = data.filter(d => d.tendencia_mercado === 'VENDA').reduce((s, d) => s + (d.total_vendido || 0), 0);
    const totalVol = totalBuy + totalSell;
    const sentimentScore = totalVol > 0 ? (totalBuy / totalVol) * 100 : 50;

    document.getElementById('sentimentScore').textContent = Math.round(sentimentScore);
    document.getElementById('totalFlow').textContent = formatCurrencyCompact(totalVol);
    
    document.getElementById('buyVolume').textContent = formatCurrencyCompact(totalBuy);
    document.getElementById('buyBar').style.width = `${totalVol > 0 ? (totalBuy/totalVol)*100 : 0}%`;
    
    document.getElementById('sellVolume').textContent = formatCurrencyCompact(totalSell);
    document.getElementById('sellBar').style.width = `${totalVol > 0 ? (totalSell/totalVol)*100 : 0}%`;

    const badge = document.getElementById('sentimentBadge');
    const insight = document.getElementById('aiInsight');

    if (sentimentScore >= 60) {
        badge.textContent = 'Bullish (Otimista)';
        badge.className = 'mt-2 px-3 py-1 rounded-full text-sm font-bold bg-accent-green/20 text-accent-green border border-accent-green/30';
        insight.textContent = `"Mercado comprador: fluxo de entrada supera saída. Institucionais aumentando exposição."`;
    } else if (sentimentScore <= 40) {
        badge.textContent = 'Bearish (Cautela)';
        badge.className = 'mt-2 px-3 py-1 rounded-full text-sm font-bold bg-accent-red/20 text-accent-red border border-accent-red/30';
        insight.textContent = `"Mercado vendedor: fluxo de saída predominante. Realização de lucros ou proteção."`;
    } else {
        badge.textContent = 'Neutro / Seletivo';
        badge.className = 'mt-2 px-3 py-1 rounded-full text-sm font-bold bg-accent-yellow/20 text-accent-yellow border border-accent-yellow/30';
        insight.textContent = `"Mercado misto: fluxo equilibrado. Stock picking é essencial."`;
    }

    renderGauge(sentimentScore);
    renderOverviewChart(data);
}

function updateConvictionSection(data) {
    const topPicks = data
        .filter(d => d.tendencia_mercado === 'COMPRA' && d.intensidade_consenso >= 80)
        .sort((a, b) => b.total_comprado - a.total_comprado)
        .slice(0, 4);

    const container = document.getElementById('cardsHighConviction');
    
    if (topPicks.length === 0) {
        container.innerHTML = `<div class="col-span-4 text-center text-gray-500 py-10">Sem ativos de alta convicção (>80% consenso) neste período.</div>`;
        return;
    }

    container.innerHTML = topPicks.map(stock => `
        <div class="bg-gray-800 p-5 rounded-2xl border border-gray-700 hover:border-brand-500 hover:shadow-glow transition-all duration-300 group cursor-default">
            <div class="flex justify-between items-start mb-4">
                <div class="w-10 h-10 rounded-full bg-brand-900/50 flex items-center justify-center border border-brand-500/30 text-brand-400 font-bold text-xs">
                    ${stock.ticker.substring(0,4)}
                </div>
                <div class="text-right">
                    <div class="text-accent-green font-mono font-bold text-lg">${Math.round(stock.intensidade_consenso)}%</div>
                    <div class="text-[10px] text-gray-500 uppercase tracking-wide">Consenso</div>
                </div>
            </div>
            
            <h4 class="text-xl font-bold text-white mb-1">${stock.ticker}</h4>
            <p class="text-xs text-gray-400 truncate mb-4">${stock.empresa || '-'}</p>
            
            <div class="pt-4 border-t border-gray-700/50 flex justify-between items-center">
                <div>
                    <div class="text-[10px] text-gray-500 uppercase">Volume Compra</div>
                    <div class="text-sm font-medium text-white">${formatCurrencyCompact(stock.total_comprado)}</div>
                </div>
                <i data-lucide="trending-up" class="w-4 h-4 text-accent-green opacity-50 group-hover:opacity-100 transition-opacity"></i>
            </div>
        </div>
    `).join('');
    
    lucide.createIcons();
}

function updateSmartMoneySection(buys, sells) {
    const renderRow = (row, type) => `
        <tr class="hover:bg-gray-700/30 transition-colors">
            <td class="px-5 py-4 font-bold text-white">${row.ticker}</td>
            <td class="px-5 py-4 text-center">
                <span class="inline-block px-2 py-1 rounded text-xs font-bold ${type === 'COMPRA' ? 'bg-accent-green/10 text-accent-green' : 'bg-accent-red/10 text-accent-red'}">
                    ${Math.round(row.intensidade_consenso)}%
                </span>
            </td>
            <td class="px-5 py-4 text-right font-mono text-gray-300">
                ${formatCurrencyCompact(type === 'COMPRA' ? row.total_comprado : row.total_vendido)}
            </td>
            <td class="px-5 py-4 text-right text-xs text-gray-400">
                ${type === 'COMPRA' ? row.top_comprador : row.top_vendedor || '-'}
            </td>
        </tr>
    `;

    document.querySelector('#tableBuys tbody').innerHTML = buys.length ? buys.slice(0, 15).map(r => renderRow(r, 'COMPRA')).join('') : '<tr><td colspan="4" class="text-center py-4 text-gray-500">Sem dados</td></tr>';
    document.querySelector('#tableSells tbody').innerHTML = sells.length ? sells.slice(0, 15).map(r => renderRow(r, 'VENDA')).join('') : '<tr><td colspan="4" class="text-center py-4 text-gray-500">Sem dados</td></tr>';

    renderScatterChart(buys);
}

async function updateDiscoverySection(month) {
    const { data: gems } = await supabase.from('resumo_mensal')
        .select('*')
        .eq('mes_referencia', month)
        .eq('tendencia_mercado', 'COMPRA')
        .lte('qtd_fundos_compradores', 10)
        .gte('total_comprado', 20000000)
        .order('intensidade_consenso', { ascending: false })
        .limit(5);

    const { data: momentum } = await supabase.from('resumo_mensal')
        .select('*')
        .eq('mes_referencia', month)
        .eq('tendencia_mercado', 'COMPRA')
        .gte('intensidade_consenso', 90)
        .order('total_comprado', { ascending: false })
        .limit(5);

    const renderList = (items, containerId, iconColor) => {
        const container = document.getElementById(containerId);
        if (!items || items.length === 0) {
            container.innerHTML = '<div class="text-sm text-gray-500 italic">Nenhuma oportunidade detectada.</div>';
            return;
        }
        
        container.innerHTML = items.map(item => `
            <div class="flex items-center justify-between p-3 bg-gray-900/40 rounded-lg border border-gray-700/50 hover:bg-gray-700/40 transition-colors">
                <div class="flex items-center gap-3">
                    <div class="w-8 h-8 rounded bg-gray-800 flex items-center justify-center text-xs font-bold text-gray-400">
                        ${item.ticker.substring(0,3)}
                    </div>
                    <div>
                        <div class="font-bold text-sm text-gray-200">${item.ticker}</div>
                        <div class="text-[10px] text-gray-500">${item.qtd_fundos_compradores} Fundos</div>
                    </div>
                </div>
                <div class="text-right">
                    <div class="text-sm font-bold ${iconColor}">${formatCurrencyCompact(item.total_comprado)}</div>
                    <div class="text-[10px] text-gray-500">Vol. Mensal</div>
                </div>
            </div>
        `).join('');
    };

    renderList(gems, 'listHiddenGems', 'text-accent-purple');
    renderList(momentum, 'listMomentum', 'text-brand-500');
}

function updateManagersDropdown(managers) {
    const select = document.getElementById('managerSelect');
    select.innerHTML = '<option value="">Selecione uma Gestora...</option>' + 
        managers.map(m => `<option value="${m.nome_grupo}">${m.nome_grupo} (${formatCurrencyCompact(m.pl_total_bilhoes * 1e9)})</option>`).join('');
}

async function loadManagerDetails(managerName) {
    if (!managerName) return;
    const tbody = document.getElementById('tbodyManagerDetails');
    tbody.innerHTML = '<tr><td colspan="4" class="py-8 text-center"><div class="loader mx-auto"></div></td></tr>';

    try {
        const { data: group } = await supabase.from('grupos_fundos').select('id').eq('nome_grupo', managerName).single();
        if (!group) throw new Error('Grupo não encontrado');

        const { data: moves } = await supabase.from('acoes_fundos')
            .select('*')
            .eq('grupo_id', group.id)
            .eq('mes_referencia', state.currentMonth)
            .order('fluxo_liquido', { ascending: false })
            .limit(20);

        if (!moves || moves.length === 0) {
            tbody.innerHTML = '<tr><td colspan="4" class="py-8 text-center text-gray-500">Sem movimentações relevantes neste mês.</td></tr>';
            return;
        }

        tbody.innerHTML = moves.map(m => `
            <tr class="hover:bg-gray-700/30 transition-colors">
                <td class="px-6 py-4 font-medium text-white">${m.ticker}</td>
                <td class="px-6 py-4 text-center">
                    <span class="px-2 py-1 text-xs rounded font-bold ${m.tipo_movimento === 'COMPRA' ? 'bg-accent-green/20 text-accent-green' : m.tipo_movimento === 'VENDA' ? 'bg-accent-red/20 text-accent-red' : 'bg-gray-700 text-gray-400'}">
                        ${m.tipo_movimento}
                    </span>
                </td>
                <td class="px-6 py-4 text-right font-mono ${m.fluxo_liquido > 0 ? 'text-accent-green' : 'text-accent-red'}">
                    ${formatCurrencyCompact(Math.abs(m.fluxo_liquido))}
                </td>
                <td class="px-6 py-4 text-right font-mono text-gray-300">
                    ${m.rentabilidade_pct ? m.rentabilidade_pct.toFixed(2) + '%' : '-'}
                </td>
            </tr>
        `).join('');

    } catch (err) {
        tbody.innerHTML = '<tr><td colspan="4" class="py-8 text-center text-red-400">Erro ao carregar dados.</td></tr>';
    }
}

function renderGauge(score) {
    const ctx = document.getElementById('gaugeChart').getContext('2d');
    if (state.charts.gauge) state.charts.gauge.destroy();

    state.charts.gauge = new Chart(ctx, {
        type: 'doughnut',
        data: {
            labels: ['Score', 'Resto'],
            datasets: [{
                data: [score, 100 - score],
                backgroundColor: [score > 50 ? '#10b981' : '#ef4444', '#1e293b'],
                borderWidth: 0,
                cutout: '85%',
                circumference: 180,
                rotation: 270,
            }]
        },
        options: {
            responsive: true,
            maintainAspectRatio: false,
            plugins: { legend: { display: false }, tooltip: { enabled: false } }
        }
    });
}

function renderOverviewChart(data) {
    const ctx = document.getElementById('chartOverviewMain').getContext('2d');
    if (state.charts.overview) state.charts.overview.destroy();

    const sorted = data.sort((a,b) => (b.total_comprado + b.total_vendido) - (a.total_comprado + a.total_vendido)).slice(0, 10);

    state.charts.overview = new Chart(ctx, {
        type: 'bar',
        data: {
            labels: sorted.map(d => d.ticker),
            datasets: [
                { label: 'Compra', data: sorted.map(d => d.total_comprado), backgroundColor: '#10b981', borderRadius: 4 },
                { label: 'Venda', data: sorted.map(d => d.total_vendido), backgroundColor: '#ef4444', borderRadius: 4 }
            ]
        },
        options: {
            responsive: true,
            maintainAspectRatio: false,
            scales: {
                x: { stacked: true, grid: { display: false }, ticks: { color: '#64748b', font: {size: 10} } },
                y: { stacked: true, display: false }
            },
            plugins: { legend: { display: false } }
        }
    });
}

function renderScatterChart(buys) {
    const ctx = document.getElementById('chartScatter').getContext('2d');
    if (state.charts.scatter) state.charts.scatter.destroy();

    const points = buys.map(d => ({ x: d.total_comprado, y: d.intensidade_consenso, ticker: d.ticker }));

    state.charts.scatter = new Chart(ctx, {
        type: 'scatter',
        data: {
            datasets: [{
                data: points,
                backgroundColor: 'rgba(16, 185, 129, 0.6)',
                borderColor: '#10b981',
                pointRadius: 6,
                pointHoverRadius: 10
            }]
        },
        options: {
            responsive: true,
            maintainAspectRatio: false,
            scales: {
                x: { type: 'logarithmic', grid: { color: '#334155' }, ticks: { color: '#64748b', callback: val => formatCurrencyCompact(val) } },
                y: { min: 0, max: 105, grid: { color: '#334155' }, ticks: { color: '#64748b' } }
            },
            plugins: {
                legend: { display: false },
                tooltip: {
                    callbacks: {
                        label: (ctx) => `${ctx.raw.ticker}: ${formatCurrencyCompact(ctx.raw.x)} (Consenso: ${Math.round(ctx.raw.y)}%)`
                    }
                }
            }
        }
    });
}

function toggleLoading(show) {
    const el = document.getElementById('loadingState');
    if (show) el.classList.remove('hidden');
    else el.classList.add('hidden');
}

function formatCurrencyCompact(val) {
    if (val >= 1e9) return 'R$ ' + (val / 1e9).toFixed(1) + 'B';
    if (val >= 1e6) return 'R$ ' + (val / 1e6).toFixed(1) + 'M';
    if (val >= 1e3) return 'R$ ' + (val / 1e3).toFixed(1) + 'K';
    return 'R$ ' + val;
}
