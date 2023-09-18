locals {
  strg = pathexpand("~/cld/home-assistant")
}

job "home-assistant" {
  constraint {
    attribute = "${attr.unique.hostname}"
    value     = "home"
  }

  group "home-assistant" {
    count = 1

    network {
      port "private" {
        to           = 8123
        host_network = "private"
      }
    }

    task "home-assistant" {
      driver = "docker"

      service {
        name     = "hass"
        port     = "private"
        provider = "nomad"
        tags     = ["local"]
      }

      env {
        PUID = "1000"
        PGID = "1000"
        TZ   = "Europe/Stockholm"
      }

      config {
        image = "lscr.io/linuxserver/homeassistant:latest"
        ports = ["private", "public"]

        mount {
          type   = "bind"
          source = "${local.strg}/config"
          target = "/config"
        }

        devices = [
          {
            host_path = "/dev/ttyACM0"
          }
        ]
      }
    }
  }
}
