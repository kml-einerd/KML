# ETL Pipeline - Sistema de Análise de Fundos Top 100

Pipeline ETL para processar dados da CVM e carregar no Supabase, focado nos Top 100 grupos econômicos.

## Visão Geral

Este ETL:
- 📥 Lê CSVs da CVM (pasta `source/`)
- 🔍 Identifica automaticamente grupos econômicos
- 🎯 Filtra apenas Top 100 grupos (95%+ do mercado)
- 🧹 Limpa e normaliza dados
- 📤 Sobe para Supabase
- 📊 Calcula ranking e métricas

**Performance:** 90% mais rápido que processar todos os fundos!

---

## Instalação

### 1. Criar Ambiente Virtual

```bash
cd etl_app
python3 -m venv venv
source venv/bin/activate  # No Windows: venv\Scripts\activate
```

### 2. Instalar Dependências

```bash
pip install -r requirements.txt
```

### 3. Configurar Credenciais

```bash
# Copiar exemplo
cp .env.example .env

# Editar com suas credenciais
nano .env
```

**Preencha:**
```env
SUPABASE_URL=https://seu-projeto.supabase.co
SUPABASE_KEY=sua-service-role-key-aqui
```

**Onde encontrar:**
- Acesse https://app.supabase.com
- Vá em **Settings** → **API**
- Copie **URL** e **service_role key** (não a anon key!)

---

## Uso

### Comando Básico

```bash
python main.py --mes 10
```

**Isso irá:**
1. Processar dados de Outubro/2025 (ano atual)
2. Identificar Top 100 grupos
3. Processar posições em ações
4. Fazer upload para Supabase
5. Calcular ranking

### Especificar Ano

```bash
python main.py --ano 2024 --mes 12
```

### Customizar Quantidade de Grupos

```bash
python main.py --mes 10 --top 50  # Top 50 em vez de 100
```

### Ajuda

```bash
python main.py --help
```

---

## Estrutura de Arquivos

```
etl_app/
├── main.py                    # Pipeline principal (executar este)
├── requirements.txt           # Dependências Python
├── .env                       # Credenciais (criar a partir do .example)
├── .env.example              # Exemplo de configuração
│
├── processors/               # Processadores de CSVs
│   ├── patrimonio_processor.py    # Processa PL e identifica grupos
│   ├── acoes_processor.py          # Processa posições em ações
│   └── cadastro_processor.py       # Processa cadastro de fundos
│
├── uploaders/                # Upload para Supabase
│   └── supabase_uploader.py       # Cliente Supabase
│
└── utils/                    # Utilitários
    ├── logger.py                  # Sistema de logs
    ├── groups_helper.py           # Identificação de grupos
    └── validator.py               # Validação de dados
```

---

## Fluxo de Processamento

### 1. Patrimônio Líquido (PL)
- Lê `cda_fi_PL_YYYYMM.csv`
- Identifica grupos econômicos
- Calcula Top N grupos por PL
- **Output:** Lista de Top grupos + dados de PL

### 2. Posições em Ações
- Lê `cda_fi_BLC_4_YYYYMM.csv`
- Filtra apenas fundos dos Top grupos
- Calcula rentabilidade
- Classifica movimentações (compra/venda)
- **Output:** Posições em ações dos Top grupos

### 3. Cadastro de Fundos
- Lê `cda_fie_YYYYMM.csv`
- Filtra apenas fundos dos Top grupos
- **Output:** Dados cadastrais dos fundos

### 4. Upload para Supabase
- Faz upload em batches (padrão: 1000 registros)
- Salva backup local em `processed/`

### 5. Cálculo de Ranking
- Executa função `atualizar_ranking_top100_v2(ano, mes)`
- Gera rankings por: patrimônio, volume, fluxo, rentabilidade

---

## Logs

### Console
Logs coloridos em tempo real:
- 🟢 **INFO** - Progresso normal
- 🟡 **WARNING** - Avisos
- 🔴 **ERROR** - Erros

### Arquivo
Logs detalhados salvos em:
```
../logs/etl_YYYYMMDD.log
```

---

## Dados Processados (Backup Local)

Salvos em `../processed/`:
```
pl_202510.csv          # Patrimônio líquido
acoes_202510.csv       # Posições em ações
cadastro_202510.csv    # Cadastro de fundos
```

---

## Configurações Avançadas (.env)

```env
# Tamanho do batch para upload
BATCH_SIZE=1000

# Nível de log (DEBUG, INFO, WARNING, ERROR)
LOG_LEVEL=INFO

# Processar apenas Top 100
TOP100_MODE=true

# Quantidade de grupos no Top
TOP_N_GROUPS=100
```

---

## Troubleshooting

### Erro: "Arquivo não encontrado"
**Solução:** Verifique se os CSVs estão na pasta `../source/`

Formato esperado:
```
source/
├── cda_fi_PL_202510.csv
├── cda_fi_BLC_4_202510.csv
└── cda_fie_202510.csv
```

### Erro: "Credenciais do Supabase não encontradas"
**Solução:** Configure o arquivo `.env` com suas credenciais

### Erro de Conexão com Supabase
**Solução:**
1. Verifique se a URL e KEY estão corretas
2. Teste a conexão:
```python
from supabase import create_client
client = create_client("sua-url", "sua-key")
print(client.table('dim_tempo').select("*").limit(1).execute())
```

### Pipeline lento
**Solução:**
1. Aumente `BATCH_SIZE` no .env (ex: 2000)
2. Use conexão de internet rápida
3. Verifique se está usando `--top 100` (não processar todos os grupos)

---

## Requisitos de Sistema

- Python 3.11+
- 2GB+ RAM
- 500MB+ espaço em disco
- Conexão com internet

---

## Desenvolvimento

### Adicionar Novo Processador

1. Criar arquivo em `processors/`
2. Herdar de `BaseProcessor`
3. Implementar método `process()`

Exemplo:
```python
from processors.base_processor import BaseProcessor

class MeuProcessor(BaseProcessor):
    def process(self, **kwargs):
        df = self.read_csv('arquivo.csv')
        # processar...
        return df
```

### Rodar Testes

```bash
# TODO: Adicionar testes unitários
pytest tests/
```

---

## Próximos Passos Após ETL

1. **Consultar dados no Supabase:**
```sql
SELECT * FROM v_top100_atual LIMIT 10;
SELECT * FROM v_dashboard_top100;
```

2. **Criar dashboard:**
- Metabase
- Tableau
- Power BI
- Streamlit

3. **Agendar execução mensal:**
```bash
# Cron job (Linux/Mac)
0 0 1 * * cd /path/to/etl_app && ./main.py --mes $(date +\%m)
```

---

## Suporte

- **Documentação:** Ver `../README.md` principal
- **Migração:** Ver `../sql_scripts/README_MIGRACAO.md`
- **Logs:** Ver `../logs/`

---

## Versão

**1.0.0** - Sistema completo de ETL para Top 100 grupos

**Última atualização:** 2025-12-13
