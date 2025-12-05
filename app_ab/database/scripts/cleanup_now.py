#!/usr/bin/env python3
"""
Script para executar limpeza do banco AGORA via psql
"""

import os
import sys
from pathlib import Path
from dotenv import load_dotenv
import subprocess

env_path = Path(__file__).parent.parent.parent / '.env'
load_dotenv(env_path)

db_url = os.getenv('DATABASE_URL')

if not db_url:
    print("❌ DATABASE_URL não encontrada no .env")
    sys.exit(1)

# SQL de limpeza
cleanup_sql = """
-- Limpeza do banco
DROP MATERIALIZED VIEW IF EXISTS public.mv_fresh_bets_30d CASCADE;
DROP MATERIALIZED VIEW IF EXISTS public.mv_fundo_summary_mes CASCADE;
DROP VIEW IF EXISTS public.view_dashboard_fundos CASCADE;
DROP VIEW IF EXISTS public.view_fresh_bets_summary CASCADE;
DROP TRIGGER IF EXISTS trg_top_movers_sync ON public.top_movers;
DROP TABLE IF EXISTS public.fresh_bets_participantes CASCADE;
DROP TABLE IF EXISTS public.snapshots_posicoes CASCADE;
DROP TABLE IF EXISTS public.audit_etl CASCADE;
DROP FUNCTION IF EXISTS public.etl_populate_derivatives() CASCADE;
DROP FUNCTION IF EXISTS public.sync_top_movers_aliases() CASCADE;
DROP FUNCTION IF EXISTS public.has_data_for_month(DATE, DATE) CASCADE;
DROP FUNCTION IF EXISTS public.update_updated_at_column() CASCADE;
"""

print("\n🧹 Executando limpeza do banco de dados...\n")

# Executar via psql
try:
    result = subprocess.run(
        ['psql', db_url, '-c', cleanup_sql],
        capture_output=True,
        text=True,
        timeout=30
    )

    if result.returncode == 0:
        print("✅ Limpeza executada com sucesso!")
        print("\nSaída:")
        print(result.stdout)
    else:
        print(f"❌ Erro ao executar limpeza:")
        print(result.stderr)
        sys.exit(1)

except FileNotFoundError:
    print("❌ psql não encontrado. Executando via python...")
    # Fallback para psycopg2
    import psycopg2

    conn = psycopg2.connect(db_url)
    cursor = conn.cursor()

    try:
        cursor.execute(cleanup_sql)
        conn.commit()
        print("✅ Limpeza executada com sucesso via psycopg2!")
    except Exception as e:
        print(f"❌ Erro: {e}")
        conn.rollback()
    finally:
        cursor.close()
        conn.close()

except Exception as e:
    print(f"❌ Erro: {e}")
    sys.exit(1)

print("\n📊 Verificando tabelas restantes...")
