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

export async function processMarkdown(markdownContent) {
    // Parse Frontmatter
    const { content, data: metadata } = matter(markdownContent);

    // Convert Markdown to HTML with GFM (tables, task lists, etc.)
    const file = await unified()
        .use(remarkParse)
        .use(remarkGfm) // GitHub Flavored Markdown (tables, strikethrough, task lists, etc.)
        .use(remarkRehype, { allowDangerousHtml: true })
        .use(rehypeRaw) // Allow raw HTML
        .use(rehypeHighlight) // Syntax highlighting for code blocks
        .use(rehypeStringify)
        .process(content);

    return {
        html: String(file),
        metadata
    };
}
