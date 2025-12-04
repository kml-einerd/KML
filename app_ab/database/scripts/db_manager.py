#!/usr/bin/env python3
"""
Database Manager - Gerenciador do banco Supabase
Permite executar SQL, visualizar tabelas, e gerenciar o schema
"""

import os
import sys
from pathlib import Path
from dotenv import load_dotenv
import psycopg2
from psycopg2.extras import RealDictCursor

# Carregar variáveis de ambiente
env_path = Path(__file__).parent.parent.parent / '.env'
load_dotenv(env_path)

class SupabaseManager:
    def __init__(self):
        self.url = os.getenv('SUPABASE_URL')
        self.service_key = os.getenv('SUPABASE_SERVICE_KEY')
        self.db_url = os.getenv('DATABASE_URL')

        if not all([self.url, self.service_key, self.db_url]):
            raise ValueError("❌ Credenciais não encontradas no .env")

        # Conexão PostgreSQL direta
        self.pg_conn = None

    def connect_pg(self):
        """Conectar ao PostgreSQL diretamente"""
        if not self.pg_conn or self.pg_conn.closed:
            self.pg_conn = psycopg2.connect(self.db_url)
        return self.pg_conn

    def execute_sql_file(self, file_path: str, verbose=True):
        """Executar arquivo SQL"""
        conn = self.connect_pg()
        cursor = conn.cursor()

        try:
            with open(file_path, 'r', encoding='utf-8') as f:
                sql = f.read()

            if verbose:
                print(f"📄 Executando: {file_path}")

            cursor.execute(sql)
            conn.commit()

            if verbose:
                print(f"✅ Sucesso: {file_path}")

            return True
        except Exception as e:
            conn.rollback()
            print(f"❌ Erro ao executar {file_path}:")
            print(f"   {str(e)}")
            return False
        finally:
            cursor.close()

    def execute_sql(self, sql: str, fetch=False):
        """Executar SQL direto"""
        conn = self.connect_pg()
        cursor = conn.cursor(cursor_factory=RealDictCursor)

        try:
            cursor.execute(sql)

            if fetch:
                result = cursor.fetchall()
                return [dict(row) for row in result]
            else:
                conn.commit()
                return True
        except Exception as e:
            conn.rollback()
            print(f"❌ Erro SQL: {str(e)}")
            return None
        finally:
            cursor.close()

    def list_tables(self):
        """Listar todas as tabelas"""
        sql = """
        SELECT
            schemaname,
            tablename,
            pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) AS size
        FROM pg_tables
        WHERE schemaname = 'public'
        ORDER BY tablename;
        """
        return self.execute_sql(sql, fetch=True)

    def describe_table(self, table_name: str):
        """Descrever estrutura de uma tabela"""
        sql = f"""
        SELECT
            column_name,
            data_type,
            character_maximum_length,
            is_nullable,
            column_default
        FROM information_schema.columns
        WHERE table_schema = 'public'
          AND table_name = '{table_name}'
        ORDER BY ordinal_position;
        """
        return self.execute_sql(sql, fetch=True)

    def count_rows(self, table_name: str):
        """Contar linhas de uma tabela"""
        sql = f"SELECT COUNT(*) as count FROM public.{table_name}"
        result = self.execute_sql(sql, fetch=True)
        return result[0]['count'] if result else 0

    def table_exists(self, table_name: str):
        """Verificar se tabela existe"""
        sql = f"""
        SELECT EXISTS (
            SELECT 1 FROM information_schema.tables
            WHERE table_schema = 'public'
              AND table_name = '{table_name}'
        ) as exists;
        """
        result = self.execute_sql(sql, fetch=True)
        return result[0]['exists'] if result else False

    def drop_table(self, table_name: str, cascade=False):
        """Deletar uma tabela"""
        cascade_str = "CASCADE" if cascade else ""
        sql = f"DROP TABLE IF EXISTS public.{table_name} {cascade_str};"
        return self.execute_sql(sql)

    def close(self):
        """Fechar conexões"""
        if self.pg_conn and not self.pg_conn.closed:
            self.pg_conn.close()


def main():
    """Menu interativo"""
    import argparse

    parser = argparse.ArgumentParser(description='Gerenciador de Banco Supabase')
    parser.add_argument('--list', action='store_true', help='Listar tabelas')
    parser.add_argument('--describe', type=str, help='Descrever tabela')
    parser.add_argument('--count', type=str, help='Contar linhas de tabela')
    parser.add_argument('--execute', type=str, help='Executar arquivo SQL')
    parser.add_argument('--sql', type=str, help='Executar SQL direto')
    parser.add_argument('--setup', action='store_true', help='Executar setup completo (todos os schemas)')

    args = parser.parse_args()

    try:
        db = SupabaseManager()

        if args.list:
            print("\n📊 Tabelas no banco:\n")
            tables = db.list_tables()
            for table in tables:
                print(f"  • {table['tablename']} ({table['size']})")

        elif args.describe:
            print(f"\n📋 Estrutura da tabela '{args.describe}':\n")
            columns = db.describe_table(args.describe)
            for col in columns:
                nullable = "NULL" if col['is_nullable'] == 'YES' else "NOT NULL"
                print(f"  {col['column_name']}: {col['data_type']} {nullable}")

        elif args.count:
            count = db.count_rows(args.count)
            print(f"\n📈 Tabela '{args.count}': {count} linhas")

        elif args.execute:
            db.execute_sql_file(args.execute)

        elif args.sql:
            result = db.execute_sql(args.sql, fetch=True)
            print("\n📋 Resultado:")
            for row in result:
                print(row)

        elif args.setup:
            print("\n🚀 Executando setup completo do banco...\n")
            schema_dir = Path(__file__).parent.parent / 'schema'

            # Executar na ordem correta
            files = [
                schema_dir / '01_tables.sql',
                schema_dir / '02_derived_tables.sql',
            ]

            for file in files:
                if file.exists():
                    db.execute_sql_file(str(file))
                else:
                    print(f"⚠️  Arquivo não encontrado: {file}")

            print("\n✅ Setup completo!")
            print("\n📊 Tabelas criadas:")
            tables = db.list_tables()
            for table in tables:
                print(f"  • {table['tablename']}")

        else:
            parser.print_help()

        db.close()

    except Exception as e:
        print(f"\n❌ Erro: {str(e)}")
        sys.exit(1)


if __name__ == '__main__':
    main()
