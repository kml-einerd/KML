# 🔧 Instruções para Corrigir Permissões do Supabase

## 🔴 Problema Identificado

O erro `permission denied for schema public` ocorre porque o Supabase está com **Row Level Security (RLS)** ativado, bloqueando o acesso mesmo com a chave `service_role`.

## ✅ Solução Rápida (5 minutos)

### Passo 1: Abrir SQL Editor do Supabase

1. Acesse: https://supabase.com/dashboard/projects
2. Selecione seu projeto
3. No menu lateral, clique em **"SQL Editor"**
4. Clique em **"New Query"**

### Passo 2: Executar o Script de Correção

1. Abra o arquivo: `fix_supabase_permissions.sql` (está na mesma pasta desta instrução)
2. **Copie TODO o conteúdo** do arquivo SQL
3. **Cole no SQL Editor** do Supabase
4. Clique em **"Run"** (ou pressione Ctrl/Cmd + Enter)

### Passo 3: Verificar se Funcionou

Execute este comando no terminal:

```bash
python test_supabase_connection.py
```

**Resultado esperado:**
```
✅ Cliente inicializado
✅ SELECT funcionou!
✅ INSERT funcionou!
✅ UPSERT funcionou!
```

### Passo 4: Executar o ETL Novamente

```bash
python main.py
```

Agora deve funcionar sem erros de permissão!

---

## 🔐 Alternativa: Desabilitar RLS Manualmente (Interface Gráfica)

Se preferir usar a interface gráfica:

1. Acesse: **Table Editor** no Supabase Dashboard
2. Para **cada tabela** (fundos, emissores, ativos, etc):
   - Clique na tabela
   - Clique no botão **"RLS"** no menu superior
   - Clique em **"Disable RLS"**
3. Repita para todas as tabelas listadas no arquivo SQL

---

## ❓ Por que isso aconteceu?

O Supabase ativa RLS (Row Level Security) por padrão para proteger seus dados. Isso é ótimo para aplicações web públicas, mas para um ETL interno, precisamos desabilitar ou criar políticas específicas para a `service_role`.

## ⚠️ Importante

- ✅ Desabilitar RLS está OK para dados internos/administrativos
- ✅ A chave `service_role` nunca deve ser exposta em aplicações frontend
- ✅ Use a chave `anon` com RLS ativado apenas para acesso público

---

## 🆘 Ainda com Problemas?

Se após seguir todos os passos ainda houver erros:

1. Verifique se as tabelas existem:
   ```sql
   SELECT table_name FROM information_schema.tables
   WHERE table_schema = 'public'
   ORDER BY table_name;
   ```

2. Verifique permissões do service_role:
   ```sql
   SELECT grantee, table_name, privilege_type
   FROM information_schema.table_privileges
   WHERE grantee = 'service_role' AND table_schema = 'public';
   ```

3. Se as tabelas não existirem, execute os scripts de criação:
   - `posição_fundos/database/normalized_schema.sql`
   - `posição_fundos/database/normalized_indexes.sql`

---

## ✅ Checklist

- [ ] Executei o script `fix_supabase_permissions.sql` no Supabase
- [ ] Executei `python test_supabase_connection.py` - todos os testes passaram
- [ ] Executei `python main.py` - ETL rodou sem erros de permissão
- [ ] Os dados foram inseridos com sucesso no Supabase

---

📝 Criado em: 2025-12-01
🤖 Gerado automaticamente pelo assistente de correção
