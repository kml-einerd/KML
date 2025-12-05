"""
Correção ortográfica e padronização de texto
"""

from thefuzz import fuzz, process
import re

class TextCorrector:
    """Corrige e padroniza textos de fundos e emissores"""
    
    def __init__(self):
        # Cache de nomes já corrigidos
        self.cache_nomes = {}
    
    def limpar_texto(self, texto: str) -> str:
        """
        Remove caracteres especiais e padroniza espaços
        
        Args:
            texto: Texto a ser limpo
            
        Returns:
            Texto limpo e padronizado
        """
        if not isinstance(texto, str):
            return texto
        
        # Remover espaços múltiplos
        texto = re.sub(r'\s+', ' ', texto)
        
        # Remover espaços no início e fim
        texto = texto.strip()
        
        # Converter para maiúsculas (padronização)
        texto = texto.upper()
        
        return texto
    
    def corrigir_nome_fundo(self, nome: str) -> str:
        """
        Corrige e padroniza nome de fundo
        
        Args:
            nome: Nome do fundo
            
        Returns:
            Nome corrigido
        """
        if not isinstance(nome, str) or not nome:
            return nome
        
        # Verificar cache
        if nome in self.cache_nomes:
            return self.cache_nomes[nome]
        
        # Limpar texto
        nome_limpo = self.limpar_texto(nome)
        
        # Armazenar no cache
        self.cache_nomes[nome] = nome_limpo
        
        return nome_limpo
    
    def corrigir_nome_emissor(self, emissor: str) -> str:
        """
        Corrige e padroniza nome de emissor
        
        Args:
            emissor: Nome do emissor
            
        Returns:
            Nome corrigido
        """
        if not isinstance(emissor, str) or not emissor:
            return emissor
        
        # Verificar cache
        if emissor in self.cache_nomes:
            return self.cache_nomes[emissor]
        
        # Limpar texto
        emissor_limpo = self.limpar_texto(emissor)
        
        # Armazenar no cache
        self.cache_nomes[emissor] = emissor_limpo
        
        return emissor_limpo
