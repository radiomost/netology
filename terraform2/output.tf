output "network_id" {
  description = "VPC network ID"
  value       = yandex_vpc_network.network.id
}

output "subnet_id" {
  description = "Public subnet ID"
  value       = yandex_vpc_subnet.public.id
}

output "instance_group_id" {
  description = "Instance Group ID"
  value       = yandex_compute_instance_group.lamp.id
}

output "instance_group_name" {
  description = "Instance Group name"
  value       = yandex_compute_instance_group.lamp.name
}

output "image_url" {
  description = "Image URL"
  value       = var.image_url
}