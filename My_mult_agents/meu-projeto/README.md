# Projeto Multiagentes com Gemini + (opcional) Claude

Este projeto é um **enxame de agentes especializados** usando Gemini CLI
(+ opcionalmente Claude/Cloud CLI para revisão estratégica).

## Estrutura

- `input.md` — descrição do objetivo, contexto e entregáveis.
- `run.sh` — ponto de entrada para rodar o enxame de agentes.
- `master.sh` — orquestrador que coordena os agentes Gemini e a síntese.
- `agents/`
  - `architect.sh` — agente arquiteto (visão de alto nível).
  - `coder.sh` — agente coder (estrutura de código e implementação).
  - `tester.sh` — agente tester (plano de testes).
  - `docs.sh` — agente de documentação (estrutura e tópicos).
  - `strategic_review_claude.sh` — revisão estratégica com Claude (se `cloud` CLI estiver disponível).
- `.state/` — saídas intermediárias (arquivos gerados na execução).

## Requisitos

- `bash`
- `gemini` CLI configurado (Gemini 2.5 Pro/Flash).
- Opcional: `cloud` CLI configurado para Claude Code (para revisão estratégica).

## Como executar

1. Edite o arquivo `input.md` com o objetivo do projeto.
2. No terminal, dentro da pasta do projeto, execute:

   ```bash
   ./run.sh
