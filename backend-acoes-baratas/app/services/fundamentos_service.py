"""
Serviço para operações relacionadas à tabela 'fundamentos_snapshot'.
"""
from typing import List, Optional
from datetime import datetime
from app.supabase_client import obter_cliente_supabase
from app.models.schemas import FundamentosSnapshotSchema


class FundamentosService:
    """Serviço para gerenciar snapshots de fundamentos."""

    def __init__(self):
        self.supabase = obter_cliente_supabase()
        self.tabela = "fundamentos"

    def obter_ultimo_por_ticker(
        self, ticker: str
    ) -> Optional[FundamentosSnapshotSchema]:
        """
        Retorna o snapshot de fundamentos mais recente para um ticker.

        Args:
            ticker: Código do ticker

        Returns:
            Optional[FundamentosSnapshotSchema]: Últimos fundamentos ou None
        """
        response = (
            self.supabase.table(self.tabela)
            .select("*")
            .eq("ticker", ticker)
            .order("created_at", desc=True)
            .limit(1)
            .execute()
        )

        if response.data:
            return FundamentosSnapshotSchema(**response.data[0])
        return None

    def obter_ultimos_todos_tickers(self) -> dict:
        """
        Retorna os fundamentos mais recentes de todos os tickers.

        Returns:
            dict: Dicionário com ticker como chave e fundamentos como valor
        """
        response = (
            self.supabase.table(self.tabela)
            .select("*")
            .order("ticker,created_at", desc=True)
            .execute()
        )

        # Filtrar apenas o mais recente de cada ticker
        ultimos = {}
        for fundamento in response.data:
            ticker = fundamento["ticker"]
            if ticker not in ultimos:
                ultimos[ticker] = FundamentosSnapshotSchema(**fundamento)

        return ultimos

    def inserir(
        self, fundamentos: FundamentosSnapshotSchema
    ) -> FundamentosSnapshotSchema:
        """
        Insere um novo snapshot de fundamentos.

        Args:
            fundamentos: Dados dos fundamentos

        Returns:
            FundamentosSnapshotSchema: Fundamentos inseridos
        """
        fundamentos_dict = fundamentos.model_dump(exclude_none=True, exclude={"id"})

        response = self.supabase.table(self.tabela).insert(fundamentos_dict).execute()

        return FundamentosSnapshotSchema(**response.data[0])

    def inserir_varios(
        self, fundamentos_lista: List[FundamentosSnapshotSchema]
    ) -> List[FundamentosSnapshotSchema]:
        """
        Insere vários snapshots de fundamentos de uma vez.

        Args:
            fundamentos_lista: Lista de fundamentos

        Returns:
            List[FundamentosSnapshotSchema]: Lista de fundamentos inseridos
        """
        fundamentos_dict = [
            f.model_dump(exclude_none=True, exclude={"id"}) for f in fundamentos_lista
        ]

        if not fundamentos_dict:
            return []

        response = self.supabase.table(self.tabela).insert(fundamentos_dict).execute()

        return [FundamentosSnapshotSchema(**f) for f in response.data]

    def calcular_scores(
        self, fundamentos: FundamentosSnapshotSchema
    ) -> FundamentosSnapshotSchema:
        """
        Calcula scores de valuation, qualidade e momento.
        Scores vão de 0 a 100.

        Args:
            fundamentos: Fundamentos base

        Returns:
            FundamentosSnapshotSchema: Fundamentos com scores calculados
        """
        score_valuation = self._calcular_score_valuation(fundamentos)
        score_qualidade = self._calcular_score_qualidade(fundamentos)
        score_momento = self._calcular_score_momento(fundamentos)

        # Score geral é a média dos três
        scores_validos = [
            s for s in [score_valuation, score_qualidade, score_momento] if s is not None
        ]
        score_geral = sum(scores_validos) / len(scores_validos) if scores_validos else None

        fundamentos.score_valuation = score_valuation
        fundamentos.score_qualidade = score_qualidade
        fundamentos.score_momento = score_momento
        fundamentos.score_geral = score_geral

        return fundamentos

    def _calcular_score_valuation(
        self, fundamentos: FundamentosSnapshotSchema
    ) -> Optional[float]:
        """Calcula score de valuation (quanto menor P/L e P/VP, melhor)."""
        pontos = []

        # P/L Trailing (quanto menor, melhor)
        if fundamentos.pl_trailing and 0 < fundamentos.pl_trailing < 30:
            # Score inverso: P/L de 5 = score alto, P/L de 30 = score baixo
            pontos.append(max(0, 100 - (fundamentos.pl_trailing / 30) * 100))

        # P/VP (quanto menor, melhor)
        if fundamentos.preco_valor_patrimonial and fundamentos.preco_valor_patrimonial > 0:
            pvp = fundamentos.preco_valor_patrimonial
            if pvp < 3:
                pontos.append(max(0, 100 - (pvp / 3) * 100))

        # Dividend Yield (quanto maior, melhor)
        if fundamentos.dividend_yield and fundamentos.dividend_yield > 0:
            # DY de 10% = score 100, DY de 0% = score 0
            pontos.append(min(100, fundamentos.dividend_yield * 1000))

        return round(sum(pontos) / len(pontos), 2) if pontos else None

    def _calcular_score_qualidade(
        self, fundamentos: FundamentosSnapshotSchema
    ) -> Optional[float]:
        """Calcula score de qualidade (margens, ROE, etc)."""
        pontos = []

        # ROE (quanto maior, melhor)
        if fundamentos.roe and fundamentos.roe > 0:
            # ROE de 20% = score 100
            pontos.append(min(100, (fundamentos.roe * 100) / 20))

        # Margem Líquida
        if fundamentos.margem_liquida and fundamentos.margem_liquida > 0:
            # Margem de 20% = score 100
            pontos.append(min(100, (fundamentos.margem_liquida * 100) / 20))

        # Liquidez Corrente (ideal próximo de 1.5-2.0)
        if fundamentos.liquidez_corrente and fundamentos.liquidez_corrente > 0:
            lc = fundamentos.liquidez_corrente
            if 1.0 <= lc <= 3.0:
                # Ideal em 1.5-2.0
                if 1.5 <= lc <= 2.0:
                    pontos.append(100)
                else:
                    pontos.append(50)

        return round(sum(pontos) / len(pontos), 2) if pontos else None

    def _calcular_score_momento(
        self, fundamentos: FundamentosSnapshotSchema
    ) -> Optional[float]:
        """Calcula score de momento (crescimento de receita e lucro)."""
        pontos = []

        # Crescimento de Receita
        if fundamentos.crescimento_receita_12m:
            crescimento = fundamentos.crescimento_receita_12m * 100
            if crescimento > 0:
                # Crescimento de 20% = score 100
                pontos.append(min(100, (crescimento / 20) * 100))
            else:
                pontos.append(0)

        # Crescimento de Lucro
        if fundamentos.crescimento_lucro_12m:
            crescimento = fundamentos.crescimento_lucro_12m * 100
            if crescimento > 0:
                # Crescimento de 20% = score 100
                pontos.append(min(100, (crescimento / 20) * 100))
            else:
                pontos.append(0)

        return round(sum(pontos) / len(pontos), 2) if pontos else None
