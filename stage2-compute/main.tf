# Fetch the latest Ubuntu 22.04 LTS image
data "yandex_compute_image" "ubuntu" {
  family = "ubuntu-2204-lts"
}

locals {
  # SSH public key for accessing VMs (ensure this exists on your host)
  ssh_public_key = file("~/.ssh/id_rsa.pub")

  subnet_a_id = data.terraform_remote_state.network.outputs.subnet_a_id
  subnet_b_id = data.terraform_remote_state.network.outputs.subnet_b_id
}

data "yandex_vpc_address" "master_ip" {
  address_id = var.master_ip_id
}

data "yandex_vpc_address" "worker1_ip" {
  address_id = var.worker1_ip_id
}

data "yandex_vpc_address" "worker2_ip" {
  address_id = var.worker2_ip_id
}

# Master Node (Non-preemptible for cluster stability)
resource "yandex_compute_instance" "master" {
  name        = "${var.project_name}-k8s-master"
  zone        = "ru-central1-a"
  platform_id = "standard-v3"
  
  resources {
    cores  = 2
    memory = 4 # Kubespray requires at least 2GB for master
  }

  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.ubuntu.id
      size     = 20
    }
  }

  network_interface {
    subnet_id = local.subnet_a_id
    nat       = true # Public IP for internet access and SSH
  }

  metadata = {
    ssh-keys = "ubuntu:${local.ssh_public_key}"
  }
  
  scheduling_policy {
    preemptible = false # Master must not be interrupted
  }
}

# Worker Nodes (Preemptible for cost optimization)
resource "yandex_compute_instance" "worker" {
  for_each    = toset(["worker-1", "worker-2"])
  name        = "${var.project_name}-k8s-${each.key}"
  
  # Distribute workers across availability zones for HA
  zone        = each.key == "worker-1" ? "ru-central1-a" : "ru-central1-b"
  platform_id = "standard-v3"
  
  resources {
    cores  = 2
    memory = 4
  }

  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.ubuntu.id
      size     = 20
    }
  }

  network_interface {
    subnet_id = each.key == "worker-1" ? local.subnet_a_id : local.subnet_b_id
    nat       = true # Public IP for pulling container images
  }

  metadata = {
    ssh-keys = "ubuntu:${local.ssh_public_key}"
  }
  
  scheduling_policy {
    preemptible = true # Cost optimization for workers
  }
}