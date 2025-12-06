# MD to PDF Pro - Web-to-Print Converter

A professional, Node.js-based tool to convert Markdown files into high-quality PDFs using **Puppeteer**, **Paged.js**, and **Mermaid.js**.

![Node.js](https://img.shields.io/badge/Node.js-18%2B-green)
![Puppeteer](https://img.shields.io/badge/Puppeteer-PDF-blue)
![Paged.js](https://img.shields.io/badge/Paged.js-Layout-orange)

---

## 🚀 Features

- **Web-to-Print Architecture**: Uses Chrome Headless (Puppeteer) for perfect rendering.
- **Professional Layouts**: Automatic pagination, headers, footers, and TOC via Paged.js.
- **Beautiful Diagrams**: Client-side rendering of Mermaid diagrams (no more static images!).
- **Smart Adaptive Design**: Automatically adjusts margins based on content density (code vs. text).
- **Custom Themes**: Includes professional themes like Retro Future, Modern Blue, and Dark Tech.

## 📦 Installation

1. **Install Dependencies**:
   ```bash
   npm install
   ```

## 💻 Usage

### Basic Conversion
```bash
node index.js convert input.md
```

### Apply a Theme
```bash
node index.js convert input.md --theme retro-future
```

### Available Themes
Check the `assets/themes` directory for available styles:
- `modern_blue` (Default)
- `retro-future` (Cyberpunk/Synthwave)
- `dark_tech` (Developer focused)
- `classic_serif` (Elegant)
- `corporate-premium`
- `creative-zine`

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

- **Frontmatter**: Title, Subtitle, Author, Date.
- **Code Blocks**: Syntax highlighting.
- **Mermaid**: Flowcharts, Sequence diagrams, Gantt charts, etc.
- **Images**: Auto-sized and centered.
- **Tables**: Styled according to the theme.

## 📄 License

ISC
