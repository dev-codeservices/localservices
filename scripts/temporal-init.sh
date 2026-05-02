#!/bin/sh
set -e

echo "Aguardando Temporal em ${TEMPORAL_CLI_ADDRESS}..."
until tctl cluster health 2>/dev/null | grep -q 'SERVING'; do
  sleep 2
done

for ns in $(echo "$TEMPORAL_NAMESPACES" | tr ',' ' '); do
  echo "Criando namespace '${ns}' (retention: ${TEMPORAL_RETENTION})..."
  tctl --ns "$ns" namespace register --retention "$TEMPORAL_RETENTION" 2>/dev/null || true
done

echo "Pronto."
