# 🔧 Solucionar Erro de Conexão Dashboard

---

## ❌ ERRO: "Erro ao conectar com Supabase"

### 🎯 SOLUÇÃO RÁPIDA (2 minutos):

#### PASSO 1: Executar Script SQL

1. Abra: **https://app.supabase.com**
2. Clique em: **SQL Editor**
3. Copie e cole TODO o conteúdo de:
   ```
   /posição_fundos/sql_scripts/99_HABILITAR_ACESSO_PUBLICO.sql
   ```
4. Clique: **RUN**
5. Deve aparecer: `✅ RLS desabilitado! Dashboard deve funcionar agora.`

#### PASSO 2: Recarregar Dashboard

1. Volte para o dashboard no navegador
2. Pressione: **Ctrl + Shift + R** (ou **Cmd + Shift + R** no Mac)
3. Aguarde carregar (~3-5 segundos)
4. ✅ **Deve funcionar!**

---

## 🔍 O QUE ESTAVA ACONTECENDO?

### Problema
As tabelas do Supabase tinham **RLS (Row Level Security)** habilitado, impedindo acesso público de leitura.

### Solução
O script `99_HABILITAR_ACESSO_PUBLICO.sql` desabilita RLS nas 3 tabelas:
- `grupos_fundos`
- `acoes_fundos`
- `resumo_mensal`

### Por que é seguro?
✅ Os dados são públicos (fonte: CVM)
✅ Dashboard só faz LEITURA (nunca escreve)
✅ Não há informações sensíveis
✅ É o padrão para dashboards públicos

---

## 🧪 VERIFICAR SE FUNCIONOU

### No Supabase SQL Editor:
```sql
SELECT tablename, rowsecurity
FROM pg_tables
WHERE schemaname = 'public'
  AND tablename IN ('grupos_fundos', 'acoes_fundos', 'resumo_mensal');
```

**Resultado esperado:**
```
tablename        | rowsecurity
-----------------+-------------
grupos_fundos    | false
acoes_fundos     | false
resumo_mensal    | false
```

Se `rowsecurity = false`, está correto! ✅

---

## 🔧 SE AINDA NÃO FUNCIONAR

### 1. Verificar Console do Navegador

1. Abra dashboard
2. Pressione **F12** (ou **Cmd + Option + I** no Mac)
3. Clique aba **Console**
4. Procure mensagens de erro (texto vermelho)
5. Me envie o erro exato

### 2. Verificar Chaves API

As chaves no código devem ser:
```javascript
SUPABASE_URL = 'https://ryfhupidxkghwkczulgg.supabase.co'
SUPABASE_ANON_KEY = 'eyJhbGci...Bne0WnMN9URE3kock_jd4u-0ZeyFUkKVAcGKr27kF5Q'
```

✅ **Já corrigido!** Não precisa mexer.

### 3. Verificar Dados no Supabase

Execute no SQL Editor:
```sql
-- Verificar se tem dados
SELECT COUNT(*) FROM grupos_fundos;
SELECT COUNT(*) FROM acoes_fundos;
SELECT COUNT(*) FROM resumo_mensal;
```

**Deve retornar números >0 para cada tabela.**

Se retornar 0, você precisa:
1. Executar ETL V2 primeiro
2. Carregar dados

---

## 📊 TESTE RÁPIDO DE CONEXÃO

### Teste Manual no Console do Navegador:

1. Abra dashboard
2. Pressione **F12**
3. Aba **Console**
4. Cole e execute:
   ```javascript
   const testClient = window.supabase.createClient(
       'https://ryfhupidxkghwkczulgg.supabase.co',
       'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJ5Zmh1cGlkeGtnaHdrY3p1bGdnIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjU0NjYyMzcsImV4cCI6MjA4MTA0MjIzN30.Bne0WnMN9URE3kock_jd4u-0ZeyFUkKVAcGKr27kF5Q'
   );

   testClient.from('grupos_fundos').select('*').limit(1).then(result => {
       console.log('Resultado:', result);
   });
   ```

5. Veja resultado:
   - ✅ **Se aparecer `data: [{...}]`** → Conexão OK!
   - ❌ **Se aparecer `error: {...}`** → Copie o erro e me envie

---

## 🎯 CHECKLIST COMPLETO

- [ ] Executei `99_HABILITAR_ACESSO_PUBLICO.sql` no Supabase
- [ ] Apareceu mensagem de sucesso
- [ ] Verifiquei que `rowsecurity = false`
- [ ] Recarreguei dashboard (Ctrl+Shift+R)
- [ ] Abri Console do navegador (F12)
- [ ] Não vejo erros vermelhos
- [ ] Dashboard carregou dados

**Se todos ✅ → Dashboard funcionando!** 🎉

---

## 💡 DICA PRO

Deixe o Console do navegador (F12) aberto enquanto usa o dashboard.

Você verá:
- ✅ Logs de sucesso (verde)
- ⚠️ Avisos (amarelo)
- ❌ Erros (vermelho)

Isso ajuda a diagnosticar problemas rapidamente.

---

## 📞 AINDA COM PROBLEMA?

Me envie:
1. Screenshot do console (F12)
2. Resultado da query de verificação RLS
3. Erro exato que aparece

---

✅ **Na maioria dos casos, executar o script SQL resolve!**
