"""
Configurações da Aplicação ETL
Carrega variáveis de ambiente e define constantes
"""

import os
from pathlib import Path
from dotenv import load_dotenv

# Carregar variáveis de ambiente
load_dotenv()

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
LOG_LEVEL = os.getenv('LOG_LEVEL', 'INFO')
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

if __name__ == '__main__':
    # Teste de configuração
    print("=== Configurações ETL ===")
    print(f"Supabase URL: {'✓' if SUPABASE_URL else '✗'}")
    print(f"Supabase Key: {'✓' if SUPABASE_KEY else '✗'}")
    print(f"Data DIR: {DATA_DIR}")
    print(f"Output DIR: {OUTPUT_DIR}")
    print(f"Threshold Grande Fundo: R$ {THRESHOLD_GRANDE_FUNDO:,.2f}")
    print(f"Batch Size: {BATCH_SIZE}")
