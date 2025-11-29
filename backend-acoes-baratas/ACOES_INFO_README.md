# Sistema de Informações Extras das Ações (yfinance)

Este sistema busca informações extras e fixas das empresas usando a biblioteca `yfinance` e armazena em uma tabela separada no Supabase.

## 📋 O que este sistema faz?

1. **Lê os tickers** da tabela `acoes` no Supabase
2. **Busca informações fixas** da empresa usando yfinance (não são dados que variam como preço)
3. **Salva em uma nova tabela** chamada `acoes_info` com o mesmo ID/ticker de referência

## 🗃️ Informações coletadas

O sistema coleta dados **fixos** da empresa, incluindo:

### Informações Básicas
- Nome longo e curto da empresa
- Descrição do negócio

### Localização e Contato
- País, Estado, Cidade
- Endereço completo e CEP
- Telefone e Website

### Classificação
- Setor
- Indústria
- Indústria-chave

### Informações Corporativas
- Número de funcionários

### Informações de Mercado
- Moeda
- Exchange (bolsa onde é negociada)
- Tipo de ativo

### Informações Fiscais
- Ano fiscal que termina
- Próximo ano fiscal

### Governança Corporativa
- Riscos de auditoria, conselho, compensação, shareholders
- Risco geral

## 🚀 Como usar

### 1. Criar a tabela no Supabase

Execute o script SQL no editor SQL do Supabase:

```bash
backend-acoes-baratas/sql/criar_tabela_acoes_info.sql
```

Ou copie e cole o conteúdo no SQL Editor do Supabase.

### 2. Executar via GitHub Actions

O sistema está configurado para rodar automaticamente no GitHub Actions:

1. Vá para a aba **Actions** do seu repositório
2. Selecione o workflow **"Sincronização Ações Baratas B3"**
3. Clique em **"Run workflow"**
4. Selecione a branch desejada
5. Clique em **"Run workflow"**

O job **"Atualizar Informações Extras das Ações"** será executado automaticamente após o job de atualização do universo de ações.

### 3. Executar localmente (opcional)

```bash
cd backend-acoes-baratas

# Instalar dependências
pip install -r requirements.txt

# Configurar variáveis de ambiente
export SUPABASE_URL="sua_url_aqui"
export SUPABASE_SERVICE_KEY="sua_chave_aqui"

# Executar o job
python -m app.jobs.atualizar_acoes_info
```

## 📊 Estrutura da tabela acoes_info

A tabela `acoes_info` tem a seguinte estrutura:

| Coluna | Tipo | Descrição |
|--------|------|-----------|
| id | BIGSERIAL | ID único (auto-incremento) |
| ticker | TEXT | Ticker da B3 (ex: PETR4) - UNIQUE |
| symbol | TEXT | Symbol do yfinance (ex: PETR4.SA) |
| nome_longo | TEXT | Nome completo da empresa |
| nome_curto | TEXT | Nome resumido |
| descricao | TEXT | Descrição do negócio |
| pais | TEXT | País da sede |
| ... | ... | (outros campos) |

## 🔄 Quando executar?

O job é executado automaticamente:
- **Semanalmente** junto com o universo de ações (domingo 02:00 UTC)
- **Manualmente** quando você acionar o workflow

Como as informações são **fixas** (não mudam com frequência), não é necessário executar diariamente.

## ⚠️ Importante

- O yfinance pode não ter dados para todas as ações brasileiras
- Algumas ações podem retornar informações incompletas
- O sistema trata erros graciosamente e continua processando
- Um delay de 1 segundo é aplicado entre requisições para não sobrecarregar o yfinance

## 📝 Logs

O sistema gera logs detalhados mostrando:
- Progresso da coleta (X/Y processados)
- Sucessos e falhas
- Resumo final com estatísticas

## 🔗 Relação com a tabela `acoes`

A tabela `acoes_info` usa o mesmo `ticker` da tabela `acoes`, permitindo que você faça JOINs facilmente:

```sql
SELECT
    a.ticker,
    a.nome_curto,
    ai.descricao,
    ai.setor,
    ai.numero_funcionarios,
    ai.website
FROM acoes a
LEFT JOIN acoes_info ai ON a.ticker = ai.ticker
WHERE a.ativo = true;
```
