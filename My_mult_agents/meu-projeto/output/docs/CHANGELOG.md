# Changelog - Histórico de Versões

Todas as mudanças notáveis neste projeto serão documentadas neste arquivo.

O formato é baseado em [Keep a Changelog](https://keepachangelog.com/pt-BR/1.0.0/),
e este projeto adere ao [Versionamento Semântico](https://semver.org/lang/pt-BR/).

## [1.0.0] - 2025-12-05

### 🎉 Lançamento Inicial

Primeira versão completa do sistema de geração do e-book "Guia Completo Sala VIP 0800™".

#### ✨ Adicionado

**E-book Principal:**
- Guia Completo Sala VIP 0800 com o Método A.V.I. (Acessos, Verificação, Ingresso)
- Introdução com promessa de transformação
- Biografia da Lari Colares
- Sistema completo em 3 passos
- Desmistificação de mitos sobre salas VIP

**Materiais Bônus:**
1. **AcessoMap™** - Mapa visual dos principais aeroportos brasileiros (GRU, GIG, CNF, BSB)
2. **Lista de Cartões Gratuitos** - Cartões sem anuidade com acesso VIP
3. **Lounge Unlocker™** - Guia global de lounges (MCO, MIA, LIS, CDG)
4. **Quiet Zones Finder™** - Alternativas quando lounges não estão disponíveis
5. **Checklist Pré-Viagem** - Sistema de verificação de 5 minutos
6. **Apps Gratuitos e Armadilhas** - Guia de apps e cuidados essenciais
7. **Casos Reais de Economia** - 2 estudos de caso detalhados
8. **Guia dos Principais Lounges do Brasil** - Reviews de 4 lounges principais

**Infraestrutura:**
- Script de montagem automatizada (`montar_ebook.py`)
- Script de validação de links (`validar_links.py`)
- Estrutura modular de conteúdo
- Sistema de geração baseado em arquivos Markdown

**Documentação:**
- README.md completo com guia de uso
- GUIA_DE_CONTEUDO.md para criadores de conteúdo
- Este CHANGELOG.md para rastreamento de versões

#### 📊 Estatísticas da v1.0.0

- **Total de módulos**: 9 (1 capítulo principal + 8 materiais bônus)
- **Tamanho do e-book**: ~30 KB
- **Imagens**: Placeholders prontos para customização
- **Aeroportos cobertos**:
  - Brasil: 4 (GRU, GIG, CNF, BSB)
  - Internacional: 4 (MCO, MIA, LIS, CDG)
- **Cartões listados**: 7 opções sem anuidade
- **Lounges detalhados**: 15+

#### 🔧 Configuração

- Formato: GitHub Flavored Markdown (GFM)
- Linguagem de script: Python 3.7+
- Compatibilidade: macOS, Linux, Windows

---

## [Unreleased] - Próximas Versões

### 🚀 Planejado para v1.1.0

#### Prioridade Alta
- [ ] Substituição de imagens placeholder por imagens finais licenciadas
- [ ] Fact-checking completo de políticas de cartões (2024-2025)
- [ ] Revisão ortográfica e gramatical profissional
- [ ] Validação de informações sobre programas de fidelidade

#### Prioridade Média
- [ ] Expansão do AcessoMap™ com mais aeroportos
  - [ ] CGH (Congonhas)
  - [ ] SDU (Santos Dumont)
  - [ ] POA (Porto Alegre)
  - [ ] REC (Recife)
- [ ] Mais lounges internacionais no Lounge Unlocker™
  - [ ] AMS (Amsterdam)
  - [ ] MAD (Madrid)
  - [ ] JFK (Nova York)
- [ ] Casos reais adicionais de economia

#### Prioridade Baixa
- [ ] Conversão automatizada para PDF (via Pandoc)
- [ ] Versão em ePub
- [ ] Diagramas ilustrativos do Método A.V.I.
- [ ] Versionamento de imagens localmente

### 🔮 Ideias Futuras (v2.0.0+)

- [ ] Sistema de analytics para rastrear capítulos mais lidos
- [ ] Versão web interativa
- [ ] Aplicativo mobile complementar
- [ ] Sistema de notificação de mudanças em políticas de cartões
- [ ] Comunidade de usuários para compartilhar experiências
- [ ] API para consulta de lounges em tempo real

---

## Tipos de Mudanças

- **✨ Adicionado** - para novas funcionalidades
- **🔄 Modificado** - para mudanças em funcionalidades existentes
- **🗑️ Removido** - para funcionalidades removidas
- **🐛 Corrigido** - para correção de bugs
- **🔒 Segurança** - em caso de vulnerabilidades
- **📚 Documentação** - mudanças apenas em documentação

---

## Versionamento

Este projeto usa [Versionamento Semântico](https://semver.org/):
- **MAJOR** (X.0.0): Mudanças incompatíveis na API/estrutura
- **MINOR** (0.X.0): Novas funcionalidades compatíveis
- **PATCH** (0.0.X): Correções de bugs compatíveis

**Versão Atual**: 1.0.0
**Próxima Versão Planejada**: 1.1.0
**Data de Lançamento Estimada**: A definir
