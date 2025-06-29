locals {
  strg  = "/mnt/jfs/pocket-id"
  image = "ghcr.io/pocket-id/pocket-id:v1.5.0"
}

job "pocket-id" {
  group "pocket-id" {
    network {
      port "http" {
        to           = 1411
        host_network = "private"
      }
    }

    task "pocket-id" {
      driver = "podman"
      user   = "0:0"

      service {
        name         = "oidc"
        port         = "http"
        provider     = "nomad"
        address_mode = "host"
        tags         = ["public"]
      }

      template {
        data        = file(".env")
        destination = "env"
        env         = true
      }

      config {
        image = "${local.image}"
        ports = ["http"]

        # userns = "keep-id"

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
