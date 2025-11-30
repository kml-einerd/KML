# 🎯 Radar Institucional - ETL Application

Aplicação Python para processar dados da CVM (Comissão de Valores Mobiliários) e fazer upload para Supabase, preparando os dados para o MVP do Radar Institucional.

## 📋 O que esta aplicação faz?

1. **Lê arquivos CSV da CVM** (balancetes e patrimônio líquido de fundos)
2. **Limpa e normaliza** os dados (encoding, formatos, valores)
3. **Aplica filtros do MVP** (apenas ações, grandes fundos, posições relevantes)
4. **Calcula agregações** (Top Movers, Fresh Bets, Ativos Populares)
5. **Faz upload para Supabase** em lotes com retry automático
6. **Interface CLI interativa** com feedback visual

## 🚀 Instalação

### 1. Pré-requisitos

- Python 3.10 ou superior
- Conta no Supabase (grátis)
- Arquivos CSV da CVM (baixar de https://dados.cvm.gov.br/)

### 2. Instalar dependências

```bash
cd posição_fundos/etl_app
pip install -r requirements.txt
```

### 3. Configurar Supabase

```bash
# Copiar template de configuração
cp .env.example .env

# Editar .env com suas credenciais
# Obtenha em: https://app.supabase.com/project/_/settings/api
```

Conteúdo do `.env`:
```
SUPABASE_URL=https://seu-projeto.supabase.co
SUPABASE_KEY=sua-chave-publica-anon
```

### 4. Criar tabelas no Supabase

1. Acesse o SQL Editor do Supabase
2. Copie o conteúdo de `../database/schema.sql`
3. Execute o script
4. Copie o conteúdo de `../database/indexes.sql`
5. Execute o script

## 📂 Preparar os dados

Organize os arquivos CSV da CVM em uma pasta:

```
posição_fundos/source/
├── cda_fi_BLC_1_202510.csv
├── cda_fi_BLC_2_202510.csv
├── cda_fi_BLC_3_202510.csv
├── cda_fi_BLC_4_202510.csv
├── cda_fi_BLC_5_202510.csv
├── cda_fi_BLC_6_202510.csv
├── cda_fi_BLC_7_202510.csv
├── cda_fi_BLC_8_202510.csv
├── cda_fi_PL_202510.csv
└── ... (outros meses)
```

## 🎮 Como Usar

### Executar a aplicação

```bash
python main.py
```

### Menu Interativo

```
🎯 RADAR INSTITUCIONAL - ETL

[1] 📁 Processar arquivos CVM
[2] 📤 Upload para Supabase
[3] ✅ Validar dados processados
[4] 🔍 Verificar status Supabase
[5] ⚙️  Configurar Supabase
[6] 🚪 Sair
```

### Fluxo recomendado

1. **Processar arquivos CVM** → Lê, limpa e filtra os dados
2. **Validar dados** → Confere estatísticas
3. **Upload para Supabase** → Envia dados processados
4. **Verificar status** → Confirma que dados foram salvos

## 📊 Dados Processados

### Filtros Aplicados

- ✅ Apenas **ações** (remove renda fixa, derivativos, etc.)
- ✅ Apenas **grandes fundos** (PL > R$ 50 milhões)
- ✅ Apenas **posições relevantes** (> R$ 100 mil)
- ✅ Apenas **tipos válidos** (ações ON, PN, Units)

### Resultado

- **Redução de ~90%** dos dados originais
- De **591k registros** → **~50k registros** por mês
- Foco total nas **ações dos grandes players**

## 🗄️ Tabelas criadas no Supabase

| Tabela | Descrição | Registros (3 meses) |
|--------|-----------|---------------------|
| `fundos` | Cadastro de fundos | ~300 |
| `patrimonio_liquido_mensal` | PL mensal | ~900 |
| `posicoes_acoes` | Posições em ações | ~150.000 |
| `top_movers` | Rankings pré-calculados | ~900 |
| `fresh_bets` | Novas apostas | ~100 |
| `ativos_metadata` | Info dos ativos | ~500 |

## ⚙️ Configurações Avançadas

Edite `config.py` para customizar:

```python
# Threshold para "grande fundo"
THRESHOLD_GRANDE_FUNDO = 50_000_000  # R$ 50M

# Tamanho do lote para upload
BATCH_SIZE = 1000

# Tentativas em caso de erro
MAX_RETRIES = 3

# Valor mínimo de posição
VALOR_MINIMO_POSICAO = 100_000  # R$ 100k
```

## 🐛 Troubleshooting

### Erro: "SUPABASE_URL não configurado"

- Verifique se o arquivo `.env` existe
- Confirme se as variáveis estão corretas

### Erro de encoding

- Os arquivos CVM usam `latin1` (ISO-8859-1)
- A aplicação detecta automaticamente, mas pode haver problemas
- Logs em `logs/etl.log`

### Upload lento

- Normal para 150k+ registros
- Lotes de 1000 registros
- Tempo estimado: 2-4 minutos

### Erro: "Table doesn't exist"

- Execute os scripts SQL primeiro (`schema.sql` e `indexes.sql`)
- Verifique no Supabase Table Editor

## 📝 Logs

Logs são salvos em `logs/etl.log` com rotação automática:

```bash
tail -f logs/etl.log
```

## 🧪 Testes

Execute testes dos módulos:

```bash
python -m processors.csv_reader
python -m processors.data_cleaner
python -m processors.filters
python -m utils.validators
```

## 📚 Documentação Adicional

- `../docs/PLANO_VISUALIZACAO.md` - Queries para o dashboard
- `../docs/DESIGN_INTERFACE.md` - Especificações de UI
- `../docs/ARQUITETURA_DADOS.md` - Diagrama ER e fluxo

## 🤝 Suporte

Problemas? Abra uma issue no GitHub com:
- Versão do Python
- Sistema operacional
- Logs relevantes (`logs/etl.log`)
- Mensagem de erro completa

## 📄 Licença

MIT License - Livre para uso e modificação

---

**Desenvolvido para o Radar Institucional MVP**
