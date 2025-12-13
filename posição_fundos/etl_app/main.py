#!/usr/bin/env python3
"""
ETL Pipeline - Sistema de Análise de Fundos Top 100
Processa dados da CVM e sobe para Supabase
"""
import os
import sys
import argparse
from datetime import datetime
from dotenv import load_dotenv

# Adicionar path do projeto
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from utils import setup_logger
from processors import PatrimonioProcessor, AcoesProcessor, CadastroProcessor
from uploaders import SupabaseUploader


class ETLPipeline:
    """Pipeline principal do ETL"""

    def __init__(self, ano: int, mes: int, top_n: int = 100):
        """
        Inicializa pipeline

        Args:
            ano: Ano de referência
            mes: Mês de referência
            top_n: Quantidade de grupos no Top
        """
        self.ano = ano
        self.mes = mes
        self.top_n = top_n

        # Carregar variáveis de ambiente
        load_dotenv()

        # Setup logger
        log_level = os.getenv('LOG_LEVEL', 'INFO')
        self.logger = setup_logger('ETL', log_level)

        # Paths
        self.base_dir = os.path.dirname(os.path.abspath(__file__))
        self.source_dir = os.path.join(os.path.dirname(self.base_dir), 'source')
        self.processed_dir = os.path.join(os.path.dirname(self.base_dir), 'processed')

        # Criar diretório de processados se não existir
        os.makedirs(self.processed_dir, exist_ok=True)

        # Configurações Supabase
        supabase_url = os.getenv('SUPABASE_URL')
        supabase_key = os.getenv('SUPABASE_KEY')

        if not supabase_url or not supabase_key:
            raise ValueError(
                "Credenciais do Supabase não encontradas!\n"
                "Configure SUPABASE_URL e SUPABASE_KEY no arquivo .env"
            )

        # Inicializar componentes
        self.uploader = SupabaseUploader(supabase_url, supabase_key, self.logger)
        self.pl_processor = PatrimonioProcessor(self.source_dir, self.logger)
        self.acoes_processor = AcoesProcessor(self.source_dir, self.logger)
        self.cadastro_processor = CadastroProcessor(self.source_dir, self.logger)

        self.batch_size = int(os.getenv('BATCH_SIZE', 1000))

    def run(self):
        """Executa pipeline completo"""
        self.logger.info("=" * 70)
        self.logger.info(f"🚀 INICIANDO ETL - Top {self.top_n} Grupos")
        self.logger.info(f"📅 Período: {self.mes:02d}/{self.ano}")
        self.logger.info("=" * 70)

        try:
            # 1. Processar Patrimônio Líquido e identificar Top grupos
            self.logger.info("\n[1/5] Processando Patrimônio Líquido...")
            df_pl, top_groups = self.pl_processor.process(self.ano, self.mes, self.top_n)

            self.logger.info(f"\n📊 Top {self.top_n} Grupos Identificados:")
            for i, group in enumerate(top_groups[:10], 1):
                self.logger.info(f"   {i:2d}. {group}")
            if len(top_groups) > 10:
                self.logger.info(f"   ... e mais {len(top_groups) - 10} grupos")

            # Estatísticas PL
            stats_pl = self.pl_processor.get_summary_stats(df_pl)
            self.logger.info(f"\n💰 Estatísticas de PL:")
            self.logger.info(f"   Total de fundos: {stats_pl['total_fundos']:,}")
            self.logger.info(f"   Total de grupos: {stats_pl['total_grupos']:,}")
            self.logger.info(f"   PL total: R$ {stats_pl['pl_total_bilhoes']:.2f} bi")

            # 2. Processar Ações (apenas Top grupos)
            self.logger.info(f"\n[2/5] Processando Posições em Ações (Top {self.top_n})...")
            df_acoes = self.acoes_processor.process(self.ano, self.mes, df_pl, top_groups)

            # Estatísticas Ações
            stats_acoes = self.acoes_processor.get_summary_stats(df_acoes)
            self.logger.info(f"\n📈 Estatísticas de Ações:")
            self.logger.info(f"   Total de posições: {stats_acoes['total_posicoes']:,}")
            self.logger.info(f"   Total de tickers: {stats_acoes['total_tickers']:,}")
            self.logger.info(f"   Valor total: R$ {stats_acoes['valor_total_mercado_bilhoes']:.2f} bi")
            self.logger.info(f"   Fluxo líquido: R$ {stats_acoes['fluxo_liquido_bilhoes']:.2f} bi")

            # 3. Processar Cadastro (apenas Top grupos)
            self.logger.info(f"\n[3/5] Processando Cadastro de Fundos (Top {self.top_n})...")
            df_cadastro = self.cadastro_processor.process(self.ano, self.mes, df_pl, top_groups)

            # 4. Upload para Supabase
            self.logger.info("\n[4/5] Fazendo Upload para Supabase...")

            # Salvar dados localmente antes do upload (backup)
            self.logger.info("Salvando dados localmente...")
            self._save_processed_data(df_pl, df_acoes, df_cadastro)

            # Upload PL
            self.logger.info("\nUpload: Patrimônio Líquido")
            # TODO: Ajustar para tabelas corretas do Supabase
            # self.uploader.upload_dataframe(df_pl, 'dim_patrimonio_liquido', self.batch_size)

            # Upload Ações
            self.logger.info("\nUpload: Posições em Ações")
            # TODO: Ajustar para tabelas corretas do Supabase
            # self.uploader.upload_dataframe(df_acoes, 'fato_posicoes', self.batch_size)

            # Upload Cadastro
            self.logger.info("\nUpload: Cadastro de Fundos")
            # TODO: Ajustar para tabelas corretas do Supabase
            # self.uploader.upload_dataframe(df_cadastro, 'dim_fundos', self.batch_size)

            # 5. Calcular Ranking Top 100
            self.logger.info("\n[5/5] Calculando Ranking Top 100...")
            result = self.uploader.execute_function(
                'atualizar_ranking_top100_v2',
                {'p_ano': self.ano, 'p_mes': self.mes}
            )

            self.logger.info(f"✓ Ranking calculado: {result}")

            # Resumo final
            self.logger.info("\n" + "=" * 70)
            self.logger.info("✅ ETL CONCLUÍDO COM SUCESSO!")
            self.logger.info("=" * 70)
            self.logger.info(f"\n📊 Resumo:")
            self.logger.info(f"   • Top {self.top_n} grupos processados")
            self.logger.info(f"   • {stats_pl['total_fundos']:,} fundos")
            self.logger.info(f"   • {stats_acoes['total_posicoes']:,} posições em ações")
            self.logger.info(f"   • R$ {stats_acoes['valor_total_mercado_bilhoes']:.2f} bi em ações")
            self.logger.info(f"\n💾 Dados salvos em: {self.processed_dir}")
            self.logger.info("\n🎯 Próximos passos:")
            self.logger.info("   1. Consulte: SELECT * FROM v_top100_atual;")
            self.logger.info("   2. Dashboard: SELECT * FROM v_dashboard_top100;")

        except Exception as e:
            self.logger.error(f"\n❌ ERRO NO PIPELINE: {str(e)}", exc_info=True)
            raise

    def _save_processed_data(self, df_pl, df_acoes, df_cadastro):
        """Salva dados processados localmente (backup)"""
        timestamp = f"{self.ano}{self.mes:02d}"

        df_pl.to_csv(
            os.path.join(self.processed_dir, f"pl_{timestamp}.csv"),
            index=False, encoding='utf-8'
        )

        df_acoes.to_csv(
            os.path.join(self.processed_dir, f"acoes_{timestamp}.csv"),
            index=False, encoding='utf-8'
        )

        df_cadastro.to_csv(
            os.path.join(self.processed_dir, f"cadastro_{timestamp}.csv"),
            index=False, encoding='utf-8'
        )

        self.logger.info("✓ Dados salvos localmente")


def main():
    """Função principal"""
    parser = argparse.ArgumentParser(
        description='ETL Pipeline - Sistema de Análise de Fundos Top 100'
    )

    parser.add_argument(
        '--ano',
        type=int,
        default=datetime.now().year,
        help='Ano de referência (default: ano atual)'
    )

    parser.add_argument(
        '--mes',
        type=int,
        required=True,
        help='Mês de referência (1-12)'
    )

    parser.add_argument(
        '--top',
        type=int,
        default=100,
        help='Quantidade de grupos no Top (default: 100)'
    )

    args = parser.parse_args()

    # Validações
    if not 1 <= args.mes <= 12:
        print("❌ Erro: Mês deve estar entre 1 e 12")
        sys.exit(1)

    if args.top < 1:
        print("❌ Erro: Top deve ser maior que 0")
        sys.exit(1)

    # Executar pipeline
    pipeline = ETLPipeline(args.ano, args.mes, args.top)
    pipeline.run()


if __name__ == '__main__':
    main()
