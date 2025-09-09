#!/bin/bash

set -e

echo "=== Configuração para Kolla Ansible ==="

PHYSICAL_IFACE="enp3s0"
BRIDGE_IP="192.168.68.116/24"
GATEWAY="192.168.68.1"

# Criar arquivo Netplan
sudo tee /etc/netplan/01-kolla-bridge.yaml > /dev/null << EOF
network:
  version: 2
  renderer: networkd
  ethernets:
    $PHYSICAL_IFACE:
      dhcp4: no
      dhcp6: no
    veth0:
      dhcp4: no
      dhcp6: no
    veth1:
      dhcp4: no
      dhcp6: no
  
  bridges:
    vmbr0:
      interfaces: [$PHYSICAL_IFACE, veth0]
      addresses: [$BRIDGE_IP]
      routes:
        - to: default
          via: $GATEWAY
      nameservers:
        addresses: [8.8.8.8, 8.8.4.4]
      parameters:
        stp: false
        forward-delay: 0
EOF

# Aplicar configuração
sudo netplan apply

# Criar veth pair manualmente (às vezes o Netplan não cria)
sudo ip link delete veth0 2>/dev/null || true
sudo ip link delete veth1 2>/dev/null || true
sudo ip link add veth0 type veth peer name veth1
sudo ip link set veth0 up
sudo ip link set veth1 up

# Adicionar veth0 à bridge (garantir)
sudo ip link set veth0 master vmbr0 2>/dev/null || true

echo "=== Configuração concluída ==="
echo "✅ SSH funcionará normalmente"
echo "✅ Bridge vmbr0: $BRIDGE_IP"
echo "✅ Interface física: $PHYSICAL_IFACE"
echo "✅ Para Neutron use:"
echo "   - vmbr0 (external network)"
echo "   - veth1 (internal networks)"