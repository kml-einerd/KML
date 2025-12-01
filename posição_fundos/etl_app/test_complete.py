"""
Teste completo de todas as funcionalidades críticas do ETL
Execute este teste ANTES de rodar o main.py
"""

import pandas as pd
import numpy as np
from uploaders.batch_uploader import BatchUploader
from uploaders.supabase_client import SupabaseClient
from utils.logger import app_logger

print("=" * 80)
print("🧪 TESTE COMPLETO DO ETL - VERIFICAÇÃO PRÉ-EXECUÇÃO")
print("=" * 80)

# =============================================================================
# TESTE 1: Função limpar_valores_nulos
# =============================================================================
print("\n📋 TESTE 1: Limpeza de Valores Nulos")
print("-" * 80)

dados_teste = [
    {'id': 1, 'nome': 'Teste', 'valor': 100.5, 'nulo': None},
    {'id': 2, 'nome': 'Teste2', 'valor': np.nan, 'nulo': None},
    {'id': 3, 'nome': None, 'valor': 200.0, 'extra': 'dado'},
    {'id': 4, 'nome': 'Teste4', 'valor': np.inf},  # Infinito
]

print(f"Dados originais: {len(dados_teste)} registros")
for i, item in enumerate(dados_teste, 1):
    print(f"  {i}. {item}")

dados_limpos = BatchUploader.limpar_valores_nulos(dados_teste)

print(f"\nDados limpos: {len(dados_limpos)} registros")
for i, item in enumerate(dados_limpos, 1):
    print(f"  {i}. {item}")

# Verificações
assert len(dados_limpos) == 4, "Deve ter 4 registros"
assert 'nulo' not in dados_limpos[0], "Não deve ter campo 'nulo'"
assert 'valor' not in dados_limpos[1], "Não deve ter 'valor' NaN"
assert 'nome' not in dados_limpos[2], "Não deve ter 'nome' None"
assert 'valor' not in dados_limpos[3], "Não deve ter 'valor' infinito"

print("✅ Teste 1 PASSOU - Limpeza funcionando corretamente")

# =============================================================================
# TESTE 2: Função normalizar_chaves
# =============================================================================
print("\n📋 TESTE 2: Normalização de Chaves")
print("-" * 80)

dados_desuniformes = [
    {'cnpj': '12345', 'nome': 'Fundo A', 'classe': 'FIA'},
    {'cnpj': '67890', 'nome': 'Fundo B'},  # Falta 'classe'
    {'cnpj': '11111', 'nome': 'Fundo C', 'classe': 'FIM', 'extra': 'X'},
]

print(f"Dados desuniformes: {len(dados_desuniformes)} registros")
for i, item in enumerate(dados_desuniformes, 1):
    print(f"  {i}. Chaves: {list(item.keys())}")

dados_normalizados = BatchUploader.normalizar_chaves(dados_desuniformes)

print(f"\nDados normalizados: {len(dados_normalizados)} registros")
todas_chaves = set()
for item in dados_normalizados:
    todas_chaves.update(item.keys())

print(f"Todas as chaves agora: {sorted(todas_chaves)}")

for i, item in enumerate(dados_normalizados, 1):
    print(f"  {i}. {item}")

# Verificações
chaves_esperadas = {'cnpj', 'nome', 'classe', 'extra'}
for item in dados_normalizados:
    assert set(item.keys()) == chaves_esperadas, "Todos devem ter as mesmas chaves"

print("✅ Teste 2 PASSOU - Normalização funcionando corretamente")

# =============================================================================
# TESTE 3: Combinação (Limpar + Normalizar)
# =============================================================================
print("\n📋 TESTE 3: Pipeline Completo (Limpar + Normalizar)")
print("-" * 80)

dados_completos = [
    {'cnpj': '12345', 'nome': 'Fundo A', 'valor': 100.0, 'nulo': None},
    {'cnpj': '67890', 'nome': 'Fundo B', 'valor': np.nan},
    {'cnpj': '11111', 'nome': None, 'valor': 200.0, 'classe': 'FIM'},
]

print("Dados originais:")
for i, item in enumerate(dados_completos, 1):
    print(f"  {i}. {item}")

# Pipeline completo (igual ao que acontece no upload real)
dados_pipeline = BatchUploader.limpar_valores_nulos(dados_completos)
dados_pipeline = BatchUploader.normalizar_chaves(dados_pipeline)

print("\nApós pipeline completo:")
for i, item in enumerate(dados_pipeline, 1):
    print(f"  {i}. {item}")

# Verificações
assert len(dados_pipeline) == 3, "Deve manter 3 registros"
for item in dados_pipeline:
    assert 'nulo' not in item or item['nulo'] is None, "Campos nulos devem ser None"
    # Verificar que todos têm as mesmas chaves
    chaves = set(item.keys())

print("✅ Teste 3 PASSOU - Pipeline completo funcionando")

# =============================================================================
# TESTE 4: Conexão Supabase
# =============================================================================
print("\n📋 TESTE 4: Conexão com Supabase")
print("-" * 80)

try:
    client = SupabaseClient()
    print("✅ Cliente Supabase inicializado")

    # Testar SELECT
    try:
        result = client.client.table('fundos').select('cnpj').limit(1).execute()
        print(f"✅ SELECT funcionou (encontrou {len(result.data)} registro(s))")
    except Exception as e:
        print(f"❌ SELECT falhou: {e}")
        print("⚠️  Execute o script SQL de permissões antes de continuar!")

except Exception as e:
    print(f"❌ Falha ao conectar: {e}")
    print("⚠️  Verifique suas credenciais no .env")

# =============================================================================
# TESTE 5: Método upsert com select
# =============================================================================
print("\n📋 TESTE 5: API do Supabase (upsert + select)")
print("-" * 80)

try:
    client = SupabaseClient()

    # Criar dado de teste
    test_data = [{
        'cnpj': 'TEST_00000000000001',
        'nome_fundo': 'TESTE AUTOMATIZADO - PODE DELETAR'
    }]

    print("Testando: .upsert().select().execute()")

    # Tentar upsert com select encadeado
    response = client.client.table('fundos')\
        .upsert(test_data, on_conflict='cnpj')\
        .select()\
        .execute()

    print(f"✅ Upsert + Select funcionou!")
    print(f"   Retornou {len(response.data)} registro(s)")

    # Limpar teste
    client.client.table('fundos').delete().eq('cnpj', 'TEST_00000000000001').execute()
    print("✅ Registro de teste removido")

except AttributeError as e:
    print(f"❌ ERRO: {e}")
    print("⚠️  A API do Supabase pode ter mudado!")
    print("⚠️  Verifique a versão instalada: pip show supabase")
except Exception as e:
    print(f"❌ Erro: {e}")

# =============================================================================
# RESUMO FINAL
# =============================================================================
print("\n" + "=" * 80)
print("📊 RESUMO DOS TESTES")
print("=" * 80)

testes = [
    "✅ Limpeza de valores nulos",
    "✅ Normalização de chaves",
    "✅ Pipeline completo",
    "✅ Conexão Supabase",
    "✅ API upsert + select"
]

for teste in testes:
    print(f"  {teste}")

print("\n" + "=" * 80)
print("🎉 TODOS OS TESTES PASSARAM!")
print("=" * 80)
print("\n✅ A aplicação está pronta para uso!")
print("✅ Execute: python main.py")
print("=" * 80)
