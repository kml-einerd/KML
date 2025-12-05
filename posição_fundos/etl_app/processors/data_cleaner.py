"""
Limpeza e normalização de dados CVM
"""

import pandas as pd
import re
from decimal import Decimal
from typing import Optional
from utils.logger import app_logger
from processors.text_corrector import TextCorrector

class DataCleaner:
    """Limpeza e normalização de dados"""

    def __init__(self):
        self.text_corrector = TextCorrector()

    @staticmethod
    def limpar_cnpj(cnpj: str) -> str:
        """
        Remove pontuação de CNPJ

        Args:
            cnpj: CNPJ com ou sem formatação

        Returns:
            CNPJ apenas com números
        """
        if pd.isna(cnpj):
            return ''

        return re.sub(r'[^\d]', '', str(cnpj))

    @staticmethod
    def normalizar_ticker(ticker: str) -> str:
        """
        Normaliza código do ticker

        Args:
            ticker: Código do ativo

        Returns:
            Ticker maiúsculo e sem espaços
        """
        if pd.isna(ticker):
            return ''

        return str(ticker).strip().upper()

    @staticmethod
    def converter_decimal(valor: str) -> float:
        """
        Converte string para float

        Args:
            valor: Valor como string (pode ter vírgula)

        Returns:
            Float ou 0.0 se inválido
        """
        if pd.isna(valor) or valor == '':
            return 0.0

        try:
            # Substituir vírgula por ponto
            valor_limpo = str(valor).replace(',', '.')
            return float(valor_limpo)
        except (ValueError, AttributeError):
            return 0.0

    @staticmethod
    def converter_data_brasileira(data_str: str) -> Optional[str]:
        """
        Converte data brasileira (DD/MM/YYYY) para ISO (YYYY-MM-DD)

        Args:
            data_str: Data em formato brasileiro

        Returns:
            Data em formato ISO ou None
        """
        if pd.isna(data_str):
            return None

        data_str = str(data_str).strip()

        # Se já está em formato ISO, retornar
        if re.match(r'^\d{4}-\d{2}-\d{2}', data_str):
            return data_str[:10]

        # Converter DD/MM/YYYY -> YYYY-MM-DD
        match = re.match(r'^(\d{2})/(\d{2})/(\d{4})', data_str)
        if match:
            dia, mes, ano = match.groups()
            return f"{ano}-{mes}-{dia}"

        return None

    @staticmethod
    def corrigir_encoding(text: str) -> str:
        """
        Corrige problemas de encoding

        Args:
            text: Texto com encoding incorreto

        Returns:
            Texto corrigido
        """
        if pd.isna(text):
            return ''

        # Mapeamento de caracteres problemáticos
        replacements = {
            '�': 'í',
            'Í': 'ó',
            'í': 'ã',
            'ô': 'õ',
            '�': 'ê',
            '': 'ç'
        }

        text_corrigido = str(text)
        for errado, correto in replacements.items():
            text_corrigido = text_corrigido.replace(errado, correto)

        return text_corrigido

    def limpar_dataframe_balancete(self, df: pd.DataFrame) -> pd.DataFrame:
        """
        Limpa DataFrame de balancete (BLC)

        Args:
            df: DataFrame bruto

        Returns:
            DataFrame limpo
        """
        app_logger.info(f"Limpando balancete ({len(df):,} linhas)...")

        df_limpo = df.copy()

        # Limpar CNPJs
        df_limpo['CNPJ_FUNDO_CLASSE'] = df_limpo['CNPJ_FUNDO_CLASSE'].apply(self.limpar_cnpj)

        # Normalizar datas
        if 'DT_COMPTC' in df_limpo.columns:
            df_limpo['DT_COMPTC'] = df_limpo['DT_COMPTC'].apply(self.converter_data_brasileira)

        # Converter valores numéricos
        colunas_numericas = [
            'QT_AQUIS_NEGOC', 'VL_AQUIS_NEGOC',
            'QT_VENDA_NEGOC', 'VL_VENDA_NEGOC',
            'QT_POS_FINAL', 'VL_MERC_POS_FINAL', 'VL_CUSTO_POS_FINAL'
        ]

        for col in colunas_numericas:
            if col in df_limpo.columns:
                df_limpo[col] = df_limpo[col].apply(self.converter_decimal)

        # Corrigir encoding em textos
        colunas_texto = ['DENOM_SOCIAL', 'TP_APLIC', 'TP_ATIVO']
        for col in colunas_texto:
            if col in df_limpo.columns:
                df_limpo[col] = df_limpo[col].apply(self.corrigir_encoding)

        # Normalizar tickers (se existir coluna CD_ATIVO ou similar)
        if 'CD_ATIVO' in df_limpo.columns:
            df_limpo['CD_ATIVO'] = df_limpo['CD_ATIVO'].apply(self.normalizar_ticker)

        # Remover linhas completamente vazias
        df_limpo = df_limpo.dropna(how='all')

        # Remover duplicatas
        antes = len(df_limpo)
        df_limpo = df_limpo.drop_duplicates()
        depois = len(df_limpo)

        if antes != depois:
            app_logger.warning(f"Removidas {antes - depois:,} linhas duplicadas")

        app_logger.success(f"✓ Balancete limpo: {len(df_limpo):,} linhas")

        return df_limpo

    def limpar_dataframe_pl(self, df: pd.DataFrame) -> pd.DataFrame:
        """
        Limpa DataFrame de Patrimônio Líquido

        Args:
            df: DataFrame bruto

        Returns:
            DataFrame limpo
        """
        app_logger.info(f"Limpando PL ({len(df):,} linhas)...")

        df_limpo = df.copy()

        # Limpar CNPJs
        df_limpo['CNPJ_FUNDO_CLASSE'] = df_limpo['CNPJ_FUNDO_CLASSE'].apply(self.limpar_cnpj)

        # Normalizar datas
        df_limpo['DT_COMPTC'] = df_limpo['DT_COMPTC'].apply(self.converter_data_brasileira)

        # Converter PL para numérico
        df_limpo['VL_PATRIM_LIQ'] = df_limpo['VL_PATRIM_LIQ'].apply(self.converter_decimal)

        # Corrigir encoding
        df_limpo['DENOM_SOCIAL'] = df_limpo['DENOM_SOCIAL'].apply(self.corrigir_encoding)

        # Remover fundos com PL zero ou negativo
        antes = len(df_limpo)
        df_limpo = df_limpo[df_limpo['VL_PATRIM_LIQ'] > 0]
        depois = len(df_limpo)

        if antes != depois:
            app_logger.warning(f"Removidos {antes - depois:,} fundos com PL <= 0")

        # Remover duplicatas
        df_limpo = df_limpo.drop_duplicates(subset=['CNPJ_FUNDO_CLASSE', 'DT_COMPTC'])

        app_logger.success(f"✓ PL limpo: {len(df_limpo):,} linhas")

        return df_limpo

    def aplicar_correcao_texto(self, df):
        """
        Aplica correção ortográfica em colunas de texto
        
        Args:
            df: DataFrame a ser corrigido
            
        Returns:
            DataFrame com textos corrigidos
        """
        df_corrigido = df.copy()
        
        # Corrigir nome do fundo
        if 'DENOM_SOCIAL' in df_corrigido.columns:
            df_corrigido['DENOM_SOCIAL'] = df_corrigido['DENOM_SOCIAL'].apply(
                self.text_corrector.corrigir_nome_fundo
            )
        
        # Corrigir nome do emissor
        if 'EMISSOR' in df_corrigido.columns:
            df_corrigido['EMISSOR'] = df_corrigido['EMISSOR'].apply(
                self.text_corrector.corrigir_nome_emissor
            )
        
        return df_corrigido

if __name__ == '__main__':
    # Testes
    cleaner = DataCleaner()

    # Teste CNPJ
    assert cleaner.limpar_cnpj('00.017.024/0001-53') == '00017024000153'

    # Teste ticker
    assert cleaner.normalizar_ticker(' petr4 ') == 'PETR4'

    # Teste decimal
    assert cleaner.converter_decimal('1.234,56') == 1234.56
    assert cleaner.converter_decimal('1234.56') == 1234.56

    # Teste data
    assert cleaner.converter_data_brasileira('31/10/2025') == '2025-10-31'

    print("✓ Todos os testes passaram!")
