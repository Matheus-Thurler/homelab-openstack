resource "openstack_images_image_v2" "ubuntu_image" {
  name             = "Ubuntu 24.04"
  image_source_url = "https://cloud-images.ubuntu.com/noble/current/noble-server-cloudimg-amd64.img"
  container_format = "bare"
  disk_format      = "qcow2"
}

