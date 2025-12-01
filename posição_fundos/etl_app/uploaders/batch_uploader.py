"""
Upload em lotes para Supabase
"""

from typing import List, Dict
import pandas as pd
from config import BATCH_SIZE
from utils.logger import app_logger
from utils.progress import ProgressTracker
from .supabase_client import SupabaseClient

class BatchUploader:
    """Gerencia upload em lotes com progresso"""

    def __init__(self, supabase_client: SupabaseClient):
        self.client = supabase_client
        self.batch_size = BATCH_SIZE

    @staticmethod
    def limpar_valores_nulos(data: List[Dict]) -> List[Dict]:
        """
        Remove valores None, NaN e infinitos dos dicionários

        Args:
            data: Lista de dicionários

        Returns:
            Lista de dicionários limpa
        """
        dados_limpos = []
        for item in data:
            item_limpo = {}
            for key, value in item.items():
                # Pular valores None
                if value is None:
                    continue

                # Tratar valores pandas NaN/NaT
                if pd.isna(value):
                    continue

                # Converter numpy types para tipos Python nativos
                if hasattr(value, 'item'):  # numpy types
                    value = value.item()

                # Verificar infinitos em floats
                if isinstance(value, float):
                    if not (-1e308 < value < 1e308):  # Infinito ou muito grande
                        continue

                item_limpo[key] = value

            if item_limpo:  # Só adicionar se não estiver vazio
                dados_limpos.append(item_limpo)

        return dados_limpos

    @staticmethod
    def normalizar_chaves(data: List[Dict]) -> List[Dict]:
        """
        Normaliza objetos para que todos tenham as mesmas chaves.
        Necessário porque o PostgREST exige que todos os objetos em um lote
        tenham exatamente os mesmos campos.

        Args:
            data: Lista de dicionários

        Returns:
            Lista normalizada
        """
        if not data:
            return data

        # Coletar todas as chaves únicas
        todas_chaves = set()
        for item in data:
            todas_chaves.update(item.keys())

        # Normalizar cada objeto para ter todas as chaves
        dados_normalizados = []
        for item in data:
            item_normalizado = {}
            for chave in todas_chaves:
                item_normalizado[chave] = item.get(chave, None)
            dados_normalizados.append(item_normalizado)

        return dados_normalizados

    def dividir_em_lotes(self, data: List[Dict], batch_size: int = None) -> List[List[Dict]]:
        """
        Divide lista em lotes

        Args:
            data: Lista completa
            batch_size: Tamanho do lote (usa BATCH_SIZE se None)

        Returns:
            Lista de lotes
        """
        if batch_size is None:
            batch_size = self.batch_size

        lotes = []
        for i in range(0, len(data), batch_size):
            lotes.append(data[i:i + batch_size])

        return lotes

    def upload_com_progresso(
        self,
        table: str,
        data: List[Dict],
        on_conflict: str = None,
        descricao: str = None,
        return_ids: bool = False
    ) -> Dict:
        """
        Faz upload em lotes com barra de progresso
        
        Args:
            table: Nome da tabela
            data: Lista de registros
            on_conflict: Coluna de conflito para upsert
            descricao: Descrição para progress bar
            return_ids: Se True, retorna lista de IDs inseridos/atualizados
            
        Returns:
            Dicionário com estatísticas e 'ids' (se solicitado)
        """
        if not data:
            app_logger.warning(f"Nenhum dado para upload em '{table}'")
            return {'total': 0, 'sucesso': 0, 'erros': 0, 'ids': []}

        # Limpar valores nulos antes do upload
        data = self.limpar_valores_nulos(data)

        if not data:
            app_logger.warning(f"Nenhum dado válido após limpeza em '{table}'")
            return {'total': 0, 'sucesso': 0, 'erros': 0, 'ids': []}

        # Normalizar chaves para que todos os objetos tenham os mesmos campos
        data = self.normalizar_chaves(data)

        if descricao is None:
            descricao = f"Uploading {table}"

        # Dividir em lotes
        lotes = self.dividir_em_lotes(data)
        
        app_logger.info(
            f"Iniciando upload para '{table}': "
            f"{len(data):,} registros em {len(lotes)} lotes"
        )
        
        # Contadores e resultados
        total = 0
        sucesso = 0
        erros = 0
        ids_retornados = []
        
        # Upload com progresso
        with ProgressTracker() as progress:
            task = progress.add_task(descricao, total=len(lotes))
            
            for i, lote in enumerate(lotes, 1):
                try:
                    # Fazer upsert - o upsert JÁ RETORNA os dados por padrão na versão 1.0.3
                    response = self.client.client.table(table)\
                        .upsert(lote, on_conflict=on_conflict)\
                        .execute()

                    # Se precisamos dos IDs, extrair da response que já tem os dados
                    if return_ids and hasattr(response, 'data') and response.data:
                        ids_retornados.extend([item.get('id') for item in response.data if 'id' in item])

                    sucesso += len(lote)
                except Exception as e:
                    app_logger.error(f"Erro no lote {i}: {e}")
                    erros += len(lote)
                    
                total += len(lote)
                progress.advance(task)
                
        # Resumo
        taxa_sucesso = (sucesso / total * 100) if total > 0 else 0
        
        app_logger.info(
            f"✓ Upload '{table}' concluído: "
            f"{sucesso:,}/{total:,} sucesso ({taxa_sucesso:.1f}%), "
            f"{erros:,} erros"
        )
        
        result = {
            'table': table,
            'total': total,
            'sucesso': sucesso,
            'erros': erros,
            'taxa_sucesso': taxa_sucesso
        }
        
        if return_ids:
            result['ids'] = ids_retornados
            
        return result

    def upload_multiplas_tabelas(
        self,
        uploads: List[Dict]
    ) -> List[Dict]:
        """
        Faz upload em múltiplas tabelas sequencialmente

        Args:
            uploads: Lista de dicionários {table, data, on_conflict, descricao}

        Returns:
            Lista de resultados

        Example:
            uploads = [
                {'table': 'fundos', 'data': df_fundos.to_dict('records'), 'on_conflict': 'cnpj'},
                {'table': 'posicoes_acoes', 'data': df_posicoes.to_dict('records')}
            ]
        """
        resultados = []

        for upload_config in uploads:
            resultado = self.upload_com_progresso(**upload_config)
            resultados.append(resultado)

        # Resumo geral
        total_geral = sum(r['total'] for r in resultados)
        sucesso_geral = sum(r['sucesso'] for r in resultados)
        erros_geral = sum(r['erros'] for r in resultados)

        app_logger.success(
            f"\\n✓ Upload completo: "
            f"{sucesso_geral:,}/{total_geral:,} registros enviados, "
            f"{erros_geral:,} erros"
        )

        return resultados

if __name__ == '__main__':
    # Teste de upload
    from processors.aggregations import DataAggregator

    # Criar dados de teste
    import pandas as pd
    df_test = pd.DataFrame({
        'cnpj': ['11111111111111', '22222222222222'],
        'nome_fundo': ['Fundo Teste 1', 'Fundo Teste 2'],
        'pl_atual': [100_000_000, 200_000_000],
        'is_grande_fundo': [True, True]
    })

    # Preparar para Supabase
    data = DataAggregator.preparar_para_supabase(df_test, 'fundos')

    # Upload (comentado para não executar acidentalmente)
    # client = SupabaseClient()
    # uploader = BatchUploader(client)
    # resultado = uploader.upload_com_progresso('fundos', data, on_conflict='cnpj')
    # print(resultado)
