# Workflow: Single Expert Analysis

---

## Objetivo
Resolver um problema ARC-AGI usando análise de um único expert (você).

---

## Pré-requisitos
- Problema formatado em arquivo markdown (ex: `problems/exemplo_001.md`)
- Prompt de solver carregado (ex: `prompts/solver_basico.md`)

---

## Passo-a-Passo

### 1. Preparação

```bash
# Verifique que o problema existe
ls problems/

# Escolha o problema a resolver
PROBLEM="problems/exemplo_001.md"
```

---

### 2. Análise com Claude Code

**Comando:**
```bash
claude-code chat
```

**Prompt para enviar:**
```
Vou te fornecer:
1. Um prompt de sistema explicando como resolver problemas ARC-AGI
2. Um problema específico para resolver

Siga EXATAMENTE a metodologia descrita no prompt de sistema.

[COLE AQUI O CONTEÚDO DE prompts/solver_basico.md]

---

AGORA RESOLVA ESTE PROBLEMA:

[COLE AQUI O CONTEÚDO DE problems/exemplo_001.md]
```

---

### 3. Salvar Solução

Após receber a análise do Claude, salve em arquivo:

```bash
# Criar arquivo de solução
# Copie a resposta do Claude para:
solutions/exemplo_001_expert_1.md
```

---

### 4. Validação Manual

**Checklist de Validação:**

- [ ] A análise seguiu o formato especificado?
- [ ] Todos os exemplos de treino foram validados?
- [ ] A regra é descrita claramente em linguagem natural?
- [ ] O output final está formatado corretamente?
- [ ] O nível de confiança é justificado?

---

### 5. Verificação da Solução

**Se você conhece a resposta correta:**

Compare o output gerado com a resposta esperada:
- ✓ Se correto: Documentar sucesso
- ✗ Se incorreto: Analisar onde errou

**Para aprender com erros:**
```markdown
## Análise de Erro

### Solução Proposta
[Output gerado]

### Solução Correta
[Output esperado]

### Divergência
[Onde diferem?]

### Causa do Erro
[Por que a regra estava incorreta?]

### Regra Corrigida
[Nova hipótese baseada no erro]
```

---

## Exemplo Completo

### Problema: exemplo_001.md
```
Input 1: [[0,0,0],[0,1,0],[0,0,0]] → Output 1: [[1,1,1],[1,1,1],[1,1,1]]
Input 2: [[0,0,0,0],[0,1,1,0]...] → Output 2: [[1,1,1,1],[1,1,1,1]...]
```

### Análise do Claude
```markdown
## ANÁLISE DO PADRÃO

### Observações Iniciais
- Todos os outputs são grids completamente preenchidos com 1s
- Os inputs têm dimensões variadas
- Todos os inputs contêm pelo menos um 1

### Hipótese de Transformação
Se existe pelo menos um 1 no input, preencher todo o grid com 1s.

### Categoria
Simple (transformação condicional)

## VALIDAÇÃO MENTAL

### Exemplo 1
Input: 3x3 com um 1 central
Aplicando regra: Detecta 1 → preenche tudo com 1
Output: [[1,1,1],[1,1,1],[1,1,1]] ✓ PASS

[...]

## SOLUÇÃO PARA TESTE

Input: 5x5 com padrão de cruz de 1s
Output:
```
1 1 1 1 1
1 1 1 1 1
1 1 1 1 1
1 1 1 1 1
1 1 1 1 1
```

Confiança: Alta (95%)
```

### Salvar Solução
```bash
# Copiar análise acima para:
echo "[análise]" > solutions/exemplo_001_expert_1.md
```

---

## Dicas de Otimização

### Para Melhorar Precisão:
1. **Seja específico** nas perguntas ao Claude
2. **Peça múltiplas hipóteses** e escolha a melhor
3. **Valide manualmente** os exemplos de treino
4. **Itere se necessário** com feedback de erros

### Para Acelerar Processo:
1. **Use templates** de problemas pré-formatados
2. **Crie aliases** de comandos frequentes
3. **Automatize validação** quando possível

---

## Próximos Passos

Após dominar o workflow single-expert:
1. → Experimente `workflows/multi_expert.md` para análise paralela
2. → Use `workflows/voting_system.md` para combinar soluções
3. → Implemente sistema iterativo com feedback

---

## Troubleshooting

### Problema: Claude não segue o formato
**Solução:** Reforce no prompt "Use EXATAMENTE este formato" e forneça exemplo

### Problema: Análise superficial
**Solução:** Peça "Explique passo-a-passo com mais detalhes"

### Problema: Múltiplas interpretações
**Solução:** Use multi-expert workflow para explorar alternativas

---

**Status:** ✅ Workflow básico funcional
**Próximo:** Testar com problema real
