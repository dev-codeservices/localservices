#!/bin/bash
# Cria/atualiza usuários e bancos de dados no PostgreSQL.
# Idempotente: seguro rodar múltiplas vezes.
#
# Variáveis de ambiente (definidas via docker-compose / .env):
#   POSTGRES_USER        → superusuário admin (injetado pelo container)
#   PG_TEMPORAL_USER     → usuário do Temporal (precisa de CREATEDB)
#   PG_TEMPORAL_PASSWORD → senha do Temporal
#   PG_APP_SERVICES      → serviços no formato: user||password||database
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

# ── Temporal ───────────────────────────────────────────────────────────────────
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
# Formato: user||password||database  (múltiplos separados por ;)
# O database é opcional — se omitido, usa o nome do usuário.
echo ""
echo "==> Serviços de aplicação (PG_APP_SERVICES)..."

IFS=';' read -ra SERVICES <<< "$PG_APP_SERVICES"
for svc in "${SERVICES[@]}"; do
    [ -z "$svc" ] && continue

    user=$(field "$svc" 1)
    pass=$(field "$svc" 2)
    db=$(field "$svc" 3)
    db="${db:-$user}"
    [ -z "$user" ] && continue

    echo ""
    echo "  user='$user'  database='$db'"
    ensure_user "$user" "$pass"

    exists=$(psql -tAc "SELECT 1 FROM pg_database WHERE datname = '$db'" \
        -U "$POSTGRES_USER" -d "$POSTGRES_DB")
    if [ -z "$exists" ]; then
        sql "$POSTGRES_DB" "CREATE DATABASE \"$db\" OWNER \"$user\";"
        echo "    + Banco criado: $db"
    else
        sql "$POSTGRES_DB" "ALTER DATABASE \"$db\" OWNER TO \"$user\";"
        echo "    ~ Banco existe: $db"
    fi
    sql "$POSTGRES_DB" "REVOKE ALL ON DATABASE \"$db\" FROM PUBLIC;"
done

echo ""
echo "==> Setup do PostgreSQL concluído."
