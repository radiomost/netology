variable "cloud_id" {
  description = "Yandex Cloud ID"
  type        = string
  default = "b1gd2gsrrlqn70h6kj6a"
}

variable "folder_id" {
  description = "Yandex Cloud Folder ID"
  type        = string
  default = "b1gklg21hdhribb2tkq1"
}

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
  default     = "diplom-project"
}

variable "master_ip_id" {
  description = "ID of reserved static IP for master node"
  type        = string
  default = "e9br6jvlqb47b8vl7ice"
}

variable "worker1_ip_id" {
  description = "ID of reserved static IP for worker-1"
  type        = string
  default = "e9birrg5mhsc2k302vck"
}

variable "worker2_ip_id" {
  description = "ID of reserved static IP for worker-2"
  type        = string
  default = "e2ldlodvbl7f8ltgm35n"
}

variable "ssh_public_key" {
  description = "SSH public key for VM access"
  type        = string
  default     = ""
}