resource "yandex_vpc_network" "netology_vpc" {
  name        = "netology-vpc"
  description = "Netology VPC зона"
}

# 1. Создаем таблицу маршрутизации для направления трафика через NAT-инстанс
resource "yandex_vpc_route_table" "nat_route" {
  network_id = yandex_vpc_network.netology_vpc.id
  name       = "nat-route-table"

  static_route {
    destination_prefix = "0.0.0.0/0"
    next_hop_address   = "192.168.10.254"
  }
}

resource "yandex_vpc_subnet" "public_subnet" {
  name           = "public"
  zone           = var.public_zone
  network_id     = yandex_vpc_network.netology_vpc.id
  v4_cidr_blocks = ["192.168.10.0/24"]
}

resource "yandex_vpc_subnet" "private_subnet" {
  name           = "private"
  zone           = var.private_zone
  network_id     = yandex_vpc_network.netology_vpc.id
  v4_cidr_blocks = ["192.168.20.0/24"]
  route_table_id = yandex_vpc_route_table.nat_route.id
}