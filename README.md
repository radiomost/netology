# Домашнее задание к занятию "`Система мониторинга Zabbix`" - `Иванов Сергей`

# Задание 1

Установите Zabbix Server с веб-интерфейсом.

**Процесс выполнения**

1. Выполняя ДЗ, сверяйтесь с процессом отражённым в записи лекции
2. Установите PostgreSQL. Для установки достаточна та версия, что есть в системном репозитороии Debian 11.
3. Пользуясь конфигуратором команд с официального сайта, составьте набор команд для установки последней версии Zabbix с поддержкой PostgreSQL и Apache.
4. Выполните все необходимые команды для установки Zabbix Server и Zabbix Web Server

**Требования к результатам**
1. Прикрепите в файл README.md скриншот авторизации в админке.
2. Приложите в файл README.md текст использованных команд в GitHub.

## Решение

Вход в админку
![Вход в админку](https://github.com/radiomost/sys-pattern-homework/blob/main/img/lesson_1_1.png)

Главный дашборд
![Главный дашборд](https://github.com/radiomost/sys-pattern-homework/blob/main/img/lesson_1_2.png)

Для установки Zabbix Servera, Zabbix Web Server, PostgresQL я использовал Ubuntu 22.04 jammy

### Установка PostgresQL

### 1. Добавляем официальный репозиторий

```bash
sudo apt install curl ca-certificates gnupg
curl -fsSL https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo gpg --dearmor -o /etc/apt/trusted.gpg.d/postgresql.gpg
echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" | sudo tee /etc/apt/sources.list.d/pgdg.list
```
### 2. Устанавливаем PostgreSQL

```bash
sudo apt update
sudo apt install postgresql
```

### 3. Проверяем установленную версию

```bash
psql --version
```

### Установка Zabbix

Выбираем на странице *https://www.zabbix.com/ru/download*:

### Пакеты Zabbix
Версия Zabbix: 7.2
Дистрибутив ОС: Ubuntu
Версия ОС: 22.04 Jammy (amd64, arm64)
КОМПОНЕНТ ЗАББИКС: Server, Frontend, Agent
База данных: PostgreSQL
Веб-сервер: Apache


a. Заходим под правами root

```bash
$ sudo -s
```
b. Устанавливаем репозиторий Zabbix

```bash
wget https://repo.zabbix.com/zabbix/7.2/release/ubuntu/pool/main/z/zabbix-release/zabbix-release_latest_7.2+ubuntu22.04_all.deb
dpkg -i zabbix-release_latest_7.2+ubuntu22.04_all.deb
apt update
```
c. Устанавливаем Zabbix сервер, веб-интерфейс и агент

```bash
apt install zabbix-server-pgsql zabbix-frontend-php php8.1-pgsql zabbix-apache-conf zabbix-sql-scripts zabbix-agent
```

d. Создаем базу данных
```bash
sudo -u postgres createuser --pwprompt zabbix
sudo -u postgres createdb -O zabbix zabbix
```

На хосте Zabbix сервера импортируем начальную схему и данные. Будет предложено ввести недавно созданный пароль.
```bash
zcat /usr/share/zabbix/sql-scripts/postgresql/server.sql.gz | sudo -u zabbix psql zabbix
```

e. Настроим базу данных для Zabbix сервера
Отредактируем файл /etc/zabbix/zabbix_server.conf
```bash
DBPassword=password
```

f. Запускаем процессы Zabbix сервера 
Запустите процессы Zabbix сервера и настройте их запуск при загрузке ОС.
```bash
systemctl restart zabbix-server apache2
systemctl enable zabbix-server apache2
```
g. Open Zabbix UI web page
The default URL for Zabbix UI when using Apache web server is http://host/zabbix

---

# Задание 2

Установите Zabbix Agent на два хоста.

### Процесс выполнения
1. Выполняя ДЗ, сверяйтесь с процессом отражённым в записи лекции.
2. Установите Zabbix Agent на 2 вирт.машины, одной из них может быть ваш Zabbix Server.
3. Добавьте Zabbix Server в список разрешенных серверов ваших Zabbix Agentов.
4. Добавьте Zabbix Agentов в раздел Configuration > Hosts вашего Zabbix Servera.
5. Проверьте, что в разделе Latest Data начали появляться данные с добавленных агентов.
### Требования к результатам
1. Приложите в файл README.md скриншот раздела Configuration > Hosts, где видно, что агенты подключены к серверу
2. Приложите в файл README.md скриншот лога zabbix agent, где видно, что он работает с сервером
3. Приложите в файл README.md скриншот раздела Monitoring > Latest data для обоих хостов, где видны поступающие от агентов данные.
4. Приложите в файл README.md текст использованных команд в GitHub

## Решение:

### 1. Cкриншот раздела Configuration > Hosts, где видно, что агенты node-1, node-2, node-4 подключены к серверу
Агенты подключенные к серверу 
![Агенты подключенные к серверу ](https://github.com/radiomost/sys-pattern-homework/blob/main/img/task_2_1.png)

### 2. Cкриншоты логов zabbix agent node-2, где видно, что он работает с сервером

```bash
journalctl -u zabbix-agent -e
```

journalctl node-2
![journalctl node-2](https://github.com/radiomost/sys-pattern-homework/blob/main/img/task_2_3.png)

```bash
sudo cat /var/log/zabbix-agent/zabbix_agentd.log
```

zabbix_agentd.log node-2 
![zabbix_agentd.log node-2 ](https://github.com/radiomost/sys-pattern-homework/blob/main/img/task_2_4.png)

### 3. Cкриншот раздела Monitoring > Latest data для трех хостов, где видны поступающие от агентов данные.

Monitoring > Latest data для нод
![Monitoring > Latest data для нод](https://github.com/radiomost/sys-pattern-homework/blob/main/img/task_2_2.png)

### 4. текст использованных команд

#### Установка zabbix-агента

```bash
sudo apt install zabbix-agent
```

### Редактируем файл zabbix_agentd.conf.

```bash
sudo nano /etc/zabbix/zabbix_agentd.conf
```

### Ищем строку и прописываем IP адрес zabbix сервера

```bash
...
Server=10.115.64.40
...
```

### Перезапускаем сервис zabbix-агента

```bash
sudo systemctl restart zabbix-agent.service
```

### Проверяем статус сервиса. Убеждаемся что агент запущен

```bash
sudo systemctl status zabbix-agent.service
```


# Задание 3 со звёздочкой

1. Установите Zabbix Agent на Windows (компьютер) и подключите его к серверу Zabbix.

### Требования к результатам

1. Приложите в файл README.md скриншот раздела Latest Data, где видно свободное место на диске C:

## Решение

Свободное место на диске C. Обведено маркером
![Свободное место на диске C. Обведено маркером](https://github.com/radiomost/sys-pattern-homework/blob/main/img/task_3_1.png)

### Критерии оценки
1. Выполнено минимум 2 обязательных задания
2. Прикреплены требуемые скриншоты и тексты
3. Задание оформлено в шаблоне с решением и опубликовано на GitHub