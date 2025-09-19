#!/bin/bash
set -e

# Validação das variáveis necessárias
required_vars=("RUNNER_URL" "RUNNER_TOKEN" "GITHUB_PAT" "GITHUB_OWNER" "RUNNER_NAME")
for var in "${required_vars[@]}"; do
    if [ -z "${!var}" ]; then
        echo "Erro: A variável de ambiente $var deve ser definida."
        exit 1
    fi
done

# --- FUNÇÃO DE VALIDAÇÃO DO PAT ---
validate_pat() {
    echo "[Validação] Verificando a validade do GITHUB_PAT..."
    local http_code=$(curl -s -o /dev/null -w "%{http_code}" \
        -H "Accept: application/vnd.github+json" \
        -H "Authorization: Bearer ${GITHUB_PAT}" \
        -H "X-GitHub-Api-Version: 2022-11-28" \
        "https://api.github.com/user")

    if [ "$http_code" -ne 200 ]; then
        echo "=========================================================================="
        echo " ERRO DE AUTENTICAÇÃO GRAVE (Código HTTP: $http_code)"
        echo "=========================================================================="
        echo " O GITHUB_PAT fornecido é INVÁLIDO ou não tem as permissões corretas."
        exit 1
    else
        echo "[Validação] GITHUB_PAT verificado com sucesso."
    fi
}

# --- FUNÇÃO PARA REMOVER RUNNERS ANTIGOS ---
remove_old_runners() {
    echo "[Limpeza] Removendo runners antigos..."
    
    local api_url="https://api.github.com/repos/${GITHUB_OWNER}/${GITHUB_REPO}/actions/runners"
    
    # Obter lista de runners
    local response=$(curl -s -w "\nHTTP_CODE:%{http_code}" \
        -H "Accept: application/vnd.github+json" \
        -H "Authorization: Bearer ${GITHUB_PAT}" \
        -H "X-GitHub-Api-Version: 2022-11-28" \
        "$api_url")
    
    local http_code=$(echo "$response" | grep "HTTP_CODE:" | cut -d':' -f2)
    local body=$(echo "$response" | sed '$d')
    
    if [ "$http_code" -ne 200 ]; then
        echo "[AVISO] Não foi possível obter lista de runners (HTTP $http_code)"
        return 1
    fi
    
    # Extrair runners
    local runners=$(echo "$body" | jq -r '.runners[] | {id, name} | @base64')
    
    if [ -z "$runners" ]; then
        echo "[Limpeza] Nenhum runner encontrado para remover."
        return 0
    fi
    
    local count=0
    for runner_base64 in $runners; do
        local runner=$(echo "$runner_base64" | base64 --decode)
        local runner_id=$(echo "$runner" | jq -r '.id')
        local runner_name=$(echo "$runner" | jq -r '.name')
        
        echo "[Limpeza] Removendo runner: $runner_name (ID: $runner_id)"
        
        # Remover runner via API
        local delete_response=$(curl -s -w "\nHTTP_CODE:%{http_code}" \
            -X DELETE \
            -H "Accept: application/vnd.github+json" \
            -H "Authorization: Bearer ${GITHUB_PAT}" \
            -H "X-GitHub-Api-Version: 2022-11-28" \
            "${api_url}/${runner_id}")
        
        local delete_code=$(echo "$delete_response" | grep "HTTP_CODE:" | cut -d':' -f2)
        
        if [ "$delete_code" -eq 204 ]; then
            echo "[✓] Runner $runner_name removido com sucesso!"
            count=$((count + 1))
        else
            echo "[✗] Falha ao remover runner $runner_name (Código: $delete_code)"
        fi
        
        sleep 1
    done
    
    echo "[Limpeza] Total de runners removidos: $count"
    return 0
}

# --- FUNÇÃO DE REGISTRO SIMPLES ---
register_runner_simple() {
    echo "[Registro] Registrando novo runner..."
    
    # Gerar nome único
    local runner_name="${RUNNER_NAME}-$(date +%Y%m%d-%H%M%S)"
    
    echo "[Registro] Nome: $runner_name"
    echo "[Registro] URL: ${RUNNER_URL}"
    
    # Configuração automática usando --unattended (funciona melhor)
    ./config.sh --url "${RUNNER_URL}" \
                --token "${RUNNER_TOKEN}" \
                --name "$runner_name" \
                --work "_work" \
                --labels "ubuntu,docker" \
                --unattended \
                --replace
    
    return $?
}

# --- EXECUÇÃO PRINCIPAL ---
echo "================================================"
echo " INICIANDO SETUP DO RUNNER"
echo "================================================"

# Validar PAT
validate_pat

# Corrigir permissões
sudo chown -R runner:runner /home/runner/_work 2>/dev/null || true

# Remover runners antigos
remove_old_runners

# Limpar configurações locais
echo "[Limpeza] Limpando configurações locais..."
rm -f .runner .credentials .credentials_rsaparams 2>/dev/null || true

# Registrar novo runner
echo "[Registro] Iniciando registro..."
register_runner_simple

if [ $? -ne 0 ]; then
    echo "[ERRO] Falha no registro do runner"
    exit 1
fi

echo "[✓] Runner registrado com sucesso!"
echo "[Início] Iniciando o runner..."

# Executar o runner diretamente
exec ./run.sh "$@"