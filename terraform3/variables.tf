variable "cloud_id" {
  type = string
}

variable "folder_id" {
  type = string
}

variable "instance_group_name" {
  description = "Имя существующей Instance Group"
  type        = string
}

variable "subnet_id" {
  description = "ID public subnet"
  type        = string
}