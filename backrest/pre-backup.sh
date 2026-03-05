#!/bin/bash
set -euo pipefail

DUMP_DIR="/backup/dumps"
mkdir -p "$DUMP_DIR"

echo "Dumpeando PostgreSQL..."
docker exec postgres pg_dumpall -U admin > "$DUMP_DIR/all_databases.sql"

echo "Dump completado: $(du -sh "$DUMP_DIR/all_databases.sql")"
