locals {
  strg  = "/mnt/jfs/koinsight"
  image = "ghcr.io/georgesg/koinsight:v0.2.2"
}

job "koinsight" {
  group "koinsight" {
    network {
      port "http" {
        to           = 3000
        host_network = "private"
      }
    }

    task "koinsight" {
      driver = "podman"
      user   = "1000:1000"

      service {
        name         = "koinsight"
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
          "${local.strg}:/app/data"
        ]
      }
    }
  }
}
