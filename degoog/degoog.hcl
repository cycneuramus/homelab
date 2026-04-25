locals {
  strg  = "/mnt/jfs/degoog"
  image = "ghcr.io/fccview/degoog:0.13.1"
}

job "degoog" {
  group "degoog" {
    network {
      port "http" {
        to           = 4444
        host_network = "private"
      }
    }

    task "degoog" {
      driver = "podman"

      service {
        name         = "search"
        port         = "http"
        provider     = "nomad"
        address_mode = "host"
        tags         = ["local"]
      }

      template {
        data        = file(".env")
        destination = "env"
        env         = true
      }

      config {
        image = "${local.image}"
        ports = ["http"]

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
