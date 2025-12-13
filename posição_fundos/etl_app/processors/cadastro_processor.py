"""
Processador de cadastro de fundos
"""
import pandas as pd
from .base_processor import BaseProcessor
from typing import List


class CadastroProcessor(BaseProcessor):
    """Processa arquivo de cadastro de fundos"""

    def process(self, ano: int, mes: int, df_pl: pd.DataFrame,
                top_groups: List[str]) -> pd.DataFrame:
        """
        Processa cadastro de fundos filtrando por Top grupos

        Args:
            ano: Ano de referência
            mes: Mês de referência
            df_pl: DataFrame com PL e grupos
            top_groups: Lista dos Top N grupos

        Returns:
            DataFrame processado com cadastro de fundos
        """
        filename = f"cda_fie_{ano}{mes:02d}.csv"

        # Ler CSV
        df = self.read_csv(filename)

        self._log("Processando cadastro de fundos...")

        # Limpar textos
        df = self.clean_text_columns(df)

        # Selecionar apenas colunas relevantes do cadastro
        # (arquivo cda_fie tem muitas colunas, vamos pegar só o básico)
        df_cadastro = df[[
            'CNPJ_FUNDO_CLASSE',
            'DENOM_SOCIAL',
            'TP_FUNDO_CLASSE',
        ]].drop_duplicates(subset=['CNPJ_FUNDO_CLASSE']).copy()

        # Join com PL para obter grupo econômico
        self._log("Fazendo join com dados de PL...")
        df_cadastro = df_cadastro.merge(
            df_pl[['cnpj_fundo', 'grupo_economico']],
            left_on='CNPJ_FUNDO_CLASSE',
            right_on='cnpj_fundo',
            how='inner'
        )

        # Filtrar apenas Top grupos
        self._log(f"Filtrando apenas Top {len(top_groups)} grupos...")
        df_cadastro = df_cadastro[df_cadastro['grupo_economico'].isin(top_groups)].copy()

        # Renomear colunas
        df_processed = df_cadastro[[
            'CNPJ_FUNDO_CLASSE',
            'DENOM_SOCIAL',
            'TP_FUNDO_CLASSE',
            'grupo_economico'
        ]].copy()

        df_processed.columns = [
            'cnpj_fundo',
            'nome_fundo',
            'tipo_fundo',
            'grupo_economico'
        ]

        self._log(f"✓ {len(df_processed):,} fundos cadastrados (Top grupos)")

        return df_processed

    def get_summary_stats(self, df: pd.DataFrame) -> dict:
        """
        Retorna estatísticas resumidas do cadastro

        Args:
            df: DataFrame processado

        Returns:
            Dicionário com estatísticas
        """
        return {
            'total_fundos': len(df),
            'total_grupos': df['grupo_economico'].nunique(),
            'tipos_fundo': df['tipo_fundo'].value_counts().to_dict(),
        }
