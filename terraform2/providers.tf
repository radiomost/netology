terraform {

  required_providers {
    yandex = {
      source = "yandex-cloud/yandex"
    }
  }

  backend "s3" {
    bucket = "netology"
    key    = "instance-group.tfstate"
    region = "us-east-1"

    endpoints = {
      s3 = "https://s3-api.rdmost.ru"
    }

    profile                     = "minio-truenas"
    skip_credentials_validation = true
    skip_metadata_api_check     = true
    use_path_style              = true
    insecure                    = true
    skip_requesting_account_id  = true
    skip_s3_checksum            = true
  }
}

provider "yandex" {
  # token                    = "do not use!!!"
  cloud_id                 = var.cloud_id
  folder_id                = var.folder_id
  service_account_key_file = file(pathexpand("~/.authorized_key.json"))
}
