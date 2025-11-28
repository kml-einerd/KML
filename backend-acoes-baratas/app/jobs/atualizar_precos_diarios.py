"""
Job para atualizar preços diários das ações.
Deve ser executado 1x por dia.
Atualiza apenas os dias que ainda não existem no banco.
Atualizado para usar brapi.dev API.
"""
import logging
import time
from datetime import date, timedelta

from app.services.sync_brapi import BrapiSync
from app.services.precos_service import PrecosService
from app.services.acoes_service import AcoesService
from app.config import obter_configuracoes

logging.basicConfig(
    level=logging.INFO, format="%(asctime)s - %(name)s - %(levelname)s - %(message)s"
)
logger = logging.getLogger(__name__)


def main():
    """Atualiza preços diários de todas as ações ativas usando brapi.dev."""
    logger.info("=== Iniciando atualização de preços diários (brapi.dev) ===")

    # Obter configurações
    config = obter_configuracoes()

    # Inicializar serviços
    brapi_sync = BrapiSync(api_key=config.brapi_api_key)
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
        precos = brapi_sync.obter_historico_precos(acao.ticker, data_inicio, data_fim)

        if precos:
            # Salvar no banco (upsert para não duplicar)
            precos_service.inserir_varios(precos)
            total_precos_inseridos += len(precos)
            logger.info(f"  ✓ {acao.ticker} - {len(precos)} dias atualizados")
        else:
            logger.warning(f"  ✗ Não foi possível obter preços de {acao.ticker}")

        # Delay para respeitar rate limit
        if i < len(acoes):
            time.sleep(0.5)

    logger.info(f"Total de preços inseridos/atualizados: {total_precos_inseridos}")
    logger.info("=== Atualização de preços diários concluída ===")


if __name__ == "__main__":
    main()
