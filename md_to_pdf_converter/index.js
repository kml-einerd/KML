#!/usr/bin/env node


console.log('🚀 Starting MD to PDF Pro...');
import fs from 'fs-extra';
import path from 'path';
import yargs from 'yargs/yargs';
import { hideBin } from 'yargs/helpers';
import { fileURLToPath } from 'url';
import { analyzeContent } from './src/content-analyzer.js';
import { processMarkdown } from './src/html-processor.js';
import { generatePdf } from './src/pdf-generator.js';
import { embedImagesInHtml } from './src/image-embedder.js';

// ESM equivalent of __dirname
const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

async function main() {
    const argv = yargs(hideBin(process.argv))
        .command('convert <file>', 'Convert Markdown to PDF', (yargs) => {
            yargs.positional('file', {
                describe: 'Markdown file to convert',
                type: 'string'
            });
        })
        .option('theme', {
            alias: 't',
            type: 'string',
            description: 'Theme name (modern-blue, classic-serif, dark-tech)',
            default: 'modern-blue'
        })
        .demandCommand(1)
        .help()
        .argv;

    const inputFile = argv.file;
    const themeName = argv.theme;

    if (!fs.existsSync(inputFile)) {
        console.error(`❌ File not found: ${inputFile}`);
        process.exit(1);
    }

    console.log(`🔍 Analyzing ${inputFile}...`);
    const markdown = await fs.readFile(inputFile, 'utf-8');

    // 1. Analyze Content
    const stats = analyzeContent(markdown);
    console.log(`📊 Content Stats: ${stats.codeBlocks} code blocks, ${stats.images} images. Layout: ${stats.layoutClass}`);

    // 2. Process Markdown to HTML
    const { html, metadata } = await processMarkdown(markdown);

    // 3. Load Resources
    const templatePath = path.join(__dirname, 'assets', 'templates', 'base.html');
    let template = await fs.readFile(templatePath, 'utf-8');

    // Check if theme exists in assets/themes
    // Handle both hyphen and underscore naming if needed, or just trust input
    const themeCssPath = path.join(__dirname, 'assets', 'themes', `${themeName}.css`);
    let themeCss = '';

    if (fs.existsSync(themeCssPath)) {
        themeCss = await fs.readFile(themeCssPath, 'utf-8');
    } else {
        console.warn(`⚠️ Theme '${themeName}' not found in assets/themes, checking for .css extension...`);
        // Try adding .css if not present (already added above)
        // List available themes
        const themesDir = path.join(__dirname, 'assets', 'themes');
        const availableThemes = await fs.readdir(themesDir);
        console.log(`Available themes: ${availableThemes.join(', ')}`);
        process.exit(1);
    }

    // 4. Inject Data into Template
    let finalHtml = template
        .replace('{{ title }}', metadata.title || 'Untitled')
        .replace('{{ subtitle }}', metadata.subtitle || '')
        .replace('{{ author }}', metadata.author || '')
        .replace('{{ date }}', metadata.date || new Date().toLocaleDateString())
        .replace('{{ content }}', html)
        .replace('{{ css_content }}', themeCss)
        .replace('{{ layoutClass }}', stats.layoutClass)
        .replace('{{ mermaidTheme }}', themeName.includes('dark') || themeName.includes('retro') ? 'dark' : 'default');

    // 4.5. Embed external images as base64
    console.log('🖼️  Embedding external images...');
    finalHtml = await embedImagesInHtml(finalHtml);

    // 5. Generate PDF
    const outputPath = path.basename(inputFile, '.md') + '.pdf';
    await generatePdf(finalHtml, outputPath);
}

main().catch(console.error);
