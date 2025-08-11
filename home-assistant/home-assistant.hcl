locals {
  strg  = "/mnt/jfs/home-assistant"
  image = "ghcr.io/home-assistant/home-assistant:2025.8"
}

job "home-assistant" {
  constraint {
    attribute = "${attr.unique.hostname}"
    value     = "apex"
  }

  group "home-assistant" {
    network {
      port "http" {
        to           = 8123
        host_network = "private"
      }
    }

    task "home-assistant" {
      driver = "podman"

      resources {
        memory_max = 1024
      }

      service {
        name         = "hass"
        port         = "http"
        provider     = "nomad"
        address_mode = "host"
        tags         = ["local"]
      }

      env {
        TZ = "Europe/Stockholm"
      }

      config {
        image  = "${local.image}"
        ports  = ["http"]
        socket = "root"

        logging = {
          driver = "journald"
        }

        volumes = [
          "${local.strg}/config:/config"
        ]

        devices = ["/dev/serial/by-id/usb-dresden_elektronik_ingenieurtechnik_GmbH_ConBee_II_DE2139508-if00:/dev/ttyACM0"]
      }
    }
  }
}
