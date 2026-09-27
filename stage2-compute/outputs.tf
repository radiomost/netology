output "master_external_ip" {
  value       = yandex_compute_instance.master.network_interface.0.nat_ip_address
  description = "Public IP of the K8s Master node"
}

output "master_internal_ip" {
  value       = yandex_compute_instance.master.network_interface.0.ip_address
  description = "Private IP of the K8s Master node"
}

output "workers_external_ips" {
  value       = { for k, v in yandex_compute_instance.worker : k => v.network_interface.0.nat_ip_address }
  description = "Public IPs of K8s Worker nodes"
}

output "workers_internal_ips" {
  value       = { for k, v in yandex_compute_instance.worker : k => v.network_interface.0.ip_address }
  description = "Private IPs of K8s Worker nodes"
}