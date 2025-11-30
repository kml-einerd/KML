"""
Cálculo de agregações para o MVP
Top Movers, Fresh Bets, Popularidade
"""

import pandas as pd
from typing import List, Dict
from config import MIN_FUNDOS_CONSENSO, TOP_MOVERS_COUNT, TOP_FRESH_BETS
from utils.logger import app_logger

class DataAggregator:
    """Calcula agregações para o dashboard"""

    @staticmethod
    def calcular_top_movers(df: pd.DataFrame) -> pd.DataFrame:
        """
        Calcula Top Movers (fundos que mais compraram/venderam)

        Args:
            df: DataFrame com posições

        Returns:
            DataFrame com rankings
        """
        app_logger.info("Calculando Top Movers...")

        # Agrupar por fundo e data
        top_movers = df.groupby(['CNPJ_FUNDO_CLASSE', 'DT_COMPTC']).agg({
            'VL_AQUIS_NEGOC': 'sum',
            'VL_VENDA_NEGOC': 'sum'
        }).reset_index()

        # Calcular fluxo líquido
        top_movers['fluxo_liquido'] = (
            top_movers['VL_AQUIS_NEGOC'] - top_movers['VL_VENDA_NEGOC']
        )

        # Renomear colunas
        top_movers = top_movers.rename(columns={
            'CNPJ_FUNDO_CLASSE': 'cnpj_fundo',
            'DT_COMPTC': 'data_competencia',
            'VL_AQUIS_NEGOC': 'total_compras',
            'VL_VENDA_NEGOC': 'total_vendas'
        })

        # Calcular rankings
        top_movers['ranking_compradores'] = top_movers.groupby('data_competencia')['fluxo_liquido'].rank(
            ascending=False, method='dense'
        ).astype(int)

        top_movers['ranking_vendedores'] = top_movers.groupby('data_competencia')['fluxo_liquido'].rank(
            ascending=True, method='dense'
        ).astype(int)

        app_logger.success(f"✓ Top Movers calculado: {len(top_movers):,} fundos")

        return top_movers

    @staticmethod
    def calcular_fresh_bets(
        df_atual: pd.DataFrame,
        df_anterior: pd.DataFrame
    ) -> pd.DataFrame:
        """
        Calcula Fresh Bets (ativos que entraram nas carteiras)

        Requer dados de 2 meses consecutivos

        Args:
            df_atual: Posições do mês atual
            df_anterior: Posições do mês anterior

        Returns:
            DataFrame com fresh bets
        """
        app_logger.info("Calculando Fresh Bets...")

        # Identificar ticker único por fundo
        df_atual['key'] = df_atual['CNPJ_FUNDO_CLASSE'] + '_' + df_atual['CD_ATIVO']
        df_anterior['key'] = df_anterior['CNPJ_FUNDO_CLASSE'] + '_' + df_anterior['CD_ATIVO']

        # Encontrar novas entradas (estava zerado, agora tem posição)
        keys_anterior = set(df_anterior['key'].unique())
        keys_atual = set(df_atual['key'].unique())

        novas_entradas_keys = keys_atual - keys_anterior

        # Filtrar apenas novas entradas
        df_novas = df_atual[df_atual['key'].isin(novas_entradas_keys)].copy()

        if len(df_novas) == 0:
            app_logger.warning("Nenhuma nova entrada identificada")
            return pd.DataFrame()

        # Agrupar por ticker
        fresh_bets = df_novas.groupby('CD_ATIVO').agg({
            'CNPJ_FUNDO_CLASSE': ['count', lambda x: list(x.unique())],
            'VL_MERC_POS_FINAL': 'sum',
            'DT_COMPTC': 'first'
        }).reset_index()

        # Renomear colunas
        fresh_bets.columns = [
            'ticker',
            'num_fundos_entraram',
            'fundos_lista',
            'volume_total',
            'data_competencia'
        ]

        # Filtrar consenso mínimo
        fresh_bets = fresh_bets[
            fresh_bets['num_fundos_entraram'] >= MIN_FUNDOS_CONSENSO
        ].copy()

        # Ordenar por número de fundos
        fresh_bets = fresh_bets.sort_values('num_fundos_entraram', ascending=False)

        app_logger.success(
            f"✓ Fresh Bets calculado: {len(fresh_bets)} ativos "
            f"(consenso mínimo: {MIN_FUNDOS_CONSENSO} fundos)"
        )

        return fresh_bets.head(TOP_FRESH_BETS)

    @staticmethod
    def calcular_ativos_populares(df: pd.DataFrame) -> pd.DataFrame:
        """
        Calcula ativos mais populares (presentes em mais carteiras)

        Alternativa quando não há dados históricos para Fresh Bets

        Args:
            df: DataFrame com posições

        Returns:
            DataFrame com ativos populares
        """
        app_logger.info("Calculando Ativos Populares...")

        # Agrupar por ticker
        populares = df.groupby('CD_ATIVO').agg({
            'CNPJ_FUNDO_CLASSE': 'nunique',
            'VL_MERC_POS_FINAL': 'sum',
            'DT_COMPTC': 'first'
        }).reset_index()

        # Renomear colunas
        populares = populares.rename(columns={
            'CD_ATIVO': 'ticker',
            'CNPJ_FUNDO_CLASSE': 'num_fundos',
            'VL_MERC_POS_FINAL': 'volume_total',
            'DT_COMPTC': 'data_competencia'
        })

        # Ordenar por número de fundos
        populares = populares.sort_values('num_fundos', ascending=False)

        app_logger.success(f"✓ Ativos Populares calculado: {len(populares)} ativos")

        return populares.head(50)

    @staticmethod
    def preparar_para_supabase(df: pd.DataFrame, tipo: str) -> List[Dict]:
        """
        Converte DataFrame para formato de inserção Supabase

        Args:
            df: DataFrame
            tipo: Tipo de dados ('top_movers', 'fresh_bets', etc.)

        Returns:
            Lista de dicionários para upload
        """
        # Converter NaN para None
        df_clean = df.where(pd.notnull(df), None)

        # Converter para lista de dicts
        records = df_clean.to_dict('records')

        app_logger.debug(f"Preparado {len(records)} registros de '{tipo}' para upload")

        return records

if __name__ == '__main__':
    # Teste de agregações
    import numpy as np

    # DataFrame de teste
    df_test = pd.DataFrame({
        'CNPJ_FUNDO_CLASSE': ['111'] * 50 + ['222'] * 50,
        'CD_ATIVO': ['PETR4', 'VALE3'] * 50,
        'DT_COMPTC': ['2025-10-31'] * 100,
        'VL_AQUIS_NEGOC': np.random.rand(100) * 1_000_000,
        'VL_VENDA_NEGOC': np.random.rand(100) * 500_000,
        'VL_MERC_POS_FINAL': np.random.rand(100) * 5_000_000
    })

    # Testar Top Movers
    top_movers = DataAggregator.calcular_top_movers(df_test)
    print(f"Top Movers: {len(top_movers)} fundos")

    # Testar Ativos Populares
    populares = DataAggregator.calcular_ativos_populares(df_test)
    print(f"Ativos Populares: {len(populares)} ativos")
