terraform {
  required_providers {
    yandex = {
      source  = "yandex-cloud/yandex"
      version = "~> 0.130.0" # Проверь актуальную версию
    }
  }
}

provider "yandex" {
  token     = var.yc_token
  cloud_id  = var.yc_cloud_id
  folder_id = var.yc_folder_id
  zone      = var.yc_zone
}

# Создаем сервисный аккаунт
resource "yandex_iam_service_account" "sa" {
  name        = "diplom-sa"
  description = "Service account for Terraform"
}

# Назначаем ему роль editor (достаточно для создания ресурсов)
resource "yandex_resourcemanager_folder_iam_member" "sa_editor" {
  folder_id = var.yc_folder_id
  role      = "editor"
  member    = "serviceAccount:${yandex_iam_service_account.sa.id}"
}

# Создаем статический ключ доступа для SA (нужен для S3 backend)
resource "yandex_iam_service_account_static_access_key" "sa_static_key" {
  service_account_id = yandex_iam_service_account.sa.id
  description        = "Static access key for S3 backend"
}

# Создаем бакет для хранения state файлов
resource "yandex_storage_bucket" "tf_state" {
  bucket     = "diplom-tf-state-${var.yc_folder_id}" # Имя должно быть уникальным глобально
  access_key = yandex_iam_service_account_static_access_key.sa_static_key.access_key
  secret_key = yandex_iam_service_account_static_access_key.sa_static_key.secret_key

  # Отключаем публичный доступ
  anonymous_access_flags {
    read = false
    list = false
  }
  
  # Включаем версионирование (хорошая практика для state)
  versioning {
    enabled = true
  }
}

# Выводим ключи, чтобы использовать их в следующей стадии
output "sa_access_key" {
  value     = yandex_iam_service_account_static_access_key.sa_static_key.access_key
  sensitive = true
}

output "sa_secret_key" {
  value     = yandex_iam_service_account_static_access_key.sa_static_key.secret_key
  sensitive = true
}

output "bucket_name" {
  value = yandex_storage_bucket.tf_state.bucket
}