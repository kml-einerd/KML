/**
 * Express Server for MD to PDF Web Converter
 * Provides API endpoints for theme selection and PDF generation
 */

import express from 'express';
import multer from 'multer';
import cors from 'cors';
import path from 'path';
import fs from 'fs-extra';
import { fileURLToPath } from 'url';
import { processMarkdown } from './src/html-processor.js';
import { generatePdf } from './src/pdf-generator.js';
import { downloadAndReplaceImages, cleanupTempImages } from './src/image-downloader.js';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const app = express();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(cors());
app.use(express.json());
app.use(express.static('public'));

// Explicitly serve index.html for root route
app.get('/', (req, res) => {
    res.sendFile(path.join(__dirname, 'public', 'index.html'));
});

// Configure Multer for file uploads (no file size limit)
const upload = multer({
    dest: 'uploads/',
    fileFilter: (req, file, cb) => {
        if (file.originalname.endsWith('.md')) {
            cb(null, true);
        } else {
            cb(new Error('Only .md files are allowed'));
        }
    }
});

/**
 * GET /api/themes
 * Returns list of available themes with thumbnail paths
 */
app.get('/api/themes', async (req, res) => {
    try {
        const themesDir = path.join(__dirname, 'assets/themes');
        const files = await fs.readdir(themesDir);

        const themes = files
            .filter(f => f.endsWith('.css'))
            .map(f => {
                const themeName = f.replace('.css', '');
                return {
                    name: themeName,
                    displayName: themeName.replace(/-/g, ' ').replace(/_/g, ' '),
                    thumbnail: `/thumbnails/${themeName}.png`,
                    cssFile: f
                };
            });

        res.json({
            success: true,
            themes,
            count: themes.length
        });
    } catch (error) {
        console.error('Error listing themes:', error);
        res.status(500).json({
            success: false,
            error: 'Failed to list themes'
        });
    }
});

/**
 * POST /api/generate
 * Generates PDF from uploaded markdown with selected theme
 */
app.post('/api/generate', upload.single('markdown'), async (req, res) => {
    let uploadedFilePath = null;
    let outputPdfPath = null;
    let tempDir = null;

    try {
        if (!req.file) {
            return res.status(400).json({
                success: false,
                error: 'No markdown file uploaded'
            });
        }

        const { theme } = req.body;
        if (!theme) {
            return res.status(400).json({
                success: false,
                error: 'No theme selected'
            });
        }

        uploadedFilePath = req.file.path;
        console.log(`📄 Processing file: ${req.file.originalname}`);
        console.log(`🎨 Theme: ${theme}`);

        // Read markdown file
        const markdownContent = await fs.readFile(uploadedFilePath, 'utf-8');

        // Process markdown to HTML
        const { html, metadata } = await processMarkdown(markdownContent);

        // Read theme CSS
        const themePath = path.join(__dirname, 'assets/themes', `${theme}.css`);
        const cssContent = await fs.readFile(themePath, 'utf-8');

        // Choose template based on content size
        // Use simple template (no Paged.js) for large documents (> 50KB or > 1000 lines)
        const isLargeDocument = markdownContent.length > 50000 ||
                                markdownContent.split('\n').length > 1000;

        const templateName = isLargeDocument ? 'base-simple.html' : 'base.html';
        const templatePath = path.join(__dirname, 'assets/templates', templateName);
        let htmlTemplate = await fs.readFile(templatePath, 'utf-8');

        console.log(`📄 Using template: ${templateName} (size: ${(markdownContent.length / 1024).toFixed(2)}KB)`);

        // Simple template replacement (Jinja2-like syntax)
        const templateData = {
            title: metadata.title || 'Document',
            subtitle: metadata.subtitle || '',
            author: metadata.author || '',
            date: metadata.date || new Date().toLocaleDateString('pt-BR'),
            css_content: cssContent,
            content: html,
            mermaidTheme: getMermaidTheme(theme),
            layoutClass: metadata.layout || 'default-layout'
        };

        // Replace template variables
        htmlTemplate = htmlTemplate.replace(/\{\{\s*(\w+)\s*\}\}/g, (match, key) => {
            return templateData[key] || '';
        });

        // Download images to local files (NEW APPROACH - FIXED!)
        console.log('🖼️  Downloading external images...');
        const result = await downloadAndReplaceImages(htmlTemplate, __dirname);
        htmlTemplate = result.html;
        tempDir = result.tempDir;

        // Generate unique output filename
        const timestamp = Date.now();
        const outputFilename = `output_${timestamp}.pdf`;
        outputPdfPath = path.join(__dirname, 'uploads', outputFilename);

        // Generate PDF
        await generatePdf(htmlTemplate, outputPdfPath);

        // Send PDF file
        res.download(outputPdfPath, `${metadata.title || 'document'}.pdf`, async (err) => {
            // Cleanup temporary files after download
            try {
                if (uploadedFilePath) await fs.remove(uploadedFilePath);
                if (outputPdfPath) await fs.remove(outputPdfPath);
                if (tempDir) await cleanupTempImages(tempDir);
            } catch (cleanupError) {
                console.error('Cleanup error:', cleanupError);
            }

            if (err) {
                console.error('Download error:', err);
            }
        });

    } catch (error) {
        console.error('❌ Generation error:', error);

        // Cleanup on error
        try {
            if (uploadedFilePath) await fs.remove(uploadedFilePath);
            if (outputPdfPath) await fs.remove(outputPdfPath);
            if (tempDir) await cleanupTempImages(tempDir);
        } catch (cleanupError) {
            console.error('Cleanup error:', cleanupError);
        }

        res.status(500).json({
            success: false,
            error: 'Failed to generate PDF',
            details: error.message
        });
    }
});

/**
 * POST /api/preview
 * Returns rendered HTML preview
 */
app.post('/api/preview', upload.single('markdown'), async (req, res) => {
    try {
        if (!req.file) {
            return res.status(400).json({
                success: false,
                error: 'No markdown file uploaded'
            });
        }

        const markdownContent = await fs.readFile(req.file.path, 'utf-8');
        const { html, metadata } = await processMarkdown(markdownContent);

        // Read theme CSS
        const theme = req.body.theme || 'obsidian';
        const themePath = path.join(__dirname, 'assets/themes', `${theme}.css`);
        let cssContent = '';
        try {
            cssContent = await fs.readFile(themePath, 'utf-8');
        } catch (e) {
            console.warn(`Theme ${theme} not found, using default.`);
        }

        // Choose template based on content size
        const isLargeDocument = markdownContent.length > 50000 ||
                                markdownContent.split('\n').length > 1000;

        const templateName = isLargeDocument ? 'base-simple.html' : 'base.html';
        const templatePath = path.join(__dirname, 'assets/templates', templateName);
        let htmlTemplate = await fs.readFile(templatePath, 'utf-8');

        const templateData = {
            title: metadata.title || 'Preview',
            subtitle: metadata.subtitle || '',
            author: metadata.author || '',
            date: metadata.date || new Date().toLocaleDateString('pt-BR'),
            css_content: cssContent,
            content: html,
            layoutClass: metadata.layout || 'default-layout'
        };

        // Replace template variables
        htmlTemplate = htmlTemplate.replace(/\{\{\s*(\w+)\s*\}\}/g, (match, key) => {
            return templateData[key] || '';
        });

        // Cleanup uploaded file
        await fs.remove(req.file.path);

        res.send(htmlTemplate);
    } catch (error) {
        console.error('Preview error:', error);
        res.status(500).send(`Error: ${error.message}`);
    }
});

/**
 * Helper function to determine Mermaid theme based on PDF theme
 */
function getMermaidTheme(themeName) {
    const darkThemes = ['dark_tech', 'retro-future', 'creative-zine'];
    return darkThemes.includes(themeName) ? 'dark' : 'default';
}

// Error handling middleware
app.use((error, req, res, next) => {
    if (error instanceof multer.MulterError) {
        return res.status(400).json({
            success: false,
            error: `Upload error: ${error.message}`
        });
    }

    res.status(500).json({
        success: false,
        error: error.message || 'Internal server error'
    });
});

// Start server
app.listen(PORT, () => {
    console.log(`
╔════════════════════════════════════════════════╗
║  🚀 MD to PDF Pro - Web Server Running        ║
╠════════════════════════════════════════════════╣
║  📍 URL: http://localhost:${PORT}                ║
║  🎨 Themes: 10 professional styles available   ║
║  📄 Ready to convert Markdown to PDF           ║
╚════════════════════════════════════════════════╝
    `);
});

// Graceful shutdown
process.on('SIGTERM', () => {
    console.log('🛑 Server shutting down...');
    process.exit(0);
});
