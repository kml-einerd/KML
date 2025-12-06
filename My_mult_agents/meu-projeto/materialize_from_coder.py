#!/usr/bin/env python3
import re
import sys
from pathlib import Path

def parse_files(markdown: str):
    """
    Procura padrões do tipo:

    ### File: caminho/arquivo.ext
    ```qualquercoisa
    ...código...
    ```
    """
    pattern = re.compile(
        r"^### File:\s*(?P<path>.+?)\s*$\s*```.*?\n(?P<code>.*?)```",
        re.MULTILINE | re.DOTALL,
    )

    for match in pattern.finditer(markdown):
        path = match.group("path").strip()
        code = match.group("code")
        yield path, code

def main():
    if len(sys.argv) < 2:
        print("Uso: materialize_from_coder.py caminho_para_coder.md", file=sys.stderr)
        sys.exit(1)

    coder_md_path = Path(sys.argv[1])
    if not coder_md_path.exists():
        print(f"[ERRO] Arquivo não encontrado: {coder_md_path}", file=sys.stderr)
        sys.exit(1)

    markdown = coder_md_path.read_text(encoding="utf-8")
    files = list(parse_files(markdown))

    if not files:
        print("[AVISO] Nenhum bloco de arquivo encontrado em coder.md. Verifique o formato.")
        sys.exit(0)

    for rel_path, code in files:
        dest = Path(rel_path)
        dest.parent.mkdir(parents=True, exist_ok=True)
        dest.write_text(code.lstrip('\n'), encoding="utf-8")
        print(f"[OK] Arquivo gerado: {dest}")

if __name__ == "__main__":
    main()
