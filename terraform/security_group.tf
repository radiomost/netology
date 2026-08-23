# Security Group для публичной ВМ
resource "yandex_vpc_security_group" "public_vm_sg" {
  name        = "public-vm-sg"
  description = "Security group for public VM"
  network_id  = yandex_vpc_network.netology_vpc.id

  ingress {
    protocol       = "ANY"
    description    = "Allow all"
    v4_cidr_blocks = ["0.0.0.0/0"]
    from_port      = 0
    to_port        = 65535
  }

  ingress {
    protocol       = "TCP"
    description    = "Allow all"
    v4_cidr_blocks = ["0.0.0.0/0"]
    from_port      = 22
    to_port        = 22
  }

  # Разрешаем весь исходящий трафик
  egress {
    protocol       = "ANY"
    description    = "Allow all outbound traffic"
    v4_cidr_blocks = ["0.0.0.0/0"]
    from_port      = 0
    to_port        = 65535
  }
}

# Security Group для NAT-инстанса
resource "yandex_vpc_security_group" "nat_instance_sg" {
  name        = "nat-instance-sg"
  description = "Security group for NAT instance"
  network_id  = yandex_vpc_network.netology_vpc.id

  # Разрешаем весь входящий трафик из нашей подсети
  ingress {
    protocol       = "ANY"
    description    = "Allow all inbound from public subnet"
    v4_cidr_blocks = ["192.168.10.0/24"]
  }

  # Разрешаем весь исходящий трафик в интернет
  egress {
    protocol       = "ANY"
    description    = "Allow all outbound traffic to internet"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}

# Security Group для private-vm
resource "yandex_vpc_security_group" "private_vm_sg" {
  name        = "private-vm-sg"
  description = "Security group for private VM"
  network_id  = yandex_vpc_network.netology_vpc.id

  # Разрешаем входящий SSH только из публичной подсети (от бастиона)
  ingress {
    protocol       = "TCP"
    description    = "Allow SSH from public subnet"
    v4_cidr_blocks = ["192.168.10.0/24"]
    from_port      = 22
    to_port        = 22
  }

  # Разрешаем ICMP (пинг) из публичной подсети для проверки связи
  ingress {
    protocol       = "ICMP"
    description    = "Allow ICMP from public subnet"
    v4_cidr_blocks = ["192.168.10.0/24"]
  }

  # Разрешаем весь исходящий трафик в интернет (через NAT)
  egress {
    protocol       = "ANY"
    description    = "Allow all outbound traffic"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}