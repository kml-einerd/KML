/**
 * HTML Processor
 * Converts Markdown to HTML using Unified (Remark/Rehype).
 */

import { unified } from 'unified';
import remarkParse from 'remark-parse';
import remarkGfm from 'remark-gfm';
import remarkRehype from 'remark-rehype';
import rehypeRaw from 'rehype-raw';
import rehypeHighlight from 'rehype-highlight';
import rehypeStringify from 'rehype-stringify';
import matter from 'gray-matter';
import { visit } from 'unist-util-visit';
import pako from 'pako';
import { enhanceMarkdown, validateAndFix } from './markdown-enhancer.js';

/**
 * Encode diagram for Kroki
 */
function encodeKroki(source) {
    const compressed = pako.deflate(source, { level: 9 });
    return Buffer.from(compressed)
        .toString('base64')
        .replace(/\+/g, '-')
        .replace(/\//g, '_');
}

/**
 * Custom plugin to convert diagram code blocks to images via Kroki
 */
function remarkDiagrams() {
    return (tree) => {
        visit(tree, 'code', (node) => {
            const supportedFormats = [
                'mermaid', 'plantuml', 'graphviz', 'dot',
                'nomnoml', 'svgbob', 'blockdiag', 'seqdiag',
                'actdiag', 'nwdiag', 'c4plantuml', 'erd',
                'excalidraw', 'pikchr', 'structurizr'
            ];

            if (supportedFormats.includes(node.lang)) {
                let diagramType = node.lang;

                // Normalize diagram type
                if (diagramType === 'dot') diagramType = 'graphviz';

                // For Mermaid, keep using client-side rendering
                if (diagramType === 'mermaid') {
                    node.type = 'html';
                    // Preserve the exact Mermaid code without escaping
                    // Mermaid.js will parse it correctly from the text content
                    const cleanValue = node.value.trim();

                    node.value = `<pre class="mermaid">${cleanValue}</pre>`;
                } else {
                    // Use Kroki for other diagram types
                    const encoded = encodeKroki(node.value);
                    const krokiUrl = `https://kroki.io/${diagramType}/svg/${encoded}`;

                    node.type = 'html';
                    node.value = `
                        <div class="diagram-container diagram-${diagramType}">
                            <img src="${krokiUrl}" alt="${diagramType} diagram" class="diagram-image" loading="lazy" />
                        </div>
                    `;
                }
            }
        });
    };
}

/**
 * Custom plugin to ensure HTML images are properly rendered
 * Wraps images in figures and adds necessary attributes
 * IMPORTANT: Also ensures images don't get nested inside headings
 * FIXED: Don't add referrerPolicy/crossOrigin for base64 images
 */
function rehypeFixImages() {
    return (tree) => {
        visit(tree, 'element', (node, index, parent) => {
            // Handle standalone img elements (not already in a figure)
            if (node.tagName === 'img' && parent && parent.tagName !== 'figure') {
                const alt = node.properties.alt || '';
                const src = node.properties.src || '';
                const isBase64 = src.startsWith('data:');

                // Determine if image should be full-width
                const isFullWidth = alt.toLowerCase().includes('capa') ||
                                   alt.toLowerCase().includes('banner') ||
                                   alt.toLowerCase().includes('header');

                const cssClass = isFullWidth ? 'image-full-width' : 'image-content';

                // Set image properties (only for external images)
                if (!isBase64) {
                    node.properties.loading = 'lazy';
                    node.properties.referrerPolicy = 'no-referrer';
                    node.properties.crossOrigin = 'anonymous';
                }

                // Add style to ensure image displays
                node.properties.style = 'display: block; max-width: 100%; height: auto;';

                // Create figure element
                const figure = {
                    type: 'element',
                    tagName: 'figure',
                    properties: {
                        className: [cssClass],
                        style: 'page-break-inside: avoid; margin: 1.5em 0;'
                    },
                    children: [node]
                };

                // Add figcaption if alt text exists
                if (alt) {
                    figure.children.push({
                        type: 'element',
                        tagName: 'figcaption',
                        properties: {},
                        children: [{
                            type: 'text',
                            value: alt
                        }]
                    });
                }

                // Replace img with figure in parent
                parent.children[index] = figure;
            }

            // Handle images already in figures
            if (node.tagName === 'figure') {
                visit(node, 'element', (child) => {
                    if (child.tagName === 'img' && child.properties) {
                        const src = child.properties.src || '';
                        const isBase64 = src.startsWith('data:');

                        if (!isBase64) {
                            child.properties.loading = 'lazy';
                            child.properties.referrerPolicy = 'no-referrer';
                            child.properties.crossOrigin = 'anonymous';
                        }
                        child.properties.style = 'display: block; max-width: 100%; height: auto;';
                    }
                });
            }
        });

        // CRITICAL FIX: Remove images/figures from inside headings
        // This happens when markdown has images right after headings without blank lines
        visit(tree, 'element', (node, index, parent) => {
            const isHeading = /^h[1-6]$/.test(node.tagName);

            if (isHeading && node.children) {
                // Extract figures and images from heading
                const extractedElements = [];
                node.children = node.children.filter((child, childIndex) => {
                    if (child.type === 'element' && (child.tagName === 'figure' || child.tagName === 'img')) {
                        extractedElements.push(child);
                        return false; // Remove from heading
                    }
                    return true; // Keep in heading
                });

                // Insert extracted elements after the heading
                if (extractedElements.length > 0 && parent && parent.children) {
                    const headingIndex = parent.children.indexOf(node);
                    parent.children.splice(headingIndex + 1, 0, ...extractedElements);
                }
            }
        });
    };
}

export async function processMarkdown(markdownContent) {
    // Parse Frontmatter
    const { content, data: metadata } = matter(markdownContent);

    // Validate and fix common markdown errors
    let cleanedContent = validateAndFix(content);

    // Apply professional enhancements
    cleanedContent = enhanceMarkdown(cleanedContent);

    // Convert Markdown to HTML with GFM (tables, task lists, etc.)
    const file = await unified()
        .use(remarkParse)
        .use(remarkGfm) // GitHub Flavored Markdown (tables, strikethrough, task lists, etc.)
        .use(remarkDiagrams) // Convert diagram code blocks (Mermaid, PlantUML, GraphViz, etc.)
        .use(remarkRehype, { allowDangerousHtml: true })
        .use(rehypeRaw) // Allow raw HTML
        .use(rehypeFixImages) // Fix image attributes for better loading
        .use(rehypeHighlight) // Syntax highlighting for code blocks
        .use(rehypeStringify)
        .process(cleanedContent);

    return {
        html: String(file),
        metadata
    };
}
