# stage0-bootstrap/terragrunt/modules/bootstrapper/main.tf

locals {
  folder_id     = var.folder_id
  service_name  = "${var.project_name}-bootstrap-sa"
  
  # Генерируем уникальный суффикс встроенными функциями Terraform
  bucket_suffix = substr(md5(uuid()), 0, 8)
  bucket_name   = "${var.project_name}-artifacts-${local.bucket_suffix}"
}

# 1. Создаём сервисный аккаунт (Правильное имя ресурса)
resource "yandex_iam_service_account" "bootstrap_sa" {
  folder_id   = local.folder_id
  name        = local.service_name
  description = "Bootstrap SA for managing S3 buckets and infrastructure"
}

# 2. Выдаём права storage.admin этому аккаунту на уровне фолдера (Правильное имя ресурса)
resource "yandex_resourcemanager_folder_iam_binding" "bootstrap_sa_admin" {
  folder_id = local.folder_id
  role      = "storage.admin"
  
  members = [
    "serviceAccount:${yandex_iam_service_account.bootstrap_sa.id}",
  ]
}

# 3. Создаём статический ключ доступа для этого SA (для бэкенда)
resource "yandex_iam_service_account_static_access_key" "bootstrap_sa_key" {
  service_account_id = yandex_iam_service_account.bootstrap_sa.id
  description        = "Static access key for Terraform S3 backend"
}

# 4. Создаём S3 бакет для хранения state-файлов (Правильное имя ресурса для YC)
resource "yandex_storage_bucket" "terraform_state" {
  bucket     = local.bucket_name
  access_key = yandex_iam_service_account_static_access_key.bootstrap_sa_key.access_key
  secret_key = yandex_iam_service_account_static_access_key.bootstrap_sa_key.secret_key
  
  versioning {
    enabled = true
  }
  
  force_destroy = true 
}