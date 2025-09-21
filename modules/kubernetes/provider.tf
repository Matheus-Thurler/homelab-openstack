terraform {
  backend "s3" {
    bucket = "homelab-tfstate"
    key    = "terraform.tfstate"
    region = "placeholder"

    endpoints = {
      s3 = "http://192.168.68.120:9000"
    }
    skip_credentials_validation = true
    skip_metadata_api_check     = true
    skip_region_validation      = true
    skip_requesting_account_id  = true
    use_path_style              = true
  }
  required_providers {
    openstack = {
      source = "terraform-provider-openstack/openstack"
      version = "3.3.2"
    }
  }
}