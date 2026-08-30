
#
# KMS symmetric key
#

resource "yandex_kms_symmetric_key" "bucket" {
  name              = "netology-bucket-encryption-key"
  description       = "KMS key for Netology Object Storage bucket"
  default_algorithm = "AES_256"
  rotation_period   = "8760h"
  folder_id         = var.folder_id

  deletion_protection = true
}

#
# Existing Object Storage bucket
#
# The bucket is imported into this Terraform project.
#

resource "yandex_storage_bucket" "netology_bucket" {
  bucket    = var.bucket_name
  folder_id = var.folder_id

  anonymous_access_flags {
    read        = true
    list        = false
    config_read = false
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        kms_master_key_id = yandex_kms_symmetric_key.bucket.id
        sse_algorithm     = "aws:kms"
      }
    }
  }
}