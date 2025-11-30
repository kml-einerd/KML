"""
Sistema de Logging estruturado usando Loguru
"""

from loguru import logger
import sys
from pathlib import Path
from config import LOG_LEVEL, LOG_FORMAT, LOG_FILE, LOG_ROTATION, LOG_RETENTION

def setup_logger(log_file: Path = LOG_FILE):
    """
    Configura o logger da aplicação

    Args:
        log_file: Caminho para o arquivo de log

    Returns:
        logger configurado
    """

    # Remover handler padrão
    logger.remove()

    # Handler para console (colorido)
    logger.add(
        sys.stdout,
        format=LOG_FORMAT,
        level=LOG_LEVEL,
        colorize=True
    )

    # Handler para arquivo (rotação automática)
    logger.add(
        log_file,
        format=LOG_FORMAT,
        level=LOG_LEVEL,
        rotation=LOG_ROTATION,
        retention=LOG_RETENTION,
        compression="zip"
    )

    logger.info("Logger configurado com sucesso")

    return logger

# Instância global do logger
app_logger = setup_logger()

if __name__ == '__main__':
    # Teste de logging
    app_logger.debug("Debug message")
    app_logger.info("Info message")
    app_logger.warning("Warning message")
    app_logger.error("Error message")
    app_logger.success("Success message")
