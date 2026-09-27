# Create VPC network for the Kubernetes cluster
resource "yandex_vpc_network" "k8s_network" {
  name        = "${var.project_name}-vpc"
  description = "VPC network for K8s infrastructure"
}

# Create subnet in availability zone 'a'
resource "yandex_vpc_subnet" "subnet_a" {
  name           = "${var.project_name}-subnet-a"
  zone           = "ru-central1-a"
  network_id     = yandex_vpc_network.k8s_network.id
  v4_cidr_blocks = ["10.10.0.0/24"]
}

# Create subnet in availability zone 'b' for high availability
resource "yandex_vpc_subnet" "subnet_b" {
  name           = "${var.project_name}-subnet-b"
  zone           = "ru-central1-b"
  network_id     = yandex_vpc_network.k8s_network.id
  v4_cidr_blocks = ["10.10.1.0/24"]
}