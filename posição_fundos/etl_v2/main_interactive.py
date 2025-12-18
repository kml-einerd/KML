#!/usr/bin/env python3
"""
ETL Interativo V2 - Análise de Fundos para Investidor Comum
Menu dinâmico para selecionar meses e tipos de dados
"""

import os
import sys
from pathlib import Path
from datetime import datetime
import questionary
from rich.console import Console
from rich.table import Table
from rich.panel import Panel
from rich import print as rprint

# Adicionar path do projeto
sys.path.insert(0, str(Path(__file__).parent))

console = Console()

# Mapeamento de meses
MESES = {
    'ago': ('08', '2025', 'Agosto 2025'),
    'set': ('09', '2025', 'Setembro 2025'),
    'out': ('10', '2025', 'Outubro 2025'),
    'nov': ('11', '2025', 'Novembro 2025'),
}

# Tipos de dados disponíveis
TIPOS_DADOS = {
    'acoes': {
        'nome': 'Ações B3 (principal)',
        'arquivos': ['PL', 'BLC_4'],
        'descricao': 'Movimentos de compra/venda de ações',
        'relevancia': '⭐⭐⭐⭐⭐'
    },
    'titulos': {
        'nome': 'Títulos Públicos',
        'arquivos': ['PL', 'BLC_1'],
        'descricao': 'LFT, NTN-B, LTN, etc.',
        'relevancia': '⭐⭐'
    },
    'exterior': {
        'nome': 'Investimento Exterior',
        'arquivos': ['PL', 'BLC_7'],
        'descricao': 'Fundos offshore, ETFs internacionais',
        'relevancia': '⭐⭐⭐'
    },
}


class ETLInteractive:
    """Pipeline ETL com interface interativa"""

    def __init__(self, source_dir: str = None):
        self.source_dir = source_dir or self._find_source_dir()
        self.meses_disponiveis = self._scan_meses()

    def _find_source_dir(self) -> str:
        """Encontra pasta source automaticamente"""
        current = Path(__file__).parent
        while current != current.parent:
            source = current / 'source'
            if source.exists():
                return str(source)
            current = current.parent
        raise FileNotFoundError("Pasta 'source' não encontrada")

    def _scan_meses(self) -> dict:
        """Escaneia pastas disponíveis em source"""
        source_path = Path(self.source_dir)
        meses_encontrados = {}

        for key, (mes, ano, nome) in MESES.items():
            pasta = source_path / f"cda_fi_{key}"
            if pasta.exists():
                # Contar arquivos
                arquivos = list(pasta.glob("*.csv"))
                tamanho_mb = sum(f.stat().st_size for f in arquivos) / (1024 * 1024)

                meses_encontrados[key] = {
                    'mes': mes,
                    'ano': ano,
                    'nome': nome,
                    'pasta': str(pasta),
                    'qtd_arquivos': len(arquivos),
                    'tamanho_mb': tamanho_mb
                }

        return meses_encontrados

    def mostrar_banner(self):
        """Mostra banner inicial"""
        banner = """
╔═══════════════════════════════════════════════════════════════╗
║                                                               ║
║         📊  ANÁLISE DE FUNDOS CVM - V2.0                     ║
║         Para Investidores Que Querem Copiar os Grandes       ║
║                                                               ║
╚═══════════════════════════════════════════════════════════════╝
        """
        console.print(banner, style="bold cyan")

    def mostrar_meses_disponiveis(self):
        """Mostra tabela com meses disponíveis"""
        table = Table(title="📅 Meses Disponíveis", show_header=True)
        table.add_column("Mês", style="cyan")
        table.add_column("Arquivos", justify="right")
        table.add_column("Tamanho", justify="right")
        table.add_column("Status", justify="center")

        for key in sorted(self.meses_disponiveis.keys()):
            info = self.meses_disponiveis[key]
            table.add_row(
                info['nome'],
                str(info['qtd_arquivos']),
                f"{info['tamanho_mb']:.1f} MB",
                "✓ Pronto"
            )

        console.print(table)
        print()

    def selecionar_meses(self) -> list:
        """Menu para selecionar meses"""
        choices = [
            {
                'name': f"{info['nome']} ({info['qtd_arquivos']} arquivos, {info['tamanho_mb']:.1f} MB)",
                'value': key
            }
            for key, info in sorted(self.meses_disponiveis.items())
        ]

        selecionados = questionary.checkbox(
            '📅 Selecione os meses para processar:',
            choices=choices
        ).ask()

        return selecionados

    def selecionar_tipo_dados(self) -> list:
        """Menu para selecionar tipos de dados"""
        choices = [
            {
                'name': f"{dados['nome']} {dados['relevancia']} - {dados['descricao']}",
                'value': key,
                'checked': key == 'acoes'  # Ações marcado por padrão
            }
            for key, dados in TIPOS_DADOS.items()
        ]

        selecionados = questionary.checkbox(
            '📊 Selecione os tipos de dados:',
            choices=choices
        ).ask()

        return selecionados

    def confirmar_processamento(self, meses: list, tipos: list) -> bool:
        """Mostra resumo e confirma processamento"""
        console.print("\n" + "="*60, style="yellow")
        console.print("📋 RESUMO DO PROCESSAMENTO", style="bold yellow")
        console.print("="*60 + "\n", style="yellow")

        # Meses
        console.print("📅 Meses selecionados:", style="bold")
        for mes in meses:
            info = self.meses_disponiveis[mes]
            console.print(f"   • {info['nome']}", style="cyan")
        print()

        # Tipos
        console.print("📊 Tipos de dados:", style="bold")
        for tipo in tipos:
            dados = TIPOS_DADOS[tipo]
            console.print(f"   • {dados['nome']} {dados['relevancia']}", style="cyan")
        print()

        # Estimativa
        total_arquivos = len(meses) * sum(len(TIPOS_DADOS[t]['arquivos']) for t in tipos)
        console.print(f"📦 Total de arquivos a processar: {total_arquivos}", style="bold green")
        console.print(f"⏱️  Tempo estimado: ~{total_arquivos * 2} segundos\n", style="green")

        return questionary.confirm(
            '✅ Deseja prosseguir com o processamento?',
            default=True
        ).ask()

    def processar(self, meses: list, tipos: list):
        """Processa os dados selecionados"""
        console.print("\n🚀 INICIANDO PROCESSAMENTO...\n", style="bold green")

        # Importar processadores
        from processors import GruposProcessor, AcoesProcessor
        from uploader import SupabaseUploader
        from dotenv import load_dotenv
        import os
        from datetime import datetime

        # Carregar credenciais
        load_dotenv()
        supabase_url = os.getenv('SUPABASE_URL')
        supabase_key = os.getenv('SUPABASE_KEY')

        if not supabase_url or not supabase_key:
            console.print("\n❌ Credenciais do Supabase não encontradas no .env!", style="red")
            console.print("Configure SUPABASE_URL e SUPABASE_KEY\n", style="yellow")
            return

        # Inicializar
        grupos_proc = GruposProcessor()
        acoes_proc = AcoesProcessor()
        uploader = SupabaseUploader(supabase_url, supabase_key)

        # Processar cada mês
        for mes_key in meses:
            info = self.meses_disponiveis[mes_key]
            console.print(f"\n📅 Processando {info['nome']}...", style="cyan")

            pasta = Path(info['pasta'])
            ano = info['ano']
            mes = info['mes']

            # Data de referência (último dia do mês)
            if mes == '12':
                mes_ref = f"{ano}-{mes}-31"
            else:
                # Pegar último dia do mês
                from calendar import monthrange
                ultimo_dia = monthrange(int(ano), int(mes))[1]
                mes_ref = f"{ano}-{mes}-{ultimo_dia:02d}"

            # Processar apenas ações por enquanto
            if 'acoes' in tipos:
                console.print("   📊 Processando ações...", style="dim")

                # 1. Processar PL e identificar Top 100
                arquivo_pl = pasta / f"cda_fi_PL_{ano}{mes}.csv"
                df_grupos, mapeamento = grupos_proc.processar(str(arquivo_pl), top_n=100)

                stats_grupos = grupos_proc.get_stats(df_grupos)
                console.print(f"      ✓ {stats_grupos['total_grupos']} grupos Top 100", style="green")
                console.print(f"      ✓ PL total: R$ {stats_grupos['pl_total_bilhoes']:.2f} bi", style="green")

                # 2. Processar ações (BLC_4)
                arquivo_blc4 = pasta / f"cda_fi_BLC_4_{ano}{mes}.csv"
                df_acoes = acoes_proc.processar(str(arquivo_blc4), mapeamento, mes_ref)

                stats_acoes = acoes_proc.get_stats(df_acoes)
                console.print(f"      ✓ {stats_acoes['total_posicoes']:,} posições", style="green")
                console.print(f"      ✓ {stats_acoes['total_tickers']} tickers", style="green")

                # 3. Upload para Supabase
                console.print("   📤 Upload para Supabase...", style="dim")

                # Limpar mês anterior
                uploader.limpar_mes(mes_ref)

                # Upload grupos
                uploader.upsert_grupos(df_grupos)

                # Upload ações
                uploader.upload_acoes(df_acoes)

                # Calcular resumo
                uploader.atualizar_resumo(mes_ref)

                # Verificar
                stats = uploader.verificar_dados(mes_ref)
                console.print(f"      ✓ {stats['grupos']} grupos | {stats['acoes']:,} ações | {stats['resumo']} tickers", style="green")

        console.print("\n✅ PROCESSAMENTO CONCLUÍDO!\n", style="bold green")

    def mostrar_proximos_passos(self):
        """Mostra próximos passos"""
        panel = Panel(
            """
1. Acesse o Supabase SQL Editor
2. Execute: SELECT * FROM v_top_compras_mes LIMIT 10;
3. Veja as ações mais compradas pelos fundos!

Ou consulte:
• v_consenso_mercado - Ver consenso de compra/venda
• v_movimentos_grupo - Ver o que um grupo específico fez
            """,
            title="🎯 Próximos Passos",
            border_style="green"
        )
        console.print(panel)

    def run(self):
        """Executa pipeline interativo"""
        # Banner
        self.mostrar_banner()

        # Mostrar meses disponíveis
        self.mostrar_meses_disponiveis()

        # Seleção de meses
        meses = self.selecionar_meses()
        if not meses:
            console.print("❌ Nenhum mês selecionado. Cancelando...", style="red")
            return

        print()

        # Seleção de tipos
        tipos = self.selecionar_tipo_dados()
        if not tipos:
            console.print("❌ Nenhum tipo de dado selecionado. Cancelando...", style="red")
            return

        print()

        # Confirmação
        if not self.confirmar_processamento(meses, tipos):
            console.print("\n❌ Processamento cancelado pelo usuário.", style="yellow")
            return

        # Processar
        self.processar(meses, tipos)

        # Próximos passos
        self.mostrar_proximos_passos()


def main():
    """Função principal"""
    try:
        etl = ETLInteractive()
        etl.run()
    except KeyboardInterrupt:
        console.print("\n\n⚠️  Interrompido pelo usuário.", style="yellow")
    except Exception as e:
        console.print(f"\n❌ ERRO: {str(e)}", style="bold red")
        raise


if __name__ == '__main__':
    main()
