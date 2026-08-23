
variable "cloud_id" {
  type    = string
  default = "b1gd2gsrrlqn70h6kj6a"
}

variable "folder_id" {
  type    = string
  default = "b1gklg21hdhribb2tkq1"
}

variable "public_zone" {
  description = "Зона доступности по умолчанию"
  type        = string
  default     = "ru-central1-b"
}

variable "private_zone" {
  description = "Зона доступности по умолчанию"
  type        = string
  default     = "ru-central1-e"
}