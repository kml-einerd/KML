"""
Módulo de processadores de CSVs da CVM
"""
from .patrimonio_processor import PatrimonioProcessor
from .acoes_processor import AcoesProcessor
from .cadastro_processor import CadastroProcessor

__all__ = ['PatrimonioProcessor', 'AcoesProcessor', 'CadastroProcessor']
