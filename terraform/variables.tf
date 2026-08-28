
variable "cloud_id" {
  type    = string
  default = "b1gd2gsrrlqn70h6kj6a"
}

variable "folder_id" {
  type    = string
  default = "b1gklg21hdhribb2tkq1"
}

variable "bucket_name" {
  description = "Имя бакета Object Storage"
  type        = string
}

variable "image_path" {
  description = "Путь к файлу изображения"
  type        = string
  default     = "./files/image.jpg"
}