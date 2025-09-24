resource "openstack_compute_keypair_v2" "test-keypair" {
  name       = "matheus"
  public_key = file("id_rsa.pub")
}