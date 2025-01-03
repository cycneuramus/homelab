locals {
  strg = "/mnt/jfs/wizarr"
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
        image = "ghcr.io/wizarrrr/wizarr:4.2.0"
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
