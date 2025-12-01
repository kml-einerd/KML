"""
Script para verificar qual tipo de chave Supabase está sendo usada
"""

import os
from pathlib import Path
from dotenv import load_dotenv
import base64
import json

# Carregar .env
env_path = Path(__file__).parent / '.env'
load_dotenv(env_path, override=True)

SUPABASE_URL = os.getenv('SUPABASE_URL', '')
SUPABASE_KEY = os.getenv('SUPABASE_KEY', '')

print("=" * 70)
print("🔍 VERIFICAÇÃO DA CHAVE SUPABASE")
print("=" * 70)

if not SUPABASE_URL:
    print("❌ SUPABASE_URL não encontrado no .env")
else:
    print(f"✅ SUPABASE_URL: {SUPABASE_URL[:30]}...")

if not SUPABASE_KEY:
    print("❌ SUPABASE_KEY não encontrado no .env")
else:
    print(f"✅ SUPABASE_KEY encontrado (comprimento: {len(SUPABASE_KEY)} chars)")

    # Tentar decodificar JWT para verificar o role
    try:
        parts = SUPABASE_KEY.split('.')
        if len(parts) == 3:
            # É um JWT
            payload = parts[1]
            # Adicionar padding se necessário
            padding = 4 - len(payload) % 4
            if padding != 4:
                payload += '=' * padding

            decoded = base64.urlsafe_b64decode(payload)
            payload_json = json.loads(decoded)

            key_role = payload_json.get('role', 'unknown')

            print("\n" + "=" * 70)
            print("📋 INFORMAÇÕES DA CHAVE")
            print("=" * 70)
            print(f"Role: {key_role}")
            print(f"Issued at: {payload_json.get('iat', 'N/A')}")

            if key_role == 'anon':
                print("\n" + "⚠️  " * 20)
                print("❌ PROBLEMA IDENTIFICADO!")
                print("⚠️  " * 20)
                print("\n🔴 Você está usando a chave 'anon' (anonymous)")
                print("🔴 Para o ETL funcionar, você DEVE usar a chave 'service_role'")
                print("\n📝 COMO CORRIGIR:")
                print("   1. Acesse: https://supabase.com/dashboard/project/SEU_PROJETO/settings/api")
                print("   2. Procure por 'service_role' na seção 'Project API keys'")
                print("   3. Copie a chave 'service_role' (NÃO a 'anon')")
                print("   4. Cole no arquivo .env, substituindo SUPABASE_KEY=...")
                print("   5. Salve o arquivo .env")
                print("   6. Execute o ETL novamente")
                print("\n⚠️  ATENÇÃO: A chave service_role tem poderes administrativos!")
                print("⚠️  Nunca compartilhe ou exponha essa chave publicamente!")
                print("⚠️  " * 20)

            elif key_role == 'service_role':
                print("\n✅ ✅ ✅ PERFEITO! ✅ ✅ ✅")
                print("✅ Você está usando a chave 'service_role' correta!")
                print("✅ Esta chave tem as permissões necessárias para o ETL")

            else:
                print(f"\n⚠️  Role desconhecido: {key_role}")
                print("⚠️  Recomendado usar 'service_role' para o ETL")

    except Exception as e:
        print(f"\n⚠️  Não foi possível decodificar a chave: {e}")
        print("⚠️  Verifique se a chave está correta no .env")

print("\n" + "=" * 70)
