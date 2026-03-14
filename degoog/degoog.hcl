locals {
  strg  = "/mnt/jfs/degoog"
  image = "ghcr.io/fccview/degoog:0.8.0"
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
      user   = "1000:1000"

      service {
        name         = "search"
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
