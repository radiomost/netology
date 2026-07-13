# Домашнее задание к занятию «Helm»

## Цель задания

В тестовой среде Kubernetes необходимо установить и обновить приложения с помощью Helm.

------

## Чеклист готовности к домашнему заданию

1. Установленное k8s-решение, например, MicroK8S.
2. Установленный локальный kubectl.
3. Установленный локальный Helm.
4. Редактор YAML-файлов с подключенным репозиторием GitHub.

------

## Инструменты и дополнительные материалы, которые пригодятся для выполнения задания

1. [Инструкция](https://helm.sh/docs/intro/install/) по установке Helm. [Helm completion](https://helm.sh/docs/helm/helm_completion/).

------

## Задание 1. Подготовить Helm-чарт для приложения

1. Необходимо упаковать приложение в чарт для деплоя в разные окружения. 
2. Каждый компонент приложения деплоится отдельным deployment’ом или statefulset’ом.
3. В переменных чарта измените образ приложения для изменения версии.

## Решение

### Создание чарта

Создаем новый Helm Chart.

```bash
helm create netology-app
```
Корректируем структуру проекта проекта:

```
netology-app/
├── Chart.yaml
├── values.yaml
└── templates
    ├── _helpers.tpl
    ├── backend-deployment.yaml
    ├── backend-service.yaml
    ├── frontend-deployment.yaml
    ├── frontend-service.yaml
    └── NOTES.txt
```

## Проверка шаблонов

Проверяем корректность чарта.

```bash
helm lint .
```

!['img_1.png'](img/img_1.png)

------
## Задание 2. Запустить две версии в разных неймспейсах

1. Подготовив чарт, необходимо его проверить. Запуститe несколько копий приложения.
2. Одну версию в namespace=app1, вторую версию в том же неймспейсе, третью версию в namespace=app2.
3. Продемонстрируйте результат.

## Решение

Создаем namespace:

```bash
kubectl create namespace app1
kubectl create namespace app2
```

!['img_2.png'](img/img_2.png)

### Версия 1

```bash
helm install app-v1 . -n app1
```

!['img_3.png'](img/img_3.png)

### Версия 2 в том же namespace

Меняем nginx:

```bash
helm install app-v2 . \
-n app1 \
--set frontend.image.tag=1.28
```

### Версия 3 в другом namespace

```bash
helm install app-v3 . \
-n app2 \
--set backend.args.text="Hello from app2"
```

Проверка:

```bash
helm list -A
```

Результат:

!['img_4.png'](img/img_4.png)


Поды:

```bash
kubectl get pods -A
```

!['img_5.png'](img/img_5.png)

## Правила приёма работы

1. Домашняя работа оформляется в своём Git репозитории в файле README.md. Выполненное домашнее задание пришлите ссылкой на .md-файл в вашем репозитории.
2. Файл README.md должен содержать скриншоты вывода необходимых команд `kubectl`, `helm`, а также скриншоты результатов.
3. Репозиторий должен содержать тексты манифестов или ссылки на них в файле README.md.
