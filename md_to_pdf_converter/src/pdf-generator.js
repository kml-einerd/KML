/**
 * PDF Generator
 * Renders HTML to PDF using Puppeteer.
 */

import puppeteer from 'puppeteer';
import fs from 'fs-extra';
import path from 'path';

export async function generatePdf(htmlContent, outputPath, options = {}) {
    const usePagedJS = options.usePagedJS !== false; // Default true

    console.log(`🚀 Launching browser... (Paged.js: ${usePagedJS ? 'enabled' : 'disabled'})`);
    const browser = await puppeteer.launch({
        headless: "new",
        args: [
            '--no-sandbox',
            '--disable-setuid-sandbox',
            '--disable-web-security',
            '--disable-features=IsolateOrigins,site-per-process'
        ]
    });
    const page = await browser.newPage();

    // Set user agent to avoid being blocked by image hosts
    await page.setUserAgent('Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36');

    // Set extra HTTP headers
    await page.setExtraHTTPHeaders({
        'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,image/apng,*/*;q=0.8',
        'Accept-Language': 'pt-BR,pt;q=0.9,en-US;q=0.8,en;q=0.7',
        'Referer': 'https://www.google.com/'
    });

    // Enable request interception to handle image loading
    await page.setRequestInterception(true);
    page.on('request', (request) => {
        // Allow all requests to proceed
        request.continue();
    });

    // Capture page console logs and errors
    page.on('console', msg => {
        const type = msg.type();
        const text = msg.text();
        // Filter out some noisy logs if needed
        if (!text.includes('Failed to load resource')) {
            console.log(`PAGE [${type}]: ${text}`);
        }
    });
    page.on('pageerror', error => console.error('PAGE ERROR:', error.message));

    console.log('📄 Setting content...');
    // Increase timeout for heavy content to 5 minutes
    // Use 'networkidle2' as it's more lenient than 'networkidle0'
    await page.setContent(htmlContent, { waitUntil: 'networkidle2', timeout: 300000 });

    // Manually trigger Mermaid rendering
    console.log('🎨 Triggering Mermaid rendering...');
    await page.evaluate(async () => {
        if (typeof mermaid !== 'undefined') {
            try {
                await mermaid.run({
                    querySelector: '.mermaid'
                });
                window.mermaidRenderComplete = true;
                console.log('Mermaid run finished.');
            } catch (error) {
                console.error('Mermaid rendering error:', error);
                window.mermaidRenderComplete = false;
                window.mermaidError = error.message;
            }
        } else {
            console.error('Mermaid not loaded!');
            window.mermaidRenderComplete = false;
        }
    });

    // Wait for rendering to complete (dynamic wait)
    console.log('⏳ Waiting for diagrams to render...');
    try {
        await page.waitForFunction(() => window.mermaidRenderComplete === true, { timeout: 30000 });
        console.log('✅ Mermaid rendering complete.');
    } catch (e) {
        console.warn('⚠️ Mermaid rendering timed out or failed (might be no diagrams).');
    }

    // Give a little extra time for layout to settle after diagrams appear
    await new Promise(resolve => setTimeout(resolve, 2000));

    // Check Mermaid rendering status with detailed debugging
    const mermaidStatus = await page.evaluate(() => {
        const diagrams = document.querySelectorAll('.mermaid');
        const svgs = document.querySelectorAll('.mermaid svg');

        return {
            total: diagrams.length,
            rendered: svgs.length,
            complete: window.mermaidRenderComplete
        };
    });

    console.log(`🎨 Mermaid status: ${mermaidStatus.rendered}/${mermaidStatus.total} diagrams rendered`);

    // Wait for Paged.js to finish rendering
    try {
        console.log('⏳ Waiting for Paged.js...');
        // Wait for the pagedjs hook or selector
        await page.waitForSelector('.pagedjs_pages', { timeout: 120000 });

        // Extra wait for Paged.js to complete all page breaks
        // For large documents, this needs to be significant
        console.log('⏳ Allowing extra time for pagination (20s)...');
        await new Promise(resolve => setTimeout(resolve, 20000));

        // Check if pagination is complete
        const pageCount = await page.evaluate(() => {
            return document.querySelectorAll('.pagedjs_page').length;
        });
        console.log(`📖 Generated ${pageCount} pages`);

        // Wait for all images to load with better error handling
        console.log('⏳ Waiting for external images to load...');

        // First, force reload all images to ensure they're fetched
        await page.evaluate(() => {
            const images = Array.from(document.images);
            images.forEach(img => {
                if (!img.complete) {
                    const src = img.src;
                    img.src = '';
                    img.src = src;
                }
            });
        });

        // Wait a bit for images to start loading
        await new Promise(resolve => setTimeout(resolve, 2000));

        const imageLoadResults = await page.evaluate(() => {
            const images = Array.from(document.images);
            console.log(`Found ${images.length} images`);

            return Promise.all(
                images.map((img, index) => {
                    // Base64/data URI images are already embedded, consider them loaded
                    if (img.src.startsWith('data:')) {
                        console.log(`Image ${index + 1} is embedded (base64), skipping wait`);
                        return Promise.resolve({ loaded: true, index, embedded: true });
                    }

                    if (img.complete && img.naturalHeight !== 0) {
                        console.log(`Image ${index + 1} already loaded`);
                        return Promise.resolve({ loaded: true, index });
                    }

                    return new Promise(resolve => {
                        const timeout = setTimeout(() => {
                            // Even if timeout, check if image is now loaded
                            const isLoaded = img.complete && img.naturalHeight !== 0;
                            if (isLoaded) {
                                console.log(`Image ${index + 1} loaded after timeout check`);
                                resolve({ loaded: true, index });
                            } else {
                                console.warn(`Image ${index + 1} timeout: ${img.src.substring(0, 60)}...`);
                                resolve({ loaded: false, index, reason: 'timeout' });
                            }
                        }, 10000); // Reduced to 10s

                        img.addEventListener('load', () => {
                            clearTimeout(timeout);
                            console.log(`Image ${index + 1} loaded`);
                            resolve({ loaded: true, index });
                        });

                        img.addEventListener('error', () => {
                            clearTimeout(timeout);
                            console.error(`Image ${index + 1} error: ${img.src.substring(0, 60)}...`);
                            resolve({ loaded: false, index, reason: 'error' });
                        });
                    });
                })
            );
        });

        const loadedCount = imageLoadResults.filter(r => r.loaded).length;
        console.log(`✅ Images: ${loadedCount}/${imageLoadResults.length} loaded successfully`);

        // Log failed images
        const failedImages = imageLoadResults.filter(r => !r.loaded);
        if (failedImages.length > 0) {
            console.warn(`⚠️  ${failedImages.length} image(s) failed to load, but PDF will still be generated`);
        }

        // Final wait for layout stabilization
        console.log('⏳ Final layout stabilization (5s)...');
        await new Promise(resolve => setTimeout(resolve, 5000));

    } catch (e) {
        console.warn('⚠️  Paged.js not detected or timed out');
    }

    console.log('🖨️  Printing PDF...');
    await page.pdf({
        path: outputPath,
        format: 'A4',
        printBackground: true,
        preferCSSPageSize: true,
        displayHeaderFooter: false,
        margin: { top: 0, right: 0, bottom: 0, left: 0 }, // Let CSS handle margins
        timeout: 300000 // 5 minutes print timeout
    });

    await browser.close();
    console.log(`✅ PDF saved to: ${outputPath}`);
}
