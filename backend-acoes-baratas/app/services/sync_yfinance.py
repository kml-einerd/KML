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
import pandas as pd
import time

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
            logger.debug(f"Obtendo info de {ticker}...")
            acao_yf = yf.Ticker(ticker)
            info = acao_yf.info

            # Verificar se info está vazio
            if not info or not isinstance(info, dict):
                logger.warning(f"Info vazio ou inválido para {ticker}")
                return None

            # Extrair código B3 (remover .SA)
            codigo_b3 = ticker.replace(".SA", "")

            # Obter nome - tentar várias fontes
            nome_curto = info.get("shortName") or info.get("symbol") or codigo_b3
            nome_longo = info.get("longName") or nome_curto

            return AcaoSchema(
                ticker=ticker,
                codigo_b3=codigo_b3,
                nome_curto=nome_curto,
                nome_longo=nome_longo,
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
            logger.error(f"Erro ao obter info de {ticker}: {type(e).__name__}: {e}")
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
            logger.debug(f"Obtendo cotação de {ticker}...")
            acao_yf = yf.Ticker(ticker)

            # Obter histórico do último dia para variação
            hist = acao_yf.history(period="2d")

            if hist is None or hist.empty:
                logger.warning(f"Histórico vazio para {ticker}")
                return None

            preco_anterior = None
            if len(hist) >= 2:
                close_val = hist.iloc[-2]["Close"]
                if pd.notna(close_val):
                    preco_anterior = float(close_val)

            # Tentar obter preço atual de várias fontes
            preco_ultimo = None
            if len(hist) > 0:
                close_val = hist.iloc[-1]["Close"]
                if pd.notna(close_val):
                    preco_ultimo = float(close_val)

            if not preco_ultimo:
                logger.warning(f"Não foi possível obter preço para {ticker}")
                return None

            # Calcular variação
            variacao_dia = None
            variacao_dia_percentual = None
            if preco_anterior and preco_anterior > 0:
                variacao_dia = preco_ultimo - preco_anterior
                variacao_dia_percentual = (variacao_dia / preco_anterior) * 100

            # Obter info adicionais (pode falhar, mas não é crítico)
            info = {}
            try:
                info = acao_yf.info or {}
            except:
                pass

            # Extrair valores com segurança
            def safe_get(d, key, default=None):
                val = d.get(key, default)
                return val if val is not None and (not isinstance(val, float) or pd.notna(val)) else None

            return CotacaoSnapshotSchema(
                ticker=ticker,
                coletado_em=datetime.utcnow(),
                preco_ultimo=preco_ultimo,
                preco_anterior=preco_anterior,
                variacao_dia=variacao_dia,
                variacao_dia_percentual=variacao_dia_percentual,
                maximo_dia=safe_get(info, "dayHigh") or (float(hist.iloc[-1]["High"]) if pd.notna(hist.iloc[-1]["High"]) else None),
                minimo_dia=safe_get(info, "dayLow") or (float(hist.iloc[-1]["Low"]) if pd.notna(hist.iloc[-1]["Low"]) else None),
                volume=safe_get(info, "volume") or (float(hist.iloc[-1]["Volume"]) if pd.notna(hist.iloc[-1]["Volume"]) else None),
                valor_mercado=safe_get(info, "marketCap"),
                pl_trailing=safe_get(info, "trailingPE"),
                pl_forward=safe_get(info, "forwardPE"),
                preco_valor_patrimonial=safe_get(info, "priceToBook"),
                dividend_yield=safe_get(info, "dividendYield"),
                payout_ratio=safe_get(info, "payoutRatio"),
                beta=safe_get(info, "beta"),
            )
        except Exception as e:
            logger.error(f"Erro ao obter cotação de {ticker}: {type(e).__name__}: {e}")
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
            logger.debug(f"Obtendo histórico de {ticker} de {data_inicio} até {data_fim}...")
            acao_yf = yf.Ticker(ticker)
            hist = acao_yf.history(start=data_inicio, end=data_fim)

            if hist is None or hist.empty:
                logger.warning(f"Histórico vazio para {ticker} no período")
                return []

            precos = []
            for data_idx, row in hist.iterrows():
                # Função auxiliar para converter valores
                def safe_float(val):
                    if pd.notna(val) and val is not None:
                        try:
                            return float(val)
                        except:
                            return None
                    return None

                preco = PrecoDiarioSchema(
                    ticker=ticker,
                    data=data_idx.date(),
                    abertura=safe_float(row["Open"]),
                    maxima=safe_float(row["High"]),
                    minima=safe_float(row["Low"]),
                    fechamento=safe_float(row["Close"]),
                    fechamento_ajustado=safe_float(row["Close"]),
                    volume=safe_float(row["Volume"]),
                )
                precos.append(preco)

            logger.debug(f"Obtidos {len(precos)} dias de histórico para {ticker}")
            return precos
        except Exception as e:
            logger.error(f"Erro ao obter histórico de {ticker}: {type(e).__name__}: {e}")
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
            logger.debug(f"Obtendo fundamentos de {ticker}...")
            acao_yf = yf.Ticker(ticker)

            # Obter info - pode falhar ou estar vazio
            info = {}
            try:
                info = acao_yf.info or {}
            except Exception as e:
                logger.warning(f"Erro ao obter info para {ticker}: {e}")

            if not info or not isinstance(info, dict):
                logger.warning(f"Info vazio ou inválido para {ticker}")
                # Mesmo assim continua, pode ter dados do histórico

            # Tentar obter dados financeiros (pode não estar disponível para todas as ações)
            crescimento_receita = None
            crescimento_lucro = None

            try:
                # Usar income_stmt ao invés de financials (API atualizada)
                income_stmt = acao_yf.income_stmt
                if income_stmt is not None and not income_stmt.empty:
                    # Tentar obter receita (Total Revenue)
                    if "Total Revenue" in income_stmt.index:
                        receitas = income_stmt.loc["Total Revenue"]
                        if len(receitas) >= 2:
                            receita_atual = receitas.iloc[0]
                            receita_anterior = receitas.iloc[1]
                            if pd.notna(receita_atual) and pd.notna(receita_anterior) and receita_anterior != 0:
                                crescimento_receita = float((receita_atual - receita_anterior) / receita_anterior)
            except Exception as e:
                logger.debug(f"Não foi possível calcular crescimento de receita para {ticker}: {e}")

            # Função auxiliar para extrair valores com segurança
            def safe_get(d, key, default=None):
                val = d.get(key, default)
                if val is None:
                    return None
                if isinstance(val, (int, float)):
                    return float(val) if pd.notna(val) else None
                return val

            return FundamentosSnapshotSchema(
                ticker=ticker,
                coletado_em=datetime.utcnow(),
                pl_trailing=safe_get(info, "trailingPE"),
                pl_forward=safe_get(info, "forwardPE"),
                preco_valor_patrimonial=safe_get(info, "priceToBook"),
                dividend_yield=safe_get(info, "dividendYield"),
                roe=safe_get(info, "returnOnEquity"),
                roa=safe_get(info, "returnOnAssets"),
                margem_liquida=safe_get(info, "profitMargins"),
                margem_operacional=safe_get(info, "operatingMargins"),
                margem_bruta=safe_get(info, "grossMargins"),
                divida_patrimonio=safe_get(info, "debtToEquity"),
                liquidez_corrente=safe_get(info, "currentRatio"),
                crescimento_receita_12m=crescimento_receita,
                crescimento_lucro_12m=crescimento_lucro,
                raw_info=info if info else {},
                raw_outros={},
            )
        except Exception as e:
            logger.error(f"Erro ao obter fundamentos de {ticker}: {type(e).__name__}: {e}")
            return None
