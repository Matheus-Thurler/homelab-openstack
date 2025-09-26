# Versão atualizada do Kubespray
FROM quay.io/kubespray/kubespray:v2.28.0

# A imagem base continua sendo Ubuntu, então o 'apt-get' ainda funciona.
# Instala o OpenVPN e o 'iproute2' (para o comando 'ip')
USER root
RUN apt-get update && apt-get install -y --no-install-recommends \
    openvpn \
    iproute2 \
    && rm -rf /var/lib/apt/lists/*