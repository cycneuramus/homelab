locals {
  strg  = "/mnt/jfs/filestash"
  crypt = "/mnt/crypt/filestash"
}

job "filestash" {
  group "filestash" {
    network {
      port "http" {
        to           = 8334
        host_network = "private"
      }
    }

    task "filestash" {
      driver = "podman"
      user   = "1000:1000"

      service {
        name         = "filestash"
        port         = "http"
        provider     = "nomad"
        address_mode = "host"
        tags         = ["public"]
      }

      config {
        image = "docker.io/machines/filestash:latest"
        ports = ["http"]

        userns = "keep-id"

        logging = {
          driver = "journald"
        }

        volumes = [
          "${local.strg}:/app/data/state",
          "${local.crypt}:/app/data/files"
        ]
      }
    }
  }
}
