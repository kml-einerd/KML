#!/usr/bin/env bash
set -e

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INPUT_PATH="${1:-$ROOT_DIR/input.md}"
STATE_DIR="$ROOT_DIR/.state"

mkdir -p "$STATE_DIR"

# Checa se o gemini CLI existe
if ! command -v gemini >/dev/null 2>&1; then
  echo "[ERRO] Comando 'gemini' não encontrado no PATH."
  echo "Verifique se o Gemini CLI está instalado e rode: gemini -h"
  exit 1
fi

echo "[master] Usando input: $INPUT_PATH"

# Executa agentes em paralelo
(
  "$ROOT_DIR/agents/architect.sh" "$INPUT_PATH" > "$STATE_DIR/architect.md"
) &

(
  "$ROOT_DIR/agents/coder.sh" "$INPUT_PATH" > "$STATE_DIR/coder.md"
) &

(
  "$ROOT_DIR/agents/tester.sh" "$INPUT_PATH" > "$STATE_DIR/tester.md"
) &

(
  "$ROOT_DIR/agents/docs.sh" "$INPUT_PATH" > "$STATE_DIR/docs.md"
) &

wait

echo "[master] Análises dos agentes concluídas. Gerando síntese com Gemini..."

combined_file="$STATE_DIR/combined_for_synthesis.md"

{
  echo "# Saídas dos agentes"
  echo
  for f in "$STATE_DIR"/architect.md "$STATE_DIR"/coder.md "$STATE_DIR"/tester.md "$STATE_DIR"/docs.md; do
    name="$(basename "$f")"
    echo
    echo "## $name"
    echo
    cat "$f"
    echo
  done
} > "$combined_file"

PROMPT="$(cat "$combined_file")"

PROMPT="$PROMPT

Você é o AGENTE SÍNTESE (Gemini).
Com base nesse material:
1) Faça um resumo executivo.
2) Monte um roadmap em etapas (com dependências).
3) Liste prioridades (Alta / Média / Baixa) para cada etapa.
Responda em Markdown."

gemini -m gemini-2.5-pro -p "$PROMPT" > "$STATE_DIR/synthesis_gemini.md"

echo "[master] Síntese (Gemini) gerada em .state/synthesis_gemini.md"

# 🔹 Revisão estratégica com Claude (se o CLI existir)
if command -v claude >/dev/null 2>&1 || command -v cloud >/dev/null 2>&1; then
  echo "[master] Rodando revisão estratégica com Claude..."
  "$ROOT_DIR/agents/strategic_review_claude.sh" "$STATE_DIR/synthesis_gemini.md" "$STATE_DIR" \
    > "$STATE_DIR/strategic_review_claude.md"
  echo "[master] Revisão estratégica gerada em .state/strategic_review_claude.md"
else
  echo "[master] Nenhum CLI 'claude' ou 'cloud' encontrado. Pulando revisão estratégica."
fi
