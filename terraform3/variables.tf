variable "cloud_id" {
  type    = string
  default = "b1gd2gsrrlqn70h6kj6a"
}

variable "folder_id" {
  type    = string
  default = "b1gklg21hdhribb2tkq1"
}

variable "instance_group_id" {
  description = "ID существующей Instance Group"
  type        = string
  default     = "cl10gl0ibfeicrepeimt"
}

variable "network_id" {
  description = "ID существующей VPC сети"
  type        = string
  default     = "enpb91433d170phejqo2"
}

variable "subnet_id" {
  description = "ID существующей public subnet"
  type        = string
  default     = "e9bj9n7cgnn5nm83vjo2"
}