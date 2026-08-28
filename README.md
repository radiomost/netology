# Домашнее задание к занятию «Вычислительные мощности. Балансировщики нагрузки»  

### Подготовка к выполнению задания

1. Домашнее задание состоит из обязательной части, которую нужно выполнить на провайдере Yandex Cloud, и дополнительной части в AWS (выполняется по желанию). 
2. Все домашние задания в блоке 15 связаны друг с другом и в конце представляют пример законченной инфраструктуры.  
3. Все задания нужно выполнить с помощью Terraform. Результатом выполненного домашнего задания будет код в репозитории. 
4. Перед началом работы настройте доступ к облачным ресурсам из Terraform, используя материалы прошлых лекций и домашних заданий.

---
## Задание 1. Yandex Cloud 

**Что нужно сделать**

1. Создать бакет Object Storage и разместить в нём файл с картинкой:

 - Создать бакет в Object Storage с произвольным именем (например, _имя_студента_дата_).
 - Положить в бакет файл с картинкой.
 - Сделать файл доступным из интернета.
 
2. Создать группу ВМ в public подсети фиксированного размера с шаблоном LAMP и веб-страницей, содержащей ссылку на картинку из бакета:

 - Создать Instance Group с тремя ВМ и шаблоном LAMP. Для LAMP рекомендуется использовать `image_id = fd827b91d99psvq5fjit`.
 - Для создания стартовой веб-страницы рекомендуется использовать раздел `user_data` в [meta_data](https://cloud.yandex.ru/docs/compute/concepts/vm-metadata).
 - Разместить в стартовой веб-странице шаблонной ВМ ссылку на картинку из бакета.
 - Настроить проверку состояния ВМ.
 
3. Подключить группу к сетевому балансировщику:

 - Создать сетевой балансировщик.
 - Проверить работоспособность, удалив одну или несколько ВМ.
4. (дополнительно)* Создать Application Load Balancer с использованием Instance group и проверкой состояния.

Полезные документы:

- [Compute instance group](https://registry.terraform.io/providers/yandex-cloud/yandex/latest/docs/resources/compute_instance_group).
- [Network Load Balancer](https://registry.terraform.io/providers/yandex-cloud/yandex/latest/docs/resources/lb_network_load_balancer).
- [Группа ВМ с сетевым балансировщиком](https://cloud.yandex.ru/docs/compute/operations/instance-groups/create-with-balancer).

## Решение

### 1. Создаем бакет Object Storage и размещаем в нём файл с картинкой

#### IAM-ключ service account

У нас уже есть файл с кредами к аккаунту:

```bash
~/.authorized_key.json
```
Нас интересует:

`service_account_id`

Получить его можно:

```bash
grep service_account_id ~/.authorized_key.json
```

!['img_1.png'](img/img_1.png)


#### Получаем Static Access Key

Теперь используем тот же service account:

```bash
yc iam access-key list \
  --service-account-id aje......vh
  ```

!['img_2.png'](img/img_2.png)

Здесь очень важно различать три значения.

##### ID

Например:

`aje........k8`

Это ID объекта access key в IAM.

##### SERVICE ACCOUNT ID

Например:

aje........vh

Это ID service account.

##### KEY ID

Например:

YCAJxxxxxxxxxxxxZi

Вот это является Access Key ID для S3.

Именно его мы используем в:

`YC_STORAGE_ACCESS_KEY`

#### Где взять Secret Access Key

Команда:

`yc iam access-key list`

*Secret* не показывает.

Если secret для существующего ключа не сохранён, создаём новый:

yc iam access-key create \
  --service-account-id aje........vh

Результат будет такой:

!['img_3.png'](img/img_3.png)

Получаем пару:

Access Key ID:
YCAJxxxxxxxxxxxxZi

Secret Access Key:
YCMxxxxxxxxxxxxxxxxxxxxxxkv

`Secret` показывается только при создании.

#### Экспортируем ключи

Для Yandex Terraform provider используем:

export YC_STORAGE_ACCESS_KEY="YCAJxxxxxxxxxxxZi"
export YC_STORAGE_SECRET_KEY="YCMxxxxxxxxxxxxxxxxxxxxxxkv"

Проверить можно безопасно:

```bash
printf 'ACCESS: %s...%s\n' \
  "${YC_STORAGE_ACCESS_KEY:0:4}" \
  "${YC_STORAGE_ACCESS_KEY: -2}"
  ```

!['img_4.png'](img/img_4.png)


```bash
printf 'ACCESS: %s...%s\n' \
  "${YC_STORAGE_SECRET_KEY:0:4}" \
  "${YC_STORAGE_SECRET_KEY: -2}"
  ```

!['img_5.png'](img/img_5.png)

#### Выдать права

```bash
yc resource-manager folder add-access-binding \
  <FOLDER_ID> \
  --role storage.editor \
  --subject serviceAccount:<SERVICE_ACCOUNT_ID>
```

!['img_6.png'](img/img_6.png)

Выполняем проект терраформ

```bash
terraform init
terraform plan
terraform apply
```
!['img_7.png'](img/img_7.png)
!['img_8.png'](img/img_8.png)

Ссылка на скачивание файла
`https://storage.yandexcloud.net/netology-ivanov-sergey-20260828/image.jpg`

### 2. Создаем группу ВМ в public подсети фиксированного размера с шаблоном LAMP и веб-страницей, содержащей ссылку на картинку из бакета

### Схема

```mermaid
graph TD
    YC[h-devops]

    subgraph Yandex Cloud
        OS[Object Storage]
        CC[Compute Cloud]

        IMG[image.jpg]
        IG[Instance Group<br/>size = 3]

        VM1[VM1<br/>LAMP + Apache]
        VM2[VM2<br/>LAMP + Apache]
        VM3[VM3<br/>LAMP + Apache]

        WEB[web page<br/>с ссылкой на image.jpg]
    end

    YC --> OS
    YC --> CC

    OS --> IMG
    CC --> IG

    IG --> VM1
    IG --> VM2
    IG --> VM3

    IMG -.-> WEB
    VM1 --> WEB
    VM2 --> WEB
    VM3 --> WEB
```

#### Нам потребуется:

1. сеть и public subnet — если они уже есть, используем существующие;
2. Instance Group;
3. Instance Template;
4.образ LAMP:
    `fd827b91d99psvq5fjit`
5. user_data для создания стартовой страницы;
6. Load Balancer для Instance Group — желательно сразу сделать правильно, поскольку нам требуется проверка состояния ВМ;
7. health check;
8. три экземпляра ВМ.

#### Добавляем права для netology-instance-group-sa

Проверяем, что у `netology-instance-group-sa` нет прав

!['img_9.png'](img/img_9.png)

!['img_10.png'](img/img_10.png)

Добавляем права `compute.editor` для `netology-instance-group-sa`

!['img_11.png'](img/img_11.png)

Добавляем права `vpc.user` для `netology-instance-group-sa`

!['img_12.png'](img/img_12.png)
 
Добавляем права `resource-manager.viewer` для `netology-instance-group-sa`

!['img_14.png'](img/img_14.png)

Проверяем:
!['img_13.png'](img/img_13.png)

!['img_15.png'](img/img_15.png)

!['img_16.png'](img/img_16.png)

### LAMP 1

!['img_17_1.png'](img/img_17_1.png)

### LAMP 2

!['img_17_2.png'](img/img_17_2.png)

### LAMP 3

!['img_17_3.png'](img/img_17_3.png)


## 3-4 Подключить группу к сетевому балансировщику и создать Application Load Balancer с использованием Instance group и проверкой состояния.

### Схема
```mermaid
graph TD
    A("Интернет")

    subgraph cl[Yandex Cloud]
        direction TB

        B1("Network Load Balancer")
        B2("Application Load Balancer")

        %% Точки распределения - маленькие кружки
        D1(( )):::junction
        D2(( )):::junction

        subgraph gr[Instance Group]
            direction LR
            E1[VM1]
            E2[VM2]
            E3[VM3]
        end
    end
        A --> B1
        A --> B2
        B1 --> D1
        B2 --> D2
        D1 --> E1
        D1 --> E2
        D1 --> E3
        D2 --> E1
        D2 --> E2
        D2 --> E3

        classDef junction fill:#333333,stroke:#333333,color:#333333
        class D1,D2 junction

        classDef purpleStyle color:#FFFFFF, fill:#AA00FF, stroke:#AA00FF
        class E1,E2,E3 purpleStyle
        style cl color:#FFFFFF, fill:#FFAE42, stroke:#F9F8BB
        style gr color:#000000, fill:#EDFF21, stroke:#AA00FF
```

---
## Задание 2*. AWS (задание со звёздочкой)

Это необязательное задание. Его выполнение не влияет на получение зачёта по домашней работе.

**Что нужно сделать**

Используя конфигурации, выполненные в домашнем задании из предыдущего занятия, добавить к Production like сети Autoscaling group из трёх EC2-инстансов с  автоматической установкой веб-сервера в private домен.

1. Создать бакет S3 и разместить в нём файл с картинкой:

 - Создать бакет в S3 с произвольным именем (например, _имя_студента_дата_).
 - Положить в бакет файл с картинкой.
 - Сделать доступным из интернета.
2. Сделать Launch configurations с использованием bootstrap-скрипта с созданием веб-страницы, на которой будет ссылка на картинку в S3. 
3. Загрузить три ЕС2-инстанса и настроить LB с помощью Autoscaling Group.

Resource Terraform:

- [S3 bucket](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket)
- [Launch Template](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/launch_template).
- [Autoscaling group](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/autoscaling_group).
- [Launch configuration](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/launch_configuration).

Пример bootstrap-скрипта:

```
#!/bin/bash
yum install httpd -y
service httpd start
chkconfig httpd on
cd /var/www/html
echo "<html><h1>My cool web-server</h1></html>" > index.html
```
### Правила приёма работы

Домашняя работа оформляется в своём Git репозитории в файле README.md. Выполненное домашнее задание пришлите ссылкой на .md-файл в вашем репозитории.
Файл README.md должен содержать скриншоты вывода необходимых команд, а также скриншоты результатов.
Репозиторий должен содержать тексты манифестов или ссылки на них в файле README.md.