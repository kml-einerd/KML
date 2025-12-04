#!/usr/bin/env python3
"""
Script para listar TODOS os objetos do banco Supabase
"""

import os
from pathlib import Path
from dotenv import load_dotenv
import requests
from urllib.parse import urljoin

env_path = Path(__file__).parent.parent.parent / '.env'
load_dotenv(env_path)

url = os.getenv('SUPABASE_URL')
service_key = os.getenv('SUPABASE_SERVICE_KEY')

headers = {
    'apikey': service_key,
    'Authorization': f'Bearer {service_key}',
    'Content-Type': 'application/json',
    'Prefer': 'return=representation'
}

# Query para listar todos os objetos
sql_queries = {
    'tables': """
        SELECT schemaname, tablename, tableowner
        FROM pg_tables
        WHERE schemaname = 'public'
        ORDER BY tablename;
    """,
    'views': """
        SELECT schemaname, viewname, viewowner
        FROM pg_views
        WHERE schemaname = 'public'
        ORDER BY viewname;
    """,
    'mat_views': """
        SELECT schemaname, matviewname, matviewowner
        FROM pg_matviews
        WHERE schemaname = 'public'
        ORDER BY matviewname;
    """,
    'functions': """
        SELECT n.nspname as schema,
               p.proname as function_name,
               pg_get_function_identity_arguments(p.oid) as arguments
        FROM pg_proc p
        JOIN pg_namespace n ON p.pronamespace = n.oid
        WHERE n.nspname = 'public'
        ORDER BY p.proname;
    """,
    'triggers': """
        SELECT trigger_schema, trigger_name, event_object_table
        FROM information_schema.triggers
        WHERE trigger_schema = 'public'
        ORDER BY trigger_name;
    """
}

print("\n" + "="*60)
print("ANÁLISE COMPLETA DO BANCO SUPABASE")
print("="*60 + "\n")

for obj_type, query in sql_queries.items():
    print(f"\n📋 {obj_type.upper().replace('_', ' ')}:")
    print("-" * 60)

    # Fazer requisição via RPC se existir, ou printar query
    print(f"Query: {query.strip()[:100]}...")
    print("\n⚠️  Execute esta query no Supabase SQL Editor para ver resultados\n")

print("\n" + "="*60)
print("INSTRUÇÕES:")
print("="*60)
print("1. Copie as queries acima")
print("2. Execute no Supabase SQL Editor")
print("3. Compare resultados com a lista de tabelas a manter")
print("\n")
