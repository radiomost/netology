resource "yandex_lb_target_group" "lamp" {
  name        = "netology-lamp-target-group"
  description = "Target group for Netology LAMP instance group"

  dynamic "target" {
    for_each = data.yandex_compute_instance_group.lamp.instances

    content {
      subnet_id = var.subnet_id
      address   = target.value.network_interface[0].ip_address
    }
  }
}

resource "yandex_lb_network_load_balancer" "lamp" {
  name        = "netology-lamp-nlb"
  description = "Network Load Balancer for Netology LAMP"

  listener {
    name          = "http"
    port          = 80
    target_port   = 80
    protocol      = "tcp"

    external_address_spec {
      ip_version = "ipv4"
    }
  }

  attached_target_group {
    target_group_id = yandex_lb_target_group.lamp.id

    healthcheck {
      name               = "http-health-check"
      healthy_threshold   = 2
      unhealthy_threshold = 3
      interval             = 10
      timeout              = 5

      http_options {
        port = 80
        path = "/"
      }
    }
  }
}