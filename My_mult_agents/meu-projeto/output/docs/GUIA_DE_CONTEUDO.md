# Guia de Conteúdo - Como Editar e Atualizar o E-book

*Manual de operações para criadores de conteúdo*

---

## 📖 Introdução

Este guia foi criado para que **Lari Colares e sua equipe** possam gerenciar o conteúdo do e-book sem precisar de conhecimento técnico profundo. Aqui você aprenderá a editar, atualizar e regenerar o material.

## 🎯 Filosofia do Conteúdo

### Tom de Voz
- **Leve e descontraído**: Como uma conversa entre amigos
- **Direto ao ponto**: Sem enrolação, foco em resultados
- **Agressivo e inteligente**: Mostrando "hacks" reais e pouco conhecidos
- **Empoderador**: O leitor é capaz, só precisa do conhecimento certo

### Persona da Lari Colares
- Viajante experiente (13 viagens em 10 meses)
- Especialista em maximização de benefícios
- Ensina de forma acessível e prática
- Transparente sobre limitações e riscos

## 📂 Onde Está Cada Coisa

### Estrutura de Conteúdo

```
content/
├── capitulos/
│   └── 00_Guia_Completo_Sala_VIP_0800.md    # E-book principal
│
└── materiais_bonus/
    ├── AcessoMap.md                          # Mapa de aeroportos BR
    ├── Apps_Gratuitos_e_Armadilhas.md       # Apps e cuidados
    ├── Casos_Reais_de_Economia.md           # Histórias de sucesso
    ├── Checklist_Pre_Viagem.md              # Checklist prático
    ├── Guia_Principais_Lounges_Brasil.md    # Reviews de lounges
    ├── Lista_Cartoes_Gratuitos.md           # Cartões sem anuidade
    ├── Lounge_Unlocker.md                   # Lounges internacionais
    └── Quiet_Zones_Finder.md                # Alternativas aos lounges
```

### Como Adicionar um Novo Material

1. Crie um novo arquivo `.md` em `content/materiais_bonus/`
2. Nomeie seguindo o padrão: `Nome_Do_Material.md`
3. Edite `scripts/montar_ebook.py` e adicione o novo arquivo na lista `materiais_bonus`
4. Execute: `python3 scripts/montar_ebook.py`

## ✍️ Guia de Estilo Markdown

### Títulos e Hierarquia

```markdown
# Título Principal (H1) - Use apenas uma vez por arquivo
## Seção Principal (H2) - Para dividir grandes blocos
### Subseção (H3) - Para detalhamentos
```

**Regra de Ouro**: Mantenha hierarquia consistente. Não pule níveis (ex: H1 → H3).

### Ênfases e Destaques

```markdown
**Negrito** para ênfase forte
*Itálico* para ênfase leve
~~Tachado~~ para correções visíveis

> Citações e boxes de destaque
> Use para "Dicas da Lari" ou avisos importantes
```

### Listas

**Listas com marcadores:**
```markdown
*   Item 1
*   Item 2
    *   Sub-item 2.1
    *   Sub-item 2.2
```

**Listas numeradas:**
```markdown
1.  Primeiro passo
2.  Segundo passo
3.  Terceiro passo
```

**Checklists interativos:**
```markdown
*   [ ] Tarefa não concluída
*   [x] Tarefa concluída
```

### Tabelas

```markdown
| Cartão | Benefício | Anuidade |
|--------|-----------|----------|
| C6 Carbon | 4 acessos/ano | Grátis* |
| Inter Black | Ilimitado | Grátis* |
```

### Imagens

**Formato padrão:**
```markdown
![Descrição da imagem](https://url-da-imagem.com/imagem.png)
```

**Importante:**
- Use descrições claras e acessíveis
- Imagens externas podem ficar indisponíveis (risco de hotlinking)
- Para produção, considere hospedar imagens próprias

**Placeholder atual:**
```markdown
![Buffet Sala VIP](https://placehold.co/600x400/2ECC71/FFFFFF/png?text=Comida+%26+Bebida)
```

### Quebras e Separadores

```markdown
---
```
Cria uma linha horizontal para separar seções visualmente.

### Emojis

Use emojis para dar personalidade e facilitar escaneamento visual:

```markdown
✈️  Viagens
💳 Cartões
🔥 Dicas quentes
⚠️  Avisos
✅ Confirmações
❌ Erros
```

## 🔄 Processo de Atualização

### Quando Atualizar?

| Situação | Arquivo(s) a Editar |
|----------|---------------------|
| Mudança em política de cartão | `Lista_Cartoes_Gratuitos.md` |
| Novo lounge no Brasil | `AcessoMap.md` + `Guia_Principais_Lounges_Brasil.md` |
| Novo lounge internacional | `Lounge_Unlocker.md` |
| Nova "armadilha" descoberta | `Apps_Gratuitos_e_Armadilhas.md` |
| Novo caso de sucesso | `Casos_Reais_de_Economia.md` |
| Atualização do método | `00_Guia_Completo_Sala_VIP_0800.md` |

### Passo a Passo para Atualização

#### 1. Edite o Arquivo

Abra o arquivo `.md` relevante em qualquer editor de texto:
- **Mac**: TextEdit, BBEdit, ou VS Code
- **Windows**: Notepad++, VS Code
- **Online**: GitHub Editor, StackEdit

#### 2. Faça suas Alterações

Siga o estilo Markdown descrito acima. Mantenha a formatação consistente com o resto do documento.

#### 3. Regenere o E-book

No terminal/prompt de comando:

```bash
# Navegue até o diretório
cd /caminho/para/output

# Execute o script
python3 scripts/montar_ebook.py
```

Você verá uma saída como:
```
🚀 Iniciando montagem do E-book...
✅ [1/9] Processando: content/capitulos/00_Guia_Completo_Sala_VIP_0800.md
...
✨ E-book montado com sucesso!
```

#### 4. Valide os Links (Opcional mas Recomendado)

```bash
python3 scripts/validar_links.py
```

Isso verificará se todas as imagens e URLs ainda estão acessíveis.

#### 5. Revise o Resultado

Abra o arquivo `ebook_completo.md` e revise:
- Suas mudanças foram aplicadas?
- A formatação está correta?
- Não há quebras de linha estranhas?

## 🎨 Elementos Visuais - Exemplos Práticos

### Box de Dica da Lari

```markdown
> 🚀 **Dica da Lari:** Sempre verifique o app do seu cartão ANTES de ir
> para o aeroporto! As parcerias podem mudar sem aviso prévio.
```

### Box de Alerta/Armadilha

```markdown
> ⚠️ **ARMADILHA:** Ter "acesso" não significa acesso GRATUITO!
> Verifique no app quantas cortesias você tem.
```

### Box de Hack/Estratégia Agressiva

```markdown
> 💥 **Hack de Ouro:** Muitos Visa Platinum já têm Dragon Pass!
> A maioria das pessoas não sabe disso.
```

### Resultado/Estatística

```markdown
> **Resultado:** Economia de **R$5.220** em 6 viagens!
```

## 📊 Checklist de Qualidade

Antes de publicar qualquer atualização, verifique:

### Conteúdo
- [ ] Informações foram verificadas em fontes oficiais?
- [ ] Datas estão atualizadas (2024-2025)?
- [ ] Tom de voz está consistente com a Lari?
- [ ] Há pelo menos um exemplo prático ou caso real?

### Formatação
- [ ] Títulos seguem a hierarquia correta?
- [ ] Listas estão formatadas consistentemente?
- [ ] Emojis foram usados de forma estratégica?
- [ ] Links de imagens estão funcionando?

### Técnico
- [ ] O e-book foi remontado com sucesso?
- [ ] Validação de links foi executada?
- [ ] Arquivo final está sem erros?

## 🆘 Resolução de Problemas

### "O script não está rodando"

**Solução:**
```bash
# Torne o script executável
chmod +x scripts/montar_ebook.py

# Execute com python3 explicitamente
python3 scripts/montar_ebook.py
```

### "Minhas alterações não aparecem no e-book final"

**Causa Provável**: Você editou o `ebook_completo.md` diretamente.
**Solução**: Edite sempre os arquivos em `content/`, não o arquivo final. Depois regenere.

### "Links de imagem não funcionam"

**Causa Provável**: URL da imagem está offline ou com erro de digitação.
**Solução**:
1. Execute `python3 scripts/validar_links.py`
2. Verifique os erros reportados
3. Substitua URLs problemáticas

### "Formatação quebrada no e-book"

**Causa Provável**: Caracteres especiais ou Markdown incorreto.
**Solução**: Revise a sintaxe Markdown no arquivo editado. Confira:
- Espaços após `#` em títulos
- Linhas vazias entre blocos de texto
- Fechamento de listas e citações

## 📞 Recursos Adicionais

### Referências de Markdown
- [GitHub Flavored Markdown](https://guides.github.com/features/mastering-markdown/)
- [Markdown Cheatsheet](https://www.markdownguide.org/cheat-sheet/)

### Ferramentas Úteis
- **Editor Online**: [StackEdit](https://stackedit.io/)
- **Preview de Markdown**: [Dillinger](https://dillinger.io/)
- **Validador**: Built-in no próprio projeto (`validar_links.py`)

---

**Lembre-se**: Este sistema foi criado para ser **simples e sustentável**. Quando em dúvida, mantenha a simplicidade e consulte este guia!
