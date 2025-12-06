/**
 * Image Downloader - SOLUÇÃO ALTERNATIVA
 * Baixa imagens e salva como arquivos temporários
 * Substitui URLs por file:// paths para melhor compatibilidade com Puppeteer
 */

import https from 'https';
import http from 'http';
import { URL } from 'url';
import fs from 'fs-extra';
import path from 'path';
import crypto from 'crypto';

/**
 * Download image from URL and save to temp file
 */
async function downloadImageToFile(imageUrl, tempDir) {
    return new Promise((resolve, reject) => {
        try {
            const url = new URL(imageUrl);
            const protocol = url.protocol === 'https:' ? https : http;

            const options = {
                headers: {
                    'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
                    'Accept': 'image/webp,image/apng,image/*,*/*;q=0.8',
                    'Accept-Language': 'pt-BR,pt;q=0.9,en-US;q=0.8,en;q=0.7',
                    'Referer': 'https://www.google.com/',
                    'Cache-Control': 'no-cache'
                }
            };

            const req = protocol.get(imageUrl, options, (res) => {
                // Handle redirects
                if (res.statusCode === 301 || res.statusCode === 302) {
                    const redirectUrl = res.headers.location;
                    console.log(`📍 Redirect: ${imageUrl.substring(0, 60)}... -> ${redirectUrl.substring(0, 60)}...`);
                    downloadImageToFile(redirectUrl, tempDir).then(resolve).catch(reject);
                    return;
                }

                if (res.statusCode !== 200) {
                    console.warn(`⚠️  Failed to download: ${imageUrl.substring(0, 60)}... (Status: ${res.statusCode})`);
                    resolve(null);
                    return;
                }

                const chunks = [];
                res.on('data', (chunk) => chunks.push(chunk));
                res.on('end', async () => {
                    try {
                        const buffer = Buffer.concat(chunks);
                        const contentType = res.headers['content-type'] || 'image/jpeg';

                        // Determine file extension
                        let ext = '.jpg';
                        if (contentType.includes('png')) ext = '.png';
                        else if (contentType.includes('svg')) ext = '.svg';
                        else if (contentType.includes('gif')) ext = '.gif';
                        else if (contentType.includes('webp')) ext = '.webp';

                        // Create unique filename
                        const hash = crypto.createHash('md5').update(imageUrl).digest('hex');
                        const filename = `img_${hash}${ext}`;
                        const filepath = path.join(tempDir, filename);

                        // Save to file
                        await fs.writeFile(filepath, buffer);

                        console.log(`✅ Downloaded: ${imageUrl.substring(0, 50)}... -> ${filename} (${(buffer.length / 1024).toFixed(2)} KB)`);
                        resolve(filepath);
                    } catch (error) {
                        console.error(`❌ Error saving image: ${error.message}`);
                        resolve(null);
                    }
                });
            });

            req.on('error', (error) => {
                console.error(`❌ Error downloading ${imageUrl.substring(0, 60)}...: ${error.message}`);
                resolve(null);
            });

            req.setTimeout(30000, () => {
                req.destroy();
                console.warn(`⏱️  Timeout: ${imageUrl.substring(0, 60)}...`);
                resolve(null);
            });

        } catch (error) {
            console.error(`❌ Invalid URL: ${imageUrl} - ${error.message}`);
            resolve(null);
        }
    });
}

/**
 * Process HTML and replace external image URLs with local file:// paths
 */
export async function downloadAndReplaceImages(html, basePath = process.cwd()) {
    // Create temp directory for images
    const tempDir = path.join(basePath, 'temp_images');
    await fs.ensureDir(tempDir);

    console.log(`📁 Temp directory: ${tempDir}`);

    // Find all img tags with src
    const imgRegex = /<img[^>]+src="([^"]+)"[^>]*>/gi;
    const matches = [...html.matchAll(imgRegex)];

    if (matches.length === 0) {
        return { html, tempDir };
    }

    console.log(`🖼️  Found ${matches.length} image(s) to download...`);

    let processedHtml = html;

    // Process each image
    for (const match of matches) {
        const fullTag = match[0];
        const imageUrl = match[1];

        // Skip data URIs (already embedded)
        if (imageUrl.startsWith('data:')) {
            continue;
        }

        // Skip local files
        if (!imageUrl.startsWith('http://') && !imageUrl.startsWith('https://')) {
            continue;
        }

        // Download to temp file
        const localPath = await downloadImageToFile(imageUrl, tempDir);

        if (localPath) {
            // Convert to file:// URL (works better with Puppeteer)
            const fileUrl = `file://${localPath}`;
            const newTag = fullTag.replace(imageUrl, fileUrl);
            processedHtml = processedHtml.replace(fullTag, newTag);
        }
    }

    return { html: processedHtml, tempDir };
}

/**
 * Cleanup temporary images
 */
export async function cleanupTempImages(tempDir) {
    try {
        if (tempDir && await fs.pathExists(tempDir)) {
            await fs.remove(tempDir);
            console.log(`🧹 Cleaned up temp images: ${tempDir}`);
        }
    } catch (error) {
        console.error(`⚠️  Error cleaning up temp images: ${error.message}`);
    }
}
