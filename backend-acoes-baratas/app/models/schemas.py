"""
Schemas Pydantic para validação e serialização de dados.
Atualizado para formato brapi.dev API.
"""
from datetime import datetime, date
from typing import Optional
from pydantic import BaseModel, Field
from decimal import Decimal


class AcaoSchema(BaseModel):
    """Modelo para a tabela 'acoes'."""

    ticker: str
    symbol: Optional[str] = None
    nome_curto: Optional[str] = None
    nome_longo: Optional[str] = None
    setor: Optional[str] = None
    industria: Optional[str] = None
    moeda: Optional[str] = "BRL"
    logo_url: Optional[str] = None
    ativo: bool = True
    created_at: Optional[datetime] = None
    atualizado_em: Optional[datetime] = None


class CotacaoSnapshotSchema(BaseModel):
    """Modelo para a tabela 'cotacoes_snapshot'."""

    id: Optional[int] = None
    ticker: str

    # Preços
    preco_atual: Optional[float] = None
    preco_abertura: Optional[float] = None
    preco_maximo_dia: Optional[float] = None
    preco_minimo_dia: Optional[float] = None
    preco_fechamento_anterior: Optional[float] = None

    # Variações
    variacao_dia: Optional[float] = None
    variacao_dia_percentual: Optional[float] = None

    # Volume e Negociação
    volume: Optional[int] = None
    volume_medio: Optional[int] = None

    # Valores de Mercado
    market_cap: Optional[int] = None

    # Faixas de Preço
    preco_maximo_52_semanas: Optional[float] = None
    preco_minimo_52_semanas: Optional[float] = None

    # Timestamp
    timestamp: datetime = Field(default_factory=datetime.now)
    created_at: Optional[datetime] = None


class PrecoDiarioSchema(BaseModel):
    """Modelo para a tabela 'precos_diarios'."""

    ticker: str
    data: date
    abertura: Optional[float] = None
    maxima: Optional[float] = None
    minima: Optional[float] = None
    fechamento: Optional[float] = None
    fechamento_ajustado: Optional[float] = None
    volume: Optional[int] = None
    created_at: Optional[datetime] = None


class FundamentosSnapshotSchema(BaseModel):
    """Modelo para a tabela 'fundamentos'."""

    id: Optional[int] = None
    ticker: str

    # Identificação
    nome_empresa: Optional[str] = None
    setor: Optional[str] = None
    industria: Optional[str] = None

    # Dados Fundamentalistas
    valor_mercado: Optional[int] = None
    valor_empresa: Optional[int] = None

    # Múltiplos de Mercado
    preco_sobre_lucro: Optional[float] = None  # P/L
    preco_sobre_valor_patrimonial: Optional[float] = None  # P/VP
    preco_sobre_vendas: Optional[float] = None  # P/V
    ev_sobre_receita: Optional[float] = None  # EV/Receita
    ev_sobre_ebitda: Optional[float] = None  # EV/EBITDA

    # Margens (em percentual)
    margem_lucro: Optional[float] = None
    margem_bruta: Optional[float] = None
    margem_ebitda: Optional[float] = None
    margem_operacional: Optional[float] = None

    # Indicadores Financeiros
    roe: Optional[float] = None  # ROE
    roa: Optional[float] = None  # ROA

    # Receita e Lucros
    receita_total: Optional[int] = None
    receita_por_acao: Optional[float] = None
    lucro_bruto: Optional[int] = None
    lucro_liquido: Optional[int] = None
    ebitda: Optional[int] = None
    lucro_por_acao: Optional[float] = None

    # Crescimento
    crescimento_receita: Optional[float] = None
    crescimento_lucro: Optional[float] = None

    # Dividendos
    dividend_yield: Optional[float] = None
    taxa_pagamento: Optional[float] = None  # Payout Ratio

    # Análise Técnica
    beta: Optional[float] = None
    preco_alvo_medio: Optional[float] = None
    recomendacao: Optional[str] = None

    # Número de Ações
    acoes_em_circulacao: Optional[int] = None

    # Data de Referência e Controle
    data_referencia: date = Field(default_factory=date.today)
    created_at: Optional[datetime] = None
    atualizado_em: Optional[datetime] = None

    # Scores (calculados internamente)
    score_valuation: Optional[float] = None
    score_qualidade: Optional[float] = None
    score_momento: Optional[float] = None
    score_geral: Optional[float] = None


# Schemas para respostas da API

class AcaoBarataResponse(BaseModel):
    """Resposta para o endpoint /acoes/baratas."""

    ticker: str
    nome: str
    preco: float
    variacao: float
    setor: Optional[str] = None
    score: Optional[float] = None


class AcaoDetalhadaResponse(BaseModel):
    """Resposta para o endpoint /acoes/{ticker}."""

    ticker: str
    nome_curto: str
    nome_longo: Optional[str] = None
    setor: Optional[str] = None
    preco_atual: Optional[float] = None
    variacao_dia: Optional[float] = None
    pl: Optional[float] = None
    pvp: Optional[float] = None
    dividend_yield: Optional[float] = None
    roe: Optional[float] = None
    score_geral: Optional[float] = None


class HealthResponse(BaseModel):
    """Resposta para o endpoint /health."""

    status: str
    timestamp: datetime = Field(default_factory=datetime.now)
