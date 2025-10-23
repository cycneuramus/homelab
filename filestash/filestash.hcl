locals {
  strg  = "/mnt/jfs/filestash"
  nas   = "/mnt/nas/apps"
  image = "docker.io/machines/filestash@sha256:ce6bd0172fa1dda8a983e72a66c8cd228da2c4a9098fcf4aee5b6d500ec90c8e"
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
          "${local.nas}/filestash:/app/data/files"
        ]
      }
    }
  }
}
