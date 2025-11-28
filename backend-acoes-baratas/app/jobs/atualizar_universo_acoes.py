"""
Job para atualizar o universo de ações da B3.
Deve ser executado 1x por semana.
Atualizado para usar brapi.dev API.
"""
import logging
import time

from app.services.sync_brapi import BrapiSync
from app.services.acoes_service import AcoesService
from app.config import obter_configuracoes

logging.basicConfig(
    level=logging.INFO, format="%(asctime)s - %(name)s - %(levelname)s - %(message)s"
)
logger = logging.getLogger(__name__)


def main():
    """Atualiza o universo de ações da B3 usando brapi.dev."""
    logger.info("=== Iniciando atualização do universo de ações (brapi.dev) ===")

    # Obter configurações
    config = obter_configuracoes()

    # Inicializar serviços
    brapi_sync = BrapiSync(api_key=config.brapi_api_key)
    acoes_service = AcoesService()

    # Obter lista de tickers da B3
    tickers = brapi_sync.obter_tickers_disponiveis()
    logger.info(f"Total de tickers a processar: {len(tickers)}")

    # Buscar informações de cada ação
    acoes_atualizadas = []
    for i, ticker in enumerate(tickers, 1):
        logger.info(f"[{i}/{len(tickers)}] Processando {ticker}...")

        acao_info = brapi_sync.obter_info_acao(ticker)
        if acao_info:
            acoes_atualizadas.append(acao_info)
            logger.info(f"  ✓ {ticker} - {acao_info.nome_curto}")
        else:
            logger.warning(f"  ✗ Não foi possível obter dados de {ticker}")

        # Delay para respeitar rate limit (plano gratuito)
        # brapi.dev é mais generoso, mas ainda precisamos ser cuidadosos
        if i < len(tickers):
            time.sleep(0.5)  # 0.5 segundo entre requisições

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
