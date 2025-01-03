locals {
  strg = pathexpand("/mnt/jfs/home-assistant")
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
        image  = "ghcr.io/home-assistant/home-assistant:2024.11"
        ports  = ["http"]
        socket = "root"

        logging = {
          driver = "journald"
        }

        volumes = [
          "${local.strg}/config:/config"
        ]

        devices = ["/dev/ttyACM0"]
      }
    }
  }
}
