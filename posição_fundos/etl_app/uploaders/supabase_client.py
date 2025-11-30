"""
Cliente Supabase com retry e logging
"""

from supabase import create_client, Client
import time
from typing import List, Dict, Optional
from config import (
    SUPABASE_URL,
    SUPABASE_KEY,
    MAX_RETRIES,
    RETRY_DELAY,
    UPLOAD_TIMEOUT
)
from utils.logger import app_logger

class SupabaseClient:
    """Cliente wrapper para Supabase com retry logic"""

    def __init__(self, url: str = SUPABASE_URL, key: str = SUPABASE_KEY):
        if not url or not key:
            raise ValueError("SUPABASE_URL e SUPABASE_KEY são obrigatórios")

        self.url = url
        self.key = key
        self.client: Client = create_client(url, key)

        app_logger.info("Cliente Supabase inicializado")

    def testar_conexao(self) -> bool:
        """
        Testa conexão com Supabase

        Returns:
            True se conectado com sucesso
        """
        try:
            # Tentar uma query simples
            result = self.client.table('fundos').select('cnpj').limit(1).execute()
            app_logger.success("✓ Conexão com Supabase OK")
            return True
        except Exception as e:
            app_logger.error(f"✗ Erro ao conectar com Supabase: {e}")
            return False

    def upsert(
        self,
        table: str,
        data: List[Dict],
        on_conflict: Optional[str] = None
    ) -> Dict:
        """
        Faz upsert (insert or update) de dados

        Args:
            table: Nome da tabela
            data: Lista de dicionários para inserir
            on_conflict: Coluna(s) de conflito (ex: 'cnpj')

        Returns:
            Resultado da operação

        Raises:
            Exception se falhar após todas as tentativas
        """
        for tentativa in range(1, MAX_RETRIES + 1):
            try:
                app_logger.debug(
                    f"Tentativa {tentativa}/{MAX_RETRIES} - "
                    f"Upsert {len(data)} registros em '{table}'"
                )

                result = self.client.table(table).upsert(
                    data,
                    on_conflict=on_conflict
                ).execute()

                app_logger.debug(f"✓ Upsert bem-sucedido em '{table}'")
                return result

            except Exception as e:
                app_logger.warning(
                    f"Tentativa {tentativa} falhou: {e}"
                )

                if tentativa < MAX_RETRIES:
                    time.sleep(RETRY_DELAY * tentativa)  # Exponential backoff
                else:
                    app_logger.error(
                        f"✗ Falha ao fazer upsert em '{table}' após {MAX_RETRIES} tentativas"
                    )
                    raise

    def insert(
        self,
        table: str,
        data: List[Dict]
    ) -> Dict:
        """
        Insere dados (sem upsert)

        Args:
            table: Nome da tabela
            data: Lista de dicionários para inserir

        Returns:
            Resultado da operação
        """
        for tentativa in range(1, MAX_RETRIES + 1):
            try:
                result = self.client.table(table).insert(data).execute()
                return result

            except Exception as e:
                if tentativa < MAX_RETRIES:
                    time.sleep(RETRY_DELAY * tentativa)
                else:
                    raise

    def select(
        self,
        table: str,
        columns: str = '*',
        filters: Optional[Dict] = None,
        limit: Optional[int] = None
    ) -> List[Dict]:
        """
        Faz SELECT de dados

        Args:
            table: Nome da tabela
            columns: Colunas a selecionar
            filters: Dicionário de filtros {coluna: valor}
            limit: Limite de resultados

        Returns:
            Lista de registros
        """
        try:
            query = self.client.table(table).select(columns)

            if filters:
                for key, value in filters.items():
                    query = query.eq(key, value)

            if limit:
                query = query.limit(limit)

            result = query.execute()
            return result.data

        except Exception as e:
            app_logger.error(f"Erro ao fazer SELECT em '{table}': {e}")
            return []

    def count(self, table: str, filters: Optional[Dict] = None) -> int:
        """
        Conta registros em uma tabela

        Args:
            table: Nome da tabela
            filters: Filtros opcionais

        Returns:
            Número de registros
        """
        try:
            query = self.client.table(table).select('*', count='exact')

            if filters:
                for key, value in filters.items():
                    query = query.eq(key, value)

            result = query.execute()
            return result.count if hasattr(result, 'count') else len(result.data)

        except Exception as e:
            app_logger.error(f"Erro ao contar em '{table}': {e}")
            return 0

    def delete(self, table: str, filters: Dict) -> Dict:
        """
        Deleta registros

        Args:
            table: Nome da tabela
            filters: Filtros para deletar

        Returns:
            Resultado da operação
        """
        try:
            query = self.client.table(table).delete()

            for key, value in filters.items():
                query = query.eq(key, value)

            result = query.execute()
            app_logger.info(f"✓ Registros deletados de '{table}'")
            return result

        except Exception as e:
            app_logger.error(f"Erro ao deletar de '{table}': {e}")
            raise

if __name__ == '__main__':
    # Teste do cliente
    try:
        client = SupabaseClient()
        client.testar_conexao()

        # Testar count
        num_fundos = client.count('fundos')
        print(f"Fundos cadastrados: {num_fundos}")

    except Exception as e:
        print(f"Erro: {e}")
