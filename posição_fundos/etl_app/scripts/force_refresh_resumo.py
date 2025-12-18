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
    
    if not url or not key:
        print("Erro: .env não configurado.")
        return

    client = create_client(url, key)
    
    # Lista de meses para reprocessar (ajuste conforme necessidade)
    meses_para_processar = [
        (2024, 6), (2024, 7), (2024, 8), (2024, 9), (2024, 10), (2024, 11), (2024, 12),
        (2025, 1)
    ]
    
    print("Iniciando reprocessamento do resumo mensal...")
    
    for ano, mes in meses_para_processar:
        mes_ref = f"{ano}-{mes:02d}-01"
        print(f"Processando {mes_ref}...")
        try:
            # Chama a função que consolida os dados no banco
            print(f"   > Enviando request para {mes_ref}...")
            response = client.rpc('atualizar_resumo_mensal', {'p_mes_ref': mes_ref}).execute()
            print(f"   ✓ Sucesso! Dados: {response.data}")
        except Exception as e:
            print(f"   ❌ Erro capturado: {type(e).__name__}: {e}")
            import traceback
            traceback.print_exc()

if __name__ == "__main__":
    main()
