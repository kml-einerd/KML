/**
 * Thumbnail Generator
 * Generates PNG thumbnails for each CSS theme using a sample markdown file
 */

import puppeteer from 'puppeteer';
import fs from 'fs-extra';
import path from 'path';
import { fileURLToPath } from 'url';
import { processMarkdown } from './html-processor.js';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const projectRoot = path.dirname(__dirname);

/**
 * Generate thumbnails for all available themes
 */
export async function generateThumbnails() {
    console.log('🎨 Starting thumbnail generation...\n');

    try {
        // Ensure thumbnails directory exists
        const thumbnailsDir = path.join(projectRoot, 'public/thumbnails');
        await fs.ensureDir(thumbnailsDir);

        // Get list of themes
        const themesDir = path.join(projectRoot, 'assets/themes');
        const themeFiles = await fs.readdir(themesDir);
        const themes = themeFiles
            .filter(f => f.endsWith('.css'))
            .map(f => f.replace('.css', ''));

        console.log(`📋 Found ${themes.length} themes to process\n`);

        // Read sample markdown file
        const sampleMarkdown = await fs.readFile(
            path.join(projectRoot, 'exemplo.md'),
            'utf-8'
        );

        // Read base template
        const templatePath = path.join(projectRoot, 'assets/templates/base.html');
        const baseTemplate = await fs.readFile(templatePath, 'utf-8');

        // Launch browser once for all thumbnails
        console.log('🚀 Launching browser...');
        const browser = await puppeteer.launch({
            headless: 'new',
            args: ['--no-sandbox', '--disable-setuid-sandbox']
        });

        const page = await browser.newPage();

        // Set viewport to A4 proportions (scaled down)
        await page.setViewport({
            width: 794,  // A4 width in pixels at 96 DPI
            height: 1123, // A4 height in pixels at 96 DPI
            deviceScaleFactor: 1
        });

        // Process each theme
        for (let i = 0; i < themes.length; i++) {
            const theme = themes[i];
            const progress = `[${i + 1}/${themes.length}]`;

            try {
                console.log(`${progress} 🎨 Processing "${theme}"...`);

                // Process markdown
                const { html, metadata } = await processMarkdown(sampleMarkdown);

                // Read theme CSS
                const themePath = path.join(themesDir, `${theme}.css`);
                const cssContent = await fs.readFile(themePath, 'utf-8');

                // Prepare template data
                const templateData = {
                    title: metadata.title || 'Sample Document',
                    subtitle: metadata.subtitle || '',
                    author: metadata.author || '',
                    date: metadata.date || new Date().toLocaleDateString('pt-BR'),
                    css_content: cssContent,
                    content: html,
                    mermaidTheme: getDarkThemes().includes(theme) ? 'dark' : 'default',
                    layoutClass: metadata.layout || 'default-layout'
                };

                // Replace template variables
                let htmlContent = baseTemplate.replace(/\{\{\s*(\w+)\s*\}\}/g, (match, key) => {
                    return templateData[key] || '';
                });

                // Special handling for css_content
                htmlContent = htmlContent.replace(/\{\s*\{\s*css_content\s*\}\s*\}/g, cssContent);

                // Set content and wait for rendering
                await page.setContent(htmlContent, {
                    waitUntil: 'networkidle0',
                    timeout: 30000
                });

                // Wait for Paged.js to finish
                try {
                    await page.waitForSelector('.pagedjs_pages', { timeout: 15000 });
                } catch (e) {
                    console.log(`${progress}   ⚠️  Paged.js not detected, using full page`);
                }

                // Wait a bit for fonts and rendering
                await new Promise(resolve => setTimeout(resolve, 2000));

                // Try to get first page, fallback to full page
                let element;
                try {
                    element = await page.$('.pagedjs_page');
                    if (!element) {
                        element = await page.$('body');
                    }
                } catch (e) {
                    element = await page.$('body');
                }

                // Generate thumbnail
                const thumbnailPath = path.join(thumbnailsDir, `${theme}.png`);

                if (element) {
                    await element.screenshot({
                        path: thumbnailPath,
                        type: 'png',
                        omitBackground: false
                    });
                } else {
                    // Fallback to full page screenshot
                    await page.screenshot({
                        path: thumbnailPath,
                        type: 'png',
                        fullPage: false
                    });
                }

                console.log(`${progress}   ✅ Saved: ${theme}.png`);

            } catch (error) {
                console.error(`${progress}   ❌ Error processing "${theme}":`, error.message);
            }
        }

        await browser.close();

        console.log('\n✨ Thumbnail generation complete!');
        console.log(`📁 Thumbnails saved to: public/thumbnails/\n`);

        return {
            success: true,
            count: themes.length,
            themes
        };

    } catch (error) {
        console.error('❌ Thumbnail generation failed:', error);
        throw error;
    }
}

/**
 * Helper function to identify dark themes
 */
function getDarkThemes() {
    return ['dark_tech', 'retro-future', 'creative-zine'];
}

/**
 * CLI execution
 */
if (import.meta.url === `file://${process.argv[1]}`) {
    console.log('╔════════════════════════════════════════════════╗');
    console.log('║     MD to PDF Pro - Thumbnail Generator       ║');
    console.log('╚════════════════════════════════════════════════╝\n');

    generateThumbnails()
        .then(result => {
            console.log(`🎉 Generated ${result.count} thumbnails successfully!`);
            process.exit(0);
        })
        .catch(error => {
            console.error('💥 Fatal error:', error);
            process.exit(1);
        });
}
