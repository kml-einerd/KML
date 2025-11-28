"""
Schemas Pydantic para validação e serialização de dados.
"""
from datetime import datetime, date
from typing import Optional, List, Dict, Any
from pydantic import BaseModel, Field
from decimal import Decimal


class AcaoSchema(BaseModel):
    """Modelo para a tabela 'acoes'."""

    ticker: str
    codigo_b3: Optional[str] = None
    nome_curto: Optional[str] = None
    nome_longo: Optional[str] = None
    bolsa: Optional[str] = None
    regiao: Optional[str] = None
    moeda: Optional[str] = None
    setor: Optional[str] = None
    industria: Optional[str] = None
    site: Optional[str] = None
    descricao_longa: Optional[str] = None
    ativo: bool = True
    criado_em: Optional[datetime] = None
    atualizado_em: Optional[datetime] = None


class CotacaoSnapshotSchema(BaseModel):
    """Modelo para a tabela 'cotacoes_snapshot'."""

    id: Optional[int] = None
    ticker: str
    coletado_em: datetime
    preco_ultimo: Optional[float] = None
    preco_anterior: Optional[float] = None
    variacao_dia: Optional[float] = None
    variacao_dia_percentual: Optional[float] = None
    maximo_dia: Optional[float] = None
    minimo_dia: Optional[float] = None
    volume: Optional[float] = None
    valor_mercado: Optional[float] = None
    pl_trailing: Optional[float] = None
    pl_forward: Optional[float] = None
    preco_valor_patrimonial: Optional[float] = None
    dividend_yield: Optional[float] = None
    payout_ratio: Optional[float] = None
    beta: Optional[float] = None


class PrecoDiarioSchema(BaseModel):
    """Modelo para a tabela 'precos_diarios'."""

    ticker: str
    data: date
    abertura: Optional[float] = None
    maxima: Optional[float] = None
    minima: Optional[float] = None
    fechamento: Optional[float] = None
    fechamento_ajustado: Optional[float] = None
    volume: Optional[float] = None


class FundamentosSnapshotSchema(BaseModel):
    """Modelo para a tabela 'fundamentos_snapshot'."""

    id: Optional[int] = None
    ticker: str
    coletado_em: datetime
    pl_trailing: Optional[float] = None
    pl_forward: Optional[float] = None
    preco_valor_patrimonial: Optional[float] = None
    dividend_yield: Optional[float] = None
    roe: Optional[float] = None
    roa: Optional[float] = None
    margem_liquida: Optional[float] = None
    margem_operacional: Optional[float] = None
    margem_bruta: Optional[float] = None
    divida_patrimonio: Optional[float] = None
    liquidez_corrente: Optional[float] = None
    crescimento_receita_12m: Optional[float] = None
    crescimento_lucro_12m: Optional[float] = None
    score_valuation: Optional[float] = None
    score_qualidade: Optional[float] = None
    score_momento: Optional[float] = None
    score_geral: Optional[float] = None
    raw_info: Optional[Dict[str, Any]] = None
    raw_outros: Optional[Dict[str, Any]] = None


class DividendoSchema(BaseModel):
    """Modelo para a tabela 'dividendos'."""

    id: Optional[int] = None
    ticker: str
    data_pagamento: date
    valor: float


class DesdobramentoSchema(BaseModel):
    """Modelo para a tabela 'desdobramentos'."""

    id: Optional[int] = None
    ticker: str
    data: date
    proporcao: float


# ========== Schemas para Respostas da API ==========


class AcaoBarataResponse(BaseModel):
    """Resposta para o endpoint /acoes-baratas."""

    ticker: str
    codigo_b3: Optional[str] = None
    nome_curto: Optional[str] = None
    setor: Optional[str] = None
    preco_ultimo: Optional[float] = None
    variacao_dia_percentual: Optional[float] = None
    valor_mercado: Optional[float] = None
    score_geral: Optional[float] = None
    score_valuation: Optional[float] = None
    score_qualidade: Optional[float] = None
    score_momento: Optional[float] = None


class MetricasHistorico(BaseModel):
    """Métricas calculadas do histórico."""

    retorno_periodo: Optional[float] = Field(
        None, description="Retorno percentual no período"
    )
    volatilidade: Optional[float] = Field(
        None, description="Desvio padrão dos retornos diários (volatilidade)"
    )
    maxima_periodo: Optional[float] = Field(None, description="Preço máximo no período")
    minima_periodo: Optional[float] = Field(None, description="Preço mínimo no período")


class AcaoDetalhadaResponse(BaseModel):
    """Resposta detalhada para o endpoint /acao/{ticker}."""

    empresa: AcaoSchema
    cotacao_atual: Optional[CotacaoSnapshotSchema] = None
    fundamentos: Optional[FundamentosSnapshotSchema] = None
    historico_precos: List[PrecoDiarioSchema] = []
    metricas: Optional[MetricasHistorico] = None


class HealthResponse(BaseModel):
    """Resposta para o endpoint /health."""

    status: str
    timestamp: datetime
    versao: str = "1.0.0"
