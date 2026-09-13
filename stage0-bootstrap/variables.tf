variable "yc_token" {
  type        = string
  description = "OAuth token for Yandex Cloud"
}

variable "yc_cloud_id" {
  type        = string
  description = "ID of the Yandex Cloud"
}

variable "yc_folder_id" {
  type        = string
  description = "ID of the Folder"
}

variable "yc_zone" {
  type        = string
  description = "Default availability zone"
  default     = "ru-central1-a"
}