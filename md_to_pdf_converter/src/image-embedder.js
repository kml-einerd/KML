/**
 * Image Embedder
 * Downloads external images and converts them to base64 for embedding in PDF
 */

import https from 'https';
import http from 'http';
import { URL } from 'url';

/**
 * Download image from URL and convert to base64
 */
export async function downloadImageAsBase64(imageUrl) {
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
                    console.log(`📍 Redirect: ${imageUrl} -> ${redirectUrl}`);
                    downloadImageAsBase64(redirectUrl).then(resolve).catch(reject);
                    return;
                }

                if (res.statusCode !== 200) {
                    console.warn(`⚠️  Failed to download image: ${imageUrl} (Status: ${res.statusCode})`);
                    resolve(null); // Return null instead of rejecting
                    return;
                }

                const chunks = [];
                res.on('data', (chunk) => chunks.push(chunk));
                res.on('end', () => {
                    try {
                        const buffer = Buffer.concat(chunks);
                        const contentType = res.headers['content-type'] || 'image/jpeg';
                        const base64 = buffer.toString('base64');
                        const dataUri = `data:${contentType};base64,${base64}`;

                        console.log(`✅ Downloaded image: ${imageUrl.substring(0, 60)}... (${(buffer.length / 1024).toFixed(2)} KB)`);
                        resolve(dataUri);
                    } catch (error) {
                        console.error(`❌ Error processing image: ${error.message}`);
                        resolve(null);
                    }
                });
            });

            req.on('error', (error) => {
                console.error(`❌ Error downloading image ${imageUrl}: ${error.message}`);
                resolve(null); // Return null instead of rejecting
            });

            // Set timeout
            req.setTimeout(30000, () => {
                req.destroy();
                console.warn(`⏱️  Timeout downloading image: ${imageUrl}`);
                resolve(null);
            });

        } catch (error) {
            console.error(`❌ Invalid URL: ${imageUrl} - ${error.message}`);
            resolve(null);
        }
    });
}

/**
 * Convert local file to base64
 */
async function localFileToBase64(filePath, basePath) {
    try {
        const fs = await import('fs-extra');
        const path = await import('path');
        const mime = await import('mime-types');

        // Resolve relative path
        const absolutePath = path.default.isAbsolute(filePath)
            ? filePath
            : path.default.join(basePath, filePath);

        console.log(`📂 Reading local image: ${absolutePath}`);

        if (!fs.default.existsSync(absolutePath)) {
            console.warn(`⚠️  Local image not found: ${absolutePath}`);
            return null;
        }

        const buffer = await fs.default.readFile(absolutePath);
        const mimeType = mime.default.lookup(absolutePath) || 'image/jpeg';
        const base64 = buffer.toString('base64');
        const dataUri = `data:${mimeType};base64,${base64}`;

        console.log(`✅ Loaded local image: ${absolutePath} (${(buffer.length / 1024).toFixed(2)} KB)`);
        return dataUri;
    } catch (error) {
        console.error(`❌ Error reading local image: ${error.message}`);
        return null;
    }
}

/**
 * Process HTML and embed external images as base64
 */
export async function embedImagesInHtml(html, basePath = process.cwd()) {
    // Find all img tags with src
    const imgRegex = /<img[^>]+src="([^"]+)"[^>]*>/gi;
    const matches = [...html.matchAll(imgRegex)];

    if (matches.length === 0) {
        return html;
    }

    console.log(`🖼️  Found ${matches.length} image(s) to embed...`);

    let processedHtml = html;

    // Process each image
    for (const match of matches) {
        const fullTag = match[0];
        const imageUrl = match[1];

        // Skip data URIs (already embedded)
        if (imageUrl.startsWith('data:')) {
            continue;
        }

        let base64Data = null;

        // Check if it's a URL or local file
        if (imageUrl.startsWith('http://') || imageUrl.startsWith('https://')) {
            // Download and convert to base64
            base64Data = await downloadImageAsBase64(imageUrl);
        } else {
            // Local file - convert to base64
            base64Data = await localFileToBase64(imageUrl, basePath);
        }

        if (base64Data) {
            // Replace the URL with base64 data URI
            const newTag = fullTag.replace(imageUrl, base64Data);
            processedHtml = processedHtml.replace(fullTag, newTag);
        }
    }

    return processedHtml;
}
