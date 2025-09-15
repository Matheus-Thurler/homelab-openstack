#!/bin/bash

# Este script para a execução se qualquer comando falhar
set -e

echo "🚀 Iniciando a configuração do Jenkins com Docker..."

# -----------------------------------------------------------------------------
# PASSO 1: Instalar o Docker Engine e o Docker Compose
# -----------------------------------------------------------------------------
echo "🔧 Passo 1/3: Instalando o Docker..."

# Atualiza a lista de pacotes
sudo apt-get update

# Instala pacotes para permitir que o apt use um repositório sobre HTTPS
sudo apt-get install -y ca-certificates curl

# Adiciona a chave GPG oficial do Docker
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg

# Configura o repositório do Docker
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Atualiza a lista de pacotes novamente com o novo repositório
sudo apt-get update

# Instala a versão mais recente do Docker Engine e do Compose
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

echo "✅ Docker instalado com sucesso!"

# -----------------------------------------------------------------------------
# PASSO 2: Criar o Dockerfile para o Jenkins
# -----------------------------------------------------------------------------
echo "📄 Passo 2/3: Criando o Dockerfile..."

cat <<'EOF' > Dockerfile
# Usamos uma imagem LTS (Long-Term Support) para maior estabilidade
FROM jenkins/jenkins:lts-jdk17

# Troca para o usuário root para instalar pacotes
USER root

# Argumento para receber o GID do grupo Docker do host
ARG DOCKER_GID

# Cria um grupo 'docker' dentro do container com o mesmo GID do host
# Isso evita problemas de permissão ao acessar o socket do Docker
RUN groupadd -g $DOCKER_GID docker && usermod -aG docker jenkins

# Volta para o usuário jenkins
USER jenkins
EOF

echo "✅ Dockerfile criado com sucesso."

# -----------------------------------------------------------------------------
# PASSO 3: Criar o arquivo docker-compose.yml (versão moderna)
# -----------------------------------------------------------------------------
echo "⚙️ Passo 3/3: Criando o docker-compose.yml..."

# Pega o GID (Group ID) do grupo 'docker' no seu sistema host
if ! getent group docker > /dev/null; then
    sudo groupadd docker
    echo "Grupo 'docker' criado no host."
fi
DOCKER_GID=$(getent group docker | cut -d: -f3)

cat <<EOF > docker-compose.yml
# Não é mais necessário declarar a versão em composes modernos

services:
  jenkins:
    container_name: "jenkins"
    build:
      context: .
      args:
        - DOCKER_GID=${DOCKER_GID}
    environment:
      - DOCKER_HOST=tcp://docker:2376
      - DOCKER_CERT_PATH=/certs/client
      - DOCKER_TLS_VERIFY=1
    networks:
      - docker-network
    ports:
      - 80:8080
      - 50000:50000
    tty: true
    volumes:
      - jenkins-data:/var/jenkins_home
      - jenkins-docker-certs:/certs/client:ro

  dind:
    container_name: "docker-dind"
    environment:
      - DOCKER_TLS_CERTDIR=/certs
    image: docker:dind
    privileged: true
    restart: always
    networks:
      docker-network:
        aliases:
          - docker
    ports:
      - 2376:2376
    tty: true
    volumes:
      - jenkins-docker-certs:/certs/client
      - jenkins-data:/var/jenkins_home
      - docker-cache:/var/lib/docker

  minio:
    container_name: "minio"
    image: quay.io/minio/minio:RELEASE.2024-11-07T00-52-20Z
    command:
      - server
      - /data
      - --console-address
      - ":9001"
    ports:
      - 9000:9000
      - 9001:9001
    networks:
      docker-network:
        aliases:
          - minio
    volumes:
      - minio-data:/data
    environment:
      - MINIO_ROOT_USER=root
      - MINIO_ROOT_PASSWORD=rootroot
      - MINIO_DEFAULT_BUCKETS=root

volumes:
  docker-cache:
    name: docker-cache
  jenkins-data:
    name: jenkins-data
  jenkins-docker-certs:
    name: jenkins-docker-certs
  minio-data:
    name: minio-data

networks:
  docker-network:
    name: jenkins-network
    driver: bridge
    driver_opts:
      com.docker.network.driver.mtu: 1450
EOF

echo "✅ docker-compose.yml criado com sucesso."

# -----------------------------------------------------------------------------
# PASSO 4: Adicionar usuário ao grupo docker e iniciar os containers
# -----------------------------------------------------------------------------
echo "🔐 Adicionando usuário atual ao grupo docker..."

# Usa o usuário 'ubuntu' (padrão das imagens Ubuntu no cloud-init)
sudo usermod -aG docker ubuntu

# Configura variável de ambiente para o projeto Docker Compose
export COMPOSE_PROJECT_NAME=jenkins

echo "🐳 Iniciando os containers com Docker Compose..."
cd /home/ubuntu
sudo -E docker compose up -d --build

echo "⏳ Aguardando inicialização do Jenkins..."
sleep 30

# -----------------------------------------------------------------------------
# Conclusão
# -----------------------------------------------------------------------------
echo "🎉 Configuração concluída!"
echo ""
echo "Jenkins está disponível em: http://$(curl -s ifconfig.me):8080"
echo "Minio está disponível em: http://$(curl -s ifconfig.me):9000"
echo ""
echo "Para obter a senha inicial de administrador do Jenkins, execute:"
echo "sudo docker exec jenkins cat /var/jenkins_home/secrets/initialAdminPassword"
echo ""
echo "Credenciais do Minio:"
echo "Usuário: root"
echo "Senha: rootroot"

# Salva informações em um arquivo para referência futura
cat <<EOF > /home/ubuntu/deployment-info.txt
Jenkins URL: http://$(curl -s ifconfig.me):8080
Minio URL: http://$(curl -s ifconfig.me):9000
Minio Credentials: root/rootroot

Para obter a senha do Jenkins:
sudo docker exec jenkins cat /var/jenkins_home/secrets/initialAdminPassword

Para ver os logs do Jenkins:
sudo docker logs jenkins

Para reiniciar os containers:
sudo docker compose restart
EOF

echo "📋 Informações de deploy salvas em: /home/ubuntu/deployment-info.txt"