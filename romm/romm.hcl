locals {
  strg  = "/mnt/jfs/romm"
  image = "ghcr.io/rommapp/romm:4.1.6-slim"
}

job "romm" {
  group "romm" {
    network {
      port "http" {
        to           = 8080
        host_network = "private"
      }
    }

    task "romm" {
      driver = "podman"
      user   = "1000:1000"

      resources {
        memory_max = 1024
      }

      service {
        name         = "roms"
        port         = "http"
        provider     = "nomad"
        address_mode = "host"
        tags         = ["public"]
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
          "${local.strg}/config:/romm/config",
          "${local.strg}/resources:/romm/resources",
          "${local.strg}/assets:/romm/assets",
          "${local.strg}/redis:/redis-data",
          "${local.strg}/roms:/romm/library/roms",
        ]
      }
    }
  }
}
