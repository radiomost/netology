variable "cloud_id" {
  description = "Yandex Cloud cloud ID"
  type        = string
}

variable "folder_id" {
  description = "Yandex Cloud folder ID"
  type        = string
}

variable "bucket_name" {
  description = "Existing Object Storage bucket"
  type        = string
  default     = "netology-ivanov-sergey-20260828"
}