#!/usr/bin/env bash
set -e

if [ -z "$1" ]; then
  echo "Uso: $0 caminho/para/input.md" >&2
  exit 1
fi

INPUT_PATH="$1"
INPUT_CONTENT="$(cat "$INPUT_PATH")"

gemini -m gemini-2.5-pro -p "
Você é o AGENTE ARQUITETO de um enxame de agentes de desenvolvimento.

Objetivo global:
- Ler o input do usuário e propor uma ARQUITETURA DE ALTO NÍVEL.
- Quebrar o sistema em módulos, componentes e fluxos principais.
- Sugerir tecnologias, camadas e integrações adequadas ao contexto.

Regras:
- Responda em Markdown.
- Traga um diagrama textual (bullet points) do fluxo principal.
- Liste riscos estruturais e trade-offs relevantes.

=== INPUT DO USUÁRIO ===
$INPUT_CONTENT
"
