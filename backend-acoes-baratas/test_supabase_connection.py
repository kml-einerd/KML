import os
from dotenv import load_dotenv
from supabase import create_client

load_dotenv()

SUPABASE_URL = os.getenv("SUPABASE_URL")
SUPABASE_KEY = os.getenv("SUPABASE_SERVICE_KEY")

if not SUPABASE_URL or not SUPABASE_KEY:
    print("Erro: SUPABASE_URL ou SUPABASE_SERVICE_KEY não definidos.")
    exit(1)

print(f"Conectando ao Supabase: {SUPABASE_URL}")
supabase = create_client(SUPABASE_URL, SUPABASE_KEY)

# Tentar inserir um registro de teste na tabela 'acoes'
data = {
    "ticker": "TESTE123",
    "nome_curto": "Teste",
    "ativo": False
}

try:
    print("Tentando inserir registro de teste...")
    response = supabase.table("acoes").upsert(data, on_conflict="ticker").execute()
    print("Resposta completa:", response)
    
    if response.data:
        print("Sucesso! Dados inseridos:", response.data)
    else:
        print("Aviso: Nenhum dado retornado (pode ser erro silencioso ou RLS).")

except Exception as e:
    print(f"Erro ao inserir: {e}")
