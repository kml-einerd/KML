#!/usr/bin/env bash
set -e

if [ -z "$1" ]; then
  echo "Uso: $0 caminho/para/input.md" >&2
  exit 1
fi

INPUT_PATH="$1"
INPUT_CONTENT="$(cat "$INPUT_PATH")"

gemini -m gemini-2.5-pro -p "
Você é o AGENTE CODER.

Objetivo:
- A partir do input do usuário, desenhar a ESTRUTURA DE CÓDIGO da solução.
- E GERAR ARQUIVOS REAIS de exemplo que possam ser salvos diretamente no projeto.

Stack padrão (pode adaptar ao contexto do input):
- Backend em Python com FastAPI.
- Organização em src/app/ com módulos claros.
- Testes em tests/.

⚠️ FORMATO OBRIGATÓRIO DA RESPOSTA (SIGA EXATAMENTE):

Responda SOMENTE usando blocos neste formato, repetidos para cada arquivo:

### File: src/app/main.py
\`\`\`python
# código completo do arquivo aqui
\`\`\`

### File: src/app/api/routes.py
\`\`\`python
# código completo do arquivo aqui
\`\`\`

### File: tests/test_basic.py
\`\`\`python
# código completo do arquivo aqui
\`\`\`

Regras IMPORTANTES:
- NÃO escreva nenhum texto fora desse padrão.
- NÃO escreva explicações, comentários fora dos blocos de código.
- Cada arquivo deve começar com a linha: \"### File: CAMINHO/DO/ARQUIVO.ext\"
- Logo em seguida, um ÚNICO bloco de código \`\`\`...\`\`\` com o conteúdo completo daquele arquivo.
- Use caminhos simples, por exemplo:
  - src/app/main.py
  - src/app/api/routes.py
  - src/app/core/config.py
  - tests/test_basic.py

Foque em:
- Um esqueleto funcional que compila/roda.
- Arquivos suficientes para alguém já subir o projeto e testar.

=== INPUT DO USUÁRIO ===
$INPUT_CONTENT
"
