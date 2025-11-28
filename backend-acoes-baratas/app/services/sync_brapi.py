"""
Serviço para sincronização de dados usando brapi.dev API.
API brasileira para dados da B3 (Bolsa brasileira).
"""
import httpx
from typing import List, Optional
from datetime import datetime, date, timedelta
from app.models.schemas import (
    AcaoSchema,
    CotacaoSnapshotSchema,
    PrecoDiarioSchema,
    FundamentosSnapshotSchema,
)
import logging

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)


class BrapiSync:
    """Serviço para sincronização de dados via brapi.dev API."""

    def __init__(self, api_key: str):
        self.api_key = api_key
        self.base_url = "https://brapi.dev/api"
        self.headers = {
            "Authorization": f"Bearer {api_key}",
            "Content-Type": "application/json"
        }

    def _fazer_requisicao(self, endpoint: str, params: dict = None) -> Optional[dict]:
        """
        Faz requisição para a API brapi.dev.

        Args:
            endpoint: Endpoint da API (ex: /quote/list)
            params: Parâmetros da query string

        Returns:
            Dict com resposta da API ou None em caso de erro
        """
        url = f"{self.base_url}{endpoint}"

        try:
            response = httpx.get(url, headers=self.headers, params=params, timeout=30.0)
            response.raise_for_status()
            return response.json()

        except httpx.HTTPStatusError as e:
            logger.error(f"Erro HTTP {e.response.status_code} ao acessar {endpoint}: {e}")
            return None
        except Exception as e:
            logger.error(f"Erro ao fazer requisição para {endpoint}: {type(e).__name__}: {e}")
            return None

    def obter_tickers_disponiveis(self) -> List[str]:
        """
        Retorna lista de tickers disponíveis na B3.

        Returns:
            List[str]: Lista de tickers (ex: ['PETR4', 'VALE3', ...])
        """
        logger.info("Buscando lista de tickers disponíveis na brapi.dev...")

        data = self._fazer_requisicao("/quote/list")

        if not data or "stocks" not in data:
            logger.error(f"Não foi possível obter lista de tickers. Resposta da API: {data}")
            return []

        tickers = []
        for item in data["stocks"]:
            if isinstance(item, dict):
                ticker = item.get("stock")
            else:
                ticker = str(item)
            
            if ticker:
                tickers.append(ticker)

        logger.info(f"Total de tickers disponíveis: {len(tickers)}")
        
        # Logar primeiros 5 tickers para debug
        if tickers:
            logger.debug(f"Exemplos de tickers: {tickers[:5]}")

        return tickers

    def obter_info_acao(self, ticker: str) -> Optional[AcaoSchema]:
        """
        Obtém informações básicas de uma ação.

        Args:
            ticker: Código da ação (ex: PETR4)

        Returns:
            AcaoSchema com dados da ação ou None
        """
        logger.debug(f"Buscando informações de {ticker}...")

        data = self._fazer_requisicao(f"/quote/{ticker}", params={"modules": "summaryProfile"})

        if not data or "results" not in data or not data["results"]:
            logger.warning(f"Nenhum dado retornado para {ticker}. Resposta: {data}")
            return None

        try:
            result = data["results"][0]
            
            # Logar dados brutos para debug se necessário
            # logger.debug(f"Dados brutos de {ticker}: {result}")

            return AcaoSchema(
                ticker=ticker,
                symbol=result.get("symbol", ticker),
                nome_curto=result.get("shortName"),
                nome_longo=result.get("longName"),
                setor=result.get("sector"),
                industria=result.get("industry"),
                moeda=result.get("currency", "BRL"),
                logo_url=result.get("logourl"),
                ativo=True,
            )

        except Exception as e:
            logger.error(f"Erro ao processar dados de {ticker}: {type(e).__name__}: {e}")
            return None

    def obter_cotacao_atual(self, ticker: str) -> Optional[CotacaoSnapshotSchema]:
        """
        Obtém cotação atual de uma ação.

        Args:
            ticker: Código da ação (ex: PETR4)

        Returns:
            CotacaoSnapshotSchema com cotação atual ou None
        """
        logger.debug(f"Buscando cotação de {ticker}...")

        data = self._fazer_requisicao(f"/quote/{ticker}")

        if not data or "results" not in data or not data["results"]:
            logger.warning(f"Nenhuma cotação retornada para {ticker}")
            return None

        try:
            result = data["results"][0]

            return CotacaoSnapshotSchema(
                ticker=ticker,
                preco_atual=result.get("regularMarketPrice"),
                preco_abertura=result.get("regularMarketOpen"),
                preco_maximo_dia=result.get("regularMarketDayHigh"),
                preco_minimo_dia=result.get("regularMarketDayLow"),
                preco_fechamento_anterior=result.get("regularMarketPreviousClose"),
                variacao_dia=result.get("regularMarketChange"),
                variacao_dia_percentual=result.get("regularMarketChangePercent"),
                volume=result.get("regularMarketVolume"),
                volume_medio=result.get("averageDailyVolume10Day"),
                market_cap=result.get("marketCap"),
                preco_maximo_52_semanas=result.get("fiftyTwoWeekHigh"),
                preco_minimo_52_semanas=result.get("fiftyTwoWeekLow"),
                timestamp=datetime.now(),
            )

        except Exception as e:
            logger.error(f"Erro ao processar cotação de {ticker}: {type(e).__name__}: {e}")
            return None

    def obter_historico_precos(
        self, ticker: str, data_inicio: date, data_fim: date
    ) -> List[PrecoDiarioSchema]:
        """
        Obtém histórico de preços de uma ação.

        Args:
            ticker: Código da ação
            data_inicio: Data inicial
            data_fim: Data final

        Returns:
            Lista de PrecoDiarioSchema com histórico
        """
        logger.debug(f"Buscando histórico de {ticker} de {data_inicio} até {data_fim}...")

        # Calcular range em dias
        dias = (data_fim - data_inicio).days

        # Determinar parâmetro de range
        if dias <= 7:
            range_param = "1mo"
        elif dias <= 90:
            range_param = "3mo"
        elif dias <= 180:
            range_param = "6mo"
        else:
            range_param = "1y"

        data = self._fazer_requisicao(
            f"/quote/{ticker}",
            params={"range": range_param, "interval": "1d"}
        )

        if not data or "results" not in data or not data["results"]:
            logger.warning(f"Nenhum histórico retornado para {ticker}")
            return []

        try:
            result = data["results"][0]

            if "historicalDataPrice" not in result:
                logger.warning(f"Sem dados históricos para {ticker}")
                return []

            precos = []
            for item in result["historicalDataPrice"]:
                data_preco = datetime.fromtimestamp(item["date"]).date()

                # Filtrar apenas datas dentro do intervalo solicitado
                if data_inicio <= data_preco <= data_fim:
                    precos.append(
                        PrecoDiarioSchema(
                            ticker=ticker,
                            data=data_preco,
                            abertura=item.get("open"),
                            maxima=item.get("high"),
                            minima=item.get("low"),
                            fechamento=item.get("close"),
                            volume=item.get("volume"),
                            fechamento_ajustado=item.get("close"),  # brapi não fornece ajustado
                        )
                    )

            logger.debug(f"Encontrados {len(precos)} dias de histórico para {ticker}")
            return precos

        except Exception as e:
            logger.error(f"Erro ao processar histórico de {ticker}: {type(e).__name__}: {e}")
            return []

    def obter_fundamentos(self, ticker: str) -> Optional[FundamentosSnapshotSchema]:
        """
        Obtém dados fundamentalistas de uma ação.

        Args:
            ticker: Código da ação

        Returns:
            FundamentosSnapshotSchema com fundamentos ou None
        """
        logger.debug(f"Buscando fundamentos de {ticker}...")

        data = self._fazer_requisicao(
            f"/quote/{ticker}",
            params={"fundamental": "true", "modules": "summaryProfile"}
        )

        if not data or "results" not in data or not data["results"]:
            logger.warning(f"Nenhum fundamento retornado para {ticker}")
            return None

        try:
            result = data["results"][0]

            return FundamentosSnapshotSchema(
                ticker=ticker,
                nome_empresa=result.get("longName"),
                setor=result.get("sector"),
                industria=result.get("industry"),
                valor_mercado=result.get("marketCap"),
                valor_empresa=result.get("enterpriseValue"),
                preco_sobre_lucro=result.get("trailingPE"),
                preco_sobre_valor_patrimonial=result.get("priceToBook"),
                preco_sobre_vendas=result.get("priceToSalesTrailing12Months"),
                ev_sobre_receita=result.get("enterpriseToRevenue"),
                ev_sobre_ebitda=result.get("enterpriseToEbitda"),
                margem_lucro=result.get("profitMargins"),
                margem_bruta=result.get("grossMargins"),
                margem_ebitda=result.get("ebitdaMargins"),
                margem_operacional=result.get("operatingMargins"),
                roe=result.get("returnOnEquity"),
                roa=result.get("returnOnAssets"),
                receita_total=result.get("totalRevenue"),
                receita_por_acao=result.get("revenuePerShare"),
                lucro_bruto=result.get("grossProfits"),
                lucro_liquido=result.get("netIncome"),
                ebitda=result.get("ebitda"),
                lucro_por_acao=result.get("trailingEps"),
                crescimento_receita=result.get("revenueGrowth"),
                crescimento_lucro=result.get("earningsGrowth"),
                dividend_yield=result.get("dividendYield"),
                taxa_pagamento=result.get("payoutRatio"),
                beta=result.get("beta"),
                preco_alvo_medio=result.get("targetMeanPrice"),
                recomendacao=result.get("recommendationKey"),
                acoes_em_circulacao=result.get("sharesOutstanding"),
                data_referencia=date.today(),
            )

        except Exception as e:
            logger.error(f"Erro ao processar fundamentos de {ticker}: {type(e).__name__}: {e}")
            return None
