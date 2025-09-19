# Use uma imagem base do Ubuntu LTS (Long-Term Support)
FROM ubuntu:22.04

# Evita prompts interativos durante a instalação de pacotes
ENV DEBIAN_FRONTEND=noninteractive

# Instala dependências básicas e para o Docker
RUN apt-get update && apt-get install -y \
    bash \
    curl \
    git \
    jq \
    openssh-client \
    python3 \
    python3-pip \
    sudo \
    ca-certificates \
    gnupg \
    expect

# Adiciona o repositório oficial do Docker
RUN install -m 0755 -d /etc/apt/keyrings
RUN curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
RUN chmod a+r /etc/apt/keyrings/docker.gpg
RUN echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  tee /etc/apt/sources.list.d/docker.list > /dev/null

# Instala o Docker Engine e o Docker Compose
RUN apt-get update && apt-get install -y \
    docker-ce \
    docker-ce-cli \
    containerd.io \
    docker-buildx-plugin \
    docker-compose-plugin

# Cria o usuário e grupo para o runner
# O usuário 'runner' terá o ID 1001. Se necessário, ajuste.
RUN useradd -m -s /bin/bash runner && \
    usermod -aG sudo runner && \
    usermod -aG docker runner && \
    echo "runner ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# Muda para o usuário runner
USER runner
WORKDIR /home/runner

ARG RUNNER_VERSION="2.328.0"
RUN curl -o actions-runner.tar.gz -L "https://github.com/actions/runner/releases/download/v${RUNNER_VERSION}/actions-runner-linux-x64-${RUNNER_VERSION}.tar.gz" && \
    tar xzf ./actions-runner.tar.gz && \
    rm ./actions-runner.tar.gz

COPY --chown=runner:runner entrypoint.sh .

RUN chmod +x entrypoint.sh

ENTRYPOINT ["./entrypoint.sh"]

