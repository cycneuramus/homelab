locals {
  strg  = "/mnt/jfs/radicale"
  image = "ghcr.io/kozea/radicale:3.5.7"
}

job "radicale" {
  group "radicale" {
    network {
      port "http" {
        to           = 5232
        host_network = "private"
      }
    }

    task "radicale" {
      driver = "podman"
      user   = "1000:1000"

      service {
        name         = "dav"
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
          "${local.strg}/config:/etc/radicale",
          "${local.strg}/data:/var/lib/radicale"
        ]
      }
    }
  }
}
