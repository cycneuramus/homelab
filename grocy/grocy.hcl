locals {
  strg = "/mnt/jfs/grocy"
}

job "grocy" {
  group "grocy" {
    network {
      port "http" {
        to           = 8080
        host_network = "private"
      }
    }

    task "grocy" {
      driver = "podman"
      user   = "1000:1000"

      service {
        name         = "grocy"
        port         = "http"
        provider     = "nomad"
        address_mode = "host"
        tags         = ["public"]
      }

      config {
        image  = "ghcr.io/bbx0/grocy:4.3"
        ports  = ["http"]
        userns = "keep-id"

        logging = {
          driver = "journald"
        }

        volumes = [
          "${local.strg}/data:/data"
        ]
      }
    }
  }
}
