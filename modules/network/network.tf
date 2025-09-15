
# networks.tf
resource "openstack_networking_network_v2" "external_network" {
  name           = "external-network"
  admin_state_up = "true"
  external       = "true"
  segments {
    physical_network = "physnet1"
    network_type     = "flat"
  }
}

resource "openstack_networking_subnet_v2" "external_subnet" {
  name            = "external-subnet"
  network_id      = openstack_networking_network_v2.external_network.id
  cidr            = "192.168.68.0/24"
  ip_version      = 4
  gateway_ip      = "192.168.68.1"  # Altere conforme seu gateway
  enable_dhcp     = false
  allocation_pool {
    start = "192.168.68.120"
    end   = "192.168.68.140"
  }
  dns_nameservers = ["8.8.8.8", "8.8.4.4"]
}



# internal_network.tf
resource "openstack_networking_network_v2" "internal_network" {
  name           = "internal-network"
  admin_state_up = "true"
}

resource "openstack_networking_subnet_v2" "internal_subnet" {
  name            = "internal-subnet"
  network_id      = openstack_networking_network_v2.internal_network.id
  cidr            = "10.0.0.0/24"
  ip_version      = 4
  dns_nameservers = ["8.8.8.8", "8.8.4.4"]
  enable_dhcp     = true
}

resource "openstack_networking_router_v2" "router" {
  name                = "main-router"
  admin_state_up      = true
  external_network_id = openstack_networking_network_v2.external_network.id
}

resource "openstack_networking_router_interface_v2" "router_interface" {
  router_id = openstack_networking_router_v2.router.id
  subnet_id = openstack_networking_subnet_v2.internal_subnet.id
}