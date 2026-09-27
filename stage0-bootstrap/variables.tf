# stage0-bootstrap/terragrunt/modules/bootstrapper/variables.tf

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
  description = "Project name used for naming resources"
  type        = string
  default     = "diplom-project"
}

variable "yc_token" {
  description = "Yandex Cloud OAuth token (if not using service account key file)"
  type        = string
  default     = ""
  sensitive   = true
}

variable "allow_insecure" {
  description = "Allow insecure connection (useful for testing)"
  type        = bool
  default     = false
}