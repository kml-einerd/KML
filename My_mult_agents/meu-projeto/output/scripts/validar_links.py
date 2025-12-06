#!/usr/bin/env python3
"""
Script de Validação de Links
Guia Completo Sala VIP 0800™

Valida todos os links de imagens e URLs no e-book.
"""

import re
import sys
from pathlib import Path
from typing import List, Tuple
import urllib.request
import urllib.error


def extrair_links(conteudo: str) -> Tuple[List[str], List[str]]:
    """
    Extrai links de imagens e URLs do conteúdo Markdown.

    Args:
        conteudo: Conteúdo do arquivo Markdown

    Returns:
        Tupla com (links de imagens, links de URLs)
    """
    # Padrão para imagens: ![alt](url)
    imagens = re.findall(r'!\[.*?\]\((https?://[^\)]+)\)', conteudo)

    # Padrão para links: [text](url) mas não imagens
    urls = re.findall(r'(?<!!)\[.*?\]\((https?://[^\)]+)\)', conteudo)

    return imagens, urls


def validar_url(url: str, timeout: int = 10) -> Tuple[bool, str]:
    """
    Valida se uma URL está acessível.

    Args:
        url: URL para validar
        timeout: Timeout em segundos

    Returns:
        Tupla (sucesso, mensagem)
    """
    try:
        req = urllib.request.Request(
            url,
            headers={'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7)'}
        )
        with urllib.request.urlopen(req, timeout=timeout) as response:
            status = response.getcode()
            if status == 200:
                return True, f"✅ OK (HTTP {status})"
            else:
                return False, f"⚠️  HTTP {status}"
    except urllib.error.HTTPError as e:
        return False, f"❌ HTTP Error {e.code}"
    except urllib.error.URLError as e:
        return False, f"❌ URL Error: {str(e.reason)}"
    except Exception as e:
        return False, f"❌ Erro: {str(e)}"


def validar_ebook(arquivo_path: Path) -> dict:
    """
    Valida todos os links do e-book.

    Args:
        arquivo_path: Caminho para o arquivo do e-book

    Returns:
        Dicionário com estatísticas da validação
    """
    print("🔍 Iniciando validação de links...")
    print(f"📄 Arquivo: {arquivo_path}")
    print("-" * 60)

    if not arquivo_path.exists():
        print(f"❌ ERRO: Arquivo não encontrado: {arquivo_path}")
        return {"sucesso": False}

    # Lê o conteúdo
    conteudo = arquivo_path.read_text(encoding='utf-8')

    # Extrai links
    imagens, urls = extrair_links(conteudo)

    print(f"\n📊 Estatísticas:")
    print(f"   🖼️  Imagens encontradas: {len(imagens)}")
    print(f"   🔗 URLs encontradas: {len(urls)}")
    print("-" * 60)

    # Validação de imagens
    print("\n🖼️  Validando Imagens:")
    print("-" * 60)

    imagens_ok = 0
    imagens_erro = []

    for i, img in enumerate(set(imagens), 1):  # set() para remover duplicatas
        print(f"[{i}/{len(set(imagens))}] {img[:60]}...")
        sucesso, msg = validar_url(img)
        print(f"    {msg}")

        if sucesso:
            imagens_ok += 1
        else:
            imagens_erro.append((img, msg))

    # Validação de URLs
    print("\n🔗 Validando URLs:")
    print("-" * 60)

    urls_ok = 0
    urls_erro = []

    unique_urls = set(urls)
    if unique_urls:
        for i, url in enumerate(unique_urls, 1):
            print(f"[{i}/{len(unique_urls)}] {url[:60]}...")
            sucesso, msg = validar_url(url)
            print(f"    {msg}")

            if sucesso:
                urls_ok += 1
            else:
                urls_erro.append((url, msg))
    else:
        print("   ℹ️  Nenhuma URL para validar")

    # Relatório final
    print("\n" + "=" * 60)
    print("📋 RELATÓRIO FINAL")
    print("=" * 60)
    print(f"\n🖼️  Imagens:")
    print(f"   ✅ OK: {imagens_ok}/{len(set(imagens))}")
    print(f"   ❌ Erros: {len(imagens_erro)}")

    print(f"\n🔗 URLs:")
    print(f"   ✅ OK: {urls_ok}/{len(unique_urls) if unique_urls else 0}")
    print(f"   ❌ Erros: {len(urls_erro)}")

    # Detalhes dos erros
    if imagens_erro or urls_erro:
        print("\n⚠️  DETALHES DOS ERROS:")
        print("-" * 60)

        if imagens_erro:
            print("\n🖼️  Imagens com erro:")
            for url, msg in imagens_erro:
                print(f"   {msg}")
                print(f"   URL: {url}\n")

        if urls_erro:
            print("\n🔗 URLs com erro:")
            for url, msg in urls_erro:
                print(f"   {msg}")
                print(f"   URL: {url}\n")

    total_erros = len(imagens_erro) + len(urls_erro)

    print("=" * 60)

    if total_erros == 0:
        print("✅ Todos os links estão funcionando!")
    else:
        print(f"⚠️  {total_erros} link(s) com problema(s)")

    print("=" * 60)

    return {
        "sucesso": total_erros == 0,
        "imagens_ok": imagens_ok,
        "imagens_erro": len(imagens_erro),
        "urls_ok": urls_ok,
        "urls_erro": len(urls_erro),
    }


def main():
    """Função principal"""
    script_dir = Path(__file__).parent
    base_dir = script_dir.parent
    arquivo_ebook = base_dir / "ebook_completo.md"

    resultado = validar_ebook(arquivo_ebook)

    if resultado.get("sucesso", False):
        sys.exit(0)
    else:
        sys.exit(1)


if __name__ == "__main__":
    main()
