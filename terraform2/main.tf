#
# VPC network
#

resource "yandex_vpc_network" "network" {
  name      = var.network_name
  folder_id = var.folder_id
}

#
# Public subnet
#

resource "yandex_vpc_subnet" "public" {
  name           = var.subnet_name
  folder_id      = var.folder_id
  zone           = var.zone
  network_id     = yandex_vpc_network.network.id
  v4_cidr_blocks = var.subnet_cidr
}

#
# Service Account for Instance Group
#

resource "yandex_iam_service_account" "instance_group" {
  name        = var.service_account_name
  folder_id   = var.folder_id
  description = "Service account for Netology LAMP Instance Group"
}

#
# Permissions for Instance Group Service Account
#
# Instance Groups perform VM operations under this service account.
#

resource "yandex_resourcemanager_folder_iam_member" "instance_group_service_account_user" {
  folder_id = var.folder_id
  role      = "iam.serviceAccounts.user"
  member    = "serviceAccount:${yandex_iam_service_account.instance_group.id}"
}

resource "yandex_resourcemanager_folder_iam_member" "instance_group_compute_editor" {
  folder_id = var.folder_id
  role      = "compute.editor"
  member    = "serviceAccount:${yandex_iam_service_account.instance_group.id}"
}

resource "yandex_resourcemanager_folder_iam_member" "instance_group_vpc_public_admin" {
  folder_id = var.folder_id
  role      = "vpc.publicAdmin"
  member    = "serviceAccount:${yandex_iam_service_account.instance_group.id}"
}

#
# Permission for Terraform Service Account to use
# the Instance Group Service Account.
#
# The service account used by Terraform is "terraform".
#

data "yandex_iam_service_account" "terraform" {
  name = "terraform"
}


#
# Instance Group
#

resource "yandex_compute_instance_group" "lamp" {
  name      = var.instance_group_name
  folder_id = var.folder_id

  service_account_id = yandex_iam_service_account.instance_group.id

  scale_policy {
    fixed_scale {
      size = var.instance_group_size
    }
  }

  allocation_policy {
    zones = [
      var.zone
    ]
  }

  instance_template {
    platform_id = "standard-v3"

    resources {
      cores  = 2
      memory = 2
    }

    boot_disk {
      initialize_params {
        image_id = var.image_id
        type     = "network-hdd"
        size     = 10
      }
    }

    network_interface {
      network_id = yandex_vpc_network.network.id
      subnet_ids = [
        yandex_vpc_subnet.public.id
      ]

      nat = true
    }

    metadata = {
      user-data = templatefile(
        "${path.module}/templates/user-data.sh.tpl",
        {
          image_url = var.image_url
        }
      )
    }

    scheduling_policy {
      preemptible = false
    }
  }

  deploy_policy {
    max_unavailable = 1
    max_expansion   = 1
    max_creating    = 1
  }

  health_check {
    tcp_options {
      port = 80
    }

    interval            = 10
    timeout             = 5
    unhealthy_threshold = 3
    healthy_threshold   = 2
  }

  depends_on = [
    yandex_resourcemanager_folder_iam_member.instance_group_compute_editor,
    yandex_resourcemanager_folder_iam_member.instance_group_service_account_user,
    yandex_resourcemanager_folder_iam_member.instance_group_vpc_public_admin
  ]
}