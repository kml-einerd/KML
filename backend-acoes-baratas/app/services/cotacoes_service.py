"""
Serviço para operações relacionadas à tabela 'cotacoes_snapshot'.
"""
from typing import List, Optional
from datetime import datetime
from app.supabase_client import obter_cliente_supabase
from app.models.schemas import CotacaoSnapshotSchema


class CotacoesService:
    """Serviço para gerenciar snapshots de cotações."""

    def __init__(self):
        self.supabase = obter_cliente_supabase()
        self.tabela = "cotacoes_snapshot"

    def obter_ultima_por_ticker(self, ticker: str) -> Optional[CotacaoSnapshotSchema]:
        """
        Retorna o snapshot de cotação mais recente para um ticker.

        Args:
            ticker: Código do ticker

        Returns:
            Optional[CotacaoSnapshotSchema]: Última cotação ou None
        """
        response = (
            self.supabase.table(self.tabela)
            .select("*")
            .eq("ticker", ticker)
            .order("coletado_em", desc=True)
            .limit(1)
            .execute()
        )

        if response.data:
            return CotacaoSnapshotSchema(**response.data[0])
        return None

    def obter_ultimas_todas_acoes(self) -> List[dict]:
        """
        Retorna as cotações mais recentes de todas as ações.
        Usa SQL para buscar apenas o snapshot mais recente de cada ticker.

        Returns:
            List[dict]: Lista de cotações mais recentes
        """
        # Usando RPC ou query otimizada
        # Para simplificar, vamos buscar todas e filtrar no Python
        # Em produção, considere criar uma view materializada no Supabase
        response = (
            self.supabase.table(self.tabela)
            .select("*")
            .order("ticker,coletado_em", desc=True)
            .execute()
        )

        # Filtrar apenas a mais recente de cada ticker
        ultimas = {}
        for cotacao in response.data:
            ticker = cotacao["ticker"]
            if ticker not in ultimas:
                ultimas[ticker] = CotacaoSnapshotSchema(**cotacao)

        return list(ultimas.values())

    def inserir(self, cotacao: CotacaoSnapshotSchema) -> CotacaoSnapshotSchema:
        """
        Insere um novo snapshot de cotação.

        Args:
            cotacao: Dados da cotação

        Returns:
            CotacaoSnapshotSchema: Cotação inserida
        """
        cotacao_dict = cotacao.model_dump(exclude_none=True, exclude={"id"})
        
        # Converter datetime para ISO string
        if "timestamp" in cotacao_dict and isinstance(cotacao_dict["timestamp"], datetime):
            cotacao_dict["timestamp"] = cotacao_dict["timestamp"].isoformat()

        # Converter campos BIGINT que podem vir como float da API
        if "volume" in cotacao_dict and cotacao_dict["volume"] is not None:
            cotacao_dict["volume"] = int(cotacao_dict["volume"])
            
        if "market_cap" in cotacao_dict and cotacao_dict["market_cap"] is not None:
            cotacao_dict["market_cap"] = int(cotacao_dict["market_cap"])

        response = self.supabase.table(self.tabela).insert(cotacao_dict).execute()

        return CotacaoSnapshotSchema(**response.data[0])

    def inserir_varios(self, cotacoes: List[CotacaoSnapshotSchema]) -> List[CotacaoSnapshotSchema]:
        """
        Insere vários snapshots de cotação de uma vez.

        Args:
            cotacoes: Lista de cotações

        Returns:
            List[CotacaoSnapshotSchema]: Lista de cotações inseridas
        """
        cotacoes_dict = []
        for cotacao in cotacoes:
            cotacao_dict = cotacao.model_dump(exclude_none=True, exclude={"id"})
            
            # Converter datetime para ISO string
            if "timestamp" in cotacao_dict and isinstance(cotacao_dict["timestamp"], datetime):
                cotacao_dict["timestamp"] = cotacao_dict["timestamp"].isoformat()

            # Converter campos BIGINT que podem vir como float da API
            if "volume" in cotacao_dict and cotacao_dict["volume"] is not None:
                cotacao_dict["volume"] = int(cotacao_dict["volume"])
                
            if "market_cap" in cotacao_dict and cotacao_dict["market_cap"] is not None:
                cotacao_dict["market_cap"] = int(cotacao_dict["market_cap"])
            
            cotacoes_dict.append(cotacao_dict)

        if not cotacoes_dict:
            return []

        response = self.supabase.table(self.tabela).insert(cotacoes_dict).execute()

        return [CotacaoSnapshotSchema(**cotacao) for cotacao in response.data]

    def obter_acoes_baratas(self, preco_maximo: float = 101.0) -> List[dict]:
        """
        Retorna ações com preço abaixo do valor especificado.
        Junta cotações com dados da empresa e fundamentos.

        Args:
            preco_maximo: Preço máximo para filtrar (default: 101.0)

        Returns:
            List[dict]: Lista de ações baratas com dados combinados
        """
        # Buscar últimas cotações baratas
        ultimas_cotacoes = self.obter_ultimas_todas_acoes()

        # Filtrar por preço
        acoes_baratas = [
            cotacao
            for cotacao in ultimas_cotacoes
            if cotacao.preco_ultimo and cotacao.preco_ultimo < preco_maximo
        ]

        return acoes_baratas
