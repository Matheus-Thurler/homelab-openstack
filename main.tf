terraform {
  required_providers {
    openstack = {
      source = "terraform-provider-openstack/openstack"
      version = "3.3.2"
    }
  }
  backend "s3" {
    bucket = "homelab-tfstate"
    key    = "terraform.tfstate"
    region = "placeholder"

    endpoints = {
      s3 = "http://192.168.68.110:9000"
    }
    skip_credentials_validation = true
    skip_metadata_api_check     = true
    skip_region_validation      = true
    skip_requesting_account_id  = true
    use_path_style              = true
  }
}
# Configure the OpenStack Provider
provider "openstack" {
  # auth_url    = "http://192.168.68.103:5000/v3"  # ← CORRIGIDO: adicione /v3
  # user_name   = "admin"                          # Usuário com permissões
  # password    = "u3dsrYIZREdas44LfoYDpn4goXun4SAQPnQRpTLP"                # Senha do usuário admin
  # tenant_name = "admin"                          # Projeto admin
  # region      = "RegionOne"
  # insecure    = true
                   # Importante para HTTP
    cloud = "kolla-admin"
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

module "openvpn" {
  depends_on = [module.network]
  source = "./modules/openvpn"
  external_network_name = module.network.external_network_name
  internal_network_name = module.network.internal_network_name
  external_network_id = module.network.external_network_id
  internal_network_id = module.network.internal_network_id
  sg_default = module.network.sg_default
}

module "kubernetes" {
  depends_on = [module.network, module.openvpn]
  source = "./modules/kubernetes"
  internal_network_id = module.network.internal_network_id
  sg_default = module.network.sg_default
}