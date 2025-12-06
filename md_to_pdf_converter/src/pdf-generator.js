/**
 * PDF Generator
 * Renders HTML to PDF using Puppeteer.
 */

import puppeteer from 'puppeteer';
import fs from 'fs-extra';
import path from 'path';

export async function generatePdf(htmlContent, outputPath) {
    console.log('🚀 Launching browser...');
    const browser = await puppeteer.launch({
        headless: "new",
        args: ['--no-sandbox', '--disable-setuid-sandbox']
    });
    const page = await browser.newPage();

    console.log('📄 Setting content...');
    await page.setContent(htmlContent, { waitUntil: 'networkidle0', timeout: 60000 });

    // Wait for Paged.js to finish rendering
    try {
        console.log('⏳ Waiting for Paged.js...');
        await page.waitForSelector('.pagedjs_pages', { timeout: 30000 });

        // Extra wait for Paged.js to complete all page breaks
        await new Promise(resolve => setTimeout(resolve, 5000));

        const pageCount = await page.evaluate(() => {
            return document.querySelectorAll('.pagedjs_page').length;
        });
        console.log(`📖 Generated ${pageCount} pages`);
    } catch (e) {
        console.warn('⚠️  Paged.js not detected');
    }

    // Wait for Mermaid diagrams to render
    try {
        await page.waitForFunction(() => {
            const diagrams = document.querySelectorAll('.mermaid');
            return diagrams.length === 0 || Array.from(diagrams).every(d => d.querySelector('svg'));
        }, { timeout: 10000 });
    } catch (e) {
        // If no mermaid diagrams or timeout, just proceed
    }

    console.log('🖨️  Printing PDF...');
    await page.pdf({
        path: outputPath,
        format: 'A4',
        printBackground: true,
        preferCSSPageSize: true,
        displayHeaderFooter: false,
        timeout: 120000
    });

    await browser.close();
    console.log(`✅ PDF saved to: ${outputPath}`);
}
