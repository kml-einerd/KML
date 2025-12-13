"""
Validador de dados antes de upload
"""
import pandas as pd
from typing import Dict, List


class DataValidator:
    """Valida dados antes de subir para o Supabase"""

    @staticmethod
    def validate_required_columns(df: pd.DataFrame, required_cols: List[str],
                                  table_name: str) -> None:
        """
        Valida se todas as colunas obrigatórias existem

        Args:
            df: DataFrame a validar
            required_cols: Lista de colunas obrigatórias
            table_name: Nome da tabela (para mensagem de erro)

        Raises:
            ValueError: Se alguma coluna obrigatória estiver faltando
        """
        missing_cols = set(required_cols) - set(df.columns)
        if missing_cols:
            raise ValueError(
                f"Tabela {table_name}: Colunas obrigatórias faltando: {missing_cols}"
            )

    @staticmethod
    def validate_no_nulls(df: pd.DataFrame, columns: List[str], table_name: str) -> None:
        """
        Valida que colunas específicas não têm valores nulos

        Args:
            df: DataFrame a validar
            columns: Lista de colunas que não podem ter nulo
            table_name: Nome da tabela

        Raises:
            ValueError: Se encontrar valores nulos
        """
        for col in columns:
            if col in df.columns:
                null_count = df[col].isna().sum()
                if null_count > 0:
                    raise ValueError(
                        f"Tabela {table_name}: Coluna '{col}' tem {null_count} valores nulos"
                    )

    @staticmethod
    def validate_numeric_range(df: pd.DataFrame, column: str, min_val: float = None,
                              max_val: float = None, table_name: str = "") -> None:
        """
        Valida que valores numéricos estão em um range válido

        Args:
            df: DataFrame a validar
            column: Coluna a validar
            min_val: Valor mínimo permitido
            max_val: Valor máximo permitido
            table_name: Nome da tabela

        Raises:
            ValueError: Se valores fora do range
        """
        if column not in df.columns:
            return

        if min_val is not None:
            below_min = (df[column] < min_val).sum()
            if below_min > 0:
                raise ValueError(
                    f"Tabela {table_name}: {below_min} valores em '{column}' "
                    f"abaixo do mínimo ({min_val})"
                )

        if max_val is not None:
            above_max = (df[column] > max_val).sum()
            if above_max > 0:
                raise ValueError(
                    f"Tabela {table_name}: {above_max} valores em '{column}' "
                    f"acima do máximo ({max_val})"
                )

    @staticmethod
    def remove_duplicates(df: pd.DataFrame, subset: List[str],
                         table_name: str, logger=None) -> pd.DataFrame:
        """
        Remove duplicatas e loga informação

        Args:
            df: DataFrame
            subset: Colunas para considerar duplicata
            table_name: Nome da tabela
            logger: Logger (opcional)

        Returns:
            DataFrame sem duplicatas
        """
        initial_count = len(df)
        df_clean = df.drop_duplicates(subset=subset, keep='first')
        removed_count = initial_count - len(df_clean)

        if removed_count > 0 and logger:
            logger.warning(
                f"Tabela {table_name}: Removidas {removed_count} linhas duplicadas"
            )

        return df_clean

    @staticmethod
    def clean_dataframe(df: pd.DataFrame) -> pd.DataFrame:
        """
        Limpa DataFrame: remove espaços, converte tipos

        Args:
            df: DataFrame a limpar

        Returns:
            DataFrame limpo
        """
        df = df.copy()

        # Limpar strings (remover espaços extras)
        for col in df.select_dtypes(include=['object']).columns:
            df[col] = df[col].str.strip() if df[col].dtype == 'object' else df[col]

        # Substituir None/NaN em strings por None explícito
        df = df.replace({pd.NA: None, 'nan': None, 'NaN': None, '': None})

        return df
