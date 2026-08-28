resource "yandex_lb_target_group" "lamp" {
  name = "netology-lamp-target-group"

  target {
    subnet_id = var.subnet_id
    address   = "10.10.10.25"
  }

  target {
    subnet_id = var.subnet_id
    address   = "10.10.10.30"
  }
}

resource "yandex_lb_network_load_balancer" "lamp" {
  name = "netology-lamp-network-lb"

  listener {
    name = "http"
    port = 80

    external_address_spec {
      ip_version = "ipv4"
    }
  }

  attached_target_group {
    target_group_id = yandex_lb_target_group.lamp.id

    healthcheck {
      name = "http-health-check"

      http_options {
        port = 80
        path = "/"
      }
    }
  }
}