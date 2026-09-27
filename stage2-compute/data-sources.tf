
# Блок импорта переменных из других проектов
data "terraform_remote_state" "network" {
  backend = "s3"
  
  config = {
    bucket                      = "netology"
    key                         = "stage1-network.tfstate"
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
}
