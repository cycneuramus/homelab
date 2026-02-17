locals {
  strg  = "/mnt/jfs/seerr"
  image = "ghcr.io/seerr-team/seerr:v3.0.1"
}

job "seerr" {
  group "seerr" {
    network {
      port "http" {
        to           = 5055
        host_network = "private"
      }
    }

    task "seerr" {
      driver = "podman"
      user   = "1000:1000"

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

        userns = "keep-id"

        logging = {
          driver = "journald"
        }

        volumes = [
          "${local.strg}:/app/config"
        ]

        tmpfs = [
          "/app/config/logs"
        ]
      }
    }
  }
}
