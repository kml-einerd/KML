/**
 * Content Analyzer
 * Analyzes markdown content to determine layout strategies.
 */

export function analyzeContent(markdown) {
    const stats = {
        codeBlocks: 0,
        images: 0,
        paragraphs: 0,
        totalLength: markdown.length,
        layoutClass: 'layout-standard'
    };

    // Count code blocks
    const codeBlockMatches = markdown.match(/```/g);
    if (codeBlockMatches) {
        stats.codeBlocks = codeBlockMatches.length / 2;
    }

    // Count images
    const imageMatches = markdown.match(/!\[.*?\]\(.*?\)/g);
    if (imageMatches) {
        stats.images = imageMatches.length;
    }

    // Smart Layout Logic
    if (stats.codeBlocks > 5) {
        stats.layoutClass = 'layout-wide'; // Wider margins for code
    } else if (stats.images > 10) {
        stats.layoutClass = 'layout-visual'; // Optimized for images
    } else {
        stats.layoutClass = 'layout-reader'; // Optimized for reading
    }

    return stats;
}
