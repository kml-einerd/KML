"""
RADAR INSTITUCIONAL - ETL Application
CLI Interativo para processamento e upload de dados CVM
"""

import questionary
from pathlib import Path
from rich.console import Console
from rich.panel import Panel
from rich import print as rprint

# Imports locais
from config import DATA_DIR, validar_config
from utils.logger import app_logger
from utils.progress import print_success, print_error, print_info, print_summary_table
from processors.csv_reader import CVMReader
from processors.data_cleaner import DataCleaner
from processors.filters import DataFilter
from processors.aggregations import DataAggregator
from uploaders.supabase_client import SupabaseClient
from uploaders.batch_uploader import BatchUploader

console = Console()

class RadarETL:
    """Aplicação principal ETL"""

    def __init__(self):
        self.reader = CVMReader()
        self.cleaner = DataCleaner()
        self.aggregator = DataAggregator()

        self.supabase_client = None
        self.uploader = None

        # Dados processados (mantidos em memória)
        self.df_fundos = None
        self.df_pl = None
        self.df_posicoes = None
        self.df_top_movers = None
        self.df_fresh_bets = None

    def mostrar_header(self):
        """Mostra header da aplicação"""
        console.clear()
        rprint(Panel.fit(
            "[bold cyan]🎯 RADAR INSTITUCIONAL - ETL[/bold cyan]\\n"
            "[dim]Processamento de dados CVM para Supabase[/dim]",
            border_style="cyan"
        ))

    def menu_principal(self):
        """Menu principal interativo"""
        self.mostrar_header()

        opcoes = [
            "📁 Processar arquivos CVM",
            "📤 Upload para Supabase",
            "✅ Validar dados processados",
            "🔍 Verificar status Supabase",
            "⚙️  Configurar Supabase",
            "🚪 Sair"
        ]

        escolha = questionary.select(
            "Selecione uma opção:",
            choices=opcoes
        ).ask()

        if escolha == opcoes[0]:
            self.processar_arquivos()
        elif escolha == opcoes[1]:
            self.upload_supabase()
        elif escolha == opcoes[2]:
            self.validar_dados()
        elif escolha == opcoes[3]:
            self.verificar_status()
        elif escolha == opcoes[4]:
            self.configurar_supabase()
        elif escolha == opcoes[5]:
            print_info("Encerrando aplicação...")
            return False

        return True

    def processar_arquivos(self):
        """Processa arquivos CSV da CVM"""
        print_info("Iniciando processamento...")

        # Selecionar pasta
        pasta = questionary.path(
            "Caminho da pasta com arquivos CVM:",
            default=str(DATA_DIR)
        ).ask()

        if not pasta:
            print_error("Cancelado pelo usuário")
            return

        pasta_path = Path(pasta)

        # Listar arquivos
        arquivos_blc = self.reader.listar_arquivos_cvm(pasta_path, 'cda_fi_BLC_*.csv')
        arquivos_pl = self.reader.listar_arquivos_cvm(pasta_path, 'cda_fi_PL_*.csv')

        if not arquivos_blc:
            print_error("Nenhum arquivo BLC encontrado!")
            self.pausar()
            return

        if not arquivos_pl:
            print_error("Nenhum arquivo PL encontrado!")
            self.pausar()
            return

        print_summary_table("Arquivos Encontrados", {
            "Balancetes (BLC)": len(arquivos_blc),
            "Patrimônio Líquido (PL)": len(arquivos_pl)
        })

        # Confirmar processamento
        confirma = questionary.confirm("Deseja processar estes arquivos?").ask()

        if not confirma:
            return

        try:
            # 1. Ler BLCs
            print_info("Lendo arquivos de balancete...")
            df_blc_raw = self.reader.ler_multiplos_csvs(arquivos_blc)

            # 2. Ler PLs
            print_info("Lendo arquivos de PL...")
            df_pl_raw = self.reader.ler_multiplos_csvs(arquivos_pl)

            # 3. Limpar dados
            print_info("Limpando dados...")
            df_blc_clean = self.cleaner.limpar_dataframe_balancete(df_blc_raw)
            df_pl_clean = self.cleaner.limpar_dataframe_pl(df_pl_raw)

            # 4. Aplicar filtros do MVP
            print_info("Aplicando filtros do MVP...")
            df_posicoes_filtrado = DataFilter.pipeline_completo(df_blc_clean, df_pl_clean)

            # 5. Calcular agregações
            print_info("Calculando agregações...")
            df_top_movers = self.aggregator.calcular_top_movers(df_posicoes_filtrado)
            df_populares = self.aggregator.calcular_ativos_populares(df_posicoes_filtrado)

            # Armazenar em memória
            self.df_posicoes = df_posicoes_filtrado
            self.df_pl = df_pl_clean
            self.df_top_movers = df_top_movers
            # self.df_fresh_bets = None  # Requer 2 meses

            # Resumo final
            print_summary_table("Processamento Concluído", {
                "Fundos únicos": df_posicoes_filtrado['CNPJ_FUNDO_CLASSE'].nunique(),
                "Posições em ações": len(df_posicoes_filtrado),
                "Top Movers calculados": len(df_top_movers),
                "Ativos populares": len(df_populares)
            })

            print_success("✓ Processamento concluído com sucesso!")

        except Exception as e:
            print_error(f"Erro durante processamento: {e}")
            app_logger.exception(e)

        self.pausar()

    def upload_supabase(self):
        """Faz upload dos dados para Supabase"""
        print_info("Preparando upload para Supabase...")

        # Verificar se há dados processados
        if self.df_posicoes is None:
            print_error("Nenhum dado processado! Execute 'Processar arquivos CVM' primeiro.")
            self.pausar()
            return

        # Inicializar cliente se necessário
        if self.supabase_client is None:
            try:
                validar_config()
                self.supabase_client = SupabaseClient()
                self.uploader = BatchUploader(self.supabase_client)
                print_success("✓ Cliente Supabase conectado")
            except Exception as e:
                print_error(f"Erro ao conectar Supabase: {e}")
                self.pausar()
                return

        # Testar conexão
        if not self.supabase_client.testar_conexao():
            print_error("Falha ao conectar com Supabase!")
            self.pausar()
            return

        # Confirmar upload
        confirma = questionary.confirm(
            f"Deseja fazer upload de {len(self.df_posicoes):,} posições para Supabase?"
        ).ask()

        if not confirma:
            return

        try:
            # Preparar dados
            print_info("Preparando dados para upload...")

            # Extrair fundos únicos
            fundos_data = self.df_posicoes[['CNPJ_FUNDO_CLASSE', 'DENOM_SOCIAL']].drop_duplicates()
            fundos_data = fundos_data.rename(columns={
                'CNPJ_FUNDO_CLASSE': 'cnpj',
                'DENOM_SOCIAL': 'nome_fundo'
            })
            fundos_data['is_grande_fundo'] = True

            # Preparar posições
            posicoes_data = self.df_posicoes.rename(columns={
                'CNPJ_FUNDO_CLASSE': 'cnpj_fundo',
                'DT_COMPTC': 'data_competencia',
                'CD_ATIVO': 'ticker',
                'TP_ATIVO': 'tipo_ativo',
                'QT_AQUIS_NEGOC': 'qtd_compra',
                'VL_AQUIS_NEGOC': 'valor_compra',
                'QT_VENDA_NEGOC': 'qtd_venda',
                'VL_VENDA_NEGOC': 'valor_venda',
                'QT_POS_FINAL': 'qtd_posicao_final',
                'VL_MERC_POS_FINAL': 'valor_mercado_final',
                'VL_CUSTO_POS_FINAL': 'valor_custo_final'
            })

            # Preparar PL
            pl_data = self.df_pl.rename(columns={
                'CNPJ_FUNDO_CLASSE': 'cnpj_fundo',
                'DT_COMPTC': 'data_competencia',
                'VL_PATRIM_LIQ': 'valor_pl'
            })

            # Configurar uploads
            uploads = [
                {
                    'table': 'fundos',
                    'data': fundos_data.to_dict('records'),
                    'on_conflict': 'cnpj',
                    'descricao': 'Uploading fundos'
                },
                {
                    'table': 'patrimonio_liquido_mensal',
                    'data': pl_data.to_dict('records'),
                    'on_conflict': 'cnpj_fundo,data_competencia',
                    'descricao': 'Uploading PL mensal'
                },
                {
                    'table': 'posicoes_acoes',
                    'data': posicoes_data.to_dict('records'),
                    'on_conflict': 'cnpj_fundo,data_competencia,ticker',
                    'descricao': 'Uploading posições'
                },
                {
                    'table': 'top_movers',
                    'data': self.df_top_movers.to_dict('records'),
                    'on_conflict': 'cnpj_fundo,data_competencia',
                    'descricao': 'Uploading top movers'
                }
            ]

            # Executar uploads
            resultados = self.uploader.upload_multiplas_tabelas(uploads)

            # Mostrar resultados
            resumo = {
                res['table']: f"{res['sucesso']:,}/{res['total']:,} ({res['taxa_sucesso']:.1f}%)"
                for res in resultados
            }

            print_summary_table("Resultados do Upload", resumo)
            print_success("✓ Upload concluído!")

        except Exception as e:
            print_error(f"Erro durante upload: {e}")
            app_logger.exception(e)

        self.pausar()

    def validar_dados(self):
        """Valida dados processados"""
        print_info("Validando dados...")

        if self.df_posicoes is None:
            print_error("Nenhum dado processado!")
            self.pausar()
            return

        # Estatísticas básicas
        stats = {
            "Total de registros": len(self.df_posicoes),
            "Fundos únicos": self.df_posicoes['CNPJ_FUNDO_CLASSE'].nunique(),
            "Ativos únicos": self.df_posicoes['CD_ATIVO'].nunique() if 'CD_ATIVO' in self.df_posicoes.columns else 0,
            "Datas de competência": self.df_posicoes['DT_COMPTC'].nunique(),
            "Valores nulos": self.df_posicoes.isnull().sum().sum()
        }

        print_summary_table("Validação de Dados", stats)

        self.pausar()

    def verificar_status(self):
        """Verifica status do Supabase"""
        print_info("Verificando status do Supabase...")

        try:
            if self.supabase_client is None:
                validar_config()
                self.supabase_client = SupabaseClient()

            # Contar registros
            stats = {
                "Fundos": self.supabase_client.count('fundos'),
                "PL Mensal": self.supabase_client.count('patrimonio_liquido_mensal'),
                "Posições": self.supabase_client.count('posicoes_acoes'),
                "Top Movers": self.supabase_client.count('top_movers'),
                "Fresh Bets": self.supabase_client.count('fresh_bets')
            }

            print_summary_table("Status do Supabase", stats)

        except Exception as e:
            print_error(f"Erro ao verificar status: {e}")

        self.pausar()

    def configurar_supabase(self):
        """Configurar credenciais Supabase"""
        print_info("Configuração de Supabase")
        print("Edite o arquivo .env com suas credenciais")
        print("SUPABASE_URL=https://seu-projeto.supabase.co")
        print("SUPABASE_KEY=sua-chave-api")

        self.pausar()

    def pausar(self):
        """Pausa para o usuário ver resultado"""
        questionary.press_any_key_to_continue("Pressione qualquer tecla para continuar...").ask()

    def executar(self):
        """Executa o loop principal"""
        continuar = True

        while continuar:
            continuar = self.menu_principal()

        print_success("Até logo!")

def main():
    """Função principal"""
    app = RadarETL()
    app.executar()

if __name__ == '__main__':
    main()
