"""
Serviço para operações relacionadas à tabela 'precos_diarios'.
"""
from typing import List, Optional
from datetime import date, datetime, timedelta
from app.supabase_client import obter_cliente_supabase
from app.models.schemas import PrecoDiarioSchema
import numpy as np


class PrecosService:
    """Serviço para gerenciar preços diários."""

    def __init__(self):
        self.supabase = obter_cliente_supabase()
        self.tabela = "precos_diarios"

    def obter_por_periodo(
        self, ticker: str, data_inicio: date, data_fim: date
    ) -> List[PrecoDiarioSchema]:
        """
        Retorna preços diários de um ticker em um período.

        Args:
            ticker: Código do ticker
            data_inicio: Data inicial
            data_fim: Data final

        Returns:
            List[PrecoDiarioSchema]: Lista de preços diários
        """
        response = (
            self.supabase.table(self.tabela)
            .select("*")
            .eq("ticker", ticker)
            .gte("data", data_inicio.isoformat())
            .lte("data", data_fim.isoformat())
            .order("data", desc=False)
            .execute()
        )

        return [PrecoDiarioSchema(**preco) for preco in response.data]

    def obter_ultimos_dias(self, ticker: str, dias: int) -> List[PrecoDiarioSchema]:
        """
        Retorna os últimos N dias de preços de um ticker.

        Args:
            ticker: Código do ticker
            dias: Número de dias

        Returns:
            List[PrecoDiarioSchema]: Lista de preços diários
        """
        data_fim = date.today()
        data_inicio = data_fim - timedelta(days=dias)

        return self.obter_por_periodo(ticker, data_inicio, data_fim)

    def obter_ultima_data_disponivel(self, ticker: str) -> Optional[date]:
        """
        Retorna a última data com preço disponível para um ticker.

        Args:
            ticker: Código do ticker

        Returns:
            Optional[date]: Última data ou None
        """
        response = (
            self.supabase.table(self.tabela)
            .select("data")
            .eq("ticker", ticker)
            .order("data", desc=True)
            .limit(1)
            .execute()
        )

        if response.data:
            return datetime.fromisoformat(response.data[0]["data"]).date()
        return None

    def inserir_ou_atualizar(self, preco: PrecoDiarioSchema) -> PrecoDiarioSchema:
        """
        Insere um novo preço ou atualiza se já existe.

        Args:
            preco: Dados do preço diário

        Returns:
            PrecoDiarioSchema: Preço inserido/atualizado
        """
        preco_dict = preco.model_dump(exclude_none=True)

        # Converter date para string ISO
        if isinstance(preco_dict.get("data"), date):
            preco_dict["data"] = preco_dict["data"].isoformat()

        response = (
            self.supabase.table(self.tabela)
            .upsert(preco_dict, on_conflict="ticker,data")
            .execute()
        )

        return PrecoDiarioSchema(**response.data[0])

    def inserir_varios(self, precos: List[PrecoDiarioSchema]) -> List[PrecoDiarioSchema]:
        """
        Insere ou atualiza vários preços de uma vez.

        Args:
            precos: Lista de preços

        Returns:
            List[PrecoDiarioSchema]: Lista de preços inseridos/atualizados
        """
        precos_dict = []
        for preco in precos:
            preco_dict = preco.model_dump(exclude_none=True)
            # Converter date para string ISO
            if isinstance(preco_dict.get("data"), date):
                preco_dict["data"] = preco_dict["data"].isoformat()
            precos_dict.append(preco_dict)

        if not precos_dict:
            return []

        response = (
            self.supabase.table(self.tabela)
            .upsert(precos_dict, on_conflict="ticker,data")
            .execute()
        )

        return [PrecoDiarioSchema(**preco) for preco in response.data]

    def calcular_metricas_periodo(
        self, ticker: str, periodo: str
    ) -> dict:
        """
        Calcula métricas de retorno e volatilidade para um período.

        Args:
            ticker: Código do ticker
            periodo: Período no formato '7d', '1m', '3m', '6m', '1a', '3a', '5a'

        Returns:
            dict: Dicionário com métricas calculadas
        """
        # Mapear período para dias
        mapa_periodos = {
            "7d": 7,
            "15d": 15,
            "1m": 30,
            "3m": 90,
            "6m": 180,
            "1a": 365,
            "3a": 365 * 3,
            "5a": 365 * 5,
        }

        dias = mapa_periodos.get(periodo, 30)
        precos = self.obter_ultimos_dias(ticker, dias)

        if len(precos) < 2:
            return {
                "retorno_periodo": None,
                "volatilidade": None,
                "maxima_periodo": None,
                "minima_periodo": None,
            }

        # Extrair fechamentos ajustados
        fechamentos = [p.fechamento_ajustado or p.fechamento for p in precos if p.fechamento]

        if len(fechamentos) < 2:
            return {
                "retorno_periodo": None,
                "volatilidade": None,
                "maxima_periodo": None,
                "minima_periodo": None,
            }

        # Calcular retorno do período
        retorno_periodo = ((fechamentos[-1] - fechamentos[0]) / fechamentos[0]) * 100

        # Calcular retornos diários
        retornos_diarios = []
        for i in range(1, len(fechamentos)):
            retorno = ((fechamentos[i] - fechamentos[i - 1]) / fechamentos[i - 1]) * 100
            retornos_diarios.append(retorno)

        # Volatilidade (desvio padrão dos retornos diários)
        volatilidade = float(np.std(retornos_diarios)) if retornos_diarios else None

        return {
            "retorno_periodo": round(retorno_periodo, 2),
            "volatilidade": round(volatilidade, 2) if volatilidade else None,
            "maxima_periodo": max(fechamentos),
            "minima_periodo": min(fechamentos),
        }
