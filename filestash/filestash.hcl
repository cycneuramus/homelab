locals {
  strg  = "/mnt/jfs/filestash"
  crypt = "/mnt/crypt/filestash"
  image = "docker.io/machines/filestash@sha256:e4c0c0537fa3bd08e988347bb563793779bb57bb0137c73d1af52b25d2e22dee"
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
