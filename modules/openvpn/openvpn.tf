resource "openstack_compute_instance_v2" "openvpn" {

  name            = "openvpn"
  image_name      = "Ubuntu 24.04"
  flavor_name     = "m1.medium"
  security_groups = [var.sg_default]
  key_pair        = "matheus"
  network {
    uuid = var.internal_network_id
  }

  user_data = <<-EOF
              #!/bin/bash
              apt-get update
              wget -O openvpn.sh https://get.vpnsetup.net/ovpn
              EOF
}

data "openstack_networking_port_v2" "instance_port" {
  depends_on = [openstack_compute_instance_v2.openvpn]
  network_id = var.internal_network_id
  device_id  = openstack_compute_instance_v2.openvpn.id
}

# Associação correta do floating IP
resource "openstack_networking_floatingip_associate_v2" "openvpn_ip" {
  depends_on = [
    openstack_compute_instance_v2.openvpn,
    data.openstack_networking_port_v2.instance_port,
    openstack_networking_floatingip_v2.openvpn_ip
  ]
  floating_ip = openstack_networking_floatingip_v2.openvpn_ip.address  # ← .address
  port_id     = data.openstack_networking_port_v2.instance_port.id       # ← port do data source
}
