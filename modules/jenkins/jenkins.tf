resource "openstack_compute_instance_v2" "jenkins" {
  name            = "jenkins"
  image_name      = "Ubuntu 24.04"  # Mudei para 22.04 que é mais estável
  flavor_name     = "m1.medium"     # Aumentei os recursos
  security_groups = [var.sg_default]
  key_pair = "matheus"

  network {
    uuid = var.internal_network_id
  }

  user_data = file("${path.module}/app/jenkins.sh")
}



# data "openstack_networking_port_v2" "instance_port" {

#   depends_on = [openstack_compute_instance_v2.web_server]
  
#   network_id = openstack_networking_network_v2.internal_network.id
#   device_id  = openstack_compute_instance_v2.web_server.id
# }

# # Associação correta do floating IP
# resource "openstack_networking_floatingip_associate_v2" "web_server_ip" {
#   depends_on = [
#     openstack_compute_instance_v2.web_server,
#     data.openstack_networking_port_v2.instance_port,
#     openstack_networking_floatingip_v2.web_server_ip
#   ]
#
#   floating_ip = openstack_networking_floatingip_v2.web_server_ip.address  # ← .address
#   port_id     = openstack_compute_instance_v2.web_server.network[0].port        # ← port do data source
# }
