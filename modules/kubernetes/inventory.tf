resource "local_file" "ansible_inventory" {
  depends_on = [openstack_compute_instance_v2.master_k8s, openstack_compute_instance_v2.workers_k8s]
  content = templatefile("${path.module}/inventory.tmpl",
    {
      master = {
        index      = range(length(openstack_compute_instance_v2.master_k8s))
        ip_address = openstack_compute_instance_v2.master_k8s[*].access_ip_v4
        user       = [for i in range(length(openstack_compute_instance_v2.master_k8s)) : "ubuntu"]
        vm_name    = openstack_compute_instance_v2.master_k8s[*].name
      }
      worker = {
        index      = range(length(openstack_compute_instance_v2.workers_k8s))
        ip_address = openstack_compute_instance_v2.workers_k8s[*].access_ip_v4
        user       = [for i in range(length(openstack_compute_instance_v2.workers_k8s)) : "ubuntu"]
        vm_name    = openstack_compute_instance_v2.workers_k8s[*].name
      }
    }
  )
  filename        = "inventory.ini"
  file_permission = "0600"
}