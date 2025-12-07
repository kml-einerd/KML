import React, { useState } from 'react';
import { Upload, FileText, Download, LayoutTemplate, Loader2 } from 'lucide-react';
import { useDropzone } from 'react-dropzone';
import { clsx } from 'clsx';
import { twMerge } from 'tailwind-merge';

const cn = (...inputs) => twMerge(clsx(inputs));

const THEMES = [
  { id: 'minimal-swiss', name: 'Minimal Swiss', desc: 'Helvetica, whitespace, B&W' },
  { id: 'tech-oreilly', name: 'Tech O\'Reilly', desc: 'Mono font, serif text, technical' },
  { id: 'dark-cyberpunk', name: 'Dark Cyberpunk', desc: 'Dark mode, neon text, futuristic' },
  { id: 'academic-paper', name: 'Academic Paper', desc: 'Serif, two columns, formal' },
  { id: 'corporate-blue', name: 'Corporate Blue', desc: 'Clean sans-serif, professional' },
  { id: 'editorial-magazine', name: 'Editorial Magazine', desc: 'Drop-caps, grid layout' },
  { id: 'nature-organic', name: 'Nature Organic', desc: 'Earth tones, rounded, humanist' },
  { id: 'vibrant-startup', name: 'Vibrant Startup', desc: 'Pop colors, gradients, 3D emojis' },
  { id: 'legal-formal', name: 'Legal Formal', desc: 'Wide margins, heavy serif' },
  { id: 'sketchy-hand', name: 'Sketchy Hand-drawn', desc: 'Handwritten style, irregular borders' },
];

function App() {
  const [file, setFile] = useState(null);
  const [theme, setTheme] = useState(THEMES[0].id);
  const [isGenerating, setIsGenerating] = useState(false);
  const [isPreviewLoading, setIsPreviewLoading] = useState(false);
  const [previewHtml, setPreviewHtml] = useState(null);

  const onDrop = (acceptedFiles) => {
    if (acceptedFiles.length > 0) {
      setFile(acceptedFiles[0]);
      setPreviewHtml(null); // Clear preview on new file
    }
  };

  const { getRootProps, getInputProps, isDragActive } = useDropzone({
    onDrop,
    accept: { 'text/markdown': ['.md'] },
    multiple: false
  });

  const handleGenerate = async () => {
    if (!file) return;

    setIsGenerating(true);
    const formData = new FormData();
    formData.append('file', file);
    formData.append('theme', theme);

    try {
      const response = await fetch('/api/generate-pdf', {
        method: 'POST',
        body: formData,
      });

      if (response.ok) {
        const blob = await response.blob();
        const url = window.URL.createObjectURL(blob);
        const a = document.createElement('a');
        a.href = url;
        a.download = `${file.name.replace('.md', '')}.pdf`;
        document.body.appendChild(a);
        a.click();
        a.remove();
      } else {
        alert('Failed to generate PDF');
      }
    } catch (error) {
      console.error('Error:', error);
      alert('Error generating PDF');
    } finally {
      setIsGenerating(false);
    }
  };

  const handlePreview = async () => {
     if (!file) return;
     setIsPreviewLoading(true);
     const formData = new FormData();
     formData.append('file', file);
     formData.append('theme', theme);
     formData.append('preview', 'true');

     try {
       const response = await fetch('/api/preview-html', {
           method: 'POST',
           body: formData
       });
       if(response.ok) {
           const html = await response.text();
           setPreviewHtml(html);
       }
     } catch(e) {
         console.error(e);
     } finally {
        setIsPreviewLoading(false);
     }
  }

  return (
    <div className="min-h-screen bg-slate-50 flex flex-col font-sans">
      <header className="bg-white border-b border-slate-200 px-6 py-4 flex items-center justify-between shadow-sm sticky top-0 z-50">
        <div className="flex items-center gap-2">
          <FileText className="w-6 h-6 text-indigo-600" />
          <h1 className="text-xl font-bold text-slate-800">Ebook Builder Design</h1>
        </div>
        <div className="text-sm text-slate-500 hidden sm:block">Web-to-Print Engine</div>
      </header>

      <main className="flex-1 max-w-7xl w-full mx-auto p-6 grid grid-cols-1 lg:grid-cols-12 gap-8">
        {/* Left Column: Controls */}
        <div className="lg:col-span-4 space-y-6">

          {/* Upload Area */}
          <div className="bg-white p-6 rounded-xl shadow-sm border border-slate-200">
            <h2 className="text-lg font-semibold mb-4 flex items-center gap-2">
              <Upload className="w-5 h-5" /> Source File
            </h2>
            <div
              {...getRootProps()}
              className={cn(
                "border-2 border-dashed rounded-lg p-8 text-center cursor-pointer transition-colors",
                isDragActive ? "border-indigo-500 bg-indigo-50" : "border-slate-300 hover:border-indigo-400",
                file ? "bg-slate-50 border-indigo-200" : ""
              )}
            >
              <input {...getInputProps()} />
              {file ? (
                <div className="flex flex-col items-center">
                   <FileText className="w-10 h-10 text-indigo-600 mb-2" />
                   <p className="font-medium text-slate-700">{file.name}</p>
                   <p className="text-xs text-slate-500">{(file.size / 1024).toFixed(1)} KB</p>
                </div>
              ) : (
                <div className="flex flex-col items-center text-slate-500">
                  <Upload className="w-8 h-8 mb-2 opacity-50" />
                  <p>Drag & drop markdown file here</p>
                  <p className="text-xs mt-1">or click to browse</p>
                </div>
              )}
            </div>
          </div>

          {/* Theme Selector */}
          <div className="bg-white p-6 rounded-xl shadow-sm border border-slate-200">
             <h2 className="text-lg font-semibold mb-4 flex items-center gap-2">
              <LayoutTemplate className="w-5 h-5" /> Select Theme
            </h2>
            <div className="space-y-3 max-h-[400px] overflow-y-auto pr-2 custom-scrollbar">
              {THEMES.map((t) => (
                <div
                  key={t.id}
                  onClick={() => setTheme(t.id)}
                  className={cn(
                    "p-3 rounded-lg border cursor-pointer transition-all",
                    theme === t.id
                      ? "border-indigo-600 bg-indigo-50 ring-1 ring-indigo-600"
                      : "border-slate-200 hover:border-slate-300 hover:bg-slate-50"
                  )}
                >
                  <h3 className="font-medium text-slate-900">{t.name}</h3>
                  <p className="text-xs text-slate-500">{t.desc}</p>
                </div>
              ))}
            </div>
          </div>

          {/* Action Buttons */}
          <div className="flex gap-3">
             <button
              onClick={handlePreview}
              disabled={!file || isPreviewLoading}
              className="flex-1 py-3 px-4 bg-white border border-slate-300 text-slate-700 rounded-lg font-medium hover:bg-slate-50 disabled:opacity-50 disabled:cursor-not-allowed transition-colors flex items-center justify-center gap-2"
            >
              {isPreviewLoading ? <Loader2 className="w-4 h-4 animate-spin"/> : "Preview"}
            </button>
            <button
              onClick={handleGenerate}
              disabled={!file || isGenerating}
              className="flex-1 py-3 px-4 bg-indigo-600 text-white rounded-lg font-medium hover:bg-indigo-700 disabled:opacity-50 disabled:cursor-not-allowed flex items-center justify-center gap-2 transition-colors shadow-sm"
            >
              {isGenerating ? (
                <>
                  <Loader2 className="w-5 h-5 animate-spin" />
                  Generating...
                </>
              ) : (
                <>
                  <Download className="w-5 h-5" />
                  Generate PDF
                </>
              )}
            </button>
          </div>

        </div>

        {/* Right Column: Preview */}
        <div className="lg:col-span-8 bg-slate-200 rounded-xl border border-slate-300 shadow-inner overflow-hidden flex flex-col h-[800px]">
           <div className="bg-slate-800 text-slate-400 px-4 py-2 text-xs flex justify-between items-center">
             <span>Live Preview (Scale: Fit)</span>
             <span>A4 (210mm x 297mm)</span>
           </div>
           <div className="flex-1 overflow-auto p-4 flex justify-center bg-slate-200">
             {previewHtml ? (
               <iframe
                  srcDoc={previewHtml}
                  className="bg-white shadow-xl min-h-[1000px] w-[210mm] border-none"
                  title="PDF Preview"
               />
             ) : (
               <div className="flex flex-col items-center justify-center text-slate-400 h-full">
                 <LayoutTemplate className="w-16 h-16 mb-4 opacity-20" />
                 <p>Upload a file and click Preview to see the result</p>
               </div>
             )}
           </div>
        </div>
      </main>
    </div>
  );
}

export default App;
