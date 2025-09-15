output "external_network_name" {
  value = openstack_networking_network_v2.external_network.name
}
output "internal_network_name" {
  value = openstack_networking_network_v2.internal_network.name
}
output "external_network_id" {
  value = openstack_networking_network_v2.external_network.id
}
output "internal_network_id" {
  value = openstack_networking_network_v2.internal_network.id
}

output "sg_default" {
  value = openstack_networking_secgroup_v2.sg_default.id
}