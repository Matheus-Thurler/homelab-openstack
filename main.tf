# Define required providers
terraform {
  backend "local" {
    path = "./terraform.tfstate"
  }
  required_providers {
    openstack = {
      source = "terraform-provider-openstack/openstack"
      version = "3.3.2"
    }
  }
}
# Configure the OpenStack Provider
provider "openstack" {
  auth_url    = "http://192.168.68.103:5000/v3"  # ← CORRIGIDO: adicione /v3
  user_name   = "admin"                          # Usuário com permissões
  password    = "u3dsrYIZREdas44LfoYDpn4goXun4SAQPnQRpTLP"                # Senha do usuário admin
  tenant_name = "admin"                          # Projeto admin
  region      = "RegionOne"
  insecure    = true
                   # Importante para HTTP
    # cloud = "kolla-admin"
}

module "images" {
  source = "./modules/image-flavor"
}

module "keypair" {
  source = "./modules/key-pair"
}

module "network" {
  depends_on = [ module.images, module.keypair ]
  source = "./modules/network"
}

module "jenkins" {
  depends_on = [module.network]
  source = "./modules/jenkins"
  external_network_name = module.network.external_network_name
  internal_network_name = module.network.internal_network_name
  external_network_id = module.network.external_network_id
  internal_network_id = module.network.internal_network_id
  sg_default = module.network.sg_default
}

module "openvpn" {
  depends_on = [module.network]
  source = "./modules/openvpn"
  external_network_name = module.network.external_network_name
  internal_network_name = module.network.internal_network_name
  external_network_id = module.network.external_network_id
  internal_network_id = module.network.internal_network_id
  sg_default = module.network.sg_default
}
# module "kubernetes" {
#   source = "./modules/kubernetes"
#   internal_network_name = module.network.internal_network_name
# }