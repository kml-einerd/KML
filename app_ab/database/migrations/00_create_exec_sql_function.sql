-- =====================================================================
-- CRIAR FUNÇÃO PARA EXECUTAR SQL VIA API
-- Execute este script PRIMEIRO no Supabase SQL Editor
-- =====================================================================

CREATE OR REPLACE FUNCTION exec_sql(sql_query text)
RETURNS text
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    result_text text;
BEGIN
    EXECUTE sql_query;
    result_text := 'SQL executado com sucesso';
    RETURN result_text;
EXCEPTION
    WHEN OTHERS THEN
        RETURN 'Erro: ' || SQLERRM;
END;
$$;

-- Permitir execução pela role service_role
GRANT EXECUTE ON FUNCTION exec_sql(text) TO service_role;
GRANT EXECUTE ON FUNCTION exec_sql(text) TO postgres;
