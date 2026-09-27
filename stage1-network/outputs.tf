output "vpc_id" {
  value       = yandex_vpc_network.k8s_network.id
  description = "ID of the created VPC"
}

output "subnet_a_id" {
  value       = yandex_vpc_subnet.subnet_a.id
  description = "ID of the subnet in ru-central1-a"
}

output "subnet_b_id" {
  value       = yandex_vpc_subnet.subnet_b.id
  description = "ID of the subnet in ru-central1-b"
}