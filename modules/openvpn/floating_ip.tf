
# floating_ip.tf
resource "openstack_networking_floatingip_v2" "openvpn_ip" {
  depends_on = [ openstack_compute_instance_v2.openvpn ]
  pool = var.external_network_name
}