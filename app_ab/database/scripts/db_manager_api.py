#!/usr/bin/env python3
"""
Database Manager via API REST - Gerenciador do banco Supabase via API
Usa a REST API do Supabase invés de conexão PostgreSQL direta
"""

import os
import sys
from pathlib import Path
from dotenv import load_dotenv
import requests
from urllib.parse import urljoin

# Carregar variáveis de ambiente
env_path = Path(__file__).parent.parent.parent / '.env'
load_dotenv(env_path)

class SupabaseAPI:
    def __init__(self):
        self.url = os.getenv('SUPABASE_URL')
        self.service_key = os.getenv('SUPABASE_SERVICE_KEY')

        if not all([self.url, self.service_key]):
            raise ValueError("❌ Credenciais não encontradas no .env")

        self.headers = {
            'apikey': self.service_key,
            'Authorization': f'Bearer {self.service_key}',
            'Content-Type': 'application/json'
        }

        self.rest_url = urljoin(self.url, '/rest/v1/')
        self.postgrest_url = self.rest_url

    def execute_sql(self, sql: str):
        """Executar SQL via RPC (se configurado) ou via postgREST"""
        # Via endpoint /rpc se existir função
        url = urljoin(self.url, '/rest/v1/rpc/exec_sql')

        try:
            response = requests.post(
                url,
                json={'query': sql},
                headers=self.headers,
                timeout=30
            )

            if response.status_code == 200:
                return response.json()
            else:
                print(f"❌ Erro HTTP {response.status_code}: {response.text}")
                return None
        except Exception as e:
            print(f"❌ Erro: {str(e)}")
            return None

    def list_tables(self):
        """Listar tabelas via pg_catalog"""
        # Tentar via endpoint genérico
        tables_to_check = ['fundos', 'emissores', 'ativos', 'patrimonio_liquido',
                          'posicoes', 'posicoes_detalhes', 'audit_etl',
                          'snapshots_posicoes', 'top_movers', 'fresh_bets']

        existing_tables = []

        for table in tables_to_check:
            url = urljoin(self.postgrest_url, f'{table}?select=*&limit=1')
            try:
                response = requests.get(url, headers=self.headers, timeout=10)
                if response.status_code == 200:
                    # Tentar pegar count
                    count_url = urljoin(self.postgrest_url, f'{table}?select=count')
                    count_resp = requests.get(
                        count_url,
                        headers={**self.headers, 'Prefer': 'count=exact'},
                        timeout=10
                    )
                    count = count_resp.headers.get('Content-Range', '0').split('/')[-1]
                    existing_tables.append({'table': table, 'rows': count})
            except:
                pass

        return existing_tables

    def table_exists(self, table_name: str):
        """Verificar se tabela existe"""
        url = urljoin(self.postgrest_url, f'{table_name}?select=*&limit=1')
        try:
            response = requests.get(url, headers=self.headers, timeout=10)
            return response.status_code == 200
        except:
            return False

    def count_rows(self, table_name: str):
        """Contar linhas de tabela"""
        url = urljoin(self.postgrest_url, f'{table_name}?select=count')
        try:
            response = requests.get(
                url,
                headers={**self.headers, 'Prefer': 'count=exact'},
                timeout=10
            )
            if response.status_code == 200:
                count_range = response.headers.get('Content-Range', '0/0')
                return int(count_range.split('/')[-1])
            return 0
        except:
            return 0

    def query_table(self, table_name: str, limit=10):
        """Query simples em tabela"""
        url = urljoin(self.postgrest_url, f'{table_name}?select=*&limit={limit}')
        try:
            response = requests.get(url, headers=self.headers, timeout=10)
            if response.status_code == 200:
                return response.json()
            return []
        except:
            return []


def main():
    """CLI interativo"""
    import argparse

    parser = argparse.ArgumentParser(description='Gerenciador Supabase via API')
    parser.add_argument('--list', action='store_true', help='Listar tabelas')
    parser.add_argument('--count', type=str, help='Contar linhas')
    parser.add_argument('--query', type=str, help='Query tabela')
    parser.add_argument('--test', action='store_true', help='Testar conexão')

    args = parser.parse_args()

    try:
        api = SupabaseAPI()

        if args.test:
            print("\n🔍 Testando conexão com Supabase...\n")
            print(f"URL: {api.url}")
            print(f"Service Key: {api.service_key[:20]}...")

            # Testar endpoint
            url = urljoin(api.url, '/rest/v1/')
            response = requests.get(url, headers=api.headers, timeout=10)

            if response.status_code in [200, 404]:  # 404 é ok, significa que API está online
                print("\n✅ Conexão estabelecida!")
            else:
                print(f"\n❌ Erro: HTTP {response.status_code}")

        elif args.list:
            print("\n📊 Verificando tabelas existentes:\n")
            tables = api.list_tables()

            if tables:
                for t in tables:
                    print(f"  ✅ {t['table']} ({t['rows']} linhas)")
            else:
                print("  ℹ️  Nenhuma tabela encontrada (banco vazio)")

        elif args.count:
            count = api.count_rows(args.count)
            print(f"\n📈 Tabela '{args.count}': {count} linhas")

        elif args.query:
            data = api.query_table(args.query, limit=5)
            print(f"\n📋 Primeiras linhas de '{args.query}':\n")
            for row in data:
                print(row)

        else:
            parser.print_help()

    except Exception as e:
        print(f"\n❌ Erro: {str(e)}")
        sys.exit(1)


if __name__ == '__main__':
    main()
