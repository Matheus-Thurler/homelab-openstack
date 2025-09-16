#!/bin/bash
apt-get update
wget -O openvpn.sh https://get.vpnsetup.net/ovpn

FLOATING_IP=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4 || echo "NULL")
echo $FLOATING_IP >> /etc/environment

# Executar o script OpenVPN em segundo plano e aguardar
sudo bash openvpn.sh --listenaddr $FLOATING_IP --serveraddr $FLOATING_IP --auto &

# Aguardar a geração do client.ovpn
timeout=120
while [ ! -f /root/client.ovpn ] && [ $timeout -gt 0 ]; do
    sleep 5
    timeout=$((timeout - 5))
    echo "Aguardando geração do client.ovpn..."
done

if [ -f /root/client.ovpn ]; then
    sudo cp /root/client.ovpn /home/ubuntu/client.ovpn
    sudo chown ubuntu:ubuntu /home/ubuntu/client.ovpn
    sudo touch /home/ubuntu/ovpn_ready  # Criar um arquivo de flag
    echo "Arquivo client.ovpn copiado com sucesso!"
else
    echo "Erro: client.ovpn não foi gerado após 120 segundos."
    exit 1
fi