output "openvpn_ip" {
  value = openstack_networking_floatingip_v2.openvpn_ip.address
}