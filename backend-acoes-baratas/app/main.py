"""
Aplicação principal FastAPI.
API para consulta de ações baratas da B3.
"""
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from datetime import datetime

from app.routers import acoes
from app.models.schemas import HealthResponse
from app.config import obter_configuracoes

# Configurações
config = obter_configuracoes()

# Criar aplicação FastAPI
app = FastAPI(
    title="API Ações Baratas B3",
    description="API para consulta e análise de ações baratas da Bolsa brasileira (B3)",
    version="1.0.0",
    docs_url="/docs",
    redoc_url="/redoc",
)

# Configurar CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Em produção, especifique os domínios permitidos
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Registrar routers
app.include_router(acoes.router)


@app.get("/", tags=["Raiz"])
async def raiz():
    """Endpoint raiz da API."""
    return {
        "mensagem": "API Ações Baratas B3",
        "versao": "1.0.0",
        "documentacao": "/docs",
    }


@app.get("/health", response_model=HealthResponse, tags=["Health"])
async def health_check():
    """
    Endpoint de health check.
    Verifica se a API está funcionando corretamente.
    """
    return HealthResponse(
        status="ok",
        timestamp=datetime.utcnow(),
        versao="1.0.0",
    )


if __name__ == "__main__":
    import uvicorn

    uvicorn.run(
        "app.main:app",
        host=config.api_host,
        port=config.api_port,
        reload=config.api_reload,
    )
