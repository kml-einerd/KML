"""
Processador de Ações (BLC_4)
Extrai movimentos de compra/venda de ações dos fundos
"""

import pandas as pd
from pathlib import Path


class AcoesProcessor:
    """Processa arquivo BLC_4 (ações)"""

    def __init__(self, logger=None):
        self.logger = logger

    def _log(self, msg: str):
        """Helper para log"""
        if self.logger:
            self.logger.info(msg)
        else:
            print(f"[AcoesProcessor] {msg}")

    def processar(self, arquivo_blc4: str, mapeamento_grupos: dict,
                  mes_referencia: str) -> pd.DataFrame:
        """
        Processa arquivo BLC_4 (ações) e filtra apenas Top grupos

        Args:
            arquivo_blc4: Caminho para arquivo cda_fi_BLC_4_*.csv
            mapeamento_grupos: Dict {CNPJ → nome_grupo}
            mes_referencia: Data de referência (ex: '2025-11-30')

        Returns:
            DataFrame com movimentos de ações
        """
        self._log(f"Processando {arquivo_blc4}...")

        # Ler CSV
        try:
            df = pd.read_csv(arquivo_blc4, sep=';', encoding='utf-8')
        except UnicodeDecodeError:
            df = pd.read_csv(arquivo_blc4, sep=';', encoding='latin1')

        self._log(f"  Lidas {len(df):,} posições de ações")

        # Filtrar apenas fundos do Top 100
        df['grupo_economico'] = df['CNPJ_FUNDO_CLASSE'].map(mapeamento_grupos)
        df_top = df[df['grupo_economico'].notna()].copy()

        self._log(f"  Filtradas {len(df_top):,} posições de fundos Top 100")

        # Converter valores numéricos
        colunas_numericas = [
            'QT_VENDA_NEGOC', 'VL_VENDA_NEGOC',
            'QT_AQUIS_NEGOC', 'VL_AQUIS_NEGOC',
            'QT_POS_FINAL', 'VL_MERC_POS_FINAL',
            'VL_CUSTO_POS_FINAL'
        ]

        for col in colunas_numericas:
            if col in df_top.columns:
                df_top[col] = pd.to_numeric(
                    df_top[col].astype(str).str.replace(',', '.'),
                    errors='coerce'
                ).fillna(0)

        # Agregar por grupo + ticker (ignorar variações no nome da empresa)
        df_agg = df_top.groupby(['grupo_economico', 'CD_ATIVO']).agg({
            'DS_ATIVO': 'first',  # Pegar primeiro nome de empresa encontrado
            'QT_AQUIS_NEGOC': 'sum',
            'VL_AQUIS_NEGOC': 'sum',
            'QT_VENDA_NEGOC': 'sum',
            'VL_VENDA_NEGOC': 'sum',
            'QT_POS_FINAL': 'sum',
            'VL_MERC_POS_FINAL': 'sum',
            'VL_CUSTO_POS_FINAL': 'sum',
        }).reset_index()

        # Renomear colunas
        df_agg.columns = [
            'grupo_economico', 'ticker', 'empresa',
            'qtd_comprada', 'valor_comprado',
            'qtd_vendida', 'valor_vendido',
            'posicao_final', 'valor_mercado', 'valor_custo'
        ]

        # Adicionar mes_referencia
        df_agg['mes_referencia'] = mes_referencia

        # Classificar tipo de movimento
        df_agg['tipo_movimento'] = df_agg.apply(
            lambda row: self._classificar_movimento(
                row['valor_comprado'],
                row['valor_vendido']
            ),
            axis=1
        )

        # Calcular rentabilidade
        df_agg['rentabilidade_pct'] = df_agg.apply(
            lambda row: self._calcular_rentabilidade(
                row['valor_mercado'],
                row['valor_custo']
            ),
            axis=1
        )

        self._log(f"  Agregadas {len(df_agg):,} posições (grupo+ticker)")

        # Converter tipos para compatibilidade com Supabase
        # Arredondar decimais para evitar problemas de precisão
        colunas_decimais = [
            'qtd_comprada', 'valor_comprado',
            'qtd_vendida', 'valor_vendido',
            'posicao_final', 'valor_mercado', 'valor_custo'
        ]
        for col in colunas_decimais:
            df_agg[col] = df_agg[col].round(2)

        # Arredondar rentabilidade para 4 casas decimais (apenas valores não-nulos)
        # rentabilidade_pct pode ser None quando valor_custo é 0
        df_agg['rentabilidade_pct'] = df_agg['rentabilidade_pct'].apply(
            lambda x: round(x, 4) if x is not None and pd.notna(x) else None
        )

        return df_agg

    def _classificar_movimento(self, comprado: float, vendido: float) -> str:
        """Classifica tipo de movimento"""
        if comprado > vendido * 1.1:  # Comprou 10% a mais
            return 'COMPRA'
        elif vendido > comprado * 1.1:  # Vendeu 10% a mais
            return 'VENDA'
        else:
            return 'NEUTRO'

    def _calcular_rentabilidade(self, valor_mercado: float, valor_custo: float) -> float:
        """Calcula rentabilidade em %"""
        if valor_custo > 0:
            return ((valor_mercado / valor_custo) - 1) * 100
        return None

    def get_stats(self, df_acoes: pd.DataFrame) -> dict:
        """Retorna estatísticas das ações"""
        return {
            'total_posicoes': len(df_acoes),
            'total_tickers': df_acoes['ticker'].nunique(),
            'total_grupos': df_acoes['grupo_economico'].nunique(),
            'valor_total_mercado_bilhoes': df_acoes['valor_mercado'].sum() / 1_000_000_000,
            'valor_comprado_bilhoes': df_acoes['valor_comprado'].sum() / 1_000_000_000,
            'valor_vendido_bilhoes': df_acoes['valor_vendido'].sum() / 1_000_000_000,
        }
