"""
Script para testar conexão e permissões do Supabase
"""

from uploaders.supabase_client import SupabaseClient
from utils.logger import app_logger

print("=" * 70)
print("🔍 TESTANDO CONEXÃO E PERMISSÕES DO SUPABASE")
print("=" * 70)

try:
    # Inicializar cliente
    print("\n1️⃣ Inicializando cliente Supabase...")
    client = SupabaseClient()
    print("   ✅ Cliente inicializado")

    # Testar query simples na tabela fundos
    print("\n2️⃣ Testando SELECT na tabela 'fundos'...")
    try:
        result = client.client.table('fundos').select('*').limit(1).execute()
        print(f"   ✅ SELECT funcionou! Tabela tem {len(result.data)} registro(s) de teste")
    except Exception as e:
        print(f"   ❌ SELECT falhou: {e}")
        print("\n   🔧 POSSÍVEIS SOLUÇÕES:")
        print("   1. Verifique se a tabela 'fundos' existe no Supabase")
        print("   2. Desabilite RLS (Row Level Security) nas tabelas:")
        print("      - Acesse: Supabase Dashboard > Authentication > Policies")
        print("      - Para cada tabela (fundos, emissores, ativos, etc):")
        print("        - Clique em 'Disable RLS' OU")
        print("        - Crie uma policy que permite tudo para service_role")

    # Testar INSERT na tabela fundos
    print("\n3️⃣ Testando INSERT na tabela 'fundos'...")
    try:
        test_data = [{
            'cnpj': '00000000000001',
            'nome_fundo': 'TESTE - REMOVER',
            'classe': 'Teste'
        }]
        result = client.client.table('fundos').insert(test_data).execute()
        print(f"   ✅ INSERT funcionou!")

        # Limpar o teste
        print("\n4️⃣ Limpando registro de teste...")
        client.client.table('fundos').delete().eq('cnpj', '00000000000001').execute()
        print("   ✅ Limpeza concluída")

    except Exception as e:
        print(f"   ❌ INSERT falhou: {e}")
        print("\n   🔧 DIAGNÓSTICO:")
        if 'permission denied' in str(e).lower():
            print("   🔴 Erro de permissão detectado!")
            print("\n   📋 INSTRUÇÕES PARA CORRIGIR:")
            print("   1. Acesse o Supabase Dashboard")
            print("   2. Vá em 'Table Editor' e selecione a tabela 'fundos'")
            print("   3. Clique em 'RLS' no menu superior")
            print("   4. DESABILITE o RLS clicando em 'Disable RLS'")
            print("   5. Repita para todas as tabelas:")
            print("      - fundos")
            print("      - emissores")
            print("      - ativos")
            print("      - patrimonio_liquido")
            print("      - posicoes")
            print("      - fi_blc_1, fi_blc_2, fi_blc_3, etc")
            print("\n   ⚠️  ALTERNATIVA (mais segura):")
            print("   Crie uma policy que permita tudo para service_role:")
            print("   - Nome: 'Allow service role all access'")
            print("   - Using: auth.role() = 'service_role'")
            print("   - Policy command: All (SELECT, INSERT, UPDATE, DELETE)")

    # Testar UPSERT
    print("\n5️⃣ Testando UPSERT na tabela 'fundos'...")
    try:
        test_data = [{
            'cnpj': '00000000000002',
            'nome_fundo': 'TESTE UPSERT - REMOVER',
        }]
        result = client.client.table('fundos').upsert(test_data, on_conflict='cnpj').execute()
        print(f"   ✅ UPSERT funcionou!")

        # Limpar
        client.client.table('fundos').delete().eq('cnpj', '00000000000002').execute()
        print("   ✅ Limpeza concluída")

    except Exception as e:
        print(f"   ❌ UPSERT falhou: {e}")

except Exception as e:
    print(f"\n❌ ERRO FATAL: {e}")
    import traceback
    traceback.print_exc()

print("\n" + "=" * 70)
print("✅ TESTE CONCLUÍDO")
print("=" * 70)
