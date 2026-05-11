# Домашнее задание к занятию 14 «Средство визуализации Grafana»

## Задание повышенной сложности

**При решении задания 1** не используйте директорию [help](./help) для сборки проекта. Самостоятельно разверните grafana, где в роли источника данных будет выступать prometheus, а сборщиком данных будет node-exporter:

- grafana;
- prometheus-server;
- prometheus node-exporter.

За дополнительными материалами можете обратиться в официальную документацию grafana и prometheus.

В решении к домашнему заданию также приведите все конфигурации, скрипты, манифесты, которые вы 
использовали в процессе решения задания.

**При решении задания 3** вы должны самостоятельно завести удобный для вас канал нотификации, например, Telegram или email, и отправить туда тестовые события.

В решении приведите скриншоты тестовых событий из каналов нотификаций.

## Обязательные задания

### Задание 1

1. Используя директорию [help](./help) внутри этого домашнего задания, запустите связку prometheus-grafana.
1. Зайдите в веб-интерфейс grafana, используя авторизационные данные, указанные в манифесте docker-compose.
1. Подключите поднятый вами prometheus, как источник данных.
1. Решение домашнего задания — скриншот веб-интерфейса grafana со списком подключенных Datasource.

## Решение

Я собрал схему окружения из трех неттопов. В сети у меня работает сервер dns, так что ip адреса заменены на реальные fqdn.

![](img/img_1.png)

На отдельных неттопах подняты экспортеры в docker.

![](img/img_2.png)

![](img/img_3.png)

Подключены экспортеры к prometheus

![](img/img_4.png)

В Grafana установлен источник данных Prometheus

![](img/img_5.png)

## Задание 2

Изучите самостоятельно ресурсы:

1. [PromQL tutorial for beginners and humans](https://valyala.medium.com/promql-tutorial-for-beginners-9ab455142085).
1. [Understanding Machine CPU usage](https://www.robustperception.io/understanding-machine-cpu-usage).
1. [Introduction to PromQL, the Prometheus query language](https://grafana.com/blog/2020/02/04/introduction-to-promql-the-prometheus-query-language/).

Создайте Dashboard и в ней создайте Panels:

- утилизация CPU для nodeexporter (в процентах, 100-idle);
- CPULA 1/5/15;
- количество свободной оперативной памяти;
- количество места на файловой системе.

Для решения этого задания приведите promql-запросы для выдачи этих метрик, а также скриншот получившейся Dashboard.

## Решение

### Утилизация CPU (100 - idle)

```promql
#A
100 - (avg by(instance) (rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100)
```

### CPU Load Average (1/5/15) 

```promql
#A
node_load1{instance="$instance"}

#B
node_load5{instance="$instance"}

#C
node_load15{instance="$instance"}
```

### Свободная RAM

```promql
#A
node_memory_MemAvailable_bytes{instance="$instance"} / 1024 / 1024 / 1024
```

### Свободное место FS

```promql
#A
node_filesystem_avail_bytes{instance="$instance", fstype!~"tmpfs|overlay",mountpoint!~"/boot|/boot/efi"} / 1024 / 1024 / 1024
```

### Заполнение диска

```promql
#A
100 - ((node_filesystem_avail_bytes{instance="$instance", fstype!~"tmpfs|overlay",mountpoint!~"/boot|/boot/efi"} / 1024 / 1024 / 1024)/(node_filesystem_size_bytes{instance="$instance", fstype!~"tmpfs|overlay",mountpoint!~"/boot|/boot/efi"} / 1024 / 1024 / 1024) * 100)
```

### Финальный дашборд

![](img/img_6.png)

## Задание 3

1. Создайте для каждой Dashboard подходящее правило alert — можно обратиться к первой лекции в блоке «Мониторинг».
1. В качестве решения задания приведите скриншот вашей итоговой Dashboard.

## Решение

![](img/img_7.png)

![](img/img_8.png)

![](img/img_9.png)

![](img/img_10.png)

![](img/img_11.png)



## Задание 4

1. Сохраните ваш Dashboard.Для этого перейдите в настройки Dashboard, выберите в боковом меню «JSON MODEL». Далее скопируйте отображаемое json-содержимое в отдельный файл и сохраните его.
1. В качестве решения задания приведите листинг этого файла.

## Решение

[dashboard.json](./dashboard-1778527488669.json)

---

### Как оформить решение задания

Выполненное домашнее задание пришлите в виде ссылки на .md-файл в вашем репозитории.

---