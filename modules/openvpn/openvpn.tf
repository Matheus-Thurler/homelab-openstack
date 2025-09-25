# Criar a instância sem depender do Floating IP no user_data
resource "openstack_compute_instance_v2" "openvpn" {
  name            = "openvpn"
  image_name      = "Ubuntu 24.04"
  flavor_name     = "m1.medium"
  security_groups = [var.sg_default]
  key_pair        = "matheus"
  network {
    uuid = var.internal_network_id
  }

  # Remover a referência ao Floating IP. Usar metadados ou IP fixo.
  user_data = templatefile("${path.module}/app/user_data.sh.tpl", {
    # Passar um placeholder ou o IP fixo (que pode ser obtido via metadados)
    floating_ip = "NULL"  # Será substituído posteriormente
  })
  lifecycle {
    ignore_changes = [ security_groups ]
  }
}

# Obter a porta da instância
data "openstack_networking_port_v2" "instance_port" {
  network_id = var.internal_network_id
  device_id  = openstack_compute_instance_v2.openvpn.id
}

# Associar o Floating IP à instância
resource "openstack_networking_floatingip_associate_v2" "openvpn_ip" {
  floating_ip = openstack_networking_floatingip_v2.openvpn_ip.address
  port_id     = data.openstack_networking_port_v2.instance_port.id
}


# 

# resource "null_resource" "download_ovpn" {
#   depends_on = [
#     openstack_networking_floatingip_associate_v2.openvpn_ip
#   ]

#   triggers = {
#     instance_ip = openstack_networking_floatingip_v2.openvpn_ip.address
#   }

#   provisioner "local-exec" {
#     command = <<-EOT
#       echo "Aguardando a instância em ${self.triggers.instance_ip} ficar pronta..."

#       # Espera o cloud-init terminar (usando 'sh' e o caminho relativo para a chave)
#       timeout 300 sh -c '
#         while ! ssh -i ./id_rsa -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o ConnectTimeout=10 ubuntu@${self.triggers.instance_ip} "sudo cloud-init status --wait"; do
#           echo "Aguardando cloud-init finalizar..."
#           sleep 10
#         done
#       '
      
#       echo "Instância pronta. Baixando client.ovpn..."
      
#       # Baixa o arquivo (usando o caminho relativo para a chave)
#       set -e 
#       scp -i ./id_rsa -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o ConnectTimeout=10 \
#         ubuntu@${self.triggers.instance_ip}:/home/ubuntu/client.ovpn \
#         ./client.ovpn
        
#       echo "Download concluído com sucesso!"
#     EOT
#   }
# }