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



# resource "null_resource" "download_ovpn" {
#   depends_on = [
#     openstack_compute_instance_v2.openvpn,
#     openstack_networking_floatingip_associate_v2.openvpn_ip  # Garante que o IP está associado
#   ]
#   provisioner "local-exec" {
#     command = <<-EOT
#       if [ ! -f "./client.ovpn" ]; then
#         scp -i ~/.ssh/id_rsa -o StrictHostKeyChecking=no ubuntu@${openstack_networking_floatingip_v2.openvpn_ip.address}:/home/ubuntu/client.ovpn ./client.ovpn
#       else
#         echo "Arquivo client.ovpn já existe localmente. Pulando download."
#       fi
#     EOT
#   }
 
# }
resource "null_resource" "download_ovpn" {
  depends_on = [
    openstack_compute_instance_v2.openvpn,
    openstack_networking_floatingip_associate_v2.openvpn_ip
  ]

  provisioner "local-exec" {
    command = <<-EOT
      # Aguardar o cloud-init completar
      echo "Aguardando instância ficar pronta..."
      timeout 300 bash -c '
        while ! ssh -i ~/.ssh/id_rsa -o StrictHostKeyChecking=no -o ConnectTimeout=5 \
          ubuntu@${openstack_networking_floatingip_v2.openvpn_ip.address} \
          "sudo cloud-init status --wait" 2>/dev/null; do
          sleep 10
          echo "Aguardando cloud-init completar..."
        done
      '
      
      # Agora tentar o SCP
      if [ ! -f "./client.ovpn" ]; then
        echo "Baixando arquivo client.ovpn..."
        scp -i ~/.ssh/id_rsa -o StrictHostKeyChecking=no \
          ubuntu@${openstack_networking_floatingip_v2.openvpn_ip.address}:/home/ubuntu/client.ovpn \
          ./client.ovpn
        echo "Download completo!"
      else
        echo "Arquivo client.ovpn já existe localmente. Pulando download."
      fi
    EOT
  }
}