"""
Serviço para operações relacionadas à tabela 'acoes_info'.
Gerencia informações extras das empresas obtidas via yfinance.
"""
from typing import List, Optional
from datetime import datetime
import logging
import yfinance as yf

from app.supabase_client import obter_cliente_supabase
from app.models.schemas import AcaoInfoSchema

logger = logging.getLogger(__name__)


class AcoesInfoService:
    """Serviço para gerenciar informações extras das ações."""

    def __init__(self):
        self.supabase = obter_cliente_supabase()
        self.tabela = "acoes_info"

    def obter_info_yfinance(self, ticker: str, symbol: str) -> Optional[AcaoInfoSchema]:
        """
        Busca informações extras de uma ação usando yfinance.

        Args:
            ticker: Código do ticker da B3 (ex: PETR4)
            symbol: Symbol do yfinance (ex: PETR4.SA)

        Returns:
            Optional[AcaoInfoSchema]: Informações extras ou None em caso de erro
        """
        try:
            logger.info(f"Buscando informações do yfinance para {ticker} ({symbol})...")

            # Criar objeto do yfinance
            stock = yf.Ticker(symbol)
            info = stock.info

            # Verificar se conseguiu dados
            if not info or len(info) == 0:
                logger.warning(f"Nenhuma informação encontrada para {symbol}")
                return None

            # Extrair informações fixas da empresa
            acao_info = AcaoInfoSchema(
                ticker=ticker,
                symbol=symbol,

                # Informações Básicas
                nome_longo=info.get("longName"),
                nome_curto=info.get("shortName"),
                descricao=info.get("longBusinessSummary"),

                # Localização e Contato
                pais=info.get("country"),
                estado=info.get("state"),
                cidade=info.get("city"),
                endereco=info.get("address1"),
                cep=info.get("zip"),
                telefone=info.get("phone"),
                website=info.get("website"),

                # Classificação
                setor=info.get("sector"),
                industria=info.get("industry"),
                industria_chave=info.get("industryKey"),

                # Informações Corporativas
                numero_funcionarios=info.get("fullTimeEmployees"),

                # Informações de Mercado
                moeda=info.get("currency"),
                exchange=info.get("exchange"),
                tipo_ativo=info.get("quoteType"),

                # Informações Fiscais
                ano_fiscal_termina=info.get("lastFiscalYearEnd"),
                proximo_ano_fiscal=info.get("nextFiscalYearEnd"),

                # Governança
                auditoria_risco=info.get("auditRisk"),
                conselho_risco=info.get("boardRisk"),
                compensacao_risco=info.get("compensationRisk"),
                shareholders_risco=info.get("shareHolderRightsRisk"),
                risco_geral=info.get("overallRisk"),
            )

            logger.info(f"✓ Informações coletadas para {ticker}")
            return acao_info

        except Exception as e:
            logger.error(f"Erro ao buscar informações do yfinance para {ticker} ({symbol}): {e}")
            return None

    def inserir_ou_atualizar(self, acao_info: AcaoInfoSchema) -> Optional[AcaoInfoSchema]:
        """
        Insere novas informações ou atualiza se já existem.

        Args:
            acao_info: Dados das informações extras

        Returns:
            AcaoInfoSchema: Informações inseridas/atualizadas ou None em caso de erro
        """
        try:
            acao_dict = acao_info.model_dump(exclude_none=True)
            acao_dict["atualizado_em"] = datetime.utcnow().isoformat()

            response = (
                self.supabase.table(self.tabela)
                .upsert(acao_dict, on_conflict="ticker")
                .execute()
            )

            if response.data:
                logger.info(f"✓ Informações extras salvas para {acao_info.ticker}")
                return AcaoInfoSchema(**response.data[0])

            logger.error(f"Erro ao salvar informações extras de {acao_info.ticker}: Sem dados retornados")
            return None

        except Exception as e:
            logger.exception(f"Exceção ao salvar informações extras de {acao_info.ticker}: {e}")
            return None

    def inserir_varias(self, acoes_info: List[AcaoInfoSchema]) -> List[AcaoInfoSchema]:
        """
        Insere ou atualiza várias informações de uma vez.

        Args:
            acoes_info: Lista de informações extras

        Returns:
            List[AcaoInfoSchema]: Lista de informações inseridas/atualizadas
        """
        if not acoes_info:
            return []

        try:
            acoes_dict = []
            for info in acoes_info:
                info_dict = info.model_dump(exclude_none=True)
                info_dict["atualizado_em"] = datetime.utcnow().isoformat()
                acoes_dict.append(info_dict)

            logger.info(f"Tentando inserir/atualizar {len(acoes_dict)} registros na tabela '{self.tabela}'...")

            response = (
                self.supabase.table(self.tabela)
                .upsert(acoes_dict, on_conflict="ticker")
                .execute()
            )

            if response.data:
                logger.info(f"✓ {len(response.data)} informações extras salvas com sucesso!")
                return [AcaoInfoSchema(**info) for info in response.data]

            logger.error("Erro ao salvar em lote: Sem dados retornados")
            return []

        except Exception as e:
            logger.exception(f"Exceção ao salvar em lote na tabela '{self.tabela}': {e}")
            return []

    def obter_por_ticker(self, ticker: str) -> Optional[AcaoInfoSchema]:
        """
        Retorna informações extras de uma ação específica pelo ticker.

        Args:
            ticker: Código do ticker (ex: PETR4)

        Returns:
            Optional[AcaoInfoSchema]: Informações encontradas ou None
        """
        response = (
            self.supabase.table(self.tabela)
            .select("*")
            .eq("ticker", ticker)
            .execute()
        )

        if response.data:
            return AcaoInfoSchema(**response.data[0])
        return None
