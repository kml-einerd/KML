"""
Validadores de dados
"""

import re
import pandas as pd
from typing import List, Optional
from decimal import Decimal, InvalidOperation

class DataValidator:
    """Validadores de dados CVM"""

    @staticmethod
    def validar_cnpj(cnpj: str) -> bool:
        """
        Valida formato de CNPJ (14 dígitos)
        Não valida dígito verificador

        Args:
            cnpj: String com CNPJ

        Returns:
            True se válido
        """
        if not cnpj:
            return False

        # Remover pontuação
        cnpj_limpo = re.sub(r'[^\d]', '', str(cnpj))

        # Deve ter 14 dígitos
        return len(cnpj_limpo) == 14 and cnpj_limpo.isdigit()

    @staticmethod
    def validar_ticker(ticker: str) -> bool:
        """
        Valida formato de ticker brasileiro

        Args:
            ticker: Código do ativo

        Returns:
            True se válido

        Examples:
            PETR4, VALE3, ITUB4, etc.
        """
        if not ticker:
            return False

        # Formato: 4 letras + 1 ou 2 dígitos (opcional: F para fracionário)
        pattern = r'^[A-Z]{4}\d{1,2}[FB]?$'
        return bool(re.match(pattern, str(ticker).strip().upper()))

    @staticmethod
    def validar_data(data_str: str) -> bool:
        """
        Valida formato de data (YYYY-MM-DD ou DD/MM/YYYY)

        Args:
            data_str: String com data

        Returns:
            True se válido
        """
        if not data_str:
            return False

        # YYYY-MM-DD
        if re.match(r'^\d{4}-\d{2}-\d{2}$', str(data_str)):
            return True

        # DD/MM/YYYY
        if re.match(r'^\d{2}/\d{2}/\d{4}$', str(data_str)):
            return True

        return False

    @staticmethod
    def validar_decimal(valor: any) -> bool:
        """
        Valida se valor pode ser convertido para Decimal

        Args:
            valor: Valor a validar

        Returns:
            True se válido
        """
        try:
            Decimal(str(valor).replace(',', '.'))
            return True
        except (InvalidOperation, ValueError):
            return False

    @staticmethod
    def validar_dataframe_schema(df: pd.DataFrame, colunas_obrigatorias: List[str]) -> tuple[bool, List[str]]:
        """
        Valida se DataFrame possui colunas obrigatórias

        Args:
            df: DataFrame a validar
            colunas_obrigatorias: Lista de colunas que devem existir

        Returns:
            (valido: bool, colunas_faltando: list)
        """
        colunas_df = set(df.columns)
        colunas_req = set(colunas_obrigatorias)

        faltando = list(colunas_req - colunas_df)

        return (len(faltando) == 0, faltando)

    @staticmethod
    def validar_integridade_pl(
        df_posicoes: pd.DataFrame,
        df_pl: pd.DataFrame,
        tolerancia: float = 0.10
    ) -> tuple[bool, dict]:
        """
        Valida integridade entre posições e PL
        Soma das posições não deve ultrapassar muito o PL

        Args:
            df_posicoes: DataFrame com posições
            df_pl: DataFrame com PL
            tolerancia: Tolerância aceita (10% = 0.10)

        Returns:
            (valido: bool, detalhes: dict)
        """
        # Agrupar posições por fundo
        posicoes_agg = df_posicoes.groupby('cnpj_fundo')['valor_mercado_final'].sum()

        # Merge com PL
        comparacao = pd.DataFrame({
            'total_posicoes': posicoes_agg
        }).join(df_pl.set_index('cnpj_fundo')['valor_pl'], how='inner')

        # Calcular diferença
        comparacao['diferenca_pct'] = (
            (comparacao['total_posicoes'] - comparacao['valor_pl'])
            / comparacao['valor_pl']
        ).abs()

        # Identificar problemas
        problemas = comparacao[comparacao['diferenca_pct'] > tolerancia]

        detalhes = {
            'total_fundos': len(comparacao),
            'fundos_com_problemas': len(problemas),
            'maior_diferenca': comparacao['diferenca_pct'].max() if len(comparacao) > 0 else 0,
            'fundos_problematicos': problemas.index.tolist() if len(problemas) > 0 else []
        }

        return (len(problemas) == 0, detalhes)

    @staticmethod
    def contar_nulos(df: pd.DataFrame) -> dict:
        """
        Conta valores nulos por coluna

        Args:
            df: DataFrame

        Returns:
            Dicionário {coluna: num_nulos}
        """
        nulos = df.isnull().sum()
        return {col: count for col, count in nulos.items() if count > 0}

    @staticmethod
    def contar_duplicatas(df: pd.DataFrame, colunas_chave: List[str]) -> int:
        """
        Conta registros duplicados

        Args:
            df: DataFrame
            colunas_chave: Colunas que definem unicidade

        Returns:
            Número de duplicatas
        """
        return df.duplicated(subset=colunas_chave).sum()

if __name__ == '__main__':
    # Testes
    validator = DataValidator()

    # Teste CNPJ
    assert validator.validar_cnpj('00.017.024/0001-53') == True
    assert validator.validar_cnpj('00017024000153') == True
    assert validator.validar_cnpj('123') == False

    # Teste Ticker
    assert validator.validar_ticker('PETR4') == True
    assert validator.validar_ticker('VALE3') == True
    assert validator.validar_ticker('INVALID') == False

    # Teste Data
    assert validator.validar_data('2025-10-31') == True
    assert validator.validar_data('31/10/2025') == True
    assert validator.validar_data('invalid') == False

    # Teste Decimal
    assert validator.validar_decimal('123.45') == True
    assert validator.validar_decimal('123,45') == True
    assert validator.validar_decimal('abc') == False

    print("✓ Todos os testes passaram!")
