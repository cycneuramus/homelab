locals {
  strg    = "/mnt/jfs/wizarr"
  version = "4.2.0"
}

job "wizarr" {
  group "wizarr" {
    network {
      port "http" {
        to           = 5690
        host_network = "private"
      }
    }

    task "wizarr" {
      driver = "podman"

      service {
        name         = "wizarr"
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
        image = "ghcr.io/wizarrrr/wizarr:${local.version}"
        ports = ["http"]

        logging = {
          driver = "journald"
        }

        volumes = [
          "${local.strg}/data:/data/database"
        ]
      }
    }
  }
}
