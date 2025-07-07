locals {
  strg  = "/mnt/jfs/silverbullet"
  image = "ghcr.io/silverbulletmd/silverbullet@sha256:d635c07cc602a98245642575d06ddbb0d3913a92c9662b556ed33e84e2ddf8d7"
}

job "silverbullet" {
  group "silverbullet" {
    network {
      port "http" {
        to           = 3000
        host_network = "private"
      }
    }

    task "silverbullet" {
      driver = "podman"
      user   = "1000:1000"

      service {
        name         = "notes"
        port         = "http"
        provider     = "nomad"
        address_mode = "host"
        tags         = ["local"]
      }

      config {
        image = "${local.image}"
        ports = ["http"]

        userns = "keep-id"

        logging = {
          driver = "journald"
        }

        volumes = [
          "${local.strg}:/space"
        ]
      }
    }
  }
}
