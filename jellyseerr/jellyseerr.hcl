locals {
  strg = pathexpand("~/cld/jellyseerr")
}

job "jellyseerr" {
  constraint {
    attribute = "${meta.performance}"
    value     = "high"
  }

  group "jellyseerr" {
    count = 1

    network {
      port "http" {
        to           = 5055
        host_network = "private"
      }
    }

    task "jellyseerr" {
      driver = "docker"

      service {
        name     = "jellyseerr"
        port     = "http"
        provider = "nomad"
        tags     = ["public"]
      }

      env {
        LOG_LEVEL = "debug"
        TZ        = "Europe/Stockholm"
      }

      template {
        data        = file("settings.json.tpl")
        destination = "settings.json"
      }

      config {
        image = "fallenbagel/jellyseerr:latest"
        ports = ["http"]

        mount {
          type   = "bind"
          source = "settings.json"
          target = "/app/config/settings.json"
        }

        mount {
          type   = "bind"
          source = "${local.strg}/config"
          target = "/app/config"
        }
      }
    }
  }
}
