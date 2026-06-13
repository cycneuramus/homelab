locals {
  strg  = "/mnt/jfs/bookorbit"
  image = "ghcr.io/bookorbit/bookorbit:1.10.0"
}

job "bookorbit" {
  group "bookorbit" {
    network {
      port "http" {
        to           = 3000
        host_network = "private"
      }
    }

    task "bookorbit" {
      driver = "podman"
      user   = "1000:1000"

      resources {
        memory_max = 4096
      }

      service {
        name         = "books"
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

        userns = "keep-id"

        logging = {
          driver = "journald"
        }

        volumes = [
          "${local.strg}/books:/books",
          "${local.strg}/data:/data"
        ]
      }
    }
  }
}
