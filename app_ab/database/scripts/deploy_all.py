#!/usr/bin/env python3
"""
Script de Deploy Completo - Radar Institucional
Executa todos os SQLs e popula o banco de dados

Uso:
    python3 deploy_all.py
"""

import os
import sys
from pathlib import Path
from dotenv import load_dotenv
import psycopg2
from psycopg2.extensions import ISOLATION_LEVEL_AUTOCOMMIT
import time

# Carregar .env
env_path = Path(__file__).parent.parent.parent / '.env'
load_dotenv(env_path)

class DatabaseDeployer:
    def __init__(self):
        self.db_url = os.getenv('DATABASE_URL')
        if not self.db_url:
            raise ValueError("❌ DATABASE_URL não encontrada no .env")

        self.schema_dir = Path(__file__).parent.parent / 'schema'
        self.conn = None

    def connect(self):
        """Conectar ao banco"""
        try:
            print("🔌 Conectando ao Supabase...")
            self.conn = psycopg2.connect(self.db_url)
            self.conn.set_isolation_level(ISOLATION_LEVEL_AUTOCOMMIT)
            print("✅ Conectado!")
            return True
        except Exception as e:
            print(f"❌ Erro ao conectar: {e}")
            print("\n⚠️  O script não conseguiu conectar via PostgreSQL direto.")
            print("Por favor, execute manualmente no Supabase SQL Editor:")
            print("\n1. Abra: https://supabase.com/dashboard")
            print("2. Vá em: SQL Editor")
            print("3. Execute os arquivos na ordem:\n")
            print("   - database/schema/03_dashboard_complete.sql")
            print("   - database/schema/04_etl_function.sql")
            print("   - SELECT * FROM populate_all_months();")
            return False

    def execute_sql_file(self, file_path: Path, description: str):
        """Executar arquivo SQL"""
        print(f"\n📄 {description}")
        print(f"   Arquivo: {file_path.name}")

        try:
            with open(file_path, 'r', encoding='utf-8') as f:
                sql = f.read()

            cursor = self.conn.cursor()
            cursor.execute(sql)

            print(f"✅ Sucesso!")
            return True

        except Exception as e:
            print(f"❌ Erro: {str(e)[:200]}")
            return False

    def run_etl(self):
        """Executar ETL para popular dados"""
        print("\n📈 Populando tabelas derivadas...")
        print("   Isso pode demorar alguns minutos...")

        try:
            cursor = self.conn.cursor()
            cursor.execute("SELECT * FROM populate_all_months();")
            results = cursor.fetchall()

            print("\n✅ ETL concluído!")
            print("\n📊 Resultados:")
            for row in results:
                mes, status, top_movers, fresh_bets = row
                print(f"   {mes}: {top_movers} top_movers, {fresh_bets} fresh_bets")

            return True

        except Exception as e:
            print(f"❌ Erro no ETL: {str(e)}")
            return False

    def verify_deployment(self):
        """Verificar se deployment foi bem sucedido"""
        print("\n🔍 Verificando deployment...")

        checks = [
            ("Views criadas", "SELECT COUNT(*) FROM pg_views WHERE schemaname = 'public' AND viewname LIKE 'v_%'"),
            ("Top Movers", "SELECT COUNT(*) FROM top_movers"),
            ("Fresh Bets", "SELECT COUNT(*) FROM fresh_bets"),
        ]

        all_ok = True
        for name, query in checks:
            try:
                cursor = self.conn.cursor()
                cursor.execute(query)
                count = cursor.fetchone()[0]
                status = "✅" if count > 0 else "⚠️ "
                print(f"{status} {name}: {count}")

                if count == 0 and name != "Views criadas":
                    all_ok = False
            except Exception as e:
                print(f"❌ {name}: Erro - {str(e)[:100]}")
                all_ok = False

        return all_ok

    def deploy(self):
        """Executar deployment completo"""
        print("\n" + "="*60)
        print("🚀 DEPLOY COMPLETO - RADAR INSTITUCIONAL")
        print("="*60)

        if not self.connect():
            return False

        # Passo 1: Schema do Dashboard
        if not self.execute_sql_file(
            self.schema_dir / '03_dashboard_complete.sql',
            "Passo 1/3: Criando schema completo do dashboard"
        ):
            print("\n⚠️  Houve erros no schema. Continue mesmo assim? (s/n)")
            if input().lower() != 's':
                return False

        time.sleep(1)

        # Passo 2: Funções ETL
        if not self.execute_sql_file(
            self.schema_dir / '04_etl_function.sql',
            "Passo 2/3: Criando funções ETL"
        ):
            print("\n⚠️  Houve erros nas funções. Continue mesmo assim? (s/n)")
            if input().lower() != 's':
                return False

        time.sleep(1)

        # Passo 3: Popular dados
        print("\n" + "-"*60)
        if not self.run_etl():
            print("\n⚠️  ETL falhou. Verifique os dados.")
            return False

        # Verificação final
        print("\n" + "-"*60)
        success = self.verify_deployment()

        print("\n" + "="*60)
        if success:
            print("✅ DEPLOYMENT COMPLETO COM SUCESSO!")
            print("="*60)
            print("\n📚 Próximos passos:")
            print("1. Teste as queries no SQL Editor")
            print("2. Configure a API (ver API_QUERIES.md)")
            print("3. Implemente o frontend")
        else:
            print("⚠️  DEPLOYMENT CONCLUÍDO COM AVISOS")
            print("="*60)
            print("\nVerifique os erros acima e execute manualmente se necessário.")

        return success

    def close(self):
        """Fechar conexão"""
        if self.conn:
            self.conn.close()


def main():
    deployer = DatabaseDeployer()

    try:
        success = deployer.deploy()
        sys.exit(0 if success else 1)
    except KeyboardInterrupt:
        print("\n\n⚠️  Deploy cancelado pelo usuário")
        sys.exit(1)
    except Exception as e:
        print(f"\n❌ Erro fatal: {e}")
        sys.exit(1)
    finally:
        deployer.close()


if __name__ == '__main__':
    main()
