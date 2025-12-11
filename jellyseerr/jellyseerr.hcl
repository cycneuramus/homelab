locals {
  strg  = "/mnt/jfs/jellyseerr"
  image = "docker.io/fallenbagel/jellyseerr:2.7.3"
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
        tags         = ["public", "monitor:curation"]
      }

      resources {
        memory_max = 1024
      }

      template {
        data        = file(".env")
        destination = "env"
        env         = true
      }

      config {
        image = "${local.image}"
        ports = ["http"]

        logging = {
          driver = "journald"
        }

        volumes = [
          "${local.strg}/settings.json:/app/config/settings.json",
          "${local.strg}/cache:/app/config/cache"
        ]
      }
    }
  }
}
