"""
Routers para endpoints relacionados a ações.
"""
from fastapi import APIRouter, HTTPException, Query
from typing import List, Optional
from datetime import datetime

from app.models.schemas import (
    AcaoBarataResponse,
    AcaoDetalhadaResponse,
    MetricasHistorico,
)
from app.services.acoes_service import AcoesService
from app.services.cotacoes_service import CotacoesService
from app.services.fundamentos_service import FundamentosService
from app.services.precos_service import PrecosService

router = APIRouter(prefix="/acoes", tags=["Ações"])


@router.get("/baratas", response_model=List[AcaoBarataResponse])
async def obter_acoes_baratas(
    preco_maximo: float = Query(default=101.0, description="Preço máximo em reais")
):
    """
    Retorna lista de ações com preço abaixo do valor especificado.

    - **preco_maximo**: Preço máximo para filtrar (default: 101.0)

    Retorna dados combinados de empresa, cotação e fundamentos.
    """
    # Inicializar serviços
    acoes_service = AcoesService()
    cotacoes_service = CotacoesService()
    fundamentos_service = FundamentosService()

    # Obter todas as ações ativas
    acoes = acoes_service.obter_todas_ativas()

    # Obter últimas cotações
    ultimas_cotacoes = {}
    cotacoes_list = cotacoes_service.obter_ultimas_todas_acoes()
    for cotacao in cotacoes_list:
        ultimas_cotacoes[cotacao.ticker] = cotacao

    # Obter últimos fundamentos
    ultimos_fundamentos = fundamentos_service.obter_ultimos_todos_tickers()

    # Montar resposta
    acoes_baratas = []
    for acao in acoes:
        cotacao = ultimas_cotacoes.get(acao.ticker)

        # Filtrar por preço
        if not cotacao or not cotacao.preco_ultimo:
            continue

        if cotacao.preco_ultimo >= preco_maximo:
            continue

        fundamentos = ultimos_fundamentos.get(acao.ticker)

        acao_barata = AcaoBarataResponse(
            ticker=acao.ticker,
            codigo_b3=acao.codigo_b3,
            nome_curto=acao.nome_curto,
            setor=acao.setor,
            preco_ultimo=cotacao.preco_ultimo,
            variacao_dia_percentual=cotacao.variacao_dia_percentual,
            valor_mercado=cotacao.valor_mercado,
            score_geral=fundamentos.score_geral if fundamentos else None,
            score_valuation=fundamentos.score_valuation if fundamentos else None,
            score_qualidade=fundamentos.score_qualidade if fundamentos else None,
            score_momento=fundamentos.score_momento if fundamentos else None,
        )

        acoes_baratas.append(acao_barata)

    # Ordenar por score geral (maiores primeiro)
    acoes_baratas.sort(
        key=lambda x: x.score_geral if x.score_geral is not None else -1, reverse=True
    )

    return acoes_baratas


@router.get("/{ticker}", response_model=AcaoDetalhadaResponse)
async def obter_detalhes_acao(
    ticker: str,
    periodo: str = Query(
        default="1m",
        description="Período para histórico de preços",
        pattern="^(7d|15d|1m|3m|6m|1a|3a|5a)$",
    ),
):
    """
    Retorna informações detalhadas de uma ação específica.

    - **ticker**: Código do ticker (ex: PETR4.SA)
    - **periodo**: Período para histórico (7d, 15d, 1m, 3m, 6m, 1a, 3a, 5a)

    Retorna:
    - Dados da empresa
    - Cotação atual
    - Fundamentos
    - Histórico de preços
    - Métricas calculadas (retorno e volatilidade)
    """
    # Inicializar serviços
    acoes_service = AcoesService()
    cotacoes_service = CotacoesService()
    fundamentos_service = FundamentosService()
    precos_service = PrecosService()

    # Buscar empresa
    empresa = acoes_service.obter_por_ticker(ticker)
    if not empresa:
        raise HTTPException(status_code=404, detail=f"Ação {ticker} não encontrada")

    # Buscar cotação atual
    cotacao_atual = cotacoes_service.obter_ultima_por_ticker(ticker)

    # Buscar fundamentos
    fundamentos = fundamentos_service.obter_ultimo_por_ticker(ticker)

    # Buscar histórico de preços
    historico_precos = precos_service.obter_ultimos_dias(
        ticker, dias=_periodo_para_dias(periodo)
    )

    # Calcular métricas
    metricas_dict = precos_service.calcular_metricas_periodo(ticker, periodo)
    metricas = MetricasHistorico(**metricas_dict)

    return AcaoDetalhadaResponse(
        empresa=empresa,
        cotacao_atual=cotacao_atual,
        fundamentos=fundamentos,
        historico_precos=historico_precos,
        metricas=metricas,
    )


def _periodo_para_dias(periodo: str) -> int:
    """Converte string de período para número de dias."""
    mapa = {
        "7d": 7,
        "15d": 15,
        "1m": 30,
        "3m": 90,
        "6m": 180,
        "1a": 365,
        "3a": 365 * 3,
        "5a": 365 * 5,
    }
    return mapa.get(periodo, 30)
