#!/usr/bin/env python3
"""
Script de Montagem Automatizada do E-book
Guia Completo Sala VIP 0800™

Este script concatena todos os módulos .md na ordem correta
para formar o e-book completo.
"""

import sys
from pathlib import Path
from datetime import datetime


def montar_ebook(base_dir: Path) -> bool:
    """
    Monta o e-book completo a partir dos módulos individuais.

    Args:
        base_dir: Diretório base do projeto

    Returns:
        True se a montagem foi bem-sucedida, False caso contrário
    """
    # Define a ordem dos arquivos
    ordem = [
        "content/capitulos/00_Guia_Completo_Sala_VIP_0800.md",
    ]

    # Materiais bonus na ordem alfabética
    materiais_bonus = [
        "content/materiais_bonus/AcessoMap.md",
        "content/materiais_bonus/Apps_Gratuitos_e_Armadilhas.md",
        "content/materiais_bonus/Casos_Reais_de_Economia.md",
        "content/materiais_bonus/Checklist_Pre_Viagem.md",
        "content/materiais_bonus/Guia_Principais_Lounges_Brasil.md",
        "content/materiais_bonus/Lista_Cartoes_Gratuitos.md",
        "content/materiais_bonus/Lounge_Unlocker.md",
        "content/materiais_bonus/Quiet_Zones_Finder.md",
    ]

    ordem.extend(materiais_bonus)

    # Arquivo de saída
    arquivo_saida = base_dir / "ebook_completo.md"

    print("🚀 Iniciando montagem do E-book...")
    print(f"📂 Diretório base: {base_dir}")
    print(f"📄 Arquivo de saída: {arquivo_saida}")
    print("-" * 60)

    erros = []
    conteudo_total = []

    # Header do e-book
    conteudo_total.append(f"""<!--
    Guia Completo Sala VIP 0800™
    Gerado automaticamente em: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}
    Por: Sistema de Montagem Automatizada
-->

""")

    # Processa cada arquivo
    for i, arquivo_rel in enumerate(ordem, 1):
        arquivo_path = base_dir / arquivo_rel

        if not arquivo_path.exists():
            erro = f"❌ ERRO: Arquivo não encontrado: {arquivo_rel}"
            print(erro)
            erros.append(erro)
            continue

        print(f"✅ [{i}/{len(ordem)}] Processando: {arquivo_rel}")

        try:
            conteudo = arquivo_path.read_text(encoding='utf-8')
            conteudo_total.append(conteudo)
            conteudo_total.append("\n\n---\n\n")  # Separador entre seções
        except Exception as e:
            erro = f"❌ ERRO ao ler {arquivo_rel}: {str(e)}"
            print(erro)
            erros.append(erro)

    # Se houver erros críticos, não salva
    if erros:
        print("\n" + "=" * 60)
        print("⚠️  ATENÇÃO: Foram encontrados erros durante a montagem:")
        for erro in erros:
            print(f"   {erro}")
        print("=" * 60)
        return False

    # Salva o arquivo final
    try:
        arquivo_saida.write_text(''.join(conteudo_total), encoding='utf-8')
        print("\n" + "=" * 60)
        print("✨ E-book montado com sucesso!")
        print(f"📊 Total de módulos: {len(ordem)}")
        print(f"📝 Tamanho do arquivo: {arquivo_saida.stat().st_size:,} bytes")
        print(f"💾 Salvo em: {arquivo_saida}")
        print("=" * 60)
        return True
    except Exception as e:
        print(f"\n❌ ERRO ao salvar o arquivo final: {str(e)}")
        return False


def main():
    """Função principal"""
    # Determina o diretório base (onde o script está)
    script_dir = Path(__file__).parent
    base_dir = script_dir.parent

    sucesso = montar_ebook(base_dir)

    if sucesso:
        print("\n✅ Processo concluído com sucesso!")
        sys.exit(0)
    else:
        print("\n❌ Processo concluído com erros.")
        sys.exit(1)


if __name__ == "__main__":
    main()
