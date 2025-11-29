"""
Job para atualizar informações extras das ações usando yfinance.
Busca dados fixos da empresa (setor, indústria, descrição, etc).
Deve ser executado semanalmente ou quando necessário.
"""
import logging
import time

from app.services.acoes_service import AcoesService
from app.services.acoes_info_service import AcoesInfoService

logging.basicConfig(
    level=logging.INFO, format="%(asctime)s - %(name)s - %(levelname)s - %(message)s"
)
logger = logging.getLogger(__name__)


def main():
    """Atualiza informações extras das ações usando yfinance."""
    logger.info("=== Iniciando atualização de informações extras das ações (yfinance) ===")

    # Inicializar serviços
    acoes_service = AcoesService()
    acoes_info_service = AcoesInfoService()

    # Obter todas as ações ativas
    acoes = acoes_service.obter_todas_ativas()
    logger.info(f"Total de ações ativas a processar: {len(acoes)}")

    if not acoes:
        logger.warning("Nenhuma ação ativa encontrada na tabela 'acoes'")
        return

    # Buscar informações extras de cada ação
    infos_atualizadas = []
    falhas = []

    for i, acao in enumerate(acoes, 1):
        ticker = acao.ticker
        symbol = acao.symbol or ticker  # Usar symbol se disponível, senão usar ticker

        logger.info(f"[{i}/{len(acoes)}] Processando {ticker} ({symbol})...")

        # Buscar informações do yfinance
        info = acoes_info_service.obter_info_yfinance(ticker, symbol)

        if info:
            infos_atualizadas.append(info)
            logger.info(f"  ✓ {ticker} - Informações coletadas")
        else:
            falhas.append(ticker)
            logger.warning(f"  ✗ Não foi possível obter informações de {ticker}")

        # Delay para não sobrecarregar o yfinance
        # yfinance não tem rate limit oficial, mas é bom ser conservador
        if i < len(acoes):
            time.sleep(1)  # 1 segundo entre requisições

    # Salvar no banco de dados em lote
    if infos_atualizadas:
        logger.info(f"\nSalvando {len(infos_atualizadas)} informações no banco...")
        resultado = acoes_info_service.inserir_varias(infos_atualizadas)

        if resultado:
            logger.info(f"✓ {len(resultado)} informações salvas com sucesso!")
        else:
            logger.error("✗ Erro ao salvar informações no banco")
    else:
        logger.warning("Nenhuma informação foi coletada.")

    # Relatório final
    logger.info("\n=== Resumo da atualização ===")
    logger.info(f"Total de ações processadas: {len(acoes)}")
    logger.info(f"Informações coletadas com sucesso: {len(infos_atualizadas)}")
    logger.info(f"Falhas: {len(falhas)}")

    if falhas:
        logger.warning(f"Ações que falharam: {', '.join(falhas)}")

    logger.info("=== Atualização de informações extras concluída ===")


if __name__ == "__main__":
    main()
