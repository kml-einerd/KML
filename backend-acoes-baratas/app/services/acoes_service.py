"""
Serviço para operações relacionadas à tabela 'acoes'.
"""
from typing import List, Optional
from datetime import datetime
from app.supabase_client import obter_cliente_supabase
from app.models.schemas import AcaoSchema


import logging

logger = logging.getLogger(__name__)

class AcoesService:
    """Serviço para gerenciar ações."""

    def __init__(self):
        self.supabase = obter_cliente_supabase()
        self.tabela = "acoes"

    def obter_todas_ativas(self) -> List[AcaoSchema]:
        """
        Retorna todas as ações ativas.

        Returns:
            List[AcaoSchema]: Lista de ações ativas
        """
        response = (
            self.supabase.table(self.tabela)
            .select("*")
            .eq("ativo", True)
            .execute()
        )
        return [AcaoSchema(**acao) for acao in response.data]

    def obter_por_ticker(self, ticker: str) -> Optional[AcaoSchema]:
        """
        Retorna uma ação específica pelo ticker.

        Args:
            ticker: Código do ticker (ex: PETR4.SA)

        Returns:
            Optional[AcaoSchema]: Ação encontrada ou None
        """
        response = (
            self.supabase.table(self.tabela)
            .select("*")
            .eq("ticker", ticker)
            .execute()
        )

        if response.data:
            return AcaoSchema(**response.data[0])
        return None

    def inserir_ou_atualizar(self, acao: AcaoSchema) -> Optional[AcaoSchema]:
        """
        Insere uma nova ação ou atualiza se já existe.

        Args:
            acao: Dados da ação

        Returns:
            AcaoSchema: Ação inserida/atualizada ou None em caso de erro
        """
        try:
            acao_dict = acao.model_dump(exclude_none=True)
            acao_dict["atualizado_em"] = datetime.utcnow().isoformat()

            response = (
                self.supabase.table(self.tabela)
                .upsert(acao_dict, on_conflict="ticker")
                .execute()
            )

            if response.data:
                return AcaoSchema(**response.data[0])
            
            logger.error(f"Erro ao salvar ação {acao.ticker}: Sem dados retornados. Response: {response}")
            return None

        except Exception as e:
            logger.exception(f"Exceção ao salvar ação {acao.ticker}: {e}")
            return None

    def inserir_varias(self, acoes: List[AcaoSchema]) -> List[AcaoSchema]:
        """
        Insere ou atualiza várias ações de uma vez.

        Args:
            acoes: Lista de ações

        Returns:
            List[AcaoSchema]: Lista de ações inseridas/atualizadas
        """
        if not acoes:
            return []

        try:
            acoes_dict = []
            for acao in acoes:
                acao_dict = acao.model_dump(exclude_none=True)
                acao_dict["atualizado_em"] = datetime.utcnow().isoformat()
                acoes_dict.append(acao_dict)

            logger.info(f"Tentando inserir/atualizar {len(acoes_dict)} registros na tabela '{self.tabela}'...")
            
            response = (
                self.supabase.table(self.tabela)
                .upsert(acoes_dict, on_conflict="ticker")
                .execute()
            )

            if response.data:
                logger.info(f"Sucesso! {len(response.data)} registros processados.")
                return [AcaoSchema(**acao) for acao in response.data]
            
            logger.error(f"Erro ao salvar em lote: Sem dados retornados. Response: {response}")
            return []

        except Exception as e:
            logger.exception(f"Exceção ao salvar em lote na tabela '{self.tabela}': {e}")
            return []

    def desativar(self, ticker: str) -> bool:
        """
        Marca uma ação como inativa.

        Args:
            ticker: Código do ticker

        Returns:
            bool: True se foi desativada com sucesso
        """
        response = (
            self.supabase.table(self.tabela)
            .update({"ativo": False, "atualizado_em": datetime.utcnow().isoformat()})
            .eq("ticker", ticker)
            .execute()
        )

        return len(response.data) > 0
