/**
 * Markdown Enhancer
 * Sistema profissional de pré-processamento de Markdown
 * Melhora tipografia, quebras de linha, espaçamento e diagramas
 */

/**
 * Aplica melhorias tipográficas profissionais
 */
function enhanceTypography(markdown) {
    let enhanced = markdown;

    // Substituir aspas retas por aspas curvas (smart quotes)
    enhanced = enhanced.replace(/"([^"]*)"/g, '“$1”');
    enhanced = enhanced.replace(/'([^']*)'/g, '‘$1’');

    // Adicionar non-breaking space antes de pontuação dupla (regras francesas/brasileiras)
    enhanced = enhanced.replace(/\s+([!?:;»])/g, '\u00A0$1');
    enhanced = enhanced.replace(/([«])\s+/g, '$1\u00A0');

    // Prevenir linhas órfãs/viúvas em títulos
    enhanced = enhanced.replace(/^(#{1,6})\s+(.+)$/gm, (match, hashes, title) => {
        // Adiciona non-breaking space entre as últimas 2-3 palavras do título
        const words = title.trim().split(' ');
        if (words.length > 3) {
            const lastThree = words.slice(-3).join('\u00A0');
            const rest = words.slice(0, -3).join(' ');
            return `${hashes} ${rest} ${lastThree}`;
        }
        return match;
    });

    // Melhorar espaçamento de símbolos monetários
    enhanced = enhanced.replace(/R\$\s*/g, 'R$\u00A0');
    enhanced = enhanced.replace(/\$\s*(\d)/g, '$\u00A0$1');

    // Reticências apropriadas
    enhanced = enhanced.replace(/\.\.\./g, '…');

    // Travessões corretos (em dash para ranges, em dash para dialogue)
    enhanced = enhanced.replace(/(\d+)\s*-\s*(\d+)/g, '$1–$2'); // en-dash para ranges numéricos

    return enhanced;
}

/**
 * Melhora a estrutura e quebras de linha
 */
function enhanceStructure(markdown) {
    let enhanced = markdown;

    // Garantir espaçamento adequado antes de títulos
    enhanced = enhanced.replace(/([^\n])\n(#{1,6}\s)/g, '$1\n\n$2');

    // Garantir espaçamento após títulos
    enhanced = enhanced.replace(/(#{1,6}\s.+)\n([^\n#])/g, '$1\n\n$2');

    // Espaçamento correto antes de listas
    enhanced = enhanced.replace(/([^\n])\n([*\-+]\s|\d+\.\s)/gm, '$1\n\n$2');

    // Espaçamento após listas
    enhanced = enhanced.replace(/^([*\-+]\s.+|\d+\.\s.+)$\n^([^*\-+\d\n])/gm, '$1\n\n$2');

    // Remover múltiplas linhas em branco (máximo 2)
    enhanced = enhanced.replace(/\n{4,}/g, '\n\n\n');

    // Garantir linha em branco antes de blockquotes
    enhanced = enhanced.replace(/([^\n])\n(>)/g, '$1\n\n$2');

    // Garantir linha em branco antes de code blocks
    enhanced = enhanced.replace(/([^\n])\n(```)/g, '$1\n\n$2');

    return enhanced;
}

/**
 * Otimiza diagramas Mermaid para melhor renderização
 */
function enhanceMermaidDiagrams(markdown) {
    let enhanced = markdown;

    // Encontrar e processar todos os blocos Mermaid
    const mermaidRegex = /```mermaid\n([\s\S]*?)```/g;

    enhanced = enhanced.replace(mermaidRegex, (match, diagramContent) => {
        let optimized = diagramContent;

        // Remover espaços desnecessários no início e fim
        optimized = optimized.trim();

        // Normalizar quebras de linha nos labels
        // Substituir <br/> por <br> (mais compatível com Mermaid)
        optimized = optimized.replace(/<br\s*\/?>/gi, '<br>');

        // NÃO alterar a indentação, preservar o conteúdo original
        // Isso evita problemas com caracteres especiais e formatação

        // Garantir que o tipo de diagrama está na primeira linha
        const lines = optimized.split('\n');
        const firstLine = lines[0].trim();

        // Verificar se tem tipo de diagrama
        if (!firstLine.match(/^(graph|flowchart|sequenceDiagram|classDiagram|stateDiagram|erDiagram|journey|gantt|pie|gitGraph)/)) {
            // Se não tem tipo, assumir flowchart TD
            optimized = 'flowchart TD\n' + optimized;
        }

        return '```mermaid\n' + optimized + '\n```';
    });

    return enhanced;
}

/**
 * Adiciona classes CSS customizadas para elementos específicos
 */
function addSemanticMarkers(markdown) {
    let enhanced = markdown;

    // Marcar blocos de destaque (texto que começa com emoji ou símbolos especiais)
    enhanced = enhanced.replace(/^(> )?([🎯✨💡📌🚀⚠️🔥]+)\s+\*\*(.+?)\*\*/gm,
        (match, quote, emoji, text) => {
            const q = quote || '';
            return `${q}<div class="highlight-box">${emoji} **${text}**`;
        });

    // Adicionar div para fechar o highlight-box (procura próximo parágrafo vazio)
    enhanced = enhanced.replace(/(<div class="highlight-box">[\s\S]+?)(\n\n)/g, '$1</div>$2');

    // Marcar tabelas com classe especial
    enhanced = enhanced.replace(/(^\|.+\|$\n^\|[-:| ]+\|$)/gm,
        '<div class="enhanced-table">\n\n$1');

    // Fechar div de tabelas
    enhanced = enhanced.replace(/(\n\|.+\|$)(\n)(?!\|)/gm, '$1\n\n</div>$2');

    return enhanced;
}

/**
 * Processa imagens para melhor apresentação
 * NOTA: Não convertemos para HTML aqui - deixamos o processador Markdown fazer isso
 * Apenas preservamos as imagens como estão
 */
function enhanceImages(markdown) {
    // Apenas retornar o markdown sem modificação
    // O processador Markdown e os plugins Rehype cuidarão das imagens
    return markdown;
}

/**
 * Melhora listas para melhor hierarquia visual
 */
function enhanceLists(markdown) {
    let enhanced = markdown;

    // Adicionar classes para listas numeradas importantes
    enhanced = enhanced.replace(/^(\d+)\.\s+\*\*(.+?)\*\*/gm,
        '<li class="list-highlight"><strong>$2</strong>');

    return enhanced;
}

/**
 * Função principal que aplica todas as melhorias
 */
export function enhanceMarkdown(markdown) {
    console.log('🎨 Enhancing Markdown with professional improvements...');

    let enhanced = markdown;

    // Aplicar melhorias em ordem
    enhanced = enhanceTypography(enhanced);
    enhanced = enhanceStructure(enhanced);
    enhanced = enhanceMermaidDiagrams(enhanced);
    enhanced = addSemanticMarkers(enhanced);
    enhanced = enhanceImages(enhanced);
    enhanced = enhanceLists(enhanced);

    console.log('✅ Markdown enhancement complete');

    return enhanced;
}

/**
 * Função para validar e corrigir erros comuns
 */
export function validateAndFix(markdown) {
    let fixed = markdown;

    // Corrigir headings mal formados
    fixed = fixed.replace(/^(#{1,6})([^\s#])/gm, '$1 $2');

    // Corrigir listas mal formadas
    fixed = fixed.replace(/^([*\-+])([^\s])/gm, '$1 $2');
    fixed = fixed.replace(/^(\d+)\.([^\s])/gm, '$1. $2');

    // Remover espaços em branco no final das linhas
    fixed = fixed.replace(/[ \t]+$/gm, '');

    // Garantir que o arquivo termina com newline
    if (!fixed.endsWith('\n')) {
        fixed += '\n';
    }

    return fixed;
}
