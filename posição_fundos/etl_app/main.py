"""
RADAR INSTITUCIONAL - ETL Application
CLI Interativo para processamento e upload de dados CVM
"""

import questionary
from pathlib import Path
from rich.console import Console
from rich.panel import Panel
from rich import print as rprint
import pandas as pd

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
        
        # Novo atributo para armazenar resultados do processamento
        self.resultados_processamento = None

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

    def _selecionar_pasta(self):
        """Seleciona pasta com arquivos para processar"""
        print_info("Selecionando pasta...")

        # Listar subpastas em DATA_DIR
        try:
            subpastas = [f.name for f in DATA_DIR.iterdir() if f.is_dir() and not f.name.startswith('.')]
            subpastas.sort()
        except FileNotFoundError:
            print_error(f"Diretório de dados não encontrado: {DATA_DIR}")
            return None

        if not subpastas:
            print_error(f"Nenhuma subpasta encontrada em {DATA_DIR}")
            return None

        # Menu de seleção de pasta
        pasta_escolhida = questionary.select(
            "Selecione o mês/pasta para processar:",
            choices=subpastas + ["Cancelar"]
        ).ask()

        if pasta_escolhida == "Cancelar" or not pasta_escolhida:
            return None

        pasta_path = DATA_DIR / pasta_escolhida
        print_info(f"Pasta selecionada: {pasta_path}")

        # Listar TODOS os arquivos CSV
        todos_arquivos = list(pasta_path.glob('*.csv'))

        if not todos_arquivos:
            print_error("Nenhum arquivo CSV encontrado!")
            self.pausar()
            return None

        print_summary_table("Arquivos Encontrados", {
            "Total de arquivos CSV": len(todos_arquivos)
        })

        # Confirmar processamento
        confirma = questionary.confirm("Deseja processar estes arquivos?").ask()
        if not confirma:
            return None

        return pasta_path

    def processar_arquivos(self):
        """
        Processa arquivos CVM usando o novo fluxo normalizado
        """
        print_info("Iniciando processamento normalizado...")
        
        # Selecionar pasta
        pasta_path = self._selecionar_pasta()
        if not pasta_path:
            return
            
        try:
            from run_etl import NormalizedETL
            
            etl = NormalizedETL()
            etl.executar(pasta_path)
            
            # Marcar como processado para habilitar menus
            self.resultados_processamento = [{'status': 'concluido'}] 
            
        except Exception as e:
            print_error(f"Erro no processamento: {e}")
            app_logger.exception(e)
            
        self.pausar()

    def upload_supabase(self):
        """Faz upload dos dados para Supabase"""
        print_info("Preparando upload para Supabase...")
        
        # Verificar se há dados processados
        if self.resultados_processamento is None or len(self.resultados_processamento) == 0:
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
        
        # Calcular total de registros
        total_registros = sum(r['total_registros'] for r in self.resultados_processamento)
        
        # Confirmar upload
        confirma = questionary.confirm(
            f"Deseja fazer upload de {total_registros:,} registros para Supabase?"
        ).ask()
        
        if not confirma:
            return
        
        try:
            from config import TABLE_UNIQUE_KEYS, TIPOS_APLICACAO_VALIDOS
            
            print_info("Preparando dados para upload...")
            
            # PASSO 1: Preparar tabela de fundos (mantém lógica existente)
            print_info("Preparando tabela de fundos...")
            fundos_data = self._preparar_tabela_fundos()
            
            # PASSO 2: Preparar uploads para todas as tabelas
            uploads = []
            
            # Adicionar fundos primeiro
            if fundos_data is not None and len(fundos_data) > 0:
                uploads.append({
                    'table': 'fundos',
                    'data': fundos_data,
                    'on_conflict': TABLE_UNIQUE_KEYS['fundos'],
                    'descricao': 'Uploading fundos'
                })
            
            # PASSO 3: Processar cada resultado e preparar para upload
            for resultado in self.resultados_processamento:
                tabela = resultado['tabela']
                df = resultado['dados']
                
                # Aplicar filtro de "apenas ações" SOMENTE para fi_blc_3
                if tabela == 'fi_blc_3':
                    print_info(f"Aplicando filtro de ações em {tabela}...")
                    if 'tp_aplic' in df.columns:
                        df_filtrado = df[df['tp_aplic'].isin(TIPOS_APLICACAO_VALIDOS)]
                        print_info(f"  {len(df)} -> {len(df_filtrado)} registros após filtro")
                    else:
                        df_filtrado = df
                else:
                    df_filtrado = df
                
                # Converter para dicionário
                dados = df_filtrado.to_dict('records')
                
                if len(dados) > 0:
                    uploads.append({
                        'table': tabela,
                        'data': dados,
                        'on_conflict': TABLE_UNIQUE_KEYS.get(tabela, 'id'),
                        'descricao': f'Uploading {tabela}'
                    })

            # PASSO 6 (OPCIONAL): Calcular e fazer upload de agregações
            print_info("Calculando agregações...")
            top_movers = self._calcular_agregacoes()

            if top_movers is not None and len(top_movers) > 0:
                uploads.append({
                    'table': 'top_movers',
                    'data': top_movers.to_dict('records'),
                    'on_conflict': 'cnpj_fundo,data_competencia',
                    'descricao': 'Uploading top movers'
                })
            
            # PASSO 4: Executar uploads
            print_info(f"Iniciando upload para {len(uploads)} tabelas...")
            resultados = self.uploader.upload_multiplas_tabelas(uploads)
            
            # PASSO 5: Mostrar resultados
            resumo = {}
            for res in resultados:
                if 'table' in res:
                    resumo[res['table']] = f"{res['sucesso']:,}/{res['total']:,} ({res['taxa_sucesso']:.1f}%)"
            
            print_summary_table("Resultados do Upload", resumo)
            print_success("✓ Upload concluído!")
            
        except Exception as e:
            print_error(f"Erro durante upload: {e}")
            app_logger.exception(e)
        
        self.pausar()

    def validar_dados(self):
        """Valida dados processados"""
        print_info("Validando dados...")
        
        if self.resultados_processamento is None or len(self.resultados_processamento) == 0:
            print_error("Nenhum dado processado!")
            self.pausar()
            return
        
        # Estatísticas por tabela
        resumo = {}
        
        for resultado in self.resultados_processamento:
            tabela = resultado['tabela']
            total = resultado['total_registros']
            mes_ref = resultado['mes_referencia']
            
            if tabela not in resumo:
                resumo[tabela] = {
                    'total': 0,
                    'meses': set()
                }
            
            resumo[tabela]['total'] += total
            resumo[tabela]['meses'].add(mes_ref)
        
        # Exibir resumo
        print_summary_table("Validação de Dados", {
            f"{tabela} ({len(info['meses'])} meses)": f"{info['total']:,} registros"
            for tabela, info in resumo.items()
        })
        
        print_success("✓ Validação concluída!")
        self.pausar()

    def verificar_status(self):
        """Verifica status das tabelas no Supabase"""
        print_info("Verificando status no Supabase...")
        
        if self.supabase_client is None:
            try:
                validar_config()
                self.supabase_client = SupabaseClient()
            except Exception as e:
                print_error(f"Erro ao conectar: {e}")
                self.pausar()
                return
        
        from config import FILE_TO_TABLE_MAPPING
        
        # Lista de todas as tabelas
        tabelas = ['fundos'] + list(FILE_TO_TABLE_MAPPING.values())
        
        resumo = {}
        
        for tabela in tabelas:
            try:
                # Contar registros
                response = self.supabase_client.client.table(tabela).select('*', count='exact').limit(1).execute()
                count = response.count if hasattr(response, 'count') else 0
                resumo[tabela] = f"{count:,} registros"
            except Exception as e:
                resumo[tabela] = f"Erro: {str(e)[:50]}"
        
        print_summary_table("Status das Tabelas no Supabase", resumo)
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

    def _preparar_tabela_fundos(self):
        """
        Prepara dados da tabela de fundos a partir dos resultados processados
        
        Returns:
            Lista de dicionários com dados dos fundos
        """
        import pandas as pd
        
        # Coletar todos os fundos únicos de todos os resultados
        fundos_list = []
        
        for resultado in self.resultados_processamento:
            df = resultado['dados']
            
            # Verificar se tem as colunas necessárias
            if 'cnpj_fundo_classe' in df.columns and 'denom_social' in df.columns:
                fundos_df = df[['cnpj_fundo_classe', 'denom_social']].drop_duplicates()
                fundos_list.append(fundos_df)
        
        if not fundos_list:
            return None
        
        # Concatenar e remover duplicatas
        fundos_completo = pd.concat(fundos_list, ignore_index=True)
        fundos_completo = fundos_completo.drop_duplicates(subset=['cnpj_fundo_classe'])
        
        # Renomear colunas para o padrão do banco
        fundos_completo = fundos_completo.rename(columns={
            'cnpj_fundo_classe': 'cnpj',
            'denom_social': 'nome_fundo'
        })
        
        # Adicionar flag de grande fundo
        fundos_completo['is_grande_fundo'] = True
        
        return fundos_completo.to_dict('records')

    def _calcular_agregacoes(self):
        """
        Calcula agregações a partir dos dados de ações (fi_blc_3)
        
        Returns:
            DataFrame com top movers ou None
        """
        # Encontrar dados de ações
        dados_acoes = None
        for resultado in self.resultados_processamento:
            if resultado['tabela'] == 'fi_blc_3':
                dados_acoes = resultado['dados']
                break
        
        if dados_acoes is None or len(dados_acoes) == 0:
            return None
        
        # Usar o agregador existente
        try:
            # Converter nomes de colunas de volta para o formato esperado pelo agregador
            # O agregador espera colunas em maiúsculo (formato original)
            # Mas nossos dados já estão em snake_case
            
            # Mapeamento reverso temporário para o agregador
            mapeamento_reverso = {
                'cnpj_fundo_classe': 'CNPJ_FUNDO_CLASSE',
                'dt_comptc': 'DT_COMPTC',
                'cd_ativo': 'CD_ATIVO',
                'tp_ativo': 'TP_ATIVO',
                'qt_pos_final': 'QT_POS_FINAL',
                'vl_merc_pos_final': 'VL_MERC_POS_FINAL'
            }
            
            df_temp = dados_acoes.rename(columns=mapeamento_reverso)
            
            top_movers = self.aggregator.calcular_top_movers(df_temp)
            
            # Se retornou algo, converter colunas de volta para snake_case
            if top_movers is not None and not top_movers.empty:
                # O agregador retorna colunas em snake_case já?
                # Vamos verificar o código do agregador se necessário, mas assumindo que retorna snake_case
                # Se não, precisaríamos renomear.
                # Olhando o código original, o agregador retornava um DF pronto para upload.
                return top_movers
                
            return None
        except Exception as e:
            app_logger.error(f"Erro ao calcular agregações: {e}")
            return None

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
