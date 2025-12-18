"""
Uploader para Supabase
"""
import pandas as pd
from supabase import create_client, Client
from typing import List, Dict
from tqdm import tqdm
import time


class SupabaseUploader:
    """Gerencia upload de dados para Supabase"""

    def __init__(self, supabase_url: str, supabase_key: str, logger=None):
        """
        Inicializa uploader

        Args:
            supabase_url: URL do projeto Supabase
            supabase_key: Service role key do Supabase
            logger: Logger (opcional)
        """
        self.supabase: Client = create_client(supabase_url, supabase_key)
        self.logger = logger

    def _log(self, message: str, level: str = "info"):
        """Helper para log"""
        if self.logger:
            getattr(self.logger, level)(message)

    def upload_dataframe(self, df: pd.DataFrame, table_name: str,
                        batch_size: int = 1000, upsert: bool = False) -> int:
        """
        Faz upload de DataFrame para tabela do Supabase

        Args:
            df: DataFrame a fazer upload
            table_name: Nome da tabela de destino
            batch_size: Tamanho do lote para upload
            upsert: Se True, faz upsert; se False, faz insert

        Returns:
            Quantidade de registros inseridos
        """
        if df.empty:
            self._log(f"⚠️  DataFrame vazio para tabela {table_name}", "warning")
            return 0

        self._log(f"Iniciando upload para '{table_name}': {len(df):,} registros")

        # Converter DataFrame para lista de dicionários
        records = df.to_dict('records')

        # Limpar None, NaN, etc
        records = self._clean_records(records)

        # Upload em batches
        total_uploaded = 0
        batches = [records[i:i + batch_size] for i in range(0, len(records), batch_size)]

        with tqdm(total=len(batches), desc=f"Upload {table_name}", unit="batch") as pbar:
            for batch in batches:
                try:
                    if upsert:
                        response = self.supabase.table(table_name).upsert(batch).execute()
                    else:
                        response = self.supabase.table(table_name).insert(batch).execute()

                    total_uploaded += len(batch)
                    pbar.update(1)

                except Exception as e:
                    self._log(f"❌ Erro no upload do batch: {str(e)}", "error")
                    # Tentar upload individual para identificar registro problemático
                    self._log("Tentando upload individual...", "warning")
                    for record in batch:
                        try:
                            if upsert:
                                self.supabase.table(table_name).upsert([record]).execute()
                            else:
                                self.supabase.table(table_name).insert([record]).execute()
                            total_uploaded += 1
                        except Exception as e2:
                            self._log(f"❌ Erro no registro: {str(e2)}", "error")
                            self._log(f"   Registro: {record}", "debug")

                # Pequeno delay entre batches para não sobrecarregar
                time.sleep(0.1)

        self._log(f"✓ Upload concluído: {total_uploaded:,} registros em '{table_name}'")
        return total_uploaded

    def _clean_records(self, records: List[Dict]) -> List[Dict]:
        """
        Limpa registros antes de upload

        Args:
            records: Lista de dicionários

        Returns:
            Lista limpa
        """
        cleaned = []

        for record in records:
            clean_record = {}
            for key, value in record.items():
                # Converter tipos problemáticos
                if pd.isna(value):
                    clean_record[key] = None
                elif isinstance(value, (pd.Timestamp, pd.DatetimeTZDtype)):
                    clean_record[key] = value.isoformat() if not pd.isna(value) else None
                elif isinstance(value, (int, float, str, bool, type(None))):
                    clean_record[key] = value
                else:
                    # Tentar converter para string
                    clean_record[key] = str(value) if value is not None else None

            cleaned.append(clean_record)

        return cleaned

    def clear_table(self, table_name: str, condition: Dict = None) -> int:
        """
        Limpa dados de uma tabela

        Args:
            table_name: Nome da tabela
            condition: Condição para deletar (ex: {'ano': 2025})

        Returns:
            Quantidade de registros deletados
        """
        self._log(f"Limpando tabela '{table_name}'...", "warning")

        try:
            query = self.supabase.table(table_name).delete()

            if condition:
                for key, value in condition.items():
                    query = query.eq(key, value)

            response = query.execute()
            count = len(response.data) if response.data else 0

            self._log(f"✓ {count} registros deletados de '{table_name}'")
            return count

        except Exception as e:
            self._log(f"❌ Erro ao limpar tabela: {str(e)}", "error")
            return 0

    def execute_function(self, function_name: str, params: Dict = None) -> Dict:
        """
        Executa uma função/stored procedure do Supabase

        Args:
            function_name: Nome da função
            params: Parâmetros da função

        Returns:
            Resultado da função
        """
        self._log(f"Executando função '{function_name}'...")

        try:
            response = self.supabase.rpc(function_name, params or {}).execute()

            self._log(f"✓ Função '{function_name}' executada com sucesso")
            return response.data

        except Exception as e:
            self._log(f"❌ Erro ao executar função: {str(e)}", "error")
            raise

    def get_table_count(self, table_name: str, condition: Dict = None) -> int:
        """
        Retorna quantidade de registros em uma tabela

        Args:
            table_name: Nome da tabela
            condition: Condição de filtro (opcional)

        Returns:
            Quantidade de registros
        """
        try:
            query = self.supabase.table(table_name).select("*", count="exact")

            if condition:
                for key, value in condition.items():
                    query = query.eq(key, value)

            response = query.execute()
            return response.count if hasattr(response, 'count') else 0

        except Exception as e:
            self._log(f"❌ Erro ao contar registros: {str(e)}", "error")
            return 0

    def upsert_patrimonio_liquido_top100(self, df: pd.DataFrame, batch_size: int = 1000) -> Dict:
        """
        Faz upsert de patrimônio líquido usando stored procedure
        Converte dados flat em modelo dimensional automaticamente

        Args:
            df: DataFrame com colunas: cnpj_fundo, nome_fundo, grupo_economico, data_competencia, valor_pl
            batch_size: Tamanho do lote

        Returns:
            Dict com estatísticas
        """
        if df.empty:
            self._log("⚠️  DataFrame vazio para patrimônio líquido", "warning")
            return {'inserted': 0, 'updated': 0, 'ignored': 0}

        self._log(f"Iniciando upsert de PL: {len(df):,} registros")

        total_inserted = 0
        total_updated = 0
        total_ignored = 0

        # Processar em batches
        batches = [df.iloc[i:i + batch_size] for i in range(0, len(df), batch_size)]

        with tqdm(total=len(batches), desc="Upsert PL", unit="batch") as pbar:
            for batch_df in batches:
                try:
                    # Converter DataFrame para JSON (array de objetos)
                    records = batch_df.to_dict('records')

                    # Converter valores para string para JSONB
                    for record in records:
                        # Garantir formato correto de data
                        if isinstance(record.get('data_competencia'), pd.Timestamp):
                            record['data_competencia'] = record['data_competencia'].strftime('%Y-%m-%d')
                        # Converter valor_pl para string
                        if 'valor_pl' in record and not pd.isna(record['valor_pl']):
                            record['valor_pl'] = str(record['valor_pl'])
                        else:
                            record['valor_pl'] = '0'

                    # Chamar stored procedure
                    response = self.supabase.rpc(
                        'upsert_patrimonio_liquido_top100',
                        {'p_dados': records}
                    ).execute()

                    # Processar resultado
                    if response.data and len(response.data) > 0:
                        result = response.data[0]
                        total_inserted += result.get('registros_inseridos', 0)
                        total_updated += result.get('registros_atualizados', 0)
                        total_ignored += result.get('registros_ignorados', 0)

                    pbar.update(1)
                    time.sleep(0.1)

                except Exception as e:
                    self._log(f"❌ Erro no batch: {str(e)}", "error")
                    total_ignored += len(batch_df)

        self._log(f"✓ Upsert PL concluído:")
        self._log(f"  • Inseridos: {total_inserted:,}")
        self._log(f"  • Atualizados: {total_updated:,}")
        self._log(f"  • Ignorados: {total_ignored:,}")

        return {
            'inserted': total_inserted,
            'updated': total_updated,
            'ignored': total_ignored
        }
