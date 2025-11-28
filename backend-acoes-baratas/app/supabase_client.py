"""
Cliente Supabase para acesso ao banco de dados.
"""
from supabase import create_client, Client
from functools import lru_cache
from app.config import obter_configuracoes


@lru_cache()
def obter_cliente_supabase() -> Client:
    """
    Retorna instância única do cliente Supabase (singleton).

    Returns:
        Client: Cliente Supabase configurado com as credenciais
    """
    config = obter_configuracoes()
    return create_client(config.supabase_url, config.supabase_service_key)
