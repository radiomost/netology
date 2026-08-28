output "instance_group_id" {
  description = "ID Instance Group"
  value       = data.yandex_compute_instance_group.lamp.id
}

output "instance_group_name" {
  description = "Имя Instance Group"
  value       = data.yandex_compute_instance_group.lamp.name
}

output "target_group_id" {
  description = "ID NLB Target Group"
  value       = yandex_lb_target_group.lamp.id
}

output "target_group_name" {
  description = "Имя NLB Target Group"
  value       = yandex_lb_target_group.lamp.name
}

output "load_balancer_id" {
  description = "ID Network Load Balancer"
  value       = yandex_lb_network_load_balancer.lamp.id
}

output "load_balancer_name" {
  description = "Имя Network Load Balancer"
  value       = yandex_lb_network_load_balancer.lamp.name
}