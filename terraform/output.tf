output "bucket_name" {
  description = "Имя созданного бакета"
  value       = yandex_storage_bucket.netology_bucket.bucket
}

output "image_url" {
  description = "Публичный URL изображения"
  value       = "https://storage.yandexcloud.net/${yandex_storage_bucket.netology_bucket.bucket}/${yandex_storage_object.image.key}"
}