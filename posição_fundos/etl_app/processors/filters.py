"""
Filtros para dados do MVP
"""

import pandas as pd
from typing import List
from config import (
    THRESHOLD_GRANDE_FUNDO,
    TIPOS_APLICACAO_VALIDOS,
    TIPOS_ATIVOS_VALIDOS,
    VALOR_MINIMO_POSICAO
)
from utils.logger import app_logger

class DataFilter:
    """Aplicação de filtros específicos do MVP"""

    @staticmethod
    def filtrar_apenas_acoes(df: pd.DataFrame) -> pd.DataFrame:
        """
        Mantém apenas registros de ações

        Args:
            df: DataFrame com coluna TP_APLIC

        Returns:
            DataFrame filtrado
        """
        antes = len(df)

        df_filtrado = df[df['TP_APLIC'].isin(TIPOS_APLICACAO_VALIDOS)].copy()

        depois = len(df_filtrado)
        reducao = (1 - depois/antes) * 100 if antes > 0 else 0

        app_logger.info(
            f"Filtro 'Apenas Ações': {antes:,} → {depois:,} "
            f"(redução: {reducao:.1f}%)"
        )

        return df_filtrado

    @staticmethod
    def filtrar_tipos_ativos_validos(df: pd.DataFrame) -> pd.DataFrame:
        """
        Mantém apenas tipos de ativos válidos (ações ON, PN, Units)

        Args:
            df: DataFrame com coluna TP_ATIVO

        Returns:
            DataFrame filtrado
        """
        antes = len(df)

        df_filtrado = df[df['TP_ATIVO'].isin(TIPOS_ATIVOS_VALIDOS)].copy()

        depois = len(df_filtrado)
        reducao = (1 - depois/antes) * 100 if antes > 0 else 0

        app_logger.info(
            f"Filtro 'Tipos Válidos': {antes:,} → {depois:,} "
            f"(redução: {reducao:.1f}%)"
        )

        return df_filtrado

    @staticmethod
    def identificar_grandes_fundos(
        df_pl: pd.DataFrame,
        threshold: float = THRESHOLD_GRANDE_FUNDO
    ) -> List[str]:
        """
        Identifica CNPJs dos grandes fundos (PL > threshold)

        Args:
            df_pl: DataFrame com PL dos fundos
            threshold: Valor mínimo de PL

        Returns:
            Lista de CNPJs dos grandes fundos
        """
        grandes = df_pl[df_pl['VL_PATRIM_LIQ'] > threshold]

        cnpjs = grandes['CNPJ_FUNDO_CLASSE'].unique().tolist()

        app_logger.info(
            f"Identificados {len(cnpjs):,} grandes fundos "
            f"(PL > R$ {threshold:,.0f})"
        )

        return cnpjs

    @staticmethod
    def filtrar_apenas_grandes_fundos(
        df: pd.DataFrame,
        cnpjs_grandes_fundos: List[str]
    ) -> pd.DataFrame:
        """
        Mantém apenas posições de grandes fundos

        Args:
            df: DataFrame com posições
            cnpjs_grandes_fundos: Lista de CNPJs dos grandes fundos

        Returns:
            DataFrame filtrado
        """
        antes = len(df)

        df_filtrado = df[
            df['CNPJ_FUNDO_CLASSE'].isin(cnpjs_grandes_fundos)
        ].copy()

        depois = len(df_filtrado)
        reducao = (1 - depois/antes) * 100 if antes > 0 else 0

        app_logger.info(
            f"Filtro 'Grandes Fundos': {antes:,} → {depois:,} "
            f"(redução: {reducao:.1f}%)"
        )

        return df_filtrado

    @staticmethod
    def filtrar_posicoes_relevantes(
        df: pd.DataFrame,
        valor_minimo: float = VALOR_MINIMO_POSICAO
    ) -> pd.DataFrame:
        """
        Remove posições pequenas (ruído)

        Args:
            df: DataFrame com posições
            valor_minimo: Valor mínimo para manter posição

        Returns:
            DataFrame filtrado
        """
        antes = len(df)

        # Manter se valor de mercado final > valor_minimo
        df_filtrado = df[
            (df['VL_MERC_POS_FINAL'] > valor_minimo) |
            (df['VL_AQUIS_NEGOC'] > valor_minimo) |
            (df['VL_VENDA_NEGOC'] > valor_minimo)
        ].copy()

        depois = len(df_filtrado)
        reducao = (1 - depois/antes) * 100 if antes > 0 else 0

        app_logger.info(
            f"Filtro 'Posições Relevantes': {antes:,} → {depois:,} "
            f"(redução: {reducao:.1f}%)"
        )

        return df_filtrado

    @staticmethod
    def pipeline_completo(
        df_posicoes: pd.DataFrame,
        df_pl: pd.DataFrame
    ) -> pd.DataFrame:
        """
        Aplica pipeline completo de filtros do MVP

        Args:
            df_posicoes: DataFrame com posições
            df_pl: DataFrame com PL

        Returns:
            DataFrame completamente filtrado
        """
        app_logger.info("Iniciando pipeline de filtros...")

        # 1. Apenas ações
        df = DataFilter.filtrar_apenas_acoes(df_posicoes)

        # 2. Tipos de ativos válidos
        df = DataFilter.filtrar_tipos_ativos_validos(df)

        # 3. Identificar grandes fundos
        grandes_fundos = DataFilter.identificar_grandes_fundos(df_pl)

        # 4. Apenas grandes fundos
        df = DataFilter.filtrar_apenas_grandes_fundos(df, grandes_fundos)

        # 5. Posições relevantes
        df = DataFilter.filtrar_posicoes_relevantes(df)

        # Resultado final
        reducao_total = (1 - len(df)/len(df_posicoes)) * 100
        app_logger.success(
            f"✓ Pipeline concluído: {len(df_posicoes):,} → {len(df):,} "
            f"(redução total: {reducao_total:.1f}%)"
        )

        return df

if __name__ == '__main__':
    # Teste dos filtros
    import numpy as np

    # Criar DataFrame de teste
    df_test = pd.DataFrame({
        'CNPJ_FUNDO_CLASSE': ['11111111111111'] * 1000,
        'TP_APLIC': ['Ações'] * 500 + ['Títulos Públicos'] * 500,
        'TP_ATIVO': ['Ação ordinária'] * 800 + ['Outro'] * 200,
        'VL_MERC_POS_FINAL': np.random.rand(1000) * 10_000_000
    })

    df_pl_test = pd.DataFrame({
        'CNPJ_FUNDO_CLASSE': ['11111111111111'],
        'VL_PATRIM_LIQ': [100_000_000]
    })

    # Testar filtros
    df_filtrado = DataFilter.pipeline_completo(df_test, df_pl_test)
    print(f"Resultado: {len(df_filtrado)} linhas")
