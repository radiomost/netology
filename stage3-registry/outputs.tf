output "registry_id" {
  value       = yandex_container_registry.diploma_registry.id
  description = "ID of the created Yandex Container Registry"
}

output "registry_name" {
  value       = yandex_container_registry.diploma_registry.name
  description = "Name of the created Yandex Container Registry"
}