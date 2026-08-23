output "public_vm_ip" {
  value = yandex_compute_instance.public_vm.network_interface.0.nat_ip_address
}