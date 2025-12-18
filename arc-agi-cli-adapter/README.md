# ARC-AGI CLI Adapter

Adaptação do sistema Poetiq ARC-AGI Solver para uso com Claude Code / Gemini CLI, sem dependências Python ou chaves de API externas.

---

## 🎯 Visão Geral

Este projeto permite resolver problemas do Abstract Reasoning Corpus (ARC-AGI) usando **apenas uma IA conversacional** (Claude Code ou Gemini CLI), sem necessidade de:

- ❌ Ambiente Python
- ❌ Chaves de API pagas
- ❌ Execução de código
- ❌ Bibliotecas externas

Funciona através de:

- ✅ Prompts estruturados
- ✅ Raciocínio simulado pela IA
- ✅ Workflows em markdown
- ✅ Validação mental

---

## 📁 Estrutura do Projeto

```
arc-agi-cli-adapter/
├── README.md                          # Este arquivo
├── problems/                          # Problemas ARC-AGI
│   └── exemplo_001.md                 # Problema de exemplo
├── solutions/                         # Soluções geradas
│   └── [serão criadas aqui]
├── prompts/                           # Biblioteca de prompts
│   └── solver_basico.md              # Prompt principal
└── workflows/                         # Guias de execução
    ├── single_expert.md              # Workflow básico
    ├── multi_expert.md               # [TODO] Múltiplos experts
    └── voting_system.md              # [TODO] Sistema de votação
```

---

## 🚀 Quick Start

### 1. Resolver Primeiro Problema

```bash
# 1. Abra o problema de exemplo
cat problems/exemplo_001.md

# 2. Inicie Claude Code
claude-code chat

# 3. Cole este prompt:
```

**No chat do Claude:**
```
Vou te fornecer um problema ARC-AGI para resolver.

Primeiro, leia esta metodologia:
[Cole o conteúdo de prompts/solver_basico.md]

Agora resolva este problema:
[Cole o conteúdo de problems/exemplo_001.md]

Siga EXATAMENTE o formato especificado na metodologia.
```

### 2. Salvar Resultado

Copie a análise do Claude e salve em:
```bash
# Criar arquivo com a solução
# Copie a resposta do Claude para:
solutions/exemplo_001_expert_1.md
```

### 3. Verificar Solução

Compare o output gerado com o esperado para validar.

---

## 📖 Guias Detalhados

### Para Iniciantes
1. Leia: `workflows/single_expert.md` - Workflow básico passo-a-passo
2. Pratique: Resolva `problems/exemplo_001.md`
3. Experimente: Crie seu próprio problema simples

### Para Usuários Avançados
1. [TODO] `workflows/multi_expert.md` - Simular múltiplos experts
2. [TODO] `workflows/voting_system.md` - Sistema de votação
3. [TODO] `workflows/iterative_refinement.md` - Feedback e iteração

---

## 💡 Como Funciona

### Conceito: "Execução Mental pela IA"

Em vez de gerar e executar código Python:

```
Sistema Original:           Sistema Adaptado:
IA → Código Python    VS    IA → Raciocínio Mental
     ↓                           ↓
Executa em sandbox         Simula transformação
     ↓                           ↓
Output real                Output simulado
```

### Exemplo Concreto

**Problema:** Transformar `[[0,1],[0,0]]` segundo padrão observado

**Sistema Original:**
```python
def transform(grid):
    return np.where(grid == 0, 1, grid)
# Executa → [[1,1],[1,1]]
```

**Sistema Adaptado:**
```markdown
Regra: Substituir 0s por 1s
Simulação:
- Posição (0,0): 0 → 1
- Posição (0,1): 1 → 1 (mantém)
- Posição (1,0): 0 → 1
- Posição (1,1): 0 → 1
Resultado: [[1,1],[1,1]]
```

**Resultado:** Idêntico, mas método diferente!

---

## 🎓 Vantagens e Limitações

### ✅ Vantagens

1. **Acessibilidade:** Funciona com qualquer LLM CLI gratuito
2. **Transparência:** Todo raciocínio é explicado
3. **Educacional:** Humanos aprendem os padrões junto
4. **Portabilidade:** Não depende de ambiente específico
5. **Simplicidade:** Apenas texto, sem código

### ⚠️ Limitações

1. **Velocidade:** Mais lento que execução real
2. **Precisão:** IA pode errar em cálculos complexos
3. **Escala:** Melhor para poucos problemas, não milhares
4. **Complexidade:** Problemas muito complexos são desafiadores

### 🎯 Quando Usar

**Use este sistema para:**
- Aprender sobre ARC-AGI
- Explorar problemas individualmente
- Não ter acesso a APIs pagas
- Prototipagem e experimentação

**Use o sistema original para:**
- Competições oficiais
- Processamento em larga escala
- Máxima precisão necessária
- Budget disponível para APIs

---

## 📊 Resultados Esperados

### Baseline (Estimativa)

| Tipo de Problema | Taxa de Acerto Esperada |
|------------------|-------------------------|
| Simples (ex: inverter valores) | 90-95% |
| Médio (ex: rotações, padrões) | 70-85% |
| Complexo (ex: múltiplas regras) | 50-70% |
| Muito Complexo | 30-50% |

### Objetivos

- **MVP:** 60% de acerto em problemas simples/médios
- **Alvo:** 80% de acerto em problemas simples/médios
- **Stretch:** Resolver pelo menos 1 problema complexo corretamente

---

## 🛠️ Ferramentas Recomendadas

### LLMs Compatíveis

1. **Claude Code** (Recomendado)
   - Excelente raciocínio abstrato
   - Bom em seguir formatos
   - Gratuito para uso pessoal

2. **Gemini CLI**
   - Alternativa viável
   - Pode ter interpretações diferentes

3. **Outros LLMs**
   - Qualquer CLI conversacional pode funcionar
   - Ajuste prompts conforme necessário

### Editores

- VS Code (com preview de markdown)
- Qualquer editor de texto

---

## 📚 Recursos Adicionais

### Aprender Mais Sobre ARC-AGI

- **Site Oficial:** https://arcprize.org/
- **Dataset:** https://github.com/fchollet/ARC
- **Paper:** Chollet, F. "On the Measure of Intelligence"

### Documentação Relacionada

- `../analise-adaptacao-arc-agi-solver.md` - Análise completa do painel de especialistas

### Comunidade

- [TODO] Discussões no GitHub
- [TODO] Exemplos da comunidade
- [TODO] Benchmark de resultados

---

## 🗺️ Roadmap

### ✅ Fase 1: MVP (Concluído)
- [x] Estrutura de diretórios
- [x] Problema de exemplo
- [x] Prompt básico de solver
- [x] Workflow single-expert
- [x] Documentação inicial

### 🔄 Fase 2: Expansão (Em Progresso)
- [ ] 10 problemas de exemplo (variadas dificuldades)
- [ ] Workflow multi-expert
- [ ] Sistema de votação
- [ ] Feedback iterativo
- [ ] Métricas de performance

### 📅 Fase 3: Otimização (Planejado)
- [ ] Biblioteca de padrões comuns
- [ ] Slash commands do Claude Code
- [ ] Automação de workflows
- [ ] Validação automática
- [ ] Benchmark formal

### 🚀 Fase 4: Comunidade (Futuro)
- [ ] Dataset completo convertido
- [ ] Contribuições da comunidade
- [ ] Comparação com sistema original
- [ ] Publicação de resultados

---

## 🤝 Como Contribuir

### Adicionar Problemas

1. Crie arquivo em `problems/` seguindo formato de `exemplo_001.md`
2. Inclua pelo menos 2 exemplos de treino
3. Documente a regra esperada (para validação)

### Melhorar Prompts

1. Teste variações de prompts
2. Documente melhorias de precisão
3. Compartilhe resultados

### Compartilhar Soluções

1. Resolva problemas usando workflows
2. Salve em `solutions/`
3. Documente taxa de acerto e aprendizados

---

## 📄 Licença

Este projeto é uma adaptação independente para fins educacionais.

- Sistema original Poetiq: Ver licença original
- Prompts e workflows desta adaptação: MIT License
- Dataset ARC-AGI: Ver https://github.com/fchollet/ARC

---

## 🙏 Agradecimentos

- **Poetiq Team:** Pelo sistema original inspirador
- **François Chollet:** Pelo ARC-AGI dataset
- **Anthropic:** Pelo Claude Code
- **Google:** Pelo Gemini

---

## 📞 Suporte

### Issues Comuns

**Q: Claude não segue o formato do prompt**
A: Reforce com "Use EXATAMENTE este formato" e forneça exemplo concreto

**Q: Solução incorreta**
A: Normal! Use feedback iterativo para refinar, ou tente multi-expert

**Q: Problema muito complexo**
A: Comece com problemas simples, aumente dificuldade gradualmente

### Obter Ajuda

- Abra issue no repositório
- Consulte `workflows/` para guias detalhados
- Revise `analise-adaptacao-arc-agi-solver.md` para contexto completo

---

**Versão:** 1.0.0
**Status:** MVP Funcional
**Última Atualização:** Dezembro 2024

---

*"Democratizando acesso a tecnologia avançada de raciocínio abstrato."*
