"""
Processador de Grupos Econômicos
Identifica Top 100 grupos a partir dos dados de PL
"""

import pandas as pd
import re
from pathlib import Path


class GruposProcessor:
    """Processa PL e identifica Top 100 grupos"""

    # Mapeamento de padrões para grupos conhecidos
    GRUPOS_CONHECIDOS = {
        'ITAU': 'Itaú',
        'ITAÚ': 'Itaú',
        'BRADESCO': 'Bradesco',
        'BANCO DO BRASIL': 'Banco do Brasil',
        'BB ': 'Banco do Brasil',
        'SANTANDER': 'Santander',
        'CAIXA': 'Caixa Econômica',
        'SAFRA': 'Safra',
        'BTG': 'BTG Pactual',
        'XP': 'XP Investimentos',
        'BRASILPREV': 'Brasilprev',
        'WESTERN': 'Western Asset',
        'ALASKA': 'Alaska',
        'VITREO': 'Vitreo',
        'GENIAL': 'Genial',
        'INTER': 'Inter',
        'NUBANK': 'Nubank',
        'VOTORANTIM': 'Votorantim',
        'SICREDI': 'Sicredi',
    }

    def __init__(self, logger=None):
        self.logger = logger

    def _log(self, msg: str):
        """Helper para log"""
        if self.logger:
            self.logger.info(msg)
        else:
            print(f"[GruposProcessor] {msg}")

    def identificar_grupo(self, nome_fundo: str) -> str:
        """
        Identifica grupo econômico a partir do nome do fundo

        Args:
            nome_fundo: Nome completo do fundo

        Returns:
            Nome do grupo identificado
        """
        nome_upper = nome_fundo.upper()

        # Tentar encontrar grupo conhecido
        for padrao, grupo in self.GRUPOS_CONHECIDOS.items():
            if padrao in nome_upper:
                return grupo

        # Se não encontrou, extrair primeira palavra significativa
        # Remove palavras comuns
        palavras_remover = [
            'FUNDO', 'FI', 'FIC', 'FIF', 'FIDC', 'INVESTIMENTO',
            'CLASSE', 'CLASSES', 'DE', 'EM', 'DA', 'DO', 'E'
        ]

        palavras = nome_upper.split()
        for palavra in palavras:
            # Limpar caracteres especiais
            palavra_limpa = re.sub(r'[^A-Z0-9]', '', palavra)

            if len(palavra_limpa) >= 3 and palavra_limpa not in palavras_remover:
                return palavra_limpa.title()

        # Fallback: usar primeira palavra
        return palavras[0].title() if palavras else 'DESCONHECIDO'

    def processar(self, arquivo_pl: str, top_n: int = 100) -> tuple:
        """
        Processa arquivo de PL e identifica Top N grupos

        Args:
            arquivo_pl: Caminho para arquivo cda_fi_PL_*.csv
            top_n: Quantidade de grupos no ranking

        Returns:
            Tuple (df_grupos_top, dict_mapeamento_cnpj_grupo)
        """
        self._log(f"Processando {arquivo_pl}...")

        # Ler CSV (encoding pode variar)
        try:
            df = pd.read_csv(arquivo_pl, sep=';', encoding='utf-8')
        except UnicodeDecodeError:
            df = pd.read_csv(arquivo_pl, sep=';', encoding='latin1')

        self._log(f"  Lidos {len(df):,} fundos")

        # Identificar grupos
        df['grupo_economico'] = df['DENOM_SOCIAL'].apply(self.identificar_grupo)

        # Converter PL para numérico
        df['VL_PATRIM_LIQ'] = pd.to_numeric(
            df['VL_PATRIM_LIQ'].astype(str).str.replace(',', '.'),
            errors='coerce'
        )

        # Agregar por grupo
        grupos_agg = df.groupby('grupo_economico').agg({
            'CNPJ_FUNDO_CLASSE': 'count',
            'VL_PATRIM_LIQ': 'sum'
        }).reset_index()

        grupos_agg.columns = ['nome_grupo', 'qtd_fundos', 'pl_total']

        # Converter PL para bilhões
        grupos_agg['pl_total_bilhoes'] = grupos_agg['pl_total'] / 1_000_000_000

        # Ordenar por PL e pegar Top N
        grupos_agg = grupos_agg.sort_values('pl_total', ascending=False)
        top_grupos = grupos_agg.head(top_n).copy()

        self._log(f"  Identificados {len(grupos_agg):,} grupos únicos")
        self._log(f"  Top {top_n} grupos por PL")

        # Criar mapeamento CNPJ → Grupo (apenas Top N)
        grupos_top_set = set(top_grupos['nome_grupo'])
        mapeamento = {}

        for _, row in df.iterrows():
            grupo = row['grupo_economico']
            if grupo in grupos_top_set:
                cnpj = row['CNPJ_FUNDO_CLASSE']
                mapeamento[cnpj] = grupo

        self._log(f"  Mapeados {len(mapeamento):,} CNPJs para Top {top_n}")

        # Converter tipos para compatibilidade com Supabase
        resultado = top_grupos[['nome_grupo', 'qtd_fundos', 'pl_total_bilhoes']].copy()
        resultado['qtd_fundos'] = resultado['qtd_fundos'].astype(int)
        resultado['pl_total_bilhoes'] = resultado['pl_total_bilhoes'].round(2)

        return resultado, mapeamento

    def get_stats(self, df_grupos: pd.DataFrame) -> dict:
        """Retorna estatísticas dos grupos"""
        return {
            'total_grupos': len(df_grupos),
            'pl_total_bilhoes': df_grupos['pl_total_bilhoes'].sum(),
            'pl_medio_bilhoes': df_grupos['pl_total_bilhoes'].mean(),
            'maior_grupo': df_grupos.iloc[0]['nome_grupo'],
            'maior_pl_bilhoes': df_grupos.iloc[0]['pl_total_bilhoes'],
        }
