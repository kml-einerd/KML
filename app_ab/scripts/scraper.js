#!/usr/bin/env node

/**
 * SCRAPER DE WIDGETS TRADINGVIEW
 * Captura dados a cada 10 segundos e salva em CSV
 */

const puppeteer = require('puppeteer');
const fs = require('fs');
const path = require('path');

// ========== CONFIGURAÇÕES ==========
const CONFIG = {
    url: 'http://localhost:8001/pages/test_widget.html',
    csvFile: 'base_atual.csv',
    updateInterval: 10000, // 10 segundos em milissegundos
    screenshotDir: 'screenshots' // Pasta para screenshots (opcional)
};

// ========== FUNÇÕES AUXILIARES ==========

function getTimestamp() {
    return new Date().toISOString().replace('T', ' ').substring(0, 19);
}

function log(emoji, message) {
    console.log(`${emoji} [${new Date().toLocaleTimeString('pt-BR')}] ${message}`);
}

function salvarCSV(dados, modo = 'append') {
    const csvPath = path.join(__dirname, CONFIG.csvFile);
    const arquivoExiste = fs.existsSync(csvPath);

    // Cabeçalho do CSV
    const header = 'timestamp,ticker,preco,variacao,volume,setor,dados_completos\n';

    if (modo === 'overwrite' || !arquivoExiste) {
        fs.writeFileSync(csvPath, header);
    }

    // Adicionar dados
    if (dados.length > 0) {
        const linhas = dados.map(d =>
            `"${d.timestamp}","${d.ticker}","${d.preco}","${d.variacao}","${d.volume}","${d.setor}","${d.dados_completos}"`
        ).join('\n') + '\n';

        fs.appendFileSync(csvPath, linhas);
        log('💾', `${dados.length} registros salvos em ${CONFIG.csvFile}`);
    } else {
        log('⚠️ ', 'Nenhum dado para salvar');
    }
}

async function extrairDados(page) {
    log('🔍', 'Extraindo dados dos widgets...');

    try {
        // Aguardar widgets carregarem
        await page.waitForSelector('.tradingview-widget-container', { timeout: 15000 });
        await page.waitForTimeout(5000); // Aguardar dados carregarem

        // Extrair dados usando JavaScript no contexto da página
        const dados = await page.evaluate(() => {
            const resultado = [];
            const timestamp = new Date().toISOString().replace('T', ' ').substring(0, 19);

            // Tentar capturar iframes do TradingView
            const iframes = document.querySelectorAll('iframe');

            // Se não conseguir dos iframes, capturar do DOM principal
            const linhas = document.querySelectorAll('tr, .tv-symbol-row, [class*="row"]');

            linhas.forEach(linha => {
                const texto = linha.innerText || linha.textContent || '';
                if (!texto.trim()) return;

                // Tentar identificar ticker (padrão brasileiro: 4 letras + número)
                const matchTicker = texto.match(/([A-Z]{4}\d)/g);

                if (matchTicker) {
                    const ticker = matchTicker[0];

                    // Tentar extrair preço (números com vírgula/ponto)
                    const matchPreco = texto.match(/R?\$?\s*(\d+[.,]\d{2})/);
                    const preco = matchPreco ? matchPreco[1] : '';

                    // Tentar extrair variação (%)
                    const matchVariacao = texto.match(/([+-]?\d+[.,]\d+)%/);
                    const variacao = matchVariacao ? matchVariacao[1] : '';

                    // Extrair setor (texto após o ticker)
                    const partes = texto.split(ticker);
                    const setor = partes[1] ? partes[1].split(/[\d.,]/)[0].trim() : '';

                    resultado.push({
                        timestamp,
                        ticker,
                        preco,
                        variacao,
                        volume: '',
                        setor,
                        dados_completos: texto.replace(/\n/g, ' ').trim()
                    });
                }
            });

            // Se não encontrou nada, capturar todo o texto visível
            if (resultado.length === 0) {
                const bodyText = document.body.innerText;
                const linhasTexto = bodyText.split('\n').filter(l => l.trim());

                linhasTexto.forEach(linha => {
                    const matchTicker = linha.match(/([A-Z]{4}\d)/);
                    if (matchTicker) {
                        resultado.push({
                            timestamp,
                            ticker: matchTicker[1],
                            preco: '',
                            variacao: '',
                            volume: '',
                            setor: '',
                            dados_completos: linha.trim()
                        });
                    }
                });
            }

            return resultado;
        });

        log('✅', `${dados.length} registros extraídos`);
        return dados;

    } catch (error) {
        log('❌', `Erro ao extrair: ${error.message}`);
        return [];
    }
}

async function tirarScreenshot(page, iteracao) {
    try {
        const dir = path.join(__dirname, CONFIG.screenshotDir);
        if (!fs.existsSync(dir)) {
            fs.mkdirSync(dir);
        }

        const filename = `screenshot_${iteracao}_${Date.now()}.png`;
        const filepath = path.join(dir, filename);

        await page.screenshot({
            path: filepath,
            fullPage: true
        });

        log('📸', `Screenshot salvo: ${filename}`);
    } catch (error) {
        log('⚠️ ', `Erro ao tirar screenshot: ${error.message}`);
    }
}

// ========== LOOP PRINCIPAL ==========

async function iniciarScraper() {
    console.log('═'.repeat(60));
    console.log('  🤖 SCRAPER DE WIDGETS TRADINGVIEW (Node.js)');
    console.log('═'.repeat(60));
    console.log(`📊 URL: ${CONFIG.url}`);
    console.log(`💾 CSV: ${CONFIG.csvFile}`);
    console.log(`⏱️  Intervalo: ${CONFIG.updateInterval / 1000} segundos`);
    console.log('═'.repeat(60));
    console.log();

    const browser = await puppeteer.launch({
        headless: true,
        args: ['--no-sandbox', '--disable-setuid-sandbox']
    });

    const page = await browser.newPage();
    await page.setViewport({ width: 1920, height: 1080 });

    log('🌐', 'Navegando para a página...');

    try {
        await page.goto(CONFIG.url, {
            waitUntil: 'networkidle2',
            timeout: 30000
        });

        log('✅', 'Página carregada com sucesso');
        console.log();

        let iteracao = 0;

        // Loop infinito
        while (true) {
            iteracao++;

            console.log('\n' + '─'.repeat(60));
            console.log(`🔄 Iteração #${iteracao} - ${getTimestamp()}`);
            console.log('─'.repeat(60));

            // Recarregar para pegar dados atualizados
            await page.reload({ waitUntil: 'networkidle2' });

            // Extrair dados
            const dados = await extrairDados(page);

            // Salvar em CSV
            if (dados.length > 0) {
                salvarCSV(dados);
            }

            // Screenshot opcional (descomente se quiser)
            // await tirarScreenshot(page, iteracao);

            // Aguardar próximo ciclo
            log('⏳', `Aguardando ${CONFIG.updateInterval / 1000} segundos...`);
            await new Promise(resolve => setTimeout(resolve, CONFIG.updateInterval));
        }

    } catch (error) {
        log('❌', `Erro fatal: ${error.message}`);
    } finally {
        await browser.close();
        log('✅', 'Browser fechado');
        console.log('═'.repeat(60));
    }
}

// ========== EXECUÇÃO ==========

console.log('\n⚠️  IMPORTANTE: Certifique-se que o servidor está rodando!');
console.log('   Execute em outro terminal: python3 -m http.server 8001\n');

// Aguardar 3 segundos para o usuário ler a mensagem
setTimeout(() => {
    log('🚀', 'Iniciando scraper em 2 segundos...');
    setTimeout(iniciarScraper, 2000);
}, 1000);

// Tratamento de interrupção (Ctrl+C)
process.on('SIGINT', () => {
    console.log('\n\n🛑 Scraper interrompido pelo usuário');
    process.exit(0);
});
