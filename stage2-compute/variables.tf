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
}

variable "worker1_ip_id" {
  description = "ID of reserved static IP for worker-1"
  type        = string
}

variable "worker2_ip_id" {
  description = "ID of reserved static IP for worker-2"
  type        = string
}