# stage0-bootstrap/terragrunt/modules/bootstrapper/outputs.tf

output "service_account_id" {
  value       = yandex_iam_service_account.bootstrap_sa.id
  description = "ID созданного сервисного аккаунта"
}

output "static_access_key" {
  value       = yandex_iam_service_account_static_access_key.bootstrap_sa_key.access_key
  description = "Access Key для подключения к S3 backend"
  sensitive   = true
}

output "static_secret_key" {
  value       = yandex_iam_service_account_static_access_key.bootstrap_sa_key.secret_key
  description = "Secret Key для подключения к S3 backend"
  sensitive   = true
}

output "bucket_name" {
  value       = yandex_storage_bucket.terraform_state.bucket
  description = "Имя созданного S3 бакета для стейт-файлов"
}