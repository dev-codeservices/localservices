#!/bin/bash
# Cria/atualiza usuários e bancos de dados no MySQL.
# Idempotente: usa CREATE DATABASE IF NOT EXISTS / CREATE USER IF NOT EXISTS.
#
# Variáveis de ambiente (definidas via docker-compose / .env):
#   MYSQL_ROOT_PASSWORD → senha do root (injetada pelo container)
#   MYSQL_APP_SERVICES  → serviços no formato: user||password||database
#                         Múltiplos serviços separados por ;
#
# Para adicionar um novo serviço:
#   1. Edite MYSQL_APP_SERVICES no .env
#   2. Execute: docker compose exec mysql /scripts/mysql-setup.sh
set -e

mysql_cmd() {
    mysql -uroot -p"$MYSQL_ROOT_PASSWORD" "$@"
}

# Extrai um campo de uma string separada por ||
field() {
    echo "$1" | awk -F'[|][|]' "{print \$$2}"
}

echo "==> Serviços de aplicação (MYSQL_APP_SERVICES)..."

# Formato: user||password||database  (múltiplos separados por ;)
IFS=';' read -ra SERVICES <<< "$MYSQL_APP_SERVICES"
for svc in "${SERVICES[@]}"; do
    [ -z "$svc" ] && continue

    user=$(field "$svc" 1)
    pass=$(field "$svc" 2)
    db=$(field "$svc" 3)
    db="${db:-$user}"
    [ -z "$user" ] && continue

    echo ""
    echo "  user='$user'  database='$db'"
    mysql_cmd <<SQL
CREATE DATABASE IF NOT EXISTS \`${db}\` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER IF NOT EXISTS '${user}'@'%' IDENTIFIED BY '${pass}';
ALTER USER '${user}'@'%' IDENTIFIED BY '${pass}';
REVOKE ALL PRIVILEGES ON *.* FROM '${user}'@'%';
GRANT ALL PRIVILEGES ON \`${db}\`.* TO '${user}'@'%';
FLUSH PRIVILEGES;
SQL
    echo "    OK: $user → $db"
done

echo ""
echo "==> Setup do MySQL concluído."
