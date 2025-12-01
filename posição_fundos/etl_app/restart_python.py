#!/usr/bin/env python
"""
Script para limpar cache e forçar reimportação dos módulos
Execute este script ANTES de rodar main.py
"""

import sys
import os
from pathlib import Path
import shutil

print("=" * 70)
print("🔄 LIMPANDO CACHE PYTHON")
print("=" * 70)

# Diretório base
base_dir = Path(__file__).parent

# 1. Limpar __pycache__
print("\n1️⃣ Removendo diretórios __pycache__...")
count = 0
for pycache_dir in base_dir.rglob('__pycache__'):
    try:
        shutil.rmtree(pycache_dir)
        count += 1
        print(f"   ✓ Removido: {pycache_dir.relative_to(base_dir)}")
    except Exception as e:
        print(f"   ✗ Erro ao remover {pycache_dir}: {e}")

print(f"   ✅ {count} diretórios __pycache__ removidos")

# 2. Limpar arquivos .pyc
print("\n2️⃣ Removendo arquivos .pyc...")
count = 0
for pyc_file in base_dir.rglob('*.pyc'):
    try:
        pyc_file.unlink()
        count += 1
    except Exception as e:
        print(f"   ✗ Erro ao remover {pyc_file}: {e}")

print(f"   ✅ {count} arquivos .pyc removidos")

# 3. Verificar se há módulos carregados em sys.modules
print("\n3️⃣ Verificando módulos carregados...")
modulos_app = [m for m in sys.modules.keys() if 'uploaders' in m or 'processors' in m]
if modulos_app:
    print(f"   ⚠️  Encontrados {len(modulos_app)} módulos em cache:")
    for mod in modulos_app[:5]:  # Mostrar apenas os primeiros 5
        print(f"      - {mod}")
    print("   💡 Feche o Python e execute main.py em uma nova sessão")
else:
    print("   ✅ Nenhum módulo da aplicação em cache")

print("\n" + "=" * 70)
print("✅ LIMPEZA CONCLUÍDA!")
print("=" * 70)
print("\n📝 PRÓXIMOS PASSOS:")
print("   1. Feche este terminal")
print("   2. Abra um novo terminal")
print("   3. Entre na pasta: cd posição_fundos/etl_app")
print("   4. Ative o ambiente virtual (se aplicável)")
print("   5. Execute: python main.py")
print("\n💡 Isso garante que o Python use o código atualizado!")
print("=" * 70)
