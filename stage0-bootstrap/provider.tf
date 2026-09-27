# stage0-bootstrap/terragrunt/modules/bootstrapper/provider.tf

terraform {

  backend "s3" {
    bucket                      = "netology"
    key                         = "stage0-bootstrap.tfstate"
    region                      = "us-east-1"
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

  required_providers {
    yandex = {
      source  = "yandex-cloud/yandex"
    }
  }
}

provider "yandex" {
  cloud_id                 = var.cloud_id
  folder_id                = var.folder_id
  service_account_key_file = file(pathexpand("~/.authorized_key.json"))
}