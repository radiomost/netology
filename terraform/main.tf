
# 3. Создаем NAT-инстанс
resource "yandex_compute_instance" "nat_instance" {
  name        = "nat-instance"
  zone        = var.public_zone
  platform_id = "standard-v3"

  resources {
    cores         = 2
    memory        = 2
    core_fraction = 20
  }

  boot_disk {
    initialize_params {
      image_id = "fd80mrhj8fl2oe87o4e1"
      type     = "network-hdd"
    }
  }

  network_interface {
    subnet_id          = yandex_vpc_subnet.public_subnet.id
    ip_address         = "192.168.10.254"
    nat                = false
    security_group_ids = [yandex_vpc_security_group.nat_instance_sg.id]
  }

  metadata = {
    user-data          = file("./cloud-init.yml")
    serial-port-enable = 1
  }
}

# 4. Создаем виртуальную машину с публичным IP
resource "yandex_compute_instance" "public_vm" {
  name        = "public-vm"
  zone        = var.public_zone
  platform_id = "standard-v3"
  hostname = "public-vm"

  resources {
    cores         = 2
    memory        = 2
    core_fraction = 20
  }

  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.ubuntu_2204.id
      type     = "network-hdd"
      size     = 12
    }
  }

  scheduling_policy {
    preemptible = true
  }

  network_interface {
    subnet_id          = yandex_vpc_subnet.public_subnet.id
    nat                = true

    security_group_ids = [
      yandex_vpc_security_group.public_vm_sg.id
      ]
  }

  metadata = {
    user-data          = file("./cloud-init.yml")
    serial-port-enable = 1
  }
}

# 4. Создаем виртуальную машину с приватным IP
resource "yandex_compute_instance" "private_vm" {
  name        = "private-vm"
  zone        = var.private_zone
  platform_id = "standard-v3"
  hostname = "private-vm"

  resources {
    cores         = 2
    memory        = 2
    core_fraction = 20
  }

  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.ubuntu_2204.id
      type     = "network-hdd"
      size     = 12
    }
  }

  scheduling_policy {
    preemptible = true
  }

  network_interface {
    subnet_id          = yandex_vpc_subnet.private_subnet.id
    nat                = false

    security_group_ids = [yandex_vpc_security_group.private_vm_sg.id]
  }

  metadata = {
    user-data          = file("./cloud-init-private.yml")
    serial-port-enable = 1
  }
}
