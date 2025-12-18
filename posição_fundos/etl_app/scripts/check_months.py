import os
import sys
from dotenv import load_dotenv
from supabase import create_client

# Adicionar root ao path
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

def main():
    load_dotenv()
    
    url = os.getenv('SUPABASE_URL')
    key = os.getenv('SUPABASE_KEY')
    
    client = create_client(url, key)
    
    # Consultar meses disponíveis
    response = client.from_('resumo_mensal').select('mes_referencia').order('mes_referencia', desc=True).execute()
    
    data = response.data
    unique_months = sorted(list(set(d['mes_referencia'] for d in data)), reverse=True)
    
    print(f"Meses encontrados em resumo_mensal ({len(unique_months)}):")
    for m in unique_months:
        print(f" - {m}")

if __name__ == "__main__":
    main()
