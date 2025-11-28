"""
Serviço para sincronização de dados usando yfinance.
Busca dados de ações da B3 (Bolsa brasileira).
"""
import yfinance as yf
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


class YFinanceSync:
    """Serviço para sincronização de dados via yfinance."""

    def __init__(self):
        self.regiao = "br"
        self.bolsa = "SAO"

    def obter_tickers_b3(self) -> List[str]:
        """
        Retorna lista de tickers da B3.

        Nota: yfinance.screen() pode não estar disponível em todas as versões.
        Como alternativa, usamos uma lista conhecida de tickers populares da B3.

        Returns:
            List[str]: Lista de tickers no formato Yahoo (ex: PETR4.SA)
        """
        # Lista de tickers populares da B3
        # Em produção, você pode usar uma fonte externa ou API específica
        tickers_conhecidos = [
            # Petróleo e Gás
            "PETR3.SA", "PETR4.SA", "PRIO3.SA", "RRRP3.SA",
            # Mineração
            "VALE3.SA",
            # Bancos
            "ITUB4.SA", "BBDC4.SA", "BBAS3.SA", "SANB11.SA", "BBSE3.SA",
            # Energia Elétrica
            "ELET3.SA", "ELET6.SA", "TAEE11.SA", "CMIG4.SA",
            # Varejo
            "MGLU3.SA", "LREN3.SA", "ARZZ3.SA", "BHIA3.SA",
            # Alimentação
            "ABEV3.SA", "JBSS3.SA", "BEEF3.SA",
            # Telecomunicações
            "VIVT3.SA", "TIMS3.SA",
            # Siderurgia
            "CSNA3.SA", "GGBR4.SA", "USIM5.SA",
            # Papel e Celulose
            "SUZB3.SA", "KLBN11.SA",
            # Construção
            "MRVE3.SA", "CYRE3.SA",
            # Saúde
            "RADL3.SA", "HAPV3.SA", "FLRY3.SA",
            # Tecnologia
            "TOTS3.SA", "LWSA3.SA",
            # Logística
            "RAIL3.SA",
            # Outros
            "WEGE3.SA", "EMBR3.SA", "AZUL4.SA", "GOAU4.SA",
            "RENT3.SA", "CSAN3.SA", "UGPA3.SA", "BRFS3.SA",
            "EQTL3.SA", "CPFE3.SA", "ENBR3.SA", "CPLE6.SA",
            "BBDC3.SA", "ITSA4.SA", "B3SA3.SA", "BPAC11.SA",
        ]

        logger.info(f"Total de tickers conhecidos da B3: {len(tickers_conhecidos)}")
        return tickers_conhecidos

    def obter_info_acao(self, ticker: str) -> Optional[AcaoSchema]:
        """
        Obtém informações básicas de uma ação.

        Args:
            ticker: Código do ticker (ex: PETR4.SA)

        Returns:
            Optional[AcaoSchema]: Dados da ação ou None se houver erro
        """
        try:
            acao_yf = yf.Ticker(ticker)
            info = acao_yf.info

            # Extrair código B3 (remover .SA)
            codigo_b3 = ticker.replace(".SA", "")

            return AcaoSchema(
                ticker=ticker,
                codigo_b3=codigo_b3,
                nome_curto=info.get("shortName", ""),
                nome_longo=info.get("longName", ""),
                bolsa=info.get("exchange", self.bolsa),
                regiao=info.get("region", self.regiao),
                moeda=info.get("currency", "BRL"),
                setor=info.get("sector", ""),
                industria=info.get("industry", ""),
                site=info.get("website", ""),
                descricao_longa=info.get("longBusinessSummary", ""),
                ativo=True,
            )
        except Exception as e:
            logger.error(f"Erro ao obter info de {ticker}: {e}")
            return None

    def obter_cotacao_atual(self, ticker: str) -> Optional[CotacaoSnapshotSchema]:
        """
        Obtém cotação atual de uma ação.

        Args:
            ticker: Código do ticker

        Returns:
            Optional[CotacaoSnapshotSchema]: Cotação atual ou None
        """
        try:
            acao_yf = yf.Ticker(ticker)
            info = acao_yf.info

            # Obter histórico do último dia para variação
            hist = acao_yf.history(period="2d")

            preco_anterior = None
            if len(hist) >= 2:
                preco_anterior = float(hist.iloc[-2]["Close"])

            preco_ultimo = info.get("currentPrice") or info.get("regularMarketPrice")
            if not preco_ultimo and len(hist) > 0:
                preco_ultimo = float(hist.iloc[-1]["Close"])

            if not preco_ultimo:
                return None

            # Calcular variação
            variacao_dia = None
            variacao_dia_percentual = None
            if preco_anterior:
                variacao_dia = preco_ultimo - preco_anterior
                variacao_dia_percentual = (variacao_dia / preco_anterior) * 100

            return CotacaoSnapshotSchema(
                ticker=ticker,
                coletado_em=datetime.utcnow(),
                preco_ultimo=preco_ultimo,
                preco_anterior=preco_anterior,
                variacao_dia=variacao_dia,
                variacao_dia_percentual=variacao_dia_percentual,
                maximo_dia=info.get("dayHigh"),
                minimo_dia=info.get("dayLow"),
                volume=info.get("volume"),
                valor_mercado=info.get("marketCap"),
                pl_trailing=info.get("trailingPE"),
                pl_forward=info.get("forwardPE"),
                preco_valor_patrimonial=info.get("priceToBook"),
                dividend_yield=info.get("dividendYield"),
                payout_ratio=info.get("payoutRatio"),
                beta=info.get("beta"),
            )
        except Exception as e:
            logger.error(f"Erro ao obter cotação de {ticker}: {e}")
            return None

    def obter_historico_precos(
        self, ticker: str, data_inicio: date, data_fim: date
    ) -> List[PrecoDiarioSchema]:
        """
        Obtém histórico de preços de uma ação.

        Args:
            ticker: Código do ticker
            data_inicio: Data inicial
            data_fim: Data final

        Returns:
            List[PrecoDiarioSchema]: Lista de preços diários
        """
        try:
            acao_yf = yf.Ticker(ticker)
            hist = acao_yf.history(start=data_inicio, end=data_fim)

            precos = []
            for data_idx, row in hist.iterrows():
                preco = PrecoDiarioSchema(
                    ticker=ticker,
                    data=data_idx.date(),
                    abertura=float(row["Open"]) if row["Open"] else None,
                    maxima=float(row["High"]) if row["High"] else None,
                    minima=float(row["Low"]) if row["Low"] else None,
                    fechamento=float(row["Close"]) if row["Close"] else None,
                    fechamento_ajustado=float(row["Close"]) if row["Close"] else None,
                    volume=float(row["Volume"]) if row["Volume"] else None,
                )
                precos.append(preco)

            return precos
        except Exception as e:
            logger.error(f"Erro ao obter histórico de {ticker}: {e}")
            return []

    def obter_fundamentos(self, ticker: str) -> Optional[FundamentosSnapshotSchema]:
        """
        Obtém fundamentos de uma ação e calcula scores.

        Args:
            ticker: Código do ticker

        Returns:
            Optional[FundamentosSnapshotSchema]: Fundamentos ou None
        """
        try:
            acao_yf = yf.Ticker(ticker)
            info = acao_yf.info

            # Obter dados financeiros
            financials = acao_yf.financials
            balance_sheet = acao_yf.balance_sheet

            # Calcular crescimentos (simplificado)
            crescimento_receita = None
            crescimento_lucro = None

            if financials is not None and not financials.empty:
                try:
                    # Tentar obter receita (Total Revenue)
                    if "Total Revenue" in financials.index:
                        receitas = financials.loc["Total Revenue"]
                        if len(receitas) >= 2:
                            receita_atual = receitas.iloc[0]
                            receita_anterior = receitas.iloc[1]
                            if receita_anterior != 0:
                                crescimento_receita = (
                                    receita_atual - receita_anterior
                                ) / receita_anterior
                except Exception:
                    pass

            return FundamentosSnapshotSchema(
                ticker=ticker,
                coletado_em=datetime.utcnow(),
                pl_trailing=info.get("trailingPE"),
                pl_forward=info.get("forwardPE"),
                preco_valor_patrimonial=info.get("priceToBook"),
                dividend_yield=info.get("dividendYield"),
                roe=info.get("returnOnEquity"),
                roa=info.get("returnOnAssets"),
                margem_liquida=info.get("profitMargins"),
                margem_operacional=info.get("operatingMargins"),
                margem_bruta=info.get("grossMargins"),
                divida_patrimonio=info.get("debtToEquity"),
                liquidez_corrente=info.get("currentRatio"),
                crescimento_receita_12m=crescimento_receita,
                crescimento_lucro_12m=crescimento_lucro,
                raw_info=info,
                raw_outros={},
            )
        except Exception as e:
            logger.error(f"Erro ao obter fundamentos de {ticker}: {e}")
            return None
