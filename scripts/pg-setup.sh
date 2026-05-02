#!/bin/bash
# Cria/atualiza usuários e schemas no PostgreSQL.
# Idempotente: seguro rodar múltiplas vezes.
#
# Variáveis de ambiente (definidas via docker-compose / .env):
#   POSTGRES_USER        → superusuário admin (injetado pelo container)
#   PG_APP_DB            → banco compartilhado de aplicações
#   PG_TEMPORAL_USER     → usuário do Temporal (precisa de CREATEDB)
#   PG_TEMPORAL_PASSWORD → senha do Temporal
#   PG_APP_SERVICES      → serviços no formato: user||password||schema
#                          Múltiplos serviços separados por ;
#
# Para adicionar um novo serviço:
#   1. Edite PG_APP_SERVICES no .env
#   2. Execute: docker compose exec postgresql /scripts/pg-setup.sh
set -e

sql() {
    psql -v ON_ERROR_STOP=1 -U "$POSTGRES_USER" -d "$1" -c "$2"
}

# Extrai um campo de uma string separada por ||
# Uso: field "$svc" <1|2|3>
field() {
    echo "$1" | awk -F'[|][|]' "{print \$$2}"
}

ensure_user() {
    local user="$1"
    local pass="${2//\'/\'\'}"   # escapa aspas simples para SQL
    local extra="${3:-}"
    local exists
    exists=$(psql -tAc "SELECT 1 FROM pg_roles WHERE rolname = '$user'" \
        -U "$POSTGRES_USER" -d "$POSTGRES_DB")
    if [ -z "$exists" ]; then
        sql "$POSTGRES_DB" "CREATE USER \"$user\" WITH PASSWORD '$pass' $extra;"
        echo "    + Criado:     $user"
    else
        sql "$POSTGRES_DB" "ALTER USER \"$user\" WITH PASSWORD '$pass';"
        echo "    ~ Atualizado: $user"
    fi
}

# ── Banco compartilhado ────────────────────────────────────────────────────────
echo "==> Banco compartilhado: '$PG_APP_DB'"
exists=$(psql -tAc "SELECT 1 FROM pg_database WHERE datname = '$PG_APP_DB'" \
    -U "$POSTGRES_USER" -d "$POSTGRES_DB")
if [ -z "$exists" ]; then
    sql "$POSTGRES_DB" "CREATE DATABASE \"$PG_APP_DB\";"
    echo "    + Criado."
fi
sql "$POSTGRES_DB" "REVOKE ALL ON DATABASE \"$PG_APP_DB\" FROM PUBLIC;"

# ── Temporal ───────────────────────────────────────────────────────────────────
echo ""
echo "==> Temporal: '$PG_TEMPORAL_USER'"
# CREATEDB obrigatório: o auto-setup cria 'temporal_visibility' e roda as migrations
ensure_user "$PG_TEMPORAL_USER" "$PG_TEMPORAL_PASSWORD" "CREATEDB"

# O temporalio/auto-setup tenta conectar ao banco 'temporal' antes de criá-lo.
# Pré-criamos aqui para que a conexão inicial funcione; o auto-setup gerencia o schema.
exists=$(psql -tAc "SELECT 1 FROM pg_database WHERE datname = 'temporal'" \
    -U "$POSTGRES_USER" -d "$POSTGRES_DB")
if [ -z "$exists" ]; then
    sql "$POSTGRES_DB" "CREATE DATABASE temporal OWNER \"$PG_TEMPORAL_USER\";"
    echo "    + Banco 'temporal' pré-criado para o auto-setup."
fi

# ── Serviços de aplicação ──────────────────────────────────────────────────────
# Formato: user||password||schema  (múltiplos separados por ;)
# O schema é opcional — se omitido, usa o nome do usuário.
echo ""
echo "==> Serviços de aplicação (PG_APP_SERVICES)..."

IFS=';' read -ra SERVICES <<< "$PG_APP_SERVICES"
for svc in "${SERVICES[@]}"; do
    [ -z "$svc" ] && continue

    user=$(field "$svc" 1)
    pass=$(field "$svc" 2)
    schema=$(field "$svc" 3)
    schema="${schema:-$user}"
    [ -z "$user" ] && continue

    echo ""
    echo "  user='$user'  schema='$schema'"
    ensure_user "$user" "$pass"
    sql "$POSTGRES_DB" "GRANT CONNECT ON DATABASE \"$PG_APP_DB\" TO \"$user\";"
    sql "$PG_APP_DB"   "CREATE SCHEMA IF NOT EXISTS \"$schema\" AUTHORIZATION \"$user\";"
    sql "$PG_APP_DB"   "REVOKE ALL ON SCHEMA \"$schema\" FROM PUBLIC;"
    # search_path restrito ao schema do serviço — evita acesso acidental a outros schemas
    sql "$POSTGRES_DB" \
        "ALTER ROLE \"$user\" IN DATABASE \"$PG_APP_DB\" SET search_path = \"$schema\";"
done

echo ""
echo "==> Setup do PostgreSQL concluído."
