/**
 * MD to PDF Pro - Frontend Application Logic
 */

// State
let uploadedFile = null;
let selectedTheme = null;
let availableThemes = [];

// DOM Elements
const dropzone = document.getElementById('dropzone');
const fileInput = document.getElementById('fileInput');
const browseBtn = document.getElementById('browseBtn');
const fileInfo = document.getElementById('fileInfo');
const fileName = document.getElementById('fileName');
const fileSize = document.getElementById('fileSize');
const removeBtn = document.getElementById('removeBtn');
const themesGrid = document.getElementById('themesGrid');
const generateBtn = document.getElementById('generateBtn');
const generateBtnText = document.getElementById('generateBtnText');
const generateInfo = document.getElementById('generateInfo');
const toast = document.getElementById('toast');
const toastMessage = document.getElementById('toastMessage');

// Initialize
document.addEventListener('DOMContentLoaded', () => {
    loadThemes();
    setupEventListeners();
});

/**
 * Load available themes from API
 */
async function loadThemes() {
    try {
        const response = await fetch('/api/themes');
        const data = await response.json();

        if (data.success) {
            availableThemes = data.themes;
            renderThemes(data.themes);
        } else {
            showToast('Erro ao carregar temas', 'error');
        }
    } catch (error) {
        console.error('Error loading themes:', error);
        showToast('Erro ao carregar temas', 'error');
        renderThemesError();
    }
}

/**
 * Render themes grid
 */
function renderThemes(themes) {
    themesGrid.innerHTML = themes.map(theme => `
        <div class="theme-card" data-theme="${theme.name}">
            <img
                src="${theme.thumbnail}"
                alt="${theme.displayName}"
                class="theme-thumbnail"
                onerror="this.src='data:image/svg+xml,<svg xmlns=%22http://www.w3.org/2000/svg%22 width=%22200%22 height=%22300%22><rect width=%22200%22 height=%22300%22 fill=%22%23334155%22/><text x=%2250%%22 y=%2250%%22 fill=%22%2394a3b8%22 text-anchor=%22middle%22 font-family=%22sans-serif%22>Sem preview</text></svg>'"
            >
            <div class="theme-name">${theme.displayName}</div>
        </div>
    `).join('');

    // Add click handlers
    document.querySelectorAll('.theme-card').forEach(card => {
        card.addEventListener('click', () => selectTheme(card.dataset.theme));
    });
}

/**
 * Render error state for themes
 */
function renderThemesError() {
    themesGrid.innerHTML = `
        <div class="loading-themes">
            <p style="color: var(--danger);">Erro ao carregar temas. Tente recarregar a página.</p>
        </div>
    `;
}

/**
 * Setup event listeners
 */
function setupEventListeners() {
    // File input
    fileInput.addEventListener('change', handleFileSelect);
    browseBtn.addEventListener('click', (e) => {
        e.stopPropagation();
        fileInput.click();
    });
    removeBtn.addEventListener('click', clearFile);

    // Drag and drop (NO click on dropzone to avoid reopening)
    dropzone.addEventListener('dragover', handleDragOver);
    dropzone.addEventListener('dragleave', handleDragLeave);
    dropzone.addEventListener('drop', handleDrop);

    // Generate button
    generateBtn.addEventListener('click', generatePDF);
}

/**
 * Handle file selection
 */
function handleFileSelect(e) {
    const file = e.target.files[0];
    if (file) {
        processFile(file);
    }
}

/**
 * Handle drag over
 */
function handleDragOver(e) {
    e.preventDefault();
    dropzone.classList.add('drag-over');
}

/**
 * Handle drag leave
 */
function handleDragLeave(e) {
    e.preventDefault();
    dropzone.classList.remove('drag-over');
}

/**
 * Handle file drop
 */
function handleDrop(e) {
    e.preventDefault();
    dropzone.classList.remove('drag-over');

    const file = e.dataTransfer.files[0];
    if (file) {
        processFile(file);
    }
}

/**
 * Process uploaded file
 */
function processFile(file) {
    // Validate file type
    if (!file.name.endsWith('.md')) {
        showToast('Por favor, selecione um arquivo .md', 'error');
        return;
    }

    // No file size limit
    uploadedFile = file;

    // Update UI
    fileName.textContent = file.name;
    fileSize.textContent = formatFileSize(file.size);
    dropzone.style.display = 'none';
    fileInfo.style.display = 'flex';

    updateGenerateButton();
    showToast('Arquivo carregado com sucesso!', 'success');
}

/**
 * Clear uploaded file
 */
function clearFile() {
    uploadedFile = null;
    fileInput.value = '';
    dropzone.style.display = 'block';
    fileInfo.style.display = 'none';
    updateGenerateButton();
}

/**
 * Select theme
 */
function selectTheme(themeName) {
    selectedTheme = themeName;

    // Update UI
    document.querySelectorAll('.theme-card').forEach(card => {
        card.classList.remove('selected');
    });

    const selectedCard = document.querySelector(`[data-theme="${themeName}"]`);
    if (selectedCard) {
        selectedCard.classList.add('selected');
    }

    updateGenerateButton();
}

/**
 * Update generate button state
 */
function updateGenerateButton() {
    const canGenerate = uploadedFile && selectedTheme;

    generateBtn.disabled = !canGenerate;

    if (canGenerate) {
        const theme = availableThemes.find(t => t.name === selectedTheme);
        generateInfo.textContent = `Pronto para gerar PDF com o tema "${theme?.displayName || selectedTheme}"`;
    } else if (!uploadedFile) {
        generateInfo.textContent = 'Faça upload de um arquivo para continuar';
    } else {
        generateInfo.textContent = 'Selecione um tema para continuar';
    }
}

/**
 * Generate PDF
 */
async function generatePDF() {
    if (!uploadedFile || !selectedTheme) return;

    // Update button state
    generateBtn.classList.add('loading');
    generateBtn.disabled = true;
    generateBtnText.textContent = 'Gerando PDF...';

    try {
        // Prepare form data
        const formData = new FormData();
        formData.append('markdown', uploadedFile);
        formData.append('theme', selectedTheme);

        // Send request
        const response = await fetch('/api/generate', {
            method: 'POST',
            body: formData
        });

        if (!response.ok) {
            const error = await response.json();
            throw new Error(error.error || 'Erro ao gerar PDF');
        }

        // Download PDF
        const blob = await response.blob();
        const url = window.URL.createObjectURL(blob);
        const a = document.createElement('a');
        a.href = url;
        a.download = uploadedFile.name.replace('.md', '.pdf');
        document.body.appendChild(a);
        a.click();
        window.URL.revokeObjectURL(url);
        document.body.removeChild(a);

        showToast('PDF gerado com sucesso!', 'success');

    } catch (error) {
        console.error('Generation error:', error);
        showToast(error.message || 'Erro ao gerar PDF', 'error');
    } finally {
        // Reset button state
        generateBtn.classList.remove('loading');
        generateBtn.disabled = false;
        generateBtnText.textContent = 'Gerar PDF Profissional';
    }
}

/**
 * Show toast notification
 */
function showToast(message, type = 'success') {
    toastMessage.textContent = message;
    toast.classList.remove('error');

    if (type === 'error') {
        toast.classList.add('error');
    }

    toast.classList.add('show');

    setTimeout(() => {
        toast.classList.remove('show');
    }, 3000);
}

/**
 * Format file size
 */
function formatFileSize(bytes) {
    if (bytes === 0) return '0 Bytes';

    const k = 1024;
    const sizes = ['Bytes', 'KB', 'MB', 'GB'];
    const i = Math.floor(Math.log(bytes) / Math.log(k));

    return Math.round(bytes / Math.pow(k, i) * 100) / 100 + ' ' + sizes[i];
}
