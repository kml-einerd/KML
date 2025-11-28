"""
Job para atualizar preços diários das ações.
Deve ser executado 1x por dia.
Atualiza apenas os dias que ainda não existem no banco.
"""
import logging
from datetime import date, timedelta

from app.services.sync_yfinance import YFinanceSync
from app.services.precos_service import PrecosService
from app.services.acoes_service import AcoesService

logging.basicConfig(
    level=logging.INFO, format="%(asctime)s - %(name)s - %(levelname)s - %(message)s"
)
logger = logging.getLogger(__name__)


def main():
    """Atualiza preços diários de todas as ações ativas."""
    logger.info("=== Iniciando atualização de preços diários ===")

    # Inicializar serviços
    yf_sync = YFinanceSync()
    precos_service = PrecosService()
    acoes_service = AcoesService()

    # Obter todas as ações ativas
    acoes = acoes_service.obter_todas_ativas()
    logger.info(f"Total de ações ativas: {len(acoes)}")

    # Definir período para atualização
    # Buscar últimos 7 dias para garantir que não perca nenhum dia
    data_fim = date.today()
    data_inicio = data_fim - timedelta(days=7)

    logger.info(f"Período de atualização: {data_inicio} até {data_fim}")

    # Atualizar preços de cada ação
    total_precos_inseridos = 0
    for i, acao in enumerate(acoes, 1):
        logger.info(f"[{i}/{len(acoes)}] Processando {acao.ticker}...")

        # Buscar histórico
        precos = yf_sync.obter_historico_precos(acao.ticker, data_inicio, data_fim)

        if precos:
            # Salvar no banco (upsert para não duplicar)
            precos_service.inserir_varios(precos)
            total_precos_inseridos += len(precos)
            logger.info(f"  ✓ {acao.ticker} - {len(precos)} dias atualizados")
        else:
            logger.warning(f"  ✗ Não foi possível obter preços de {acao.ticker}")

    logger.info(f"Total de preços inseridos/atualizados: {total_precos_inseridos}")
    logger.info("=== Atualização de preços diários concluída ===")


if __name__ == "__main__":
    main()
