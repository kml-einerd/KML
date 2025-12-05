"""
Processador de arquivos individuais da CVM
"""

import pandas as pd
from pathlib import Path
from typing import Dict, List

from config import (
    identificar_tabela_por_arquivo,
    extrair_mes_referencia,
    COLUMN_MAPPING,
    CVM_ENCODING,
    CVM_SEPARATOR
)
from processors.csv_reader import CVMReader
from processors.data_cleaner import DataCleaner
from utils.logger import app_logger

class FileProcessor:
    """Processa arquivos CSV individuais da CVM"""
    
    def __init__(self):
        self.reader = CVMReader()
        self.cleaner = DataCleaner()
    
    def processar_arquivo(self, arquivo_path: Path, lista_grandes_fundos: List[str] = None) -> Dict:
        """
        Processa um único arquivo CSV
        
        Args:
            arquivo_path: Caminho do arquivo
            lista_grandes_fundos: Lista de CNPJs dos grandes fundos (opcional)
            
        Returns:
            Dicionário com informações do processamento:
            {
                'tabela': nome da tabela de destino,
                'dados': DataFrame processado,
                'mes_referencia': data de referência,
                'total_registros': quantidade de registros
            }
        """
        nome_arquivo = arquivo_path.name
        
        # Identificar tabela de destino
        tabela_destino = identificar_tabela_por_arquivo(nome_arquivo)
        if not tabela_destino:
            app_logger.warning(f"Arquivo não reconhecido: {nome_arquivo}")
            return None
        
        # Extrair mês de referência
        mes_referencia = extrair_mes_referencia(nome_arquivo)
        
        app_logger.info(f"Processando {nome_arquivo} -> {tabela_destino}")
        
        try:
            # Ler arquivo
            df = pd.read_csv(
                arquivo_path,
                encoding=CVM_ENCODING,
                sep=CVM_SEPARATOR,
                dtype=str  # Ler tudo como string primeiro
            )
            
            # Limpar dados
            df_limpo = self.cleaner.limpar_dataframe_balancete(df)
            
            # Aplicar correção de texto
            df_corrigido = self.cleaner.aplicar_correcao_texto(df_limpo)
            
            # Filtrar apenas grandes fundos (se lista fornecida)
            if lista_grandes_fundos is not None and 'CNPJ_FUNDO_CLASSE' in df_corrigido.columns:
                df_filtrado = df_corrigido[
                    df_corrigido['CNPJ_FUNDO_CLASSE'].isin(lista_grandes_fundos)
                ]
            else:
                df_filtrado = df_corrigido
            
            # Adicionar coluna de mês de referência
            df_filtrado['MES_REFERENCIA'] = mes_referencia
            
            # Renomear colunas para snake_case (para o Supabase)
            df_final = self.renomear_colunas(df_filtrado)
            
            return {
                'tabela': tabela_destino,
                'dados': df_final,
                'mes_referencia': mes_referencia,
                'total_registros': len(df_final)
            }
            
        except Exception as e:
            app_logger.error(f"Erro ao processar {nome_arquivo}: {e}")
            return None
    
    def renomear_colunas(self, df: pd.DataFrame) -> pd.DataFrame:
        """
        Renomeia colunas do DataFrame para o padrão do banco (snake_case)
        
        Args:
            df: DataFrame com colunas originais
            
        Returns:
            DataFrame com colunas renomeadas
        """
        # Criar mapeamento apenas para colunas que existem no DataFrame
        mapeamento_atual = {
            col: COLUMN_MAPPING.get(col, col.lower())
            for col in df.columns
            if col in COLUMN_MAPPING or col == 'MES_REFERENCIA'
        }
        
        # Adicionar mapeamento para MES_REFERENCIA
        if 'MES_REFERENCIA' in df.columns:
            mapeamento_atual['MES_REFERENCIA'] = 'mes_referencia'
        
        return df.rename(columns=mapeamento_atual)
