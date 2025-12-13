"""
Processador base para CSVs da CVM
"""
import pandas as pd
import os
from typing import Optional
from abc import ABC, abstractmethod


class BaseProcessor(ABC):
    """Classe base para processadores de CSV"""

    def __init__(self, source_dir: str, logger=None):
        """
        Inicializa processador

        Args:
            source_dir: Diretório com arquivos CSV
            logger: Logger (opcional)
        """
        self.source_dir = source_dir
        self.logger = logger

    def _log(self, message: str, level: str = "info"):
        """Helper para log"""
        if self.logger:
            getattr(self.logger, level)(message)

    def read_csv(self, filename: str, encoding: str = 'latin1',
                 sep: str = ';', **kwargs) -> pd.DataFrame:
        """
        Lê arquivo CSV da CVM

        Args:
            filename: Nome do arquivo
            encoding: Encoding do arquivo
            sep: Separador
            **kwargs: Argumentos adicionais para pd.read_csv

        Returns:
            DataFrame com dados
        """
        filepath = os.path.join(self.source_dir, filename)

        if not os.path.exists(filepath):
            raise FileNotFoundError(f"Arquivo não encontrado: {filepath}")

        self._log(f"Lendo arquivo: {filename}")

        df = pd.read_csv(filepath, encoding=encoding, sep=sep, **kwargs)
        self._log(f"✓ {len(df):,} linhas carregadas")

        return df

    @abstractmethod
    def process(self, **kwargs) -> pd.DataFrame:
        """
        Processa os dados (implementar em subclasses)

        Returns:
            DataFrame processado
        """
        pass

    def clean_text_columns(self, df: pd.DataFrame) -> pd.DataFrame:
        """
        Limpa colunas de texto

        Args:
            df: DataFrame

        Returns:
            DataFrame com textos limpos
        """
        df = df.copy()

        for col in df.select_dtypes(include=['object']).columns:
            # Remove espaços extras
            df[col] = df[col].str.strip() if hasattr(df[col], 'str') else df[col]

            # Remove caracteres especiais problemáticos
            if hasattr(df[col], 'str'):
                df[col] = df[col].str.replace('�', '', regex=False)

        return df

    def safe_decimal(self, value, default: float = 0.0) -> float:
        """
        Converte valor para decimal de forma segura

        Args:
            value: Valor a converter
            default: Valor padrão se conversão falhar

        Returns:
            Valor decimal
        """
        try:
            if pd.isna(value):
                return default
            return float(value)
        except (ValueError, TypeError):
            return default
