"""
Processador de Patrimônio Líquido dos fundos
"""
import pandas as pd
from datetime import datetime
from .base_processor import BaseProcessor
from utils.groups_helper import GroupsHelper


class PatrimonioProcessor(BaseProcessor):
    """Processa arquivo de Patrimônio Líquido (PL)"""

    def process(self, ano: int, mes: int, top_n: int = 100) -> tuple:
        """
        Processa dados de PL e identifica Top N grupos

        Args:
            ano: Ano de referência
            mes: Mês de referência
            top_n: Quantidade de grupos no Top

        Returns:
            Tuple (df_pl_processado, lista_top_groups)
        """
        filename = f"cda_fi_PL_{ano}{mes:02d}.csv"

        # Ler CSV
        df = self.read_csv(filename)

        self._log("Processando dados de PL...")

        # Limpar textos
        df = self.clean_text_columns(df)

        # Identificar grupos econômicos
        self._log("Identificando grupos econômicos...")
        df['grupo_economico'] = df['DENOM_SOCIAL'].apply(GroupsHelper.identify_group)

        # Converter valores
        df['VL_PATRIM_LIQ'] = df['VL_PATRIM_LIQ'].apply(self.safe_decimal)

        # Calcular Top N grupos
        self._log(f"Calculando Top {top_n} grupos por PL...")
        top_groups = GroupsHelper.calculate_top_groups(df, top_n=top_n)

        self._log(f"✓ Top {top_n} grupos identificados")
        self._log(f"  Total de grupos únicos: {df['grupo_economico'].nunique()}")

        # Preparar DataFrame final
        df_processed = df[[
            'CNPJ_FUNDO_CLASSE',
            'DENOM_SOCIAL',
            'grupo_economico',
            'DT_COMPTC',
            'VL_PATRIM_LIQ'
        ]].copy()

        # Renomear colunas
        df_processed.columns = [
            'cnpj_fundo',
            'nome_fundo',
            'grupo_economico',
            'data_competencia',
            'valor_pl'
        ]

        # Converter data
        df_processed['data_competencia'] = pd.to_datetime(
            df_processed['data_competencia'],
            format='%Y-%m-%d',
            errors='coerce'
        )

        self._log(f"✓ {len(df_processed):,} registros de PL processados")

        return df_processed, top_groups

    def get_summary_stats(self, df: pd.DataFrame) -> dict:
        """
        Retorna estatísticas resumidas do PL

        Args:
            df: DataFrame processado

        Returns:
            Dicionário com estatísticas
        """
        return {
            'total_fundos': df['cnpj_fundo'].nunique(),
            'total_grupos': df['grupo_economico'].nunique(),
            'pl_total_bilhoes': df['valor_pl'].sum() / 1_000_000_000,
            'pl_medio_milhoes': df['valor_pl'].mean() / 1_000_000,
            'maior_fundo': df.loc[df['valor_pl'].idxmax(), 'nome_fundo'],
            'maior_pl_bilhoes': df['valor_pl'].max() / 1_000_000_000,
        }
