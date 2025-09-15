resource "openstack_containerinfra_clustertemplate_v1" "clustertemplate_1" {
  name                  = "clustertemplate_1"
  image                 = "Fedora CoreOS 42"
  coe                   = "kubernetes"
  flavor                = "m1.small"
  master_flavor         = "m1.medium"
  dns_nameserver        = "1.1.1.1"
  docker_storage_driver = "devicemapper"
  docker_volume_size    = 10
  volume_driver         = "cinder"
  network_driver        = "flannel"
  server_type           = "vm"
  master_lb_enabled     = true
  floating_ip_enabled   = false
  fixed_network = var.internal_network_name
  cluster_distro = "fedora-coreos"
}