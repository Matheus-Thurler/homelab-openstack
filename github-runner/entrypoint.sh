#!/bin/bash
set -e



echo "Removendo o runner..."

./config.sh remove --unattended --token "${RUNNER_TOKEN}"


./config.sh --url ${RUNNER_URL} --work "_work" --unattended --replace --labels "ubuntu,docker" --name ${RUNNER_NAME} --token ${RUNNER_TOKEN}

# Inicia o runner e mantém o container em execução
./run.sh