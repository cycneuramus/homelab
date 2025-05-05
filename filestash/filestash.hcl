locals {
  strg  = "/mnt/jfs/filestash"
  crypt = "/mnt/crypt/filestash"
  image = "docker.io/machines/filestash@sha256:12b96db45b63fdd309f45884e94d74e18706987f70e68b88b6fbde8e595e5e4d"
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
