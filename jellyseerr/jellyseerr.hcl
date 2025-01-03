locals {
  strg = "/mnt/jfs/jellyseerr"
}

job "jellyseerr" {
  group "jellyseerr" {
    network {
      port "http" {
        to           = 5055
        host_network = "private"
      }
    }

    task "jellyseerr" {
      driver = "podman"

      service {
        name         = "jellyseerr"
        port         = "http"
        provider     = "nomad"
        address_mode = "host"
        tags         = ["public"]
      }

      resources {
        memory_max = 1024
      }

      env {
        LOG_LEVEL = "info"
        TZ        = "Europe/Stockholm"
      }

      template {
        data        = file("settings.json")
        destination = "local/settings.json"
        uid         = 1000
        gid         = 1000
      }

      config {
        image = "fallenbagel/jellyseerr:2.1.0"
        ports = ["http"]

        logging = {
          driver = "journald"
        }

        volumes = [
          "local/settings.json:/app/config/settings.json",
          "${local.strg}/db:/app/config/db"
        ]
      }
    }
  }
}
