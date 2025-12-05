"""
Configurações da Aplicação ETL
Carrega variáveis de ambiente e define constantes
"""

import os
from pathlib import Path
from dotenv import load_dotenv

# Forçar reload do .env (importante se você mudou a chave)
env_path = Path(__file__).parent / '.env'
load_dotenv(env_path, override=True)

# ==========================================
# SUPABASE
# ==========================================
SUPABASE_URL = os.getenv('SUPABASE_URL', '')
SUPABASE_KEY = os.getenv('SUPABASE_KEY', '')

# ==========================================
# PATHS
# ==========================================
BASE_DIR = Path(__file__).parent.parent
DATA_DIR = BASE_DIR / 'source'
OUTPUT_DIR = BASE_DIR / 'processed'
LOGS_DIR = BASE_DIR / 'logs'

# Criar diretórios se não existirem
OUTPUT_DIR.mkdir(exist_ok=True)
LOGS_DIR.mkdir(exist_ok=True)

# ==========================================
# FILTROS DO MVP
# ==========================================
# Patrimônio Líquido mínimo para ser considerado "grande fundo"
THRESHOLD_GRANDE_FUNDO = 50_000_000  # R$ 50 milhões

# Top N fundos por categoria (alternativa ao threshold de PL)
TOP_N_FUNDOS_POR_CATEGORIA = 200

# PL mínimo para os Top 200 fundos (pode ser ajustado dinamicamente)
TOP_200_FUNDOS_PL_MINIMO = 50_000_000  # R$ 50 milhões

# Tipos de aplicação permitidos (apenas ações)
TIPOS_APLICACAO_VALIDOS = ['Ações']

# Tipos de ativos permitidos
TIPOS_ATIVOS_VALIDOS = [
    'Ação ordinária',
    'Ação preferencial',
    'Units',
    'Ação ordinária ou preferencial'  # CVM às vezes usa essa nomenclatura
]

# Valor mínimo de posição para considerar (evitar ruído)
VALOR_MINIMO_POSICAO = 100_000  # R$ 100 mil

# ==========================================
# UPLOAD (SUPABASE)
# ==========================================
# Tamanho do lote para upload
BATCH_SIZE = 1000

# Máximo de tentativas em caso de erro
MAX_RETRIES = 3

# Tempo de espera entre retries (segundos)
RETRY_DELAY = 2

# Timeout para operações de upload (segundos)
UPLOAD_TIMEOUT = 30

# ==========================================
# PROCESSAMENTO
# ==========================================
# Encoding padrão dos arquivos CVM
CVM_ENCODING = 'latin1'  # Arquivos CVM usam ISO-8859-1

# Separador CSV
CVM_SEPARATOR = ';'

# Chunk size para leitura de CSVs grandes
CHUNK_SIZE = 10_000

# Colunas essenciais por tipo de arquivo
COLUNAS_BLC = [
    'TP_FUNDO_CLASSE',
    'CNPJ_FUNDO_CLASSE',
    'DENOM_SOCIAL',
    'DT_COMPTC',
    'TP_APLIC',
    'TP_ATIVO',
    'QT_AQUIS_NEGOC',
    'VL_AQUIS_NEGOC',
    'QT_VENDA_NEGOC',
    'VL_VENDA_NEGOC',
    'QT_POS_FINAL',
    'VL_MERC_POS_FINAL',
    'VL_CUSTO_POS_FINAL'
]

COLUNAS_PL = [
    'CNPJ_FUNDO_CLASSE',
    'DENOM_SOCIAL',
    'DT_COMPTC',
    'VL_PATRIM_LIQ'
]

# ==========================================
# AGREGAÇÕES (FRESH BETS)
# ==========================================
# Número mínimo de fundos para considerar "consenso"
MIN_FUNDOS_CONSENSO = 3

# Número de resultados para Fresh Bets
TOP_FRESH_BETS = 20

# Número de resultados para Top Movers
TOP_MOVERS_COUNT = 10

# ==========================================
# LOGGING
# ==========================================
LOG_LEVEL = os.getenv('LOG_LEVEL', 'DEBUG')
LOG_FORMAT = "{time:YYYY-MM-DD HH:mm:ss} | {level: <8} | {message}"
LOG_FILE = LOGS_DIR / 'etl.log'
LOG_ROTATION = "10 MB"  # Rotacionar logs a cada 10MB
LOG_RETENTION = "30 days"  # Manter logs por 30 dias

# ==========================================
# INTERFACE (CLI)
# ==========================================
# Largura da progress bar
PROGRESS_BAR_WIDTH = 60

# Refresh rate da progress bar (Hz)
PROGRESS_REFRESH_RATE = 10

# ==========================================
# VALIDAÇÃO
# ==========================================
# Validar CNPJs (apenas formato, não dígito verificador)
VALIDAR_CNPJ = True

# Tolerância de erro nas agregações (%)
TOLERANCIA_AGREGACAO = 0.01  # 0.01%

# ==========================================
# MAPEAMENTOS
# ==========================================
# Mapeamento de nomes de arquivos CVM para identificação
ARQUIVO_PATTERNS = {
    'balancete': r'cda_fi_BLC_\d+_\d{6}\.csv',
    'patrimonio': r'cda_fi_PL_\d{6}\.csv',
    'fie': r'cda_fie_\d{6}\.csv'
}

# Mapeamento de padrões de arquivo para tabelas do Supabase
FILE_TO_TABLE_MAPPING = {
    'fi_BLC_1': 'fi_blc_1',      # Títulos Públicos Federais
    'fi_BLC_2': 'fi_blc_2',      # Títulos Privados de Crédito
    'fi_BLC_3': 'fi_blc_3',      # Ações (PRINCIPAL PARA O MVP)
    'fi_BLC_4': 'fi_blc_4',      # Fundos de Investimento
    'fi_BLC_5': 'fi_blc_5',      # Derivativos
    'fi_BLC_6': 'fi_blc_6',      # Operações Compromissadas
    'fi_BLC_7': 'fi_blc_7',      # Ativos no Exterior
    'fi_BLC_8': 'fi_blc_8',      # Outros Ativos
    'fi_PL': 'fi_pl',            # Patrimônio Líquido
    'fi_CONFID': 'fi_confid',    # Dados Confidenciais
    'fie': 'fie',                # Fundos de Investimento Estruturados
    'fie_CONFID': 'fie_confid'   # FIE - Dados Confidenciais
}

# Mapeamento de colunas originais para colunas do banco (snake_case)
COLUMN_MAPPING = {
    'TP_FUNDO_CLASSE': 'tp_fundo_classe',
    'CNPJ_FUNDO_CLASSE': 'cnpj_fundo_classe',
    'DENOM_SOCIAL': 'denom_social',
    'DT_COMPTC': 'dt_comptc',
    'TP_APLIC': 'tp_aplic',
    'TP_ATIVO': 'tp_ativo',
    'EMISSOR_LIGADO': 'emissor_ligado',
    'TP_NEGOC': 'tp_negoc',
    'QT_VENDA_NEGOC': 'qt_venda_negoc',
    'VL_VENDA_NEGOC': 'vl_venda_negoc',
    'QT_AQUIS_NEGOC': 'qt_aquis_negoc',
    'VL_AQUIS_NEGOC': 'vl_aquis_negoc',
    'QT_POS_FINAL': 'qt_pos_final',
    'VL_MERC_POS_FINAL': 'vl_merc_pos_final',
    'VL_CUSTO_POS_FINAL': 'vl_custo_pos_final',
    'DT_CONFID_APLIC': 'dt_confid_aplic',
    'CD_ATIVO': 'cd_ativo',
    'DS_ATIVO': 'ds_ativo',
    'DT_VENC': 'dt_venc',
    'CD_SELIC': 'cd_selic',
    'DT_INI_VIGENCIA': 'dt_ini_vigencia',
    'CNPJ_EMISSOR': 'cnpj_emissor',
    'EMISSOR': 'emissor',
    'TITULO_POSFX': 'titulo_posfx',
    'CD_INDEXADOR_POSFX': 'cd_indexador_posfx',
    'DS_INDEXADOR_POSFX': 'ds_indexador_posfx',
    'PR_INDEXADOR_POSFX': 'pr_indexador_posfx',
    'PR_CUPOM_POSFX': 'pr_cupom_posfx',
    'PR_TAXA_PREFX': 'pr_taxa_prefx',
    'RISCO_EMISSOR': 'risco_emissor',
    'AG_RISCO': 'ag_risco',
    'DT_RISCO': 'dt_risco',
    'GRAU_RISCO': 'grau_risco',
    'PF_PJ_EMISSOR': 'pf_pj_emissor',
    'CPF_CNPJ_EMISSOR': 'cpf_cnpj_emissor',
    'CNPJ_FUNDO_INVEST': 'cnpj_fundo_invest',
    'FUNDO_INVEST': 'fundo_invest',
    'VL_PATRIM_LIQ': 'vl_patrim_liq',
    'ID_DOC': 'id_doc',
    # Adicione outros conforme necessário
}

# Mapeamento de tipos de fundo
TIPOS_FUNDO = {
    'FIA': 'Fundo de Investimento em Ações',
    'FIM': 'Fundo de Investimento Multimercado',
    'FIF': 'Fundo de Investimento Financeiro',
    'FIDC': 'Fundo de Investimento em Direitos Creditórios',
    'FIP': 'Fundo de Investimento em Participações',
    'FII': 'Fundo de Investimento Imobiliário'
}

# ==========================================
# CHAVES ÚNICAS POR TABELA (PARA UPSERT)
# ==========================================

TABLE_UNIQUE_KEYS = {
    'fundos': 'cnpj',
    'fi_blc_1': 'cnpj_fundo_classe,dt_comptc,cd_ativo,mes_referencia',
    'fi_blc_2': 'cnpj_fundo_classe,dt_comptc,cnpj_emissor,dt_venc,mes_referencia',
    'fi_blc_3': 'cnpj_fundo_classe,dt_comptc,cd_ativo,mes_referencia',
    'fi_blc_4': 'cnpj_fundo_classe,dt_comptc,cnpj_fundo_invest,mes_referencia',
    'fi_blc_5': 'cnpj_fundo_classe,dt_comptc,cd_ativo_derivativo,mes_referencia',
    'fi_blc_6': 'cnpj_fundo_classe,dt_comptc,cpf_cnpj_emissor,dt_venc,mes_referencia',
    'fi_blc_7': 'cnpj_fundo_classe,dt_comptc,cd_ativo_bv_merc,mes_referencia',
    'fi_blc_8': 'cnpj_fundo_classe,dt_comptc,ds_ativo,mes_referencia',
    'fi_confid': 'cnpj_fundo_classe,dt_comptc,tp_aplic,mes_referencia',
    'fi_pl': 'cnpj_fundo_classe,dt_comptc,mes_referencia',
    'fie': 'cnpj_fundo_classe,dt_comptc,cd_ativo,mes_referencia',
    'fie_confid': 'cnpj_fundo_classe,dt_comptc,tp_aplic,mes_referencia'
}

# ==========================================
# HELPERS
# ==========================================
def validar_config():
    """Valida se as configurações necessárias estão presentes"""
    erros = []

    if not SUPABASE_URL:
        erros.append("SUPABASE_URL não configurado no .env")

    if not SUPABASE_KEY:
        erros.append("SUPABASE_KEY não configurado no .env")

    if erros:
        raise ValueError(f"Configuração inválida:\\n" + "\\n".join(erros))

    return True

def get_data_competencia_from_filename(filename: str) -> str:
    """
    Extrai data de competência do nome do arquivo

    Exemplo: cda_fi_BLC_1_202510.csv → 2025-10-31
    """
    import re
    match = re.search(r'(\d{6})\.csv', filename)
    if match:
        yyyymm = match.group(1)
        year = yyyymm[:4]
        month = yyyymm[4:6]

        # Último dia do mês
        from calendar import monthrange
        last_day = monthrange(int(year), int(month))[1]

        return f"{year}-{month}-{last_day:02d}"

    return None

def identificar_tabela_por_arquivo(nome_arquivo: str) -> str:
    """
    Identifica a tabela de destino baseado no nome do arquivo.
    
    Exemplo:
        'cda_fi_BLC_3_202510.csv' -> 'fi_blc_3'
        'cda_fi_PL_202510.csv' -> 'fi_pl'
        'cda_fie_202510.csv' -> 'fie'
    
    Args:
        nome_arquivo: Nome do arquivo CSV
        
    Returns:
        Nome da tabela no Supabase ou None se não identificado
    """
    import re
    
    # Remover extensão
    nome_base = nome_arquivo.replace('.csv', '')
    
    # Tentar identificar o padrão
    for padrao, tabela in FILE_TO_TABLE_MAPPING.items():
        # Criar regex para o padrão (ex: fi_BLC_3 -> cda_fi_BLC_3_\d{6})
        if padrao.startswith('fi_'):
            regex = rf'cda_{padrao}_\d{{6}}'
        elif padrao.startswith('fie'):
            if 'CONFID' in padrao:
                regex = r'cda_fie_CONFID_\d{6}'
            else:
                regex = r'cda_fie_\d{6}'
        else:
            continue
            
        if re.search(regex, nome_base):
            return tabela
    
    return None

def extrair_mes_referencia(nome_arquivo: str) -> str:
    """
    Extrai o mês de referência do nome do arquivo e retorna como data.
    
    Exemplo:
        'cda_fi_BLC_3_202510.csv' -> '2025-10-31'
        'cda_fi_PL_202508.csv' -> '2025-08-31'
    
    Args:
        nome_arquivo: Nome do arquivo CSV
        
    Returns:
        Data no formato YYYY-MM-DD (último dia do mês) ou None
    """
    import re
    from calendar import monthrange
    
    match = re.search(r'(\d{6})\.csv', nome_arquivo)
    if match:
        yyyymm = match.group(1)
        year = int(yyyymm[:4])
        month = int(yyyymm[4:6])
        
        # Último dia do mês
        last_day = monthrange(year, month)[1]
        
        return f"{year:04d}-{month:02d}-{last_day:02d}"
    
    return None

if __name__ == '__main__':
    # Teste de configuração
    print("=== Configurações ETL ===")
    print(f"Supabase URL: {'✓' if SUPABASE_URL else '✗'}")
    print(f"Supabase Key: {'✓' if SUPABASE_KEY else '✗'}")
    print(f"Data DIR: {DATA_DIR}")
    print(f"Output DIR: {OUTPUT_DIR}")
    print(f"Threshold Grande Fundo: R$ {THRESHOLD_GRANDE_FUNDO:,.2f}")
    print(f"Batch Size: {BATCH_SIZE}")
    print()

    # Testar identificação de tabelas
    arquivos_teste = [
        'cda_fi_BLC_1_202510.csv',
        'cda_fi_BLC_3_202510.csv',
        'cda_fi_PL_202510.csv',
        'cda_fie_202508.csv',
        'cda_fie_CONFID_202508.csv'
    ]
    
    print("=== Teste de Mapeamento de Arquivos ===")
    for arquivo in arquivos_teste:
        tabela = identificar_tabela_por_arquivo(arquivo)
        mes_ref = extrair_mes_referencia(arquivo)
        print(f"{arquivo}")
        print(f"  -> Tabela: {tabela}")
        print(f"  -> Mês: {mes_ref}")
        print()
