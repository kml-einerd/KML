"""
Configurações da aplicação.
Lê variáveis de ambiente necessárias para funcionamento do backend.
"""
import os
from pydantic_settings import BaseSettings, SettingsConfigDict
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

    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        case_sensitive=False,
        extra="ignore"
    )


@lru_cache()
def obter_configuracoes() -> Configuracoes:
    """
    Retorna instância única das configurações (singleton).

    Returns:
        Configuracoes: Objeto com todas as configurações da aplicação
    """
    return Configuracoes()
