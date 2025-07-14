locals {
  strg  = "/mnt/jfs/silverbullet"
  image = "ghcr.io/silverbulletmd/silverbullet@sha256:69e37ce27c693fe6640d2c792c5161413d0b715195660df9fea024fd42a7162b"
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
