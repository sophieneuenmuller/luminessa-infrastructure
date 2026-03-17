#!/bin/bash
set -euo pipefail

DUMP_DIR="/backup/dumps"
mkdir -p "$DUMP_DIR"

echo "Dumpeando PostgreSQL (vía red)..."

# Set password for pg_dumpall
export PGPASSWORD="$POSTGRES_PASSWORD"

# Run dump over network (host is 'postgres' in the database network)
pg_dumpall -h postgres -U "$POSTGRES_USER" > "$DUMP_DIR/all_databases.sql"

# Clean up password
unset PGPASSWORD

echo "Dump completado: $(du -sh "$DUMP_DIR/all_databases.sql")"
