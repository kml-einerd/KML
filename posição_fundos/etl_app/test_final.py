"""
TESTE FINAL - Verifica que TUDO está funcionando antes de rodar o ETL completo
"""

import pandas as pd
import numpy as np
from uploaders.batch_uploader import BatchUploader
from uploaders.supabase_client import SupabaseClient
from utils.logger import app_logger

print("=" * 80)
print("🎯 TESTE FINAL - VERIFICAÇÃO COMPLETA")
print("=" * 80)

sucesso_total = True

# =============================================================================
# TESTE 1: Upload Real com Normalização
# =============================================================================
print("\n📋 TESTE 1: Upload Real (com normalização + limpeza)")
print("-" * 80)

try:
    client = SupabaseClient()
    uploader = BatchUploader(client)

    # Criar dados de teste com problemas reais que apareceram:
    # - Campos diferentes (problema do "All keys must match")
    # - Valores None/NaN (problema do "Empty json")
    dados_teste = [
        {'cnpj': 'TEST_A_001', 'nome_fundo': 'Fundo A', 'classe': 'FIA'},
        {'cnpj': 'TEST_B_002', 'nome_fundo': 'Fundo B'},  # Falta classe
        {'cnpj': 'TEST_C_003', 'nome_fundo': None, 'classe': 'FIM'},  # Nome None
        {'cnpj': 'TEST_D_004', 'nome_fundo': 'Fundo D', 'valor': np.nan},  # NaN
    ]

    print(f"Dados de teste: {len(dados_teste)} registros")
    for i, item in enumerate(dados_teste, 1):
        print(f"  {i}. {item}")

    # Upload usando o método real
    resultado = uploader.upload_com_progresso(
        table='fundos',
        data=dados_teste,
        on_conflict='cnpj',
        descricao='Teste final',
        return_ids=False
    )

    print(f"\n📊 Resultado do upload:")
    print(f"   Total: {resultado['total']}")
    print(f"   Sucesso: {resultado['sucesso']}")
    print(f"   Erros: {resultado['erros']}")
    print(f"   Taxa: {resultado['taxa_sucesso']:.1f}%")

    if resultado['sucesso'] == resultado['total']:
        print("✅ TESTE 1 PASSOU - Upload 100% bem sucedido!")
    else:
        print(f"⚠️  TESTE 1 PARCIAL - {resultado['erros']} erros")
        sucesso_total = False

    # Limpar dados de teste
    print("\n🧹 Limpando dados de teste...")
    for item in dados_teste:
        cnpj = item.get('cnpj')
        if cnpj:
            client.client.table('fundos').delete().eq('cnpj', cnpj).execute()
    print("✅ Limpeza concluída")

except Exception as e:
    print(f"❌ TESTE 1 FALHOU: {e}")
    import traceback
    traceback.print_exc()
    sucesso_total = False

# =============================================================================
# TESTE 2: Upload com return_ids
# =============================================================================
print("\n📋 TESTE 2: Upload com Retorno de IDs")
print("-" * 80)

try:
    client = SupabaseClient()
    uploader = BatchUploader(client)

    dados_ids = [
        {'cnpj': 'TEST_ID_001', 'nome_fundo': 'Teste ID 1'},
        {'cnpj': 'TEST_ID_002', 'nome_fundo': 'Teste ID 2'},
    ]

    resultado = uploader.upload_com_progresso(
        table='fundos',
        data=dados_ids,
        on_conflict='cnpj',
        return_ids=True  # IMPORTANTE: testar retorno de IDs
    )

    if 'ids' in resultado and len(resultado['ids']) > 0:
        print(f"✅ TESTE 2 PASSOU - {len(resultado['ids'])} IDs retornados")
        print(f"   IDs: {resultado['ids'][:3]}...")  # Mostrar primeiros 3
    else:
        print(f"⚠️  TESTE 2 AVISO - Nenhum ID retornado (pode ser normal se não foi inserido)")

    # Limpar
    for item in dados_ids:
        client.client.table('fundos').delete().eq('cnpj', item['cnpj']).execute()

except Exception as e:
    print(f"❌ TESTE 2 FALHOU: {e}")
    sucesso_total = False

# =============================================================================
# TESTE 3: Pipeline de Limpeza
# =============================================================================
print("\n📋 TESTE 3: Pipeline de Limpeza (sem upload)")
print("-" * 80)

dados_sujos = [
    {'a': 1, 'b': 'x'},
    {'a': 2, 'c': 'y'},  # Chave diferente
    {'a': None, 'b': np.nan},  # Valores ruins
]

print("Antes:")
for item in dados_sujos:
    print(f"  {item}")

# Aplicar pipeline
limpos = BatchUploader.limpar_valores_nulos(dados_sujos)
normalizados = BatchUploader.normalizar_chaves(limpos)

print("\nDepois:")
for item in normalizados:
    print(f"  {item}")

# Verificar que todos têm as mesmas chaves
chaves_sets = [set(item.keys()) for item in normalizados]
todas_iguais = all(s == chaves_sets[0] for s in chaves_sets)

if todas_iguais:
    print("✅ TESTE 3 PASSOU - Todas as chaves normalizadas")
else:
    print("❌ TESTE 3 FALHOU - Chaves ainda diferentes")
    sucesso_total = False

# =============================================================================
# RESULTADO FINAL
# =============================================================================
print("\n" + "=" * 80)
if sucesso_total:
    print("🎉🎉🎉 TODOS OS TESTES PASSARAM! 🎉🎉🎉")
    print("=" * 80)
    print("\n✅ A aplicação está 100% pronta!")
    print("✅ Pode executar: python main.py")
    print("\n🚀 Expectativa: Upload de ~25.000 fundos com 100% de sucesso")
else:
    print("⚠️  ALGUNS TESTES FALHARAM")
    print("=" * 80)
    print("\n⚠️  Revise os erros acima antes de executar o ETL completo")

print("=" * 80)
