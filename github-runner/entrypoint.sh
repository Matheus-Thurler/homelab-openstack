#!/bin/bash
set -e


./config.sh --url ${RUNNER_URL} --labels "ubuntu,docker" --name ${GITHUB_REPO} --token ${RUNNER_TOKEN}

# Inicia o runner e mantém o container em execução
./run.sh