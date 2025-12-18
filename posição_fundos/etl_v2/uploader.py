"""
Uploader para Supabase
Upload simplificado das 3 tabelas
"""

import pandas as pd
from supabase import create_client, Client
from typing import Dict
from rich.progress import track


class SupabaseUploader:
    """Gerencia upload para Supabase"""

    def __init__(self, url: str, key: str, logger=None):
        self.client: Client = create_client(url, key)
        self.logger = logger

    def _log(self, msg: str):
        """Helper para log"""
        if self.logger:
            self.logger.info(msg)
        else:
            print(f"[Uploader] {msg}")

    def limpar_mes(self, mes_referencia: str):
        """Limpa dados de um mês específico"""
        self._log(f"Limpando dados de {mes_referencia}...")

        # Limpar acoes_fundos
        self.client.table('acoes_fundos').delete().eq('mes_referencia', mes_referencia).execute()

        # Limpar resumo_mensal
        self.client.table('resumo_mensal').delete().eq('mes_referencia', mes_referencia).execute()

        self._log("  Dados antigos removidos")

    def upsert_grupos(self, df_grupos: pd.DataFrame) -> int:
        """
        Faz upsert de grupos (insert ou update)

        Args:
            df_grupos: DataFrame com colunas: nome_grupo, qtd_fundos, pl_total_bilhoes

        Returns:
            Quantidade de grupos inseridos/atualizados
        """
        self._log(f"Upload de {len(df_grupos)} grupos...")

        records = df_grupos.to_dict('records')

        # Limpar valores None/NaN e garantir tipos corretos
        for record in records:
            for key, value in record.items():
                if pd.isna(value):
                    record[key] = None
                elif key == 'qtd_fundos':
                    # qtd_fundos deve ser INTEGER
                    record[key] = int(value)
                elif key == 'pl_total_bilhoes':
                    # pl_total_bilhoes deve ser DECIMAL (float é ok)
                    record[key] = float(value)

        # Upsert (on_conflict atualiza se já existe)
        response = self.client.table('grupos_fundos').upsert(
            records,
            on_conflict='nome_grupo'
        ).execute()

        self._log(f"  ✓ {len(response.data)} grupos processados")
        return len(response.data)

    def upload_acoes(self, df_acoes: pd.DataFrame, batch_size: int = 1000) -> int:
        """
        Faz upload de ações em batches

        Args:
            df_acoes: DataFrame com movimentos de ações
            batch_size: Tamanho do lote

        Returns:
            Quantidade de registros inseridos
        """
        if df_acoes.empty:
            self._log("  Nenhuma ação para processar")
            return 0

        self._log(f"Upload de {len(df_acoes):,} movimentos de ações...")

        # Buscar IDs dos grupos
        grupos_response = self.client.table('grupos_fundos').select('id, nome_grupo').execute()
        grupos_map = {g['nome_grupo']: g['id'] for g in grupos_response.data}

        # Adicionar grupo_id
        df_acoes['grupo_id'] = df_acoes['grupo_economico'].map(grupos_map)

        # Remover registros sem grupo_id (não deveriam existir)
        df_acoes = df_acoes[df_acoes['grupo_id'].notna()].copy()

        # Selecionar colunas
        colunas = [
            'mes_referencia', 'grupo_id', 'ticker', 'empresa',
            'qtd_comprada', 'valor_comprado', 'qtd_vendida', 'valor_vendido',
            'posicao_final', 'valor_mercado', 'valor_custo',
            'tipo_movimento', 'rentabilidade_pct'
        ]

        df_upload = df_acoes[colunas].copy()

        # Converter para records
        records = df_upload.to_dict('records')

        # Limpar None/NaN e garantir tipos corretos
        for record in records:
            for key, value in record.items():
                if pd.isna(value):
                    record[key] = None
                elif key == 'grupo_id':
                    # grupo_id deve ser INTEGER
                    record[key] = int(value)
                elif key in ['ticker', 'empresa', 'mes_referencia', 'tipo_movimento']:
                    # Campos de texto/data - manter como estão
                    record[key] = str(value) if value is not None else None
                elif isinstance(value, (float, int)):
                    # Campos numéricos (DECIMAL) - converter para float
                    record[key] = float(value)

        # Upload em batches
        total = 0
        batches = [records[i:i + batch_size] for i in range(0, len(records), batch_size)]

        for batch in track(batches, description="  Upload ações"):
            try:
                response = self.client.table('acoes_fundos').insert(batch).execute()
                total += len(response.data)
            except Exception as e:
                self._log(f"    Erro no batch: {str(e)}")

        self._log(f"  ✓ {total:,} ações carregadas")
        return total

    def atualizar_resumo(self, mes_referencia: str) -> int:
        """
        Chama função do Supabase para calcular resumo mensal

        Args:
            mes_referencia: Data de referência

        Returns:
            Quantidade de tickers processados
        """
        self._log(f"Calculando resumo mensal para {mes_referencia}...")

        try:
            response = self.client.rpc(
                'atualizar_resumo_mensal',
                {'p_mes_ref': mes_referencia}
            ).execute()

            count = response.data if response.data else 0
            self._log(f"  ✓ Resumo calculado para {count} tickers")
            return count

        except Exception as e:
            self._log(f"  ❌ Erro ao calcular resumo: {str(e)}")
            return 0

    def verificar_dados(self, mes_referencia: str = None) -> Dict:
        """Verifica quantidade de dados carregados"""
        stats = {}

        # Contar grupos
        resp = self.client.table('grupos_fundos').select('*', count='exact').execute()
        stats['grupos'] = resp.count

        # Contar ações
        query = self.client.table('acoes_fundos').select('*', count='exact')
        if mes_referencia:
            query = query.eq('mes_referencia', mes_referencia)
        resp = query.execute()
        stats['acoes'] = resp.count

        # Contar resumo
        query = self.client.table('resumo_mensal').select('*', count='exact')
        if mes_referencia:
            query = query.eq('mes_referencia', mes_referencia)
        resp = query.execute()
        stats['resumo'] = resp.count

        return stats
