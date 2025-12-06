#!/usr/bin/env bash
set -e

if [ -z "$1" ]; then
  echo "Uso: $0 caminho/para/input.md" >&2
  exit 1
fi

INPUT_PATH="$1"
INPUT_CONTENT="$(cat "$INPUT_PATH")"

gemini -m gemini-2.5-pro -p "
Você é o AGENTE TESTER.

Objetivo:
- Criar um PLANO DE TESTES completo para a solução descrita.
- Cobrir testes unitários, de integração e (se fizer sentido) de ponta a ponta.
- Destacar casos de borda e riscos de regressão.

Regras:
- Responda em Markdown.
- Estruture em seções: Estratégia Geral, Tipos de Teste, Casos de Teste, Ferramentas Sugeridas.
- Liste métricas de qualidade (ex.: coverage desejado, critérios de aceitação).

=== INPUT DO USUÁRIO ===
$INPUT_CONTENT
"
