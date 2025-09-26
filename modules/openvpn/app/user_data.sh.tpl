#!/bin/bash
apt-get update
wget -O openvpn.sh https://get.vpnsetup.net/ovpn

FLOATING_IP=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4 || echo "NULL")
echo $FLOATING_IP >> /etc/environment

# Executar o script OpenVPN em segundo plano e aguardar
sudo bash openvpn.sh --auto &

# Aguardar a geração do client.ovpn
timeout=120
while [ ! -f /root/client.ovpn ] && [ $timeout -gt 0 ]; do
    sleep 5
    timeout=$((timeout - 5))
    echo "Aguardando geração do client.ovpn..."
done

if [ -f /root/client.ovpn ]; then
    # CORREÇÃO: Substituir o IP do remote pelo FLOATING_IP
    sudo sed -i "s/remote [0-9]\+\.[0-9]\+\.[0-9]\+\.[0-9]\+/remote $FLOATING_IP/" /root/client.ovpn
    
    sudo cp /root/client.ovpn /home/ubuntu/client.ovpn
    sudo chown ubuntu:ubuntu /home/ubuntu/client.ovpn
    sudo touch /home/ubuntu/ovpn_ready
    
    # Verificar se a substituição funcionou
    echo "Configuração remote no client.ovpn:"
    grep "remote" /home/ubuntu/client.ovpn
    echo "Arquivo client.ovpn corrigido e copiado com sucesso!"
else
    echo "Erro: client.ovpn não foi gerado após 120 segundos."
    exit 1
fi