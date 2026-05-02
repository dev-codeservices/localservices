#!/bin/bash
# Ponto de entrada do init do PostgreSQL — executado uma vez na criação do volume.
# Toda a lógica fica em /scripts/pg-setup.sh para permitir re-execução manual.
exec /scripts/pg-setup.sh
