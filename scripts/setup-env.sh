#!/bin/bash
# Combina os arquivos de env individuais em um único .env na raiz do projeto.
# Se um envs/<serviço>.env não existir, cria a partir do .example correspondente.
#
# Uso:
#   ./scripts/setup-env.sh
set -e

cd "$(dirname "$0")/.."

SERVICES=(postgresql redis temporal mysql)

echo "==> Verificando arquivos de env..."
for svc in "${SERVICES[@]}"; do
    env_file="envs/${svc}.env"
    example_file="${env_file}.example"
    if [ ! -f "$env_file" ]; then
        if [ ! -f "$example_file" ]; then
            echo "ERRO: $example_file não encontrado." >&2
            exit 1
        fi
        cp "$example_file" "$env_file"
        echo "    Criado: $env_file  (a partir do .example — edite conforme necessário)"
    else
        echo "    OK: $env_file"
    fi
done

echo ""
echo "==> Gerando .env..."
{
    for svc in "${SERVICES[@]}"; do
        cat "envs/${svc}.env"
        echo ""
    done
} > .env

echo "    .env gerado com sucesso."
echo ""
echo "Próximo passo: docker compose up -d"
