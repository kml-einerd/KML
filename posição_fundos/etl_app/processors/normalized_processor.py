"""
Processador Normalizado para ETL
"""

import pandas as pd
from pathlib import Path
from typing import Dict, List, Tuple, Any
from rich.progress import Progress

from config import (
    CVM_ENCODING,
    CVM_SEPARATOR,
    identificar_tabela_por_arquivo,
    extrair_mes_referencia,
    COLUMN_MAPPING
)
from processors.data_cleaner import DataCleaner
from utils.logger import app_logger

class NormalizedProcessor:
    """Processador para o esquema normalizado"""
    
    def __init__(self):
        self.cleaner = DataCleaner()
        
    def ler_e_concatenar_todos_os_arquivos(self, pasta_path: Path) -> pd.DataFrame:
        """
        Lê todos os arquivos CSV da pasta e concatena em um único DataFrame
        
        Args:
            pasta_path: Caminho da pasta com os CSVs
            
        Returns:
            DataFrame concatenado com coluna 'origem_arquivo' e 'tabela_origem'
        """
        todos_arquivos = list(pasta_path.glob('*.csv'))
        dfs = []
        
        app_logger.info(f"Lendo {len(todos_arquivos)} arquivos em {pasta_path}...")
        
        for arquivo in todos_arquivos:
            try:
                tabela = identificar_tabela_por_arquivo(arquivo.name)
                mes_ref = extrair_mes_referencia(arquivo.name)

                # Ler CSV com tratamento robusto de erros
                try:
                    # Primeira tentativa: leitura normal
                    df = pd.read_csv(
                        arquivo,
                        encoding=CVM_ENCODING,
                        sep=CVM_SEPARATOR,
                        dtype=str,
                        low_memory=False
                    )
                except Exception as e1:
                    # Segunda tentativa: com engine Python e tratamento de linhas ruins
                    app_logger.warning(f"Erro na primeira tentativa para {arquivo.name}, tentando modo robusto...")
                    try:
                        df = pd.read_csv(
                            arquivo,
                            encoding=CVM_ENCODING,
                            sep=CVM_SEPARATOR,
                            dtype=str,
                            engine='python',
                            on_bad_lines='skip',
                            quoting=1  # QUOTE_MINIMAL
                            # Nota: low_memory não é compatível com engine='python'
                        )
                        app_logger.warning(f"✓ Arquivo {arquivo.name} lido com modo robusto (algumas linhas podem ter sido ignoradas)")
                    except Exception as e2:
                        app_logger.error(f"Falha ao ler {arquivo.name} mesmo em modo robusto: {e2}")
                        continue

                # Adicionar metadados
                df['origem_arquivo'] = arquivo.name
                df['tabela_origem'] = tabela
                df['mes_referencia'] = mes_ref

                dfs.append(df)
                app_logger.info(f"✓ {arquivo.name}: {len(df):,} registros")

            except Exception as e:
                app_logger.error(f"Erro fatal ao processar {arquivo.name}: {e}")
        
        if not dfs:
            return pd.DataFrame()
            
        # Concatenar tudo
        app_logger.info("Concatenando DataFrames...")
        df_gigante = pd.concat(dfs, ignore_index=True)
        
        return df_gigante

    def limpar_dados(self, df: pd.DataFrame) -> pd.DataFrame:
        """
        Aplica limpeza e normalização no DataFrame gigante
        """
        app_logger.info("Limpando dados...")
        
        # Renomear colunas para snake_case (usando o mapeamento existente)
        # Primeiro, identificar quais colunas do mapeamento existem no DF
        cols_to_rename = {k: v for k, v in COLUMN_MAPPING.items() if k in df.columns}
        df = df.rename(columns=cols_to_rename)
        
        # Aplicar correções do DataCleaner
        # Como o DataCleaner espera nomes de colunas específicos (alguns originais, alguns processados),
        # vamos adaptar ou usar métodos específicos.
        
        # Limpar CNPJs
        if 'cnpj_fundo_classe' in df.columns:
            df['cnpj_fundo_classe'] = df['cnpj_fundo_classe'].apply(self.cleaner.limpar_cnpj)
        
        if 'cnpj_emissor' in df.columns:
            df['cnpj_emissor'] = df['cnpj_emissor'].apply(self.cleaner.limpar_cnpj)
            
        if 'cpf_cnpj_emissor' in df.columns:
            df['cpf_cnpj_emissor'] = df['cpf_cnpj_emissor'].apply(self.cleaner.limpar_cnpj)

        # Normalizar datas (dt_comptc)
        if 'dt_comptc' in df.columns:
            df['dt_comptc'] = df['dt_comptc'].apply(self.cleaner.converter_data_brasileira)
            
        # Converter valores numéricos importantes
        cols_numericas = [
            'vl_patrim_liq', 'qt_pos_final', 'vl_merc_pos_final', 
            'vl_custo_pos_final', 'vl_aquis_negoc', 'vl_venda_negoc'
        ]
        
        for col in cols_numericas:
            if col in df.columns:
                df[col] = df[col].apply(self.cleaner.converter_decimal)

        # Correção ortográfica (thefuzz)
        # Isso pode ser lento em DFs gigantes, então aplicamos apenas em valores únicos e mapeamos de volta
        if 'denom_social' in df.columns:
            app_logger.info("Aplicando correção ortográfica em nomes de fundos...")
            nomes_unicos = df['denom_social'].unique()
            mapa_nomes = {nome: self.cleaner.text_corrector.corrigir_nome_fundo(nome) for nome in nomes_unicos if pd.notna(nome)}
            df['denom_social'] = df['denom_social'].map(lambda x: mapa_nomes.get(x, x))
            
        if 'emissor' in df.columns:
            app_logger.info("Aplicando correção ortográfica em emissores...")
            emissores_unicos = df['emissor'].unique()
            mapa_emissores = {nome: self.cleaner.text_corrector.corrigir_nome_emissor(nome) for nome in emissores_unicos if pd.notna(nome)}
            df['emissor'] = df['emissor'].map(lambda x: mapa_emissores.get(x, x))

        return df

    def preparar_tabela_fundos(self, df: pd.DataFrame) -> List[Dict]:
        """Extrai dados únicos para tabela fundos"""
        if 'cnpj_fundo_classe' not in df.columns or 'denom_social' not in df.columns:
            app_logger.warning("Colunas necessárias para fundos não encontradas")
            return []

        # Selecionar colunas, incluindo tp_fundo_classe se existir
        colunas = ['cnpj_fundo_classe', 'denom_social']
        if 'tp_fundo_classe' in df.columns:
            colunas.append('tp_fundo_classe')

        df_fundos = df[colunas].drop_duplicates(subset=['cnpj_fundo_classe'])

        # Renomear colunas
        rename_map = {
            'cnpj_fundo_classe': 'cnpj',
            'denom_social': 'nome_fundo'
        }
        if 'tp_fundo_classe' in df_fundos.columns:
            rename_map['tp_fundo_classe'] = 'classe'

        df_fundos = df_fundos.rename(columns=rename_map)

        # Remover NaNs e valores vazios
        df_fundos = df_fundos.dropna(subset=['cnpj'])
        df_fundos = df_fundos[df_fundos['cnpj'].str.len() > 0]

        return df_fundos.to_dict('records')

    def preparar_tabela_emissores(self, df: pd.DataFrame) -> List[Dict]:
        """Extrai dados únicos para tabela emissores"""
        # Emissores podem vir de várias colunas dependendo do arquivo
        emissores = []
        
        # De fi_blc_2, 6, etc.
        if 'cnpj_emissor' in df.columns and 'emissor' in df.columns:
            df_e = df[['cnpj_emissor', 'emissor']].rename(columns={'cnpj_emissor': 'cnpj_cpf', 'emissor': 'nome_emissor'})
            emissores.append(df_e)
            
        if 'cpf_cnpj_emissor' in df.columns and 'emissor' in df.columns:
            df_e = df[['cpf_cnpj_emissor', 'emissor']].rename(columns={'cpf_cnpj_emissor': 'cnpj_cpf', 'emissor': 'nome_emissor'})
            emissores.append(df_e)
            
        if not emissores:
            return []
            
        df_emissores = pd.concat(emissores).drop_duplicates(subset=['cnpj_cpf'])
        df_emissores = df_emissores.dropna(subset=['cnpj_cpf'])
        # Tipo pessoa pode ser inferido pelo tamanho do documento (11=PF, 14=PJ)
        df_emissores['tipo_pessoa'] = df_emissores['cnpj_cpf'].apply(lambda x: 'PJ' if len(str(x)) > 11 else 'PF')
        
        return df_emissores.to_dict('records')

    def preparar_tabela_ativos(self, df: pd.DataFrame, mapa_emissores: Dict[str, str]) -> List[Dict]:
        """Extrai dados únicos para tabela ativos"""
        # Ativos vêm principalmente de cd_ativo, ds_ativo
        if 'cd_ativo' not in df.columns:
            app_logger.warning("Coluna 'cd_ativo' não encontrada, pulando ativos")
            return []

        # Selecionar colunas relevantes que existem
        cols = ['cd_ativo']
        if 'ds_ativo' in df.columns:
            cols.append('ds_ativo')
        if 'tp_ativo' in df.columns:
            cols.append('tp_ativo')

        # Tentar pegar emissor para vincular
        col_emissor = None
        if 'cnpj_emissor' in df.columns:
            cols.append('cnpj_emissor')
            col_emissor = 'cnpj_emissor'
        elif 'cpf_cnpj_emissor' in df.columns:
            cols.append('cpf_cnpj_emissor')
            col_emissor = 'cpf_cnpj_emissor'

        # Criar subset com colunas existentes
        df_ativos = df[cols].copy()

        # Drop duplicates baseado em colunas que existem
        subset_cols = ['cd_ativo']
        if 'tp_ativo' in df_ativos.columns:
            subset_cols.append('tp_ativo')

        df_ativos = df_ativos.drop_duplicates(subset=subset_cols)

        # Remover linhas onde cd_ativo é nulo ou vazio
        df_ativos = df_ativos.dropna(subset=['cd_ativo'])
        df_ativos = df_ativos[df_ativos['cd_ativo'].str.len() > 0]

        registros = []
        for _, row in df_ativos.iterrows():
            # Construir registro apenas com campos válidos
            reg = {'codigo': row['cd_ativo']}

            if 'ds_ativo' in row and pd.notna(row['ds_ativo']):
                reg['descricao'] = row['ds_ativo']

            if 'tp_ativo' in row and pd.notna(row['tp_ativo']):
                reg['tipo_ativo'] = row['tp_ativo']

            # Tentar vincular emissor
            if col_emissor and col_emissor in row:
                doc_emissor = row[col_emissor]
                if pd.notna(doc_emissor) and doc_emissor in mapa_emissores:
                    reg['emissor_id'] = mapa_emissores[doc_emissor]

            registros.append(reg)

        return registros

    def preparar_tabela_pl(self, df: pd.DataFrame, mapa_fundos: Dict[str, str]) -> List[Dict]:
        """Prepara dados de PL"""
        df_pl = df[df['tabela_origem'] == 'fi_pl'].copy()
        if df_pl.empty:
            return []
            
        registros = []
        for _, row in df_pl.iterrows():
            cnpj = row.get('cnpj_fundo_classe')
            if cnpj in mapa_fundos:
                registros.append({
                    'fundo_id': mapa_fundos[cnpj],
                    'data_competencia': row.get('dt_comptc'),
                    'valor_pl': row.get('vl_patrim_liq'),
                    'mes_referencia': row.get('mes_referencia')
                })
        return registros

    def preparar_tabela_posicoes(self, df: pd.DataFrame, mapa_fundos: Dict[str, str], mapa_ativos: Dict[Tuple[str, str], str]) -> Tuple[List[Dict], List[Dict]]:
        """
        Prepara dados de posições e detalhes
        Retorna (lista_posicoes, lista_detalhes_raw)
        """
        # Filtrar tabelas de posições (excluir PL, confidencial, exterior por enquanto)
        tabelas_posicao = ['fi_blc_1', 'fi_blc_2', 'fi_blc_3', 'fi_blc_4', 'fi_blc_5', 'fi_blc_6', 'fi_blc_7', 'fi_blc_8']
        df_pos = df[df['tabela_origem'].isin(tabelas_posicao)].copy()
        
        registros_pos = []
        registros_detalhes = [] # Vai precisar do ID da posição inserida, então isso é complexo no batch
        # Na verdade, para detalhes, vamos precisar inserir posições primeiro, pegar IDs e depois inserir detalhes.
        # O BatchUploader vai precisar lidar com isso ou retornamos dados brutos para processamento em etapas.
        
        # Vamos retornar os dados preparados para inserção.
        # O vínculo com detalhes será feito via chave composta (fundo_id, ativo_id, data) se possível,
        # ou inserimos detalhes como JSONB na própria tabela de posições se simplificarmos,
        # MAS o schema pede tabela separada.
        
        # Estratégia: Retornar lista de posições com um ID temporário ou chave lógica para vincular detalhes depois?
        # Ou melhor: Inserir posições, recuperar IDs (via upsert returning), e então inserir detalhes.
        
        for _, row in df_pos.iterrows():
            cnpj = row.get('cnpj_fundo_classe')
            if cnpj not in mapa_fundos:
                continue
                
            fundo_id = mapa_fundos[cnpj]
            
            # Identificar ativo
            codigo = row.get('cd_ativo')
            tipo = row.get('tp_ativo')
            ativo_key = (codigo, tipo)
            ativo_id = mapa_ativos.get(ativo_key)
            
            # Dados da posição
            posicao = {
                'fundo_id': fundo_id,
                'ativo_id': ativo_id,
                'data_competencia': row.get('dt_comptc'),
                'tipo_aplicacao': row.get('tp_aplic'),
                'qtd_posicao_final': row.get('qt_pos_final'),
                'valor_mercado_final': row.get('vl_merc_pos_final'),
                'valor_custo_final': row.get('vl_custo_pos_final'),
                'mes_referencia': row.get('mes_referencia')
            }
            
            # Dados de detalhes (tudo que sobrou relevante)
            detalhes = {k: v for k, v in row.to_dict().items() if k not in posicao and pd.notna(v)}
            
            registros_pos.append(posicao)
            registros_detalhes.append(detalhes) # Lista paralela
            
        return registros_pos, registros_detalhes
