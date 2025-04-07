locals {
  strg  = "/mnt/jfs/jellystat"
  image = "docker.io/cyfershepard/jellystat:1.1.4"
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
        image = "${local.image}"
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
