#!/usr/bin/env bash
set -e

if [ $# -lt 2 ]; then
  echo "Uso: $0 caminho_para_synthesis.md caminho_para_pasta_state" >&2
  exit 1
fi

SYNTHESIS_PATH="$1"
STATE_DIR="$2"

# Descobre qual comando do Claude existe: 'claude' (oficial) ou 'cloud' (algumas instalações antigas)
if command -v claude >/dev/null 2>&1; then
  CLAUDE_CMD="claude"
elif command -v cloud >/dev/null 2>&1; then
  CLAUDE_CMD="cloud"
else
  echo "[strategic_review] Nenhum CLI 'claude' ou 'cloud' encontrado no PATH." >&2
  exit 1
fi

INPUT_CONTENT="$(cat "$SYNTHESIS_PATH")"

$CLAUDE_CMD -p "
Você é o REVISOR ESTRATÉGICO CLAUDE.

Você recebe a SÍNTESE de um projeto gerada por um enxame de agentes (arquitetura, código, testes, docs).

Tarefas:
1) Revisar criticamente a solução proposta.
2) Apontar riscos, gargalos e dívidas técnicas.
3) Sugerir melhorias concretas, marcando cada item como Prioridade: Alta, Média ou Baixa.
4) Se perceber inconsistências importantes, proponha um fluxo corrigido e explique por quê.

Responda em Markdown bem estruturado (com títulos, listas e seções claras).

=== SÍNTESE DO PROJETO ===
$INPUT_CONTENT
"
