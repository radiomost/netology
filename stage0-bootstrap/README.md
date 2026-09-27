# Yandex.Cloud Bootstrap Module — Создание S3 бакета и сервисного аккаунта
## 📋 Описание

Этот модуль предназначен для **самоподготовки инфраструктуры** (bootstrap) в начале проекта.
Он создаёт:
- Сервисный аккаунт (Service Account)
  - IAM роль `folder.objectStorage.admin` (минимальные права для работы с S3)
- С3 бакет (`diplom-{project_name}-artifacts-*`) 
  - Для хранения артефактов, конфигураций и промежуточных данных

## 🚀 Как использовать

### Шаг 1: Настройка переменных (terraform.tfvars)

Откройте файл `terraform.tfvars` и заполните:
```hcl
region     = "ru-central1"
folder_id   = "your-folder-id-here" # Получите в YC Console -> Фолдеры
token       = "ya-token-or-use-config-file" 
allow_insecure = false
```

### Шаг 2: Инициализация Terraform
```bash
cd /root/netology/stage0-bootstrap/terragrunt/modules/bootstrapper
terraform init
```

### Шаг 3: Применение (создание ресурсов)
```bash
terraform plan # Проверка перед созданием
terraform apply -auto-approve # Создать ресурсы
```

### Шаг 4: Получение данных о ресурсах
После успешного применения вы получите:
- `service_account_id` — ID сервисного аккаунта (можно использовать в других модулях)
- `bucket_name` — Название S3 бакета для артефактов
- `sa_token_url` — URL страницы YC Console с сервисным аккаунтом

## ⚠️ Важные замечания

### Бюджет и оптимизация:
- **НЕ используйте preemptible ВМ** на этом этапе! Сервисный аккаунт + S3 бакет не требуют compute-ресурсов.
- Минимизируйте права доступа (принцип наименьших привилегий).

### Безопасность: 
- Храните токены в защищённом хранилище (Secret Manager) или используйте `~/.config/yandex-cloud/config.yaml` с доверенными SSH ключами.
- Коммитьте только `.tfstate.enc`, если используете шифрование состояния Terraform.

## 📦 Структура модуля
```
terragrunt/modules/bootstrapper/
├── main.tf             # Основные ресурсы (SA + S3 бакет)
├── variables.tf        # Переменные для настройки региона, фолдера и т.д.
├── terraform.tfvars    # Заполняется вручную перед первым запуском
└── README.md           # Эта документация
```

## 🔗 Ссылки
- [Документация Yandex.Cloud Terraform Provider](https://registry.terraform.io/providers/yandex-cloud/yandex/latest)
