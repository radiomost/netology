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

variable "zone" {
  description = "Availability zone"
  type        = string

  default = "ru-central1-a"
}

variable "network_name" {
  description = "VPC network name"
  type        = string

  default = "netology-lamp-network"
}

variable "subnet_name" {
  description = "Public subnet name"
  type        = string

  default = "netology-lamp-public-subnet"
}

variable "subnet_cidr" {
  description = "Public subnet CIDR"
  type        = list(string)

  default = [
    "10.10.10.0/24"
  ]
}

variable "instance_group_name" {
  description = "Instance Group name"
  type        = string

  default = "netology-lamp-instance-group"
}

variable "instance_group_size" {
  description = "Number of VM instances"
  type        = number

  default = 3
}

variable "service_account_name" {
  description = "Service account used by Instance Group"
  type        = string

  default = "netology-instance-group-sa"
}

variable "image_id" {
  description = "LAMP image ID"
  type        = string

  default = "fd827b91d99psvq5fjit"
}

variable "image_url" {
  description = "Public URL of the image from Object Storage"
  type        = string

  default = "https://storage.yandexcloud.net/netology-ivanov-sergey-20260828/image.jpg"
}