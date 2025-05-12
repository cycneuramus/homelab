locals {
  strg  = "/mnt/jfs/filestash"
  crypt = "/mnt/crypt/filestash"
  image = "docker.io/machines/filestash@sha256:e8d65bc9cee192d1515270abce59e749c83f6f1c35b9eb56e992790464328af8"
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
        image = "${local.image}"
        ports = ["http"]

        force_pull = true

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
