# Changelog - Sistema de Análise de Fundos

---

## [4.0.0] - 2025-12-13

### ✨ Novo - ETL Completo e Otimizado

#### Pipeline ETL Python
- ✅ **Processadores completos** para todos os CSVs da CVM
  - `PatrimonioProcessor` - Patrimônio líquido + identificação de grupos
  - `AcoesProcessor` - Posições em ações (BLC_4)
  - `CadastroProcessor` - Cadastro de fundos

- ✅ **Sistema de Grupos Econômicos**
  - Identificação automática de grupos a partir do nome dos fundos
  - Mapeamento de grupos conhecidos (BTG, Itaú, XP, etc.)
  - Cálculo automático do Top N grupos por patrimônio

- ✅ **Upload Otimizado para Supabase**
  - Upload em batches configurável
  - Tratamento de erros por registro
  - Suporte a upsert
  - Limpeza automática de dados

- ✅ **Sistema de Logs**
  - Logs coloridos no console
  - Logs detalhados em arquivo
  - Progress bars com tqdm

- ✅ **Validação de Dados**
  - Validação de colunas obrigatórias
  - Verificação de valores nulos
  - Validação de ranges numéricos
  - Remoção de duplicatas

- ✅ **Backup Automático**
  - Salvamento local de dados processados
  - Formato CSV para análise offline

#### Arquivos Criados

**ETL Core:**
- `etl_app/main.py` - Pipeline principal (executável)
- `etl_app/requirements.txt` - Dependências Python
- `etl_app/.env.example` - Exemplo de configuração
- `etl_app/README.md` - Documentação completa do ETL

**Processadores:**
- `etl_app/processors/base_processor.py` - Classe base
- `etl_app/processors/patrimonio_processor.py` - Processador de PL
- `etl_app/processors/acoes_processor.py` - Processador de ações
- `etl_app/processors/cadastro_processor.py` - Processador de cadastro
- `etl_app/processors/__init__.py`

**Uploaders:**
- `etl_app/uploaders/supabase_uploader.py` - Cliente Supabase
- `etl_app/uploaders/__init__.py`

**Utilitários:**
- `etl_app/utils/logger.py` - Sistema de logs
- `etl_app/utils/groups_helper.py` - Helper de grupos
- `etl_app/utils/validator.py` - Validação de dados
- `etl_app/utils/__init__.py`

#### Documentação Atualizada

- ✅ `EXECUCAO_RAPIDA.md` - Guia passo a passo de 15 minutos
- ✅ `README.md` - Atualizado com informações do ETL
- ✅ `etl_app/README.md` - Documentação completa do pipeline

### 🎯 Otimizações

- **Performance:** 90% mais rápido processando apenas Top 100 grupos
- **Automação:** Pipeline end-to-end completamente automatizado
- **Flexibilidade:** Configuração via variáveis de ambiente
- **Confiabilidade:** Validação em múltiplas camadas
- **Observabilidade:** Logs detalhados e estatísticas em tempo real

### 📋 Como Usar

#### Setup Inicial (uma vez)
```bash
# 1. Configurar credenciais
cd etl_app
cp .env.example .env
nano .env  # Preencher SUPABASE_URL e SUPABASE_KEY

# 2. Instalar dependências
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
```

#### Execução (mensal)
```bash
cd etl_app
source venv/bin/activate
python main.py --mes 10  # Outubro
```

### 🔧 Configurações (.env)

```env
SUPABASE_URL=https://seu-projeto.supabase.co
SUPABASE_KEY=sua-service-role-key-aqui
LOG_LEVEL=INFO
BATCH_SIZE=1000
TOP100_MODE=true
TOP_N_GROUPS=100
```

### 📊 Output

**Console:**
- Progresso em tempo real com cores
- Estatísticas de processamento
- Avisos e erros destacados

**Backup Local (processed/):**
- `pl_YYYYMM.csv` - Patrimônio líquido
- `acoes_YYYYMM.csv` - Posições em ações
- `cadastro_YYYYMM.csv` - Cadastro de fundos

**Supabase:**
- Dados inseridos automaticamente
- Ranking calculado via stored procedure
- Views atualizadas

---

## [3.0.0] - 2025-12-12

### Anterior
- Sistema Top 100
- Análise de ações B3
- Rentabilidade e performance
- Script único de migração

---

## Próximas Versões

### [4.1.0] - Planejado
- [ ] Processamento de outros blocos (BLC_1, BLC_2, etc.)
- [ ] Histórico de ranking (comparação mensal)
- [ ] Exportação para Excel/PDF
- [ ] Notificações por email

### [5.0.0] - Futuro
- [ ] Dashboard web interativo
- [ ] API REST documentada
- [ ] Agendamento automático (cron)
- [ ] Machine Learning para previsões

---

## Dependências

**Python 3.11+**
```
supabase==2.3.4
pandas==2.1.4
python-dotenv==1.0.0
tqdm==4.66.1
colorama==0.4.6
```

**PostgreSQL 14+ (Supabase)**

---

## Compatibilidade

- ✅ macOS (testado)
- ✅ Linux (compatível)
- ✅ Windows (compatível com ajustes)
- ✅ Python 3.11+
- ✅ Supabase (PostgreSQL 14+)

---

## Migração de Versões Anteriores

Se você tinha versão 3.0 ou anterior:

1. **Backup dos dados atuais** (se tiver)
2. **Executar novo script de migração** (17_migracao_completa_supabase.sql)
3. **Configurar ETL** (copiar .env.example → .env)
4. **Instalar dependências** (pip install -r requirements.txt)
5. **Executar pipeline** (python main.py --mes XX)

---

## Suporte

- **Issues:** Reporte problemas via GitHub Issues
- **Documentação:** Ver README.md e arquivos .md nas pastas
- **Email:** [seu-email]

---

**Mantenedores:** [Seu Nome]
**Licença:** MIT (ou conforme projeto)
