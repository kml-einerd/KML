import sys
import os
from pathlib import Path

# Adicionar diretório atual ao path para imports funcionarem
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

from config import DATA_DIR, validar_config
from utils.logger import app_logger
from utils.progress import print_success, print_error, print_info, print_summary_table
from processors.csv_reader import CVMReader
from processors.data_cleaner import DataCleaner
from processors.filters import DataFilter
from processors.aggregations import DataAggregator
from uploaders.supabase_client import SupabaseClient
from uploaders.batch_uploader import BatchUploader

def run_pipeline():
    print("🚀 Iniciando Pipeline ETL (Modo Automático)...")
    
    # 1. Inicializar componentes
    reader = CVMReader()
    cleaner = DataCleaner()
    aggregator = DataAggregator()
    
    # 2. Processar Arquivos
    print("\n[1/4] 📂 Processando Arquivos...")
    pasta_path = Path(DATA_DIR)
    
    arquivos_blc = reader.listar_arquivos_cvm(pasta_path, 'cda_fi_BLC_*.csv')
    arquivos_pl = reader.listar_arquivos_cvm(pasta_path, 'cda_fi_PL_*.csv')
    
    if not arquivos_blc or not arquivos_pl:
        print("❌ Erro: Arquivos CSV não encontrados na pasta source!")
        return

    print(f"   - Encontrados {len(arquivos_blc)} balancetes e {len(arquivos_pl)} arquivos de PL")
    
    # Ler e Processar
    print("   - Lendo e limpando dados (aguarde)...")
    df_blc_raw = reader.ler_multiplos_csvs(arquivos_blc)
    df_pl_raw = reader.ler_multiplos_csvs(arquivos_pl)
    
    df_blc_clean = cleaner.limpar_dataframe_balancete(df_blc_raw)
    df_pl_clean = cleaner.limpar_dataframe_pl(df_pl_raw)
    
    print("   - Aplicando filtros e agregações...")
    df_posicoes = DataFilter.pipeline_completo(df_blc_clean, df_pl_clean)
    df_top_movers = aggregator.calcular_top_movers(df_posicoes)
    
    print(f"   ✅ Processamento concluído: {len(df_posicoes)} posições geradas.")

    # 3. Upload Supabase
    print("\n[2/4] 📤 Preparando Upload para Supabase...")
    
    try:
        validar_config()
        supabase = SupabaseClient()
        uploader = BatchUploader(supabase)
        
        if not supabase.testar_conexao():
            print("❌ Erro: Falha na conexão com Supabase. Verifique .env")
            return
            
        print("   - Conexão OK. Iniciando upload...")
        
        # Preparar dados para upload
        fundos_data = df_posicoes[['CNPJ_FUNDO_CLASSE', 'DENOM_SOCIAL']].drop_duplicates()
        fundos_data = fundos_data.rename(columns={'CNPJ_FUNDO_CLASSE': 'cnpj', 'DENOM_SOCIAL': 'nome_fundo'})
        fundos_data['is_grande_fundo'] = True
        
        posicoes_data = df_posicoes.rename(columns={
            'CNPJ_FUNDO_CLASSE': 'cnpj_fundo', 'DT_COMPTC': 'data_competencia', 'CD_ATIVO': 'ticker',
            'TP_ATIVO': 'tipo_ativo', 'QT_AQUIS_NEGOC': 'qtd_compra', 'VL_AQUIS_NEGOC': 'valor_compra',
            'QT_VENDA_NEGOC': 'qtd_venda', 'VL_VENDA_NEGOC': 'valor_venda', 'QT_POS_FINAL': 'qtd_posicao_final',
            'VL_MERC_POS_FINAL': 'valor_mercado_final', 'VL_CUSTO_POS_FINAL': 'valor_custo_final'
        })
        
        pl_data = df_pl_clean.rename(columns={
            'CNPJ_FUNDO_CLASSE': 'cnpj_fundo', 'DT_COMPTC': 'data_competencia', 'VL_PATRIM_LIQ': 'valor_pl'
        })
        
        uploads = [
            {'table': 'fundos', 'data': fundos_data.to_dict('records'), 'on_conflict': 'cnpj', 'descricao': 'Fundos'},
            {'table': 'patrimonio_liquido_mensal', 'data': pl_data.to_dict('records'), 'on_conflict': 'cnpj_fundo,data_competencia', 'descricao': 'PL Mensal'},
            {'table': 'posicoes_acoes', 'data': posicoes_data.to_dict('records'), 'on_conflict': 'cnpj_fundo,data_competencia,ticker', 'descricao': 'Posições'},
            {'table': 'top_movers', 'data': df_top_movers.to_dict('records'), 'on_conflict': 'cnpj_fundo,data_competencia', 'descricao': 'Top Movers'}
        ]
        
        resultados = uploader.upload_multiplas_tabelas(uploads)
        
        print("\n[3/4] 📊 Resultados do Upload:")
        for res in resultados:
            print(f"   - {res['table']}: {res['sucesso']} sucessos / {res['falha']} falhas")
            
    except Exception as e:
        print(f"❌ Erro crítico no upload: {e}")
        import traceback
        traceback.print_exc()
        return

    print("\n[4/4] 🎉 Pipeline Finalizado com Sucesso!")

if __name__ == "__main__":
    run_pipeline()
