locals {
  strg  = pathexpand("~/.local/share/home-assistant")
  image = "ghcr.io/home-assistant/home-assistant:2026.2"
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
      # user   = "1000:1000"

      resources {
        memory_max = 1024
      }

      service {
        name         = "hass"
        port         = "http"
        provider     = "nomad"
        address_mode = "host"
        tags         = ["local", "monitor:personal"]
      }

      env {
        TZ = "Europe/Stockholm"
      }

      config {
        image = "${local.image}"
        ports = ["http"]

        # userns = "keep-id"

        logging = {
          driver = "journald"
        }

        volumes = [
          "${local.strg}/config:/config",
        ]

        devices = ["/dev/serial/by-id/usb-dresden_elektronik_ingenieurtechnik_GmbH_ConBee_II_DE2139508-if00:/dev/ttyACM0"]
      }
    }
  }
}
