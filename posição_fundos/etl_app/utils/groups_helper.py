"""
Helper para identificar e trabalhar com grupos econômicos
"""
import pandas as pd
import re
from typing import List, Dict


class GroupsHelper:
    """Classe para identificar grupos econômicos dos fundos"""

    # Mapeamento de padrões para grupos conhecidos
    KNOWN_GROUPS = {
        'BTG PACTUAL': ['BTG', 'PACTUAL'],
        'ITAÚ': ['ITAU', 'ITAÚ'],
        'BRADESCO': ['BRADESCO'],
        'XP': ['XP INV', 'XP ASSET'],
        'SANTANDER': ['SANTANDER'],
        'BANCO DO BRASIL': ['BB ', 'BANCO DO BRASIL'],
        'CAIXA': ['CAIXA ECONÔMICA', 'CAIXA ECONOMICA'],
        'SAFRA': ['SAFRA'],
        'VOTORANTIM': ['VOTORANTIM'],
        'ICATU': ['ICATU'],
        'SUL AMERICA': ['SUL AMERICA', 'SULAMERICA'],
        'BRADESCO SEGUROS': ['BRADESCO VIDA', 'BRADESCO PREVIDENCIA'],
        'CIELO': ['CIELO'],
    }

    @staticmethod
    def clean_name(nome: str) -> str:
        """
        Limpa o nome do fundo para facilitar identificação

        Args:
            nome: Nome original do fundo

        Returns:
            Nome limpo
        """
        if pd.isna(nome):
            return ""

        nome = str(nome).upper()
        # Remove caracteres especiais e múltiplos espaços
        nome = re.sub(r'[^\w\s]', ' ', nome)
        nome = re.sub(r'\s+', ' ', nome)
        return nome.strip()

    @classmethod
    def identify_group(cls, nome_fundo: str) -> str:
        """
        Identifica o grupo econômico do fundo

        Args:
            nome_fundo: Nome do fundo

        Returns:
            Nome do grupo econômico identificado
        """
        nome_clean = cls.clean_name(nome_fundo)

        # Tentar identificar por padrões conhecidos
        for group_name, patterns in cls.KNOWN_GROUPS.items():
            for pattern in patterns:
                if pattern in nome_clean:
                    return group_name

        # Se não identificou, pega as primeiras palavras significativas
        words = nome_clean.split()
        if len(words) >= 2:
            # Ignora palavras genéricas
            generic_words = {'FUNDO', 'INVESTIMENTO', 'FINANCEIRO', 'FI', 'FIF',
                           'RENDA', 'FIXA', 'ACOES', 'MULTIMERCADO', 'CREDITO',
                           'PRIVADO', 'CLASSE', 'RESPONSABILIDADE', 'LIMITADA'}

            significant_words = [w for w in words[:5] if w not in generic_words and len(w) > 2]
            if significant_words:
                return ' '.join(significant_words[:2])

        return nome_clean.split()[0] if words else 'OUTROS'

    @staticmethod
    def calculate_top_groups(df_pl: pd.DataFrame, top_n: int = 100) -> List[str]:
        """
        Calcula os Top N grupos por patrimônio líquido

        Args:
            df_pl: DataFrame com dados de PL (deve ter 'grupo_economico' e 'VL_PATRIM_LIQ')
            top_n: Quantidade de grupos no topo

        Returns:
            Lista com nomes dos Top N grupos
        """
        # Agregar PL por grupo
        pl_por_grupo = df_pl.groupby('grupo_economico')['VL_PATRIM_LIQ'].sum().reset_index()
        pl_por_grupo = pl_por_grupo.sort_values('VL_PATRIM_LIQ', ascending=False)

        # Retornar Top N
        top_groups = pl_por_grupo.head(top_n)['grupo_economico'].tolist()

        return top_groups

    @staticmethod
    def filter_top_groups_data(df: pd.DataFrame, top_groups: List[str],
                               group_column: str = 'grupo_economico') -> pd.DataFrame:
        """
        Filtra DataFrame para manter apenas dados dos Top grupos

        Args:
            df: DataFrame a filtrar
            top_groups: Lista de grupos top
            group_column: Nome da coluna de grupo

        Returns:
            DataFrame filtrado
        """
        return df[df[group_column].isin(top_groups)].copy()
