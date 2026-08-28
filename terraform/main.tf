resource "yandex_storage_bucket" "netology_bucket" {
  bucket    = var.bucket_name
  folder_id = var.folder_id

  anonymous_access_flags {
    read        = true
    list        = false
    config_read = false
  }
}

resource "yandex_storage_object" "image" {
  bucket = yandex_storage_bucket.netology_bucket.bucket
  key    = "image.jpg"
  source = var.image_path

  depends_on = [
    yandex_storage_bucket.netology_bucket
  ]
}