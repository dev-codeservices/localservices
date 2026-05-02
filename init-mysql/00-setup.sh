#!/bin/bash
# Ponto de entrada do init do MySQL — executado uma vez na criação do volume.
# Toda a lógica fica em /scripts/mysql-setup.sh para permitir re-execução manual.
exec /scripts/mysql-setup.sh
