"""
Job para atualizar o universo de ações da B3.
Deve ser executado 1x por semana.
"""
import logging

from app.services.sync_yfinance import YFinanceSync
from app.services.acoes_service import AcoesService

logging.basicConfig(
    level=logging.INFO, format="%(asctime)s - %(name)s - %(levelname)s - %(message)s"
)
logger = logging.getLogger(__name__)


def main():
    """Atualiza o universo de ações da B3."""
    logger.info("=== Iniciando atualização do universo de ações ===")

    # Inicializar serviços
    yf_sync = YFinanceSync()
    acoes_service = AcoesService()

    # Obter lista de tickers da B3
    tickers = yf_sync.obter_tickers_b3()
    logger.info(f"Total de tickers a processar: {len(tickers)}")

    # Buscar informações de cada ação
    acoes_atualizadas = []
    for i, ticker in enumerate(tickers, 1):
        logger.info(f"[{i}/{len(tickers)}] Processando {ticker}...")

        acao_info = yf_sync.obter_info_acao(ticker)
        if acao_info:
            acoes_atualizadas.append(acao_info)
            logger.info(f"  ✓ {ticker} - {acao_info.nome_curto}")
        else:
            logger.warning(f"  ✗ Não foi possível obter dados de {ticker}")

    # Salvar no banco de dados
    if acoes_atualizadas:
        logger.info(f"Salvando {len(acoes_atualizadas)} ações no banco...")
        acoes_service.inserir_varias(acoes_atualizadas)
        logger.info("✓ Ações salvas com sucesso!")
    else:
        logger.warning("Nenhuma ação foi atualizada.")

    logger.info("=== Atualização do universo de ações concluída ===")


if __name__ == "__main__":
    main()
