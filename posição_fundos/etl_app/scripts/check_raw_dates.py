import os
import sys
from dotenv import load_dotenv
from supabase import create_client

sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

def main():
    load_dotenv()
    client = create_client(os.getenv('SUPABASE_URL'), os.getenv('SUPABASE_KEY'))
    
    # Tentar buscar datas distintas de acoes_fundos
    # Como distinct é chato via API simples sem RPC, vou pegar uma amostra ou usar RPC se existir
    # Vou tentar pegar os últimos 1000 registros e ver as datas
    print("Verificando acoes_fundos...")
    try:
        response = client.from_('acoes_fundos').select('mes_referencia').limit(2000).order('mes_referencia', desc=True).execute()
        datas = set(d['mes_referencia'] for d in response.data)
        print("Datas encontradas na amostra de acoes_fundos:")
        for d in sorted(datas, reverse=True):
            print(f" - {d}")
    except Exception as e:
        print(f"Erro ao ler acoes_fundos: {e}")

if __name__ == "__main__":
    main()
