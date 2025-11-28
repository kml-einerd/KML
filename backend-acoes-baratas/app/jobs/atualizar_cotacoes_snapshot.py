"""
Job para atualizar snapshots de cotações em tempo real.
Deve ser executado a cada 5 minutos (ou outra frequência configurada).
"""
import logging

from app.services.sync_yfinance import YFinanceSync
from app.services.cotacoes_service import CotacoesService
from app.services.acoes_service import AcoesService

logging.basicConfig(
    level=logging.INFO, format="%(asctime)s - %(name)s - %(levelname)s - %(message)s"
)
logger = logging.getLogger(__name__)


def main():
    """Atualiza snapshots de cotações de todas as ações ativas."""
    logger.info("=== Iniciando atualização de cotações (snapshot) ===")

    # Inicializar serviços
    yf_sync = YFinanceSync()
    cotacoes_service = CotacoesService()
    acoes_service = AcoesService()

    # Obter todas as ações ativas
    acoes = acoes_service.obter_todas_ativas()
    logger.info(f"Total de ações ativas: {len(acoes)}")

    # Atualizar cotação de cada ação
    cotacoes_atualizadas = []
    for i, acao in enumerate(acoes, 1):
        logger.info(f"[{i}/{len(acoes)}] Processando {acao.ticker}...")

        cotacao = yf_sync.obter_cotacao_atual(acao.ticker)
        if cotacao:
            cotacoes_atualizadas.append(cotacao)

            preco = cotacao.preco_ultimo or 0
            variacao = cotacao.variacao_dia_percentual or 0
            logger.info(
                f"  ✓ {acao.ticker} - R$ {preco:.2f} ({variacao:+.2f}%)"
            )
        else:
            logger.warning(f"  ✗ Não foi possível obter cotação de {acao.ticker}")

    # Salvar no banco de dados
    if cotacoes_atualizadas:
        logger.info(f"Salvando {len(cotacoes_atualizadas)} cotações no banco...")
        cotacoes_service.inserir_varios(cotacoes_atualizadas)
        logger.info("✓ Cotações salvas com sucesso!")
    else:
        logger.warning("Nenhuma cotação foi atualizada.")

    logger.info("=== Atualização de cotações concluída ===")


if __name__ == "__main__":
    main()
