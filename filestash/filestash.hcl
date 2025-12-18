locals {
  strg  = "/mnt/jfs/filestash"
  nas   = "/mnt/nas/apps"
  image = "docker.io/machines/filestash@sha256:fdac4361f4515454954d40ce77e247a7e75a92134278ba34bd85407226f2707f"
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
