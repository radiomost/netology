output "vpc_id" {
  value       = yandex_vpc_network.k8s_network.id
  description = "ID of the created VPC"
}

output "subnet_a_id" {
  value       = yandex_vpc_subnet.subnet_a.id
  description = "ID of the subnet in ru-central1-d"
}

output "subnet_d_id" {
  value       = yandex_vpc_subnet.subnet_d.id
  description = "ID of the subnet in ru-central1-d"
}