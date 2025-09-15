# Define um mapa local com as especificações de cada flavor.
# Isso substitui o array associativo do seu script Bash.
locals {
  flavors = {
    "m1.tiny" = {
      vcpus     = 1
      ram       = 512
      disk      = 1
      ephemeral = 0
    }
    "m1.small" = {
      vcpus     = 1
      ram       = 2048
      disk      = 20
      ephemeral = 0
    }
    "m1.medium" = {
      vcpus     = 2
      ram       = 4096
      disk      = 40
      ephemeral = 0
    }
    "m1.large" = {
      vcpus     = 4
      ram       = 8192
      disk      = 80
      ephemeral = 0
    }
    "m1.xlarge" = {
      vcpus     = 8
      ram       = 16384
      disk      = 160
      ephemeral = 0
    }
  }
}

# Cria os flavors do OpenStack dinamicamente usando for_each.
# O for_each itera sobre o mapa "locals.flavors" que definimos acima.
resource "openstack_compute_flavor_v2" "flavors" {
  for_each = local.flavors

  name      = each.key              # Usa a chave do mapa como nome do flavor (ex: "m1.tiny")
  vcpus     = each.value.vcpus      # Pega o valor de "vcpus" do item atual
  ram       = each.value.ram        # Pega o valor de "ram"
  disk      = each.value.disk       # Pega o valor de "disk"
  ephemeral = each.value.ephemeral  # Pega o valor de "ephemeral"
  is_public = true                  # Opcional: torna o flavor público para todos os projetos
}