resource "openstack_compute_instance_v2" "master_k8s" {
  name            = "master-k8s"
  image_name      = "Ubuntu 24.04"  # Mudei para 22.04 que é mais estável
  flavor_name     = "m1.medium"     # Aumentei os recursos
  security_groups = [var.sg_default]
  key_pair = "matheus"
  count = 1

  network {
    uuid = var.internal_network_id
  }
}

resource "openstack_compute_instance_v2" "workers_k8s" {
  name            = "workers-k8s-${count.index + 1}"
  image_name      = "Ubuntu 24.04"  # Mudei para 22.04 que é mais estável
  flavor_name     = "m1.medium"     # Aumentei os recursos
  security_groups = [var.sg_default]
  key_pair = "matheus"
  count = 2
  network {
    uuid = var.internal_network_id
  }
}

