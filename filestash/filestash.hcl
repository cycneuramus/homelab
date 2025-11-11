locals {
  strg  = "/mnt/jfs/filestash"
  nas   = "/mnt/nas/apps"
  image = "docker.io/machines/filestash@sha256:dd5ffbe9127724d2b27b63416d2ad81c18da4f04bacfb9d516f200e68acb140c"
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
        tags         = ["public", "monitor:collaboration"]
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
