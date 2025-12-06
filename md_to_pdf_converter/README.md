# MD to PDF Pro - Web-to-Print Converter

A professional, Node.js-based tool to convert Markdown files into high-quality PDFs using **Puppeteer**, **Paged.js**, and **Mermaid.js**.

![Node.js](https://img.shields.io/badge/Node.js-18%2B-green)
![Puppeteer](https://img.shields.io/badge/Puppeteer-PDF-blue)
![Paged.js](https://img.shields.io/badge/Paged.js-Layout-orange)

---

## 🚀 Features

- **Web-to-Print Architecture**: Uses Chrome Headless (Puppeteer) for perfect rendering
- **Professional Layouts**: Automatic pagination, headers, footers via Paged.js
- **Beautiful Diagrams**: Client-side rendering of Mermaid diagrams with full UTF-8 support
- **Special Characters Support**: Full support for Portuguese characters (acentos, ã, ç, R$)
- **11 Professional Themes**: From classic serif to modern tech styles
- **Web Interface**: Easy-to-use web UI with theme preview
- **REST API**: Programmatic access for integrations

## 📦 Installation

1. **Clone the repository**:
   ```bash
   git clone <repository-url>
   cd md_to_pdf_converter
   ```

2. **Install Dependencies**:
   ```bash
   npm install
   ```

## 💻 Usage

### Web Interface (Recommended)

1. **Start the server**:
   ```bash
   npm start
   ```

2. **Open your browser**:
   ```
   http://localhost:3000
   ```

3. **Upload your Markdown file, select a theme, and generate PDF!**

### CLI Usage

```bash
node index.js convert input.md --theme obsidian
```

### API Usage

**List available themes:**
```bash
curl http://localhost:3000/api/themes
```

**Generate PDF:**
```bash
curl -X POST http://localhost:3000/api/generate \
  -F "markdown=@input.md" \
  -F "theme=obsidian" \
  --output output.pdf
```

### Available Themes (11 total)

- `obsidian` - Dark theme inspired by Obsidian
- `modern_blue` - Clean modern blue design
- `dark_tech` - Developer-focused dark theme
- `classic_serif` - Elegant traditional typography
- `academic-modern` - Academic paper style
- `corporate-premium` - Professional business theme
- `creative-zine` - Creative magazine style
- `minimalist-architect` - Minimalist clean design
- `playful-handbook` - Fun handbook style
- `retro-future` - Cyberpunk/Synthwave aesthetic
- `technical-manual` - Technical documentation style

## 🛠️ Project Structure

```
md_to_pdf_converter/
├── index.js                # CLI Entry Point
├── src/
│   ├── pdf-generator.js    # Puppeteer Logic
│   ├── html-processor.js   # Markdown -> HTML (Unified)
│   └── content-analyzer.js # Smart Layout Logic
├── assets/
│   ├── templates/          # HTML Layouts (base.html)
│   └── themes/             # CSS Themes
└── package.json
```

## 📝 Markdown Features Supported

### Text Formatting
- **Frontmatter**: YAML metadata (title, subtitle, author, date)
- **Headings**: H1 through H6 with automatic styling
- **Bold**, *Italic*, ~~Strikethrough~~
- Links and images with auto-sizing
- Blockquotes with styled borders

### Code
- **Syntax Highlighting**: Automatic language detection
- **Inline Code**: Styled code snippets
- Support for 100+ programming languages

### Diagrams (Mermaid.js)
- ✅ Flowcharts (`graph`, `flowchart`)
- ✅ Sequence Diagrams
- ✅ Class Diagrams
- ✅ State Diagrams
- ✅ Gantt Charts
- ✅ Pie Charts
- ✅ Git Graphs
- ✅ Full UTF-8 support (Portuguese, Spanish, French, etc.)
- ✅ Special characters (R$, €, £, acentos, cedilha)

### Tables and Lists
- GitHub Flavored Markdown tables
- Ordered and unordered lists
- Task lists with checkboxes
- Nested lists

### Advanced Features
- Automatic page breaks
- Page numbering
- Professional typography
- Smart quotes
- Non-breaking spaces
- Cover page generation

## 🧪 Testing

Run the automated test suite:
```bash
node test-complete.js
```

This will:
1. Process Markdown with all features
2. Generate a test PDF with Mermaid diagrams
3. Verify rendering of special characters
4. Output statistics and validation

## 🐛 Troubleshooting

### PDF generation hangs
- Check if Puppeteer downloaded Chromium: `npm install puppeteer`
- Increase timeout in `pdf-generator.js` if needed

### Mermaid diagrams not rendering
- Verify diagram syntax at [Mermaid Live Editor](https://mermaid.live)
- Check console logs for specific errors
- Ensure proper diagram type is specified (graph, flowchart, etc.)

### Special characters display as boxes
- This should be fixed! All UTF-8 characters are now supported
- If you see issues, report them with a sample file

## 🚀 Deployment

### Render.com
The project includes configuration for Render deployment:
```bash
# Automatically uses process.env.PORT
# No changes needed for Render deployment
```

### Docker
```bash
docker build -t md-to-pdf-pro .
docker run -p 3000:3000 md-to-pdf-pro
```

## 📄 License

ISC

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## ✅ Recent Updates (2025-12-06)

- ✅ Fixed Mermaid rendering for special characters
- ✅ Corrected HTML template syntax
- ✅ Improved CSS for diagram display
- ✅ Enhanced markdown processing pipeline
- ✅ Added comprehensive test suite
- ✅ All 11 themes working correctly

See `CORRECOES_REALIZADAS.md` for detailed changelog.
