"""
Job para atualizar fundamentos das ações.
Deve ser executado 1x por semana.
"""
import logging

from app.services.sync_yfinance import YFinanceSync
from app.services.fundamentos_service import FundamentosService
from app.services.acoes_service import AcoesService

logging.basicConfig(
    level=logging.INFO, format="%(asctime)s - %(name)s - %(levelname)s - %(message)s"
)
logger = logging.getLogger(__name__)


def main():
    """Atualiza fundamentos de todas as ações ativas."""
    logger.info("=== Iniciando atualização de fundamentos ===")

    # Inicializar serviços
    yf_sync = YFinanceSync()
    fundamentos_service = FundamentosService()
    acoes_service = AcoesService()

    # Obter todas as ações ativas
    acoes = acoes_service.obter_todas_ativas()
    logger.info(f"Total de ações ativas: {len(acoes)}")

    # Buscar fundamentos de cada ação
    fundamentos_atualizados = []
    for i, acao in enumerate(acoes, 1):
        logger.info(f"[{i}/{len(acoes)}] Processando {acao.ticker}...")

        fundamentos = yf_sync.obter_fundamentos(acao.ticker)
        if fundamentos:
            # Calcular scores
            fundamentos = fundamentos_service.calcular_scores(fundamentos)
            fundamentos_atualizados.append(fundamentos)

            logger.info(
                f"  ✓ {acao.ticker} - Score Geral: {fundamentos.score_geral or 'N/A'}"
            )
        else:
            logger.warning(f"  ✗ Não foi possível obter fundamentos de {acao.ticker}")

    # Salvar no banco de dados
    if fundamentos_atualizados:
        logger.info(f"Salvando {len(fundamentos_atualizados)} fundamentos no banco...")
        fundamentos_service.inserir_varios(fundamentos_atualizados)
        logger.info("✓ Fundamentos salvos com sucesso!")
    else:
        logger.warning("Nenhum fundamento foi atualizado.")

    logger.info("=== Atualização de fundamentos concluída ===")


if __name__ == "__main__":
    main()
