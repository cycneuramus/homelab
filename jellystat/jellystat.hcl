locals {
  strg    = "/mnt/jfs/jellystat"
  version = "1.1.2"
}

job "jellystat" {
  group "jellystat" {
    network {
      port "app" {
        to           = 3000
        host_network = "private"
      }
    }

    task "jellystat" {
      driver = "podman"
      # user   = "1000:1000"

      service {
        name         = "jellystat"
        port         = "app"
        provider     = "nomad"
        address_mode = "host"
        tags         = ["local"]
      }

      template {
        data        = file(".env")
        destination = "env"
        env         = true
      }

      config {
        image = "cyfershepard/jellystat:${local.version}"
        ports = ["app"]

        logging = {
          driver = "journald"
        }

        volumes = [
          "${local.strg}/backup-data:/app/backend/backup-data"
        ]
      }
    }
  }
}
