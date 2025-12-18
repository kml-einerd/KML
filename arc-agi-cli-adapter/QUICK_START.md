# 🚀 Quick Start - Resolva Seu Primeiro Problema ARC-AGI em 5 Minutos

---

## Passo 1: Veja o Problema (30 segundos)

Abra o arquivo `problems/exemplo_001.md` e observe:

**O que você verá:**
- 3 exemplos de transformação (input → output)
- 1 input de teste para você resolver
- Padrão a descobrir: O que transforma os inputs nos outputs?

**Exemplo rápido:**
```
Input:  [[0,0,0],      Output:  [[1,1,1],
         [0,1,0],  →            [1,1,1],
         [0,0,0]]               [1,1,1]]
```

**Pergunta:** Qual é a regra? 🤔

---

## Passo 2: Copie o Prompt do Solver (1 minuto)

Abra `prompts/solver_basico.md` e **copie todo o conteúdo**.

Este prompt ensina a IA como resolver problemas ARC-AGI de forma estruturada.

---

## Passo 3: Inicie o Claude Code (30 segundos)

```bash
claude-code chat
```

Ou use qualquer LLM CLI que você tenha (Gemini, etc.)

---

## Passo 4: Cole no Chat (1 minuto)

**Cole esta mensagem completa:**

```
Vou te fornecer:
1. Uma metodologia para resolver problemas ARC-AGI
2. Um problema específico

Siga EXATAMENTE a metodologia.

=== METODOLOGIA ===
[COLE AQUI TODO O CONTEÚDO DE prompts/solver_basico.md]

=== PROBLEMA ===
[COLE AQUI TODO O CONTEÚDO DE problems/exemplo_001.md]

Comece sua análise agora!
```

---

## Passo 5: Receba a Solução (1-2 minutos)

O Claude vai retornar algo como:

```markdown
## ANÁLISE DO PADRÃO

### Observações Iniciais
Todos os outputs são grids completamente preenchidos com 1s...

### Hipótese de Transformação
Se existe pelo menos um valor 1 no input, preencher todo o grid com 1s.

[...]

## SOLUÇÃO PARA TESTE

Output Final:
```
1 1 1 1 1
1 1 1 1 1
1 1 1 1 1
1 1 1 1 1
1 1 1 1 1
```

Confiança: Alta (95%)
```

---

## Passo 6: Verifique! (30 segundos)

Para o `exemplo_001.md`, a resposta esperada é:
- **Regra:** "Se houver pelo menos um 1, preencha tudo com 1s"
- **Output:** Grid 5x5 todo de 1s

**Acertou?** 🎉

---

## 🎯 Parabéns!

Você acabou de resolver um problema ARC-AGI usando apenas IA conversacional!

---

## 🔥 Próximos Passos

### Nível 1: Pratique
- Crie seu próprio problema simples
- Teste variações do prompt
- Experimente com diferentes LLMs

### Nível 2: Avance
- Leia `workflows/single_expert.md` para workflow completo
- Tente problemas ARC-AGI reais do dataset oficial
- Documente sua taxa de acerto

### Nível 3: Domine
- Implemente multi-expert workflow
- Crie sistema de votação
- Contribua com novos problemas e soluções

---

## 💡 Dicas Pro

### Para Melhores Resultados:
1. **Seja específico:** "Use EXATAMENTE este formato" ajuda
2. **Peça explicação:** "Explique passo-a-passo" melhora qualidade
3. **Itere:** Se errar, peça "Tente novamente considerando que [feedback]"

### Se Algo der Errado:
- **Claude não segue formato?** → Reforce no prompt
- **Solução muito vaga?** → Peça "mais detalhes passo-a-passo"
- **Múltiplas interpretações?** → Peça "liste 3 hipóteses diferentes"

---

## 📊 Benchmarks Rápidos

Teste você mesmo com estes problemas simples:

### Problema A: Inversão
```
Input: [[0,0,1,1]] → Output: [[1,1,0,0]]
Input: [[0,1,0]] → Output: [[1,0,1]]
Teste: [[0,0,0,1]] → ?
```
<details>
<summary>Resposta</summary>
Output: [[1,1,1,0]]
Regra: Inverter 0↔1
</details>

### Problema B: Rotação
```
Input: [[1,2],[3,4]] → Output: [[2,4],[1,3]]
Input: [[5,6],[7,8]] → Output: [[6,8],[5,7]]
Teste: [[9,0],[1,2]] → ?
```
<details>
<summary>Resposta</summary>
Output: [[0,2],[9,1]]
Regra: Rotação 90° horário
</details>

---

## 🎓 Entendendo o Sistema

### Como Funciona Internamente?

```
Você → Prompt + Problema → Claude Code
                                ↓
                    Claude simula execução mental
                                ↓
                    Identifica padrão abstrato
                                ↓
                    Valida contra exemplos
                                ↓
                    Aplica ao teste
                                ↓
         ← Solução + Explicação ← Claude Code
```

### Por que Funciona?

LLMs modernos (Claude, Gemini) são **bons em:**
- Reconhecimento de padrões visuais/abstratos
- Raciocínio lógico step-by-step
- Validação de hipóteses

**Mas precisam de:**
- Prompts estruturados (por isso o `solver_basico.md`)
- Exemplos claros (por isso múltiplos exemplos de treino)
- Formato definido (por isso o template de resposta)

---

## 🏆 Desafio Rápido

**Cronômetro:** Você consegue resolver 3 problemas simples em 15 minutos?

1. `exemplo_001.md` (fornecido)
2. Problema A acima (inversão)
3. Problema B acima (rotação)

**Meta:**
- ✅ 3/3 corretos: Expert!
- ✅ 2/3 corretos: Bom trabalho!
- ✅ 1/3 correto: Continue praticando!

---

## 📚 Recursos

- **Documentação Completa:** `README.md`
- **Análise Detalhada:** `../analise-adaptacao-arc-agi-solver.md`
- **Workflow Avançado:** `workflows/single_expert.md`
- **ARC-AGI Official:** https://arcprize.org/

---

## 🤝 Compartilhe Seus Resultados

Resolveu um problema interessante?
- Documente em `solutions/`
- Compartilhe sua taxa de acerto
- Contribua com novos problemas

---

**Tempo Total:** ~5 minutos
**Dificuldade:** Fácil
**Pré-requisitos:** Claude Code ou similar

**Vamos começar!** 🚀

---

*Criado para tornar ARC-AGI acessível a todos, sem barreiras técnicas.*
