# Получаем актуальный ID образа Ubuntu 22.04 LTS из каталога Yandex Cloud
data "yandex_compute_image" "ubuntu_2204" {
  family = "ubuntu-2204-lts"
}
