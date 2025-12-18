# 📊 Dashboard Fundos Top 100

Dashboard interativo HTML para análise de movimentações dos Top 100 fundos brasileiros.

---

## 🚀 COMO ABRIR

### Método 1: Script Automático (Recomendado)
```bash
cd /Users/kemueldemelleopoldino/Desktop/DEV_KML/GITHUB/KML-1/app_ab
./scripts/abrir_dashboard_fundos.sh
```

### Método 2: Abrir Diretamente
Dê duplo clique no arquivo:
```
/Users/kemueldemelleopoldino/Desktop/DEV_KML/GITHUB/KML-1/app_ab/pages/dashboard_fundos.html
```

---

## ✅ O QUE ESTÁ INCLUSO

### 📄 Arquivos Criados
1. **`pages/dashboard_fundos.html`** (94KB)
   - Dashboard completo com HTML e CSS
   - Design responsivo e moderno
   - 5 abas de análise

2. **`assets/js/dashboard_fundos.js`** (35KB)
   - Lógica completa de conexão com Supabase
   - Todas as queries integradas
   - Gráficos interativos com Chart.js

3. **`scripts/abrir_dashboard_fundos.sh`**
   - Script para abrir automaticamente

### 🔧 Bibliotecas Externas (CDN)
- **Supabase JS** - Conexão com banco de dados
- **Chart.js** - Gráficos interativos
- **Google Fonts** - Tipografia Inter

### 🔐 Credenciais
**Já configuradas no código!**
- ✅ SUPABASE_URL
- ✅ SUPABASE_ANON_KEY

Tudo funciona direto sem configuração adicional.

---

## 📊 FUNCIONALIDADES

### 1️⃣ **Aba: Sinais** 🎯
- **Compra Forte**: Ações com consenso >80% de compra
- **Venda Forte**: Ações com consenso >80% de venda
- **Gráficos**: Top 10 de cada categoria
- **Tabelas**: Top 20 detalhadas

### 2️⃣ **Aba: Momentum** 📈
- **Tendências**: Ações compradas consistentemente
- **Gráfico**: Consistência de compra ao longo dos meses
- **Tabela**: Top 20 com momentum positivo

### 3️⃣ **Aba: Grandes Gestores** 👑
- **Seletor de Grupo**: Escolha entre os Top 100
- **Gráfico Pizza**: Top 5 maiores grupos por PL
- **Detalhes**: Ver portfolio completo de um grupo

### 4️⃣ **Aba: Descoberta** 💎
- **Hidden Gems**: Ações fora do radar com forte compra
- **Alta Convicção**: Poucos fundos, muito dinheiro

### 5️⃣ **Aba: Panorama** 📊
- **Distribuição**: Pie chart compra/venda/neutro
- **Evolução Temporal**: Linha do tempo
- **Ações Populares**: Mais fundos posicionados

---

## 🎨 DESIGN

### Cores e Tema
- **Tema Escuro** profissional
- **Paleta**:
  - 🟢 Verde: Compra (#10b981)
  - 🔴 Vermelho: Venda (#ef4444)
  - 🟡 Amarelo: Neutro (#f59e0b)
  - 🔵 Azul: Destaque (#3b82f6)

### Responsivo
- ✅ Desktop (1800px+)
- ✅ Tablet (768px - 1800px)
- ✅ Mobile (<768px)

---

## 📈 DADOS

### Origem
Conectado diretamente ao Supabase:
- **Tabelas**: grupos_fundos, acoes_fundos, resumo_mensal
- **Views**: v_top_compras_mes, v_top_vendas_mes, v_consenso_mercado, v_movimentos_grupo

### Atualização
- **Mensal**: Dados processados pelo ETL V2
- **Seletor de Mês**: Escolha qual mês analisar
- **Botão Refresh**: Recarregar dados

---

## 🔍 COMO USAR

### Primeiro Acesso
1. Abra o dashboard (script ou duplo clique)
2. **Aguarde** carregar (~3-5 segundos)
3. Dashboard aparece com dados do mês mais recente

### Navegação
1. **Trocar Mês**: Dropdown no topo
2. **Trocar Aba**: Clique nas tabs
3. **Ver Detalhes de Grupo**: Aba "Grandes Gestores" → Selecione grupo → Clique "Ver Detalhes"
4. **Atualizar**: Botão "🔄 Atualizar Dashboard"

### Interpretação

#### 🟢 Compra Forte
- **Consenso >90%**: Unanimidade (sinal MUITO forte)
- **Consenso 80-90%**: Consenso forte
- **Volume >1bi**: Movimento mega significativo

#### 📈 Momentum
- **4/4 meses**: Tendência super consistente
- **3/4 meses**: Tendência forte
- **Fluxo >1bi**: Volume muito significativo

#### 💎 Hidden Gems
- **3-10 fundos**: Pouco conhecido
- **Consenso >70%**: Mas forte entre os que compraram
- **>50M**: Volume significativo

---

## ⚡ PERFORMANCE

### Otimizações
- **Lazy Loading**: Charts só carregam quando necessário
- **Cache**: Dados em memória após primeira carga
- **CDN**: Bibliotecas servidas via CDN rápido

### Tempo de Carregamento
- **Primeira carga**: ~3-5 segundos
- **Troca de aba**: Instantâneo
- **Troca de mês**: ~2-3 segundos

---

## 🐛 SOLUÇÃO DE PROBLEMAS

### Dashboard não abre
```bash
# Verifique se arquivo existe
ls -la pages/dashboard_fundos.html

# Abra manualmente
open pages/dashboard_fundos.html
```

### "Carregando..." infinito
1. **Abra Console do Navegador**: F12 → Console
2. **Veja erros**: Procure mensagens em vermelho
3. **Verifique conexão**: Internet ativa?

### Dados não aparecem
1. **Verifique se ETL foi executado**
2. **Confira Supabase**: Tem dados nas tabelas?
3. **Console do navegador**: Procure erros de conexão

### Gráficos não aparecem
1. **Aguarde carregar completamente**
2. **Recarregue página**: Ctrl+R ou Cmd+R
3. **Limpe cache**: Ctrl+Shift+R ou Cmd+Shift+R

---

## 📌 QUERIES UTILIZADAS

O dashboard executa automaticamente estas queries SQL:

### Sinais (Aba 1)
- Compra Forte: `WHERE intensidade_consenso > 80 AND tendencia_mercado = 'COMPRA'`
- Venda Forte: `WHERE intensidade_consenso > 80 AND tendencia_mercado = 'VENDA'`

### Momentum (Aba 2)
- Agrega 4 meses de dados
- Calcula consistência de compra
- Filtra: `meses_comprando >= 3 AND fluxo > 100M`

### Grandes Gestores (Aba 3)
- Top 5 por PL: `ORDER BY pl_total_bilhoes DESC LIMIT 5`
- Detalhes: `JOIN acoes_fundos ON grupo_id`

### Descoberta (Aba 4)
- Hidden Gems: `qtd_fundos BETWEEN 3 AND 10 AND consenso > 70%`
- Alta Convicção: `qtd_fundos <= 8 AND total > 100M`

### Panorama (Aba 5)
- Distribuição: `GROUP BY tendencia_mercado`
- Evolução: Todos os meses disponíveis
- Populares: `qtd_fundos_posicionados >= 15`

---

## 🎯 CASOS DE USO

### 1. Procurar ação para comprar
1. **Aba Sinais** → Ver "Compra Forte"
2. **Aba Momentum** → Confirmar tendência
3. **Aba Grandes Gestores** → Ver se grandes estão comprando
4. ✅ **Decisão**: Combinar os 3 sinais

### 2. Verificar se devo sair de PETR4
1. **Aba Sinais** → Ver se está em "Venda Forte"
2. **Aba Panorama** → Ver ações populares
3. **Ctrl+F** → Buscar "PETR4" nas tabelas
4. ✅ **Decisão**: Baseado nos sinais

### 3. Descobrir novas oportunidades
1. **Aba Descoberta** → "Hidden Gems"
2. **Aba Descoberta** → "Alta Convicção"
3. **Pesquisar fundamentalista** das que aparecerem
4. ✅ **Decisão**: Validar com análise própria

---

## 📚 DOCUMENTAÇÃO RELACIONADA

- **Queries SQL**: `/sql_scripts/queries_uteis/dashboard_investidor.sql`
- **Schema V2**: `/sql_scripts/01_CRIAR_SCHEMA_V2.sql`
- **ETL**: `/etl_v2/README.md`

---

## ⚠️ AVISOS

### ❌ NÃO faça
- ❌ Comprar baseado APENAS no dashboard
- ❌ Ignorar análise fundamentalista
- ❌ Seguir cegamente os fundos

### ✅ FAÇA
- ✅ Use como FILTRO inicial
- ✅ Valide com fundamentalista
- ✅ Considere seu perfil de risco
- ✅ Diversifique

---

## 🔄 ATUALIZAÇÃO DE DADOS

### Quando atualizar
- **Mensalmente**: Após rodar ETL com dados novos da CVM
- **Automático**: Dashboard sempre mostra dados mais recentes do banco

### Como atualizar
1. Execute ETL V2 (processa novos meses)
2. Abra dashboard
3. Selecione novo mês no dropdown
4. Clique "🔄 Atualizar Dashboard"

---

## 📞 SUPORTE

**Problemas?**
1. Verifique console do navegador (F12)
2. Confirme dados no Supabase
3. Teste conexão internet
4. Recarregue página (Ctrl+Shift+R)

---

✅ **Dashboard 100% funcional e pronto para uso!**

🎉 **Boa análise! Que você encontre ótimas oportunidades!**
