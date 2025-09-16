FROM jenkins/jenkins:latest

USER root

RUN apt-get update && \
    apt-get install -y sudo vim curl wget gnupg2 software-properties-common

RUN echo 'root:abc123' | chpasswd

RUN echo "jenkins ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# Add Docker's official GPG key and repo
RUN curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg && \
    echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/debian $(lsb_release -cs) stable" > /etc/apt/sources.list.d/docker.list

# Install Docker CLI
RUN apt-get update && \
    apt-get install -y docker-ce-cli

# Create docker group and add jenkins user
RUN groupadd docker && \
    usermod -aG docker jenkins

USER jenkins