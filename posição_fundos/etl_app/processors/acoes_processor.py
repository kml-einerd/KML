"""
Processador de posições em ações (BLC_4)
"""
import pandas as pd
from .base_processor import BaseProcessor
from typing import List


class AcoesProcessor(BaseProcessor):
    """Processa arquivo de ações (BLC_4)"""

    def process(self, ano: int, mes: int, df_pl: pd.DataFrame,
                top_groups: List[str]) -> pd.DataFrame:
        """
        Processa dados de ações filtrando por Top grupos

        Args:
            ano: Ano de referência
            mes: Mês de referência
            df_pl: DataFrame com PL e grupos (para fazer join)
            top_groups: Lista dos Top N grupos

        Returns:
            DataFrame processado com posições em ações
        """
        filename = f"cda_fi_BLC_4_{ano}{mes:02d}.csv"

        # Ler CSV
        df = self.read_csv(filename)

        self._log("Processando posições em ações...")

        # Limpar textos
        df = self.clean_text_columns(df)

        # Join com PL para obter grupo econômico
        self._log("Fazendo join com dados de PL...")
        df = df.merge(
            df_pl[['cnpj_fundo', 'grupo_economico']],
            left_on='CNPJ_FUNDO_CLASSE',
            right_on='cnpj_fundo',
            how='inner'
        )

        # Filtrar apenas Top grupos
        self._log(f"Filtrando apenas Top {len(top_groups)} grupos...")
        df = df[df['grupo_economico'].isin(top_groups)].copy()

        self._log(f"✓ {len(df):,} posições após filtro Top grupos")

        # Converter valores numéricos
        numeric_cols = [
            'QT_VENDA_NEGOC', 'VL_VENDA_NEGOC',
            'QT_AQUIS_NEGOC', 'VL_AQUIS_NEGOC',
            'QT_POS_FINAL', 'VL_MERC_POS_FINAL', 'VL_CUSTO_POS_FINAL'
        ]

        for col in numeric_cols:
            df[col] = df[col].apply(self.safe_decimal)

        # Extrair ticker (primeiras letras + número)
        df['ticker'] = df['CD_ATIVO'].str.extract(r'([A-Z]{4}\d{1,2})', expand=False)

        # Preparar DataFrame final
        df_processed = df[[
            'CNPJ_FUNDO_CLASSE',
            'grupo_economico',
            'DT_COMPTC',
            'CD_ATIVO',
            'ticker',
            'DS_ATIVO',
            'TP_ATIVO',
            'QT_VENDA_NEGOC',
            'VL_VENDA_NEGOC',
            'QT_AQUIS_NEGOC',
            'VL_AQUIS_NEGOC',
            'QT_POS_FINAL',
            'VL_MERC_POS_FINAL',
            'VL_CUSTO_POS_FINAL',
            'EMISSOR_LIGADO'
        ]].copy()

        # Renomear colunas
        df_processed.columns = [
            'cnpj_fundo',
            'grupo_economico',
            'data_competencia',
            'codigo_ativo',
            'ticker',
            'descricao_ativo',
            'tipo_ativo',
            'qtd_vendida',
            'valor_venda',
            'qtd_comprada',
            'valor_compra',
            'qtd_posicao_final',
            'valor_mercado',
            'valor_custo',
            'emissor_ligado'
        ]

        # Converter data
        df_processed['data_competencia'] = pd.to_datetime(
            df_processed['data_competencia'],
            format='%Y-%m-%d',
            errors='coerce'
        )

        # Calcular rentabilidade da posição
        df_processed['rentabilidade'] = (
            (df_processed['valor_mercado'] - df_processed['valor_custo']) /
            df_processed['valor_custo'].replace(0, 1) * 100
        )

        # Classificar tipo de movimentação
        df_processed['tipo_movimentacao'] = df_processed.apply(
            self._classify_movement, axis=1
        )

        self._log(f"✓ {len(df_processed):,} posições em ações processadas")

        return df_processed

    def _classify_movement(self, row) -> str:
        """
        Classifica o tipo de movimentação

        Args:
            row: Linha do DataFrame

        Returns:
            'COMPRA', 'VENDA' ou 'NEUTRO'
        """
        compra = row['valor_compra']
        venda = row['valor_venda']

        if compra > venda:
            return 'COMPRA'
        elif venda > compra:
            return 'VENDA'
        else:
            return 'NEUTRO'

    def get_summary_stats(self, df: pd.DataFrame) -> dict:
        """
        Retorna estatísticas resumidas das ações

        Args:
            df: DataFrame processado

        Returns:
            Dicionário com estatísticas
        """
        return {
            'total_posicoes': len(df),
            'total_tickers': df['ticker'].nunique(),
            'total_grupos': df['grupo_economico'].nunique(),
            'valor_total_mercado_bilhoes': df['valor_mercado'].sum() / 1_000_000_000,
            'total_compras_bilhoes': df['valor_compra'].sum() / 1_000_000_000,
            'total_vendas_bilhoes': df['valor_venda'].sum() / 1_000_000_000,
            'fluxo_liquido_bilhoes': (df['valor_compra'].sum() - df['valor_venda'].sum()) / 1_000_000_000,
            'rentabilidade_media': df[df['valor_custo'] > 0]['rentabilidade'].mean(),
        }
