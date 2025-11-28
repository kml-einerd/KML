"""
Configurações da aplicação.
Lê variáveis de ambiente necessárias para funcionamento do backend.
"""
import os
from pydantic_settings import BaseSettings
from functools import lru_cache


class Configuracoes(BaseSettings):
    """Configurações da aplicação carregadas de variáveis de ambiente."""

    # Supabase
    supabase_url: str
    supabase_service_key: str

    # API
    api_host: str = "0.0.0.0"
    api_port: int = 8000
    api_reload: bool = False

    # Ambiente
    environment: str = "development"

    class Config:
        env_file = ".env"
        case_sensitive = False


@lru_cache()
def obter_configuracoes() -> Configuracoes:
    """
    Retorna instância única das configurações (singleton).

    Returns:
        Configuracoes: Objeto com todas as configurações da aplicação
    """
    return Configuracoes()
