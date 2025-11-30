"""
Leitor inteligente de arquivos CSV da CVM
"""

import pandas as pd
import chardet
from pathlib import Path
from typing import Optional, List
from config import CVM_ENCODING, CVM_SEPARATOR, CHUNK_SIZE
from utils.logger import app_logger
from utils.validators import DataValidator

class CVMReader:
    """
    Leitor especializado para arquivos CSV da CVM
    Detecta encoding, valida schema e trata erros
    """

    def __init__(self, encoding: str = CVM_ENCODING, separator: str = CVM_SEPARATOR):
        self.encoding = encoding
        self.separator = separator
        self.validator = DataValidator()

    def detectar_encoding(self, filepath: Path) -> str:
        """
        Detecta encoding do arquivo automaticamente

        Args:
            filepath: Caminho do arquivo

        Returns:
            Nome do encoding detectado
        """
        with open(filepath, 'rb') as f:
            raw_data = f.read(100000)  # Ler primeiros 100KB
            result = chardet.detect(raw_data)

        detected_encoding = result['encoding']
        confidence = result['confidence']

        app_logger.debug(f"Encoding detectado: {detected_encoding} (confiança: {confidence:.2%})")

        return detected_encoding if confidence > 0.7 else self.encoding

    def ler_csv(
        self,
        filepath: Path,
        colunas_obrigatorias: Optional[List[str]] = None,
        auto_detect_encoding: bool = True
    ) -> pd.DataFrame:
        """
        Lê arquivo CSV com tratamento de erros

        Args:
            filepath: Caminho do arquivo
            colunas_obrigatorias: Lista de colunas que devem existir
            auto_detect_encoding: Se True, tenta detectar encoding automaticamente

        Returns:
            DataFrame carregado

        Raises:
            FileNotFoundError: Se arquivo não existe
            ValueError: Se schema inválido
        """
        if not filepath.exists():
            raise FileNotFoundError(f"Arquivo não encontrado: {filepath}")

        # Detectar encoding se solicitado
        encoding = self.detectar_encoding(filepath) if auto_detect_encoding else self.encoding

        app_logger.info(f"Lendo {filepath.name} (encoding: {encoding})")

        try:
            # Ler CSV
            df = pd.read_csv(
                filepath,
                sep=self.separator,
                encoding=encoding,
                low_memory=False,
                na_values=['', 'NA', 'N/A', 'null', '#N/D'],
                dtype=str  # Ler tudo como string primeiro
            )

            app_logger.success(f"✓ {len(df):,} linhas lidas de {filepath.name}")

            # Validar schema se necessário
            if colunas_obrigatorias:
                valido, faltando = self.validator.validar_dataframe_schema(df, colunas_obrigatorias)

                if not valido:
                    raise ValueError(
                        f"Colunas faltando em {filepath.name}: {', '.join(faltando)}"
                    )

            return df

        except UnicodeDecodeError as e:
            app_logger.error(f"Erro de encoding em {filepath.name}: {e}")
            # Tentar encoding alternativo
            app_logger.warning("Tentando encoding alternativo (latin1)...")
            return pd.read_csv(
                filepath,
                sep=self.separator,
                encoding='latin1',
                low_memory=False,
                dtype=str
            )

        except Exception as e:
            app_logger.error(f"Erro ao ler {filepath.name}: {e}")
            raise

    def ler_multiplos_csvs(
        self,
        filepaths: List[Path],
        colunas_obrigatorias: Optional[List[str]] = None
    ) -> pd.DataFrame:
        """
        Lê e concatena múltiplos CSVs (ex: BLC_1 até BLC_8)

        Args:
            filepaths: Lista de caminhos de arquivos
            colunas_obrigatorias: Colunas que devem existir

        Returns:
            DataFrame concatenado
        """
        dataframes = []

        for filepath in filepaths:
            df = self.ler_csv(filepath, colunas_obrigatorias)
            dataframes.append(df)

        if not dataframes:
            app_logger.warning("Nenhum arquivo foi lido")
            return pd.DataFrame()

        df_final = pd.concat(dataframes, ignore_index=True)
        app_logger.info(f"Total após concatenação: {len(df_final):,} linhas")

        return df_final

    def listar_arquivos_cvm(self, diretorio: Path, padrao: str) -> List[Path]:
        """
        Lista arquivos CVM em um diretório

        Args:
            diretorio: Diretório onde buscar
            padrao: Padrão glob (ex: 'cda_fi_BLC_*.csv')

        Returns:
            Lista de caminhos encontrados (ordenados)
        """
        arquivos = sorted(diretorio.glob(padrao))

        app_logger.info(f"Encontrados {len(arquivos)} arquivos com padrão '{padrao}'")

        return list(arquivos)

    def identificar_mes_competencia(self, filepath: Path) -> Optional[str]:
        """
        Extrai mês de competência do nome do arquivo

        Args:
            filepath: Caminho do arquivo

        Returns:
            Data no formato YYYY-MM-DD (último dia do mês)

        Example:
            cda_fi_BLC_1_202510.csv → 2025-10-31
        """
        import re
        from calendar import monthrange

        filename = filepath.name
        match = re.search(r'(\d{6})\.csv', filename)

        if match:
            yyyymm = match.group(1)
            year = int(yyyymm[:4])
            month = int(yyyymm[4:6])

            # Último dia do mês
            last_day = monthrange(year, month)[1]

            return f"{year:04d}-{month:02d}-{last_day:02d}"

        return None

if __name__ == '__main__':
    # Teste de leitura
    from config import DATA_DIR

    reader = CVMReader()

    # Listar arquivos
    arquivos_blc = reader.listar_arquivos_cvm(DATA_DIR, 'cda_fi_BLC_*.csv')

    if arquivos_blc:
        # Testar leitura de 1 arquivo
        df = reader.ler_csv(arquivos_blc[0])
        print(f"Shape: {df.shape}")
        print(f"Colunas: {list(df.columns[:5])}...")

        # Testar identificação de data
        data = reader.identificar_mes_competencia(arquivos_blc[0])
        print(f"Data de competência: {data}")
